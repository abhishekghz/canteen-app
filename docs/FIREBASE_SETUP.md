# Firebase Setup — what I need from you

You chose: **you create the project + share the web config.** Here's the exact,
minimal path. Steps 1–4 are yours; then paste me the values in step 5 and I wire
the app. Steps 6–7 you run once (they need your Google login, which I can't do).

The web config values (apiKey, appId, etc.) are **not secrets** — they ship in
every web app — so it's fine to paste them here.

---

## 1. Create the project
1. Go to https://console.firebase.google.com → **Add project**.
2. Name it (e.g. `canteen-app`). Google Analytics: optional (you can skip).

## 2. Enable Email/Password auth
- Left menu → **Build → Authentication → Get started**.
- **Sign-in method** tab → **Email/Password** → **Enable** → Save.

## 3. Create Firestore
- Left menu → **Build → Firestore Database → Create database**.
- Start in **production mode** (rules will be deployed later). Pick a region
  near you (e.g. `asia-south1` for India). Enable.

## 4. Register a Web app + get config
- Project Overview (top) → click the **`</>`** (Web) icon → give it a nickname
  (e.g. `canteen-web`) → **Register app**.
- You'll see a `firebaseConfig = { ... }` block. **Copy those values.**

## 5. Paste me these values
Send me this block (fill in your real values):

```
apiKey:            "..."
authDomain:        "....firebaseapp.com"
projectId:         "..."
storageBucket:     "....appspot.com"
messagingSenderId: "..."
appId:             "1:...:web:..."
```

If you also want the **Android** and **iOS** apps wired to Firebase, in Project
settings → *Your apps* → **Add app** for Android (package `com.canteen.canteen_app`)
and iOS (bundle id `com.canteen.canteenApp`), then send me:
- Android app's `appId` (looks like `1:...:android:...`)
- iOS app's `appId` (looks like `1:...:ios:...`)

(Not required to start — web is enough to see it working against Firebase.)

## 6. You run once: deploy rules + functions
After I wire the config, from the project folder:
```bash
npm i -g firebase-tools
firebase login
firebase use --add           # pick your new project, alias it "default"
cd functions && npm install && npm run build && cd ..
firebase deploy --only firestore:rules,firestore:indexes,functions
```

## 7. You run once: seed data + create the admin
```bash
firebase functions:secrets:set SETUP_SECRET     # choose any secret string
```
Then call the `bootstrap` callable once (email defaults to `admin@canteen.app`,
password `admin123` — change them). Easiest: I'll give you a tiny script, or you
can call it from the Firebase console's Functions tester with:
```json
{ "setupSecret": "<the secret you set>", "email": "admin@canteen.app", "password": "choose-a-strong-one" }
```

That creates the admin account (with the admin claim), and seeds pricing, the
weekly menu, and snack slots.

---

Once step 5 is in, I'll set `lib/firebase_options.dart`, and the app runs against
Firebase with:
```bash
flutter run -d chrome --dart-define=BACKEND=firebase
```
