import boto3
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from botocore.exceptions import ClientError, NoCredentialsError
from config import settings

logger = logging.getLogger(__name__)


class SecurityHubClient:
    def __init__(self):
        self.client = boto3.client('securityhub', region_name=settings.aws_region)
        self.account_id = self._get_account_id()
    
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
        Fetch all Security Hub findings with optional filters
        
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
            paginator = self.client.get_paginator('get_findings')
            
            for page in paginator.paginate(Filters=filters):
                findings = page.get('Findings', [])
                all_findings.extend(findings)
                logger.info(f"Fetched {len(findings)} findings in this page")
            
            logger.info(f"Total findings fetched: {len(all_findings)}")
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
        """Get Security Hub CSPM findings specifically"""
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
        """Get a specific finding by ID"""
        try:
            response = self.client.get_findings(
                Filters={
                    'Id': [{'Value': finding_id, 'Comparison': 'EQUALS'}]
                }
            )
            findings = response.get('Findings', [])
            return findings[0] if findings else None
        except Exception as e:
            logger.error(f"Error fetching finding {finding_id}: {e}")
            return None 