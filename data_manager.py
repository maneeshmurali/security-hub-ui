import json
import logging
import boto3
from typing import List, Dict, Any, Optional
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from botocore.exceptions import ClientError

from models import Finding, FindingHistory, SessionLocal
from config import settings

logger = logging.getLogger(__name__)


class DataManager:
    def __init__(self):
        self.s3_client = None
        if settings.s3_bucket_name:
            self.s3_client = boto3.client('s3')
    
    def store_findings(self, findings: List[Dict[str, Any]]) -> int:
        """
        Store findings in the database and track changes
        
        Args:
            findings: List of finding dictionaries from Security Hub
            
        Returns:
            Number of findings processed
        """
        db = SessionLocal()
        processed_count = 0
        
        try:
            for finding_data in findings:
                finding_id = finding_data.get('Id')
                if not finding_id:
                    continue
                
                # Check if finding already exists
                existing_finding = db.query(Finding).filter(Finding.id == finding_id).first()
                
                if existing_finding:
                    # Track changes for existing finding
                    changes = self._detect_changes(existing_finding, finding_data)
                    if changes:
                        self._store_finding_history(db, existing_finding, changes)
                        self._update_finding(db, existing_finding, finding_data)
                else:
                    # Create new finding
                    new_finding = self._create_finding_from_data(finding_data)
                    db.add(new_finding)
                    
                    # Store initial history entry
                    self._store_finding_history(db, new_finding, {"action": "created"})
                
                processed_count += 1
            
            db.commit()
            logger.info(f"Successfully processed {processed_count} findings")
            
        except Exception as e:
            db.rollback()
            logger.error(f"Error storing findings: {e}")
            raise
        finally:
            db.close()
        
        return processed_count
    
    def _create_finding_from_data(self, finding_data: Dict[str, Any]) -> Finding:
        """Create a Finding object from Security Hub data"""
        return Finding(
            id=finding_data.get('Id'),
            title=finding_data.get('Title'),
            description=finding_data.get('Description'),
            severity=finding_data.get('Severity', {}).get('Label'),
            status=finding_data.get('RecordState'),
            product_name=finding_data.get('ProductName'),
            product_arn=finding_data.get('ProductArn'),
            aws_account_id=finding_data.get('AwsAccountId'),
            region=finding_data.get('Region'),
            created_at=self._parse_datetime(finding_data.get('CreatedAt')),
            updated_at=self._parse_datetime(finding_data.get('UpdatedAt')),
            first_observed_at=self._parse_datetime(finding_data.get('FirstObservedAt')),
            last_observed_at=self._parse_datetime(finding_data.get('LastObservedAt')),
            finding_provider=finding_data.get('FindingProviderFields', {}).get('ProviderName'),
            finding_type=finding_data.get('Types', [None])[0] if finding_data.get('Types') else None,
            compliance_status=finding_data.get('Compliance', {}).get('Status'),
            workflow_status=finding_data.get('Workflow', {}).get('Status'),
            record_state=finding_data.get('RecordState'),
            confidence=finding_data.get('Confidence'),
            criticality=finding_data.get('Criticality'),
            remediation_text=finding_data.get('Remediation', {}).get('Recommendation', {}).get('Text'),
            remediation_url=finding_data.get('Remediation', {}).get('Recommendation', {}).get('Url'),
            resources=json.dumps(finding_data.get('Resources', [])),
            types=json.dumps(finding_data.get('Types', [])),
            user_defined_fields=json.dumps(finding_data.get('UserDefinedFields', {})),
            verification_state=finding_data.get('VerificationState'),
            workflow=json.dumps(finding_data.get('Workflow', {})),
            is_archived=finding_data.get('RecordState') == 'ARCHIVED'
        )
    
    def _update_finding(self, db: Session, finding: Finding, finding_data: Dict[str, Any]):
        """Update an existing finding with new data"""
        finding.title = finding_data.get('Title', finding.title)
        finding.description = finding_data.get('Description', finding.description)
        finding.severity = finding_data.get('Severity', {}).get('Label', finding.severity)
        finding.status = finding_data.get('RecordState', finding.status)
        finding.workflow_status = finding_data.get('Workflow', {}).get('Status', finding.workflow_status)
        finding.compliance_status = finding_data.get('Compliance', {}).get('Status', finding.compliance_status)
        finding.verification_state = finding_data.get('VerificationState', finding.verification_state)
        finding.updated_at = self._parse_datetime(finding_data.get('UpdatedAt'))
        finding.last_observed_at = self._parse_datetime(finding_data.get('LastObservedAt'))
        finding.last_updated = datetime.utcnow()
        finding.is_archived = finding_data.get('RecordState') == 'ARCHIVED'
    
    def _detect_changes(self, existing_finding: Finding, new_data: Dict[str, Any]) -> Dict[str, Any]:
        """Detect changes between existing and new finding data"""
        changes = {}
        
        new_severity = new_data.get('Severity', {}).get('Label')
        if new_severity != existing_finding.severity:
            changes['severity'] = {'old': existing_finding.severity, 'new': new_severity}
        
        new_status = new_data.get('RecordState')
        if new_status != existing_finding.status:
            changes['status'] = {'old': existing_finding.status, 'new': new_status}
        
        new_workflow_status = new_data.get('Workflow', {}).get('Status')
        if new_workflow_status != existing_finding.workflow_status:
            changes['workflow_status'] = {'old': existing_finding.workflow_status, 'new': new_workflow_status}
        
        new_compliance_status = new_data.get('Compliance', {}).get('Status')
        if new_compliance_status != existing_finding.compliance_status:
            changes['compliance_status'] = {'old': existing_finding.compliance_status, 'new': new_compliance_status}
        
        new_verification_state = new_data.get('VerificationState')
        if new_verification_state != existing_finding.verification_state:
            changes['verification_state'] = {'old': existing_finding.verification_state, 'new': new_verification_state}
        
        return changes
    
    def _store_finding_history(self, db: Session, finding: Finding, changes: Dict[str, Any]):
        """Store finding history entry"""
        history_entry = FindingHistory(
            finding_id=finding.id,
            status=finding.status,
            severity=finding.severity,
            workflow_status=finding.workflow_status,
            compliance_status=finding.compliance_status,
            verification_state=finding.verification_state,
            changes=json.dumps(changes)
        )
        db.add(history_entry)
    
    def _parse_datetime(self, datetime_str: Optional[str]) -> Optional[datetime]:
        """Parse datetime string from Security Hub format"""
        if not datetime_str:
            return None
        try:
            return datetime.fromisoformat(datetime_str.replace('Z', '+00:00'))
        except ValueError:
            return None
    
    def get_findings(self, 
                    severity: Optional[str] = None,
                    status: Optional[str] = None,
                    product_name: Optional[str] = None,
                    workflow_status: Optional[str] = None,
                    region: Optional[str] = None,
                    aws_account_id: Optional[str] = None,
                    compliance_status: Optional[str] = None,
                    start_date: Optional[datetime] = None,
                    end_date: Optional[datetime] = None,
                    limit: int = 100,
                    offset: int = 0) -> List[Finding]:
        """Get findings with filters"""
        db = SessionLocal()
        try:
            query = db.query(Finding)
            
            if severity:
                query = query.filter(Finding.severity == severity)
            
            if status:
                query = query.filter(Finding.status == status)
            
            if product_name:
                query = query.filter(Finding.product_name == product_name)
            
            if workflow_status:
                query = query.filter(Finding.workflow_status == workflow_status)
            
            if region:
                query = query.filter(Finding.region == region)
            
            if aws_account_id:
                query = query.filter(Finding.aws_account_id == aws_account_id)
            
            if compliance_status:
                query = query.filter(Finding.compliance_status == compliance_status)
            
            if start_date and end_date:
                query = query.filter(
                    and_(
                        Finding.created_at >= start_date,
                        Finding.created_at <= end_date
                    )
                )
            
            return query.order_by(Finding.created_at.desc()).offset(offset).limit(limit).all()
        
        finally:
            db.close()
    
    def get_finding_by_id(self, finding_id: str) -> Optional[Finding]:
        """Get a specific finding by ID"""
        db = SessionLocal()
        try:
            finding = db.query(Finding).filter(Finding.id == finding_id).first()
            if finding:
                logger.info(f"Found finding: {finding.id} - {finding.title}")
            else:
                logger.warning(f"No finding found with ID: {finding_id}")
            return finding
        finally:
            db.close()
    
    def get_finding_history(self, finding_id: str) -> List[FindingHistory]:
        """Get history for a specific finding"""
        db = SessionLocal()
        try:
            return db.query(FindingHistory).filter(
                FindingHistory.finding_id == finding_id
            ).order_by(FindingHistory.timestamp.desc()).all()
        finally:
            db.close()
    
    def upload_to_s3(self, data: Dict[str, Any], filename: str) -> bool:
        """Upload data to S3 bucket"""
        if not self.s3_client or not settings.s3_bucket_name:
            logger.warning("S3 upload not configured")
            return False
        
        try:
            key = f"{settings.s3_prefix}{filename}"
            self.s3_client.put_object(
                Bucket=settings.s3_bucket_name,
                Key=key,
                Body=json.dumps(data, default=str),
                ContentType='application/json'
            )
            logger.info(f"Successfully uploaded {filename} to S3")
            return True
        except ClientError as e:
            logger.error(f"Error uploading to S3: {e}")
            return False
    
    def export_findings_csv(self, findings: List[Finding]) -> str:
        """Export findings to CSV format"""
        import csv
        import io
        
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Write header
        writer.writerow([
            'ID', 'Title', 'Severity', 'Status', 'Product Name', 'AWS Account',
            'Region', 'Created At', 'Updated At', 'Workflow Status', 'Compliance Status'
        ])
        
        # Write data
        for finding in findings:
            writer.writerow([
                finding.id, finding.title, finding.severity, finding.status,
                finding.product_name, finding.aws_account_id, finding.region,
                finding.created_at, finding.updated_at, finding.workflow_status,
                finding.compliance_status
            ])
        
        return output.getvalue()
    
    # Comment management methods
    def get_finding_comments(self, finding_id: str) -> List[Any]:
        """Get comments for a specific finding"""
        db = SessionLocal()
        try:
            from models import FindingComment
            return db.query(FindingComment).filter(
                FindingComment.finding_id == finding_id
            ).order_by(FindingComment.created_at.desc()).all()
        finally:
            db.close()
    
    def add_finding_comment(self, finding_id: str, comment: str, author: str = "System", is_internal: bool = False) -> Any:
        """Add a comment to a finding"""
        db = SessionLocal()
        try:
            from models import FindingComment
            new_comment = FindingComment(
                finding_id=finding_id,
                comment=comment,
                author=author,
                is_internal=is_internal
            )
            db.add(new_comment)
            db.commit()
            db.refresh(new_comment)
            return new_comment
        except Exception as e:
            db.rollback()
            logger.error(f"Error adding comment: {e}")
            raise
        finally:
            db.close()
    
    def update_finding_comment(self, comment_id: int, comment: str, author: str = "System", is_internal: bool = False) -> Optional[Any]:
        """Update a comment for a finding"""
        db = SessionLocal()
        try:
            from models import FindingComment
            existing_comment = db.query(FindingComment).filter(FindingComment.id == comment_id).first()
            if not existing_comment:
                return None
            
            existing_comment.comment = comment
            existing_comment.author = author
            existing_comment.is_internal = is_internal
            existing_comment.updated_at = datetime.utcnow()
            
            db.commit()
            db.refresh(existing_comment)
            return existing_comment
        except Exception as e:
            db.rollback()
            logger.error(f"Error updating comment: {e}")
            raise
        finally:
            db.close()
    
    def delete_finding_comment(self, comment_id: int) -> bool:
        """Delete a comment for a finding"""
        db = SessionLocal()
        try:
            from models import FindingComment
            comment = db.query(FindingComment).filter(FindingComment.id == comment_id).first()
            if not comment:
                return False
            
            db.delete(comment)
            db.commit()
            return True
        except Exception as e:
            db.rollback()
            logger.error(f"Error deleting comment: {e}")
            raise
        finally:
            db.close() 