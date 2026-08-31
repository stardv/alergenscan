# AlergenScan — Domain Research Report

**Date:** August 2026
**Scope:** Market landscape, data sources, regulation, technical approaches, and MVP recommendation for a mobile app that identifies allergens in packaged foods (barcode scan or name search) and restaurant dishes.

---

## Table of Contents

1. [Market & Competitors](#1-market--competitors)
2. [Packaged-Goods Data Sources](#2-packaged-goods-data-sources)
3. [Restaurant Data — The Hard Problem](#3-restaurant-data--the-hard-problem)
4. [Name Search](#4-name-search)
5. [Regulation](#5-regulation)
6. [Technical Approaches](#6-technical-approaches)
7. [Recommended MVP](#7-recommended-mvp)
8. [Risks](#8-risks)
9. [Recommendation & Open Questions](#9-recommendation--open-questions)

---

## 1. Market & Competitors

### 1.1 Yuka

| Attribute | Detail |
|---|---|
| **Core mechanic** | Barcode scan of packaged food and cosmetics. Rates products 0–100: 60 % nutritional quality (Nutri-Score), 30 % additives, 10 % organic. |
| **Data source** | Open Food Facts + proprietary corrections layer. Users can contribute missing products. |
| **Monetization** | Freemium. Free scanning; premium ($14.99 /yr) unlocks offline mode, dietary-preference filters (gluten, lactose), and ad-free experience. |
| **Geographic coverage** | Strong in France (origin), good in EU/UK, expanding in US. >50 M downloads globally. |
| **Restaurant coverage** | **None.** Packaged goods only. |
| **Common complaints** | Premium paywall for allergen filtering; allergen detection is superficial (preferences, not true ingredient-level analysis); inaccurate ratings for niche products; poor coverage outside France/US; no "may contain" handling. ([App Store](https://apps.apple.com/us/app/yuka-food-cosmetic-scanner/id1092799236)) |

### 1.2 Open Food Facts App

| Attribute | Detail |
|---|---|
| **Core mechanic** | Barcode scan. Shows raw product data: ingredients, Nutri-Score, NOVA group, allergen tags. |
| **Data source** | Open Food Facts database (ODbL licence). Entirely crowdsourced. |
| **Monetization** | Non-profit, donation-funded. Fully free, no ads. |
| **Geographic coverage** | 3+ million products, 200+ countries. France dominant (~1.2 M), then US (~860 K), Germany (~390 K), Spain (~360 K). Thin coverage in Asia, Africa, Latin America. ([Open Food Facts](https://world.openfoodfacts.org/countries)) |
| **Restaurant coverage** | **None.** |
| **Common complaints** | Data quality is inconsistent (crowdsourced); many products have missing or malformed allergen fields; OCR-extracted ingredients often contain errors; UX is utilitarian; no personalised allergen profile or alerts. |

### 1.3 Fig (Food Scanner & Discovery)

| Attribute | Detail |
|---|---|
| **Core mechanic** | Barcode scan + product search. Compares each product's ingredient list and allergen statement against a personal dietary profile. Supports "every dietary restriction and allergy" including Low FODMAP, histamine, Alpha-Gal, etc. |
| **Data source** | Proprietary database, augmented by Open Food Facts and user submissions. Claims 1 M+ members. |
| **Monetization** | Freemium. Free barcode scanning; premium unlocks advanced filters and expanded product library. |
| **Geographic coverage** | Primarily US. Growing UK presence. Limited outside English-speaking markets. |
| **Restaurant coverage** | **Limited.** Fig has added restaurant/chain menu scanning for selected US chains, but coverage is shallow — mainly the top fast-food brands. Not a primary feature. |
| **Common complaints** | Missing products outside US; false positives (overly cautious flagging); premium tier needed for full functionality; slow to add new products. ([Fig vs Yuka comparison](https://www.oliveapp.com/blogs/fig-vs-yuka-app), [Trash Panda comparison](https://www.trashpandaapp.com/blog/comparing-different-food-scanner-apps)) |

### 1.4 Spoonful

| Attribute | Detail |
|---|---|
| **Core mechanic** | Barcode scan with traffic-light result (green / yellow / red). Detects the top 8 US allergens, plus gluten (celiac-specific) and FODMAP content. |
| **Data source** | Proprietary database curated by Monash-trained dietitians. |
| **Monetization** | Freemium. Basic scanning free; premium ($3.99/mo or $29.99/yr) for FODMAP analysis, advanced filters, and alternatives. Acquired by MWM (French app studio). |
| **Geographic coverage** | US, UK, Australia. Product database skews heavily Anglophone. |
| **Restaurant coverage** | **None.** Packaged goods only. |
| **Common complaints** | Small product database relative to Yuka/Fig; "product not found" is frequent; sometimes flags safe products as yellow; Australian/UK coverage is shallow. ([App Store](https://apps.apple.com/us/app/spoonful-diet-food-scanner/id1481914232), [Spoonful blog](https://blog.spoonfulapp.com/update-support-for-top-8-allergens/)) |

### 1.5 ContentChecked

| Attribute | Detail |
|---|---|
| **Core mechanic** | Barcode scan. Checks product against a personal allergen/ingredient avoidance list. Covers >200 K products. Scans for the US top 9 plus EU allergens (celery, mustard, lupin, etc.). |
| **Data source** | Proprietary database. |
| **Monetization** | Free with ads; premium removes ads. |
| **Geographic coverage** | Primarily US. |
| **Restaurant coverage** | **None.** |
| **Common complaints** | Outdated database; many products not found; UX feels dated; limited outside US; app updates have been infrequent (unclear if still actively maintained as of 2026). ([Food Allergy Institute review](https://foodallergyinstitute.com/resources/blog/4-best-apps-for-food-allergies)) |

### 1.6 Soosee

| Attribute | Detail |
|---|---|
| **Core mechanic** | **OCR-based.** Points camera at an ingredient list (no barcode needed); highlights allergens and unwanted ingredients in real-time using on-device text recognition. |
| **Data source** | No database — works directly from the label text via OCR. Users configure which ingredients to flag. |
| **Monetization** | Freemium. Basic scanning free; premium unlocks custom ingredient lists and additional dietary profiles. |
| **Geographic coverage** | Language-dependent. Works well for English and several European languages. Accuracy degrades with non-Latin scripts. |
| **Restaurant coverage** | **None** (requires a printed ingredient list to scan). |
| **Common complaints** | OCR accuracy issues on curved, glossy, or low-contrast labels; cannot identify allergens not explicitly listed (e.g., "natural flavours" hiding an allergen); no database means no cross-reference or completeness check; no barcode mode. ([Osana comparison](https://osana.co/blog/yuka-alternatives)) |

### 1.7 AllergyEats

| Attribute | Detail |
|---|---|
| **Core mechanic** | **Restaurant reviews and ratings.** Users rate restaurants on allergy-friendliness. Search by location, cuisine, and allergen. |
| **Data source** | User-generated reviews. No structured allergen-per-dish data. |
| **Monetization** | Free. Revenue from restaurant partnerships / advertising. |
| **Geographic coverage** | US only. |
| **Restaurant coverage** | **Primary focus**, but it is a review/rating platform, not a dish-level allergen database. Tells you whether a restaurant is *generally* accommodating, not whether a specific dish contains milk. |
| **Common complaints** | Sparse reviews outside major metro areas; no structured allergen data per dish; more useful for dining confidence than for ingredient-level safety; stale reviews; app UX is dated. ([LA Food Allergy](https://www.lafoodallergy.com/learn/the-best-food-allergy-apps-managing-allergies-with-ease-and-confidence)) |

### 1.8 Spokin

| Attribute | Detail |
|---|---|
| **Core mechanic** | **Community reviews** of restaurants, products, and recipes, filtered by allergen. 73 K+ reviews across 80 countries. Also offers curated "safe product" lists and travel guides. |
| **Data source** | User-contributed reviews. Covers 78 allergens. Editorially curated guides. |
| **Monetization** | Free (iOS only). Revenue model unclear — likely sponsorship and partnerships. |
| **Geographic coverage** | Global in theory (reviews from 80 countries), but density is overwhelmingly US-centric. |
| **Restaurant coverage** | **Yes — community-based.** Users share which restaurants were safe for their specific allergies. Filtered by allergen and cuisine. More granular than AllergyEats but still review-based, not dish-level ingredient data. |
| **Common complaints** | iOS-only (no Android); review density is thin outside major US cities; no barcode scanning; no structured ingredient-level data; relies entirely on community — if a restaurant has no reviews, there's nothing. ([App Store](https://apps.apple.com/us/app/spokin-manage-food-allergies/id1201909035), [Spokin](https://www.spokin.com/about-the-spokin-app)) |

### 1.9 Competitive Gap Summary

| Capability | Yuka | OFF | Fig | Spoonful | ContentChecked | Soosee | AllergyEats | Spokin |
|---|---|---|---|---|---|---|---|---|
| Barcode scan | Yes | Yes | Yes | Yes | Yes | No | No | No |
| OCR scan | No | No | No | No | No | **Yes** | No | No |
| Name / text search | No | Yes | Yes | No | No | No | No | No |
| Restaurant dishes | No | No | Partial | No | No | No | Reviews | Reviews |
| Allergen profile | Premium | No | Yes | Yes | Yes | Yes | N/A | Yes |
| "May contain" | No | Partial | Partial | Yes | No | No | N/A | N/A |

**Key takeaway:** No existing app combines barcode scanning, name search, *and* restaurant-dish allergen lookup in a single experience. The restaurant gap is the widest. AllergyEats and Spokin provide restaurant *reviews* (social proof) but not structured allergen-per-dish data. Fig has limited chain coverage. This is the main opportunity for AlergenScan.

---

## 2. Packaged-Goods Data Sources

### 2.1 Open Food Facts (OFF)

| Attribute | Detail |
|---|---|
| **API** | REST. `GET https://world.openfoodfacts.org/api/v2/product/{barcode}` returns JSON with `allergens_tags`, `traces_tags`, `ingredients_text`, `labels_tags`, etc. Also supports search by name. V2 is current; V3 in development. ([API docs](https://openfoodfacts.github.io/openfoodfacts-server/api/)) |
| **Licence** | Open Database License (ODbL). Free for any use including commercial, with attribution and share-alike. |
| **Product count** | ~3.5 M products (Aug 2026). France ~1.2 M, US ~860 K, Germany ~390 K, Spain ~360 K, UK ~178 K. ([Country stats](https://world.openfoodfacts.org/countries)) |
| **Allergen field quality** | `allergens_tags` uses a controlled vocabulary (e.g., `en:milk`, `en:gluten`). Populated on ~60–70 % of products that have ingredients. Quality varies: strong for French/German products (active community), weaker in US/Asia. Many products have ingredients text but no parsed allergen tags — the ingredients are there, but tag extraction hasn't been done or verified. |
| **Regional gaps** | Thin in Asia (Japan, China, India), Latin America, Middle East, Africa. US coverage is decent for supermarket brands but weak for regional / ethnic brands. |
| **Rate limits** | No hard rate limit for reasonable use. Guideline: max 100 req/min. Bulk data available as CSV/JSONL dump (~7 GB). |
| **Cost** | Free. |

### 2.2 USDA FoodData Central

| Attribute | Detail |
|---|---|
| **API** | REST. `GET https://api.nal.usda.gov/fdc/v1/food/{fdcId}?api_key=KEY`. Free API key required. ([Docs](https://fdc.nal.usda.gov/api-guide)) |
| **Licence** | Public domain (US government data). |
| **Content** | ~400 K food items across Foundation Foods, SR Legacy, Branded Food Products (from Label Insight partnership). Branded dataset has ~350 K products with UPC barcodes and ingredient lists. |
| **Allergen fields** | **No dedicated allergen field.** You get `ingredients` as a text string. Allergen extraction must be done by parsing. Some entries in the branded dataset include a `labelNutrients` block but not allergen declarations. |
| **Regional gaps** | US-only focus. No international barcodes. |
| **Rate limits** | 3,600 requests/hour per key. |
| **Cost** | Free. |

### 2.3 Nutritionix

| Attribute | Detail |
|---|---|
| **API** | REST + NLP endpoint (`POST /v2/natural/nutrients` accepts free-text like "Big Mac with fries"). Barcode lookup via `GET /v2/search/item?upc={barcode}`. ([API](https://www.nutritionix.com/api)) |
| **Licence** | Commercial. No redistribution without licence. |
| **Content** | ~1 M branded products (US-centric) + restaurant items from 200+ US chain restaurants. |
| **Allergen fields** | Limited. Nutritionix focuses on macronutrients (calories, fat, protein, etc.). Allergen attributes exist but are inconsistently populated. Ingredient text is available for parsing. |
| **Restaurant data** | **This is the main differentiator.** Nutritionix has structured nutrition data for menu items at major US chains (McDonald's, Chick-fil-A, Starbucks, etc.). Allergen flags are present for some chains but not universal. |
| **Cost** | Starts at **$1,850/month** for commercial use. Free tier exists for non-commercial / educational with 50 requests/day. |
| **Rate limits** | Depends on plan. |
| **Regional gaps** | Almost entirely US. No meaningful EU coverage. |

### 2.4 Edamam

| Attribute | Detail |
|---|---|
| **API** | Multiple APIs: Food Database API (barcode lookup, text search), Nutrition Analysis API (parse ingredient strings and return nutrients + allergens), Recipe Search API. ([Docs](https://developer.edamam.com/)) |
| **Licence** | Commercial. |
| **Allergen fields** | The Nutrition Analysis API can take an ingredient string and return `healthLabels` including `GLUTEN_FREE`, `DAIRY_FREE`, `PEANUT_FREE`, etc. These are inferred from ingredient parsing, not from manufacturer declarations. |
| **Content** | ~900 K branded products (US + some EU). |
| **Cost** | Free tier: 100 calls/min, 1 K calls/month. Developer: $29/month. Pro: $249/month. Enterprise: custom. |
| **Regional gaps** | US-heavy. EU coverage limited. |

### 2.5 Spoonacular

| Attribute | Detail |
|---|---|
| **API** | REST. Includes `GET /food/products/upc/{upc}` for barcode lookup, ingredient parsing, and recipe analysis. Returns allergen information (intolerances field). ([Docs](https://spoonacular.com/food-api)) |
| **Licence** | Commercial. |
| **Content** | ~500 K products (aggregated from multiple sources). |
| **Allergen fields** | Returns `intolerances` array. Quality is reasonable for US products, inconsistent for EU. |
| **Cost** | Free: 150 requests/day. $30/month: 1,500/day. $60/month: 3,000/day. Higher tiers available. |
| **Regional gaps** | Primarily US. |

### 2.6 FSA / FDA Datasets

| Source | Detail |
|---|---|
| **UK FSA** | The Food Standards Agency publishes allergen guidance and compliance tools but does **not** operate a public product-level allergen database or API. Their focus is on business compliance, not consumer lookup. ([FSA PPDS guidance](https://www.food.gov.uk/business-guidance/prepacked-for-direct-sale-ppds-allergen-labelling-changes-for-restaurants-cafes-and-pubs)) |
| **US FDA** | FDA requires allergen labelling but does not maintain a searchable product database with allergen fields. Recall data includes allergen-related recalls and can be accessed via the [openFDA API](https://open.fda.gov/apis/food/enforcement/), which is useful for flagging recalled products but not for general allergen lookup. |

### 2.7 GS1 / UPC Barcode Lookup Services

| Service | Coverage | Cost | Notes |
|---|---|---|---|
| **GS1 (official)** | Authoritative barcode registry. GTIN → brand owner mapping. | Enterprise pricing. Not consumer-facing. | Does **not** include ingredients or allergens — just product identity. |
| **UPCitemdb** | ~32 M barcodes | Free: 100 req/day. Paid from $10/mo. | Returns product name, brand, category, images. No ingredients or allergens. |
| **Barcode Lookup** | ~25 M barcodes | Free: 50 req/month. Paid from $29/mo. | Similar to UPCitemdb. No allergen data. |
| **Open EAN/GTIN DB** | Varies | Free | Community-maintained. Sparse allergen data. |

**Verdict on barcode services:** Useful for resolving an unknown barcode to a product name and brand (to then search in OFF or other databases), but none provide allergen or ingredient data. They are a fallback for barcode resolution, not a primary data source.

### 2.8 Comparison Matrix

| Source | Barcode coverage | Allergen field | Licence | Cost | Best for |
|---|---|---|---|---|---|
| **Open Food Facts** | 3.5 M (EU-heavy) | Structured tags (variable quality) | ODbL (free) | Free | MVP backbone |
| **USDA FoodData** | 350 K (US only) | None (raw ingredients only) | Public domain | Free | US gap-fill |
| **Nutritionix** | 1 M (US) + restaurants | Limited | Commercial | $1,850+/mo | Restaurant data |
| **Edamam** | 900 K (US-leaning) | Inferred from parsing | Commercial | $29–249+/mo | Ingredient parsing API |
| **Spoonacular** | 500 K (US) | Intolerances array | Commercial | $30–60+/mo | Budget commercial API |
| **UPC lookup services** | 25–32 M | None | Commercial | $10–29+/mo | Barcode → name resolution |

### 2.9 MVP Data Strategy Recommendation

**Primary backbone: Open Food Facts.** It is free, open-licensed, has the best EU coverage, and includes structured allergen tags. Its weaknesses (US regional brands, inconsistent tag quality) are manageable.

**Gap-filling strategy:**
1. **USDA FoodData Central** (free) for US-branded products not in OFF. Parse ingredient strings for allergens.
2. **Own OCR pipeline** — when a barcode resolves to a product but has no allergen tags, prompt the user to photograph the ingredient list. Parse it on-device or server-side.
3. **Community contribution** — let users submit corrections and missing products (mirroring OFF's model).
4. **Paid API (Edamam or Spoonacular)** only if scale justifies cost, primarily for the ingredient-parsing NLP endpoint rather than raw product data.

---

## 3. Restaurant Data — The Hard Problem

### 3.1 What Chain Restaurants Publish

Most large chains publish allergen information, but in wildly inconsistent formats:

| Chain | Format | Allergens covered | Accessibility |
|---|---|---|---|
| **McDonald's** | PDF booklet (UK: [allergen booklet](https://www.mcdonalds.com/gb/en-gb/good-to-know/allergen-booklet.html)); web nutrition page (US); in-app | EU 14 (UK), US Big 9 (US) | PDF is scrapeable but changes layout without notice. No API. |
| **Starbucks** | PDF and website; in-app | Varies by region | No API. PDF format changes frequently. |
| **Subway** | Interactive HTML allergen chart on website | EU 14 / US 9 depending on region | HTML table — somewhat scrapeable. |
| **Chipotle** | Online nutrition calculator + allergen toggles | US Big 9 | Custom web widget — possible to scrape, fragile. |
| **Nando's** | PDF and website with allergen filter | EU 14 (UK/EU) | Reasonably structured HTML. |
| **Pret a Manger** | Website + in-store labelling (post-Natasha's Law) | EU 14 | HTML with allergen icons. Better than most. |
| **Domino's** | Website allergen matrix | EU 14 (UK), US 9 (US) | HTML table — scrapeable. |

**Pattern:** Every chain does it differently. There is no standard format, no shared schema, and no API. Scraping is possible but maintenance-heavy — menus change seasonally, and layouts break without warning.

### 3.2 Aggregator APIs

| Aggregator | Restaurant coverage | Allergen data | Cost | Verdict |
|---|---|---|---|---|
| **Nutritionix** | 200+ US chains, 180 K+ menu items | Partial allergen flags (not universal) | $1,850+/mo | Best available but expensive and US-only. Allergen fields are not consistently populated. |
| **MenuStat** | NYC Health Department initiative. ~90 US chains. | Calories, sodium, etc. **No allergen fields.** | Free (research use) | Not useful for allergens. |
| **Edamam** | Limited restaurant coverage | Can parse dish descriptions for allergens (NLP) | $29–249+/mo | Ingredient parsing is useful, but requires you to supply the dish description/recipe. |

**No aggregator provides reliable, comprehensive, dish-level allergen data for restaurants — let alone across both US and EU.**

### 3.3 Independent Restaurants

**Blunt assessment: reliable allergen data for independent restaurants is not obtainable at scale.**

- Independent restaurants change menus frequently, often daily.
- Ingredient sourcing varies by supplier availability.
- Even where EU law requires allergen disclosure (see §3.4), compliance is often a printed sheet or verbal communication by staff — not a structured, machine-readable dataset.
- No aggregator, scraper, or API covers independent restaurants.
- Crowdsourced data (Spokin model) is better than nothing but is unverifiable, may be outdated by the time someone reads it, and creates liability risk.

### 3.4 Legal Landscape

#### EU / UK: Regulation (EU) No 1169/2011 (FIC)

The FIC regulation applies to **all food businesses**, including restaurants, takeaways, and canteens — not just pre-packed food. Article 44 requires that allergen information for non-prepacked food be provided to the consumer. ([Regulation text](https://www.legislation.gov.uk/eur/2011/1169/annex/II), [Manchester Food Allergens guide](https://sites.manchester.ac.uk/foodallergens/information-for-food-businesses/eu-legal-requirements-on-food-allergen-labelling/))

**In practice:**
- Restaurants must declare the 14 Annex II allergens if present in a dish.
- Information can be provided verbally if there's a visible notice directing customers to ask staff, AND a written record is available on request.
- Many restaurants comply minimally: a small sign saying "ask staff about allergens" with a printed matrix behind the counter.
- **This data is not digitised, not standardised, and not accessible to third parties.**

**Natasha's Law (UK, October 2021):** Specifically addresses **prepacked for direct sale** (PPDS) food — sandwiches, wraps, boxed salads made on-premises. Requires full ingredient list with emphasised allergens on each item. Does not change the rules for made-to-order restaurant food. ([FSA guidance](https://www.food.gov.uk/business-guidance/prepacked-for-direct-sale-ppds-allergen-labelling-changes-for-restaurants-cafes-and-pubs))

#### US: FALCPA + FDA Menu Labeling

- **FALCPA** (2004) + **FASTER Act** (2021, effective Jan 2023) requires declaration of the "Big 9" allergens on **packaged food** labels only. Does **not** apply to restaurants. ([FDA](https://www.fda.gov/food/nutrition-food-labeling-and-critical-foods/food-allergies), [FoodSafety.gov](https://www.foodsafety.gov/blog/food-allergy-safety-treatment-education-and-research-act-2021))
- **FDA Menu Labeling Rule** (2018) requires chain restaurants with 20+ locations to post **calorie counts** on menus. Allergens are not included. ([FDA menu labeling](https://www.fda.gov/food/nutrition-food-labeling-and-critical-foods/menu-labeling-requirements))
- No federal law requires restaurants to disclose allergens. Some states and cities have voluntary guidelines, but no mandated machine-readable disclosure.

### 3.5 Realistic Strategy for AlergenScan

**Phase 1 (launch):**
- **Chain restaurants only.** Scrape/curate allergen matrices from the top 50–100 chains in target markets (US, UK, EU). Store in a structured database. Maintain manually with periodic checks.
- **"Staff question" checklist.** For independent restaurants, provide the user with a printable/in-app checklist of questions to ask (e.g., "Does this dish contain nuts, milk, eggs, or gluten? Is it prepared on shared surfaces?"). This is legally defensible and genuinely useful.

**Phase 2:**
- **User-contributed data** — allow users to add allergen information for dishes they've eaten, with verification (photo of the allergen menu, community upvotes). Flag all user-contributed data as unverified.
- **Partnership with restaurant POS/menu platforms** (e.g., Toast, Square, Lightspeed) — if allergen data enters the POS system, an API integration could surface it. Long-term play.

**Phase 3:**
- **LLM-assisted extraction** — for restaurant websites and uploaded menu photos, use an LLM to identify dishes and infer likely allergens from ingredient descriptions. Always flag this as "AI-inferred, not manufacturer-confirmed."

---

## 4. Name Search

### 4.1 The Problem

Free-text product search is harder than it appears:

- **Fuzzy matching.** Users type "cheerios" or "cherios" or "honey nut cheerios" — the system must resolve all of these to the correct product(s).
- **Brand disambiguation.** "Digestives" could be McVitie's (UK), Aldi's own-brand, or a dozen others. "Oreo" could be original, double-stuff, golden, or a regional variant.
- **Regional variants.** The same product name can have different formulations in different countries. US Kit Kat (Hershey's, contains PGPR) ≠ UK Kit Kat (Nestlé, different recipe and allergen profile). A user in the US searching "Kit Kat" must not see UK allergen data.
- **Language.** "Lait" (French for milk), "Milch" (German), "Leche" (Spanish) — multi-language search is essential for an international product database.

### 4.2 How Competitors Handle It

- **Open Food Facts** uses Elasticsearch. Search by product name returns results ranked by popularity and completeness. Supports language-specific fields. Works reasonably well but returns many near-duplicates (same product scanned by different users with different metadata quality). ([OFF search](https://world.openfoodfacts.org/cgi/search.pl))
- **Fig** combines barcode lookup with a text search that matches against their curated product database. Results are filtered by the user's allergen profile. Works well within their US-centric dataset; breaks down for products not in their DB.
- **Yuka** primarily relies on barcode — name search is secondary and limited.

### 4.3 Implementation Approach

1. **Start with OFF's search API** (`GET /cgi/search.pl?search_terms=...&json=1`). Apply country filtering (`tagtype_0=countries&tag_contains_0=contains&tag_0=United+Kingdom`).
2. **Client-side fuzzy matching** for offline cache: use a trigram-based or Levenshtein distance algorithm (e.g., Fuse.js for JS). Index product names + brands.
3. **Normalise queries:** strip accents, lowercase, expand common abbreviations, handle plurals.
4. **Present results with country flag** — always show the product's country of sale so the user can select the right regional variant.
5. **Disambiguation UI** — when multiple matches exist, show brand + size + country and let the user pick. Never auto-select if there's ambiguity.

### 4.4 Where It Fails

- Products not in the database → "not found." Mitigation: prompt user to scan the barcode or photograph ingredients.
- Cross-border products → user in Belgium might get French product data. Mitigation: use geolocation + explicit country preference.
- Identical names, different formulations → must treat each country-variant as a distinct product. OFF handles this with separate entries per country, but the data is inconsistent.

---

## 5. Regulation

### 5.1 Mandatory Allergen Lists

#### EU: 14 Allergens (FIC Regulation 1169/2011, Annex II)

1. Cereals containing **gluten** (wheat, rye, barley, oats, spelt, kamut)
2. **Crustaceans**
3. **Eggs**
4. **Fish**
5. **Peanuts**
6. **Soybeans**
7. **Milk** (including lactose)
8. **Tree nuts** (almonds, hazelnuts, walnuts, cashews, pecans, Brazil nuts, pistachios, macadamia)
9. **Celery**
10. **Mustard**
11. **Sesame**
12. **Sulphur dioxide / sulphites** (>10 mg/kg or mg/L as SO₂)
13. **Lupin**
14. **Molluscs**

Source: [Annex II](https://www.legislation.gov.uk/eur/2011/1169/annex/II)

#### US: 9 Allergens (FALCPA + FASTER Act)

1. **Milk**
2. **Eggs**
3. **Fish**
4. **Crustacean shellfish**
5. **Tree nuts**
6. **Peanuts**
7. **Wheat**
8. **Soybeans**
9. **Sesame** (added by FASTER Act, effective Jan 1, 2023)

Source: [FDA](https://www.fda.gov/food/nutrition-food-labeling-and-critical-foods/food-allergies)

#### UK: Same 14 as EU (retained EU law post-Brexit) + Natasha's Law for PPDS

**Notable gaps between EU and US:** The US does not require labelling of celery, mustard, lupin, molluscs, or sulphites. An app targeting both markets must support the union of both lists (14+).

### 5.2 "May Contain" / Precautionary Allergen Labelling (PAL)

**The core problem:** "May contain" labelling is **voluntary and unregulated** in most jurisdictions. There is no legal standard defining when it must or must not be used.

- In the EU, PAL is not mandated. The FIC regulation requires declaration of *intentional* allergen ingredients but says nothing about cross-contamination risk. Manufacturers use PAL defensively and inconsistently — a product that says "may contain peanuts" is not necessarily more likely to contain peanuts than a product that says nothing. ([World Allergy Organization](https://www.worldallergyorganizationjournal.org/article/S1939-4551(24)00104-2/fulltext))
- In the US, "may contain" and "produced in a facility that processes…" are voluntary advisory statements. The FDA has considered but not finalised rules to standardise them.
- **Codex Alimentarius** adopted new international PAL guidance in July 2026, and the EU has announced plans to harmonise PAL rules by Q4 2027. This may eventually bring consistency. ([FAO/Codex](https://www.fao.org/newsroom/detail/global-food-safety-standards-body-codex-adopts-new-guidance-on--may-contain--allergen-labels/en), [Bird & Bird EU analysis](https://www.twobirds.com/en/insights/2026/eu-to-harmonise-may-contain-allergen-labels-new-rules-expected-by-q4-2027))

**Implication for AlergenScan:** Display "may contain" / "traces" data when available (OFF provides `traces_tags`), but always label it clearly as precautionary. Never conflate "contains" with "may contain." Allow users to configure whether they want to be warned about PAL statements.

### 5.3 Legal Implications for a Consumer App

1. **Present results as advisory, never authoritative.** The app must include clear disclaimers: "This information is provided for guidance only. Always check the product label and consult with the manufacturer if in doubt. [App name] is not a substitute for reading the label."

2. **Product-liability exposure:** If a user relies on the app and has a reaction because the data was wrong (stale formulation, missing allergen tag), the app developer could face negligence claims. Mitigations:
   - Terms of service with liability limitation and disclaimer.
   - Show data provenance (e.g., "Source: Open Food Facts, last updated: 2025-12-01").
   - Show a "last verified" timestamp and warn if data is older than 6 months.
   - **Never** display an unqualified "safe" label. Use "no known allergens detected in database" rather than "allergen-free."

3. **Regulatory compliance:** The app itself is not a food label and is not directly subject to FIC or FALCPA. But misleading health claims could fall under consumer protection law (EU Unfair Commercial Practices Directive, US FTC Act). Avoid claiming the app "guarantees safety" or "eliminates allergen risk."

---

## 6. Technical Approaches

### 6.1 Barcode Scanning

Barcode scanning on mobile is a solved problem in 2026. Key options:

| Library | Platform | Notes |
|---|---|---|
| **expo-camera** (Expo SDK) | iOS + Android | Built-in `onBarcodeScanned` callback. Replaces deprecated `expo-barcode-scanner`. The simplest option for Expo-based apps. ([npm](https://www.npmjs.com/package/expo-camera)) |
| **react-native-vision-camera** + barcode plugin | iOS + Android | More control over camera UI, supports continuous scanning, frame processors. Better for custom UX. ([Margelo blog](https://margelo.com/blog/react-native-barcode-scanner)) |
| **react-native-data-scanner** | iOS + Android | One method call, OS-native UI. No camera permission needed on Android (uses system scanner). Simplest integration. |
| **Google ML Kit Barcode Scanning** | iOS + Android (native) | On-device, fast, supports all common formats (EAN-13, UPC-A, QR, etc.). |
| **Apple Vision / AVFoundation** | iOS (native) | Built into iOS. VNDetectBarcodesRequest. No third-party dependency. |

**Recommendation for MVP:** If using Expo, `expo-camera` with `onBarcodeScanned` is sufficient. If bare React Native, `react-native-vision-camera` with the barcode scanner plugin. Both support EAN-13 (European) and UPC-A (US) — the two formats used on food products.

### 6.2 OCR of Ingredient Lists

For the case where a barcode resolves to a product with no allergen data, or the user points the camera at a loose ingredient list:

| Approach | Pros | Cons |
|---|---|---|
| **Apple Vision (on-device)** | Fast, private, no network required, good accuracy on clear labels. iOS 16+ VNRecognizeTextRequest. | iOS only. Accuracy drops on curved, glossy, low-contrast labels. Struggles with very small text. |
| **Google ML Kit Text Recognition (on-device)** | Cross-platform (iOS + Android), free, on-device, good for Latin scripts. | Accuracy on non-Latin scripts is weaker. Same physical challenges as Apple Vision. |
| **Google Cloud Vision API** | Higher accuracy, supports 100+ languages, handles difficult images better. | Requires network. Cost: $1.50 per 1 K images. Privacy concern (images leave device). Latency. |
| **Tesseract (on-device)** | Open source, offline. | Significantly lower accuracy than ML Kit or Apple Vision. Not recommended in 2026. |

**Recommendation:** Use **on-device OCR** (ML Kit for cross-platform, or Apple Vision on iOS) as the primary approach. Reserve cloud OCR for a "retry with better accuracy" option that the user can opt into. On-device preserves privacy and works offline.

**Practical accuracy issues:**
- Curved surfaces (cans, bottles) cause text distortion. Mitigation: guide the user to flatten the label or take multiple photos.
- Glossy packaging causes glare. Mitigation: instruct users to avoid flash; use diffuse lighting.
- Small text on dense ingredient lists. Mitigation: allow pinch-to-zoom before capture.
- Multi-language ingredient lists (common in EU: same label in 5+ languages). Mitigation: detect language blocks and parse only the relevant one.

### 6.3 Ingredient Parsing and Allergen Matching

This is the most safety-critical component. The system must match ingredient text against known allergens, including hundreds of synonyms, derivatives, and non-obvious names.

#### The Synonym/Derivative Problem

A non-exhaustive sample:

| Allergen | Common synonyms / derivatives |
|---|---|
| **Milk** | Casein, caseinate, whey, lactalbumin, lactoglobulin, ghee, lactose, curds, galactose |
| **Gluten** | Wheat, semolina, durum, spelt, kamut, einkorn, emmer, triticale, bulgur, couscous, seitan, farro, wheat starch, modified wheat starch |
| **Egg** | Albumin, globulin, lysozyme, mayonnaise, meringue, ovalbumin, ovomucin, ovovitellin, surimi (sometimes) |
| **Soy** | Soya, edamame, miso, tempeh, tofu, soy lecithin (E322), soy protein isolate, textured vegetable protein (TVP) |
| **Peanut** | Groundnut, arachis oil, monkey nuts, earth nuts, beer nuts |
| **Tree nuts** | Almond (marzipan, frangipane, praline), hazelnut (Nutella, gianduja), walnut, cashew, pecan, pistachio, macadamia, Brazil nut |
| **Fish** | Anchovy (Worcestershire sauce, Caesar dressing), surimi, fish sauce, fish gelatin, isinglass |
| **Sesame** | Tahini, halvah, til, gingelly oil, benne seeds |
| **Sulphites** | E220–E228, sulphur dioxide, sodium sulphite, sodium bisulphite, sodium metabisulphite, potassium bisulphite |
| **Lupin** | Lupine, lupin flour, lupin seed |
| **Celery** | Celeriac, celery salt, celery seed |
| **Mustard** | Mustard flour, mustard oil, mustard seed, mustard powder |

#### Deterministic Rules vs. LLM

| Approach | When to use | When NOT to use |
|---|---|---|
| **Curated synonym dictionary + regex/token matching** | Primary allergen detection from structured ingredient text. This is the safety-critical path. A missed synonym → false negative → potential hospitalisation. The dictionary must be exhaustive, version-controlled, and updated when new derivatives are identified. | — |
| **LLM (GPT-4, Claude, etc.)** | (a) Parsing messy OCR output into clean ingredient lists. (b) Handling ambiguous ingredient descriptions in restaurant menus ("chef's special sauce"). (c) Identifying potential allergens in free-text dish descriptions where no structured data exists. (d) Answering user questions about ingredients. | **Never as the sole allergen detection mechanism on structured data.** LLMs hallucinate. An LLM might miss "casein" as a milk derivative or hallucinate an allergen that isn't present. False negatives in an LLM are unpredictable and unreproducible. |

**Recommended architecture:**
1. **Primary path (packaged goods with ingredients text):** Deterministic synonym-match engine. Tokenise the ingredient string, match each token against the allergen synonym dictionary. Flag matches. This is auditable, testable, and deterministic.
2. **Secondary path (OCR output):** LLM to clean/structure the OCR text → then pass cleaned text through the deterministic engine.
3. **Tertiary path (restaurant dish descriptions):** LLM to infer *likely* allergens from a dish name/description. Always flag as "AI-inferred" with a warning. Never present as confirmed.

### 6.4 On-Device vs. Cloud Processing

| | On-device | Cloud |
|---|---|---|
| **Privacy** | Ingredient photos never leave the phone. | Photos uploaded to server. GDPR implications. |
| **Latency** | Fast (<500ms for OCR + parsing). | Network-dependent (1–3s). |
| **Offline** | Works without internet (if product cache is local). | Requires connectivity. |
| **Accuracy** | Limited by on-device model size. | Higher accuracy (larger models). |
| **Cost** | Free at scale. | Per-request API costs. |

**Recommendation:** On-device for barcode scanning, OCR, and deterministic allergen matching. Cloud only for LLM-based fallback analysis and product database sync.

---

## 7. Recommended MVP

### 7.1 Stack Recommendation

**React Native with Expo (SDK 52+).** Not a menu of options — this is the recommendation.

**Rationale:**
- Single codebase for iOS + Android. Critical for a bootstrapped product — maintaining two native codebases doubles effort.
- `expo-camera` provides barcode scanning out of the box.
- Expo's ML Kit integration enables on-device OCR.
- Expo EAS for builds and OTA updates — no CI/CD to configure from scratch.
- Large ecosystem and community. Performance is sufficient for this app (it's not a game or video editor).
- Flutter is a viable alternative but has a smaller food-tech plugin ecosystem. Native Swift/Kotlin is overkill for MVP. PWA lacks reliable camera/OCR access.

**Backend: Supabase (PostgreSQL + Edge Functions + Auth).**

**Rationale:**
- PostgreSQL with full-text search for product name lookup.
- Edge Functions (Deno) for lightweight API logic (OCR fallback, allergen parsing, OFF API proxy).
- Built-in auth (email/social) for user accounts and allergen profiles.
- Generous free tier. Easy to self-host later if needed.
- Row Level Security for user data.

**Offline product cache: SQLite (via `expo-sqlite`).**
- Cache the user's recently scanned products and their full allergen data locally.
- Pre-seed with a compressed extract of OFF products for the user's country (~50–100 K most-scanned products). ~20–50 MB.
- Sync delta updates periodically.

### 7.2 Phased Scope

#### V1 — Ship This First

| Feature | Detail |
|---|---|
| **Barcode scan** | Scan EAN-13 / UPC-A. Look up in OFF API → display allergens, ingredients, "may contain" traces. |
| **Personal allergen profile** | User selects their allergens from the EU 14 + US 9 union list. Results are colour-coded: red (contains your allergen), amber (may contain / traces), green (not detected). |
| **Name search** | Text search against OFF database. Country-filtered. Basic fuzzy matching. |
| **Offline cache** | Recent scans cached in SQLite. Works without internet for previously scanned products. |
| **OCR fallback** | If product not in database, user can photograph ingredient list. On-device OCR → deterministic allergen matching. Clearly labelled as "scanned from label." |
| **Disclaimer** | Prominent advisory disclaimer on every result. "Always verify with the product label." |
| **Platforms** | iOS + Android via Expo. |

#### V2 — After Validation

| Feature | Detail |
|---|---|
| **Chain restaurant lookup** | Curated allergen data for top 50–100 chains (US + UK). Search by chain → menu item → allergens. |
| **Staff question checklist** | For non-chain restaurants: an in-app checklist of questions to ask about allergens. |
| **User contributions** | Submit missing products (barcode + photo of ingredients). Community verification before inclusion. |
| **Product reformulation alerts** | If a product's ingredients change in the OFF database, notify users who have it in their history. |
| **Premium tier** | Unlimited history, advanced filters, family profiles, export data. |

#### V3 — Ambitious

| Feature | Detail |
|---|---|
| **Independent restaurant data** | User-contributed allergen data for specific dishes. Verified by community. |
| **LLM-powered menu analysis** | Photo a restaurant menu → LLM extracts dishes and infers likely allergens. Always flagged as AI-inferred. |
| **POS integrations** | Partner with Toast, Square, etc. for structured allergen data from restaurants. |
| **Wearable alerts** | Apple Watch / Wear OS companion for quick scan results. |

### 7.3 Architecture Diagram (Simplified)

```
┌─────────────────────────────────────────────┐
│              Mobile App (Expo)              │
│  ┌──────────┐ ┌──────────┐ ┌─────────────┐ │
│  │ Barcode  │ │  OCR     │ │ Text Search │ │
│  │ Scanner  │ │ (ML Kit) │ │ (Fuse.js)   │ │
│  └────┬─────┘ └────┬─────┘ └──────┬──────┘ │
│       │             │              │        │
│  ┌────▼─────────────▼──────────────▼──────┐ │
│  │     Allergen Matching Engine           │ │
│  │   (deterministic synonym dictionary)   │ │
│  └────────────────┬───────────────────────┘ │
│                   │                         │
│  ┌────────────────▼───────────────────────┐ │
│  │     SQLite Cache (offline products)    │ │
│  └────────────────────────────────────────┘ │
└───────────────────┬─────────────────────────┘
                    │ API calls
        ┌───────────▼───────────┐
        │   Supabase Backend    │
        │  ┌──────────────────┐ │
        │  │  PostgreSQL      │ │
        │  │  (products,      │ │
        │  │   restaurants,   │ │
        │  │   user profiles) │ │
        │  └──────────────────┘ │
        │  ┌──────────────────┐ │
        │  │  Edge Functions  │ │
        │  │  (OFF proxy,     │ │
        │  │   LLM fallback,  │ │
        │  │   sync logic)    │ │
        │  └──────────────────┘ │
        └───────────┬───────────┘
                    │
    ┌───────────────▼───────────────┐
    │    External Data Sources      │
    │  ┌─────────┐ ┌─────────────┐ │
    │  │  OFF    │ │ USDA FDC    │ │
    │  │  API    │ │ API         │ │
    │  └─────────┘ └─────────────┘ │
    └───────────────────────────────┘
```

---

## 8. Risks

### 8.1 Data Staleness (Reformulations)

Manufacturers reformulate products regularly — changing suppliers, adding or removing ingredients. The OFF database is crowdsourced and updates lag behind actual shelf products. A product scanned 18 months ago may have a different recipe today.

**Mitigation:** Show "data last updated" timestamps prominently. Prompt users to re-scan ingredient lists if the data is older than 6 months. Subscribe to OFF's change feed for automated alerts.

### 8.2 False Negatives — The Critical Safety Failure

A **false negative** (app says "no allergens detected" when an allergen is present) could cause anaphylaxis or death. This is the single most important risk.

**Causes:**
- Missing synonym in the allergen dictionary (e.g., "casein" not mapped to milk).
- Product in database with incomplete allergen tags.
- OCR misread ("contains milk" read as "contains mllk" and not matched).
- Stale data after reformulation.
- User scans the wrong product (similar packaging).

**Mitigation:**
- **Never display an unqualified "safe" or "allergen-free" result.** Always say "no known allergens detected" with a disclaimer.
- Invest heavily in the synonym dictionary. Test it against a corpus of real ingredient lists. Treat it as safety-critical code with review and versioning.
- Dual-check: match both against `allergens_tags` (structured data) AND against the raw `ingredients_text` (parsed by the deterministic engine). If either flags an allergen, report it.
- Unit test the allergen engine with an extensive test suite of real ingredient strings.

### 8.3 Coverage Gaps Outside the EU

OFF's coverage drops sharply outside Europe. US coverage is decent for major brands but weak for regional products. Asia, Latin America, and Africa have minimal coverage.

**Mitigation:** Be transparent about coverage. Show "X products in database for [country]" in the app. Encourage contributions. Use USDA FoodData Central as a US supplement.

### 8.4 Restaurant Data Is Unverifiable

Even for chain restaurants, the data we scrape or curate is a snapshot. Menus change, suppliers change, seasonal items rotate. For independent restaurants, there is no source of truth.

**Mitigation:** Timestamp all restaurant data. Clearly distinguish "manufacturer-declared" (chain allergen matrix) from "user-contributed" from "AI-inferred." Allow users to report inaccuracies.

### 8.5 Legal Exposure

If a user has an allergic reaction and claims the app misled them, the developer could face:
- Negligence claims (duty of care to provide accurate information).
- Consumer protection claims (misleading health information).
- Product liability claims (if the app is classified as a "product" providing health safety information).

**Mitigation:**
- Robust terms of service with liability disclaimers. Consult a lawyer in each target jurisdiction.
- Never present results as a substitute for reading the label.
- Carry professional indemnity / errors & omissions insurance.
- Log data provenance — be able to show that data came from OFF/manufacturer sources and that the matching engine worked correctly at the time.

---

## 9. Recommendation & Open Questions

### Concrete Recommendation

Build AlergenScan as an **Expo (React Native) mobile app** with a **Supabase backend**, using **Open Food Facts as the primary data source** for packaged goods. Ship V1 with barcode scanning, name search, personal allergen profiles, on-device OCR fallback, and a deterministic allergen-matching engine. Defer restaurant features to V2, starting with chain-only coverage.

The app should be **advisory, not authoritative.** Every screen must reinforce that the user should verify with the actual product label. The allergen synonym dictionary is the most safety-critical component and should be treated with the rigour of medical-device software — version-controlled, peer-reviewed, and exhaustively tested.

The restaurant problem is real but unsolvable at launch for independent restaurants. Start with curated chain data and a staff-question checklist. Let user-contributed data grow organically, but never present it as verified.

### Open Questions for the Product Owner

1. **Target market for launch.** EU-first (where OFF coverage is best and FIC regulation creates demand) or US-first (larger app market but weaker data coverage)? This drives the initial product database seeding strategy.

2. **Monetization model.** Freemium (unlimited scans, premium for history/family profiles/restaurant features)? Subscription? Purely free with sponsorship? The Yuka model (premium for allergen filtering) is proven but limits the core value proposition.

3. **Liability appetite.** How much legal risk is acceptable? This determines the aggressiveness of language ("safe" vs. "no known allergens detected"), the disclaimer wording, and whether to invest in legal review before launch.

4. **Restaurant data commitment.** Is the team willing to manually curate and maintain allergen matrices for 50–100 chain restaurants? This is ongoing labour, not a one-time task. Menus change quarterly.

5. **User-contributed data policy.** Allow users to submit allergen data? If so, what verification process? Unverified user data displayed as fact is a liability risk. But requiring verification slows growth.

6. **"May contain" policy.** Should the app warn on "may contain" / trace statements by default? Some users with severe allergies avoid all "may contain" products; others with mild intolerances ignore them. This should be user-configurable, but the default setting has safety implications.

7. **Offline scope.** How large an offline product cache is acceptable? A full OFF extract for one country could be 50–200 MB. Is this acceptable for a mobile app, or should offline be limited to previously-scanned products only?

8. **Language coverage at launch.** How many languages should the allergen synonym dictionary cover? English is mandatory; French, German, Spanish, and Italian cover most of the EU. Each language requires its own synonym mapping.

9. **Accessibility.** Should results be voice-readable for visually impaired users? This is both a moral imperative and a significant user segment (people who struggle to read small ingredient labels are a core audience).

10. **Data partnerships.** Is the team open to commercial API agreements (Nutritionix for restaurants, Edamam for parsing) if the free tier proves insufficient? What's the budget threshold?

---

## Sources

- [Open Food Facts API Documentation](https://openfoodfacts.github.io/openfoodfacts-server/api/)
- [Open Food Facts Country Statistics](https://world.openfoodfacts.org/countries)
- [USDA FoodData Central API Guide](https://fdc.nal.usda.gov/api-guide)
- [Nutritionix API](https://www.nutritionix.com/api)
- [Edamam Developer Portal](https://developer.edamam.com/)
- [Spoonacular Food API](https://spoonacular.com/food-api)
- [EU Regulation 1169/2011 Annex II](https://www.legislation.gov.uk/eur/2011/1169/annex/II)
- [EU FIC Allergen Labelling Requirements](https://sites.manchester.ac.uk/foodallergens/information-for-food-businesses/eu-legal-requirements-on-food-allergen-labelling/)
- [FDA — Food Allergies](https://www.fda.gov/food/nutrition-food-labeling-and-critical-foods/food-allergies)
- [FASTER Act (FoodSafety.gov)](https://www.foodsafety.gov/blog/food-allergy-safety-treatment-education-and-research-act-2021)
- [Natasha's Law — FSA Guidance](https://www.food.gov.uk/business-guidance/prepacked-for-direct-sale-ppds-allergen-labelling-changes-for-restaurants-cafes-and-pubs)
- [McDonald's UK Allergen Booklet](https://www.mcdonalds.com/gb/en-gb/good-to-know/allergen-booklet.html)
- [Codex Alimentarius PAL Guidance (FAO)](https://www.fao.org/newsroom/detail/global-food-safety-standards-body-codex-adopts-new-guidance-on--may-contain--allergen-labels/en)
- [EU PAL Harmonisation Plans (Bird & Bird)](https://www.twobirds.com/en/insights/2026/eu-to-harmonise-may-contain-allergen-labels-new-rules-expected-by-q4-2027)
- [World Allergy Organization — PAL Update](https://www.worldallergyorganizationjournal.org/article/S1939-4551(24)00104-2/fulltext)
- [Expo Camera / Barcode Scanning](https://margelo.com/blog/react-native-barcode-scanner)
- [Spokin App](https://www.spokin.com/about-the-spokin-app)
- [AllergyEats](https://www.allergyeats.com/)
- [Yuka — App Store](https://apps.apple.com/us/app/yuka-food-cosmetic-scanner/id1092799236)
- [Fig — Trash Panda Comparison](https://www.trashpandaapp.com/blog/comparing-different-food-scanner-apps)
- [Spoonful — App Store](https://apps.apple.com/us/app/spoonful-diet-food-scanner/id1481914232)
- [Osana — Yuka Alternatives](https://osana.co/blog/yuka-alternatives)
