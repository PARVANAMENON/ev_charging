/**
 * API Service Module
 * 
 * This module handles all communication with the Flask backend API.
 * It provides a centralized way to make HTTP requests and handle responses.
 */

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

class ApiService {
  constructor() {
    this.baseURL = API_BASE_URL;
  }

  /**
   * Generic request method with error handling
   */
  async request(endpoint, options = {}) {
    try {
      const url = `${this.baseURL}${endpoint}`;
      const config = {
        headers: {
          'Content-Type': 'application/json',
          ...options.headers,
        },
        credentials: 'include', // For session cookies
        ...options,
      };

      const response = await fetch(url, config);
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || `HTTP error! status: ${response.status}`);
      }

      return data;
    } catch (error) {
      console.error('API request failed:', error);
      throw error;
    }
  }

  /**
   * Authentication endpoints
   */
  async register(userData) {
    return this.request('/register', {
      method: 'POST',
      body: JSON.stringify(userData),
    });
  }

  async login(credentials) {
    return this.request('/login', {
      method: 'POST',
      body: JSON.stringify(credentials),
    });
  }

  async logout() {
    return this.request('/logout', {
      method: 'POST',
    });
  }

  async getCurrentUser() {
    return this.request('/current-user');
  }

  /**
   * Vehicle endpoints
   */
  async getVehicles() {
    return this.request('/vehicles');
  }

  async addVehicle(vehicleData) {
    return this.request('/vehicles', {
      method: 'POST',
      body: JSON.stringify(vehicleData),
    });
  }

  /**
   * Station endpoints
   */
  async getNearbyStations(latitude, longitude, radius = 10) {
    const params = new URLSearchParams({
      latitude: latitude.toString(),
      longitude: longitude.toString(),
      radius: radius.toString(),
    });
    return this.request(`/stations/nearby?${params}`);
  }

  async getStation(stationId) {
    return this.request(`/stations/${stationId}`);
  }

  async getStations() {
    return this.request('/stations');
  }

  async addStation(stationData) {
    return this.request('/stations', {
      method: 'POST',
      body: JSON.stringify(stationData),
    });
  }

  /**
   * Slot endpoints
   */
  async getAvailableSlots(stationId, vehicleType, startTime, endTime) {
    const params = new URLSearchParams({
      station_id: stationId.toString(),
      vehicle_type: vehicleType,
      start_time: startTime,
      end_time: endTime,
    });
    return this.request(`/slots/available?${params}`);
  }

  /**
   * Booking endpoints
   */
  async createBooking(bookingData) {
    return this.request('/bookings', {
      method: 'POST',
      body: JSON.stringify(bookingData),
    });
  }

  async getBookings() {
    return this.request('/bookings');
  }

  async cancelBooking(bookingId) {
    return this.request(`/bookings/${bookingId}`, {
      method: 'DELETE',
    });
  }

  /**
   * Admin endpoints
   */
  async getAllBookings() {
    return this.request('/admin/bookings');
  }

  /**
   * Health check
   */
  async healthCheck() {
    return this.request('/health');
  }
}

// Create a singleton instance
const apiService = new ApiService();

export default apiService;
