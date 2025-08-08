#!/usr/bin/env python3
"""
Test script for batch processing functionality
"""

import logging
from security_hub_client import SecurityHubClient
from datetime import datetime

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def test_batch_processing():
    """Test the new batch processing functionality"""
    try:
        logger.info("Starting batch processing test...")
        
        client = SecurityHubClient()
        
        # Test region discovery
        logger.info("Testing region discovery...")
        regions = client._get_available_regions()
        logger.info(f"Discovered {len(regions)} regions: {regions[:5]}...")  # Show first 5
        
        # Test finding fetch with batch processing
        logger.info("Testing batch finding fetch...")
        start_time = datetime.utcnow()
        
        findings = client.get_findings()
        
        end_time = datetime.utcnow()
        duration = (end_time - start_time).total_seconds()
        
        logger.info(f"Fetched {len(findings)} findings in {duration:.2f} seconds")
        
        # Show sample findings by region
        region_counts = {}
        for finding in findings:
            region = finding.get('Region', 'Unknown')
            region_counts[region] = region_counts.get(region, 0) + 1
        
        logger.info("Findings by region:")
        for region, count in sorted(region_counts.items()):
            logger.info(f"  {region}: {count} findings")
        
        logger.info("Batch processing test completed successfully!")
        
    except Exception as e:
        logger.error(f"Error in batch processing test: {e}")
        raise

if __name__ == "__main__":
    test_batch_processing() 