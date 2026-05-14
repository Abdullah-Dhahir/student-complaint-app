# Student Complaint and Suggestion Mobile App

A Flutter mobile application for students to submit complaints and suggestions about university facilities, services, or academic issues, with an admin panel for managing complaints.

## Project Information

- **Project Supervisor:** Mohammad Salim
- **Platform:** Android, iOS, macOS
- **Framework:** Flutter
- **State Management:** setState (Simple)

## Features

### Student Features
- ✅ Login and Registration
- ✅ Submit complaints with category selection and description
- ✅ View all submitted complaints with status tracking
- ✅ Filter complaints by status (All, Received, In Progress, Resolved)
- ✅ View detailed complaint information
- ✅ Track complaint status with unique tracking numbers
- ✅ Receive admin responses

### Admin Features
- ✅ View all complaints from all students
- ✅ Update complaint status (Received → In Progress → Resolved)
- ✅ Add responses to complaints
- ✅ Dashboard with statistics

## Technology Stack

- **Flutter SDK:** ^3.8.1
- **Dart:** ^3.8.1
- **Dependencies:**
  - intl: ^0.19.0 (Date formatting)
  - cupertino_icons: ^1.0.8

## Project Structure

```
lib/
├── models/              # Data models
│   ├── complaint.dart   # Complaint model with status enum
│   └── user.dart        # User model with role enum
├── screens/             # UI screens
│   ├── login_screen.dart
│   ├── registration_screen.dart
│   ├── student_home_screen.dart
│   ├── admin_home_screen.dart
│   ├── submit_complaint_screen.dart
│   ├── complaint_detail_screen.dart
│   └── admin_complaint_detail_screen.dart
├── widgets/             # Reusable widgets
│   └── complaint_card.dart
├── data/               # Dummy data for testing
│   └── dummy_data.dart
├── utils/              # Utilities
│   ├── app_theme.dart  # App theme and colors
│   └── helpers.dart    # Helper functions
└── main.dart           # App entry point
```

## Status Colors

- 🔴 **Red (Received):** New complaints that haven't been reviewed yet
- 🟠 **Orange (In Progress):** Complaints being actively worked on
- 🟢 **Green (Resolved):** Complaints that have been resolved

## Demo Credentials

### Student Account
- Username: `student1`
- Password: `password123`

### Admin Account
- Username: `admin`
- Password: `password123`

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK (3.8.1 or higher)
- Android Studio / VS Code with Flutter extensions
- iOS Simulator / Android Emulator / Physical device

### Installation

1. Navigate to the project directory
```bash
cd student_complaint_app
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
# For Android
flutter run -d android

# For iOS
flutter run -d ios

# For macOS
flutter run -d macos
```

## Usage

### For Students

1. **Login/Register:**
   - Open the app
   - Login with credentials or register a new account
   - Email verification required after registration

2. **Submit a Complaint:**
   - Tap the "New Complaint" floating button
   - Select a category from the dropdown
   - Write a detailed description (minimum 20 characters)
   - Optionally add a photo (coming soon)
   - Submit the complaint

3. **Track Complaints:**
   - View all your complaints on the home screen
   - Filter by status (Received, In Progress, Resolved)
   - Tap on any complaint to view full details
   - Check for admin responses

### For Admins

1. **Login:**
   - Login with admin credentials

2. **View Complaints:**
   - See all complaints from all students
   - View statistics by status
   - Filter complaints by status

3. **Manage Complaints:**
   - Tap on any complaint to open details
   - Update the status (Received/In Progress/Resolved)
   - Add a response message for the student
   - Save changes

## Complaint Categories

- Classroom Facilities
- Cafeteria
- Library
- IT Services
- Hostel
- Transportation
- Administration
- Academic
- Sports Facilities
- Other

## Features Currently Using Dummy Data

The following features are implemented with dummy data and will require Firebase integration later:

- ✅ User authentication (currently validates against dummy users)
- ✅ Complaint submission (simulates network delay)
- ✅ Complaint status updates (simulates update process)
- ⏳ Photo upload (placeholder - shows "coming soon" message)
- ⏳ Push notifications (not yet implemented)

## Next Steps (Firebase Integration)

1. **Firebase Authentication:**
   - Replace dummy login with Firebase Auth
   - Implement email verification
   - Add password reset functionality

2. **Firebase Firestore:**
   - Store complaints in Firestore
   - Real-time complaint updates
   - Query and filter complaints

3. **Firebase Storage:**
   - Upload complaint images
   - Store user profile pictures

4. **Firebase Cloud Messaging:**
   - Push notifications for status changes
   - Admin response notifications

5. **Additional Features:**
   - Image upload from camera/gallery
   - Offline support with local caching
   - Search functionality
   - Complaint analytics for admin

## Design Decisions

### Simple State Management
- Uses `setState` for state management (beginner-friendly)
- No complex state management solutions needed for this app size
- Easy to understand and maintain

### University Theme
- Primary Color: Dark Blue (#1E3A8A)
- Secondary Color: Light Blue (#3B82F6)
- Accent Color: Gold/Amber (#F59E0B)
- Professional and clean design

### User Experience
- Intuitive navigation
- Clear status indicators with colors
- Form validation for all inputs
- Loading states for async operations
- Success/error feedback with snackbars

## Testing

Currently, the app uses dummy data for testing. You can:

1. Login as different users (student1, student2, admin)
2. Submit new complaints as a student
3. View and manage complaints as an admin
4. Test all status transitions
5. Test filtering functionality

## Known Limitations

- Camera/Photo upload not yet implemented
- Push notifications not yet implemented
- No actual backend/Firebase integration
- No offline data persistence
- Search functionality not implemented

## Learning Outcomes

Students working on this project will learn:

- ✅ Building complete Flutter mobile apps
- ✅ Working with forms and validation in Flutter
- ✅ Navigation and routing between screens
- ✅ State management with setState
- ✅ Creating reusable widgets
- ✅ Implementing user authentication flows
- ✅ Different user roles (student vs admin)
- ✅ Material Design principles
- ✅ Clean code practices in Dart

Future learning (with Firebase):
- Firebase Authentication integration
- Firestore database operations
- Firebase Storage for images
- Push notifications with FCM
- Real-time data synchronization

## Contributing

This is a student project. For questions or issues, contact the project supervisor.

## License

This project is created for educational purposes as part of university coursework.

---

**Last Updated:** November 22, 2025
**Version:** 1.0.0
