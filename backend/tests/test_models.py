"""
Database Model Tests

This module contains test cases for the database models and their functionality.
"""

import pytest
import mysql.connector
from datetime import datetime, timedelta
from backend.app.models import DatabaseManager, User, Vehicle, Station, Slot, Booking


@pytest.fixture
def db_manager():
    """Create test database manager"""
    db = DatabaseManager()
    db.create_database_and_schema()
    return db


@pytest.fixture
def sample_user(db_manager):
    """Create sample user for testing"""
    user_model = User(db_manager)
    user_id = user_model.create_user('testuser', 'test@example.com', 'testpass')
    return user_id


class TestDatabaseManager:
    """Test database manager functionality"""
    
    def test_database_creation(self, db_manager):
        """Test database and table creation"""
        assert db_manager.connect() is True
        
        # Test that tables exist by trying to query them
        conn = db_manager.get_connection()
        cursor = conn.cursor()
        
        # Check if users table exists
        cursor.execute("SHOW TABLES LIKE 'users'")
        assert cursor.fetchone() is not None
        
        cursor.close()


class TestUserModel:
    """Test user model functionality"""
    
    def test_create_user(self, db_manager):
        """Test user creation"""
        user_model = User(db_manager)
        
        success = user_model.create_user('newuser', 'new@example.com', 'password123')
        assert success is True
        
        # Verify user exists
        user = user_model.authenticate_user('newuser', 'password123')
        assert user is not None
        assert user['username'] == 'newuser'
    
    def test_authenticate_user_valid(self, db_manager):
        """Test user authentication with valid credentials"""
        user_model = User(db_manager)
        user_model.create_user('authuser', 'auth@example.com', 'authpass')
        
        user = user_model.authenticate_user('authuser', 'authpass')
        assert user is not None
        assert user['username'] == 'authuser'
    
    def test_authenticate_user_invalid(self, db_manager):
        """Test user authentication with invalid credentials"""
        user_model = User(db_manager)
        
        user = user_model.authenticate_user('nonexistent', 'wrongpass')
        assert user is None
    
    def test_get_user_by_id(self, db_manager):
        """Test getting user by ID"""
        user_model = User(db_manager)
        user_model.create_user('getuser', 'get@example.com', 'getpass')
        
        user = user_model.authenticate_user('getuser', 'getpass')
        retrieved_user = user_model.get_user_by_id(user['id'])
        
        assert retrieved_user is not None
        assert retrieved_user['username'] == 'getuser'


class TestVehicleModel:
    """Test vehicle model functionality"""
    
    def test_add_vehicle(self, db_manager):
        """Test adding a vehicle"""
        user_model = User(db_manager)
        vehicle_model = Vehicle(db_manager)
        
        # Create user first
        user_model.create_user('vehicleuser', 'vehicle@example.com', 'pass')
        user = user_model.authenticate_user('vehicleuser', 'pass')
        
        # Add vehicle
        success = vehicle_model.add_vehicle(user['id'], '2-wheeler', 'VEH123')
        assert success is True
        
        # Verify vehicle exists
        vehicles = vehicle_model.get_user_vehicles(user['id'])
        assert len(vehicles) == 1
        assert vehicles[0]['license_plate'] == 'VEH123'
    
    def test_get_user_vehicles(self, db_manager):
        """Test getting user vehicles"""
        user_model = User(db_manager)
        vehicle_model = Vehicle(db_manager)
        
        # Create user
        user_model.create_user('multiuser', 'multi@example.com', 'pass')
        user = user_model.authenticate_user('multiuser', 'pass')
        
        # Add multiple vehicles
        vehicle_model.add_vehicle(user['id'], '2-wheeler', 'VEH1')
        vehicle_model.add_vehicle(user['id'], '4-wheeler', 'VEH2')
        
        vehicles = vehicle_model.get_user_vehicles(user['id'])
        assert len(vehicles) == 2


class TestStationModel:
    """Test station model functionality"""
    
    def test_get_nearby_stations(self, db_manager):
        """Test getting nearby stations"""
        station_model = Station(db_manager)
        
        stations = station_model.get_nearby_stations(12.9716, 77.5946, 50)
        assert len(stations) > 0
        
        # Verify station structure
        station = stations[0]
        assert 'name' in station
        assert 'address' in station
        assert 'distance_km' in station
    
    def test_add_station(self, db_manager):
        """Test adding a station"""
        station_model = Station(db_manager)
        
        success = station_model.add_station(
            'Test Station',
            'Test Address',
            13.0,
            77.0,
            4
        )
        assert success is True
        
        # Verify station exists
        stations = station_model.get_nearby_stations(13.0, 77.0, 1)
        assert len(stations) > 0
        assert any(s['name'] == 'Test Station' for s in stations)


class TestSlotModel:
    """Test slot model functionality"""
    
    def test_get_available_slots(self, db_manager):
        """Test getting available slots"""
        slot_model = Slot(db_manager)
        
        start_time = datetime.now() + timedelta(hours=1)
        end_time = datetime.now() + timedelta(hours=2)
        
        slots = slot_model.get_available_slots(1, '4-wheeler', start_time, end_time)
        assert isinstance(slots, list)
        
        if slots:  # If slots are available
            slot = slots[0]
            assert 'slot_number' in slot
            assert 'slot_type' in slot


class TestBookingModel:
    """Test booking model functionality"""
    
    def test_create_booking(self, db_manager):
        """Test creating a booking"""
        # Setup
        user_model = User(db_manager)
        vehicle_model = Vehicle(db_manager)
        slot_model = Slot(db_manager)
        booking_model = Booking(db_manager)
        
        # Create user and vehicle
        user_model.create_user('bookinguser', 'booking@example.com', 'pass')
        user = user_model.authenticate_user('bookinguser', 'pass')
        vehicle_model.add_vehicle(user['id'], '4-wheeler', 'BOOK123')
        
        # Get available slots
        start_time = datetime.now() + timedelta(hours=1)
        end_time = datetime.now() + timedelta(hours=2)
        slots = slot_model.get_available_slots(1, '4-wheeler', start_time, end_time)
        
        if slots:
            # Create booking
            success = booking_model.create_booking(
                user['id'],
                slots[0]['id'],
                1,  # Assuming first vehicle ID
                start_time,
                end_time
            )
            assert success is True
    
    def test_cancel_booking(self, db_manager):
        """Test cancelling a booking"""
        # This would require creating a booking first
        # For now, test that the method exists and handles non-existent bookings
        booking_model = Booking(db_manager)
        
        success = booking_model.cancel_booking(999, 1)  # Non-existent booking
        assert success is False
    
    def test_get_user_bookings(self, db_manager):
        """Test getting user bookings"""
        booking_model = Booking(db_manager)
        
        bookings = booking_model.get_user_bookings(1)
        assert isinstance(bookings, list)


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
