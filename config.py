import os
from typing import Optional
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Database settings
    database_url: str = "sqlite:///./security_hub_findings.db"
    
    # AWS Settings
    aws_region: str = "us-east-1"
    
    # S3 Settings (optional)
    s3_bucket_name: Optional[str] = None
    s3_prefix: str = "security-hub-findings/"
    
    # Polling settings
    polling_interval_minutes: int = 30
    
    # API settings
    host: str = "0.0.0.0"
    port: int = 8000
    
    # Security Hub filters
    default_severity_filter: str = "CRITICAL,HIGH,MEDIUM,LOW,INFORMATIONAL"
    default_status_filter: str = "ACTIVE,SUPPRESSED"
    
    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings() 