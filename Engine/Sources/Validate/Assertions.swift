import Foundation

/// A very small XCTest-shaped shim.
///
/// Xcode is not required to run these — `swift run Validate` executes the
/// whole suite from the command line. The assertion names deliberately match
/// XCTest so the suite can be lifted into a real test target unchanged if you
/// later want it running inside Xcode.
enum Failures {
    nonisolated(unsafe) static var messages: [String] = []
    nonisolated(unsafe) static var currentTest = ""

    static func record(_ message: String, _ file: String, _ line: Int) {
        let short = (file as NSString).lastPathComponent
        messages.append("  \(currentTest) — \(message)  (\(short):\(line))")
    }
}

func XCTAssertEqual<T: Equatable>(_ a: @autoclosure () -> T,
                                  _ b: @autoclosure () -> T,
                                  _ message: String = "",
                                  file: String = #file, line: Int = #line) {
    let (x, y) = (a(), b())
    if x != y {
        Failures.record("expected \(y), got \(x). \(message)", file, line)
    }
}

func XCTAssertNotEqual<T: Equatable>(_ a: @autoclosure () -> T,
                                     _ b: @autoclosure () -> T,
                                     _ message: String = "",
                                     file: String = #file, line: Int = #line) {
    if a() == b() { Failures.record("expected values to differ. \(message)", file, line) }
}

func XCTAssertNil<T>(_ value: @autoclosure () -> T?,
                     _ message: String = "",
                     file: String = #file, line: Int = #line) {
    if let v = value() { Failures.record("expected nil, got \(v). \(message)", file, line) }
}

func XCTAssertTrue(_ value: @autoclosure () -> Bool,
                   _ message: String = "",
                   file: String = #file, line: Int = #line) {
    if !value() { Failures.record("expected true. \(message)", file, line) }
}

func XCTAssertFalse(_ value: @autoclosure () -> Bool,
                    _ message: String = "",
                    file: String = #file, line: Int = #line) {
    if value() { Failures.record("expected false. \(message)", file, line) }
}

func XCTAssertGreaterThan<T: Comparable>(_ a: @autoclosure () -> T,
                                         _ b: @autoclosure () -> T,
                                         _ message: String = "",
                                         file: String = #file, line: Int = #line) {
    let (x, y) = (a(), b())
    if !(x > y) { Failures.record("expected \(x) > \(y). \(message)", file, line) }
}

func XCTAssertLessThan<T: Comparable>(_ a: @autoclosure () -> T,
                                      _ b: @autoclosure () -> T,
                                      _ message: String = "",
                                      file: String = #file, line: Int = #line) {
    let (x, y) = (a(), b())
    if !(x < y) { Failures.record("expected \(x) < \(y). \(message)", file, line) }
}

func XCTAssertThrowsError<T>(_ expression: @autoclosure () throws -> T,
                             _ message: String = "",
                             file: String = #file, line: Int = #line,
                             _ handler: (Error) -> Void = { _ in }) {
    do {
        _ = try expression()
        Failures.record("expected an error to be thrown. \(message)", file, line)
    } catch {
        handler(error)
    }
}

func XCTFail(_ message: String = "", file: String = #file, line: Int = #line) {
    Failures.record(message, file, line)
}
