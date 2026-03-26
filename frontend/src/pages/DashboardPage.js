/**
 * Dashboard Page Component
 * 
 * This component displays the user dashboard with overview information,
 * quick actions, and recent bookings.
 */

import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import apiService from '../services/api';

const DashboardPage = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [vehicles, setVehicles] = useState([]);
  const [recentBookings, setRecentBookings] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        const [vehiclesResponse, bookingsResponse] = await Promise.all([
          apiService.getVehicles(),
          apiService.getBookings()
        ]);
        
        setVehicles(vehiclesResponse.vehicles || []);
        setRecentBookings((bookingsResponse.bookings || []).slice(0, 3));
      } catch (error) {
        console.error('Failed to fetch dashboard data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  if (isLoading) {
    return <div className="loading-spinner"><div className="spinner"></div></div>;
  }

  return (
    <div>
      <h1>Dashboard</h1>
      <p>Welcome back, {user?.username}!</p>
      
      {/* Quick Actions */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '20px', margin: '30px 0' }}>
        <div className="card">
          <div className="card-title">Find Charging Stations</div>
          <div className="card-content">
            <p>Locate nearby EV charging stations based on your location.</p>
            <button 
              className="button button-primary" 
              onClick={() => navigate('/stations')}
              style={{ marginTop: '15px' }}
            >
              Browse Stations
            </button>
          </div>
        </div>
        
        <div className="card">
          <div className="card-title">Manage Vehicles</div>
          <div className="card-content">
            <p>You have {vehicles.length} vehicle(s) registered.</p>
            <button 
              className="button" 
              onClick={() => navigate('/stations')}
              style={{ marginTop: '15px' }}
            >
              Add Vehicle
            </button>
          </div>
        </div>
        
        <div className="card">
          <div className="card-title">View Bookings</div>
          <div className="card-content">
            <p>View and manage your charging slot bookings.</p>
            <button 
              className="button" 
              onClick={() => navigate('/bookings')}
              style={{ marginTop: '15px' }}
            >
              My Bookings
            </button>
          </div>
        </div>
      </div>
      
      {/* Recent Bookings */}
      {recentBookings.length > 0 && (
        <div className="card">
          <div className="card-title">Recent Bookings</div>
          <div className="card-content">
            <div className="booking-list">
              {recentBookings.map(booking => (
                <div key={booking.id} className="booking-item">
                  <div className="booking-header">
                    <strong>{booking.station_name}</strong>
                    <span className={`badge ${booking.status}`}>
                      {booking.status}
                    </span>
                  </div>
                  <div className="booking-details">
                    <p>Slot: {booking.slot_number} ({booking.slot_type})</p>
                    <p>Vehicle: {booking.license_plate}</p>
                    <p>
                      {new Date(booking.start_time).toLocaleString()} - {' '}
                      {new Date(booking.end_time).toLocaleString()}
                    </p>
                  </div>
                </div>
              ))}
            </div>
            {recentBookings.length >= 3 && (
              <button 
                className="button" 
                onClick={() => navigate('/bookings')}
                style={{ marginTop: '15px' }}
              >
                View All Bookings
              </button>
            )}
          </div>
        </div>
      )}
      
      {/* No Bookings */}
      {recentBookings.length === 0 && (
        <div className="card">
          <div className="card-title">No Bookings Yet</div>
          <div className="card-content">
            <p>You haven't made any bookings yet. Start by finding a charging station near you.</p>
            <button 
              className="button button-primary" 
              onClick={() => navigate('/stations')}
              style={{ marginTop: '15px' }}
            >
              Find Stations
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default DashboardPage;
