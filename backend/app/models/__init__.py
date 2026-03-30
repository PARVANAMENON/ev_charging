"""
Database models for EV Charging Slot Booking System

This module defines all database entities based on SRS requirements:
- User: Registered users and admins
- Vehicle: User vehicles (2-wheeler/4-wheeler)
- Station: EV charging stations
- Slot: Charging slots at stations
- Booking: User bookings for slots
"""

import mysql.connector
from mysql.connector import Error
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Tuple
import bcrypt

from ..config import Config


class DatabaseManager:
    """Handles database connection and schema management"""
    
    def __init__(self):
        self.config = {
            'host': Config.MYSQL_HOST,
            'user': Config.MYSQL_USER,
            'password': Config.MYSQL_PASSWORD,
            'database': Config.MYSQL_DATABASE
        }
        self.connection = None
    
    def connect(self) -> bool:
        """Establish database connection"""
        try:
            self.connection = mysql.connector.connect(**self.config)
            return True
        except Error as e:
            print(f"Database connection error: {e}")
            return False
    
    def create_database_and_schema(self) -> bool:
        """Create database and all tables if they don't exist"""
        try:
            # Connect without database to create it
            temp_config = self.config.copy()
            temp_config.pop('database', None)
            
            conn = mysql.connector.connect(**temp_config)
            cursor = conn.cursor()
            
            # Create database
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS {Config.MYSQL_DATABASE}")
            cursor.execute(f"USE {Config.MYSQL_DATABASE}")
            
            # Create tables
            self._create_users_table(cursor)
            self._create_vehicles_table(cursor)
            self._create_stations_table(cursor)
            self._create_slots_table(cursor)
            self._create_bookings_table(cursor)
            
            # Insert sample data
            self._insert_sample_data(cursor)
            
            conn.commit()
            cursor.close()
            conn.close()
            
            return True
            
        except Error as e:
            print(f"Database creation error: {e}")
            return False
    
    def _create_users_table(self, cursor):
        """Create users table"""
        query = """
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            user_type ENUM('user', 'admin') DEFAULT 'user',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_username (username),
            INDEX idx_email (email)
        ) ENGINE=InnoDB
        """
        cursor.execute(query)
    
    def _create_vehicles_table(self, cursor):
        """Create vehicles table"""
        query = """
        CREATE TABLE IF NOT EXISTS vehicles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            vehicle_type ENUM('2-wheeler', '4-wheeler') NOT NULL,
            license_plate VARCHAR(20) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            INDEX idx_user_id (user_id)
        ) ENGINE=InnoDB
        """
        cursor.execute(query)
    
    def _create_stations_table(self, cursor):
        """Create stations table"""
        query = """
        CREATE TABLE IF NOT EXISTS stations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            address TEXT NOT NULL,
            latitude DECIMAL(10, 8) NOT NULL,
            longitude DECIMAL(11, 8) NOT NULL,
            total_slots INT DEFAULT 4,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_location (latitude, longitude)
        ) ENGINE=InnoDB
        """
        cursor.execute(query)
    
    def _create_slots_table(self, cursor):
        """Create slots table"""
        query = """
        CREATE TABLE IF NOT EXISTS slots (
            id INT AUTO_INCREMENT PRIMARY KEY,
            station_id INT NOT NULL,
            slot_number INT NOT NULL,
            slot_type ENUM('2-wheeler', '4-wheeler') NOT NULL,
            is_available BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (station_id) REFERENCES stations(id) ON DELETE CASCADE,
            UNIQUE KEY unique_station_slot (station_id, slot_number),
            INDEX idx_station_id (station_id),
            INDEX idx_availability (is_available)
        ) ENGINE=InnoDB
        """
        cursor.execute(query)
    
    def _create_bookings_table(self, cursor):
        """Create bookings table"""
        query = """
        CREATE TABLE IF NOT EXISTS bookings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            slot_id INT NOT NULL,
            vehicle_id INT NOT NULL,
            start_time TIMESTAMP NOT NULL,
            end_time TIMESTAMP NOT NULL,
            status ENUM('active', 'cancelled', 'completed') DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (slot_id) REFERENCES slots(id) ON DELETE CASCADE,
            FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
            INDEX idx_user_id (user_id),
            INDEX idx_slot_id (slot_id),
            INDEX idx_time_range (start_time, end_time),
            INDEX idx_status (status)
        ) ENGINE=InnoDB
        """
        cursor.execute(query)
    
    def _insert_sample_data(self, cursor):
        """Insert sample stations and slots"""
        # Check if data already exists
        cursor.execute("SELECT COUNT(*) FROM stations")
        if cursor.fetchone()[0] > 0:
            return
        
        # Insert sample stations
        stations = [
            ('Central Charging Hub', '123 Main Street, Bangalore', 12.9716, 77.5946, 4),
            ('North EV Station', '456 Park Avenue, Bangalore', 13.0350, 77.5965, 6),
            ('South Charging Point', '789 Ring Road, Bangalore', 12.9081, 77.5476, 4)
        ]
        
        station_query = """
        INSERT INTO stations (name, address, latitude, longitude, total_slots) 
        VALUES (%s, %s, %s, %s, %s)
        """
        cursor.executemany(station_query, stations)
        
        # Get station IDs and create slots
        cursor.execute("SELECT id, total_slots FROM stations")
        stations_data = cursor.fetchall()
        
        slots_data = []
        for station_id, total_slots in stations_data:
            for slot_num in range(1, total_slots + 1):
                # Alternate between 2-wheeler and 4-wheeler slots
                slot_type = '2-wheeler' if slot_num % 2 == 0 else '4-wheeler'
                slots_data.append((station_id, slot_num, slot_type))
        
        slot_query = """
        INSERT INTO slots (station_id, slot_number, slot_type) 
        VALUES (%s, %s, %s)
        """
        cursor.executemany(slot_query, slots_data)

        # Create a default admin account if it does not exist
        cursor.execute("SELECT COUNT(*) FROM users WHERE username = %s", ('admin',))
        if cursor.fetchone()[0] == 0:
            admin_password_hash = bcrypt.hashpw('admin123'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            cursor.execute(
                "INSERT INTO users (username, email, password_hash, user_type) VALUES (%s, %s, %s, 'admin')",
                ('admin', 'admin@example.com', admin_password_hash)
            )

    def get_connection(self):
        """Get database connection"""
        try:
            if not self.connection:
                self.connect()
            elif not self.connection.is_connected():
                try:
                    self.connection.close()
                except Exception:
                    pass
                self.connection = None
                self.connect()
        except Exception as e:
            print(f"Database get_connection error: {e}")
            try:
                if self.connection:
                    self.connection.close()
            except Exception:
                pass
            self.connection = None
            self.connect()

        return self.connection
    
    def close(self):
        """Close database connection"""
        try:
            if self.connection and self.connection.is_connected():
                self.connection.close()
        except Exception:
            pass


class User:
    """User model for authentication and user management"""
    
    def __init__(self, db_manager: DatabaseManager):
        self.db = db_manager
    
    def create_user(self, username: str, email: str, password: str, user_type: str = 'user') -> bool:
        """Create a new user"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor()
            
            # Hash password
            password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            
            query = """
            INSERT INTO users (username, email, password_hash, user_type) 
            VALUES (%s, %s, %s, %s)
            """
            cursor.execute(query, (username, email, password_hash, user_type))
            conn.commit()
            cursor.close()
            
            return True
            
        except Error as e:
            print(f"User creation error: {e}")
            return False
    
    def authenticate_user(self, username: str, password: str) -> Optional[Dict]:
        """Authenticate user and return user data"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            query = """
            SELECT id, username, email, password_hash, user_type 
            FROM users WHERE username = %s
            """
            cursor.execute(query, (username,))
            user = cursor.fetchone()
            cursor.close()
            
            if user and bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
                # Remove password hash from returned data
                del user['password_hash']
                return user
            
            return None
            
        except Error as e:
            print(f"Authentication error: {e}")
            return None
    
    def get_user_by_id(self, user_id: int) -> Optional[Dict]:
        """Get user by ID"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            query = """
            SELECT id, username, email, user_type, created_at 
            FROM users WHERE id = %s
            """
            cursor.execute(query, (user_id,))
            user = cursor.fetchone()
            cursor.close()
            
            return user
            
        except Error as e:
            print(f"Get user error: {e}")
            return None


class Vehicle:
    """Vehicle model for user vehicles"""
    
    def __init__(self, db_manager: DatabaseManager):
        self.db = db_manager
    
    def add_vehicle(self, user_id: int, vehicle_type: str, license_plate: str) -> bool:
        """Add a vehicle for user"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor()
            
            query = """
            INSERT INTO vehicles (user_id, vehicle_type, license_plate) 
            VALUES (%s, %s, %s)
            """
            cursor.execute(query, (user_id, vehicle_type, license_plate))
            conn.commit()
            cursor.close()
            
            return True
            
        except Error as e:
            print(f"Vehicle creation error: {e}")
            return False
    
    def get_user_vehicles(self, user_id: int) -> List[Dict]:
        """Get all vehicles for a user"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            query = """
            SELECT id, vehicle_type, license_plate, created_at 
            FROM vehicles WHERE user_id = %s
            """
            cursor.execute(query, (user_id,))
            vehicles = cursor.fetchall()
            cursor.close()
            
            return vehicles
            
        except Error as e:
            print(f"Get vehicles error: {e}")
            return []


class Station:
    """Station model for charging stations"""
    
    def __init__(self, db_manager: DatabaseManager):
        self.db = db_manager
    
    def get_nearby_stations(self, latitude: float, longitude: float, radius_km: float = 10.0) -> List[Dict]:
        """Get stations within radius of user location"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            # Simple distance calculation (Haversine formula approximation)
            query = """
            SELECT id, name, address, latitude, longitude, total_slots,
                   (6371 * acos(cos(radians(%s)) * cos(radians(latitude)) * 
                    cos(radians(longitude) - radians(%s)) + sin(radians(%s)) * 
                    sin(radians(latitude)))) AS distance_km
            FROM stations
            HAVING distance_km < %s
            ORDER BY distance_km
            """
            cursor.execute(query, (latitude, longitude, latitude, radius_km))
            stations = cursor.fetchall()
            cursor.close()
            
            return stations
            
        except Error as e:
            print(f"Get nearby stations error: {e}")
            return []
    
    def get_station_by_id(self, station_id: int) -> Optional[Dict]:
        """Get station details by ID"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            query = """
            SELECT id, name, address, latitude, longitude, total_slots 
            FROM stations WHERE id = %s
            """
            cursor.execute(query, (station_id,))
            station = cursor.fetchone()
            cursor.close()
            
            return station
            
        except Error as e:
            print(f"Get station error: {e}")
            return None
    
    def add_station(self, name: str, address: str, latitude: float, longitude: float, total_slots: int = 4) -> bool:
        """Add a new charging station (admin only)"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor()
            
            query = """
            INSERT INTO stations (name, address, latitude, longitude, total_slots) 
            VALUES (%s, %s, %s, %s, %s)
            """
            cursor.execute(query, (name, address, latitude, longitude, total_slots))
            station_id = cursor.lastrowid
            
            # Create slots for the station
            for slot_num in range(1, total_slots + 1):
                slot_type = '2-wheeler' if slot_num % 2 == 0 else '4-wheeler'
                slot_query = """
                INSERT INTO slots (station_id, slot_number, slot_type) 
                VALUES (%s, %s, %s)
                """
                cursor.execute(slot_query, (station_id, slot_num, slot_type))
            
            conn.commit()
            cursor.close()
            
            return True
            
        except Error as e:
            print(f"Station creation error: {e}")
            return False

    def get_all_stations(self) -> List[Dict]:
        """Get all charging stations"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor(dictionary=True)
            query = """
            SELECT id, name, address, latitude, longitude, total_slots
            FROM stations
            ORDER BY name
            """
            cursor.execute(query)
            stations = cursor.fetchall()
            cursor.close()
            return stations
        except Error as e:
            print(f"Get all stations error: {e}")
            return []


class Slot:
    """Slot model for charging slots"""
    
    def __init__(self, db_manager: DatabaseManager):
        self.db = db_manager
    
    def get_available_slots(self, station_id: int, vehicle_type: str, start_time: datetime, end_time: datetime) -> List[Dict]:
        """Get available slots for a time period"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            query = """
            SELECT s.id, s.slot_number, s.slot_type
            FROM slots s
            WHERE s.station_id = %s 
            AND s.slot_type = %s 
            AND s.is_available = TRUE
            AND s.id NOT IN (
                SELECT b.slot_id 
                FROM bookings b 
                WHERE b.status = 'active'
                AND ((b.start_time <= %s AND b.end_time > %s)
                     OR (b.start_time < %s AND b.end_time >= %s)
                     OR (b.start_time >= %s AND b.end_time <= %s))
            )
            ORDER BY s.slot_number
            """
            cursor.execute(query, (station_id, vehicle_type, start_time, start_time, end_time, end_time, start_time, end_time))
            slots = cursor.fetchall()
            cursor.close()
            
            return slots
            
        except Error as e:
            print(f"Get available slots error: {e}")
            return []
    
    def get_slot_by_id(self, slot_id: int) -> Optional[Dict]:
        """Get slot details by ID"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            query = """
            SELECT s.*, st.name as station_name
            FROM slots s
            JOIN stations st ON s.station_id = st.id
            WHERE s.id = %s
            """
            cursor.execute(query, (slot_id,))
            slot = cursor.fetchone()
            cursor.close()
            
            return slot
            
        except Error as e:
            print(f"Get slot error: {e}")
            return None


class Booking:
    """Booking model for slot reservations"""
    
    def __init__(self, db_manager: DatabaseManager):
        self.db = db_manager
    
    def create_booking(self, user_id: int, slot_id: int, vehicle_id: int, start_time: datetime, end_time: datetime) -> bool:
        """Create a new booking"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor()
            
            # Check if slot is available for the time period
            check_query = """
            SELECT COUNT(*) as count
            FROM bookings 
            WHERE slot_id = %s 
            AND status = 'active'
            AND ((start_time <= %s AND end_time > %s)
                 OR (start_time < %s AND end_time >= %s)
                 OR (start_time >= %s AND end_time <= %s))
            """
            cursor.execute(check_query, (slot_id, start_time, start_time, end_time, end_time, start_time, end_time))
            count = cursor.fetchone()[0]
            
            if count > 0:
                return False  # Slot already booked
            
            # Create booking
            query = """
            INSERT INTO bookings (user_id, slot_id, vehicle_id, start_time, end_time) 
            VALUES (%s, %s, %s, %s, %s)
            """
            cursor.execute(query, (user_id, slot_id, vehicle_id, start_time, end_time))
            conn.commit()
            cursor.close()
            
            return True
            
        except Error as e:
            print(f"Booking creation error: {e}")
            return False
    
    def cancel_booking(self, booking_id: int, user_id: int) -> bool:
        """Cancel a booking"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor()
            
            query = """
            UPDATE bookings 
            SET status = 'cancelled' 
            WHERE id = %s AND user_id = %s
            """
            cursor.execute(query, (booking_id, user_id))
            conn.commit()
            affected_rows = cursor.rowcount
            cursor.close()
            
            return affected_rows > 0
            
        except Error as e:
            print(f"Booking cancellation error: {e}")
            return False
    
    def get_user_bookings(self, user_id: int) -> List[Dict]:
        """Get all bookings for a user"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            query = """
            SELECT b.id, b.start_time, b.end_time, b.status,
                   s.slot_number, s.slot_type,
                   st.id AS station_id, st.name as station_name, st.address,
                   v.vehicle_type, v.license_plate
            FROM bookings b
            JOIN slots s ON b.slot_id = s.id
            JOIN stations st ON s.station_id = st.id
            JOIN vehicles v ON b.vehicle_id = v.id
            WHERE b.user_id = %s
            ORDER BY b.start_time DESC
            """
            cursor.execute(query, (user_id,))
            bookings = cursor.fetchall()
            cursor.close()
            
            return bookings
            
        except Error as e:
            print(f"Get user bookings error: {e}")
            return []
    
    def get_all_bookings(self) -> List[Dict]:
        """Get all bookings (admin only)"""
        try:
            conn = self.db.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            query = """
            SELECT b.id, b.start_time, b.end_time, b.status,
                   u.username, u.email,
                   s.slot_number, s.slot_type,
                   st.name as station_name, st.address,
                   v.vehicle_type, v.license_plate
            FROM bookings b
            JOIN users u ON b.user_id = u.id
            JOIN slots s ON b.slot_id = s.id
            JOIN stations st ON s.station_id = st.id
            JOIN vehicles v ON b.vehicle_id = v.id
            ORDER BY b.start_time DESC
            """
            cursor.execute(query)
            bookings = cursor.fetchall()
            cursor.close()
            
            return bookings
            
        except Error as e:
            print(f"Get all bookings error: {e}")
            return []
