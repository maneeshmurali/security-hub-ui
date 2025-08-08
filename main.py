import logging
from datetime import datetime, timedelta
from typing import List, Optional
from fastapi import FastAPI, HTTPException, Query, Depends
from fastapi.responses import HTMLResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.requests import Request
from pydantic import BaseModel
import io

from models import create_tables, get_db
from data_manager import DataManager
from scheduler import scheduler
from config import settings

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="AWS Security Hub Findings API",
    description="API for managing and querying AWS Security Hub findings",
    version="1.0.0"
)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Setup templates
templates = Jinja2Templates(directory="templates")

# Create database tables
create_tables()

# Pydantic models for API responses
class FindingResponse(BaseModel):
    id: str
    title: str
    description: Optional[str]
    severity: Optional[str]
    status: Optional[str]
    product_name: Optional[str]
    aws_account_id: Optional[str]
    region: Optional[str]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    workflow_status: Optional[str]
    compliance_status: Optional[str]
    verification_state: Optional[str]
    is_archived: bool

    class Config:
        from_attributes = True

class FindingHistoryResponse(BaseModel):
    id: int
    finding_id: str
    timestamp: datetime
    status: Optional[str]
    severity: Optional[str]
    workflow_status: Optional[str]
    compliance_status: Optional[str]
    verification_state: Optional[str]
    changes: Optional[str]

    class Config:
        from_attributes = True

class SchedulerStatusResponse(BaseModel):
    running: bool
    next_run: Optional[str]
    polling_interval_minutes: int

class CommentRequest(BaseModel):
    comment: str
    author: str = "System"
    is_internal: bool = False

class CommentResponse(BaseModel):
    id: int
    finding_id: str
    author: str
    comment: str
    created_at: datetime
    updated_at: datetime
    is_internal: bool

    class Config:
        from_attributes = True

# Initialize data manager
data_manager = DataManager()

@app.on_event("startup")
async def startup_event():
    """Start the scheduler when the application starts"""
    scheduler.start()
    logger.info("Application started and scheduler initialized")

@app.on_event("shutdown")
async def shutdown_event():
    """Stop the scheduler when the application shuts down"""
    scheduler.stop()
    logger.info("Application shutdown and scheduler stopped")

@app.get("/", response_class=HTMLResponse)
async def root(request: Request):
    """Serve the main dashboard"""
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/api/findings", response_model=List[FindingResponse])
async def get_findings(
    severity: Optional[str] = Query(None, description="Filter by severity (CRITICAL, HIGH, MEDIUM, LOW, INFORMATIONAL)"),
    status: Optional[str] = Query(None, description="Filter by status (ACTIVE, ARCHIVED)"),
    product_name: Optional[str] = Query(None, description="Filter by product name"),
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    limit: int = Query(100, ge=1, le=1000, description="Number of findings to return"),
    offset: int = Query(0, ge=0, description="Number of findings to skip")
):
    """Get findings with optional filters"""
    try:
        # Parse dates if provided
        start_dt = None
        end_dt = None
        if start_date:
            start_dt = datetime.strptime(start_date, "%Y-%m-%d")
        if end_date:
            end_dt = datetime.strptime(end_date, "%Y-%m-%d")
        
        findings = data_manager.get_findings(
            severity=severity,
            status=status,
            product_name=product_name,
            start_date=start_dt,
            end_date=end_dt,
            limit=limit,
            offset=offset
        )
        
        return findings
    except Exception as e:
        logger.error(f"Error getting findings: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/api/findings/{finding_id}", response_model=FindingResponse)
async def get_finding(finding_id: str):
    """Get a specific finding by ID"""
    # Decode URL-encoded finding ID
    import urllib.parse
    decoded_finding_id = urllib.parse.unquote(finding_id)
    
    finding = data_manager.get_finding_by_id(decoded_finding_id)
    if not finding:
        raise HTTPException(status_code=404, detail="Finding not found")
    return finding

@app.get("/api/findings/{finding_id}/history", response_model=List[FindingHistoryResponse])
async def get_finding_history(finding_id: str):
    """Get history for a specific finding"""
    # Decode URL-encoded finding ID
    import urllib.parse
    decoded_finding_id = urllib.parse.unquote(finding_id)
    
    history = data_manager.get_finding_history(decoded_finding_id)
    if not history:
        raise HTTPException(status_code=404, detail="Finding history not found")
    return history

@app.get("/api/findings/{finding_id}/comments", response_model=List[CommentResponse])
async def get_finding_comments(finding_id: str):
    """Get comments for a specific finding"""
    # Decode URL-encoded finding ID
    import urllib.parse
    decoded_finding_id = urllib.parse.unquote(finding_id)
    
    comments = data_manager.get_finding_comments(decoded_finding_id)
    return comments

@app.post("/api/findings/{finding_id}/comments", response_model=CommentResponse)
async def add_finding_comment(finding_id: str, comment_request: CommentRequest):
    """Add a comment to a finding"""
    # Decode URL-encoded finding ID
    import urllib.parse
    decoded_finding_id = urllib.parse.unquote(finding_id)
    
    # Verify finding exists
    finding = data_manager.get_finding_by_id(decoded_finding_id)
    if not finding:
        raise HTTPException(status_code=404, detail="Finding not found")
    
    comment = data_manager.add_finding_comment(
        finding_id=decoded_finding_id,
        comment=comment_request.comment,
        author=comment_request.author,
        is_internal=comment_request.is_internal
    )
    return comment

@app.put("/api/findings/{finding_id}/comments/{comment_id}", response_model=CommentResponse)
async def update_finding_comment(finding_id: str, comment_id: int, comment_request: CommentRequest):
    """Update a comment for a finding"""
    # Decode URL-encoded finding ID
    import urllib.parse
    decoded_finding_id = urllib.parse.unquote(finding_id)
    
    comment = data_manager.update_finding_comment(
        comment_id=comment_id,
        comment=comment_request.comment,
        author=comment_request.author,
        is_internal=comment_request.is_internal
    )
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")
    return comment

@app.delete("/api/findings/{finding_id}/comments/{comment_id}")
async def delete_finding_comment(finding_id: str, comment_id: int):
    """Delete a comment for a finding"""
    # Decode URL-encoded finding ID
    import urllib.parse
    decoded_finding_id = urllib.parse.unquote(finding_id)
    
    success = data_manager.delete_finding_comment(comment_id)
    if not success:
        raise HTTPException(status_code=404, detail="Comment not found")
    return {"message": "Comment deleted successfully"}

@app.post("/api/findings/fetch")
async def manual_fetch():
    """Manually trigger a findings fetch"""
    try:
        scheduler.run_manual_fetch()
        return {"message": "Manual fetch triggered successfully"}
    except Exception as e:
        logger.error(f"Error in manual fetch: {e}")
        raise HTTPException(status_code=500, detail="Error triggering manual fetch")

@app.get("/api/scheduler/status", response_model=SchedulerStatusResponse)
async def get_scheduler_status():
    """Get scheduler status"""
    return scheduler.get_scheduler_status()

@app.get("/api/findings/export/csv")
async def export_findings_csv(
    severity: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    product_name: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None)
):
    """Export findings as CSV"""
    try:
        # Parse dates if provided
        start_dt = None
        end_dt = None
        if start_date:
            start_dt = datetime.strptime(start_date, "%Y-%m-%d")
        if end_date:
            end_dt = datetime.strptime(end_date, "%Y-%m-%d")
        
        findings = data_manager.get_findings(
            severity=severity,
            status=status,
            product_name=product_name,
            start_date=start_dt,
            end_date=end_dt,
            limit=10000  # Export more findings
        )
        
        csv_content = data_manager.export_findings_csv(findings)
        
        return StreamingResponse(
            io.StringIO(csv_content),
            media_type="text/csv",
            headers={"Content-Disposition": "attachment; filename=findings_export.csv"}
        )
    except Exception as e:
        logger.error(f"Error exporting findings: {e}")
        raise HTTPException(status_code=500, detail="Error exporting findings")

@app.get("/api/findings/export/json")
async def export_findings_json(
    severity: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    product_name: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None)
):
    """Export findings as JSON"""
    try:
        # Parse dates if provided
        start_dt = None
        end_dt = None
        if start_date:
            start_dt = datetime.strptime(start_date, "%Y-%m-%d")
        if end_date:
            end_dt = datetime.strptime(end_date, "%Y-%m-%d")
        
        findings = data_manager.get_findings(
            severity=severity,
            status=status,
            product_name=product_name,
            start_date=start_dt,
            end_date=end_dt,
            limit=10000  # Export more findings
        )
        
        # Convert findings to dict for JSON serialization
        findings_data = []
        for finding in findings:
            finding_dict = {
                "id": finding.id,
                "title": finding.title,
                "description": finding.description,
                "severity": finding.severity,
                "status": finding.status,
                "product_name": finding.product_name,
                "aws_account_id": finding.aws_account_id,
                "region": finding.region,
                "created_at": finding.created_at.isoformat() if finding.created_at else None,
                "updated_at": finding.updated_at.isoformat() if finding.updated_at else None,
                "workflow_status": finding.workflow_status,
                "compliance_status": finding.compliance_status,
                "verification_state": finding.verification_state,
                "is_archived": finding.is_archived
            }
            findings_data.append(finding_dict)
        
        return {
            "export_timestamp": datetime.utcnow().isoformat(),
            "findings_count": len(findings_data),
            "findings": findings_data
        }
    except Exception as e:
        logger.error(f"Error exporting findings: {e}")
        raise HTTPException(status_code=500, detail="Error exporting findings")

@app.get("/api/stats")
async def get_stats():
    """Get statistics about findings"""
    try:
        # Get basic stats
        all_findings = data_manager.get_findings(limit=10000)

        # Count by severity
        severity_counts = {}
        status_counts = {}
        product_counts = {}

        for finding in all_findings:
            # Severity counts
            severity = finding.severity or "UNKNOWN"
            severity_counts[severity] = severity_counts.get(severity, 0) + 1

            # Status counts
            status = finding.status or "UNKNOWN"
            status_counts[status] = status_counts.get(status, 0) + 1

            # Product counts
            product = finding.product_name or "UNKNOWN"
            product_counts[product] = product_counts.get(product, 0) + 1

        return {
            "total_findings": len(all_findings),
            "severity_distribution": severity_counts,
            "status_distribution": status_counts,
            "product_distribution": product_counts,
            "last_updated": datetime.utcnow().isoformat()
        }
    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        # Return empty stats instead of throwing error
        return {
            "total_findings": 0,
            "severity_distribution": {},
            "status_distribution": {},
            "product_distribution": {},
            "last_updated": datetime.utcnow().isoformat()
        }

@app.get("/api/debug/findings")
async def debug_findings():
    """Debug endpoint to check finding data"""
    try:
        findings = data_manager.get_findings(limit=5)
        debug_data = []
        
        for finding in findings:
            debug_data.append({
                "id": finding.id,
                "title": finding.title,
                "severity": finding.severity,
                "status": finding.status,
                "product_name": finding.product_name,
                "aws_account_id": finding.aws_account_id,
                "region": finding.region,
                "created_at": finding.created_at.isoformat() if finding.created_at else None,
                "updated_at": finding.updated_at.isoformat() if finding.updated_at else None,
                "workflow_status": finding.workflow_status,
                "compliance_status": finding.compliance_status,
                "verification_state": finding.verification_state,
                "description": finding.description[:100] + "..." if finding.description and len(finding.description) > 100 else finding.description
            })
        
        return {
            "total_findings": len(findings),
            "sample_findings": debug_data
        }
    except Exception as e:
        logger.error(f"Error in debug endpoint: {e}")
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=settings.host, port=settings.port) 