/**
 * Stations Page Component
 * 
 * This component displays nearby charging stations based on user location
 * and allows users to select a station for booking.
 */

import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import apiService from '../services/api';

const StationsPage = () => {
  const navigate = useNavigate();
  const [location, setLocation] = useState({ latitude: '', longitude: '' });
  const [stations, setStations] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [radius, setRadius] = useState(10);

  // Get user's current location
  const getCurrentLocation = () => {
    if (navigator.geolocation) {
      setIsLoading(true);
      setError('');
      
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setLocation({
            latitude: position.coords.latitude.toString(),
            longitude: position.coords.longitude.toString()
          });
          setIsLoading(false);
        },
        (error) => {
          setError('Unable to get your location. Please enter manually.');
          setIsLoading(false);
        }
      );
    } else {
      setError('Geolocation is not supported by your browser.');
    }
  };

  // Fetch nearby stations
  const fetchStations = async () => {
    if (!location.latitude || !location.longitude) {
      setError('Please provide location coordinates');
      return;
    }

    setIsLoading(true);
    setError('');

    try {
      const response = await apiService.getNearbyStations(
        parseFloat(location.latitude),
        parseFloat(location.longitude),
        radius
      );
      
      setStations(response.stations || []);
      
      if (response.stations.length === 0) {
        setError('No stations found within the specified radius.');
      }
    } catch (error) {
      setError(error.message || 'Failed to fetch stations. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  // Handle location input change
  const handleLocationChange = (field, value) => {
    setLocation(prev => ({
      ...prev,
      [field]: value
    }));
  };

  // Handle station selection
  const handleStationSelect = (stationId) => {
    navigate(`/booking/${stationId}`);
  };

  // Auto-fetch stations when location changes
  useEffect(() => {
    if (location.latitude && location.longitude) {
      fetchStations();
    }
  }, [location.latitude, location.longitude]);

  return (
    <div>
      <h1>Find Charging Stations</h1>
      
      {/* Location Input */}
      <div className="card">
        <div className="card-title">Your Location</div>
        <div className="card-content">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr auto', gap: '15px', alignItems: 'end' }}>
            <div className="form-group" style={{ margin: 0 }}>
              <label htmlFor="latitude" className="form-label">Latitude</label>
              <input
                type="number"
                id="latitude"
                step="0.000001"
                value={location.latitude}
                onChange={(e) => handleLocationChange('latitude', e.target.value)}
                className="form-input"
                placeholder="12.9716"
                disabled={isLoading}
              />
            </div>
            
            <div className="form-group" style={{ margin: 0 }}>
              <label htmlFor="longitude" className="form-label">Longitude</label>
              <input
                type="number"
                id="longitude"
                step="0.000001"
                value={location.longitude}
                onChange={(e) => handleLocationChange('longitude', e.target.value)}
                className="form-input"
                placeholder="77.5946"
                disabled={isLoading}
              />
            </div>
            
            <button
              onClick={getCurrentLocation}
              className="button"
              disabled={isLoading}
            >
              Use Current Location
            </button>
          </div>
          
          <div className="form-group" style={{ marginTop: '15px', marginBottom: 0 }}>
            <label htmlFor="radius" className="form-label">Search Radius (km)</label>
            <select
              id="radius"
              value={radius}
              onChange={(e) => setRadius(parseInt(e.target.value))}
              className="form-select"
              style={{ width: '200px' }}
            >
              <option value={5}>5 km</option>
              <option value={10}>10 km</option>
              <option value={20}>20 km</option>
              <option value={50}>50 km</option>
            </select>
          </div>
        </div>
      </div>
      
      {/* Error Display */}
      {error && (
        <div className="alert alert-error" style={{ marginTop: '20px' }}>
          {error}
        </div>
      )}
      
      {/* Loading State */}
      {isLoading && (
        <div className="loading-spinner" style={{ height: '200px' }}>
          <div className="spinner"></div>
        </div>
      )}
      
      {/* Stations List */}
      {!isLoading && stations.length > 0 && (
        <div>
          <h2 style={{ marginTop: '30px' }}>
            Nearby Stations ({stations.length})
          </h2>
          
          <div className="station-list">
            {stations.map(station => (
              <div
                key={station.id}
                className="station-card"
                onClick={() => handleStationSelect(station.id)}
              >
                <div className="station-name">{station.name}</div>
                <div className="station-address">{station.address}</div>
                <div className="station-distance">
                  {station.distance_km.toFixed(2)} km away
                </div>
                <div style={{ marginTop: '10px', fontSize: '14px', color: '#666' }}>
                  {station.total_slots} slots available
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
      
      {/* No Stations */}
      {!isLoading && !error && stations.length === 0 && location.latitude && location.longitude && (
        <div className="card" style={{ marginTop: '30px' }}>
          <div className="card-title">No Stations Found</div>
          <div className="card-content">
            <p>No charging stations found within {radius} km of your location.</p>
            <p>Try increasing the search radius or entering a different location.</p>
          </div>
        </div>
      )}
      
      {/* Instructions */}
      {!location.latitude && !location.longitude && !isLoading && (
        <div className="card" style={{ marginTop: '30px' }}>
          <div className="card-title">How to Find Stations</div>
          <div className="card-content">
            <p>Enter your location coordinates or use your current location to find nearby charging stations.</p>
            <ul style={{ marginLeft: '20px', marginTop: '10px' }}>
              <li>Click "Use Current Location" to auto-fill your coordinates</li>
              <li>Or manually enter latitude and longitude</li>
              <li>Adjust the search radius as needed</li>
              <li>Click on any station to view available slots and make a booking</li>
            </ul>
          </div>
        </div>
      )}
    </div>
  );
};

export default StationsPage;
