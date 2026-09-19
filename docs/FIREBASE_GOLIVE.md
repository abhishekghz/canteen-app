# Firebase Go-Live — remaining steps (all in the console, no CLI)

**Status from my live test against `canteen-app-72a86`:**
- ✅ Web app config wired into the app (`lib/firebase_options.dart`).
- ✅ **Email/Password auth is enabled and working** — I registered `admin@canteen.app`
  and Firebase Auth accepted it.
- ⛔ **Firestore rules are not published yet** → every read/write is denied
  (`permission-denied`). That's the one thing blocking the app.

Your Firebase CLI can't run on this machine (Node 26 breaks `firebase-tools`) and
Cloud Functions need the paid Blaze plan — so this setup uses **no CLI and no
Functions**. Admin is a `role: "admin"` field on your user document.

---

## Step 1 — Publish the Firestore rules  (fixes the permission error)
Firebase Console → **Build → Firestore Database → Rules** tab → replace all the
text with the contents of `firestore.rules` (in the project root) → **Publish**.

## Step 2 — Clean up the test admin user
Because rules weren't published when I tested, the `admin@canteen.app` user was
created in **Auth** but its profile document didn't save. Remove it so you can
re-create it cleanly:
- Console → **Build → Authentication → Users** → find `admin@canteen.app` → **Delete user**.

## Step 3 — Create the admin account (in the app)
Run the app against Firebase:
```bash
export PATH="$HOME/flutter-sdk/bin:$PATH"
cd "Canteen app"
flutter run -d chrome --dart-define=BACKEND=firebase
```
On the login screen → **Create an account** → register `admin@canteen.app` with a
password you choose. (This now succeeds and writes the profile doc.)

## Step 4 — Promote it to admin (one field edit)
Console → **Firestore Database → Data** → open collection **`users`** → open the
document whose `email` is `admin@canteen.app` → change field **`role`** from
`student` to **`admin`** → save.

## Step 5 — Seed the menu / prices / snack slots (one tap)
Sign out and log back in as `admin@canteen.app` → you now see the **Admin
Dashboard** → tap the **☁️ upload icon** (top-right, "Seed initial data").
This writes the default prices, the 7-day menu, and the 2 snack slots to Firestore.

## Done ✅
- Students: register in the app → book meals/snacks/coupons, pay (stub), see orders.
- Admin: edit menu, edit charges, set payment status, configure snack slots.
- Everything is real-time via Firestore, secured by the rules.

---

### Optional: wire Android & iOS to Firebase too
Web is enough to run against Firebase. For the native apps to use Firebase
(instead of the in-memory demo), add them in Console → **Project settings → Your
apps → Add app**:
- **Android**: package name `com.canteen.canteen_app` → download `google-services.json`
  into `android/app/`, and send me the Android **appId** (`1:…:android:…`).
- **iOS**: bundle id `com.canteen.canteenApp` → download `GoogleService-Info.plist`
  into `ios/Runner/`, and send me the iOS **appId** (`1:…:ios:…`).

Send me those two appIds and I'll finish `lib/firebase_options.dart`; then the
APK/iOS builds run against Firebase with `--dart-define=BACKEND=firebase`.
(You already have the Android `com.google.gms.google-services` plugin line — I'll
add it to the Gradle files when you send `google-services.json`.)
