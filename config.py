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
    app_port: int = 8000
    
    # Security Hub filters
    default_severity_filter: str = "CRITICAL,HIGH,MEDIUM,LOW,INFORMATIONAL"
    default_status_filter: str = "ACTIVE,SUPPRESSED"
    
    # Additional settings (with defaults)
    enable_https: bool = False
    redis_max_memory: str = "256mb"
    worker_processes: int = 4
    log_level: str = "INFO"
    enable_structured_logging: bool = True
    docker_subnet: str = "172.20.0.0/16"
    health_check_interval: int = 30
    health_check_timeout: int = 10
    health_check_retries: int = 3
    cache_ttl: int = 3600
    enable_cache: bool = True
    enable_rate_limiting: bool = True
    rate_limit_requests: int = 100
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_from_email: str = ""
    slack_webhook_url: str = ""
    db_pool_size: int = 10
    max_concurrent_requests: int = 100
    request_timeout: int = 30
    enable_cors: bool = True
    cors_allowed_origins: str = "*"
    enable_realtime_updates: bool = True
    enable_export: bool = True
    enable_bulk_operations: bool = True
    enable_watchlist: bool = True
    enable_filter_presets: bool = True
    enable_notifications: bool = True
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"


settings = Settings() 