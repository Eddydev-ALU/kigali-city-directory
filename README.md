# Kigali City Directory

A Flutter mobile application for discovering and managing services and places in Kigali, Rwanda. Built with Firebase Authentication, Cloud Firestore, OpenStreetMap (via `flutter_map`), and Riverpod state management.

---

## Features

- **Firebase Authentication** – Sign up, log in, log out with email & password. Email verification enforced before app access.
- **Location Listings (CRUD)** – Create, read, update, and delete service/place listings stored in Firestore. Each listing stores a real latitude and longitude.
- **Directory Screen** – Redesigned home feed with a personalised greeting (`Hello, {firstname}`), headline, search bar, square category cards with icons and subtle shadows, and a live listing count.
- **Search & Category Filtering** – Real-time text search and category filtering with an animated square-card category selector.
- **Map View (OpenStreetMap)** – Interactive map displaying all listings as colour-coded markers per category. Tapping a marker flies the camera to that location and opens an info sheet. The count badge lets you jump directly to a single location or open a searchable location-chooser list when there are multiple listings.
- **Listing Detail** – Full detail page with an embedded mini-map (OSM) showing the exact location, get-directions button, contact call, like/unlike, and edit/delete for the owner.
- **My Location (GPS)** – "Use My Location" button in the Add/Edit form uses `geolocator` to pre-fill coordinates with high-accuracy GPS. On simulators/emulators use the device's location override; on a real device it returns your actual GPS position.
- **Liked Listings** – Users can like/unlike listings; liked listings are shown in a dedicated tab in My Listings.
- **Riverpod State Management** – All Firestore operations go through a service layer and are exposed via stream/state providers.
- **Bottom Navigation** – Directory, My Listings, Map View, and Settings tabs.
- **Settings** – User profile display and notification preference toggle (persisted locally + Firestore).

---

## Map Technology — OpenStreetMap

The app originally used **Google Maps** (`google_maps_flutter`). This was replaced with **OpenStreetMap** via `flutter_map` + `latlong2` for the following reasons:

- No API key required — no billing setup, no quota limits for a small app.
- Works out of the box on iOS and Android with zero native configuration.
- Open data, open source.

**Known limitations of OpenStreetMap:**

- Tile data accuracy varies by region. Some streets and buildings in Kigali may be incomplete, outdated, or missing compared to Google Maps.
- The public OSM tile server (`tile.openstreetmap.org`) is intended for low-volume use. For a production app with significant traffic, consider a third-party tile provider (Mapbox, Stadia Maps, etc.) or self-hosted tiles.
- There is no built-in turn-by-turn navigation SDK; the "Get Directions" button opens Google Maps in the browser as a workaround.

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
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /listings/{listingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.createdBy;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.createdBy;
    }
  }
}
```

### Firestore Collections

| Collection | Document ID | Fields |
|---|---|---|
| `users` | User UID | `uid`, `email`, `displayName`, `createdAt`, `notificationsEnabled`, `likedListings` |
| `listings` | Auto-ID | `name`, `category`, `address`, `contactNumber`, `description`, `latitude`, `longitude`, `createdBy`, `createdByEmail`, `timestamp` |

### Firestore Indexes

- `listings` – `createdBy` (==) + `timestamp` (desc) → My Listings screen
- `listings` – `timestamp` (desc) → Directory / all listings

Create these in Firebase Console → Firestore → Indexes if you see a console error with a direct link.

---

## State Management – Riverpod

All Firestore interactions are abstracted through a **service layer** and exposed to the UI via **Riverpod providers**.

### Architecture

```
UI Widgets
    ↓  ref.watch / ref.read
Riverpod Providers  (lib/providers/)
    ↓
Service Layer       (lib/services/)
    ↓
Firebase (Auth + Firestore)
```

### Key Providers

| Provider | Type | Purpose |
|---|---|---|
| `authStateChangesProvider` | `StreamProvider<User?>` | Reactive Firebase auth state |
| `authNotifierProvider` | `StateNotifierProvider<AuthNotifier>` | Sign up / sign in / sign out |
| `currentUserProfileProvider` | `FutureProvider<UserModel?>` | Logged-in user's Firestore profile |
| `likedListingIdsProvider` | `StreamProvider<List<String>>` | Real-time liked listing IDs |
| `allListingsStreamProvider` | `StreamProvider<List<ListingModel>>` | Real-time all listings (re-subscribes only on UID change) |
| `myListingsStreamProvider` | `StreamProvider<List<ListingModel>>` | Real-time listings owned by current user |
| `filteredListingsProvider` | `Provider<AsyncValue<List<ListingModel>>>` | Derived filtered/searched listings |
| `searchQueryProvider` | `StateProvider<String>` | Current search text |
| `categoryFilterProvider` | `StateProvider<String?>` | Selected category filter |
| `listingNotifierProvider` | `StateNotifierProvider<ListingNotifier>` | CRUD operations + loading & error states |
| `likedListingsProvider` | `Provider<AsyncValue<List<ListingModel>>>` | Full listing objects for liked IDs |
| `settingsNotifierProvider` | `StateNotifierProvider<SettingsNotifier>` | Notification preference toggle |

---

## Navigation Structure

```
AuthWrapper (auth gate)
├── WelcomeScreen
├── LoginScreen → SignupScreen → VerifyEmailScreen
└── HomeScreen (BottomNavigationBar)
    ├── [0] DirectoryScreen → ListingDetailScreen
    ├── [1] MyListingsScreen (My Listings tab + Liked tab)
    │       └── AddEditListingScreen (add + edit)
    ├── [2] MapViewScreen → ListingDetailScreen
    └── [3] SettingsScreen
```

---

## Folder Structure

```
kigali-city-directory/
├── README.md
└── kigali_city/                      # Flutter project root
    ├── pubspec.yaml
    ├── android/
    ├── ios/
    └── lib/
        ├── main.dart                 # App entry point, Firebase init
        ├── firebase_options.dart     # Generated by flutterfire CLI
        ├── assets/
        │   └── kigali.jpeg
        ├── models/
        │   ├── listing_model.dart    # ListingModel + categories list
        │   └── user_model.dart       # UserModel
        ├── providers/
        │   ├── auth_provider.dart    # Auth state, notifier, user profile
        │   ├── listing_provider.dart # Listing streams, filters, CRUD notifier
        │   └── settings_provider.dart
        ├── screens/
        │   ├── auth/
        │   │   ├── welcome_screen.dart
        │   │   ├── login_screen.dart
        │   │   ├── signup_screen.dart
        │   │   └── verify_email_screen.dart
        │   ├── directory/
        │   │   ├── directory_screen.dart   # Redesigned home with greeting + OSM categories
        │   │   └── listing_detail_screen.dart
        │   ├── home/                       # HomeScreen (bottom nav shell)
        │   ├── map_view/
        │   │   └── map_view_screen.dart    # OSM map, markers, location chooser
        │   ├── my_listings/
        │   │   ├── my_listings_screen.dart # My Listings + Liked tabs
        │   │   └── add_edit_listing_screen.dart  # GPS "Use My Location" button
        │   └── settings/
        │       └── settings_screen.dart
        ├── services/
        │   ├── auth_service.dart
        │   └── listing_service.dart
        ├── theme/
        │   └── app_theme.dart        # AppColors + AppTheme
        └── widgets/
            └── listing_card.dart
```

---

## Running the App

```bash
# Install dependencies
flutter pub get

# iOS – install pods (required after adding/removing packages)
cd ios && pod install && cd ..

# Run on device/simulator
flutter run

# Build for Android
flutter build apk

# Build for iOS
flutter build ipa
```

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^4.5.0 | Firebase initialisation |
| `firebase_auth` | ^6.2.0 | Email/password authentication |
| `cloud_firestore` | ^6.1.3 | Database (listings + user profiles) |
| `flutter_riverpod` | ^2.6.1 | State management |
| `flutter_map` | ^8.2.2 | OpenStreetMap rendering |
| `latlong2` | ^0.9.1 | Lat/lng coordinate type for flutter_map |
| `geolocator` | ^14.0.2 | Device GPS for "Use My Location" |
| `url_launcher` | ^6.3.1 | Open directions in external maps app |
| `intl` | ^0.20.1 | Date formatting |
| `shared_preferences` | ^2.3.3 | Local settings persistence |
| `uuid` | ^4.5.1 | Unique ID generation |

---

## Color Theme

| Color | Hex | Usage |
|---|---|---|
| Primary Blue | `#0A2463` | App bars, buttons, primary actions |
| Light Blue | `#1E3B96` | Secondary elements |
| Dark Blue | `#061A40` | Dark backgrounds |
| Accent Yellow | `#FFC107` | FAB, badges, highlights |
| White | `#FFFFFF` | Backgrounds, cards |
| Light Grey | `#F5F5F5` | Input fills, category square backgrounds |
