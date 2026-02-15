# Hostel Management System - Flutter App

A Flutter mobile application that connects to the Next.js Hostel Management System backend.

## Features

- **Dashboard**: View student information, room details, payment summary, and quick stats
- **Profile**: View and edit student profile information
- **Room Details**: View room allocation, amenities, and roommates
- **Payments**: View payment history, pending dues, and process payments
- **Complaints**: View and raise maintenance complaints

## Getting Started

### Prerequisites

- Flutter SDK (3.10+)
- Dart SDK (3.0+)
- Android Studio or VS Code with Flutter extension
- Running Next.js backend server

### Configuration

Update the API base URL in `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // For Android emulator connecting to localhost
  static const String baseUrl = 'http://10.0.2.2:3000';
  
  // For iOS simulator
  // static const String baseUrl = 'http://localhost:3000';
  
  // For physical device (use your computer's IP)
  // static const String baseUrl = 'http://192.168.x.x:3000';
  
  // For production
  // static const String baseUrl = 'https://your-deployed-app.vercel.app';
}
```

### Running the App

1. Start the Next.js backend:
   ```bash
   cd ..
   npm run dev
   ```

2. Run the Flutter app:
   ```bash
   flutter run
   ```

### Building

**For Android:**
```bash
flutter build apk
```

**For iOS:**
```bash
flutter build ios
```

**For Web:**
```bash
flutter build web
```

## Project Structure

```
lib/
├── config/
│   └── api_config.dart      # API configuration
├── models/
│   ├── student.dart         # Student model
│   ├── complaint.dart       # Complaint model
│   ├── payment.dart         # Payment model
│   └── room.dart            # Room/Allocation models
├── providers/
│   └── student_provider.dart # State management
├── screens/
│   ├── dashboard_screen.dart # Main dashboard
│   ├── profile_screen.dart   # Profile page
│   ├── room_screen.dart      # Room details
│   ├── payments_screen.dart  # Payments page
│   └── complaints_screen.dart # Complaints page
├── services/
│   └── api_service.dart      # API client
├── theme/
│   └── app_theme.dart        # App theming
├── widgets/
│   ├── stat_card.dart        # Statistics card
│   ├── quick_action_card.dart # Quick action button
│   └── info_card.dart        # Information card
└── main.dart                  # App entry point
```

## Design

The app replicates the design of the Next.js web application with:
- **Indigo/Purple color scheme**
- **Inter font family** (via Google Fonts)
- **Card-based UI** with rounded corners and shadows
- **Gradient headers** matching the web design
- **Status badges** with consistent colors

## API Endpoints Used

- `GET /api/students` - List students
- `GET /api/students/:id` - Get student details
- `PUT /api/students/:id` - Update student profile
- `GET /api/complaints` - List complaints
- `POST /api/complaints` - Create complaint
- `GET /api/payments` - List payments
- `PUT /api/payments/:id` - Update payment
- `GET /api/allocations` - List room allocations
- `GET /api/rooms` - List rooms
