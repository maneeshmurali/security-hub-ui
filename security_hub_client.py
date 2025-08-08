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
        Fetch Security Hub findings with optional filters from the configured region
        
        Args:
            filters: Optional filters to apply to the findings query
            
        Returns:
            List of finding dictionaries
        """
        all_findings = []
        
        # Default filters if none provided - fetch all active findings regardless of workflow status
        if filters is None:
            filters = {
                'RecordState': [{'Value': 'ACTIVE', 'Comparison': 'EQUALS'}]
            }
        
        try:
            logger.info(f"Fetching findings from region: {self.default_region}")
            client = boto3.client('securityhub', region_name=self.default_region)
            
            paginator = client.get_paginator('get_findings')
            
            for page in paginator.paginate(Filters=filters):
                findings = page.get('Findings', [])
                # Add region information to each finding
                for finding in findings:
                    finding['Region'] = self.default_region
                all_findings.extend(findings)
                logger.info(f"Fetched {len(findings)} findings from {self.default_region} in this page")
            
            logger.info(f"Total findings fetched from {self.default_region}: {len(all_findings)}")
            return all_findings
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == 'AccessDeniedException':
                logger.error("Access denied. Check IAM permissions for Security Hub")
            elif error_code == 'InvalidParameterException':
                logger.error(f"Invalid parameters in filters: {e}")
            else:
                logger.error(f"AWS Security Hub error: {e}")
            return []
        
        except NoCredentialsError:
            logger.error("No AWS credentials found. Ensure IAM role is properly configured")
            return []
        
        except Exception as e:
            logger.error(f"Unexpected error fetching findings: {e}")
            return []
    
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
        """Get Security Hub CSPM findings specifically from the configured region"""
        filters = {
            'RecordState': [{'Value': 'ACTIVE', 'Comparison': 'EQUALS'}],
            'ProductName': [
                {'Value': 'Security Hub', 'Comparison': 'EQUALS'},
                {'Value': 'AWS Foundational Security Best Practices', 'Comparison': 'EQUALS'},
                {'Value': 'AWS Security Hub', 'Comparison': 'EQUALS'}
            ]
        }
        return self.get_findings(filters)
    
    def get_finding_by_id(self, finding_id: str) -> Optional[Dict[str, Any]]:
        """Get a specific finding by ID from the configured region"""
        try:
            logger.info(f"Searching for finding {finding_id} in region: {self.default_region}")
            client = boto3.client('securityhub', region_name=self.default_region)
            
            response = client.get_findings(
                Filters={
                    'Id': [{'Value': finding_id, 'Comparison': 'EQUALS'}]
                }
            )
            findings = response.get('Findings', [])
            if findings:
                finding = findings[0]
                finding['Region'] = self.default_region
                logger.info(f"Found finding {finding_id} in region {self.default_region}")
                return finding
                
        except Exception as e:
            logger.error(f"Error fetching finding {finding_id}: {e}")
        
        logger.warning(f"Finding {finding_id} not found")
        return None 