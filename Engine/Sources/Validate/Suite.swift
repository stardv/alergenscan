import Foundation
import AllergenEngine

final class AllergenEngineTests {

    let engine = AllergenEngine()

    // MARK: - Helpers

    private func status(_ text: String, _ allergen: Allergen) -> AllergenStatus {
        engine.analyze(labelText: text)[allergen]?.0 ?? .notDetected
    }

    // MARK: - Derivatives (the whole point of the dictionary)

    func testDetectsMilkFromDerivativesThatNeverSayMilk() {
        for text in ["Ingredients: sugar, sodium caseinate, salt",
                     "Ingredients: whey powder, lecithin",
                     "Ingredients: wheat flour, butter, sugar",
                     "Contains lactose",
                     "Ingredients: ghee, spices"] {
            XCTAssertEqual(status(text, .milk), .contains, "failed on: \(text)")
        }
    }

    func testDetectsGlutenFromDerivatives() {
        for text in ["Ingredients: semolina, water",
                     "Ingredients: durum wheat",
                     "Ingredients: barley malt extract",
                     "Ingredients: spelt flour",
                     "Ingredients: couscous"] {
            XCTAssertEqual(status(text, .gluten), .contains, "failed on: \(text)")
        }
    }

    func testDetectsEggFromDerivatives() {
        XCTAssertEqual(status("Ingredients: albumen, sugar", .eggs), .contains)
        XCTAssertEqual(status("Ingredients: lysozyme", .eggs), .contains)
        XCTAssertEqual(status("Ingredients: mayonnaise", .eggs), .contains)
    }

    func testDetectsHiddenFishAndSesame() {
        XCTAssertEqual(status("Ingredients: worcestershire sauce", .fish), .contains)
        XCTAssertEqual(status("Ingredients: tahini, chickpeas", .sesame), .contains)
    }

    func testDetectsSulphiteENumbers() {
        XCTAssertEqual(status("Ingredients: grapes, E220", .sulphites), .contains)
        XCTAssertEqual(status("Contains sodium metabisulphite", .sulphites), .contains)
    }

    // MARK: - False positives that would make the app useless

    func testPeanutButterIsNotDairy() {
        let result = engine.analyze(labelText: "Ingredients: peanut butter, salt")
        XCTAssertEqual(result[.peanuts]?.0, .contains)
        XCTAssertNil(result[.milk], "\"butter\" inside \"peanut butter\" must not read as dairy")
    }

    func testCoconutMilkIsNotDairy() {
        let result = engine.analyze(labelText: "Ingredients: coconut milk, rice")
        XCTAssertNil(result[.milk], "coconut milk is not dairy")
        XCTAssertNil(result[.treeNuts], "coconut is not a tree nut under EU rules")
    }

    func testCocoaButterIsNotDairy() {
        XCTAssertEqual(status("Ingredients: cocoa mass, cocoa butter, sugar", .milk), .notDetected)
    }

    func testAlmondMilkIsTreeNutNotDairy() {
        let result = engine.analyze(labelText: "Ingredients: almond milk, water")
        XCTAssertEqual(result[.treeNuts]?.0, .contains)
        XCTAssertNil(result[.milk])
    }

    func testWordsThatMerelyContainAllergenSubstrings() {
        XCTAssertEqual(status("Ingredients: nutmeg, cinnamon", .treeNuts), .notDetected)
        XCTAssertEqual(status("Ingredients: eggplant, olive oil", .eggs), .notDetected)
        XCTAssertEqual(status("Ingredients: buckwheat flour", .gluten), .notDetected)
        XCTAssertEqual(status("Ingredients: cream of tartar", .milk), .notDetected)
    }

    // MARK: - "Free from" claims

    func testFreeFromClaimsAreNotTreatedAsIngredients() {
        XCTAssertEqual(status("Gluten free oat-free bread", .gluten), .notDetected)
        XCTAssertEqual(status("Dairy free spread", .milk), .notDetected)
        XCTAssertEqual(status("Free from milk and egg", .milk), .notDetected)
        XCTAssertEqual(status("This product does not contain peanuts", .peanuts), .notDetected)
        XCTAssertEqual(status("Contains no soy", .soybeans), .notDetected)
    }

    func testFreeFromClaimDoesNotMaskARealIngredientElsewhere() {
        // Gluten-free, but genuinely contains milk. The negation must be local.
        let result = engine.analyze(labelText: "Gluten free. Ingredients: butter, sugar")
        XCTAssertEqual(result[.gluten]?.0 ?? .notDetected, .notDetected)
        XCTAssertEqual(result[.milk]?.0, .contains)
    }

    // MARK: - Precautionary statements

    func testMayContainIsTracesNotIngredients() {
        let result = engine.analyze(labelText: "Ingredients: oats, sugar. May contain peanuts.")
        XCTAssertEqual(result[.gluten]?.0, .contains)
        XCTAssertEqual(result[.peanuts]?.0, .mayContain)
    }

    func testFactoryWarningIsTraces() {
        let text = "Ingredients: sugar. Produced in a factory that also handles milk and sesame."
        let result = engine.analyze(labelText: text)
        XCTAssertEqual(result[.milk]?.0, .mayContain)
        XCTAssertEqual(result[.sesame]?.0, .mayContain)
    }

    func testPrecautionaryMarkerDoesNotLeakBackwardsOverIngredients() {
        // "milk" appears before the marker, so it is a declared ingredient.
        let result = engine.analyze(labelText: "Ingredients: milk, sugar. May contain nuts.")
        XCTAssertEqual(result[.milk]?.0, .contains, "milk is declared, not a trace")
        XCTAssertEqual(result[.treeNuts]?.0, .mayContain)
    }

    func testContainsBeatsMayContainForTheSameAllergen() {
        let result = engine.analyze(labelText: "Ingredients: butter. May contain milk.")
        XCTAssertEqual(result[.milk]?.0, .contains, "declared must outrank precautionary")
    }

    // MARK: - Cross-referencing (the union rule)

    func testDatabaseFlagWinsWhenLabelMissesIt() {
        let label = SourceReading(source: .label, findings: [:])          // read it, found nothing
        let db = SourceReading(source: .database,
                               findings: [.milk: (.contains, ["en:milk"])])

        let result = engine.combine(readings: [label, db], profile: [.milk])
        XCTAssertEqual(result.findings.first?.status, .contains,
                       "a flag from either source must survive the merge")
        XCTAssertEqual(result.headline, .contains)
    }

    func testLabelFlagWinsWhenDatabaseMissesIt() {
        let label = SourceReading(source: .label,
                                  findings: [.milk: (.contains, ["casein"])])
        let db = SourceReading(source: .database, findings: [:])

        let result = engine.combine(readings: [label, db], profile: [.milk])
        XCTAssertEqual(result.findings.first?.status, .contains)
    }

    func testMostCautiousStatusWinsOnDisagreement() {
        let label = SourceReading(source: .label,
                                  findings: [.peanuts: (.mayContain, ["peanut"])])
        let db = SourceReading(source: .database,
                               findings: [.peanuts: (.contains, ["en:peanuts"])])

        let result = engine.combine(readings: [label, db], profile: [.peanuts])
        XCTAssertEqual(result.findings.first?.status, .contains)
        XCTAssertEqual(result.findings.first?.sources.count, 2)
    }

    func testNoSourcesReadableIsInconclusiveNotAllClear() {
        let label = SourceReading(source: .label, findings: nil)
        let db = SourceReading(source: .database, findings: nil)

        let result = engine.combine(readings: [label, db], profile: [.milk])
        XCTAssertTrue(result.isInconclusive)
        XCTAssertEqual(result.headline, .couldNotCheck,
                       "unreadable must never present as an all-clear")
    }

    func testAllergensOutsideProfileAreNotReported() {
        let label = SourceReading(source: .label,
                                  findings: [.milk: (.contains, ["butter"]),
                                             .gluten: (.contains, ["wheat"])])
        let result = engine.combine(readings: [label], profile: [.milk])
        XCTAssertEqual(result.findings.count, 1)
        XCTAssertEqual(result.findings.first?.allergen, .milk)
    }

    func testFlaggedAllergensSortAboveClearOnes() {
        let label = SourceReading(source: .label,
                                  findings: [.gluten: (.contains, ["wheat"])])
        let result = engine.combine(readings: [label], profile: [.milk, .gluten, .eggs])
        XCTAssertEqual(result.findings.first?.allergen, .gluten)
        XCTAssertEqual(result.flagged.count, 1)
    }

    // MARK: - Evidence

    func testEvidenceExplainsTheVerdict() {
        let result = engine.analyze(labelText: "Ingredients: whey, butter, sugar")
        let evidence = result[.milk]?.1 ?? []
        XCTAssertTrue(evidence.contains("whey"))
        XCTAssertTrue(evidence.contains("butter"))
    }

    // MARK: - OCR robustness

    func testHandlesUppercaseAndPunctuationFromOCR() {
        XCTAssertEqual(status("INGREDIENTS: WHEAT FLOUR, SUGAR, MILK.", .milk), .contains)
        XCTAssertEqual(status("Ingredients: wheat-flour; sugar", .gluten), .contains)
    }

    func testHandlesAccentedText() {
        XCTAssertEqual(status("Ingrédients : lait, sucre, sésame", .sesame), .contains)
    }

    func testEmptyTextFindsNothing() {
        XCTAssertTrue(engine.analyze(labelText: "").isEmpty)
        XCTAssertTrue(engine.analyze(labelText: "   \n  ").isEmpty)
    }

    // MARK: - Open Food Facts

    func testDecodesProductAndUnionsTagsWithIngredients() throws {
        let json = """
        {"status":1,"product":{
          "code":"3017620422003",
          "product_name":"Test Spread",
          "brands":"TestBrand",
          "ingredients_text":"Sugar, palm oil, hazelnuts, skimmed milk powder",
          "allergens_tags":["en:milk","en:nuts"],
          "traces_tags":["en:peanuts"],
          "last_modified_t":1700000000
        }}
        """.data(using: .utf8)!

        let product = try OpenFoodFactsClient.decode(json, barcode: "3017620422003")
        XCTAssertEqual(product.displayName, "TestBrand — Test Spread")

        let findings = engine.analyze(product: product)
        XCTAssertEqual(findings[.milk]?.0, .contains)
        XCTAssertEqual(findings[.treeNuts]?.0, .contains)
        XCTAssertEqual(findings[.peanuts]?.0, .mayContain)
    }

    func testIngredientsTextCatchesAllergenMissingFromTags() throws {
        // Tags omit milk; the ingredients name butter. The union must catch it.
        let json = """
        {"status":1,"product":{
          "code":"123","product_name":"Biscuits",
          "ingredients_text":"Wheat flour, butter, sugar",
          "allergens_tags":["en:gluten"],"traces_tags":[]
        }}
        """.data(using: .utf8)!

        let product = try OpenFoodFactsClient.decode(json, barcode: "123")
        let findings = engine.analyze(product: product)
        XCTAssertEqual(findings[.milk]?.0, .contains,
                       "must not rely on OFF tags alone — they are often incomplete")
    }

    func testMissingProductThrowsNotFound() {
        let json = #"{"status":0,"status_verbose":"product not found"}"#.data(using: .utf8)!
        XCTAssertThrowsError(try OpenFoodFactsClient.decode(json, barcode: "000")) { error in
            XCTAssertEqual(error as? OFFError, .notFound)
        }
    }

    func testRecordWithNoDateCountsAsStale() {
        let product = OFFProduct(barcode: "1", lastModified: nil)
        XCTAssertTrue(product.isStale())
    }

    func testOldRecordIsStale() {
        let old = Date().addingTimeInterval(-60 * 60 * 24 * 400)
        XCTAssertTrue(OFFProduct(barcode: "1", lastModified: old).isStale())
        XCTAssertFalse(OFFProduct(barcode: "1", lastModified: Date()).isStale())
    }

    // MARK: - Dictionary integrity

    func testEveryAllergenHasAtLeastOneTerm() {
        for allergen in Allergen.allCases {
            let count = AllergenDictionary.terms.filter { $0.allergens.contains(allergen) }.count
            XCTAssertGreaterThan(count, 0, "\(allergen.displayName) has no synonyms")
        }
    }

    func testLongerPhrasesSortBeforeShorterOnes() {
        let phrases = AllergenDictionary.terms.map(\.phrase)
        guard let coconutMilk = phrases.firstIndex(of: "coconut milk"),
              let milk = phrases.firstIndex(of: "milk") else {
            XCTFail("expected both phrases in the dictionary")
            return
        }
        XCTAssertLessThan(coconutMilk, milk, "multi-word phrases must be tried first")
    }

    // MARK: - Non-English labels

    func testDetectsFrenchLabel() {
        // Verbatim ingredients_text for Nutella from Open Food Facts.
        let text = "Sucre, huile de palme, NOISETTES 13%, cacao maigre 7,4%, "
                 + "LAIT ecreme en poudre 6,6%, LACTOSERUM en poudre, "
                 + "emulsifiants: lecithines (SOJA), vanilline. Sans gluten."
        let result = engine.analyze(labelText: text)
        XCTAssertEqual(result[.milk]?.0, .contains)
        XCTAssertEqual(result[.treeNuts]?.0, .contains)
        XCTAssertEqual(result[.soybeans]?.0, .contains)
        XCTAssertEqual(result[.gluten]?.0 ?? .notDetected, .notDetected,
                       "\"sans gluten\" is a free-from claim, not an ingredient")
    }

    func testDetectsGermanLabel() {
        let text = "Zutaten: Weizenmehl, Vollmilchpulver, Haselnusse, Huhnerei, Sojalecithin"
        let result = engine.analyze(labelText: text)
        XCTAssertEqual(result[.gluten]?.0, .contains)
        XCTAssertEqual(result[.treeNuts]?.0, .contains)
        XCTAssertEqual(result[.soybeans]?.0, .contains)
    }

    func testDetectsSpanishLabel() {
        let text = "Ingredientes: harina de trigo, leche en polvo, huevo, almendras"
        let result = engine.analyze(labelText: text)
        XCTAssertEqual(result[.gluten]?.0, .contains)
        XCTAssertEqual(result[.milk]?.0, .contains)
        XCTAssertEqual(result[.eggs]?.0, .contains)
        XCTAssertEqual(result[.treeNuts]?.0, .contains)
    }

    func testDetectsItalianLabel() {
        let text = "Ingredienti: farina di frumento, burro, uova, nocciole, sedano"
        let result = engine.analyze(labelText: text)
        XCTAssertEqual(result[.gluten]?.0, .contains)
        XCTAssertEqual(result[.milk]?.0, .contains)
        XCTAssertEqual(result[.eggs]?.0, .contains)
        XCTAssertEqual(result[.treeNuts]?.0, .contains)
        XCTAssertEqual(result[.celery]?.0, .contains)
    }

    func testFrenchAndGermanFreeFromClaims() {
        XCTAssertEqual(status("Sans lait, sans oeuf", .milk), .notDetected)
        XCTAssertEqual(status("Ohne Milch", .milk), .notDetected)
        XCTAssertEqual(status("Sin lactosa", .milk), .notDetected)
        XCTAssertEqual(status("Senza glutine", .gluten), .notDetected)
    }

    func testLigaturesAndEszettAreExpanded() {
        XCTAssertEqual(status("Ingredients: \u{153}uf", .eggs), .contains)
        XCTAssertEqual(status("Zutaten: Eiwei\u{df}", .eggs), .contains)
    }

    // MARK: - Default profile

    func testDefaultProfileIsNutsAndEggs() {
        XCTAssertEqual(Allergen.defaultProfile, [.peanuts, .treeNuts, .eggs])
    }

    func testDefaultProfileCoversBothKindsOfNut() {
        // Peanuts are legumes, tree nuts are not. A "nut allergy" that only
        // watched one of them would miss half the shelf.
        XCTAssertTrue(Allergen.defaultProfile.contains(.peanuts))
        XCTAssertTrue(Allergen.defaultProfile.contains(.treeNuts))
    }

    // MARK: - Terms carrying more than one allergen

    func testMarzipanIsNutsAndEgg() {
        let result = engine.analyze(labelText: "Ingredients: marzipan, sugar")
        XCTAssertEqual(result[.treeNuts]?.0, .contains)
        XCTAssertEqual(result[.eggs]?.0, .contains, "marzipan is almonds and egg white")
    }

    func testNougatIsNutsAndEgg() {
        let result = engine.analyze(labelText: "Ingredients: nougat")
        XCTAssertEqual(result[.treeNuts]?.0, .contains)
        XCTAssertEqual(result[.eggs]?.0, .contains)
    }

    func testSurimiIsFishAndEgg() {
        let result = engine.analyze(labelText: "Ingredients: surimi, salt")
        XCTAssertEqual(result[.fish]?.0, .contains)
        XCTAssertEqual(result[.eggs]?.0, .contains, "surimi is bound with egg white")
    }

    // MARK: - The two default allergens, in depth

    func testNutDerivativesThatDoNotSayNut() {
        for text in ["Ingredients: marzipan", "Ingredients: praline",
                     "Ingredients: frangipane", "Ingredients: gianduja",
                     "Ingredients: amaretti", "Ingredients: nougatine",
                     "Ingredients: ground almonds", "Ingredients: almond essence"] {
            XCTAssertEqual(status(text, .treeNuts), .contains, "missed nuts in: \(text)")
        }
    }

    func testPeanutDerivativesThatDoNotSayPeanut() {
        for text in ["Ingredients: groundnut oil", "Ingredients: arachis oil",
                     "Ingredients: monkey nuts", "Ingredients: beer nuts"] {
            XCTAssertEqual(status(text, .peanuts), .contains, "missed peanut in: \(text)")
        }
    }

    func testEggDerivativesThatDoNotSayEgg() {
        for text in ["Ingredients: albumen", "Ingredients: lysozyme",
                     "Ingredients: conalbumin", "Ingredients: ovomucin",
                     "Ingredients: livetin", "Ingredients: aioli",
                     "Ingredients: hollandaise", "Ingredients: meringue"] {
            XCTAssertEqual(status(text, .eggs), .contains, "missed egg in: \(text)")
        }
    }

    func testNutAndEggAcrossEuropeanLanguages() {
        XCTAssertEqual(status("Ingredients: noisettes, oeuf entier", .treeNuts), .contains)
        XCTAssertEqual(status("Ingredients: noisettes, oeuf entier", .eggs), .contains)
        XCTAssertEqual(status("Zutaten: Haselnusse, Huhnerei", .treeNuts), .contains)
        XCTAssertEqual(status("Zutaten: Haselnusse, Huhnerei", .eggs), .contains)
        XCTAssertEqual(status("Ingredientes: avellanas, huevo entero", .treeNuts), .contains)
        XCTAssertEqual(status("Ingredienti: nocciole, uovo intero", .eggs), .contains)
    }

    func testPeanutAndTreeNutStayDistinct() {
        let peanutOnly = engine.analyze(labelText: "Ingredients: peanuts, salt")
        XCTAssertEqual(peanutOnly[.peanuts]?.0, .contains)
        XCTAssertNil(peanutOnly[.treeNuts], "peanut is a legume, not a tree nut")

        let treeOnly = engine.analyze(labelText: "Ingredients: almonds, salt")
        XCTAssertEqual(treeOnly[.treeNuts]?.0, .contains)
        XCTAssertNil(treeOnly[.peanuts])
    }

    // MARK: - Ingredients classifier

    func testRealIngredientLabelScoresAsLabel() {
        let text = "Ingredients: sugar, palm oil, hazelnuts 13%, cocoa powder 7.4%, skimmed milk powder 6.6%, whey powder, emulsifier: lecithins (soy), vanillin."
        let result = IngredientsClassifier.classify(text)
        XCTAssertTrue(result.looksLikeLabel, "a real label must score as a label (score: \(result.score))")
    }

    func testFrenchLabelScoresAsLabel() {
        let text = "Ingrédients: sucre, huile de palme, NOISETTES 13%, cacao maigre 7,4%, LAIT écrémé en poudre 6,6%, LACTOSÉRUM en poudre, émulsifiants: lécithines (SOJA), vanilline."
        let result = IngredientsClassifier.classify(text)
        XCTAssertTrue(result.looksLikeLabel, "a French label must score as a label (score: \(result.score))")
    }

    func testGermanLabelScoresAsLabel() {
        let text = "Zutaten: Weizenmehl, Zucker, Vollmilchpulver, Haselnüsse, Hühnerei, Sojalecithin, E471, Salz."
        let result = IngredientsClassifier.classify(text)
        XCTAssertTrue(result.looksLikeLabel, "a German label must score as a label (score: \(result.score))")
    }

    func testNovelTextDoesNotScoreAsLabel() {
        let text = "It was a bright cold day in April and the clocks were striking thirteen. Winston Smith his chin nuzzled into his breast in an effort to escape the vile wind slipped quickly through the glass doors of Victory Mansions though not quickly enough to prevent a swirl of gritty dust from entering along with him."
        let result = IngredientsClassifier.classify(text)
        XCTAssertFalse(result.looksLikeLabel, "a novel page must not score as a label (score: \(result.score))")
    }

    func testMenuTextDoesNotScoreAsLabel() {
        let text = "Grilled salmon with seasonal vegetables and rice pilaf. Pan-seared duck breast with cherry reduction. Chocolate fondant with vanilla ice cream. House salad with balsamic vinaigrette."
        let result = IngredientsClassifier.classify(text)
        XCTAssertFalse(result.looksLikeLabel, "a menu must not score as a label (score: \(result.score))")
    }

    func testPosterTextDoesNotScoreAsLabel() {
        let text = "SUMMER FESTIVAL 2025 Live Music Food Drinks Family Fun July 15-17 City Park Free Entry"
        let result = IngredientsClassifier.classify(text)
        XCTAssertFalse(result.looksLikeLabel, "a poster must not score as a label (score: \(result.score))")
    }

    func testPlainIngredientListWithoutHeaderScoresAsLabel() {
        // The header is the first thing to fall outside the frame, and a
        // product with no allergens in it has nothing for the dictionary to
        // match. This still has to read as a label, or a legible packet comes
        // back as "Couldn't check this".
        let text = "water, sugar, salt, citric acid, natural flavouring, colour"
        let result = IngredientsClassifier.classify(text)
        XCTAssertTrue(result.looksLikeLabel,
                      "a header-less ingredient list must score as a label (score: \(result.score))")
    }

    func testProseWithCommasStillDoesNotScoreAsLabel() {
        // Guards the signal above: commas alone must not be enough.
        let text = "She paused, considered the question, and decided, after some thought, that the answer was no, though she could not say why, and the afternoon wore on."
        let result = IngredientsClassifier.classify(text)
        XCTAssertFalse(result.looksLikeLabel,
                       "comma-heavy prose must not score as a label (score: \(result.score))")
    }

    func testProductNameGuessedWithoutIngredientsHeader() {
        let text = "Choco Hazelnut Spread\n400g\nwater, sugar, hazelnuts, cocoa"
        XCTAssertEqual(IngredientsClassifier.guessProductName(from: text),
                       "Choco Hazelnut Spread")
    }

    func testProductNameGuessSkipsTheIngredientLineItself() {
        let text = "water, sugar, salt, citric acid, natural flavouring, colour"
        XCTAssertNil(IngredientsClassifier.guessProductName(from: text),
                     "a bare ingredient list has no product name to offer")
    }

    func testEmptyTextDoesNotScoreAsLabel() {
        let result = IngredientsClassifier.classify("")
        XCTAssertFalse(result.looksLikeLabel, "empty text must not be a label")
    }

    func testFailSafeNonLabelTextBecomesInconclusive() {
        // Non-label text with no allergens found: must be inconclusive.
        let label = SourceReading(
            source: .label,
            findings: engine.analyze(labelText: "The quick brown fox jumps over the lazy dog")
        )
        let result = engine.combine(
            readings: [label],
            profile: [.milk, .gluten],
            labelText: "The quick brown fox jumps over the lazy dog"
        )
        XCTAssertTrue(result.isInconclusive,
                      "non-label text with no allergens must be inconclusive, not all-clear")
        XCTAssertEqual(result.headline, .couldNotCheck)
    }

    func testFailSafeNonLabelTextStillFlagsAllergens() {
        // Non-label text BUT it happens to mention an allergen: must still flag it.
        let label = SourceReading(
            source: .label,
            findings: engine.analyze(labelText: "The butter was fresh from the farm")
        )
        let result = engine.combine(
            readings: [label],
            profile: [.milk],
            labelText: "The butter was fresh from the farm"
        )
        XCTAssertFalse(result.isInconclusive,
                       "allergens found in non-label text must still be flagged")
        XCTAssertEqual(result.findings.first(where: { $0.allergen == .milk })?.status, .contains)
    }

    func testClassifierNeverTurnsRedToGreen() {
        // Even with low classifier confidence, allergens found must be reported.
        let label = SourceReading(
            source: .label,
            findings: [.peanuts: (.contains, ["peanut"])]
        )
        let result = engine.combine(
            readings: [label],
            profile: [.peanuts],
            labelText: "Random text about peanut processing"
        )
        XCTAssertEqual(result.findings.first?.status, .contains,
                       "classifier must never suppress an allergen hit")
    }

    func testDatabaseSourcePreventsInconclusiveOnNonLabelText() {
        // If we have a database source, non-label OCR text shouldn't make it inconclusive.
        let label = SourceReading(source: .label, findings: [:])
        let db = SourceReading(source: .database, findings: [:])
        let result = engine.combine(
            readings: [label, db],
            profile: [.milk],
            labelText: "Some random text that is not a label"
        )
        XCTAssertFalse(result.isInconclusive,
                       "database source should prevent inconclusive even with non-label OCR text")
    }

    func testIngredientsTextsArePassedThrough() {
        let label = SourceReading(source: .label, findings: [:])
        let result = engine.combine(
            readings: [label],
            profile: [.milk],
            labelText: "Ingredients: sugar, salt",
            databaseText: "Sugar, wheat flour, milk"
        )
        XCTAssertEqual(result.ingredientsTexts.count, 2)
        XCTAssertEqual(result.ingredientsTexts[0].source, .label)
        XCTAssertEqual(result.ingredientsTexts[1].source, .database)
    }

    // Explicit registry — no XCTest runtime here to discover these for us.
    lazy var allTests: [(String, () throws -> Void)] = [
        ("testDetectsMilkFromDerivativesThatNeverSayMilk", testDetectsMilkFromDerivativesThatNeverSayMilk),
        ("testDetectsGlutenFromDerivatives", testDetectsGlutenFromDerivatives),
        ("testDetectsEggFromDerivatives", testDetectsEggFromDerivatives),
        ("testDetectsHiddenFishAndSesame", testDetectsHiddenFishAndSesame),
        ("testDetectsSulphiteENumbers", testDetectsSulphiteENumbers),
        ("testPeanutButterIsNotDairy", testPeanutButterIsNotDairy),
        ("testCoconutMilkIsNotDairy", testCoconutMilkIsNotDairy),
        ("testCocoaButterIsNotDairy", testCocoaButterIsNotDairy),
        ("testAlmondMilkIsTreeNutNotDairy", testAlmondMilkIsTreeNutNotDairy),
        ("testWordsThatMerelyContainAllergenSubstrings", testWordsThatMerelyContainAllergenSubstrings),
        ("testFreeFromClaimsAreNotTreatedAsIngredients", testFreeFromClaimsAreNotTreatedAsIngredients),
        ("testFreeFromClaimDoesNotMaskARealIngredientElsewhere", testFreeFromClaimDoesNotMaskARealIngredientElsewhere),
        ("testMayContainIsTracesNotIngredients", testMayContainIsTracesNotIngredients),
        ("testFactoryWarningIsTraces", testFactoryWarningIsTraces),
        ("testPrecautionaryMarkerDoesNotLeakBackwardsOverIngredients", testPrecautionaryMarkerDoesNotLeakBackwardsOverIngredients),
        ("testContainsBeatsMayContainForTheSameAllergen", testContainsBeatsMayContainForTheSameAllergen),
        ("testDatabaseFlagWinsWhenLabelMissesIt", testDatabaseFlagWinsWhenLabelMissesIt),
        ("testLabelFlagWinsWhenDatabaseMissesIt", testLabelFlagWinsWhenDatabaseMissesIt),
        ("testMostCautiousStatusWinsOnDisagreement", testMostCautiousStatusWinsOnDisagreement),
        ("testNoSourcesReadableIsInconclusiveNotAllClear", testNoSourcesReadableIsInconclusiveNotAllClear),
        ("testAllergensOutsideProfileAreNotReported", testAllergensOutsideProfileAreNotReported),
        ("testFlaggedAllergensSortAboveClearOnes", testFlaggedAllergensSortAboveClearOnes),
        ("testEvidenceExplainsTheVerdict", testEvidenceExplainsTheVerdict),
        ("testHandlesUppercaseAndPunctuationFromOCR", testHandlesUppercaseAndPunctuationFromOCR),
        ("testHandlesAccentedText", testHandlesAccentedText),
        ("testEmptyTextFindsNothing", testEmptyTextFindsNothing),
        ("testDecodesProductAndUnionsTagsWithIngredients", testDecodesProductAndUnionsTagsWithIngredients),
        ("testIngredientsTextCatchesAllergenMissingFromTags", testIngredientsTextCatchesAllergenMissingFromTags),
        ("testMissingProductThrowsNotFound", testMissingProductThrowsNotFound),
        ("testRecordWithNoDateCountsAsStale", testRecordWithNoDateCountsAsStale),
        ("testOldRecordIsStale", testOldRecordIsStale),
        ("testEveryAllergenHasAtLeastOneTerm", testEveryAllergenHasAtLeastOneTerm),
        ("testLongerPhrasesSortBeforeShorterOnes", testLongerPhrasesSortBeforeShorterOnes),
        ("testDetectsFrenchLabel", testDetectsFrenchLabel),
        ("testDetectsGermanLabel", testDetectsGermanLabel),
        ("testDetectsSpanishLabel", testDetectsSpanishLabel),
        ("testDetectsItalianLabel", testDetectsItalianLabel),
        ("testFrenchAndGermanFreeFromClaims", testFrenchAndGermanFreeFromClaims),
        ("testLigaturesAndEszettAreExpanded", testLigaturesAndEszettAreExpanded),
        ("testDefaultProfileIsNutsAndEggs", testDefaultProfileIsNutsAndEggs),
        ("testDefaultProfileCoversBothKindsOfNut", testDefaultProfileCoversBothKindsOfNut),
        ("testMarzipanIsNutsAndEgg", testMarzipanIsNutsAndEgg),
        ("testNougatIsNutsAndEgg", testNougatIsNutsAndEgg),
        ("testSurimiIsFishAndEgg", testSurimiIsFishAndEgg),
        ("testNutDerivativesThatDoNotSayNut", testNutDerivativesThatDoNotSayNut),
        ("testPeanutDerivativesThatDoNotSayPeanut", testPeanutDerivativesThatDoNotSayPeanut),
        ("testEggDerivativesThatDoNotSayEgg", testEggDerivativesThatDoNotSayEgg),
        ("testNutAndEggAcrossEuropeanLanguages", testNutAndEggAcrossEuropeanLanguages),
        ("testPeanutAndTreeNutStayDistinct", testPeanutAndTreeNutStayDistinct),
        ("testRealIngredientLabelScoresAsLabel", testRealIngredientLabelScoresAsLabel),
        ("testFrenchLabelScoresAsLabel", testFrenchLabelScoresAsLabel),
        ("testGermanLabelScoresAsLabel", testGermanLabelScoresAsLabel),
        ("testNovelTextDoesNotScoreAsLabel", testNovelTextDoesNotScoreAsLabel),
        ("testMenuTextDoesNotScoreAsLabel", testMenuTextDoesNotScoreAsLabel),
        ("testPosterTextDoesNotScoreAsLabel", testPosterTextDoesNotScoreAsLabel),
        ("testPlainIngredientListWithoutHeaderScoresAsLabel", testPlainIngredientListWithoutHeaderScoresAsLabel),
        ("testProseWithCommasStillDoesNotScoreAsLabel", testProseWithCommasStillDoesNotScoreAsLabel),
        ("testProductNameGuessedWithoutIngredientsHeader", testProductNameGuessedWithoutIngredientsHeader),
        ("testProductNameGuessSkipsTheIngredientLineItself", testProductNameGuessSkipsTheIngredientLineItself),
        ("testEmptyTextDoesNotScoreAsLabel", testEmptyTextDoesNotScoreAsLabel),
        ("testFailSafeNonLabelTextBecomesInconclusive", testFailSafeNonLabelTextBecomesInconclusive),
        ("testFailSafeNonLabelTextStillFlagsAllergens", testFailSafeNonLabelTextStillFlagsAllergens),
        ("testClassifierNeverTurnsRedToGreen", testClassifierNeverTurnsRedToGreen),
        ("testDatabaseSourcePreventsInconclusiveOnNonLabelText", testDatabaseSourcePreventsInconclusiveOnNonLabelText),
        ("testIngredientsTextsArePassedThrough", testIngredientsTextsArePassedThrough),
    ]
}
