# Daily Fitness

Daily Fitness is a cross-platform Flutter ecommerce system for gym equipment, supplements, and accessories.

## Features
- Flutter web and mobile-ready UI
- Firebase Authentication with email/password and Google sign-in
- Cloud Firestore based product, user, order, cart, and notification collections
- Firebase Storage support for document uploads
- Firebase Cloud Messaging integration for notifications
- Role-based access for Buyer, Seller, Rider, and Admin
- Responsive dashboards and consistent design across web and mobile

## Setup
1. Install Flutter and ensure it is on your PATH.
2. Add your Firebase project configuration to `lib/firebase_options.dart`.
3. Run `flutter pub get`.
4. Start the app with `flutter run -d chrome` for web or `flutter run` for mobile.

## Project Structure
- `lib/main.dart` — Application entry point
- `lib/app.dart` — Routing and providers
- `lib/services/` — Firebase, auth, Firestore, storage, notifications
- `lib/providers/` — Session and role state
- `lib/ui/` — Authentication, dashboards, and responsive views

## Firebase Collections
The app uses collections like `users`, `addresses`, `products`, `orders`, `notifications`, `sellerProfiles`, `riderProfiles`, `analytics`, `settings`, and more.
