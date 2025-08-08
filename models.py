from sqlalchemy import create_engine, Column, String, DateTime, Text, Integer, Boolean, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
from config import settings

Base = declarative_base()


class Finding(Base):
    __tablename__ = "findings"
    
    id = Column(String, primary_key=True)  # Security Hub finding ID
    title = Column(String)
    description = Column(Text)
    severity = Column(String)
    status = Column(String)
    product_name = Column(String)
    product_arn = Column(String)
    aws_account_id = Column(String)
    region = Column(String)
    created_at = Column(DateTime)
    updated_at = Column(DateTime)
    first_observed_at = Column(DateTime)
    last_observed_at = Column(DateTime)
    finding_provider = Column(String)
    finding_type = Column(String)
    compliance_status = Column(String)
    workflow_status = Column(String)
    record_state = Column(String)
    confidence = Column(Integer)
    criticality = Column(Integer)
    remediation_text = Column(Text)
    remediation_url = Column(String)
    resources = Column(JSON)
    types = Column(JSON)
    user_defined_fields = Column(JSON)
    verification_state = Column(String)
    workflow = Column(JSON)
    is_archived = Column(Boolean, default=False)
    last_updated = Column(DateTime, default=datetime.utcnow)


class FindingHistory(Base):
    __tablename__ = "finding_history"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    finding_id = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)
    status = Column(String)
    severity = Column(String)
    workflow_status = Column(String)
    compliance_status = Column(String)
    verification_state = Column(String)
    changes = Column(JSON)  # Store what changed in this update


# Database setup
engine = create_engine(settings.database_url)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def create_tables():
    Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close() 