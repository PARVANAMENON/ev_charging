/**
 * Header Component
 * 
 * This component displays the main navigation header with logo,
 * navigation links, and user information.
 */

import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const Header = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <header className="header">
      <div className="header-content">
        <a href="/dashboard" className="logo">
          EV Charging Booking
        </a>
        
        <nav className="nav-links">
          <a href="/dashboard" className="nav-link">
            Dashboard
          </a>
          <a href="/stations" className="nav-link">
            Stations
          </a>
          <a href="/bookings" className="nav-link">
            My Bookings
          </a>
          
          {user?.user_type === 'admin' && (
            <a href="/admin" className="nav-link">
              Admin
            </a>
          )}
          
          <span className="nav-link" style={{ border: 'none', cursor: 'default' }}>
            {user?.username}
          </span>
          
          <button 
            onClick={handleLogout}
            className="nav-link"
            style={{ cursor: 'pointer' }}
          >
            Logout
          </button>
        </nav>
      </div>
    </header>
  );
};

export default Header;
