# Running AlergenScan on your iPhone

## What you need

1. **Xcode** — free from the Mac App Store. Not currently installed on this
   machine; the engine below builds without it, but the app does not.
2. **XcodeGen** — generates the Xcode project from `project.yml`:
   ```bash
   brew install xcodegen
   ```

## Build it

```bash
cd /Users/Dima/code/alergenscan
xcodegen generate          # creates AlergenScan.xcodeproj
open AlergenScan.xcodeproj
```

In Xcode: select your iPhone as the run destination, set **Signing & Capabilities
→ Team** to your Apple ID, then press ⌘R.

> With a free Apple ID the app stops working after 7 days and needs rebuilding
> from Xcode. A paid Apple Developer account ($99/year) removes that.

### The simulator cannot test scanning

**The iOS Simulator has no camera.** OCR and barcode scanning cannot be tested
there at all — you need a real iPhone for anything involving the viewfinder.

What *does* work in the simulator: the Allergens tab, and **Enter barcode** on
the Scan screen, which exercises the Open Food Facts lookup, the engine, and the
result screen without a camera. That covers most of the app's logic. Everything
else needs hardware.

## Try it without Xcode

The engine has a command-line front end using exactly the same logic the app
does. No Xcode, no iPhone, no build:

```bash
swift run --package-path Engine Check 3017620422003          # by barcode
swift run --package-path Engine Check "sugar, whey, almonds" # by ingredients
swift run --package-path Engine Check --all 5000159407236    # all 14 allergens
swift run --package-path Engine Check --only milk,eggs "..."  # a custom profile
```

Barcode input goes to the live Open Food Facts API. Text input is treated as if
OCR had read it off a packet. This is the fastest way to find a missing synonym:
type an ingredient list that fooled the app and see what comes back.

## Check the allergen engine

The engine is a plain Swift package and needs no Xcode at all:

```bash
swift run --package-path Engine Validate
```

That runs the full safety suite and exits non-zero if anything fails. **Run it
after every change to the dictionary.** A missing synonym is a false negative,
which is the one failure mode that actually matters here.

## Adding an ingredient the app missed

This will happen — the dictionary is not complete and cannot be.

1. Add the term to `Engine/Sources/AllergenEngine/AllergenDictionary.swift`
   (or `AllergenDictionaryEU.swift` for French, German, Spanish, Italian).
   Write it **without accents** — text is folded before matching.
2. Add a test for it in `Engine/Sources/Validate/Suite.swift` and register it
   in `allTests` at the bottom.
3. Run `swift run --package-path Engine Validate`.

If the new term is a phrase that contains a shorter one — like `oat milk` —
the longest-first matcher handles it automatically. If it is a phrase that
should flag *nothing* but must stop a shorter term matching inside it — like
`coconut milk` — add it with `nil` as the allergen.
