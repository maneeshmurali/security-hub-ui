#!/usr/bin/env python3
"""
Test script for Security Hub Application
This script tests the basic functionality of the application components.
"""

import sys
import os
import logging
from datetime import datetime

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def test_imports():
    """Test that all required modules can be imported."""
    try:
        import boto3
        import fastapi
        import sqlalchemy
        import pydantic
        import schedule
        logger.info("✅ All required packages imported successfully")
        return True
    except ImportError as e:
        logger.error(f"❌ Import error: {e}")
        return False

def test_config():
    """Test configuration loading."""
    try:
        from config import settings
        logger.info(f"✅ Configuration loaded successfully")
        logger.info(f"   - AWS Region: {settings.aws_region}")
        logger.info(f"   - Database URL: {settings.database_url}")
        logger.info(f"   - Polling Interval: {settings.polling_interval_minutes} minutes")
        return True
    except Exception as e:
        logger.error(f"❌ Configuration error: {e}")
        return False

def test_database():
    """Test database connection and table creation."""
    try:
        from models import create_tables, engine
        create_tables()
        logger.info("✅ Database tables created successfully")
        
        # Test connection
        with engine.connect() as conn:
            result = conn.execute("SELECT 1")
            logger.info("✅ Database connection test successful")
        return True
    except Exception as e:
        logger.error(f"❌ Database error: {e}")
        return False

def test_security_hub_client():
    """Test Security Hub client initialization."""
    try:
        from security_hub_client import SecurityHubClient
        client = SecurityHubClient()
        logger.info(f"✅ Security Hub client initialized successfully")
        logger.info(f"   - Account ID: {client.account_id}")
        return True
    except Exception as e:
        logger.error(f"❌ Security Hub client error: {e}")
        logger.info("   Note: This is expected if AWS credentials are not configured")
        return False

def test_data_manager():
    """Test data manager initialization."""
    try:
        from data_manager import DataManager
        manager = DataManager()
        logger.info("✅ Data manager initialized successfully")
        return True
    except Exception as e:
        logger.error(f"❌ Data manager error: {e}")
        return False

def test_scheduler():
    """Test scheduler initialization."""
    try:
        from scheduler import SecurityHubScheduler
        scheduler = SecurityHubScheduler()
        logger.info("✅ Scheduler initialized successfully")
        return True
    except Exception as e:
        logger.error(f"❌ Scheduler error: {e}")
        return False

def test_api_models():
    """Test API model definitions."""
    try:
        from main import FindingResponse, FindingHistoryResponse, SchedulerStatusResponse
        logger.info("✅ API models defined successfully")
        return True
    except Exception as e:
        logger.error(f"❌ API models error: {e}")
        return False

def main():
    """Run all tests."""
    logger.info("🧪 Starting Security Hub Application Tests")
    logger.info("=" * 50)
    
    tests = [
        ("Package Imports", test_imports),
        ("Configuration", test_config),
        ("Database", test_database),
        ("Security Hub Client", test_security_hub_client),
        ("Data Manager", test_data_manager),
        ("Scheduler", test_scheduler),
        ("API Models", test_api_models),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        logger.info(f"\n🔍 Testing: {test_name}")
        try:
            if test_func():
                passed += 1
        except Exception as e:
            logger.error(f"❌ Test failed with exception: {e}")
    
    logger.info("\n" + "=" * 50)
    logger.info(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        logger.info("🎉 All tests passed! Application is ready to run.")
        return 0
    else:
        logger.warning("⚠️ Some tests failed. Please check the errors above.")
        return 1

if __name__ == "__main__":
    sys.exit(main()) 