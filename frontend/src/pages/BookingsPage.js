/**
 * Bookings Page Component
 * 
 * This component displays all user bookings with options to view details
 * and cancel active bookings.
 */

import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import apiService from '../services/api';

const BookingsPage = () => {
  const navigate = useNavigate();
  const [bookings, setBookings] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [cancellingId, setCancellingId] = useState(null);

  useEffect(() => {
    fetchBookings();
  }, []);

  const fetchBookings = async () => {
    try {
      const response = await apiService.getBookings();
      setBookings(response.bookings || []);
    } catch (error) {
      setError('Failed to fetch bookings');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCancelBooking = async (bookingId) => {
    if (!window.confirm('Are you sure you want to cancel this booking?')) {
      return;
    }

    setCancellingId(bookingId);
    setError('');

    try {
      await apiService.cancelBooking(bookingId);
      
      // Update local state to reflect cancellation
      setBookings(prev => 
        prev.map(booking => 
          booking.id === bookingId 
            ? { ...booking, status: 'cancelled' }
            : booking
        )
      );
      
    } catch (error) {
      setError(error.message || 'Failed to cancel booking');
    } finally {
      setCancellingId(null);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'active':
        return '#28a745';
      case 'cancelled':
        return '#dc3545';
      case 'completed':
        return '#6c757d';
      default:
        return '#6c757d';
    }
  };

  const isCancellable = (booking) => {
    return booking.status === 'active' && new Date(booking.start_time) > new Date();
  };

  if (isLoading) {
    return <div className="loading-spinner"><div className="spinner"></div></div>;
  }

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <h1>My Bookings</h1>
        <button 
          className="button button-primary"
          onClick={() => navigate('/stations')}
        >
          Book New Slot
        </button>
      </div>
      
      {error && (
        <div className="alert alert-error">
          {error}
        </div>
      )}

      {bookings.length === 0 ? (
        <div className="card">
          <div className="card-title">No Bookings</div>
          <div className="card-content">
            <p>You haven't made any bookings yet.</p>
            <button 
              className="button button-primary"
              onClick={() => navigate('/stations')}
              style={{ marginTop: '15px' }}
            >
              Find Charging Stations
            </button>
          </div>
        </div>
      ) : (
        <div className="booking-list">
          {bookings.map(booking => (
            <div key={booking.id} className="booking-item">
              <div className="booking-header">
                <div>
                  <strong>{booking.station_name}</strong>
                  <div style={{ fontSize: '14px', color: '#666', marginTop: '5px' }}>
                    {booking.address}
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <span 
                    style={{ 
                      color: getStatusColor(booking.status),
                      fontWeight: 'bold',
                      textTransform: 'uppercase'
                    }}
                  >
                    {booking.status}
                  </span>
                </div>
              </div>
              
              <div className="booking-details">
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '15px', marginTop: '15px' }}>
                  <div>
                    <strong>Slot:</strong> {booking.slot_number} ({booking.slot_type})
                  </div>
                  <div>
                    <strong>Vehicle:</strong> {booking.license_plate} ({booking.vehicle_type})
                  </div>
                  <div>
                    <strong>Start:</strong> {new Date(booking.start_time).toLocaleString()}
                  </div>
                  <div>
                    <strong>End:</strong> {new Date(booking.end_time).toLocaleString()}
                  </div>
                </div>
                
                <div style={{ marginTop: '15px', display: 'flex', gap: '10px' }}>
                  {isCancellable(booking) && (
                    <button
                      onClick={() => handleCancelBooking(booking.id)}
                      className="button button-danger"
                      disabled={cancellingId === booking.id}
                    >
                      {cancellingId === booking.id ? 'Cancelling...' : 'Cancel Booking'}
                    </button>
                  )}
                  
                  <button
                    className="button"
                    onClick={() => navigate(`/booking/${booking.station_id}`)}
                  >
                    Book Again
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default BookingsPage;
