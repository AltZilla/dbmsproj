# 📱 Hostel Management System — Flutter Mobile App

> **Location:** `hostel_app/` directory inside the main project  
> **Framework:** Flutter (Dart) • **Version:** 1.0.0+1 • **SDK:** Dart ≥ 3.10.3

---

## 🧭 Overview

The `hostel_app` is a **Flutter mobile application** that acts as the front-end client for the **Smart Hostel Management System**. Instead of using the web browser, students and admins can use this app on their Android or iOS phones to manage everything — from viewing room details to raising maintenance complaints.

It talks to the **Next.js backend** (running on your computer or a deployed server) through a REST API over HTTP.

---

## 🛠️ Tech Stack

| Layer            | Technology                        |
|------------------|-----------------------------------|
| Language         | Dart                              |
| Framework        | Flutter (Material 3)              |
| State Management | `provider` package (^6.1.1)       |
| HTTP Client      | `http` package (^1.2.0)           |
| Fonts            | Google Fonts – **Inter** (^6.1.0) |
| Date Formatting  | `intl` package (^0.19.0)          |
| Backend          | Next.js REST API (separate repo)  |

---

## 🗂️ Project Structure

```
hostel_app/lib/
│
├── main.dart                    ← App entry point
│
├── config/
│   └── api_config.dart          ← Backend URL configuration
│
├── models/                      ← Data classes (Dart equivalents of DB tables)
│   ├── student.dart
│   ├── complaint.dart
│   ├── payment.dart
│   └── room.dart
│
├── providers/
│   └── student_provider.dart    ← Global state (ChangeNotifier)
│
├── services/
│   └── api_service.dart         ← All HTTP API calls in one place
│
├── screens/                     ← All app screens (pages)
│   ├── dashboard_screen.dart
│   ├── profile_screen.dart
│   ├── room_screen.dart
│   ├── payments_screen.dart
│   ├── complaints_screen.dart
│   ├── analytics_screen.dart
│   ├── admin_dashboard_screen.dart
│   └── admin/
│       ├── admin_students_screen.dart
│       ├── admin_rooms_screen.dart
│       ├── admin_hostels_screen.dart
│       ├── admin_payments_screen.dart
│       ├── admin_complaints_screen.dart
│       └── admin_allocations_screen.dart
│
├── theme/
│   └── app_theme.dart           ← Global colors, fonts, component styles
│
└── widgets/
    ├── stat_card.dart
    ├── quick_action_card.dart
    └── info_card.dart
```

---

## 🚀 Entry Point — `main.dart`

When the app starts, `main()` calls `runApp(HostelApp())`. This sets up:

1. **`MultiProvider`** — wraps the entire app so state is accessible everywhere
2. **`StudentProvider`** — the only global provider; holds the current student's data
3. **`MaterialApp`** — the app shell with the title **"Smart Hostel Management"**, the custom theme, and `DashboardScreen` as the first screen

```dart
void main() {
  runApp(const HostelApp());
}
// → MultiProvider → MaterialApp → DashboardScreen
```

---

## 🎨 Theme — `app_theme.dart`

The entire app uses a carefully designed **Indigo/Purple** color system derived from the web version.

### Color Palette

| Token        | Hex       | Usage                          |
|--------------|-----------|--------------------------------|
| `primary900` | `#312E81` | AppBar background              |
| `primary600` | `#4F46E5` | Buttons, accents               |
| `primary400` | `#818CF8` | Focused input borders          |
| `gray50`     | `#F9FAFB` | Scaffold background            |
| `success500` | `#22C55E` | Paid/Resolved status badges    |
| `warning500` | `#F59E0B` | Pending/Partial status badges  |
| `error500`   | `#EF4444` | Overdue/Critical status badges |

### Gradients

| Name              | Colors                  | Usage           |
|-------------------|-------------------------|-----------------|
| `primaryGradient` | `#667EEA → #764BA2`     | Cards, headers  |
| `headerGradient`  | `#3B82F6 → #4338CA`     | Section headers |
| `navbarGradient`  | `#1E1B4B → #312E81`     | Navigation bar  |

### Typography
All text uses the **Inter** font (via Google Fonts), with sizes from 12px (bodySmall) up to 32px (displayLarge), each with defined font weights.

---

## 📦 Data Models

### `Student`
Represents a hostel resident.

| Field                | Type    | Description                       |
|----------------------|---------|-----------------------------------|
| `id`                 | int     | Database primary key              |
| `registrationNumber` | String  | e.g., `24BCE5420`                 |
| `firstName/lastName` | String  | Student's name                    |
| `email/phone`        | String  | Contact information               |
| `gender/dateOfBirth` | String? | Personal details                  |
| `guardianName/Phone` | String? | Emergency contact                 |
| `roomNumber`         | String? | Assigned room (e.g., `A-101`)     |
| `hostelName`         | String? | Which hostel they're in           |
| `totalPaid`          | double  | Sum of completed payments         |
| `totalPending`       | double  | Sum of pending/overdue payments   |
| `activeComplaints`   | int     | Number of open complaints         |

### `Complaint`
Represents a maintenance/service request.

| Field       | Type      | Description                                |
|-------------|-----------|---------------------------------------------|
| `title`     | String    | Short description of the issue              |
| `category`  | String    | `electrical`, `plumbing`, `furniture`, etc. |
| `status`    | String    | `open`, `assigned`, `resolved`, `closed`    |
| `priority`  | int       | 1 (critical) to 5 (low)                     |
| `createdAt` | DateTime  | When it was filed                           |
| `resolvedAt`| DateTime? | When it was fixed (if resolved)             |

Category icons: ⚡ electrical, 🚿 plumbing, 🪑 furniture, 🧹 cleaning, 📶 internet, 🔒 security.

### `Payment`
Represents a hostel fee record.

| Field           | Type      | Description                             |
|-----------------|-----------|-----------------------------------------|
| `amount`        | double    | Payment amount in currency              |
| `dueDate`       | DateTime  | When it must be paid by                 |
| `paymentDate`   | DateTime? | When it was actually paid               |
| `paymentStatus` | String    | `pending`, `paid`, `overdue`, `partial` |
| `semester`      | String?   | Academic semester label                 |
| `daysOverdue`   | int?      | How many days past due date             |

### `Room` / `Allocation`
- **`RoomDetails`**: Room number, type (single/double/triple), hostel name, capacity, occupancy, price, amenities
- **`Allocation`**: Links a Student to a Room (check-in/check-out dates, active status)

---

## 🔌 API Service — `api_service.dart`

A **singleton** class that handles all communication with the Next.js backend. Uses 4 core HTTP helpers:

| Method      | HTTP Verb | Use Case           |
|-------------|-----------|---------------------|
| `_get()`    | GET       | Fetch data          |
| `_post()`   | POST      | Create new records  |
| `_put()`    | PUT       | Update records      |
| `_delete()` | DELETE    | Remove records      |

All requests go to `ApiConfig.baseUrl` with a configured timeout.

### Available API Methods

| Category    | Method                | Endpoint                              |
|-------------|-----------------------|---------------------------------------|
| Dashboard   | `getDashboardStats()` | Multiple parallel fetches             |
| Students    | `getStudents()`       | `GET /api/students`                   |
| Students    | `getStudent(id)`      | `GET /api/students/:id`               |
| Students    | `createStudent()`     | `POST /api/students`                  |
| Students    | `updateStudent()`     | `PUT /api/students/:id`               |
| Students    | `deactivateStudent()` | `DELETE /api/students/:id`            |
| Complaints  | `getComplaints()`     | `GET /api/complaints`                 |
| Complaints  | `createComplaint()`   | `POST /api/complaints`                |
| Complaints  | `updateComplaint()`   | `PUT /api/complaints/:id`             |
| Payments    | `getPayments()`       | `GET /api/payments`                   |
| Payments    | `updatePayment()`     | `PUT /api/payments/:id`               |
| Rooms       | `getRooms()`          | `GET /api/rooms`                      |
| Allocations | `getAllocations()`    | `GET /api/allocations`                |
| Allocations | `autoAllocate()`      | `POST /api/allocations/auto-allocate` |
| Hostels     | `getHostels()`        | `GET /api/hostels`                    |

---

## 🧠 State Management — `student_provider.dart`

Uses Flutter's **Provider** pattern with `ChangeNotifier`.

**State held globally:**
- `_students` — list of all students
- `_selectedStudent` — the currently viewed student  
- `_isLoading` — shows loading spinners across the app
- `_error` — error messages for UI feedback

**Key methods:**

```dart
loadStudents()           // Fetches all students from API, auto-selects first
selectStudent(int id)    // Loads detailed data for one student
updateStudentProfile()   // Sends PUT request, then refreshes selected student
```

Any widget using `Consumer<StudentProvider>` or `context.watch<StudentProvider>()` automatically rebuilds when values change.

---

## 📱 Screens

### Student-Facing Screens

#### 1. 🏠 Dashboard Screen
The **home screen** of the app. Shows a high-level summary:
- Student selector (switch between students)
- Summary cards: Room Number, Hostel, Amount Paid, Pending Amount
- Active complaints count badge
- Quick action buttons linking to other screens
- Recent payment and complaint preview

---

#### 2. 👤 Profile Screen
Shows and allows editing of the full student profile:
- Personal info: name, registration number, DOB, gender
- Contact info: email, phone, address
- Guardian info: name and phone
- **Edit mode**: toggle "Edit" to update fields, saved via PUT API

---

#### 3. 🛏️ Room Screen
Displays room allocation details:
- Room number, type (Single/Double/Triple), floor
- Hostel name and block
- Room amenities list
- Roommates (other students in the same room)
- Check-in date and allocation status

---

#### 4. 💳 Payments Screen
Full payment history and management:
- Payment summary (total paid vs. pending)
- Paginated list of all payment records with status badges
- **Status filters**: All / Pending / Paid / Overdue
- Tap a payment → option to mark it paid (PUT API call)
- Overdue indicator with number of days late

---

#### 5. 🔧 Complaints Screen
Raise and track maintenance issues:
- List of all complaints with status/priority badges
- **Filter by status**: Open / Assigned / Resolved
- **Raise new complaint** form with:
  - Title and description
  - Category (electrical, plumbing, furniture, etc.)
  - Priority level (1 Critical → 5 Low)
- Category represented as emoji icons

---

#### 6. 📊 Analytics Screen
Charts and summary statistics:
- Payment trends over time
- Complaint distribution by category
- Occupancy rates across hostels
- Semester-wise financial summaries

---

### Admin Screens

#### 7. 🖥️ Admin Dashboard
Overview for hostel administrators:
- Live stats: total students, rooms, open complaints, pending payments
- Quick navigation cards to each admin module

---

#### 8. 👨‍🎓 Admin Students
Full student management:
- Paginated list with search functionality
- Add new student (form with all fields)
- View/edit any student's details
- Deactivate/remove students

---

#### 9. 🏠 Admin Rooms
Room inventory management:
- List all rooms with occupancy status color-coded
- Filter by hostel or room type
- Add new rooms to the system
- View room details and current residents

---

#### 10. 🏢 Admin Hostels
Hostel building management:
- View all hostel buildings with capacity info
- Current occupancy vs. total capacity
- Add new hostel blocks

---

#### 11. 💰 Admin Payments
Payment oversight for all students:
- Full payment register across all students
- Filter by status (pending / paid / overdue)
- Mark payments as paid with confirmation
- Highlight overdue payments

---

#### 12. 📝 Admin Complaints
Complaint handling workflow:
- View all complaints across all students
- Assign complaints to maintenance staff
- Update status: `open → assigned → resolved → closed`
- Filter by category and priority level

---

#### 13. 🔗 Admin Allocations
Room allocation management:
- View all active and past allocations
- Manually assign a student to a specific room
- **Auto-allocate**: one click assigns all unallocated students optimally
- Deallocate / vacate a student from their room

---

## ⚙️ Configuration

Edit `lib/config/api_config.dart` to set the backend URL:

```dart
// Android emulator → backend localhost
static const String baseUrl = 'http://10.0.2.2:3000';

// iOS simulator
// static const String baseUrl = 'http://localhost:3000';

// Physical device → use your PC's local IP
// static const String baseUrl = 'http://192.168.x.x:3000';

// Production deployment
// static const String baseUrl = 'https://your-app.vercel.app';
```

---

## 🏃 How to Run

### Step 1 — Start the Next.js backend
```bash
# In the project root (dbmsproj-master/)
npm run dev
# Backend runs at http://localhost:3000
```

### Step 2 — Run the Flutter app
```bash
cd hostel_app
flutter pub get       # Install all dependencies
flutter run           # Run on connected device/emulator
```

### Build for release
```bash
flutter build apk     # Android APK
flutter build ios     # iOS (requires Mac + Xcode)
flutter build web     # Web deployment
```

---

## 🔄 Data Flow (How it all connects)

```
User taps a button
      ↓
Screen Widget
      ↓
StudentProvider (global state) OR direct ApiService call
      ↓
ApiService._get() / _post() / _put()
      ↓
HTTP Request → Next.js Backend (localhost:3000)
      ↓
Next.js Route Handler → PostgreSQL Database
      ↓
JSON Response → Dart Model.fromJson()
      ↓
Provider.notifyListeners() → UI rebuilds automatically
```

---

## 📐 Architecture Diagram

```
┌─────────────────────────────────────┐
│           Flutter Mobile App        │
│                                     │
│  Screens ──→ Widgets                │
│     │                               │
│     ├──→ StudentProvider            │  ← Global state (ChangeNotifier)
│     │                               │
│     └──→ ApiService (singleton)     │  ← HTTP client
│              │                      │
└──────────────│──────────────────────┘
               │ HTTP REST (JSON)
┌──────────────▼──────────────────────┐
│         Next.js Backend             │
│      (localhost:3000 / Vercel)      │
└──────────────┬──────────────────────┘
               │ SQL Queries
┌──────────────▼──────────────────────┐
│         PostgreSQL Database         │
│   (schema.sql + triggers.sql)       │
└─────────────────────────────────────┘
```

---

*This Flutter app is part of the full-stack **Smart Hostel Management System** DBMS project.*

---

---

# 🧑‍💻 Code Explanation — File by File

This section walks through every major source file with actual code snippets and explains what each line / block does.

---

## 1. `lib/main.dart` — App Entry Point

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/student_provider.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HostelApp());   // ← Starts the Flutter engine with our root widget
}

class HostelApp extends StatelessWidget {
  const HostelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(             // ← Wraps the whole app in state management
      providers: [
        ChangeNotifierProvider(create: (_) => StudentProvider()), // ← Creates one global StudentProvider
      ],
      child: MaterialApp(
        title: 'Smart Hostel Management',
        debugShowCheckedModeBanner: false,  // ← Removes the red "DEBUG" ribbon
        theme: AppTheme.lightTheme,         // ← Applies our custom theme
        home: const DashboardScreen(),      // ← First screen shown when app opens
      ),
    );
  }
}
```

**Why `MultiProvider`?**
Even though we only have one provider now (`StudentProvider`), wrapping in `MultiProvider` makes it easy to add more later (e.g., `AdminProvider`, `ThemeProvider`) without changing this file.

**Why `StatelessWidget`?**
`HostelApp` itself never changes — it's just a container. Only inner screens hold mutable state.

---

## 2. `lib/theme/app_theme.dart` — Design System

```dart
class AppTheme {
  // ── Color constants ──────────────────────────────────────────────
  static const Color primary600 = Color(0xFF4F46E5); // buttons, main accent
  static const Color primary900 = Color(0xFF312E81); // AppBar background
  static const Color gray50     = Color(0xFFF9FAFB); // page background
  static const Color success500 = Color(0xFF22C55E); // paid / resolved
  static const Color error500   = Color(0xFFEF4444); // overdue / critical

  // ── Gradients ────────────────────────────────────────────────────
  static const LinearGradient navbarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)], // dark indigo → purple
  );

  // ── ThemeData (applied globally) ─────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,                // uses Material 3 design system
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary600,           // Flutter auto-generates tonal palette
        primary: primary600,
      ),
      scaffoldBackgroundColor: gray50,   // all Scaffold backgrounds become light gray
      textTheme: GoogleFonts.interTextTheme(), // replace default font with Inter

      // AppBar: dark purple, white text
      appBarTheme: AppBarTheme(
        backgroundColor: primary900,
        foregroundColor: Colors.white,
      ),

      // Cards: white, 16px rounded corners, gray border
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: gray200),
        ),
      ),

      // Buttons: indigo background, white text, 12px corners
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
```

**Key concept:** By defining everything in `AppTheme` once, every widget across all 13 screens automatically inherits the same look. Changing `primary600` here changes ALL buttons, chips, and indicators at once.

---

## 3. `lib/models/student.dart` — Data Model

```dart
class Student {
  final int id;
  final String registrationNumber;  // e.g. "24BCE5420"
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;              // '?' means this can be null (optional)
  final String? roomNumber;         // null if not yet allocated
  final String? hostelName;
  final double totalPaid;           // calculated on backend and sent in JSON
  final double totalPending;
  final int activeComplaints;

  // Computed property — no extra field needed in JSON
  String get fullName => '$firstName $lastName';

  // Factory constructor — converts raw JSON Map into a typed Student object
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int,
      registrationNumber: json['registration_number'] ?? '', // fallback if missing
      firstName: json['first_name'] ?? '',
      // double.tryParse handles edge cases where backend returns "1000.00" as a String
      totalPaid: double.tryParse(json['total_paid']?.toString() ?? '0') ?? 0,
      totalPending: double.tryParse(json['total_pending']?.toString() ?? '0') ?? 0,
      activeComplaints: int.tryParse(json['active_complaints']?.toString() ?? '0') ?? 0,
      // ... other fields
    );
  }

  // toJson() is used when sending data back to the server (PUT /api/students/:id)
  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      // Note: room info & payment totals are NOT sent — server computes them
    };
  }
}
```

**Why `double.tryParse`?**
SQL databases can return numeric values as strings in JSON. `tryParse` safely converts `"1000.00"` → `1000.0` and returns `0` if the value is null or malformed.

**Why `final`?**
All fields are `final` (immutable). If student data changes (e.g., after editing profile), a completely new `Student` object is created rather than mutating the existing one. This ensures predictable state.

---

## 4. `lib/providers/student_provider.dart` — Global State

```dart
class StudentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService(); // gets the singleton instance

  List<Student> _students = [];       // all students list (for the selector)
  Student? _selectedStudent;          // currently-viewed student (nullable)
  bool _isLoading = false;            // drives loading spinners in UI
  String? _error;                     // null = no error, else show error message

  // Public getters — UI reads these, cannot modify them directly
  Student? get selectedStudent => _selectedStudent;
  bool get isLoading => _isLoading;

  Future<void> loadStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // ← tells all Consumer widgets to rebuild (shows spinner)

    try {
      _students = await _apiService.getStudents();
      if (_students.isNotEmpty && _selectedStudent == null) {
        await selectStudent(_students.first.id); // auto-select first student
      }
    } catch (e) {
      _error = e.toString(); // store the error so UI can display it
    } finally {
      _isLoading = false;
      notifyListeners(); // ← rebuilds UI again (hides spinner, shows data)
    }
  }

  Future<bool> updateStudentProfile(Map<String, dynamic> updates) async {
    if (_selectedStudent == null) return false;

    try {
      final success = await _apiService.updateStudent(_selectedStudent!.id, updates);
      if (success) {
        // Re-fetch the student to get the updated data from the server
        await selectStudent(_selectedStudent!.id);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
```

**`notifyListeners()` explained:**
Every time this is called, Flutter finds all widgets that are "listening" (via `Consumer<StudentProvider>` or `context.watch<StudentProvider>()`) and calls their `build()` method again with the new data.

**Pattern — try / finally:**
`finally` always runs, even if an exception is thrown. This guarantees `_isLoading` is always set back to `false`, so the spinner never gets stuck.

---

## 5. `lib/services/api_service.dart` — HTTP Client

```dart
class ApiService {
  // Singleton pattern — only one instance exists for the entire app lifetime
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;   // every 'ApiService()' returns the same object
  ApiService._internal();              // private constructor

  String get baseUrl => ApiConfig.baseUrl; // reads URL from config file

  // ── Core HTTP helper ────────────────────────────────────────────
  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'))
          .timeout(ApiConfig.timeout);    // throws TimeoutException if too slow

      if (response.statusCode == 200) {
        return json.decode(response.body); // parse JSON string → Dart Map
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e'); // re-wrap with cleaner message
    }
  }

  // ── Dashboard stats — fires 4 API calls simultaneously ──────────
  Future<Map<String, int>> getDashboardStats() async {
    final results = await Future.wait([   // ← runs all 4 calls IN PARALLEL
      _get('/api/students?limit=1'),
      _get('/api/rooms?limit=1'),
      _get('/api/complaints?status=open&limit=1'),
      _get('/api/payments?status=pending&limit=1'),
    ]);
    // Each result has a 'pagination.total' field from the backend
    return {
      'totalStudents':   results[0]['pagination']?['total'] ?? 0,
      'totalRooms':      results[1]['pagination']?['total'] ?? 0,
      'openComplaints':  results[2]['pagination']?['total'] ?? 0,
      'pendingPayments': results[3]['pagination']?['total'] ?? 0,
    };
  }

  // ── Students — paginated list with search support ────────────────
  Future<Map<String, dynamic>> getStudentsRaw({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    // Builds query string: "page=1&limit=10&search=john"
    final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return await _get('/api/students?$queryString');
  }

  // ── Complaints — create with all required fields ─────────────────
  Future<bool> createComplaint({
    required int studentId,
    required int roomId,
    required String category,
    required String title,
    required String description,
    required int priority,
  }) async {
    final data = await _post('/api/complaints', {
      'student_id': studentId,
      'room_id': roomId,
      'category': category,
      'title': title,
      'description': description,
      'priority': priority,
    });
    return data['success'] == true; // returns true/false for easy error handling
  }
}
```

**Why `Future.wait`?**
Instead of fetching student count, then room count, then complaints (3 sequential waits), `Future.wait` fires all requests at the same time. If each takes 300ms, sequential = 900ms. Parallel = ~300ms.

**Why singleton?**
The HTTP client keeps an internal connection pool. Creating a new `ApiService()` every time a widget rebuilds would waste resources. The singleton ensures one shared client.

---

## 6. `lib/screens/dashboard_screen.dart` — Home Screen

### Animation Setup

```dart
class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {    // ← needed to create AnimationControllers

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Create a 600ms fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,  // 'this' works because of TickerProviderStateMixin
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut, // starts fast, slows down at end
    );

    // After the first frame renders, load data and start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadStudents(); // fetch from API
      _fadeController.forward(); // play the fade-in
    });
  }

  @override
  void dispose() {
    _fadeController.dispose(); // ALWAYS dispose controllers to prevent memory leaks
    super.dispose();
  }
```

### Dynamic Greeting

```dart
String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';   // 00:00 – 11:59
  if (hour < 17) return 'Good afternoon'; // 12:00 – 16:59
  return 'Good evening';                  // 17:00 – 23:59
}

String _getGreetingEmoji() {
  final hour = DateTime.now().hour;
  if (hour < 12) return '☀️';  // sunrise
  if (hour < 17) return '🌤️'; // partly cloudy
  return '🌙';                 // moon for evening
}
```

### Consumer + State-driven UI

```dart
body: Consumer<StudentProvider>(  // ← re-renders whenever provider calls notifyListeners()
  builder: (context, provider, child) {

    // State 1: Loading spinner (first load only)
    if (provider.isLoading && provider.selectedStudent == null) {
      return const Center(child: CircularProgressIndicator(...));
    }

    // State 2: Error with retry button
    if (provider.error != null && provider.selectedStudent == null) {
      return Center(
        child: Column(children: [
          Text(provider.error!),
          ElevatedButton(
            onPressed: () => provider.loadStudents(), // retry
            child: const Text('Retry'),
          ),
        ]),
      );
    }

    // State 3: Happy path — show the dashboard
    final student = provider.selectedStudent!;
    return FadeTransition(
      opacity: _fadeAnimation,  // ← wraps content in the fade-in animation
      child: SingleChildScrollView(
        child: Column(children: [
          _buildStudentSelector(student, provider),
          if (student.totalPending > 0) _buildPaymentAlert(student, ...),
          _buildWelcomeHeader(student, dateFormat),
          _buildStatsRow(student, currencyFormat),
          _buildQuickActionsGrid(student),
        ]),
      ),
    );
  },
),
```

### Welcome Header (Gradient Card)

```dart
Widget _buildWelcomeHeader(Student student, DateFormat dateFormat) {
  return Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      // 3-color diagonal gradient: indigo → violet → purple
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF7C3AED)],
      ),
      borderRadius: BorderRadius.circular(20),
      // Drop shadow for depth
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4338CA).withOpacity(0.3),
          blurRadius: 24,
          offset: const Offset(0, 10), // shadow goes 10px down
        ),
      ],
    ),
    child: Row(
      children: [
        // Left: greeting text + reg number
        Expanded(
          child: Column(children: [
            Text('${_getGreeting()} ${_getGreetingEmoji()}'),
            Text(student.firstName, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
            // Registration number in monospace pill badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(student.registrationNumber,
                  style: TextStyle(fontFamily: 'monospace')),
            ),
          ]),
        ),
        // Right: room number badge
        if (student.roomNumber != null)
          Text(student.roomNumber!, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}
```

### Payment Alert Banner

```dart
Widget _buildPaymentAlert(Student student, NumberFormat fmt) {
  final isOverdue = student.totalPending > 0;

  return Container(
    decoration: BoxDecoration(
      // Red gradient if overdue, yellow if just pending
      gradient: LinearGradient(
        colors: isOverdue
            ? [Color(0xFFFEE2E2), Color(0xFFFECACA)]  // red
            : [Color(0xFFFEF9C3), Color(0xFFFEF08A)], // yellow
      ),
    ),
    child: Row(children: [
      // Icon changes dynamically
      Icon(isOverdue ? Icons.warning_rounded : Icons.info_outline),
      Text('${fmt.format(student.totalPending)} pending'),
      // "View" button navigates to PaymentsScreen
      InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PaymentsScreen(studentId: student.id)),
        ),
        child: Text('View'),
      ),
    ]),
  );
}
```

### Bottom Navigation

```dart
void _onBottomNavTap(int index, Student student) {
  if (index == 0) return; // already on Home tab, do nothing

  // Map index → screen widget
  Widget screen;
  switch (index) {
    case 1: screen = RoomScreen(studentId: student.id); break;
    case 2: screen = PaymentsScreen(studentId: student.id); break;
    case 3: screen = ComplaintsScreen(studentId: student.id); break;
    case 4: screen = ProfileScreen(studentId: student.id); break;
    default: return;
  }

  // Push the screen, and when user pops back, reset bottom nav to Home (0)
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
      .then((_) => setState(() => _bottomNavIndex = 0));
}
```

---

## 7. `lib/screens/complaints_screen.dart` — Raise & Track Complaints

### State Variables

```dart
class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final ApiService _apiService = ApiService(); // direct API call (not via provider)
  List<Complaint> _complaints = [];            // complaint list for this student
  bool _isLoading = true;
  int? _roomId;         // student's room ID (needed to submit a complaint)

  // Form state (used only when raise-complaint modal is open)
  bool _showForm = false;
  String _category = 'electrical'; // default category
  String _title = '';
  String _description = '';
  int _priority = 3;    // default: medium priority
```

### Data Loading

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);

  try {
    // Step 1: fetch student to get their room ID
    final student = await _apiService.getStudent(widget.studentId);
    if (student != null) {
      setState(() => _roomId = student.roomId); // save room ID for complaint form
    }

    // Step 2: fetch all complaints for this student
    final complaints = await _apiService.getComplaints(widget.studentId);
    setState(() => _complaints = complaints);
  } catch (e) {
    debugPrint('Error loading complaints: $e');
  } finally {
    setState(() => _isLoading = false); // always hide spinner
  }
}
```

### Submit Complaint with Validation

```dart
Future<void> _submitComplaint() async {
  // Guard 1: student must be in a room
  if (_roomId == null) {
    setState(() => _formError = 'You must be assigned to a room...');
    return;
  }

  // Guard 2: title and description required
  if (_title.isEmpty || _description.isEmpty) {
    setState(() => _formError = 'Please fill in all required fields.');
    return;
  }

  // All guards passed — send to API
  try {
    final success = await _apiService.createComplaint(
      studentId: widget.studentId,
      roomId: _roomId!,
      category: _category,    // e.g. 'electrical'
      title: _title,
      description: _description,
      priority: _priority,    // 1–5
    );

    if (success) {
      setState(() {
        _showForm = false;    // close the modal
        _title = '';          // reset form fields
        _description = '';
        _category = 'electrical';
        _priority = 3;
        _message = 'Complaint raised successfully!';
        _isSuccess = true;
      });
      await _loadData();    // refresh the complaint list
    }
  } catch (e) {
    setState(() => _formError = 'An error occurred: $e');
  }

  // Auto-clear the success/error message after 5 seconds
  Future.delayed(const Duration(seconds: 5), () {
    if (mounted) setState(() => _message = null); // 'mounted' check prevents setState after dispose
  });
}
```

### Status Color Mapping

```dart
final statusColors = {
  'open':        (Color(0xFFFEF3C7), Color(0xFF92400E), Color(0xFFFDE68A)), // amber
  'assigned':    (Color(0xFFDBEAFE), Color(0xFF1E40AF), Color(0xFFBFDBFE)), // blue
  'in_progress': (Color(0xFFE0E7FF), Color(0xFF3730A3), Color(0xFFC7D2FE)), // indigo
  'resolved':    (Color(0xFFD1FAE5), Color(0xFF065F46), Color(0xFFA7F3D0)), // green
  'closed':      (AppTheme.gray100,  AppTheme.gray600,  AppTheme.gray200),  // gray
};
// Usage: colors.$1 = background, colors.$2 = text, colors.$3 = border
// Dart 3 Record destructuring: (bg, text, border) = statusColors[status]!;
```

### Complaint Card Build

```dart
// ListView.builder efficiently renders only visible cards (not all at once)
ListView.builder(
  itemCount: _complaints.length,
  itemBuilder: (context, index) {
    final complaint = _complaints[index];
    final colors = statusColors[complaint.status] ?? defaultColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Category badge: emoji + label
            Text(Complaint.getCategoryIcon(complaint.category)),
            Text(complaint.category.replaceAll('_', ' ').toUpperCase()),

            // Status badge: colored pill
            Container(
              decoration: BoxDecoration(color: colors.$1, borderRadius: BorderRadius.circular(16)),
              child: Text(complaint.status.toUpperCase(),
                  style: TextStyle(color: colors.$2)),
            ),
          ],
        ),
        Text(complaint.title, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(complaint.description),

        // Priority dot: red for P1/P2 (urgent), blue otherwise
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: complaint.priority <= 2 ? AppTheme.error500 : Color(0xFF60A5FA),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Text('Priority: P${complaint.priority}'),
        Text('Created: ${DateFormat('MMM d, yyyy').format(complaint.createdAt)}'),
      ]),
    );
  },
)
```

---

## 8. `lib/screens/payments_screen.dart` — Payments & Fee History

### State & Computed Properties

```dart
class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> _payments = [];
  double _totalPaid = 0;
  double _totalPending = 0;
  Set<int> _selectedPaymentIds = {}; // tracks which payments are checked in modal

  // Computed getter — filters from _payments on every access (no separate list)
  List<Payment> get _pendingPayments =>
      _payments.where((p) => p.isPending).toList();
      // isPending is defined on the model as: ['pending','overdue','partial'].contains(status)

  // Computed getter — sums only the selected items
  double get _selectedAmount => _pendingPayments
      .where((p) => _selectedPaymentIds.contains(p.id))
      .fold(0, (sum, p) => sum + p.amount);
      // fold() is like Array.reduce() — starts at 0, adds each amount
```

### Load Payments with Aggregation

```dart
Future<void> _loadPayments() async {
  setState(() => _isLoading = true);

  final payments = await _apiService.getPayments(widget.studentId);
  setState(() {
    _payments = payments;

    // Calculate totals in-memory from the fetched list
    _totalPaid = payments
        .where((p) => p.paymentStatus == 'paid')  // filter paid ones
        .fold(0, (sum, p) => sum + p.amount);      // sum their amounts

    _totalPending = payments
        .where((p) => p.isPending)
        .fold(0, (sum, p) => sum + p.amount);
  });
}
```

### Process Payment (Mark as Paid)

```dart
Future<void> _processPayment() async {
  setState(() => _isProcessing = true); // shows spinner on the button

  try {
    // Loop through each selected pending payment and mark it paid
    for (final payment in _pendingPayments
        .where((p) => _selectedPaymentIds.contains(p.id))) {
      await _apiService.updatePayment(payment.id, {
        'payment_status': 'paid',
        'payment_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        // Auto-generate receipt: "RCP-" + last 8 digits of timestamp
        'receipt_number': 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      });
    }

    setState(() => _paymentSuccess = true); // show success animation

    await Future.delayed(const Duration(seconds: 2)); // let user see the ✅

    setState(() {
      _showPaymentModal = false;
      _paymentSuccess = false;
      _selectedPaymentIds.clear();
    });

    await _loadPayments(); // refresh with updated data from server
  } catch (e) {
    // Show a snackbar (toast) at the bottom of the screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment failed. Please try again.')),
    );
  } finally {
    setState(() => _isProcessing = false); // always re-enable the button
  }
}
```

### Payment Row Builder

```dart
Widget _buildPaymentRow(Payment payment) {
  // Map status string → (background color, text color)
  final statusColors = {
    'paid':    (Color(0xFFD1FAE5), Color(0xFF065F46)), // green
    'pending': (Color(0xFFFEF3C7), Color(0xFF92400E)), // amber
    'overdue': (Color(0xFFFEE2E2), Color(0xFF991B1B)), // red
    'partial': (Color(0xFFDBEAFE), Color(0xFF1E40AF)), // blue
  };
  final colors = statusColors[payment.paymentStatus] ?? fallback;

  return Container(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        // Column 1: Date — shows payment date if paid, due date if pending
        Text(DateFormat('dd/MM/yyyy').format(
          payment.paymentDate ?? payment.dueDate, // '??' = null coalescing
        )),
        Text(payment.paymentDate != null ? 'Paid on' : 'Due by'),

        // Column 2: Semester or fallback label
        Text(payment.semester ?? 'Fee Payment'),

        // Column 3: Amount formatted as ₹1,000
        Text('₹${NumberFormat('#,##0').format(payment.amount)}'),

        // Column 4: Status badge (colored pill)
        Container(
          decoration: BoxDecoration(
            color: colors.$1,                          // background
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(payment.paymentStatus.toUpperCase(),
              style: TextStyle(color: colors.$2)),    // text color
        ),

        // Column 5: Receipt number in monospace font (or '-' if none)
        Text(payment.receiptNumber ?? '-',
            style: TextStyle(fontFamily: 'monospace')),
      ],
    ),
  );
}
```

### Pay Now Modal — Checkbox Selection

```dart
// The modal lets students select which pending payments to pay
Column(
  children: _pendingPayments.map((payment) {
    final isSelected = _selectedPaymentIds.contains(payment.id);

    return GestureDetector(
      // Tapping the entire row toggles the checkbox
      onTap: () => setState(() {
        if (isSelected) {
          _selectedPaymentIds.remove(payment.id);
        } else {
          _selectedPaymentIds.add(payment.id);
        }
      }),
      child: Container(
        // Selected items get highlighted background
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary50 : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primary300 : AppTheme.gray200,
          ),
        ),
        child: Row(
          children: [
            // The actual checkbox (also works independently)
            Checkbox(
              value: isSelected,
              activeColor: AppTheme.primary600,
              onChanged: (value) => setState(() {
                if (value ?? false) {
                  _selectedPaymentIds.add(payment.id);
                } else {
                  _selectedPaymentIds.remove(payment.id);
                }
              }),
            ),
            // Semester label + due date
            Text(payment.semester ?? 'Fee Payment'),
            Text('Due: ${DateFormat('dd/MM/yyyy').format(payment.dueDate)}'),
            // Amount (highlighted in primary color when selected)
            Text('₹${NumberFormat('#,##0').format(payment.amount)}',
                style: TextStyle(
                  color: isSelected ? AppTheme.primary600 : AppTheme.gray900,
                )),
          ],
        ),
      ),
    );
  }).toList(),
)
```

---

## 9. `lib/models/complaint.dart` — Static Utility Method

```dart
// Static method maps category string → emoji icon
// Called anywhere as: Complaint.getCategoryIcon('electrical') → '⚡'
static String getCategoryIcon(String category) {
  switch (category) {
    case 'electrical': return '⚡';
    case 'plumbing':   return '🚿';
    case 'furniture':  return '🪑';
    case 'cleaning':   return '🧹';
    case 'pest_control': return '🐛';
    case 'internet':   return '📶';
    case 'security':   return '🔒';
    default:           return '📝'; // fallback for 'other'
  }
}
```

---

## 10. `lib/models/payment.dart` — Computed Property

```dart
// Computed getter — no field, derived from paymentStatus at runtime
bool get isPending =>
    ['pending', 'overdue', 'partial'].contains(paymentStatus);
// Usage: if (payment.isPending) { ... }
// This avoids checking 3 separate conditions everywhere in the UI
```

---

## Key Dart / Flutter Concepts Used

| Concept | Where Used | What it does |
|---|---|---|
| `StatefulWidget` | All screens | Holds mutable state with `setState()` |
| `StatelessWidget` | `HostelApp`, simple widgets | No state, just renders |
| `ChangeNotifier` + `Provider` | `StudentProvider` | Global state that rebuilds listeners |
| `Consumer<T>` | Dashboard body | Rebuilds when provider changes |
| `context.read<T>()` | Event handlers | Gets provider without rebuilding |
| `Future<T>` + `async/await` | All API calls | Non-blocking async operations |
| `Future.wait([...])` | `getDashboardStats` | Runs multiple futures in parallel |
| `?.` (null-safe access) | `student?.roomId` | Safely accesses nullable values |
| `??` (null coalescing) | `json['field'] ?? ''` | Fallback when value is null |
| `!` (null assertion) | `_roomId!` | Asserts value is not null (use carefully) |
| `mounted` check | After `await` in `setState` | Prevents crash if widget was disposed |
| `ListView.builder` | Complaints, payments list | Lazy rendering — only builds visible items |
| `fold()` | Payment totals | Functional reduce/aggregate over a list |
| `.where()` | Filter payments/complaints | LINQ-like filtering |
| `DateFormat` (intl) | All date displays | Formats DateTime → readable strings |
| `NumberFormat.currency` | All money displays | Formats double → ₹1,000 |
| `Dart 3 Records ($1, $2)` | `statusColors` map | Tuple-like return of multiple values |

---

*End of Code Explanation — `hostel_app/MOBILE_APP_EXPLAINED.md`*
