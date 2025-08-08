#!/bin/bash

# AWS Security Hub Findings Dashboard - Complete Deployment Script
# Platform-independent deployment automation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
REPO_URL=""
DEPLOY_DIR="$HOME/security-hub"
PROFILE="default"
SKIP_DOCKER_INSTALL=false
SKIP_SETUP=false

# Function to show usage
show_usage() {
    echo "AWS Security Hub Findings Dashboard - Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --repo URL        Repository URL to clone"
    echo "  -d, --dir DIR         Deployment directory (default: ~/security-hub)"
    echo "  -p, --profile PROFILE Deployment profile (default, dev, monitoring, nginx, traefik)"
    echo "  --skip-docker         Skip Docker installation"
    echo "  --skip-setup          Skip initial setup"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Profiles:"
    echo "  default               Basic production setup"

    echo ""
    echo "Examples:"
    echo "  $0 -r https://github.com/user/security-hub.git"

    echo "  $0 -r https://github.com/user/security-hub.git -d /opt/security-hub"
}

# Function to parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--repo)
                REPO_URL="$2"
                shift 2
                ;;
            -d|--dir)
                DEPLOY_DIR="$2"
                shift 2
                ;;
            -p|--profile)
                PROFILE="$2"
                shift 2
                ;;
            --skip-docker)
                SKIP_DOCKER_INSTALL=true
                shift
                ;;
            --skip-setup)
                SKIP_SETUP=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root"
        exit 1
    fi
    
    # Check available memory
    MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    MEMORY_GB=$((MEMORY_KB / 1024 / 1024))
    
    if [ $MEMORY_GB -lt 4 ]; then
        print_warning "Low memory detected: ${MEMORY_GB}GB (recommended: 4GB+)"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Memory: ${MEMORY_GB}GB"
    fi
    
    # Check available disk space
    DISK_SPACE=$(df -BG "$DEPLOY_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $DISK_SPACE -lt 20 ]; then
        print_warning "Low disk space: ${DISK_SPACE}GB (recommended: 20GB+)"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Disk space: ${DISK_SPACE}GB"
    fi
    
    # Check internet connectivity
    if ! curl -s --max-time 10 https://www.google.com > /dev/null; then
        print_error "No internet connectivity detected"
        exit 1
    fi
    
    print_success "System requirements check passed"
}

# Function to install Docker
install_docker() {
    if [ "$SKIP_DOCKER_INSTALL" = true ]; then
        print_status "Skipping Docker installation"
        return 0
    fi
    
    print_status "Installing Docker..."
    
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        print_warning "Docker is already installed"
        read -p "Reinstall Docker? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # Run Docker installation script
    if [ -f "scripts/install-docker.sh" ]; then
        chmod +x scripts/install-docker.sh
        ./scripts/install-docker.sh
    else
        # Fallback to automatic installation
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        
        # Add user to docker group
        sudo usermod -aG docker $USER
        
        # Start Docker service
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    
    # Apply group changes
    newgrp docker
    
    print_success "Docker installation completed"
}

# Function to clone repository
clone_repository() {
    if [ -z "$REPO_URL" ]; then
        print_error "Repository URL is required. Use -r option."
        exit 1
    fi
    
    print_status "Cloning repository..."
    
    # Create deployment directory
    mkdir -p "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
    
    # Clone repository
    if [ -d ".git" ]; then
        print_warning "Repository already exists, pulling latest changes..."
        git pull
    else
        git clone "$REPO_URL" .
    fi
    
    print_success "Repository cloned successfully"
}

# Function to setup environment
setup_environment() {
    if [ "$SKIP_SETUP" = true ]; then
        print_status "Skipping environment setup"
        return 0
    fi
    
    print_status "Setting up environment..."
    
    # Copy environment template
    if [ -f "env.docker" ]; then
        cp env.docker .env
        print_success "Environment file created"
    else
        print_error "Environment template not found"
        exit 1
    fi
    
    # Make scripts executable
    chmod +x scripts/*.sh 2>/dev/null || true
    
    # Create necessary directories
    mkdir -p data logs config
    mkdir -p nginx/ssl traefik
    
    print_success "Environment setup completed"
}

# Function to configure application
configure_application() {
    print_status "Configuring application..."
    
    # Get server IP
    SERVER_IP=$(curl -s http://checkip.amazonaws.com || hostname -I | awk '{print $1}')
    
    print_status "Server IP: $SERVER_IP"
    print_status "Deployment directory: $DEPLOY_DIR"
    print_status "Profile: $PROFILE"
    
    # Show configuration options
    echo ""
    print_status "Current configuration:"
    cat .env | grep -E "^(AWS_REGION|APP_PORT|POLLING_INTERVAL_MINUTES)" | head -10
    
    echo ""
    print_warning "You can edit the configuration file (.env) before starting the application"
    read -p "Edit configuration now? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v nano > /dev/null; then
            nano .env
        elif command -v vim > /dev/null; then
            vim .env
        else
            print_error "No text editor found. Please edit .env manually"
        fi
    fi
}

# Function to deploy application
deploy_application() {
    print_status "Deploying application with profile: $PROFILE"
    
    # Build and start services
    docker-compose up -d --build
    
    print_success "Application deployed successfully"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Wait for services to start
    sleep 10
    
    # Check container status
    if docker-compose ps | grep -q "Up"; then
        print_success "All containers are running"
    else
        print_error "Some containers failed to start"
        docker-compose ps
        exit 1
    fi
    
    # Check application health
    if curl -f http://localhost:8000/api/stats > /dev/null 2>&1; then
        print_success "Application is responding"
    else
        print_warning "Application health check failed (may still be starting)"
    fi
    
    # Show service URLs
    SERVER_IP=$(curl -s http://checkip.amazonaws.com || hostname -I | awk '{print $1}')
    
    echo ""
    print_success "Deployment completed successfully!"
    echo ""
    print_status "Service URLs:"
    echo "  Dashboard: http://$SERVER_IP:8000"
    echo "  API Docs: http://$SERVER_IP:8000/docs"
    


    esac
    
    echo ""
    print_status "Management commands:"
    echo "  View logs: docker-compose logs -f"
    echo "  Stop services: docker-compose down"
    echo "  Restart services: docker-compose restart"
    echo "  Check status: docker-compose ps"
}

# Function to setup firewall
setup_firewall() {
    print_status "Setting up firewall..."
    
    # Check if ufw is available
    if command -v ufw > /dev/null; then
        # Allow application port
        sudo ufw allow 8000/tcp
        

        

        
        # Enable firewall
        echo "y" | sudo ufw enable
        
        print_success "Firewall configured"
    else
        print_warning "UFW not available, skipping firewall configuration"
    fi
}

# Function to setup SSL certificates
setup_ssl() {
    if [ "$PROFILE" = "nginx" ] || [ "$PROFILE" = "traefik" ]; then
        print_status "Setting up SSL certificates..."
        
        # Generate self-signed certificates
        if [ -f "Makefile" ]; then
            make ssl-generate
        else
            mkdir -p nginx/ssl
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout nginx/ssl/key.pem \
                -out nginx/ssl/cert.pem \
                -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
        fi
        
        print_success "SSL certificates generated"
    fi
}



# Function to show post-deployment instructions
show_post_deployment_instructions() {
    echo ""
    print_success "🎉 Deployment completed successfully!"
    echo ""
    print_status "Next steps:"
    echo "1. Configure AWS credentials/role for Security Hub access"
    echo "2. Access the dashboard at: http://$SERVER_IP:8000"
    echo "3. Review and customize the configuration in .env"
    echo "4. Configure domain and SSL certificates for production"
    echo ""
    print_status "Useful commands:"
    echo "  View logs: docker-compose logs -f"
    echo "  Check status: docker-compose ps"
    echo "  Restart: docker-compose restart"
    echo "  Stop: docker-compose down"

    echo "  Health check: make health"
    echo ""
    print_status "Configuration file: $DEPLOY_DIR/.env"
    print_status "Logs directory: $DEPLOY_DIR/logs"
    print_status "Data directory: $DEPLOY_DIR/data"

}

# Main deployment function
main() {
    echo "🚀 AWS Security Hub Findings Dashboard - Complete Deployment"
    echo "============================================================"
    echo ""
    
    # Parse command line arguments
    parse_args "$@"
    
    # Check requirements
    check_requirements
    
    # Install Docker
    install_docker
    
    # Clone repository
    clone_repository
    
    # Setup environment
    setup_environment
    
    # Configure application
    configure_application
    
    # Setup SSL certificates
    setup_ssl
    
    # Deploy application
    deploy_application
    
    # Verify deployment
    verify_deployment
    
    # Setup firewall
    setup_firewall
    

    
    # Show post-deployment instructions
    show_post_deployment_instructions
}

# Run main function with all arguments
main "$@" 