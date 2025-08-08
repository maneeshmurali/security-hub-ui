import boto3
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from botocore.exceptions import ClientError, NoCredentialsError
from config import settings

logger = logging.getLogger(__name__)


class SecurityHubClient:
    def __init__(self):
        self.default_region = settings.aws_region
        self.account_id = self._get_account_id()
        self._available_regions = None
    
    def _get_available_regions(self) -> List[str]:
        """Get list of all available AWS regions"""
        if self._available_regions is None:
            try:
                ec2_client = boto3.client('ec2', region_name=self.default_region)
                regions = ec2_client.describe_regions()
                self._available_regions = [region['RegionName'] for region in regions['Regions']]
                logger.info(f"Found {len(self._available_regions)} available regions")
            except Exception as e:
                logger.error(f"Failed to get available regions: {e}")
                # Fallback to common regions
                self._available_regions = [
                    'us-east-1', 'us-east-2', 'us-west-1', 'us-west-2',
                    'eu-west-1', 'eu-west-2', 'eu-west-3', 'eu-central-1',
                    'ap-southeast-1', 'ap-southeast-2', 'ap-northeast-1', 'ap-northeast-2',
                    'sa-east-1', 'ca-central-1', 'ap-south-1', 'eu-north-1'
                ]
        return self._available_regions
    
    def _get_account_id(self) -> str:
        """Get the current AWS account ID"""
        try:
            sts_client = boto3.client('sts')
            response = sts_client.get_caller_identity()
            return response['Account']
        except Exception as e:
            logger.error(f"Failed to get account ID: {e}")
            return "unknown"
    
    def get_findings(self, filters: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """
        Fetch Security Hub findings with optional filters from all available regions in batches
        
        Args:
            filters: Optional filters to apply to the findings query
            
        Returns:
            List of finding dictionaries
        """
        all_findings = []
        
        # Default filters if none provided - fetch only HIGH, CRITICAL, MEDIUM with NEW workflow
        if filters is None:
            filters = {
                'RecordState': [{'Value': 'ACTIVE', 'Comparison': 'EQUALS'}],
                'SeverityLabel': [
                    {'Value': 'CRITICAL', 'Comparison': 'EQUALS'},
                    {'Value': 'HIGH', 'Comparison': 'EQUALS'},
                    {'Value': 'MEDIUM', 'Comparison': 'EQUALS'}
                ],
                'WorkflowStatus': [{'Value': 'NEW', 'Comparison': 'EQUALS'}]
            }
        
        # Check if multi-region processing is enabled (can be disabled via environment variable)
        import os
        enable_multi_region = os.getenv('ENABLE_MULTI_REGION', 'true').lower() == 'true'
        
        if not enable_multi_region:
            logger.info("Multi-region processing disabled, using single region only")
            return self._fetch_findings_from_regions([self.default_region], filters)
        
        try:
            # Get all available regions
            regions = self._get_available_regions()
            logger.info(f"Found {len(regions)} regions to process")
            
            # Process all available regions for comprehensive coverage
            max_regions = int(os.getenv('MAX_REGIONS', '0'))  # 0 means no limit
            if max_regions > 0:
                regions = regions[:max_regions]
                logger.info(f"Processing limited set of regions: {regions} (max: {max_regions})")
            else:
                logger.info(f"Processing all available regions: {regions}")
            
            # Process regions one at a time for maximum stability
            batch_size = 1  # Process 1 region at a time
            for i in range(0, len(regions), batch_size):
                batch_regions = regions[i:i + batch_size]
                logger.info(f"Processing region {i + 1}/{len(regions)}: {batch_regions}")
                
                try:
                    batch_findings = self._fetch_findings_from_regions(batch_regions, filters)
                    all_findings.extend(batch_findings)
                    logger.info(f"Successfully processed region {batch_regions[0]}")
                except Exception as e:
                    logger.error(f"Failed to process region {batch_regions[0]}: {e}")
                    continue
                
                # Longer delay between regions to be very respectful to AWS APIs
                if i + batch_size < len(regions):
                    import time
                    time.sleep(10)  # 10 second delay between regions
            
            logger.info(f"Total findings fetched from {len(regions)} regions: {len(all_findings)}")
            return all_findings
            
        except Exception as e:
            logger.error(f"Error in batch fetching: {e}")
            # Fallback to single region if batch processing fails
            logger.info("Falling back to single region processing")
            return self._fetch_findings_from_regions([self.default_region], filters)
    
    def _fetch_findings_from_regions(self, regions: List[str], filters: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Fetch findings from a specific batch of regions"""
        batch_findings = []
        
        for region in regions:
            try:
                logger.info(f"Fetching findings from region: {region}")
                
                # Create client with timeout configuration
                config = boto3.session.Config(
                    connect_timeout=30,  # 30 seconds connection timeout
                    read_timeout=60,     # 60 seconds read timeout
                    retries={'max_attempts': 2}  # Limit retries
                )
                client = boto3.client('securityhub', region_name=region, config=config)
                
                paginator = client.get_paginator('get_findings')
                region_findings = []
                
                # Limit pagination to prevent infinite loops
                page_count = 0
                max_pages = int(os.getenv('MAX_PAGES_PER_REGION', '20'))  # Limit to 20 pages per region
                
                for page in paginator.paginate(Filters=filters):
                    page_count += 1
                    if page_count > max_pages:
                        logger.warning(f"Reached max pages ({max_pages}) for region {region}, stopping pagination")
                        break
                        
                    findings = page.get('Findings', [])
                    for finding in findings:
                        finding['Region'] = region
                    region_findings.extend(findings)
                    
                    # Log progress
                    if page_count % 5 == 0:
                        logger.info(f"Processed {page_count} pages from {region}, found {len(region_findings)} findings so far")
                
                batch_findings.extend(region_findings)
                logger.info(f"Fetched {len(region_findings)} findings from {region} in {page_count} pages")
                
            except ClientError as e:
                error_code = e.response['Error']['Code']
                if error_code == 'AccessDeniedException':
                    logger.warning(f"Access denied to Security Hub in region {region}: {e}")
                elif error_code == 'InvalidAccessException':
                    logger.warning(f"Invalid access to Security Hub in region {region}: {e}")
                else:
                    logger.warning(f"AWS ClientError in region {region}: {e}")
                continue
            except NoCredentialsError:
                logger.warning(f"No AWS credentials found for region {region}")
                continue
            except Exception as e:
                logger.warning(f"Unexpected error fetching findings from {region}: {e}")
                continue
        
        return batch_findings
    
    def get_findings_by_severity(self, severity: str) -> List[Dict[str, Any]]:
        """Get findings filtered by severity"""
        filters = {
            'SeverityLabel': [{'Value': severity, 'Comparison': 'EQUALS'}]
        }
        return self.get_findings(filters)
    
    def get_findings_by_status(self, status: str) -> List[Dict[str, Any]]:
        """Get findings filtered by workflow status"""
        filters = {
            'WorkflowStatus': [{'Value': status, 'Comparison': 'EQUALS'}]
        }
        return self.get_findings(filters)
    
    def get_findings_by_product(self, product_name: str) -> List[Dict[str, Any]]:
        """Get findings filtered by product name"""
        filters = {
            'ProductName': [{'Value': product_name, 'Comparison': 'EQUALS'}]
        }
        return self.get_findings(filters)
    
    def get_findings_by_time_range(self, start_time: datetime, end_time: datetime) -> List[Dict[str, Any]]:
        """Get findings within a time range"""
        filters = {
            'CreatedAt': [
                {
                    'Start': start_time.isoformat(),
                    'End': end_time.isoformat()
                }
            ]
        }
        return self.get_findings(filters)
    
    def get_all_findings(self) -> List[Dict[str, Any]]:
        """Get all findings without filters"""
        return self.get_findings()
    
    def get_cspm_findings(self) -> List[Dict[str, Any]]:
        """Get Security Hub CSPM findings specifically with HIGH, CRITICAL, MEDIUM and NEW workflow"""
        filters = {
            'RecordState': [{'Value': 'ACTIVE', 'Comparison': 'EQUALS'}],
            'ProductName': [
                {'Value': 'Security Hub', 'Comparison': 'EQUALS'},
                {'Value': 'AWS Foundational Security Best Practices', 'Comparison': 'EQUALS'},
                {'Value': 'AWS Security Hub', 'Comparison': 'EQUALS'}
            ],
            'SeverityLabel': [
                {'Value': 'CRITICAL', 'Comparison': 'EQUALS'},
                {'Value': 'HIGH', 'Comparison': 'EQUALS'},
                {'Value': 'MEDIUM', 'Comparison': 'EQUALS'}
            ],
            'WorkflowStatus': [{'Value': 'NEW', 'Comparison': 'EQUALS'}]
        }
        return self.get_findings(filters)
    
    def get_finding_by_id(self, finding_id: str) -> Optional[Dict[str, Any]]:
        """Get a specific finding by ID from all available regions"""
        try:
            # Get all available regions
            regions = self._get_available_regions()
            logger.info(f"Searching for finding {finding_id} across {len(regions)} regions")
            
            for region in regions:
                try:
                    logger.info(f"Searching in region: {region}")
                    client = boto3.client('securityhub', region_name=region)
                    
                    response = client.get_findings(
                        Filters={
                            'Id': [{'Value': finding_id, 'Comparison': 'EQUALS'}]
                        }
                    )
                    
                    findings = response.get('Findings', [])
                    if findings:
                        finding = findings[0]
                        finding['Region'] = region
                        logger.info(f"Found finding {finding_id} in region {region}")
                        return finding
                        
                except ClientError as e:
                    error_code = e.response['Error']['Code']
                    if error_code == 'AccessDeniedException':
                        logger.warning(f"Access denied to Security Hub in region {region}: {e}")
                    else:
                        logger.warning(f"AWS ClientError in region {region}: {e}")
                    continue
                except Exception as e:
                    logger.warning(f"Error searching in region {region}: {e}")
                    continue
                    
        except Exception as e:
            logger.error(f"Error in multi-region search for finding {finding_id}: {e}")
        
        logger.warning(f"Finding {finding_id} not found in any region")
        return None 