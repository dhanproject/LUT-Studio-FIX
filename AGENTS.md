# Persistent Instructions for LUT Studio APK Build

## Critical Rules for GitHub Actions APK Build
- **Node.js Version:** ALWAYS use Node.js version 24 or higher. Capacitor 8+ will FAIL on Node 20.
- **Java Version:** Use OpenJDK 21 (Zulu) for maximum compatibility with modern Gradle.
- **File Structure:** Always ensure `package.json` and `index.html` are at the root directory. If the source comes from a ZIP, detect the inner folder and move contents to root.
- **Android Folder Management:** Never rely on the `android/` folder from a ZIP export. Delete it and regenerate using `npx cap add android` and `npx cap sync android` on the CI runner.
- **Capacitor Configuration:** If `capacitor.config.json` is missing, auto-generate a fallback to prevent build termination.
- **Gradle Execution:** Use `./gradlew assembleDebug --no-daemon` to ensure stability in headless CI environments.

## Deployment Workflow Summary
1. Cleanup root.
2. Unzip & Move to root.
3. Setup Node 24 & Java 21.
4. `npm install --legacy-peer-deps`.
5. `npm run build` (ensure `dist/` exists).
6. `npx cap add android` + `npx cap sync android`.
7. Gradle build.
