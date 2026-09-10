# Where this stands

Last worked on: 9 September 2026. Building, signed, and installed on
the phone. Not yet tested against real food.

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

**The app** (`App/`) compiles clean — no errors, no warnings — for both the
simulator and the device, and is installed on Dmitry's iPhone (iPhone 16 Pro,
iOS 26.6.1). It launches and the Allergens tab works. It has an icon.

## What is NOT verified

**Nothing has been tested against real packaging yet.** The app builds, signs,
installs and launches on hardware, and the engine's 49 checks pass — but no
actual food has been scanned. Everything below the camera is exercised only by
synthetic input.

Specifically unverified:

- **OCR quality on real labels.** Small print, curved packets, foil, low light.
- **The readiness thresholds** in `FrameAnalyzer` (4 lines / 40 characters /
  0.3 confidence). Picked by reasoning, not tuned against real packets. If the
  button lights up on a brand name, raise them; if it never lights up on a
  genuine ingredients list, lower them.
- **Whether Open Food Facts actually covers the food in this house.** See the
  country question below.

## Building it

Xcode 26.6 is at `/Applications/Xcode.app`. The iOS 26.5 platform is
installed. Signing is set up: free personal team `A8XUB34269`, pinned in
`project.yml`, so `xcodegen generate` never loses it.

Everything runs from the command line — no need to drive the Xcode UI:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodegen generate                      # after any project.yml change

# simulator (no camera — Allergens tab and "Enter barcode" only)
xcodebuild -project AlergenScan.xcodeproj -scheme AlergenScan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# the phone
xcodebuild -project AlergenScan.xcodeproj -scheme AlergenScan \
  -destination 'id=86BADED2-A859-51BB-B550-BD5B2F00DA51' \
  -allowProvisioningUpdates build
xcrun devicectl device install app --device 86BADED2-A859-51BB-B550-BD5B2F00DA51 \
  <path to built AlergenScan.app>
```

The phone must be **unlocked** to launch, and Developer Mode is already on.
**Builds expire after 7 days** — free account. Reinstall with the two commands
above. Ticking "Connect via network" in Xcode's Devices window makes that work
over Wi-Fi without the cable.

The app icon is generated, not hand-drawn: `python3 Tools/make_icon.py` writes
straight into the asset catalog. Edit the script, not the PNG.

## What to try — none of this is done yet

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
