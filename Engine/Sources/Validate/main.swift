import Foundation

// Runs the allergen engine's safety checks. Exits non-zero on any failure so
// this can gate a commit or a build.
let suite = AllergenEngineTests()
var passed = 0

print("AlergenScan — allergen engine checks\n")

for (name, body) in suite.allTests {
    Failures.currentTest = name
    let before = Failures.messages.count
    do {
        try body()
    } catch {
        Failures.record("threw unexpectedly: \(error)", #file, #line)
    }
    if Failures.messages.count == before {
        passed += 1
        print("  ✓ \(name)")
    } else {
        print("  ✗ \(name)")
    }
}

print("\n\(passed)/\(suite.allTests.count) passed")

if !Failures.messages.isEmpty {
    print("\nFailures:")
    Failures.messages.forEach { print($0) }
    exit(1)
}
