# Nabta — polished kid-friendly build

## What's inside
- `lib/` — the full app (replace your existing `lib/` folder with this one)
- `pubspec.yaml` — dependencies (replace yours with this)

## How to install into your project
1. In your Flutter project, **delete your old `lib/` folder** and copy this `lib/` in its place.
2. **Replace your `pubspec.yaml`** with the one here.
3. In VS Code terminal (or via Command Palette → "Dart: Get Packages"):
   run `flutter pub get`.
4. Run it: press **F5** (Chrome) to test, or push to GitHub for the Android APK.

> Your Firebase keys are already filled in (`lib/main.dart`) — it connects to your
> existing `courses-app-6476a` project, so all your subjects/courses/users still work.

## New dependency
- `google_fonts` — used for the friendly rounded "Cairo" font (works for Arabic + English).
  It downloads the font at runtime, so the device needs internet on first launch.

## Cloud steps required
Only ONE small Firestore rules addition is needed — the progress dashboard now stores
each completed lesson's title, which your current rules already allow (the
`completedLessons` sub-collection). **If you already published the rules with the
`completedLessons` block, you are done — no cloud change needed.**

If you have NOT yet added that block, publish this in Firebase Console → Firestore →
Rules (it's your existing rules plus the `completedLessons` match):

```
match /users/{userId} {
  allow read: if isSignedIn() && request.auth.uid == userId;
  allow create: if isSignedIn() && request.auth.uid == userId;
  allow update: if isSignedIn()
    && request.auth.uid == userId
    && request.resource.data.role == resource.data.role;

  match /completedLessons/{lessonId} {
    allow read, write: if isSignedIn() && request.auth.uid == userId;
  }
}
```

Nothing else in the cloud changes. No new services, no paid features.

## Notes
- If your `test/widget_test.dart` still references the old `MyApp`, delete that test
  file — the app is now `NabtaApp`. (It doesn't affect the APK build.)
- Teacher code is in `lib/services/auth_service.dart` → `teacherCode`.

---

## 🎨 NEW: illustrations (playful UI update)
The UI now has a sky theme, bubble quiz answers, hero banners and mascot slots.

To add your own illustrations, open `assets/images/README_IMAGES.txt` — it lists
the exact file names to drop in (home_mascot.png, video_mascot.png, celebrate.png,
trophy.png) and how to resize/move them. Until you add files, friendly emoji
placeholders show automatically, so the app runs immediately.

The image-slot widget is `lib/widgets/app_image.dart`:
    AppImage('home_mascot.png', width: 92)   // change width to resize

---

## 🎨 Illustrations + 🔊 sounds (already embedded)
Your 6 characters and 3 sounds are already inside this project and wired up —
nothing to add. See `assets/images/README_IMAGES.txt` for the mapping and how to
swap/resize any of them.

New dependency added: `audioplayers` (for the sound effects). Because the
dependencies changed, run **`flutter pub get`** after copying the files in.

Sounds:
- correct answer  -> assets/sounds/correct.wav
- wrong answer    -> assets/sounds/wrong.wav
- lesson complete -> assets/sounds/complete.wav
