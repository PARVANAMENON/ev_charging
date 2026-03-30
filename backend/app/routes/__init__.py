"""
API Routes for EV Charging Slot Booking System

This module implements all RESTful API endpoints based on SRS requirements:
- User authentication (register, login)
- Vehicle management
- Station search and management
- Slot availability and booking
- Admin functionality
"""

from flask import Flask, request, jsonify, session
from flask_cors import CORS
from flask_session import Session
from datetime import datetime, timedelta
from functools import wraps
import os

from ..config import Config
from ..models import DatabaseManager, User, Vehicle, Station, Slot, Booking


def create_app():
    """Create and configure Flask application"""
    app = Flask(__name__)
    
    # Configuration
    app.config.from_object(Config)
    
    # Initialize extensions
    CORS(app, origins=Config.CORS_ORIGINS, supports_credentials=True)
    Session(app)
    
    # Initialize database
    db_manager = DatabaseManager()
    db_manager.create_database_and_schema()
    
    # Initialize models
    user_model = User(db_manager)
    vehicle_model = Vehicle(db_manager)
    station_model = Station(db_manager)
    slot_model = Slot(db_manager)
    booking_model = Booking(db_manager)
    
    # Decorators
    def login_required(f):
        """Decorator to require login"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if 'user_id' not in session:
                return jsonify({'error': 'Authentication required'}), 401
            return f(*args, **kwargs)
        return decorated_function
    
    def admin_required(f):
        """Decorator to require admin access"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if 'user_id' not in session or session.get('user_type') != 'admin':
                return jsonify({'error': 'Admin access required'}), 403
            return f(*args, **kwargs)
        return decorated_function
    
    # Utility functions
    def get_current_user():
        """Get current logged-in user"""
        if 'user_id' in session:
            return user_model.get_user_by_id(session['user_id'])
        return None
    
    # Authentication Routes
    @app.route('/api/register', methods=['POST'])
    def register():
        """User registration endpoint"""
        try:
            data = request.get_json()
            
            # Validation
            if not data or not all(k in data for k in ('username', 'email', 'password')):
                return jsonify({'error': 'Missing required fields'}), 400
            
            username = data['username'].strip()
            email = data['email'].strip()
            password = data['password']
            
            if len(username) < 3 or len(password) < 6:
                return jsonify({'error': 'Username must be at least 3 characters, password at least 6'}), 400
            
            # Create user
            success = user_model.create_user(username, email, password)
            
            if success:
                created_user = user_model.authenticate_user(username, password)
                return jsonify({
                    'message': 'User registered successfully',
                    'user': created_user
                }), 201
            else:
                return jsonify({'error': 'Username or email already exists'}), 400
                
        except Exception as e:
            return jsonify({'error': 'Registration failed'}), 500
    
    @app.route('/api/login', methods=['POST'])
    def login():
        """User login endpoint"""
        try:
            data = request.get_json()
            
            if not data or not all(k in data for k in ('username', 'password')):
                return jsonify({'error': 'Missing username or password'}), 400
            
            username = data['username'].strip()
            password = data['password']
            
            # Authenticate
            user = user_model.authenticate_user(username, password)
            
            if user:
                session['user_id'] = user['id']
                session['username'] = user['username']
                session['user_type'] = user['user_type']
                
                return jsonify({
                    'message': 'Login successful',
                    'user': user
                }), 200
            else:
                return jsonify({'error': 'Invalid credentials'}), 401
                
        except Exception as e:
            return jsonify({'error': 'Login failed'}), 500
    
    @app.route('/api/logout', methods=['POST'])
    def logout():
        """User logout endpoint"""
        session.clear()
        return jsonify({'message': 'Logout successful'}), 200
    
    @app.route('/api/current-user', methods=['GET'])
    def current_user():
        """Get current logged-in user"""
        user = get_current_user()
        if user:
            return jsonify({'user': user}), 200
        return jsonify({'error': 'Not logged in'}), 401
    
    # Vehicle Routes
    @app.route('/api/vehicles', methods=['GET'])
    @login_required
    def get_vehicles():
        """Get user's vehicles"""
        vehicles = vehicle_model.get_user_vehicles(session['user_id'])
        return jsonify({'vehicles': vehicles}), 200
    
    @app.route('/api/vehicles', methods=['POST'])
    @login_required
    def add_vehicle():
        """Add a new vehicle"""
        try:
            data = request.get_json()
            
            if not data or not all(k in data for k in ('vehicle_type', 'license_plate')):
                return jsonify({'error': 'Missing required fields'}), 400
            
            vehicle_type = data['vehicle_type']
            license_plate = data['license_plate'].strip().upper()
            
            if vehicle_type not in ['2-wheeler', '4-wheeler']:
                return jsonify({'error': 'Invalid vehicle type'}), 400
            
            success = vehicle_model.add_vehicle(session['user_id'], vehicle_type, license_plate)
            
            if success:
                return jsonify({'message': 'Vehicle added successfully'}), 201
            else:
                return jsonify({'error': 'Failed to add vehicle'}), 400
                
        except Exception as e:
            return jsonify({'error': 'Failed to add vehicle'}), 500
    
    # Station Routes
    @app.route('/api/stations/nearby', methods=['GET'])
    def get_nearby_stations():
        """Get nearby stations based on location"""
        try:
            latitude = request.args.get('latitude', type=float)
            longitude = request.args.get('longitude', type=float)
            radius = request.args.get('radius', 10.0, type=float)
            
            if not latitude or not longitude:
                return jsonify({'error': 'Latitude and longitude required'}), 400
            
            stations = station_model.get_nearby_stations(latitude, longitude, radius)
            return jsonify({'stations': stations}), 200
            
        except Exception as e:
            return jsonify({'error': 'Failed to get stations'}), 500
    
    @app.route('/api/stations/<int:station_id>', methods=['GET'])
    def get_station(station_id):
        """Get station details"""
        station = station_model.get_station_by_id(station_id)
        
        if station:
            return jsonify({'station': station}), 200
        else:
            return jsonify({'error': 'Station not found'}), 404

    @app.route('/api/stations', methods=['GET'])
    def get_stations():
        """Get list of all stations"""
        stations = station_model.get_all_stations()
        return jsonify({'stations': stations}), 200
    
    @app.route('/api/stations', methods=['POST'])
    @admin_required
    def add_station():
        """Add a new charging station (admin only)"""
        try:
            data = request.get_json()
            
            if not data or not all(k in data for k in ('name', 'address', 'latitude', 'longitude')):
                return jsonify({'error': 'Missing required fields'}), 400
            
            name = data['name'].strip()
            address = data['address'].strip()
            latitude = data['latitude']
            longitude = data['longitude']
            total_slots = data.get('total_slots', 4)
            
            success = station_model.add_station(name, address, latitude, longitude, total_slots)
            
            if success:
                return jsonify({'message': 'Station added successfully'}), 201
            else:
                return jsonify({'error': 'Failed to add station'}), 400
                
        except Exception as e:
            return jsonify({'error': 'Failed to add station'}), 500
    
    # Slot Routes
    @app.route('/api/slots/available', methods=['GET'])
    def get_available_slots():
        """Get available slots for a station and time period"""
        try:
            station_id = request.args.get('station_id', type=int)
            vehicle_type = request.args.get('vehicle_type')
            start_time_str = request.args.get('start_time')
            end_time_str = request.args.get('end_time')
            
            if not all([station_id, vehicle_type, start_time_str, end_time_str]):
                return jsonify({'error': 'Missing required parameters'}), 400
            
            if vehicle_type not in ['2-wheeler', '4-wheeler']:
                return jsonify({'error': 'Invalid vehicle type'}), 400
            
            try:
                start_time = datetime.fromisoformat(start_time_str.replace('Z', '+00:00'))
                end_time = datetime.fromisoformat(end_time_str.replace('Z', '+00:00'))
            except ValueError:
                return jsonify({'error': 'Invalid datetime format'}), 400
            
            slots = slot_model.get_available_slots(station_id, vehicle_type, start_time, end_time)
            return jsonify({'slots': slots}), 200
            
        except Exception as e:
            return jsonify({'error': 'Failed to get available slots'}), 500
    
    # Booking Routes
    @app.route('/api/bookings', methods=['POST'])
    @login_required
    def create_booking():
        """Create a new booking"""
        try:
            data = request.get_json()
            
            if not data or not all(k in data for k in ('slot_id', 'vehicle_id', 'start_time', 'end_time')):
                return jsonify({'error': 'Missing required fields'}), 400
            
            slot_id = data['slot_id']
            vehicle_id = data['vehicle_id']
            
            try:
                start_time = datetime.fromisoformat(data['start_time'].replace('Z', '+00:00'))
                end_time = datetime.fromisoformat(data['end_time'].replace('Z', '+00:00'))
            except ValueError:
                return jsonify({'error': 'Invalid datetime format'}), 400
            
            if start_time >= end_time:
                return jsonify({'error': 'End time must be after start time'}), 400
            
            if start_time <= datetime.now():
                return jsonify({'error': 'Start time must be in the future'}), 400
            
            success = booking_model.create_booking(session['user_id'], slot_id, vehicle_id, start_time, end_time)
            
            if success:
                return jsonify({'message': 'Booking created successfully'}), 201
            else:
                return jsonify({'error': 'Slot not available for selected time'}), 400
                
        except Exception as e:
            return jsonify({'error': 'Failed to create booking'}), 500
    
    @app.route('/api/bookings', methods=['GET'])
    @login_required
    def get_bookings():
        """Get user's bookings"""
        bookings = booking_model.get_user_bookings(session['user_id'])
        return jsonify({'bookings': bookings}), 200
    
    @app.route('/api/bookings/<int:booking_id>', methods=['DELETE'])
    @login_required
    def cancel_booking(booking_id):
        """Cancel a booking"""
        success = booking_model.cancel_booking(booking_id, session['user_id'])
        
        if success:
            return jsonify({'message': 'Booking cancelled successfully'}), 200
        else:
            return jsonify({'error': 'Booking not found or cannot be cancelled'}), 404
    
    @app.route('/api/admin/bookings', methods=['GET'])
    @admin_required
    def get_all_bookings():
        """Get all bookings (admin only)"""
        bookings = booking_model.get_all_bookings()
        return jsonify({'bookings': bookings}), 200
    
    # Health check endpoint
    @app.route('/api/health', methods=['GET'])
    def health_check():
        """Health check endpoint"""
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'database': 'connected' if db_manager.get_connection().is_connected() else 'disconnected'
        }), 200
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Endpoint not found'}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({'error': 'Internal server error'}), 500
    
    return app


if __name__ == '__main__':
    app = create_app()
    app.run(debug=Config.DEBUG, host='0.0.0.0', port=Config.PORT)
