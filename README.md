# 🏠 Smart Hostel Management & Analytics System

A comprehensive, full-stack application designed to digitize and automate university hostel operations. This system features a robust PostgreSQL database, a Next.js REST API layer, and a cross-platform Flutter mobile application.

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:
- **Node.js 18+** & **npm**
- **Flutter SDK** (and relevant platform tools like Android Studio or Xcode)
- **PostgreSQL** (Local instance or a cloud provider like [Neon](https://neon.tech))

---

## 📂 Project Structure

- **`/database`**: SQL scripts for schema, triggers, views, and seed data.
- **`/src`**: Next.js 16.1 (App Router) API layer.
- **`/hostel_app`**: Flutter mobile application source code.

---

## 🛠️ Installation & Setup

### 1. Database Setup

Execute the SQL scripts in the `database/` directory in the following order:

1.  `database/schema.sql` (Tables, types, constraints, and indexes)
2.  `database/triggers.sql` (Business logic automation)
3.  `database/views.sql` (Aggregated analytics views)
4.  `database/seed.sql` (Sample data for development)

### 2. Web Server (Next.js API)

The API server handles database communication and CORS for the mobile app.

```bash
# Install dependencies
npm install

# Configure environment variables
cp env.example.txt .env.local
# Open .env.local and set your DATABASE_URL or individual DB_* settings

# Start the API server
npm run dev
```
The API will be available at `http://localhost:3000/api`.

### 3. Mobile Application (Flutter)

The Flutter app is the primary interface for both students and admins.

```bash
cd hostel_app

# Install dependencies
flutter pub get

# Configure API URL
# Update 'hostel_app/lib/config/api_config.dart' 
# Set baseUrl to 'http://localhost:3000' (or your machine's IP for emulators)

# Run the application
flutter run -d chrome  # For Web
# or
flutter run -d <device_id>  # For Android/iOS
```

---

## 🏗️ Architecture Overview

- **Database Layer**: PostgreSQL with normalized schema (3NF), triggers for data integrity, and views for complex analytics.
- **API Layer**: Next.js Route Handlers providing RESTful endpoints with connection pooling and parameterized queries for security.
- **Application Layer**: Flutter app using the **Provider** pattern for state management and a service-oriented architecture for API communication.

## 📊 Key Features

- **Student Portal**: Dashboard, profile management, room info, complaint tracking, and payment history.
- **Admin Portal**: Student/Room CRUD, allocation management, complaint resolution, and payment tracking.
- **Analytics Dashboard**: Real-time insights into occupancy, complaint trends, and resolution performance.

---

*This project was built to demonstrate core DBMS concepts and modern full-stack development practices.*
