# 📋 SRS Report — EV Charging Slot Booking System

> **Document:** SRS final.pdf  
> **Authors:** Parvana Menon S, Neema Shaju, Niranjana V, Mubeen Rahman  
> **Supervisor:** Vaishak Krishnan  
> **Date:** March 19, 2026  

---

## 1. Document Overview

This is a **Software Requirements Specification (SRS)** document following the **IEEE 830** and **IEEE 29148** standards. It defines the functional and non-functional requirements for a web-based **EV Charging Slot Booking System** — a platform that helps electric vehicle owners locate and book charging slots at nearby stations.

---

## 2. Scope

The system enables users to:
- Register and log into the system
- Select their vehicle type (2-wheeler / 4-wheeler)
- Enter location details
- View nearby EV charging stations
- Check slot availability and make bookings
- Cancel bookings

A core constraint is **exclusive slot booking** — once a time slot is booked, no other user can reserve it for that same time window.

---

## 3. Tech Stack

| Layer | Technology |
|---|---|
| OS | Windows / Linux |
| Database | MySQL 8.0.41 |
| Backend | Flask (Python) |
| Frontend | React |
| Interface | Web Browser |
| API Style | RESTful API over HTTP |

---

## 4. User Classes

| User Type | Access Level |
|---|---|
| **Admin** | Full system control (add/update stations, manage slots, view bookings) |
| **User** | Registered user — can search, book, and cancel slots |
| **Guest** | View-only access |

---

## 5. System Models

### 5.1 Use Case Diagram

**Actors:** User, Admin

**User Actions:**
- Register / Login
- Select vehicle type
- Enter location
- View charging stations
- Check slot availability
- Book / Cancel booking

**Admin Actions:**
- Add / Update station
- Manage slots
- View bookings

### 5.2 Class Diagram

**Main Classes:** `User`, `Vehicle`, `Station`, `Slot`, `Booking`

**Relationships:**
- User → makes → Booking
- Station → contains → Slots
- Slot → belongs to → Station
- Booking → is linked to → Slot

### 5.3 Sequence Diagram

The documented sequence for slot booking:
1. User logs into system
2. User enters location and destination
3. System displays nearby charging stations
4. User selects a station
5. System shows available slots

> ⚠️ **Note:** The SRS labels this section as "Example sequence for getting *movie* recommendation" — this appears to be a **copy-paste error** from a template. The described steps are actually correct for EV slot booking.

---

## 6. Use Case Specifications

| UC ID | Use Case | Actor | Key Pre/Post Conditions |
|---|---|---|---|
| UC-01 | User Registration | User | Pre: No existing account → Post: Account created in DB |
| UC-02 | User Login | User | Pre: Must be registered → Post: Dashboard displayed |
| UC-03 | Select Vehicle Type | User | Pre: Must be logged in → Post: Vehicle type stored |
| UC-04 | Enter Location | User | Pre: Must be logged in → Post: Location data processed |
| UC-05 | View Charging Stations | User | Pre: Location provided → Post: Station list displayed |
| UC-06 | Check Slot Availability | User | Pre: Station selected → Post: Slots displayed |
| UC-07 | Book Charging Slot | User | Pre: Slot available → Post: Slot reserved exclusively |
| UC-08 | Manage Stations | Admin | Pre: Admin logged in → Post: Station data updated |

> ⚠️ **Note:** UC-01 is labeled "User Login" in the heading but the table content says "User Registration" — likely a **minor labeling inconsistency**.

---

## 7. Functional Requirements

| ID | Requirement |
|---|---|
| FR-01 | System shall allow user registration |
| FR-02 | System shall authenticate users |
| FR-03 | System shall allow vehicle type selection |
| FR-04 | System shall allow location input |
| FR-05 | System shall display nearby charging stations |
| FR-06 | System shall show slot availability |
| FR-07 | System shall allow slot booking |
| FR-08 | System shall prevent double booking |
| FR-09 | System shall allow booking cancellation |
| FR-10 | Admin shall manage stations and slots |

---

## 8. Non-Functional Requirements

| ID | Requirement |
|---|---|
| NFR-01 | Response time < 3 seconds |
| NFR-02 | Secure user authentication |
| NFR-03 | System availability ≥ 99% |
| NFR-04 | User-friendly interface |
| NFR-05 | Support multiple concurrent users |

---

## 9. External Interface Requirements

### 9.1 User Interface
- Web-based UI for searching and booking slots
- Map or list view for stations

### 9.2 Hardware Interface
- Runs on standard devices: desktops, laptops, mobile devices

### 9.3 Software Interface
- MySQL Database Server
- Web Browser
- Backend server (Flask)

### 9.4 Communication Interface
- HTTP Protocol
- RESTful API

---

## 10. Requirements Traceability Matrix

| Requirement ID | Design Module | Test Case |
|---|---|---|
| FR-01 | Registration Module | TC01 |
| FR-02 | Login Module | TC02 |
| FR-03 | Vehicle Selection Module | TC03 |
| FR-04 | Location Input Module | TC04 |
| FR-05 | Station Display Module | TC05 |
| FR-06 | Slot Availability Module | TC06 |
| FR-07 | Booking Module | TC07 |

> ⚠️ **Note:** FR-08 (prevent double booking), FR-09 (cancel booking), and FR-10 (admin management) are **missing from the traceability matrix**. These should be added to complete coverage.

---

## 11. Observations & Recommendations

### ✅ Strengths
- Good coverage of core user flows (registration → booking)
- Clear separation of admin and user roles
- Traceability matrix provides a link between requirements and test cases
- Follows IEEE SRS standards

### ⚠️ Issues Found

| # | Issue | Severity |
|---|---|---|
| 1 | Section 4.3 (Sequence Diagram) contains the text "Example sequence for getting *movie* recommendation" — a template copy-paste error | Medium |
| 2 | UC-01 heading says "User Login" but the use case is actually "User Registration" | Low |
| 3 | FR-08, FR-09, FR-10 are missing from the Requirements Traceability Matrix | Medium |
| 4 | The NFR bullet formatting in the PDF is broken (text runs together across lines) | Low |
| 5 | No mention of payment/billing integration — relevant if future monetization is planned | Low |
| 6 | No data security/privacy requirements documented (e.g., GDPR, data encryption at rest) | Medium |
| 7 | No error handling / edge case requirements specified (e.g., network failure, station offline) | Medium |
| 8 | Guest user class mentioned in Section 3.2 but never referenced again in use cases or FRs | Low |

### 💡 Suggestions for Improvement
- Add use cases and FRs for **payment processing** if applicable
- Specify **data privacy** and **security** requirements more explicitly
- Add **error/exception flows** to use case specifications
- Expand the traceability matrix to cover all 10 functional requirements
- Fix the copy-paste error in Section 4.3
- Include a dedicated **Guest User** use case or clarify their role
- Consider adding **notification requirements** (e.g., booking confirmation emails/SMS)

---

## 12. Summary

This SRS describes a reasonably well-structured **EV Charging Slot Booking System** with a clear tech stack (React + Flask + MySQL). It covers user registration, authentication, slot discovery, booking, and admin management. The document is mostly complete but has a few **template errors**, **incomplete traceability coverage**, and **missing requirement categories** (security, error handling, guest user flows) that should be addressed before development begins.
