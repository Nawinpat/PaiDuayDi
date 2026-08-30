# PaiDuayDi

Android application for finding compatible travel companions and nearby trips.

## Google Maps setup (Android)

The Home screen shows Google Maps behind the trip sheet and requests the
device's location while the app is open.

1. Create a Google Maps Platform API key and enable **Maps SDK for Android**
   and **Places API (New)**.
2. Create or update `android/local.properties` (this file is ignored by Git):

   ```properties
   GOOGLE_MAPS_API_KEY=your_android_restricted_key
   ```

3. Restrict the key to the Android application ID `com.paiduaydi.paiduaydi`
   and its signing certificate SHA-1 before distributing the app.
4. Run `flutter pub get`, then `flutter run` on an Android device/emulator.

No key is stored in this repository. Without it, the app UI will run but Google
Maps cannot load map tiles.
