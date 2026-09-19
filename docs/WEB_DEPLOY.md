# Web — setup, test, and deploy to Firebase Hosting

Your Firebase project **`canteen-app-72a86`** is live and seeded (menu, prices,
snack slots). Default admin: **`admin@canteen.app` / `admin123`** (admin
everywhere, by email).

Toolchain is already installed on this Mac:
- Flutter → `~/flutter-sdk`
- Node 20 (for the Firebase CLI, since your system Node 26 breaks it) → `/opt/homebrew/opt/node@20`
- Firebase CLI → v13.8.0

---

## A. Test locally (optional)
```bash
export PATH="$HOME/flutter-sdk/bin:$PATH"
cd "Canteen app"
flutter run -d chrome --dart-define=BACKEND=firebase
```
- Register a student → book → pay → see it in Orders.
- Log in as `admin@canteen.app` / `admin123` → Admin Dashboard → edit menu, charges,
  set payment status.

## B. Deploy to Firebase Hosting (get a shareable link)

### Step 1 — log in (one time, interactive)
```bash
export PATH="/opt/homebrew/opt/node@20/bin:$PATH"
firebase login
```
This opens your browser to sign in with the Google account that owns the
Firebase project. (Needed once; the CLI remembers you.)

### Step 2 — build + deploy
From the project folder, either run the helper script:
```bash
./deploy-web.sh
```
…or do it manually:
```bash
export PATH="$HOME/flutter-sdk/bin:/opt/homebrew/opt/node@20/bin:$PATH"
flutter build web --dart-define=BACKEND=firebase
firebase deploy --only hosting
```

### Step 3 — share the link
After deploy, your app is live at:
```
https://canteen-app-72a86.web.app
```
(also https://canteen-app-72a86.firebaseapp.com). Both domains are already
authorized for Firebase Auth, so login/registration work on the shared link.

Anyone you send the link to can register as a student and use the app; you log
in as the admin with `admin@canteen.app` / `admin123`.

---

## Prefer I deploy it for you?
Do **Step 1** (`firebase login`) in your terminal, then tell me — I'll run the
build + deploy from here and hand you the live link. (Your login is stored
locally after Step 1, so I can deploy to your project without ever seeing your
credentials.)

## Updating later
Any time you change the app, re-run `./deploy-web.sh` to push a new version to
the same link.
