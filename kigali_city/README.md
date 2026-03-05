# Kigali City Directory

A Flutter mobile application for discovering and managing services and places in Kigali, Rwanda. Built with Firebase Authentication, Cloud Firestore, Google Maps, and Riverpod state management.

---

## Features

- **Firebase Authentication** – Sign up, log in, log out with email & password. Email verification enforced before app access.
- **Location Listings (CRUD)** – Create, read, update, and delete service/place listings stored in Firestore.
- **Directory Search & Filtering** – Search by name and filter by category with real-time Firestore-backed updates.
- **Detail Page + Google Maps** – View listing details with an embedded map marker and turn-by-turn navigation.
- **Riverpod State Management** – All Firestore operations go through a service layer and are exposed via stream/state providers.
- **Bottom Navigation** – Directory, My Listings, Map View, and Settings tabs.
- **Settings** – User profile display and notification preference toggle (persisted locally + Firestore).

---

## Firebase Setup

### Prerequisites

1. Create a Firebase project at [https://console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Authentication** → **Email/Password** sign-in method.
3. Create a **Cloud Firestore** database (start in production mode then configure rules).
4. Run `flutterfire configure` to regenerate `lib/firebase_options.dart` for your project.

### Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // All authenticated users can read listings; only owner can write
    match /listings/{listingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.createdBy;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.createdBy;
    }
  }
}
```

### Firestore Collections

| Collection  | Document ID | Fields |
|-------------|-------------|--------|
| `users`     | User UID    | `uid`, `email`, `displayName`, `createdAt`, `notificationsEnabled` |
| `listings`  | Auto-ID     | `name`, `category`, `address`, `contactNumber`, `description`, `latitude`, `longitude`, `createdBy`, `createdByEmail`, `timestamp` |

### Firestore Indexes

The app uses the following compound queries which may require indexes:

- `listings` – `createdBy` (==) + `timestamp` (desc) → for My Listings screen
- `listings` – `timestamp` (desc) → for Directory screen

Create these indexes in the Firebase Console → Firestore → Indexes if you see an error in the debug console with a link.

---

## Google Maps Setup

### Get an API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Enable the **Maps SDK for Android** and **Maps SDK for iOS**.
3. Create an API key and restrict it to your app's bundle ID / SHA-1.

### Android

In `android/app/src/main/AndroidManifest.xml`, replace `YOUR_GOOGLE_MAPS_API_KEY`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY" />
```

### iOS

In `ios/Runner/AppDelegate.swift`, replace `YOUR_GOOGLE_MAPS_API_KEY`:

```swift
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY")
```

---

## State Management – Riverpod

All Firestore interactions are abstracted through a **service layer** and exposed to the UI via **Riverpod providers**. UI widgets never call Firebase APIs directly.

### Architecture

```
UI Widgets
    ↓  ref.watch / ref.read
Riverpod Providers (lib/providers/)
    ↓
Service Layer (lib/services/)
    ↓
Firebase (Auth + Firestore)
```

### Key Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `authStateChangesProvider` | `StreamProvider<User?>` | Reactive Firebase auth state |
| `authNotifierProvider` | `StateNotifierProvider<AuthNotifier>` | Sign up / sign in / sign out + loading & error states |
| `allListingsStreamProvider` | `StreamProvider<List<ListingModel>>` | Real-time stream of all listings |
| `myListingsStreamProvider` | `StreamProvider<List<ListingModel>>` | Real-time stream of user's own listings |
| `filteredListingsProvider` | `Provider<AsyncValue<List<ListingModel>>>` | Derived filtered/searched listings |
| `searchQueryProvider` | `StateProvider<String>` | Current search text |
| `categoryFilterProvider` | `StateProvider<String?>` | Selected category filter |
| `listingNotifierProvider` | `StateNotifierProvider<ListingNotifier>` | CRUD operations + loading & error states |
| `settingsNotifierProvider` | `StateNotifierProvider<SettingsNotifier>` | Notification preference toggle |

---

## Navigation Structure

```
AuthWrapper (auth gate)
├── LoginScreen → SignupScreen → VerifyEmailScreen
└── HomeScreen (BottomNavigationBar)
    ├── [0] DirectoryScreen → ListingDetailScreen
    ├── [1] MyListingsScreen → AddEditListingScreen
    ├── [2] MapViewScreen → ListingDetailScreen
    └── [3] SettingsScreen
```

---

## Running the App

```bash
# Install dependencies
flutter pub get

# Run on device/simulator
flutter run

# Build for Android
flutter build apk

# Build for iOS
flutter build ipa
```

---

## Color Theme

| Color | Hex | Usage |
|-------|-----|-------|
| Primary Blue | `#1565C0` | App bar, buttons, primary actions |
| Light Blue | `#1E88E5` | Secondary elements |
| Accent Yellow | `#FFC107` | FAB, badges, highlights |
| White | `#FFFFFF` | Backgrounds, cards |
