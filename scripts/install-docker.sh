#!/bin/bash

# Universal Docker Installation Script
# Works on Ubuntu, Amazon Linux, CentOS, RHEL, Debian, and other Linux distributions

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

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        OS=SuSE
    elif [ -f /etc/redhat-release ]; then
        OS=RedHat
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    echo "$OS"
}

# Function to check if Docker is already installed
check_docker_installed() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        print_warning "Docker is already installed (version $DOCKER_VERSION)"
        read -p "Do you want to reinstall Docker? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Skipping Docker installation"
            return 0
        fi
    fi
    return 1
}

# Function to install Docker on Ubuntu/Debian
install_docker_ubuntu() {
    print_status "Installing Docker on Ubuntu/Debian..."
    
    # Update package index
    sudo apt-get update
    
    # Install prerequisites
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    print_success "Docker installed successfully on Ubuntu/Debian"
}

# Function to install Docker on Amazon Linux/RHEL/CentOS
install_docker_amazon() {
    print_status "Installing Docker on Amazon Linux/RHEL/CentOS..."
    
    # Update system
    sudo yum update -y
    
    # Install Docker
    sudo yum install -y docker
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_success "Docker installed successfully on Amazon Linux/RHEL/CentOS"
}

# Function to install Docker Compose
install_docker_compose() {
    print_status "Installing Docker Compose..."
    
    # Check if Docker Compose is already installed
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        print_warning "Docker Compose is already installed (version $COMPOSE_VERSION)"
        return 0
    fi
    
    # Download and install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for compatibility
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    print_success "Docker Compose installed successfully"
}

# Function to setup Docker user group
setup_docker_group() {
    print_status "Setting up Docker user group..."
    
    # Create docker group if it doesn't exist
    sudo groupadd docker 2>/dev/null || true
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    print_success "User added to docker group"
    print_warning "You need to log out and log back in for group changes to take effect"
    print_warning "Or run: newgrp docker"
}

# Function to start Docker service
start_docker_service() {
    print_status "Starting Docker service..."
    
    # Start Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Wait for Docker to be ready
    sleep 5
    
    print_success "Docker service started and enabled"
}

# Function to verify Docker installation
verify_docker_installation() {
    print_status "Verifying Docker installation..."
    
    # Test Docker
    if docker run hello-world > /dev/null 2>&1; then
        print_success "Docker is working correctly"
    else
        print_error "Docker verification failed"
        return 1
    fi
    
    # Test Docker Compose
    if docker-compose --version > /dev/null 2>&1; then
        print_success "Docker Compose is working correctly"
    else
        print_error "Docker Compose verification failed"
        return 1
    fi
    
    # Show versions
    echo ""
    print_status "Installed versions:"
    docker --version
    docker-compose --version
    
    return 0
}

# Function to install additional tools
install_additional_tools() {
    print_status "Installing additional useful tools..."
    
    # Detect distribution
    DISTRO=$(detect_distro)
    
    if [[ "$DISTRO" == *"Ubuntu"* ]] || [[ "$DISTRO" == *"Debian"* ]]; then
        # Install useful tools on Ubuntu/Debian
        sudo apt-get install -y \
            curl \
            wget \
            git \
            htop \
            tree \
            unzip \
            jq \
            net-tools
    elif [[ "$DISTRO" == *"Amazon"* ]] || [[ "$DISTRO" == *"RedHat"* ]] || [[ "$DISTRO" == *"CentOS"* ]]; then
        # Install useful tools on Amazon Linux/RHEL/CentOS
        sudo yum install -y \
            curl \
            wget \
            git \
            htop \
            tree \
            unzip \
            jq \
            net-tools
    fi
    
    print_success "Additional tools installed"
}

# Function to show post-installation instructions
show_post_install_instructions() {
    echo ""
    print_success "Docker installation completed successfully!"
    echo ""
    print_status "Post-installation steps:"
    echo "1. Log out and log back in, or run: newgrp docker"
    echo "2. Test Docker: docker run hello-world"
    echo "3. Test Docker Compose: docker-compose --version"
    echo ""
    print_status "Next steps for Security Hub Dashboard:"
    echo "1. Clone the repository: git clone <repository-url>"
    echo "2. Navigate to directory: cd Security-Hub"
    echo "3. Copy environment file: cp env.docker .env"
    echo "4. Edit configuration: nano .env"
    echo "5. Start the application: make quick-start"
    echo ""
    print_status "Useful Docker commands:"
    echo "- List containers: docker ps"
    echo "- List images: docker images"
    echo "- View logs: docker logs <container>"
    echo "- Stop all containers: docker stop \$(docker ps -q)"
    echo "- Remove all containers: docker rm \$(docker ps -aq)"
    echo "- Clean up images: docker system prune -a"
}

# Main installation function
main() {
    echo "🐳 Universal Docker Installation Script"
    echo "========================================"
    echo ""
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root"
        exit 1
    fi
    
    # Detect distribution
    DISTRO=$(detect_distro)
    print_status "Detected distribution: $DISTRO"
    
    # Check if Docker is already installed
    if check_docker_installed; then
        print_status "Docker is already installed, proceeding with setup..."
    else
        # Install Docker based on distribution
        if [[ "$DISTRO" == *"Ubuntu"* ]] || [[ "$DISTRO" == *"Debian"* ]]; then
            install_docker_ubuntu
        elif [[ "$DISTRO" == *"Amazon"* ]] || [[ "$DISTRO" == *"RedHat"* ]] || [[ "$DISTRO" == *"CentOS"* ]]; then
            install_docker_amazon
        else
            print_error "Unsupported distribution: $DISTRO"
            print_status "Trying automatic installation..."
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            rm get-docker.sh
        fi
    fi
    
    # Install Docker Compose
    install_docker_compose
    
    # Setup Docker group
    setup_docker_group
    
    # Start Docker service
    start_docker_service
    
    # Install additional tools
    install_additional_tools
    
    # Verify installation
    if verify_docker_installation; then
        show_post_install_instructions
    else
        print_error "Docker installation verification failed"
        exit 1
    fi
}

# Handle command line arguments
case "${1:-install}" in
    "install")
        main
        ;;
    "verify")
        verify_docker_installation
        ;;
    "help"|"-h"|"--help")
        echo "Universal Docker Installation Script"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  install    Install Docker and Docker Compose (default)"
        echo "  verify     Verify Docker installation"
        echo "  help       Show this help message"
        echo ""
        echo "This script works on:"
        echo "- Ubuntu/Debian"
        echo "- Amazon Linux"
        echo "- RHEL/CentOS"
        echo "- Other Linux distributions"
        ;;
    *)
        print_error "Unknown command: $1"
        exit 1
        ;;
esac 