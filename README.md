# PassportIDPhotoMaker

Generated from niche `id-photo-maker` (Scanning, tier A, score 78).

**Utility:** Compliant passport/visa/ID photos from a selfie
**Primary ASO keyword:** `passport photo`
**Also target:** `id photo`, `visa photo`, `passport size photo`, `passport photo maker`
**Paywall hook:** All country sizes, background removal, print sheet

> Bg-remove + size templates. One-time high intent; people pay to avoid a store trip.

## Build it

```bash
brew install xcodegen        # once
cd PassportIDPhotoMaker
xcodegen generate
open PassportIDPhotoMaker.xcodeproj
```

The app runs immediately on a MockPurchaseProvider (real paywall UI, fake
purchases). To go live:

1. Replace `revenueCatKey` in `Sources/App.swift` with your RevenueCat key.
2. In App Store Connect create products `id-photo-maker_yearly` and `id-photo-maker_weekly`,
   map them into a RevenueCat offering, entitlement id `premium`.
3. Build the real feature in `Sources/ContentView.swift`.
4. **Guideline 4.3:** make the function, UI, screenshots and keywords genuinely
   distinct from any sibling app. Re-niche, never reskin.

Bundle id: `com.zubeid.idphotomaker`

## Ship to TestFlight

This app ships with a Fastlane lane + GitHub Actions workflow. One-time account
setup (API key, signing) is documented in the kit's `Tools/appgen/DEPLOYMENT.md`.
Once your GitHub secrets are set, trigger the **TestFlight** workflow (or push a
`v*` tag), or run locally:

```bash
bundle install
bundle exec fastlane beta
```
