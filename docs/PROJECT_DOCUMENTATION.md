# Daily Fitness - E-Commerce System Documentation

## Project Overview
Daily Fitness is a cross-platform e-commerce application built with Flutter and Firebase for selling gym equipment, supplements, and fitness accessories. It supports 4 user roles: Buyer, Seller, Rider, and Admin.

## Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Auth, Storage, Messaging)
- **Image Storage**: Cloudinary
- **Deployment**: Railway (Web), Google Play (Android)
- **State Management**: Provider

## Live URLs
- **Web App**: https://dailyfitness-production.up.railway.app
- **GitHub**: https://github.com/tsukasakazuki354-lang/dailyfitness

---

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (UI)                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│  │  Buyer   │ │  Seller  │ │  Rider   │ │  Admin   │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘   │
├─────────────────────────────────────────────────────────┤
│                  Providers (State)                        │
│              SessionProvider (Auth State)                 │
├─────────────────────────────────────────────────────────┤
│                    Services Layer                         │
│  AuthService | FirestoreService | CloudinaryService      │
│  NotificationService | StorageService                    │
├─────────────────────────────────────────────────────────┤
│                  Firebase Backend                         │
│  ┌────────────┐ ┌────────────┐ ┌────────────────────┐   │
│  │ Firestore  │ │    Auth    │ │  Cloud Messaging   │   │
│  └────────────┘ └────────────┘ └────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                  External Services                        │
│  ┌────────────┐ ┌────────────┐                           │
│  │ Cloudinary │ │   Google   │                           │
│  │  (Images)  │ │  Sign-In   │                           │
│  └────────────┘ └────────────┘                           │
└─────────────────────────────────────────────────────────┘
```

---

## User Roles & Features

### Buyer
- Browse products by category
- Search and filter products
- Add to cart with quantity selection
- Selectable cart items for checkout
- Place orders with address selection
- Track order status in real-time
- Write product reviews with star ratings
- Manage wishlist
- View order history with status tabs
- Manage saved addresses (cascading PH dropdowns)
- Edit profile
- View notifications

### Seller
- Add/edit/delete products with image upload
- View and manage orders
- Assign riders to deliveries
- Update order status (confirm → pickup → delivery → complete)
- View product reviews and reply to customers
- Analytics dashboard with charts
- Store settings (customization, payment, shipping, security)
- Profile management

### Rider
- View assigned deliveries
- Update delivery status
- Track earnings and reports
- Submit complaints/feedback
- Profile management

### Admin
- Approve/decline/suspend seller and rider accounts
- Monitor all products on platform
- View platform analytics with charts
- Manage all users (search, filter by status)

---

## Database Schema (Firestore)

### Collection: `users`
| Field | Type | Description |
|-------|------|-------------|
| uid | string | Firebase Auth UID |
| role | string | buyer/seller/rider/admin |
| firstName | string | First name |
| lastName | string | Last name |
| username | string | Unique username |
| email | string | Email address |
| phoneNumber | string | Phone number |
| profileImage | string | Profile image URL |
| status | string | active/pending/declined/suspended |
| createdAt | timestamp | Account creation date |
| updatedAt | timestamp | Last update date |

### Collection: `products`
| Field | Type | Description |
|-------|------|-------------|
| productId | string | Unique product ID |
| sellerId | string | Seller's UID |
| category | string | Gym Equipment/Supplements/Accessories |
| productName | string | Product name |
| description | string | Product description |
| price | number | Product price |
| salePrice | number | Discounted price (0 if none) |
| stock | number | Available quantity |
| status | string | active/inactive/draft |
| images | array | List of image URLs |
| tags | array | Product tags |
| createdAt | timestamp | Creation date |
| updatedAt | timestamp | Last update |

### Collection: `orders`
| Field | Type | Description |
|-------|------|-------------|
| orderId | string | Unique order ID |
| buyerId | string | Buyer's UID |
| sellerId | string | Seller's UID |
| riderId | string | Assigned rider's UID |
| items | array | List of order items |
| subtotal | number | Items total |
| shippingFee | number | Shipping cost |
| total | number | Grand total |
| paymentMethod | string | cod/card/gcash |
| paymentStatus | string | pending/paid |
| orderStatus | string | pending/confirmed/for_pickup/on_delivery/delivered/completed/cancelled |
| deliveryStatus | string | Same as orderStatus |
| statusHistory | array | [{status, timestamp}] |
| address | map | Delivery address |
| createdAt | timestamp | Order date |
| updatedAt | timestamp | Last update |

### Collection: `carts`
| Field | Type | Description |
|-------|------|-------------|
| cartId | string | Same as userId |
| userId | string | Owner's UID |
| items | array | [{productId, name, image, quantity, price}] |
| totalAmount | number | Cart total |
| updatedAt | timestamp | Last update |

### Collection: `addresses`
| Field | Type | Description |
|-------|------|-------------|
| addressId | string | Unique address ID |
| userId | string | Owner's UID |
| region | string | Philippine region |
| provinceCity | string | Province or city |
| municipality | string | Municipality |
| barangay | string | Barangay |
| streetAddress | string | Street/house number |
| zipCode | string | Zip code |
| isDefault | boolean | Default address flag |
| createdAt | timestamp | Creation date |

### Collection: `reviews`
| Field | Type | Description |
|-------|------|-------------|
| reviewId | string | Unique review ID |
| productId | string | Product being reviewed |
| userId | string | Reviewer's UID |
| userName | string | Reviewer's name |
| rating | number | 1-5 stars |
| comment | string | Review text |
| sellerReply | string | Seller's response |
| createdAt | timestamp | Review date |

### Collection: `wishlist`
| Field | Type | Description |
|-------|------|-------------|
| userId | string | Document ID = user UID |
| productIds | array | List of saved product IDs |
| updatedAt | timestamp | Last update |

### Collection: `notifications`
| Field | Type | Description |
|-------|------|-------------|
| notificationId | string | Unique ID |
| userId | string | Recipient's UID |
| title | string | Notification title |
| message | string | Notification body |
| type | string | info/order/promo/delivery |
| isRead | boolean | Read status |
| createdAt | timestamp | Send date |

### Collection: `sellerProfiles`
| Field | Type | Description |
|-------|------|-------------|
| sellerId | string | Same as UID |
| storeName | string | Store name |
| businessType | string | Individual/Corporation/Partnership |
| businessPermitUrl | string | Document URL |
| taxRegistrationUrl | string | Document URL |
| validIdUrl | string | Document URL |
| verificationStatus | string | pending/approved/declined |
| commissionRate | number | Platform commission |

### Collection: `riderProfiles`
| Field | Type | Description |
|-------|------|-------------|
| riderId | string | Same as UID |
| validIdUrl | string | Document URL |
| driverLicenseUrl | string | Document URL |
| performanceStats | map | {totalDeliveries, onTimeRate} |
| riderLevel | string | Bronze/Silver/Gold |
| verificationStatus | string | pending/approved/declined |

---

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # Routes & providers
├── firebase_options.dart        # Firebase config
├── data/
│   └── ph_address_data.dart     # Philippine address data
├── models/
│   ├── app_user.dart
│   ├── product.dart
│   ├── order.dart
│   ├── cart_item.dart
│   ├── address.dart
│   └── notification_model.dart
├── providers/
│   └── session_provider.dart    # Auth state management
├── services/
│   ├── auth_service.dart        # Firebase Auth + Google
│   ├── firebase_service.dart    # Firebase initialization
│   ├── firestore_service.dart   # Firestore CRUD
│   ├── cloudinary_service.dart  # Image uploads
│   ├── notification_service.dart
│   └── storage_service.dart
└── ui/
    ├── shared/
    │   ├── splash_screen.dart
    │   ├── guest_page.dart
    │   ├── theme_palette.dart
    │   ├── address_dropdown_fields.dart
    │   └── document_upload_field.dart
    ├── auth/
    │   ├── login_page.dart
    │   ├── register_page.dart
    │   ├── buyer_register_page.dart
    │   ├── seller_register_page.dart
    │   └── rider_register_page.dart
    ├── guest/
    │   └── guest_shell.dart
    ├── buyer/
    │   ├── buyer_shell.dart
    │   ├── buyer_home_content.dart
    │   ├── shop_page.dart
    │   ├── product_detail_page.dart
    │   ├── cart_page.dart
    │   ├── checkout_page.dart
    │   ├── wishlist_page.dart
    │   ├── order_history_page.dart
    │   ├── order_detail_page.dart
    │   ├── saved_addresses_page.dart
    │   ├── profile_page.dart
    │   └── notifications_page.dart
    ├── seller/
    │   ├── seller_shell.dart
    │   └── pages/
    │       ├── seller_overview_page.dart
    │       ├── seller_products_page.dart
    │       ├── seller_orders_page.dart
    │       ├── seller_analytics_page.dart
    │       ├── seller_reviews_page.dart
    │       ├── seller_warnings_page.dart
    │       ├── seller_settings_page.dart
    │       └── seller_profile_page.dart
    ├── rider/
    │   ├── rider_shell.dart
    │   └── pages/
    │       ├── rider_overview_page.dart
    │       ├── rider_earnings_page.dart
    │       ├── rider_deliveries_page.dart
    │       ├── rider_complaints_page.dart
    │       ├── rider_map_page.dart
    │       └── rider_profile_page.dart
    └── admin/
        ├── admin_shell.dart
        └── pages/
            ├── admin_overview_page.dart
            ├── admin_users_page.dart
            ├── admin_products_page.dart
            └── admin_analytics_page.dart
```

---

## Security & Access Control

| Role | Signup | Login Requirement |
|------|--------|-------------------|
| Buyer | Immediate access | Email/password or Google |
| Seller | Pending admin approval | Must be approved first |
| Rider | Pending admin approval | Must be approved first |
| Admin | Pre-configured | Full access |

### Firestore Rules Summary
- Users can read/write their own documents
- Admin can write to any user document
- Authenticated users can read products
- Orders accessible by buyer, seller, or rider involved
- Reviews writable by authenticated users

---

## Deployment

### Web (Railway)
- Dockerfile builds Flutter web and serves with Nginx
- Auto-deploys on GitHub push
- URL: https://dailyfitness-production.up.railway.app

### Android
- Build: `flutter build apk --release`
- Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS
- Build: `flutter build ios --release`
- Requires Xcode and Apple Developer account

---

## Setup Instructions

1. Clone: `git clone https://github.com/tsukasakazuki354-lang/dailyfitness.git`
2. Install dependencies: `flutter pub get`
3. Configure Firebase: Update `lib/firebase_options.dart`
4. Configure Cloudinary: Update `lib/services/cloudinary_service.dart`
5. Run: `flutter run`

## Environment Requirements
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Firebase project with Auth, Firestore, Storage, Messaging
- Cloudinary account with unsigned upload preset
- Android Studio / VS Code with Flutter extension
