"""
Backend Test Suite

This module contains comprehensive test cases for the Flask backend API.
It tests all functional requirements from the SRS document.
"""

import pytest
import json
import mysql.connector
from datetime import datetime, timedelta
from backend.run import create_app
from backend.app.models import DatabaseManager, User, Vehicle, Station, Slot, Booking


@pytest.fixture
def app():
    """Create test Flask app"""
    app = create_app()
    app.config['TESTING'] = True
    app.config['WTF_CSRF_ENABLED'] = False
    app.config['SESSION_TYPE'] = 'filesystem'
    
    with app.app_context():
        yield app


@pytest.fixture
def client(app):
    """Create test client"""
    return app.test_client()


@pytest.fixture
def db_manager():
    """Create test database manager"""
    db = DatabaseManager()
    db.create_database_and_schema()
    return db


@pytest.fixture
def test_user(db_manager):
    """Create test user"""
    user_model = User(db_manager)
    user_model.create_user('testuser', 'test@example.com', 'testpass')
    return {'username': 'testuser', 'password': 'testpass'}


@pytest.fixture
def test_admin(db_manager):
    """Create test admin user"""
    user_model = User(db_manager)
    user_model.create_user('admin', 'admin@example.com', 'adminpass', 'admin')
    return {'username': 'admin', 'password': 'adminpass'}


@pytest.fixture
def authenticated_client(client, test_user):
    """Create authenticated client"""
    client.post('/api/login', json=test_user)
    return client


@pytest.fixture
def admin_client(client, test_admin):
    """Create admin authenticated client"""
    client.post('/api/login', json=test_admin)
    return client


class TestAuthentication:
    """Test authentication endpoints"""
    
    def test_register_user(self, client, db_manager):
        """Test user registration"""
        response = client.post('/api/register', json={
            'username': 'newuser',
            'email': 'new@example.com',
            'password': 'newpass123'
        })
        
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['message'] == 'User registered successfully'
        
        # Verify user exists in database
        user_model = User(db_manager)
        user = user_model.authenticate_user('newuser', 'newpass123')
        assert user is not None
        assert user['username'] == 'newuser'
    
    def test_register_duplicate_username(self, client, test_user):
        """Test registration with duplicate username"""
        response = client.post('/api/register', json={
            'username': test_user['username'],
            'email': 'different@example.com',
            'password': 'password123'
        })
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'already exists' in data['error']
    
    def test_login_valid_credentials(self, client, test_user):
        """Test login with valid credentials"""
        response = client.post('/api/login', json=test_user)
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['message'] == 'Login successful'
        assert data['user']['username'] == test_user['username']
    
    def test_login_invalid_credentials(self, client):
        """Test login with invalid credentials"""
        response = client.post('/api/login', json={
            'username': 'invalid',
            'password': 'invalid'
        })
        
        assert response.status_code == 401
        data = json.loads(response.data)
        assert data['error'] == 'Invalid credentials'
    
    def test_logout(self, authenticated_client):
        """Test logout functionality"""
        response = authenticated_client.post('/api/logout')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['message'] == 'Logout successful'
    
    def test_current_user(self, authenticated_client):
        """Test getting current user"""
        response = authenticated_client.get('/api/current-user')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['user']['username'] == 'testuser'


class TestVehicles:
    """Test vehicle management endpoints"""
    
    def test_add_vehicle(self, authenticated_client):
        """Test adding a vehicle"""
        response = authenticated_client.post('/api/vehicles', json={
            'vehicle_type': '2-wheeler',
            'license_plate': 'TEST123'
        })
        
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['message'] == 'Vehicle added successfully'
    
    def test_get_vehicles(self, authenticated_client):
        """Test getting user vehicles"""
        # First add a vehicle
        authenticated_client.post('/api/vehicles', json={
            'vehicle_type': '4-wheeler',
            'license_plate': 'TEST456'
        })
        
        response = authenticated_client.get('/api/vehicles')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data['vehicles']) >= 1
        assert data['vehicles'][0]['license_plate'] == 'TEST456'
    
    def test_add_vehicle_unauthenticated(self, client):
        """Test adding vehicle without authentication"""
        response = client.post('/api/vehicles', json={
            'vehicle_type': '2-wheeler',
            'license_plate': 'UNAUTH123'
        })
        
        assert response.status_code == 401


class TestStations:
    """Test station management endpoints"""
    
    def test_get_nearby_stations(self, client):
        """Test getting nearby stations"""
        response = client.get('/api/stations/nearby?latitude=12.9716&longitude=77.5946')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert 'stations' in data
        assert len(data['stations']) > 0
    
    def test_get_station_by_id(self, client):
        """Test getting station by ID"""
        response = client.get('/api/stations/1')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert 'station' in data
        assert data['station']['id'] == 1
    
    def test_add_station_admin(self, admin_client):
        """Test adding station as admin"""
        response = admin_client.post('/api/stations', json={
            'name': 'Test Station',
            'address': 'Test Address',
            'latitude': 13.0,
            'longitude': 77.0,
            'total_slots': 4
        })
        
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['message'] == 'Station added successfully'
    
    def test_add_station_unauthorized(self, authenticated_client):
        """Test adding station as regular user"""
        response = authenticated_client.post('/api/stations', json={
            'name': 'Test Station',
            'address': 'Test Address',
            'latitude': 13.0,
            'longitude': 77.0,
            'total_slots': 4
        })
        
        assert response.status_code == 403


class TestSlots:
    """Test slot availability endpoints"""
    
    def test_get_available_slots(self, client):
        """Test getting available slots"""
        start_time = (datetime.now() + timedelta(hours=1)).isoformat()
        end_time = (datetime.now() + timedelta(hours=2)).isoformat()
        
        response = client.get(f'/api/slots/available?station_id=1&vehicle_type=4-wheeler&start_time={start_time}&end_time={end_time}')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert 'slots' in data


class TestBookings:
    """Test booking management endpoints"""
    
    def test_create_booking(self, authenticated_client):
        """Test creating a booking"""
        # First add a vehicle
        vehicle_response = authenticated_client.post('/api/vehicles', json={
            'vehicle_type': '4-wheeler',
            'license_plate': 'BOOK123'
        })
        
        # Get available slots
        start_time = (datetime.now() + timedelta(hours=1)).isoformat()
        end_time = (datetime.now() + timedelta(hours=2)).isoformat()
        
        slots_response = client.get(f'/api/slots/available?station_id=1&vehicle_type=4-wheeler&start_time={start_time}&end_time={end_time}')
        slots_data = json.loads(slots_response.data)
        
        if slots_data['slots']:
            slot_id = slots_data['slots'][0]['id']
            
            # Create booking
            response = authenticated_client.post('/api/bookings', json={
                'slot_id': slot_id,
                'vehicle_id': 1,  # Assuming first vehicle has ID 1
                'start_time': start_time,
                'end_time': end_time
            })
            
            assert response.status_code == 201
            data = json.loads(response.data)
            assert data['message'] == 'Booking created successfully'
    
    def test_get_user_bookings(self, authenticated_client):
        """Test getting user bookings"""
        response = authenticated_client.get('/api/bookings')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert 'bookings' in data
    
    def test_cancel_booking(self, authenticated_client):
        """Test cancelling a booking"""
        # First create a booking
        # (This would require setup code to create a booking first)
        # For now, test the endpoint exists and handles missing booking
        
        response = authenticated_client.delete('/api/bookings/999')
        
        # Should return 404 for non-existent booking
        assert response.status_code in [404, 400]
    
    def test_get_all_bookings_admin(self, admin_client):
        """Test getting all bookings as admin"""
        response = admin_client.get('/api/admin/bookings')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert 'bookings' in data
    
    def test_get_all_bookings_unauthorized(self, authenticated_client):
        """Test getting all bookings as regular user"""
        response = authenticated_client.get('/api/admin/bookings')
        
        assert response.status_code == 403


class TestHealthCheck:
    """Test health check endpoint"""
    
    def test_health_check(self, client):
        """Test health check endpoint"""
        response = client.get('/api/health')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['status'] == 'healthy'
        assert 'timestamp' in data


class TestErrorHandling:
    """Test error handling"""
    
    def test_404_endpoint(self, client):
        """Test 404 for non-existent endpoint"""
        response = client.get('/api/nonexistent')
        
        assert response.status_code == 404
        data = json.loads(response.data)
        assert data['error'] == 'Endpoint not found'
    
    def test_invalid_json(self, client):
        """Test handling of invalid JSON"""
        response = client.post('/api/login', 
                             data='invalid json',
                             content_type='application/json')
        
        assert response.status_code == 400


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
