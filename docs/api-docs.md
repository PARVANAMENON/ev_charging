# EV Charging Slot Booking System - API Documentation

## Overview

This document describes the RESTful API endpoints for the EV Charging Slot Booking System. The API follows REST conventions and uses JSON for all request/response bodies.

**Base URL**: `http://localhost:5000/api`

## Authentication

The API uses session-based authentication. Users must log in to access protected endpoints.

- Login creates a session cookie
- Session cookie is automatically included in subsequent requests
- Logout clears the session

## Response Format

All API responses follow this format:

**Success Response**:
```json
{
  "data": { ... },
  "message": "Operation successful"
}
```

**Error Response**:
```json
{
  "error": "Error description"
}
```

## Endpoints

### Authentication

#### POST /register
Register a new user account.

**Request Body**:
```json
{
  "username": "string (3-50 chars)",
  "email": "string (valid email)",
  "password": "string (6+ chars)"
}
```

**Response**:
```json
{
  "message": "User registered successfully"
}
```

#### POST /login
Authenticate user and create session.

**Request Body**:
```json
{
  "username": "string",
  "password": "string"
}
```

**Response**:
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "user_type": "user",
    "created_at": "2026-03-26T10:00:00Z"
  }
}
```

#### POST /logout
Clear user session.

**Response**:
```json
{
  "message": "Logout successful"
}
```

#### GET /current-user
Get current logged-in user information.

**Response**:
```json
{
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "user_type": "user",
    "created_at": "2026-03-26T10:00:00Z"
  }
}
```

### Vehicles

#### GET /vehicles
Get all vehicles for the current user.

**Authentication**: Required

**Response**:
```json
{
  "vehicles": [
    {
      "id": 1,
      "vehicle_type": "4-wheeler",
      "license_plate": "ABC123",
      "created_at": "2026-03-26T10:00:00Z"
    }
  ]
}
```

#### POST /vehicles
Add a new vehicle for the current user.

**Authentication**: Required

**Request Body**:
```json
{
  "vehicle_type": "2-wheeler|4-wheeler",
  "license_plate": "string"
}
```

**Response**:
```json
{
  "message": "Vehicle added successfully"
}
```

### Stations

#### GET /stations/nearby
Get nearby charging stations based on location.

**Query Parameters**:
- `latitude` (float, required): Latitude coordinate
- `longitude` (float, required): Longitude coordinate  
- `radius` (float, optional): Search radius in km (default: 10)

**Response**:
```json
{
  "stations": [
    {
      "id": 1,
      "name": "Central Charging Hub",
      "address": "123 Main Street, Bangalore",
      "latitude": 12.9716,
      "longitude": 77.5946,
      "total_slots": 4,
      "distance_km": 2.5
    }
  ]
}
```

#### GET /stations/{station_id}
Get station details by ID.

**Response**:
```json
{
  "station": {
    "id": 1,
    "name": "Central Charging Hub",
    "address": "123 Main Street, Bangalore",
    "latitude": 12.9716,
    "longitude": 77.5946,
    "total_slots": 4
  }
}
```

#### POST /stations
Add a new charging station.

**Authentication**: Admin required

**Request Body**:
```json
{
  "name": "string",
  "address": "string",
  "latitude": "float",
  "longitude": "float",
  "total_slots": "integer (default: 4)"
}
```

**Response**:
```json
{
  "message": "Station added successfully"
}
```

### Slots

#### GET /slots/available
Get available slots for a station and time period.

**Query Parameters**:
- `station_id` (int, required): Station ID
- `vehicle_type` (string, required): "2-wheeler" or "4-wheeler"
- `start_time` (string, required): ISO 8601 datetime
- `end_time` (string, required): ISO 8601 datetime

**Response**:
```json
{
  "slots": [
    {
      "id": 1,
      "slot_number": 1,
      "slot_type": "4-wheeler"
    }
  ]
}
```

### Bookings

#### POST /bookings
Create a new booking.

**Authentication**: Required

**Request Body**:
```json
{
  "slot_id": "integer",
  "vehicle_id": "integer",
  "start_time": "string (ISO 8601)",
  "end_time": "string (ISO 8601)"
}
```

**Response**:
```json
{
  "message": "Booking created successfully"
}
```

#### GET /bookings
Get all bookings for the current user.

**Authentication**: Required

**Response**:
```json
{
  "bookings": [
    {
      "id": 1,
      "start_time": "2026-03-26T15:00:00Z",
      "end_time": "2026-03-26T17:00:00Z",
      "status": "active",
      "slot_number": 1,
      "slot_type": "4-wheeler",
      "station_name": "Central Charging Hub",
      "station_address": "123 Main Street, Bangalore",
      "vehicle_type": "4-wheeler",
      "license_plate": "ABC123"
    }
  ]
}
```

#### DELETE /bookings/{booking_id}
Cancel a booking.

**Authentication**: Required

**Response**:
```json
{
  "message": "Booking cancelled successfully"
}
```

#### GET /admin/bookings
Get all bookings in the system.

**Authentication**: Admin required

**Response**:
```json
{
  "bookings": [
    {
      "id": 1,
      "start_time": "2026-03-26T15:00:00Z",
      "end_time": "2026-03-26T17:00:00Z",
      "status": "active",
      "username": "john_doe",
      "email": "john@example.com",
      "slot_number": 1,
      "slot_type": "4-wheeler",
      "station_name": "Central Charging Hub",
      "station_address": "123 Main Street, Bangalore",
      "vehicle_type": "4-wheeler",
      "license_plate": "ABC123"
    }
  ]
}
```

### System

#### GET /health
Health check endpoint.

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2026-03-26T10:00:00Z",
  "database": "connected"
}
```

## Error Codes

- `400`: Bad Request - Invalid input data
- `401`: Unauthorized - Authentication required
- `403`: Forbidden - Insufficient permissions
- `404`: Not Found - Resource not found
- `500`: Internal Server Error - Server error

## Data Types

### User Types
- `user`: Regular user
- `admin`: Administrator user

### Vehicle Types
- `2-wheeler`: Two-wheeler vehicles
- `4-wheeler`: Four-wheeler vehicles

### Booking Statuses
- `active`: Currently active booking
- `cancelled`: Cancelled booking
- `completed`: Completed booking

## Date/Time Format

All datetime fields use ISO 8601 format: `YYYY-MM-DDTHH:MM:SSZ`

Example: `2026-03-26T15:30:00Z`

## Rate Limiting

Currently no rate limiting is implemented. Consider adding for production use.

## CORS

The API supports CORS for `http://localhost:3000` (React development server).

## Security Considerations

- Passwords are hashed using bcrypt
- Session-based authentication
- SQL injection prevention through parameterized queries
- Input validation on all endpoints
