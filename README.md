# Arab Chat Android starter

This project wraps the existing `index.html` in an Android APK using Capacitor and GitHub Actions.

## GitHub Actions
- Push these files to the default branch (`main` or `master`).
- Open Actions -> Build Arab Chat APK -> Run workflow if needed.
- Download the `Arab-Chat-debug-APK` artifact from a successful run.

Important: the current HTML app uses local browser storage for accounts/chat data. Packaging it as an APK does not create a shared backend or make Google sign-in real. Video calling/matching across devices needs a proper backend/signaling service before production use.
