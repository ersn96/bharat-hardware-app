# Bharat Hardware Electrical & Tools App

Vyapar-style billing and inventory management app for hardware shops.

## Features
- ✅ Create bills with GST
- ✅ Inventory management
- ✅ Low stock alerts
- ✅ Offline-first (works without internet)
- ✅ Print & share bills via WhatsApp
- ✅ Customer ledger (Udhar tracking)

## Build APK
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --release