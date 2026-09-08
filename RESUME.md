# Where this stands

Last worked on: 7 September 2026. Paused to upgrade macOS.

## The goal

A personal allergen scanner for iPhone. Point it at food packaging; it reads
the ingredients, looks up the barcode, and says whether the allergens in the
profile are present. Built for one family's use, not the App Store.

Default profile is **peanuts, tree nuts and egg**.

## What is done and verified

**The engine** (`Engine/`) is finished and tested. It is a plain Swift package
with no UI and no Apple frameworks, so it builds and runs its own checks with
Command Line Tools alone — no Xcode needed:

```bash
swift run --package-path Engine Validate    # 49/49 passing
```

Also has a CLI front end using the same logic the app uses:

```bash
swift run --package-path Engine Check 3017620422003            # live barcode lookup
swift run --package-path Engine Check "sugar, whey, almonds"   # as if OCR read it
swift run --package-path Engine Check --all <barcode>          # all 14 allergens
swift run --package-path Engine Check --only milk,eggs "..."   # custom profile
```

Both were confirmed working against the live Open Food Facts API.

## What is NOT verified

**`App/` has never been compiled.** Xcode was not installed on this machine —
only Command Line Tools, so there was no iOS SDK to build against. The nine
Swift files pass `swiftc -parse`, which catches syntax errors but not type
errors.

**Expect the first build to fail with a list of errors.** That is anticipated,
not a sign the design is wrong. Work through them; the shapes most likely to
need fixing are the AVFoundation capture delegate, the `@MainActor` isolation
in `CameraController`, and SwiftUI API details in `ScanView` / `ResultView`.

## Pick up here

1. **Install Xcode.** On macOS 15.6.1 the ceiling was **Xcode 26.3** (26.4+
   requires macOS Tahoe 26.2). After upgrading macOS, take the current Xcode
   from the App Store instead — the version constraint goes away.

   ```bash
   sudo xcode-select -s /Applications/Xcode.app
   xcodebuild -version
   ```

2. **Generate the project and open it.**

   ```bash
   brew install xcodegen
   cd /Users/Dima/code/alergenscan
   xcodegen generate          # AlergenScan.xcodeproj is generated, not committed
   open AlergenScan.xcodeproj
   ```

3. **Set signing.** Xcode → Settings → Accounts → add Apple ID. Then target
   `AlergenScan` → Signing & Capabilities → Team. If the bundle ID collides,
   change `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` and re-run `xcodegen
   generate` — never edit the `.xcodeproj` directly, it is regenerated.

4. **Fix the first build.** See above.

5. **Test on a real iPhone.** The simulator has **no camera**, so OCR and
   barcode scanning cannot be tested there at all. The simulator does exercise
   the Allergens tab and the "Enter barcode" path. Everything else needs
   hardware and iOS 16+.

   A free Apple ID works but the app expires off the phone every 7 days.

### What to try once it runs

| Case | Expected |
|---|---|
| Something with nuts | Red, naming the word that triggered it |
| Plain rice or pasta | Green, "None of your allergens found" |
| Peanut butter, coconut milk | Must **not** flag dairy |
| Most chocolate | Amber trace warning, not red |
| Point at a blank wall, Scan | "Couldn't check this" — never green |

That last one matters most: an unreadable label must never read as an all-clear.

## Decisions already made — don't relitigate these

- **Sources are unioned, never averaged.** If the label says no milk and the
  database says milk, the answer is milk. Conflicts resolve to the more
  cautious reading, so the failure mode is a false alarm, not a missed allergen.
- **The app never says "safe."** The strongest claim is "None of your allergens
  found" — about what was read, not about the food.
- **Matching is longest-phrase-first with span consumption.** This is what stops
  "peanut butter" reading as dairy. Do not replace it with substring search.
- **Deterministic dictionary, no LLM on the matching path.** A false negative
  can hospitalise someone; a model that occasionally invents an answer is not
  an acceptable component here.
- **Non-English terms are not optional.** Open Food Facts returns ingredients in
  the product's own language. An English-only dictionary silently missed milk on
  every French label — that bug was found and fixed.

## Open questions

- **Which country?** Decides how good Open Food Facts coverage will be —
  strong in France, decent in US/Germany/Spain, thin elsewhere. Never answered.
- **The son's exact allergens.** Defaults are peanuts + tree nuts + egg. If the
  nut allergy is only one of the two, `Allergen.defaultProfile` in
  `Engine/Sources/AllergenEngine/Allergen.swift` is a one-line change.
- **Should "may contain" default to flagging?** Currently yes, as its own amber
  state. Depends on how severe the allergy is.

## Also in this repo

`docs/research/allergen-research.md` — domain research on competitors, data
sources, regulation and risks. **It contains at least two known errors**: it
claims Open Food Facts has no allergen profile (it does), and it lists
Spoonful's monthly price as $3.99 (it is $4.99). Its numbers were not all
verified. Treat it as a starting point, not a reference.

Worth knowing before building further: **Fig** and **Spoonful** already do the
packaged-goods scanning well, and both have 7-day trials. Open Food Facts' own
app is free and unlimited. Testing those against a real shopping basket is
still the cheapest way to find out whether this project needs to exist.
