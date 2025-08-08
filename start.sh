#!/bin/bash

# Security Hub Application Startup Script
# For local development and testing

echo "🚀 Starting Security Hub Application..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📚 Installing dependencies..."
pip install -r requirements.txt

# Create data directory if it doesn't exist
mkdir -p data logs

# Run tests
echo "🧪 Running tests..."
python test_app.py

# Start the application
echo "🌐 Starting application..."
echo "   Access the dashboard at: http://localhost:8000"
echo "   API documentation at: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop the application"

python main.py 