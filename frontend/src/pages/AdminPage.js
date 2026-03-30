/**
 * Admin Page Component
 * 
 * This component provides admin functionality for managing stations
 * and viewing all bookings in the system.
 */

import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import apiService from '../services/api';

const AdminPage = () => {
  const navigate = useNavigate();
  const [bookings, setBookings] = useState([]);
  const [stations, setStations] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Form state for adding station
  const [showAddStation, setShowAddStation] = useState(false);
  const [stationForm, setStationForm] = useState({
    name: '',
    address: '',
    latitude: '',
    longitude: '',
    total_slots: 4
  });
  const [isAddingStation, setIsAddingStation] = useState(false);

  useEffect(() => {
    fetchAdminData();
  }, []);

  const fetchAdminData = async () => {
    try {
      const [bookingsResponse, stationsResponse] = await Promise.all([
        apiService.getAllBookings(),
        apiService.getStations()
      ]);
      
      setBookings(bookingsResponse.bookings || []);
      setStations(stationsResponse.stations || []);
      
    } catch (error) {
      setError('Failed to fetch admin data');
    } finally {
      setIsLoading(false);
    }
  };

  const handleAddStation = async (e) => {
    e.preventDefault();
    setIsAddingStation(true);
    setError('');

    try {
      await apiService.addStation({
        name: stationForm.name,
        address: stationForm.address,
        latitude: parseFloat(stationForm.latitude),
        longitude: parseFloat(stationForm.longitude),
        total_slots: stationForm.total_slots
      });

      // Reset form and refresh stations
      setStationForm({
        name: '',
        address: '',
        latitude: '',
        longitude: '',
        total_slots: 4
      });
      setShowAddStation(false);
      
      // Refresh data
      fetchAdminData();
      
    } catch (error) {
      setError(error.message || 'Failed to add station');
    } finally {
      setIsAddingStation(false);
    }
  };

  const handleStationFormChange = (field, value) => {
    setStationForm(prev => ({
      ...prev,
      [field]: value
    }));
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

  if (isLoading) {
    return <div className="loading-spinner"><div className="spinner"></div></div>;
  }

  return (
    <div>
      <h1>Admin Dashboard</h1>
      
      {error && (
        <div className="alert alert-error">
          {error}
        </div>
      )}

      {/* Statistics Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '20px', marginBottom: '30px' }}>
        <div className="card">
          <div className="card-title">Total Stations</div>
          <div className="card-content">
            <h2 style={{ margin: 0 }}>{stations.length}</h2>
          </div>
        </div>
        
        <div className="card">
          <div className="card-title">Total Bookings</div>
          <div className="card-content">
            <h2 style={{ margin: 0 }}>{bookings.length}</h2>
          </div>
        </div>
        
        <div className="card">
          <div className="card-title">Active Bookings</div>
          <div className="card-content">
            <h2 style={{ margin: 0 }}>
              {bookings.filter(b => b.status === 'active').length}
            </h2>
          </div>
        </div>
      </div>

      {/* Station Management */}
      <div className="card">
        <div className="card-title">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span>Station Management</span>
            <button
              className="button button-primary"
              onClick={() => setShowAddStation(!showAddStation)}
            >
              {showAddStation ? 'Cancel' : 'Add Station'}
            </button>
          </div>
        </div>
        
        <div className="card-content">
          {showAddStation && (
            <form onSubmit={handleAddStation} style={{ marginBottom: '20px', padding: '20px', border: '1px solid #000', backgroundColor: '#f8f8f8' }}>
              <h3>Add New Station</h3>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '15px', marginTop: '15px' }}>
                <div className="form-group" style={{ margin: 0 }}>
                  <label className="form-label">Station Name</label>
                  <input
                    type="text"
                    value={stationForm.name}
                    onChange={(e) => handleStationFormChange('name', e.target.value)}
                    className="form-input"
                    required
                  />
                </div>
                
                <div className="form-group" style={{ margin: 0 }}>
                  <label className="form-label">Address</label>
                  <input
                    type="text"
                    value={stationForm.address}
                    onChange={(e) => handleStationFormChange('address', e.target.value)}
                    className="form-input"
                    required
                  />
                </div>
                
                <div className="form-group" style={{ margin: 0 }}>
                  <label className="form-label">Latitude</label>
                  <input
                    type="number"
                    step="0.000001"
                    value={stationForm.latitude}
                    onChange={(e) => handleStationFormChange('latitude', e.target.value)}
                    className="form-input"
                    required
                  />
                </div>
                
                <div className="form-group" style={{ margin: 0 }}>
                  <label className="form-label">Longitude</label>
                  <input
                    type="number"
                    step="0.000001"
                    value={stationForm.longitude}
                    onChange={(e) => handleStationFormChange('longitude', e.target.value)}
                    className="form-input"
                    required
                  />
                </div>
                
                <div className="form-group" style={{ margin: 0 }}>
                  <label className="form-label">Total Slots</label>
                  <input
                    type="number"
                    min="1"
                    max="20"
                    value={stationForm.total_slots}
                    onChange={(e) => handleStationFormChange('total_slots', parseInt(e.target.value))}
                    className="form-input"
                    required
                  />
                </div>
              </div>
              
              <div style={{ marginTop: '15px' }}>
                <button
                  type="submit"
                  className="form-button"
                  style={{ maxWidth: '200px' }}
                  disabled={isAddingStation}
                >
                  {isAddingStation ? 'Adding...' : 'Add Station'}
                </button>
              </div>
            </form>
          )}
          
          <table className="table">
            <thead>
              <tr>
                <th>Station Name</th>
                <th>Address</th>
                <th>Total Slots</th>
              </tr>
            </thead>
            <tbody>
              {stations.map(station => (
                <tr key={station.id}>
                  <td>{station.name}</td>
                  <td>{station.address}</td>
                  <td>{station.total_slots}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* All Bookings */}
      <div className="card" style={{ marginTop: '20px' }}>
        <div className="card-title">All Bookings</div>
        <div className="card-content">
          {bookings.length === 0 ? (
            <p>No bookings found in the system.</p>
          ) : (
            <table className="table">
              <thead>
                <tr>
                  <th>User</th>
                  <th>Station</th>
                  <th>Slot</th>
                  <th>Vehicle</th>
                  <th>Start Time</th>
                  <th>End Time</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {bookings.map(booking => (
                  <tr key={booking.id}>
                    <td>{booking.username}</td>
                    <td>{booking.station_name}</td>
                    <td>{booking.slot_number}</td>
                    <td>{booking.license_plate}</td>
                    <td>{new Date(booking.start_time).toLocaleString()}</td>
                    <td>{new Date(booking.end_time).toLocaleString()}</td>
                    <td>
                      <span 
                        style={{ 
                          color: getStatusColor(booking.status),
                          fontWeight: 'bold',
                          textTransform: 'uppercase'
                        }}
                      >
                        {booking.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
};

export default AdminPage;
