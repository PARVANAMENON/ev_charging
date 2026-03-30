/**
 * Header Component
 * 
 * This component displays the main navigation header with logo,
 * navigation links, and user information.
 */

import React from 'react';
import { NavLink, Link, useNavigate } from 'react-router-dom';
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
        <Link to="/dashboard" className="logo">
          EV Booking Pro
        </Link>

        <nav className="nav-links">
          <NavLink to="/dashboard" className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}>
            Dashboard
          </NavLink>
          <NavLink to="/stations" className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}>
            Stations
          </NavLink>
          <NavLink to="/bookings" className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}>
            My Bookings
          </NavLink>

          {user?.user_type === 'admin' && (
            <NavLink to="/admin" className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}>
              Admin
            </NavLink>
          )}

          <span className="nav-username">
            {user?.username}
          </span>

          <button type="button" onClick={handleLogout} className="nav-link">
            Logout
          </button>
        </nav>
      </div>
    </header>
  );
};

export default Header;
