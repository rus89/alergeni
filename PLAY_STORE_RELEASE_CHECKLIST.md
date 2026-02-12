# Android Google Play release checklist

This checklist is tailored for this repository and current Android setup.

## 1) Security and signing

- [x] Release signing wired in `android/app/build.gradle.kts`.
- [x] Keystore path read from `android/key.properties`.
- [x] `android/key.properties.example` added as a template.
- [x] Signing files added to `.gitignore`.
- [ ] Rotate the current keystore passwords if they were ever committed to a remote.
- [ ] Ensure `android/key.properties` is not tracked by git:
  - `git rm --cached android/key.properties`

## 2) Network policy

- [x] Replaced broad cleartext allowance with host-specific rule:
  - `android/app/src/main/res/xml/network_security_config.xml`
- [x] Manifest now references `android:networkSecurityConfig`.
- [ ] If API host changes from `77.46.150.200`, update `network_security_config.xml`.

## 3) App metadata

- [ ] Confirm final `version` in `pubspec.yaml` (`versionName+versionCode`).
- [ ] Confirm app title and icon in `AndroidManifest.xml` and launcher resources.
- [ ] Confirm package ID is final (`com.serbiaOpenData.udahni`).

## 4) Quality gates

- [x] `flutter analyze` equivalent check passed for touched files.
- [x] Release bundle build passed:
  - `flutter build appbundle --release`
  - output: `build/app/outputs/bundle/release/app-release.aab`
- [ ] Run regression smoke test on a physical Android device from the release build.

## 5) Play Console submission

- [ ] Create app in Play Console (if not already created).
- [ ] Complete Data safety form (location + network usage).
- [ ] Complete App content declarations (ads, target audience, etc. as applicable).
- [ ] Prepare listing assets (short description, full description, screenshots, icon, feature graphic).
- [ ] Upload `app-release.aab` to internal testing first.
- [ ] Verify install/update path from tester accounts.
- [ ] Promote to closed/open/production track after validation.
