import schedule
import time
import logging
import threading
from datetime import datetime
from security_hub_client import SecurityHubClient
from data_manager import DataManager
from config import settings

logger = logging.getLogger(__name__)


class SecurityHubScheduler:
    def __init__(self):
        self.client = SecurityHubClient()
        self.data_manager = DataManager()
        self.running = False
        self.thread = None
    
    def start(self):
        """Start the scheduler in a separate thread"""
        if self.running:
            logger.warning("Scheduler is already running")
            return
        
        self.running = True
        self.thread = threading.Thread(target=self._run_scheduler, daemon=True)
        self.thread.start()
        logger.info("Security Hub scheduler started")
    
    def stop(self):
        """Stop the scheduler"""
        self.running = False
        if self.thread:
            self.thread.join()
        logger.info("Security Hub scheduler stopped")
    
    def _run_scheduler(self):
        """Run the scheduler loop"""
        # Schedule the job to run every X minutes
        schedule.every(settings.polling_interval_minutes).minutes.do(self._fetch_and_store_findings)
        
        # Run initial fetch
        self._fetch_and_store_findings()
        
        # Keep the scheduler running
        while self.running:
            schedule.run_pending()
            time.sleep(60)  # Check every minute
    
    def _fetch_and_store_findings(self):
        """Fetch findings from Security Hub and store them"""
        try:
            logger.info("Starting scheduled Security Hub findings fetch (24-hour interval)")
            start_time = datetime.utcnow()
            
            # Fetch all findings (now includes multi-region batch processing)
            logger.info("Fetching all findings from all regions...")
            all_findings = self.client.get_all_findings()
            logger.info(f"Fetched {len(all_findings)} total findings from all regions")
            
            # Also fetch CSPM findings specifically (also multi-region)
            logger.info("Fetching CSPM findings from all regions...")
            cspm_findings = self.client.get_cspm_findings()
            logger.info(f"Fetched {len(cspm_findings)} CSPM findings from all regions")
            
            # Combine all findings
            findings = all_findings + cspm_findings
            
            # Remove duplicates based on finding ID
            unique_findings = {}
            for finding in findings:
                finding_id = finding.get('Id')
                if finding_id:
                    unique_findings[finding_id] = finding
            
            findings = list(unique_findings.values())
            
            if findings:
                # Store findings in database
                logger.info("Storing findings in database...")
                processed_count = self.data_manager.store_findings(findings)
                
                # Upload to S3 if configured
                if settings.s3_bucket_name:
                    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
                    filename = f"findings_{timestamp}.json"
                    
                    upload_data = {
                        "timestamp": timestamp,
                        "findings_count": len(findings),
                        "processed_count": processed_count,
                        "findings": findings
                    }
                    
                    self.data_manager.upload_to_s3(upload_data, filename)
                
                end_time = datetime.utcnow()
                duration = (end_time - start_time).total_seconds()
                
                logger.info(f"Successfully processed {processed_count} findings in {duration:.2f} seconds")
                logger.info(f"Total findings: {len(findings)}, CSPM findings: {len(cspm_findings)}")
                logger.info(f"Next scheduled fetch: {settings.polling_interval_minutes} minutes from now")
            else:
                logger.warning("No findings retrieved from Security Hub")
                
        except Exception as e:
            logger.error(f"Error in scheduled findings fetch: {e}")
    
    def run_manual_fetch(self):
        """Manually trigger a findings fetch"""
        logger.info("Manual findings fetch triggered")
        self._fetch_and_store_findings()
    
    def get_scheduler_status(self):
        """Get current scheduler status"""
        return {
            "running": self.running,
            "next_run": schedule.next_run().isoformat() if schedule.jobs else None,
            "polling_interval_minutes": settings.polling_interval_minutes
        }


# Global scheduler instance
scheduler = SecurityHubScheduler() 