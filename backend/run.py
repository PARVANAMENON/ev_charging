"""
Flask application entry point

This module starts the EV Charging Slot Booking System backend server.
It initializes the database, creates all tables, and starts the Flask API server.
"""

import sys
import os

# Add the app directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.routes import create_app
from app.config import Config


def main():
    """Main function to start the Flask application"""
    print("Starting EV Charging Slot Booking System Backend...")
    print(f"Database: {Config.MYSQL_DATABASE}")
    print(f"Server: http://localhost:{Config.PORT}")
    
    app = create_app()
    app.run(debug=Config.DEBUG, host='0.0.0.0', port=Config.PORT)


if __name__ == '__main__':
    main()
