# Ship the iOS app from Windows (no Mac)

The whole iOS build, signing, and TestFlight upload happen on **GitHub Actions
macOS runners**. You never need a Mac â€” you click "Run workflow" and install via
TestFlight. This is the same Flutter codebase as Android.

- Bundle ID: **`com.scanella.mobile`** (change it *everywhere* before your first
  upload if you want a different one â€” see "Change the bundle ID" below).
- Repo: `origin` is already set to `https://github.com/rakpa/cloude_code.git`.

---

## Step 0 â€” Push the code
From the project folder (`C:\RAKESH\Cloude code\others`):

```bash
git push -u origin main
```

This publishes the app + the two workflows. If GitHub asks for credentials, use a
**Personal Access Token** (github.com â†’ Settings â†’ Developer settings â†’ Tokens)
as the password.

## Step 1 â€” Get "it builds on iOS" green (no Apple account needed)
- On push, **iOS CI (Simulator)** runs automatically (or Actions tab â†’ run it).
- It compiles the app for the iOS simulator, launches it, and uploads a
  **screenshot artifact**. Green = the app builds and runs on iOS. ðŸŽ‰

## Step 2 â€” One-time Apple credentials (reused for ALL your apps)
1. **Team ID** â€” developer.apple.com â†’ Membership â†’ copy the 10-char Team ID.
2. **App Store Connect API key** â€” App Store Connect â†’ Users and Access â†’ Integrations
   â†’ App Store Connect API â†’ **generate a key with the `App Manager` role**.
   Download the **`.p8`** (once only), and note the **Key ID** and **Issuer ID**.

## Step 3 â€” Add 4 GitHub secrets
Repo â†’ Settings â†’ Secrets and variables â†’ Actions â†’ New repository secret:

| Secret | Value |
|--------|-------|
| `APPLE_TEAM_ID` | your 10-char Team ID |
| `ASC_KEY_ID` | the API Key ID |
| `ASC_ISSUER_ID` | the Issuer ID |
| `ASC_KEY_P8` | paste the **entire contents** of the `.p8` file |

## Step 4 â€” Register the app with Apple
1. **Identifiers** (developer.apple.com â†’ Certificates, IDs & Profiles â†’ Identifiers)
   â†’ register an App ID with bundle ID **`com.scanella.mobile`** (enable no special
   capabilities for now). *(fastlane can also create the provisioning profile
   automatically; the App ID must exist.)*
2. **App record** (App Store Connect â†’ Apps â†’ +) â†’ New App â†’ iOS â†’ pick the bundle
   ID â†’ give it a name (e.g. "Scanly"). This is required for TestFlight.

## Step 5 â€” Build a signed IPA
Actions â†’ **iOS Release (signed IPA)** â†’ Run workflow:
- `build_number`: `1`
- `upload_to_testflight`: **false** (first run â€” just prove signing works)

Success â†’ download the **`ios-ipa`** artifact. This confirms the Apple
Distribution cert + App Store profile + signing all work.

## Step 6 â€” Upload to TestFlight
Run **iOS Release** again with:
- `build_number`: `2`  *(must be higher than any previous upload)*
- `upload_to_testflight`: **true**

Then App Store Connect â†’ your app â†’ TestFlight â†’ wait for processing â†’ add
yourself as a tester / install the **TestFlight** app on your iPhone â†’ test on
device.

> **Bump `build_number` every single upload** â€” Apple rejects reused build numbers.

---

## Gotchas (each is a real, known failure)
- **Distribution cert limit (~2â€“3, account-wide across all your apps).** fastlane
  `cert` makes one per run. If you see "maximum number of certificates," revoke old
  **Apple Distribution** certs at developer.apple.com, or switch to fastlane `match`
  (one reused cert) â€” tell me and I'll convert it.
- **Newest Xcode is required** â€” Apple rejects uploads not built with the current
  iOS SDK. The workflows auto-select the newest Xcode on the runner; don't pin it.
- **Signing usually needs 1â€“2 iterations.** If a run fails, open the failing step,
  copy its log, and paste it to me â€” I'll fix the workflow and you re-run.
- **Export compliance** is pre-answered (`ITSAppUsesNonExemptEncryption=false` in
  Info.plist), so TestFlight won't ask.

## Change the bundle ID
If you want something other than `com.scanella.mobile`, change it in **all** of:
- `ios/Runner.xcodeproj/project.pbxproj` (bundle id occurrences)
- `ios/fastlane/Fastfile` (`APP_ID` default)
- `.github/workflows/ios-ci.yml` and `ios-release.yml` (`BUNDLE_ID`)

â€¦and register that ID in Step 4. (Tell me the ID you want and I'll do the swap.)

