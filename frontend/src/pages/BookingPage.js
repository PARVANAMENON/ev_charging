/**
 * Booking Page Component
 * 
 * This component handles the slot booking process for a selected station.
 * It shows available slots, allows vehicle selection, and manages booking creation.
 */

import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import apiService from '../services/api';

const BookingPage = () => {
  const { stationId } = useParams();
  const parsedStationId = parseInt(stationId, 10);
  const navigate = useNavigate();
  const { user } = useAuth();
  
  const [station, setStation] = useState(null);
  const [vehicles, setVehicles] = useState([]);
  const [availableSlots, setAvailableSlots] = useState([]);
  const [selectedSlot, setSelectedSlot] = useState(null);
  const [selectedVehicle, setSelectedVehicle] = useState('');
  const [selectedVehicleType, setSelectedVehicleType] = useState('2-wheeler');
  const [manualLicensePlate, setManualLicensePlate] = useState('');
  const [useManualVehicleType, setUseManualVehicleType] = useState(false);
  const [bookingTime, setBookingTime] = useState({
    date: '',
    startTime: '',
    endTime: ''
  });
  
  const [isLoading, setIsLoading] = useState(true);
  const [isBooking, setIsBooking] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Load station, vehicles, and available slots
  useEffect(() => {
    const loadData = async () => {
      let stationError = '';
      let vehicleError = '';

      try {
        if (Number.isNaN(parsedStationId)) {
          throw new Error('Invalid station ID');
        }

        const stationResponse = await apiService.getStation(parsedStationId);
        if (!stationResponse || !stationResponse.station) {
          throw new Error('Station could not be found');
        }
        setStation(stationResponse.station);
      } catch (error) {
        stationError = error?.message || 'Failed to load station information';
      }

      try {
        const vehiclesResponse = await apiService.getVehicles();
        const vehiclesList = vehiclesResponse.vehicles || [];
        setVehicles(vehiclesList);

        if (vehiclesList.length > 0) {
          setSelectedVehicle(vehiclesList[0].id);
          setSelectedVehicleType(vehiclesList[0].vehicle_type);
          setUseManualVehicleType(false);
        } else {
          setUseManualVehicleType(true);
          setSelectedVehicle('');
        }
      } catch (error) {
        vehicleError = 'Failed to load your vehicles';
        setUseManualVehicleType(true);
        setSelectedVehicle('');
      }

      const now = new Date();
      const nextHour = new Date(now.getTime() + 60 * 60 * 1000);
      const endTime = new Date(nextHour.getTime() + 60 * 60 * 1000);

      setBookingTime({
        date: nextHour.toISOString().split('T')[0],
        startTime: nextHour.toTimeString().slice(0, 5),
        endTime: endTime.toTimeString().slice(0, 5)
      });

      if (stationError || vehicleError) {
        setError([stationError, vehicleError].filter(Boolean).join('. '));
      }

      setIsLoading(false);
    };

    loadData();
  }, [stationId]);

  // Fetch available slots when time or vehicle changes
  useEffect(() => {
    if (bookingTime.date && bookingTime.startTime && bookingTime.endTime && (selectedVehicle || useManualVehicleType)) {
      fetchAvailableSlots();
    }
  }, [bookingTime, selectedVehicle, useManualVehicleType, selectedVehicleType]);

  const fetchAvailableSlots = async () => {
    const vehicle = vehicles.find(v => v.id === parseInt(selectedVehicle));
    const vehicleType = vehicle ? vehicle.vehicle_type : selectedVehicleType;
    if (!vehicleType) return;

    try {
      const startDateTime = new Date(`${bookingTime.date}T${bookingTime.startTime}`);
      const endDateTime = new Date(`${bookingTime.date}T${bookingTime.endTime}`);
      
      const response = await apiService.getAvailableSlots(
        stationId,
        vehicleType,
        startDateTime.toISOString(),
        endDateTime.toISOString()
      );
      
      setAvailableSlots(response.slots || []);
      setSelectedSlot(null); // Reset selected slot
    } catch (error) {
      setAvailableSlots([]);
      console.error('Failed to fetch available slots:', error);
    }
  };

  const handleBooking = async () => {
    if (!selectedSlot) {
      setError('Please select a slot');
      return;
    }

    setIsBooking(true);
    setError('');
    setSuccess('');

    try {
      let vehicleId = parseInt(selectedVehicle);
      if (!vehicleId) {
        if (!manualLicensePlate) {
          setError('Please enter your license plate to add a vehicle');
          setIsBooking(false);
          return;
        }

        await apiService.addVehicle({
          vehicle_type: selectedVehicleType,
          license_plate: manualLicensePlate
        });

        const vehiclesResponse = await apiService.getVehicles();
        const newVehicles = vehiclesResponse.vehicles || [];
        setVehicles(newVehicles);
        if (newVehicles.length > 0) {
          vehicleId = newVehicles[0].id;
          setSelectedVehicle(vehicleId);
        }
      }

      const startDateTime = new Date(`${bookingTime.date}T${bookingTime.startTime}`);
      const endDateTime = new Date(`${bookingTime.date}T${bookingTime.endTime}`);

      await apiService.createBooking({
        slot_id: selectedSlot,
        vehicle_id: vehicleId,
        start_time: startDateTime.toISOString(),
        end_time: endDateTime.toISOString()
      });

      setSuccess('Booking created successfully!');
      
      // Redirect to bookings page after 2 seconds
      setTimeout(() => {
        navigate('/bookings');
      }, 2000);

    } catch (error) {
      setError(error.message || 'Failed to create booking');
    } finally {
      setIsBooking(false);
    }
  };

  const handleTimeChange = (field, value) => {
    setBookingTime(prev => ({
      ...prev,
      [field]: value
    }));
  };

  if (isLoading) {
    return <div className="loading-spinner"><div className="spinner"></div></div>;
  }

  if (!station) {
    return (
      <div className="card">
        <div className="card-title">Station Not Found</div>
        <div className="card-content">
          <p>{error || 'The requested station could not be found.'}</p>
          <div style={{ display: 'flex', gap: '10px', marginTop: '15px' }}>
            <button className="button" onClick={() => navigate('/stations')}>
              Back to Stations
            </button>
            <button className="button button-secondary" onClick={() => window.location.reload()}>
              Retry
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div>
      <h1>Book Charging Slot</h1>
      
      {/* Station Info */}
      <div className="card">
        <div className="card-title">{station.name}</div>
        <div className="card-content">
          <p>{station.address}</p>
          <p>Total slots: {station.total_slots}</p>
        </div>
      </div>

      {/* Success/Error Messages */}
      {success && (
        <div className="alert alert-success" style={{ marginTop: '20px' }}>
          {success}
        </div>
      )}
      
      {error && (
        <div className="alert alert-error" style={{ marginTop: '20px' }}>
          {error}
        </div>
      )}

      {/* Vehicle Selection */}
      <div className="card" style={{ marginTop: '20px' }}>
        <div className="card-title">Select Vehicle</div>
        <div className="card-content">
          {vehicles.length > 0 && !useManualVehicleType && (
            <>
              <div className="form-group" style={{ margin: 0 }}>
                <select
                  value={selectedVehicle}
                  onChange={(e) => setSelectedVehicle(e.target.value)}
                  className="form-select"
                >
                  {vehicles.map(vehicle => (
                    <option key={vehicle.id} value={vehicle.id}>
                      {vehicle.license_plate} ({vehicle.vehicle_type})
                    </option>
                  ))}
                </select>
              </div>

              <button
                className="button button-secondary"
                style={{ marginTop: '15px' }}
                onClick={() => {
                  setUseManualVehicleType(true);
                  setSelectedVehicle('');
                }}
              >
                Use custom vehicle type instead
              </button>
            </>
          )}

          {(vehicles.length === 0 || useManualVehicleType) && (
            <div>
              <p>Select your vehicle type and enter a license plate.</p>
              <div className="form-group" style={{ margin: 0 }}>
                <label className="form-label">Vehicle Type</label>
                <select
                  value={selectedVehicleType}
                  onChange={(e) => setSelectedVehicleType(e.target.value)}
                  className="form-select"
                >
                  <option value="2-wheeler">2-wheeler</option>
                  <option value="4-wheeler">4-wheeler</option>
                </select>
              </div>
              <div className="form-group" style={{ margin: '15px 0 0 0' }}>
                <label className="form-label">License Plate</label>
                <input
                  type="text"
                  value={manualLicensePlate}
                  onChange={(e) => setManualLicensePlate(e.target.value)}
                  className="form-input"
                  placeholder="Enter license plate"
                />
              </div>
              {vehicles.length > 0 && (
                <button
                  className="button button-secondary"
                  style={{ marginTop: '15px' }}
                  onClick={() => setUseManualVehicleType(false)}
                >
                  Use existing registered vehicle instead
                </button>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Time Selection */}
      <div className="card" style={{ marginTop: '20px' }}>
        <div className="card-title">Select Time</div>
        <div className="card-content">
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '15px' }}>
            <div className="form-group" style={{ margin: 0 }}>
              <label htmlFor="date" className="form-label">Date</label>
              <input
                type="date"
                id="date"
                value={bookingTime.date}
                onChange={(e) => handleTimeChange('date', e.target.value)}
                className="form-input"
                min={new Date().toISOString().split('T')[0]}
              />
            </div>
            
            <div className="form-group" style={{ margin: 0 }}>
              <label htmlFor="startTime" className="form-label">Start Time</label>
              <input
                type="time"
                id="startTime"
                value={bookingTime.startTime}
                onChange={(e) => handleTimeChange('startTime', e.target.value)}
                className="form-input"
              />
            </div>
            
            <div className="form-group" style={{ margin: 0 }}>
              <label htmlFor="endTime" className="form-label">End Time</label>
              <input
                type="time"
                id="endTime"
                value={bookingTime.endTime}
                onChange={(e) => handleTimeChange('endTime', e.target.value)}
                className="form-input"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Available Slots */}
      <div className="card" style={{ marginTop: '20px' }}>
        <div className="card-title">
          Available Slots {availableSlots.length > 0 && `(${availableSlots.length})`}
        </div>
        <div className="card-content">
          {availableSlots.length === 0 ? (
            <p>
              {(selectedVehicle || useManualVehicleType) && bookingTime.date && bookingTime.startTime && bookingTime.endTime
                ? 'No slots available for the selected time and vehicle type.'
                : 'Please select a vehicle and time to see available slots.'}
            </p>
          ) : (
            <div className="slot-grid">
              {availableSlots.map(slot => (
                <div
                  key={slot.id}
                  className={`slot-card ${selectedSlot === slot.id ? 'selected' : ''}`}
                  onClick={() => setSelectedSlot(slot.id)}
                >
                  <div className="slot-number">Slot {slot.slot_number}</div>
                  <div className="slot-type">{slot.slot_type}</div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Booking Button */}
      {selectedSlot && (selectedVehicle || useManualVehicleType) && (
        <div style={{ marginTop: '20px', textAlign: 'center' }}>
          <button
            onClick={handleBooking}
            className="form-button"
            style={{ maxWidth: '300px' }}
            disabled={isBooking}
          >
            {isBooking ? 'Booking...' : 'Confirm Booking'}
          </button>
        </div>
      )}
    </div>
  );
};

export default BookingPage;
