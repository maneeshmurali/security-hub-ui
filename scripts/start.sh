#!/bin/bash

# AWS Security Hub Findings Dashboard - Docker Startup Script
# This script provides a complete automated deployment solution

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if Docker Compose is available
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose and try again."
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Function to create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p data logs config
    mkdir -p nginx/ssl traefik
    mkdir -p scripts
    
    print_success "Directories created"
}

# Function to setup environment file
setup_environment() {
    if [ ! -f .env ]; then
        print_status "Creating .env file from template..."
        cp env.docker .env
        print_success ".env file created. Please review and modify as needed."
        print_warning "You may want to edit the .env file before continuing."
        read -p "Press Enter to continue or Ctrl+C to edit .env file..."
    else
        print_success ".env file already exists"
    fi
}

# Function to build and start services
start_services() {
    local profile=$1
    
    print_status "Building and starting services with profile: $profile"
    
    if [ "$profile" = "dev" ]; then
        docker-compose --profile dev up -d --build

    elif [ "$profile" = "nginx" ]; then
        docker-compose --profile nginx up -d --build
    elif [ "$profile" = "traefik" ]; then
        docker-compose --profile traefik up -d --build
    else
        docker-compose up -d --build
    fi
    
    print_success "Services started successfully"
}

# Function to check service health
check_health() {
    print_status "Checking service health..."
    
    # Wait for services to be ready
    sleep 10
    
    # Check main application
    if curl -f http://localhost:8000/api/stats > /dev/null 2>&1; then
        print_success "Main application is healthy"
    else
        print_warning "Main application health check failed"
    fi
    
    # Check Redis
    if docker exec security-hub-redis redis-cli ping > /dev/null 2>&1; then
        print_success "Redis is healthy"
    else
        print_warning "Redis health check failed"
    fi
}

# Function to show service status
show_status() {
    print_status "Service Status:"
    docker-compose ps
    
    echo ""
    print_status "Service URLs:"
    echo "  Main Application: http://localhost:8000"
    echo "  API Documentation: http://localhost:8000/docs"
    

    
    # Check if reverse proxy is enabled
    if docker-compose ps | grep -q nginx; then
        echo "  Nginx: http://localhost:80"
    fi
    
    if docker-compose ps | grep -q traefik; then
        echo "  Traefik Dashboard: http://localhost:8080"
    fi
}

# Function to show logs
show_logs() {
    print_status "Showing logs for main application..."
    docker-compose logs -f security-hub-app
}

# Function to stop services
stop_services() {
    print_status "Stopping services..."
    docker-compose down
    print_success "Services stopped"
}

# Function to restart services
restart_services() {
    print_status "Restarting services..."
    docker-compose restart
    print_success "Services restarted"
}

# Function to clean up
cleanup() {
    print_status "Cleaning up Docker resources..."
    docker-compose down -v --remove-orphans
    docker system prune -f
    print_success "Cleanup completed"
}



# Function to show help
show_help() {
    echo "AWS Security Hub Findings Dashboard - Docker Management Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  start [profile]    Start services (default, dev, monitoring, nginx, traefik)"
    echo "  stop               Stop all services"
    echo "  restart            Restart all services"
    echo "  status             Show service status and URLs"
    echo "  logs               Show application logs"
    echo "  health             Check service health"
    echo "  cleanup            Clean up Docker resources"
    echo "  setup              Initial setup (create directories, .env file)"
    echo "  help               Show this help message"
    echo ""
    echo "Profiles:"
    echo "  default            Production setup with basic services"
    echo "  dev                Development setup with hot reloading"
    echo "  nginx              Production setup with Nginx reverse proxy"
    echo "  traefik            Production setup with Traefik reverse proxy"
    echo ""
    echo "Examples:"
    echo "  $0 setup"
    echo "  $0 start"
    echo "  $0 start dev"
    echo "  $0 status"
}

# Main script logic
case "${1:-start}" in
    "start")
        profile=${2:-default}
        check_docker
        check_docker_compose
        setup_environment
        start_services "$profile"
        check_health
        show_status
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        restart_services
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "health")
        check_health
        ;;

    "cleanup")
        cleanup
        ;;
    "setup")
        check_docker
        check_docker_compose
        create_directories
        setup_environment
        print_success "Setup completed successfully"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac 