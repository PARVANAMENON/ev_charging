# Testing Guide

## Overview

This document describes how to run and interpret tests for the EV Charging Slot Booking System.

## Test Structure

The project includes comprehensive test suites:

```
tests/
├── backend/
│   ├── test_api.py      # API endpoint tests
│   └── test_models.py   # Database model tests
└── frontend/           # Frontend tests (future)
```

## Backend Tests

### Prerequisites

1. Install test dependencies:
```bash
pip install pytest pytest-flask
```

2. Ensure MySQL server is running
3. Test database will be created automatically

### Running Tests

#### Run all backend tests:
```bash
cd backend
python -m pytest tests/ -v
```

#### Run specific test file:
```bash
cd backend
python -m pytest tests/test_api.py -v
```

#### Run specific test class:
```bash
cd backend
python -m pytest tests/test_api.py::TestAuthentication -v
```

#### Run specific test method:
```bash
cd backend
python -m pytest tests/test_api.py::TestAuthentication::test_login_valid_credentials -v
```

### Test Coverage

#### Authentication Tests (`TestAuthentication`)
- User registration
- Duplicate username handling
- Login with valid/invalid credentials
- Logout functionality
- Current user retrieval

#### Vehicle Tests (`TestVehicles`)
- Adding vehicles
- Retrieving user vehicles
- Authentication requirements

#### Station Tests (`TestStations`)
- Getting nearby stations
- Station details by ID
- Admin station management
- Authorization checks

#### Slot Tests (`TestSlots`)
- Available slot retrieval
- Time-based availability

#### Booking Tests (`TestBookings`)
- Booking creation
- User booking retrieval
- Booking cancellation
- Admin booking access

#### Database Model Tests (`TestModels`)
- Database creation and connection
- User model operations
- Vehicle model operations
- Station model operations
- Slot model operations
- Booking model operations

### Test Data

Tests use a separate test database that's automatically created and populated with sample data:

- Sample users (regular and admin)
- Sample charging stations
- Sample slots
- Test vehicles and bookings

### Test Fixtures

Key test fixtures:
- `app`: Flask application instance
- `client`: Test client for HTTP requests
- `db_manager`: Database manager with test schema
- `test_user`: Authenticated regular user
- `test_admin`: Authenticated admin user
- `authenticated_client`: Client with user session
- `admin_client`: Client with admin session

## Frontend Tests

Frontend tests are planned but not yet implemented. They will include:

- Component rendering tests
- User interaction tests
- Form validation tests
- Navigation tests
- API integration tests

## Running Tests in CI/CD

For automated testing, use:

```bash
# Backend tests
cd backend && python -m pytest tests/ --cov=app --cov-report=html

# Frontend tests (when implemented)
cd frontend && npm test -- --coverage --watchAll=false
```

## Test Best Practices

1. **Test Isolation**: Each test should be independent
2. **Cleanup**: Tests clean up after themselves
3. **Fixtures**: Use fixtures for common setup
4. **Assertions**: Make assertions specific and meaningful
5. **Error Cases**: Test both success and failure scenarios
6. **Edge Cases**: Test boundary conditions
7. **Authentication**: Test both authenticated and unauthenticated access

## Writing New Tests

When adding new features, include tests for:

1. **Happy Path**: Normal successful operation
2. **Validation**: Input validation errors
3. **Authentication**: Required vs optional auth
4. **Authorization**: Role-based access control
5. **Error Handling**: Error responses
6. **Edge Cases**: Boundary conditions

### Example Test Structure:

```python
class TestNewFeature:
    def test_new_feature_success(self, authenticated_client):
        """Test successful new feature usage"""
        response = authenticated_client.post('/api/new-endpoint', json={
            'param': 'value'
        })
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['message'] == 'Success'
    
    def test_new_feature_unauthorized(self, client):
        """Test unauthorized access"""
        response = client.post('/api/new-endpoint', json={
            'param': 'value'
        })
        assert response.status_code == 401
```

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Ensure MySQL is running
   - Check database credentials
   - Verify test database permissions

2. **Import Errors**
   - Ensure Python path includes project root
   - Check virtual environment activation

3. **Test Failures**
   - Check test data setup
   - Verify API endpoint changes
   - Review recent code changes

### Debugging Tests

Run tests with verbose output:
```bash
python -m pytest tests/ -v -s
```

Run specific test with debugging:
```bash
python -m pytest tests/test_api.py::TestAuthentication::test_login_valid_credentials -v -s --pdb
```

## Performance Testing

For performance testing, consider:

1. **Load Testing**: Multiple concurrent requests
2. **Database Performance**: Query optimization
3. **Response Times**: API endpoint performance
4. **Memory Usage**: Resource consumption

## Integration Testing

Integration tests verify end-to-end functionality:

1. **User Flow**: Complete user journeys
2. **Cross-Module**: Interaction between components
3. **Database**: Data consistency
4. **API Integration**: Frontend-backend communication

## Test Reports

Generate test coverage reports:

```bash
pip install pytest-cov
python -m pytest tests/ --cov=app --cov-report=html
```

View coverage report in `htmlcov/index.html`.

## Continuous Integration

Configure CI pipeline to:

1. Run all tests on code changes
2. Check test coverage thresholds
3. Fail builds on test failures
4. Generate test reports
5. Notify team of test results
