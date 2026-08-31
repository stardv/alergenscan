# AlergenScan

A personal allergen checker for iPhone. Point it at a food package; it reads the
ingredients, looks up the barcode, and tells you whether the allergens *you* care
about are in there.

## How it decides

Two sources, in this order:

1. **The label.** On-device OCR (Apple's Vision framework) reads the ingredients
   printed on the packet. This is the primary source, because it is the packet in
   your hand — it cannot be out of date.
2. **Open Food Facts.** If a barcode is in the frame, the product is looked up in
   the free, open database. This is the fallback for when the label can't be read,
   and a second opinion when it can.

**The two are unioned, never averaged.** If the label says no milk and the
database says milk, the answer is milk. A disagreement always resolves to the
more cautious reading, so a conflict produces a false alarm rather than a missed
allergen.

## What it will not say

It never says "safe". The strongest claim on the result screen is *"None of your
allergens found"* — a statement about what was read, not a promise about the
food. Every result carries the reason for its verdict ("Because of: whey,
butter") so you can check it against the packet by eye.

When nothing could be read at all, it says **"Couldn't check this"** rather than
showing a reassuring green screen.

## Layout

```
Engine/     Swift package. All the allergen logic. No UI, no Apple frameworks.
            Builds and tests without Xcode.
App/        SwiftUI iPhone app: camera, Vision OCR, result screen.
project.yml XcodeGen spec that wires the two together.
docs/       Domain research: competitors, data sources, regulation, risks.
```

The split is deliberate. The engine is the part that can hurt someone if it's
wrong, so it is kept free of UI concerns and covered by a suite you can run in
one command:

```bash
swift run --package-path Engine Validate
```

See [SETUP.md](SETUP.md) to build and install the app.

## Defaults

A fresh install watches for **peanuts, tree nuts and egg**. Change it on the
Allergens tab — any of the 14 can be toggled, and there are one-tap buttons to
reset, select all, or clear.

Peanuts and tree nuts are separate entries because they are separate allergens:
a peanut is a legume. The default watches both, since "a nut allergy" in
ordinary use usually means both and guessing narrow would be the unsafe guess.

To change what a fresh install starts with, edit one line —
`Allergen.defaultProfile` in `Engine/Sources/AllergenEngine/Allergen.swift`.
It applies on first launch only: once the profile has been edited the user's
choice wins, and clearing every allergen stays cleared.

## The dictionary

`Engine/Sources/AllergenEngine/AllergenDictionary.swift` maps roughly 340
ingredient names onto the 14 allergens that must be declared under EU
Regulation 1169/2011 — a set that covers all nine required in the US.

It knows the derivatives that never say the allergen's name: casein, whey and
lactoserum are milk; semolina and spelt are gluten; albumen and lysozyme are
egg. `AllergenDictionaryEU.swift` adds French, German, Spanish and Italian,
because Open Food Facts returns ingredients in the product's own language and
European packaging is printed in it.

Matching is longest-phrase-first with span consumption, so "peanut butter" does
not read as dairy and "coconut milk" does not read as milk. A term can imply
several allergens at once where the ingredient really does carry them —
marzipan is almonds *and* egg white, surimi is fish *and* egg.

**A missing synonym here is a false negative.** Treat additions the way you would
treat a change to a medical device: add the term, add a test, run the suite.

## Limits worth knowing

- Coverage in Open Food Facts is strong in France, decent in the US, Germany and
  Spain, and thin elsewhere. A "not found" often means a gap in the database,
  not an absence of allergens.
- Database entries go stale when manufacturers reformulate. Entries older than a
  year are flagged in the result.
- OCR cannot see what the label doesn't say. "Natural flavourings" can hide an
  allergen, and no amount of parsing will reveal it.
- Nothing here is medical advice, and none of it replaces reading the packet.
