# 🔒 AWS Security Hub Findings Dashboard

## 📖 What is this?

This is a **Security Monitoring Dashboard** that automatically collects and displays security issues (called "findings") from your AWS account. Think of it as a **security alarm system** that continuously monitors your cloud infrastructure and shows you what needs attention.

### 🎯 What does it do?

- **🔍 Automatically scans** your AWS account for security problems **across all regions**
- **📊 Displays findings** in an easy-to-read dashboard
- **💬 Allows you to add notes** to each security issue
- **📈 Tracks changes** over time to see if problems are getting better or worse
- **📋 Lets you filter and search** through security issues
- **📤 Exports data** for reports and analysis
- **🌍 Multi-region support** - automatically discovers and monitors all AWS regions

## 🏗️ How it works (Simple Explanation)

### 1. **Data Collection** 📥
- The application connects to AWS Security Hub (AWS's security monitoring service)
- It automatically discovers all available AWS regions in your account
- It checks for new security findings every 24 hours **across all regions** in efficient batches
- It collects information like:
  - What the security issue is
  - How serious it is (Critical, High, Medium, Low)
  - Which AWS service is affected
  - Which AWS region it's in
  - When it was discovered
  - Current status (Active, Resolved, etc.)

### 2. **Data Storage** 💾
- All findings are stored in a PostgreSQL database
- This creates a permanent record of all security issues
- You can see the history of how issues changed over time
- Your notes and comments are also saved

### 3. **Web Dashboard** 🌐
- A user-friendly web interface shows all the data
- You can filter by severity, status, region, etc.
- Click on any finding to see detailed information
- Add comments and notes to track your progress

## 🚀 Quick Start

### Prerequisites
- An AWS account with Security Hub enabled
- A Linux server (Ubuntu, Amazon Linux, etc.)
- Docker and Docker Compose installed

### Step 1: Set up AWS Permissions

Create an IAM role with these permissions:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "securityhub:GetFindings",
                "securityhub:BatchGetFindings",
                "securityhub:ListFindings"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::your-backup-bucket/*"
        }
    ]
}
```

### Step 2: Configure the Application

Create a `.env` file:
```bash
# AWS Configuration
AWS_REGION=us-east-1
S3_BUCKET_NAME=your-backup-bucket
S3_PREFIX=security-hub-backups/

# Database Configuration
DATABASE_URL=postgresql://username:password@localhost:5432/security_hub

# Application Settings
POLLING_INTERVAL_MINUTES=30
HOST=0.0.0.0
PORT=8000
```

### Step 3: Deploy

```bash
# Clone the repository
git clone <repository-url>
cd Security-Hub

# Copy your .env file
cp .env.example .env
# Edit .env with your settings

# Deploy using Docker
./scripts/deploy.sh
```

### Step 4: Access the Dashboard

Open your browser and go to: `http://your-server-ip:8000`

## 📊 Understanding the Dashboard

### Main Dashboard
- **Statistics Cards**: Shows total findings, critical issues, etc.
- **Findings Table**: Lists all security issues with filters
- **Auto-refresh**: Updates automatically every 30 seconds

### Finding Details
When you click on a finding, you'll see:
- **Basic Information**: ID, title, severity, status
- **Additional Details**: AWS account, region, compliance status
- **Description**: What the security issue is about
- **Comments**: Your notes and observations
- **History**: How the issue has changed over time

### Filters Available
- **Severity**: Critical, High, Medium, Low, Informational
- **Status**: Active, Archived
- **Product**: Which AWS service is affected
- **Workflow Status**: NEW, NOTIFIED, RESOLVED, SUPPRESSED
- **Region**: Which AWS region
- **Account**: Which AWS account (if multiple)
- **Compliance**: Compliance status
- **Date Range**: When the issue was found

## 🔧 Technical Architecture

### Components

1. **FastAPI Backend** (`main.py`)
   - Provides REST API endpoints
   - Handles web requests
   - Manages data flow

2. **Data Manager** (`data_manager.py`)
   - Handles database operations
   - Stores and retrieves findings
   - Manages comments and history

3. **Security Hub Client** (`security_hub_client.py`)
   - Connects to AWS Security Hub across all regions
   - Fetches security findings with batch processing
   - Handles AWS API calls efficiently

4. **Scheduler** (`scheduler.py`)
   - Runs automatic data collection every 24 hours
   - Manages polling intervals and batch processing
   - Handles background tasks with progress logging

5. **Frontend** (`static/js/app.js`, `templates/index.html`)
   - User interface
   - Real-time updates
   - Filtering and search

### Data Flow

```
AWS Security Hub → Security Hub Client → Data Manager → PostgreSQL Database
                                                      ↓
Web Dashboard ← FastAPI Backend ← Data Manager ← PostgreSQL Database
```

### Database Schema

**Findings Table:**
- `id`: Unique finding identifier
- `title`: Finding title
- `description`: Detailed description
- `severity`: Critical, High, Medium, Low, Informational
- `status`: Active, Archived
- `product_name`: AWS service name
- `aws_account_id`: AWS account ID
- `region`: AWS region
- `workflow_status`: Current workflow state
- `compliance_status`: Compliance information
- `created_at`: When found
- `updated_at`: Last updated

**Comments Table:**
- `id`: Comment ID
- `finding_id`: Reference to finding
- `author`: Who wrote the comment
- `comment`: Comment text
- `is_internal`: Internal note flag
- `created_at`: When created

**History Table:**
- `id`: History record ID
- `finding_id`: Reference to finding
- `timestamp`: When change occurred
- `changes`: What changed (JSON)

## 🛠️ Maintenance and Operations

### Monitoring
- Check application logs: `docker-compose logs -f security-hub-app`
- Monitor database: `docker-compose logs -f security-hub-db`
- Check scheduler status: Visit `/api/scheduler/status`

### Backup
- Database backups are stored in PostgreSQL
- Optional S3 backup for findings data
- Comments and history are preserved

### Updates
```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

## 🔍 Troubleshooting

### Common Issues

1. **Container showing as unhealthy**
   - Check if multi-region processing is causing issues: Set `ENABLE_MULTI_REGION=false` in your `.env` file
   - Verify AWS credentials and permissions
   - Check application logs: `docker-compose logs -f security-hub-app`
   - Try manual fetch: `curl -X POST http://localhost:8000/api/findings/fetch`

2. **No findings showing**
   - Check AWS Security Hub is enabled
   - Verify IAM permissions
   - Check application logs

3. **Database connection issues**
   - Verify PostgreSQL is running
   - Check DATABASE_URL in .env
   - Restart containers

3. **Filters not working**
   - Ensure latest code is deployed
   - Check browser console for errors
   - Verify filter parameters

### Logs and Debugging
```bash
# View application logs
docker-compose logs security-hub-app

# View database logs
docker-compose logs security-hub-db

# Check API health
curl http://localhost:8000/api/test/health

# Test finding retrieval
curl http://localhost:8000/api/findings?limit=1
```

## 📈 Features and Capabilities

### ✅ What it does well
- **Real-time monitoring** of security issues
- **Comprehensive filtering** and search
- **Comment system** for collaboration
- **History tracking** for audit trails
- **Export capabilities** for reporting
- **Responsive design** for mobile/desktop

### 🔄 Automation
- **Automatic data collection** every 24 hours with efficient batch processing
- **Multi-region batch processing** (3 regions at a time) to avoid overwhelming AWS APIs
- **Configurable multi-region processing** (can be disabled via `ENABLE_MULTI_REGION=false`)
- **Resource optimization** with timeouts and pagination limits
- **Background processing** of findings
- **Auto-refresh** of dashboard
- **Scheduled backups** (if configured)

### 📊 Reporting
- **CSV export** of findings
- **JSON export** for integration
- **Filtered exports** by criteria
- **Historical data** analysis

## 🤝 Contributing

This application is designed to be:
- **Easy to deploy** with Docker
- **Simple to configure** with environment variables
- **Extensible** for additional features
- **Well-documented** for maintenance

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review application logs
3. Verify configuration settings
4. Test API endpoints manually

## 🔐 Security Considerations

- **IAM roles** with minimal required permissions
- **Database security** with proper credentials
- **Network access** control via firewall
- **Regular updates** for security patches
- **Backup strategy** for data protection

---

**🎯 Goal**: Make AWS security monitoring accessible, understandable, and actionable for everyone in your organization. 