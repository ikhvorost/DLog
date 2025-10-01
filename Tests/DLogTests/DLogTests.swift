import Foundation
import XCTest
import DLog
import Network
/*@testable*/ import DLog


let Location = "<DLogTests.swift:[0-9]+>"
let SECS = #"[0-9]+(\.[0-9]{3})?s"#
let Interval = #"\{average:\#(SECS),duration:\#(SECS)\}"#
let Empty = ">$"

// MARK: - Atomic

@discardableResult
func synchronized<T>(_ obj: AnyObject, body: () -> T) -> T {
  objc_sync_enter(obj)
  defer {
    objc_sync_exit(obj)
  }
  return body()
}

class Atomic<T>: @unchecked Sendable {
  fileprivate var _value: T
  
  init(_ value: T) {
    _value = value
  }
  
  var value: T {
    get {
      synchronized(self) { _value }
    }
    set {
      synchronized(self) { _value = newValue }
    }
  }
  
  func sync<U>(_ body: (inout T) -> U) -> U {
    synchronized(self) { body(&_value) }
  }
}

// MARK: - Extensions

// Locale: en_US
extension NSLocale {
  @objc
  static let currentLocale = NSLocale(localeIdentifier: "en_US")
}

// Time zone: GMT
// NSTimeZone.default = TimeZone(abbreviation: "GMT")!
extension NSTimeZone {
  @objc
  static let defaultTimeZone = TimeZone(abbreviation: "GMT")
}

extension String {
  func match(_ pattern: String) -> Bool {
    let range = self.range(of: pattern, options: [.regularExpression])
    return range != nil
  }
}

extension StaticString {
  var string: String { "\(self)" }
}

fileprivate extension XCTestCase {
  
  func wait(count: Int, timeout: TimeInterval = 1, repeat r: Int = 1, name: String = #function, closure: ([XCTestExpectation]) -> Void) {
    guard count > 0, r > 0 else { return }
    
    let exps = (0..<r * count).map { _ in expectation(description: name) }
    
    for i in 0..<r {
      let start = Int(i * count)
      let end = start + Int(count) - 1
      closure(Array(exps[start...end]))
    }
    
    wait(for: exps, timeout: timeout)
  }
  
  func wait(timeout: TimeInterval = 1, name: String = #function, closure: (XCTestExpectation) -> Void) {
    wait(count: 1, timeout: timeout, name: name) { expectations in
      closure(expectations[0])
    }
  }
}

// MARK: - Utils

fileprivate func delay(_ secs: [TimeInterval] = [0.1]) {
  let sec = secs.randomElement()!
  Thread.sleep(forTimeInterval: sec)
}

/// Get text standard output
fileprivate func readStream(file: Int32, stream: UnsafeMutablePointer<FILE>, block: () -> Void) -> String {
  let buffer = Atomic([String]())
  
  // Set pipe
  let pipe = Pipe()
  let original = dup(file);
  setvbuf(stream, nil, _IONBF, 0)
  dup2(pipe.fileHandleForWriting.fileDescriptor, file)
  
  pipe.fileHandleForReading.readabilityHandler = { handle in
    if let text = String(data: handle.availableData, encoding: .utf8) {
      buffer.sync { $0.append(text) }
    }
  }
  
  block()
  
  delay()
  
  // Revert
  fflush(stream)
  dup2(original, file)
  close(original)
  
  // Print
  let text = buffer.value.joined()
  print(text, terminator: "")
  
  return text
}

fileprivate func read_stdout(_ block: () -> Void) -> String? {
  readStream(file: STDOUT_FILENO, stream: stdout, block: block)
}

fileprivate func read_stderr(_ block: () -> Void) -> String? {
  readStream(file: STDERR_FILENO, stream: stderr, block: block)
}

//  log stream --debug --info --predicate 'subsystem == "com.dlog.logger"'
fileprivate func read_oslog_stream(subsystem: String = "com.dlog.logger", block: () -> Void) -> String {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
  process.arguments = ["stream", "--debug", "--info", "--predicate", "subsystem == \"\(subsystem)\""]
  let pipe = Pipe()
  process.standardOutput = pipe
  do {
    try process.run()
  }
  catch {
    print("Error running process: \(error.localizedDescription)")
  }
  delay()
  
  let buffer = Atomic([String]())
  pipe.fileHandleForReading.readabilityHandler = { handle in
    if let text = String(data: handle.availableData, encoding: .utf8) {
      buffer.sync { $0.append(text) }
    }
  }
  
  block()
  delay()
  
  return buffer.value.joined()
}

@discardableResult
fileprivate func log_all(_ log: Log, message: LogMessage) -> [LogItem?] {
  return [
    log.log(message),
    log.log("\(message)"),
    
    log.trace(message),
    log.trace("\(message)"),
    
    log.debug(message),
    log.debug("\(message)"),
    
    log.info(message),
    log.info("\(message)"),
    
    log.warning(message),
    log.warning("\(message)"),
    
    log.error(message),
    log.error("\(message)"),
    
    log.assert(false, message),
    log.assert(false, "\(message)"),
    
    log.fault(message),
    log.fault("\(message)"),
  ]
}

final class DLogTests: XCTestCase {
  
  func test_sendable() {
    let logger = DLog()
    let net = logger["NET"]
    let interval = logger.interval("interval")
    let scope = logger.scope("scope")
    
    DispatchQueue.global().async {
      logger.log("log")
      net.info("info")
      
      interval?.begin()
      interval?.end()
      
      scope?.enter()
      scope?.leave()
    }
  }
  
  func test_disabled() {
    let logger = DLog.disabled
    
    log_all(logger, message: "log").forEach {
      XCTAssert($0 == nil)
    }
    
    XCTAssert(logger.scope("scope") == nil)
    XCTAssert(logger.interval("interval") == nil)
  }
  
  func test_block() {
    let logger = DLog()
    
    let date = Date()
    
    log_all(logger, message: "log")
    
    logger.scope("scope") {
      log_all($0, message: "log")
    }
    
    logger.interval("interval") {
      log_all(logger, message: "log")
    }
    
    let timeout = -date.timeIntervalSinceNow
    XCTAssert(timeout < 0.001)
  }
  
  func test_category() {
    let logger = DLog()
    
    let net = logger["NET"]
    var item = net.log("log")
    XCTAssert(item?.category == "NET")
    
    let store = logger.category(name: "STORE")
    item = store.log("log")
    XCTAssert(item?.category == "STORE")
  }
  
  func test_log_params() {
    let logger = DLog()
    
    var item = logger.log()
    XCTAssert(item?.message == "")
    
    item = logger.log(10)
    XCTAssert(item?.message == "10")
    
    let name = "Bob"
    item = logger.log(name)
    XCTAssert(item?.message == "Bob")
    
    let a = 1
    let b = 3.0
    item = logger.log(a, "two", b, true)
    XCTAssert(item?.message == "1 two 3.0 true")
  }
  
  func test_trace() {
    let log = DLog()
    
    let item = log.trace("trace")
    XCTAssert(item?.traceInfo.processInfo == ProcessInfo.processInfo)
    XCTAssert(item?.traceInfo.queueLabel == "com.apple.main-thread")
    XCTAssert(item?.traceInfo.stackAddresses.count != 0)
    XCTAssert(item?.traceInfo.thread == Thread.current)
    XCTAssert(item?.traceInfo.tid != 0)
  }
  
  func test_assert() {
    let log = DLog()
    let item = log.assert(true, "assert")
    XCTAssert(item == nil)
  }
  
  func test_log_all() {
    let log = DLog(metadata: ["a" : 10])
    log.metadata["a"] = 20
    XCTAssert(log.metadata["a"] as? Int == 20)
    log.metadata["b"] = "20"
    XCTAssert(log.metadata["b"] as? String == "20")
    
    log_all(log, message: "log").forEach {
      guard let item = $0 else {
        XCTFail()
        return
      }
      
      XCTAssert(item.time <= Date())
      XCTAssert(item.category == "DLOG")
      XCTAssert(item.stack == nil)
      
      XCTAssert(item.location.fileID.string == "DLogTests/DLogTests.swift")
      XCTAssert(item.location.file.string == "DLogTests/DLogTests.swift")
      XCTAssert(item.location.function.string == "log_all(_:message:)")
      XCTAssert(item.location.line < #line)
      XCTAssert(item.location.moduleName == "DLogTests")
      XCTAssert(item.location.fileName == "DLogTests.swift")
      
      XCTAssert(item.metadata.count == 2)
      XCTAssert(item.metadata["a"] as? Int == 20)
      XCTAssert(item.metadata["b"] as? String == "20")
      
      XCTAssert(item.message == "log")
    }
    
    log.metadata.removeAll()
    XCTAssert(log.metadata.value.isEmpty)
  }
  
  func test_scope() {
    let logger = DLog()
    
    let scope = logger.scope("scope") { scope in
      XCTAssert(scope.name == "scope")
      XCTAssert(scope.level == 1)
      XCTAssert(scope.duration == 0)
      
      delay()
      
      let item = scope.log("log")
      XCTAssert(item?.stack?.count == 0)
    }
    XCTAssert(scope?.level == 0)
    XCTAssert((scope?.duration ?? 0) >= 0.1)
    
    
    scope?.enter()
    scope?.enter()
    
    XCTAssert(scope?.level == 1)
    XCTAssert(scope?.duration == 0)
    
    delay()
    
    let item = scope?.log("log")
    XCTAssert(item?.stack?.count == 0)
    
    scope?.leave()
    scope?.leave()
    
    XCTAssert(scope?.level == 0)
    XCTAssert((scope?.duration ?? 0) >= 0.1)
  }
  
  func test_scope_stack() {
    let log = DLog()
    
    log.scope("Scope0") { scope in
      XCTAssert(scope.level == 1)
      let item = scope.debug("debug")
      XCTAssert(item?.stack?.count == 0)
      
      scope.scope("Scope1") { scope in
        XCTAssert(scope.level == 2)
        let item = scope.debug("debug")
        XCTAssert(item?.stack?.count == 1)
        
        scope.scope("Scope2") { scope in
          XCTAssert(scope.level == 3)
          let item = scope.debug("debug")
          XCTAssert(item?.stack?.count == 2)
        }
      }
    }
  }
  
  func test_scope_concurrent() {
    let logger = DLog()
    
    DispatchQueue.concurrentPerform(iterations: 10) { i in
      delay([0.1, 0.2, 0.3, 0.4])
      let scope = logger.scope("Scope \(i)") {
        delay([0.1, 0.2, 0.3, 0.4])
        $0.debug("debug \(i)")
      }
      XCTAssert(scope?.duration ?? 0 >= 0.1)
    }
  }
  
  func test_interval() {
    let logger = DLog()
    
    let int = logger.interval("interval2")
    if let stats = int?.stats {
      XCTAssert(stats.count == 0)
      XCTAssert(stats.total == 0)
      XCTAssert(stats.min == 0)
      XCTAssert(stats.max == 0)
      XCTAssert(stats.average == 0)
    }
    
    let interval = logger.interval("interval") {
      delay()
    }
    XCTAssert("\(interval!.name)" == "interval")
    XCTAssert((interval?.duration ?? 0) >= 0.1)
    if let stats = interval?.stats {
      XCTAssert(stats.count == 1)
      XCTAssert(stats.total >= 0.1)
      XCTAssert(stats.min >= 0.1)
      XCTAssert(stats.max >= 0.1)
      XCTAssert(stats.average >= 0.1)
    }
    
    interval?.begin()
    interval?.begin()
    
    delay([0.3])
    
    interval?.end()
    interval?.end()
    
    XCTAssert(interval?.duration ?? 0 >= 0.1)
    if let stats = interval?.stats {
      XCTAssert(stats.count == 2)
      XCTAssert(stats.total >= 0.2)
      XCTAssert(stats.min >= 0.1)
      XCTAssert(stats.max >= 0.3)
      XCTAssert(stats.average >= 0.2)
    }
    
    interval?.begin()
    
    delay([0.2])
    
    interval?.end()
    XCTAssert(interval?.duration ?? 0 >= 0.1)
    if let stats = interval?.stats {
      XCTAssert(stats.count == 3)
      XCTAssert(stats.total >= 0.5)
      XCTAssert(stats.min >= 0.1)
      XCTAssert(stats.max >= 0.3)
      XCTAssert(stats.average >= 0.2)
    }
  }
  
  func test_interval_concurrent() {
    let logger = DLog()
    
    let interval = Atomic<LogInterval?>(nil)
    
    DispatchQueue.concurrentPerform(iterations: 10) { i in
      interval.value = logger.interval("interval") {
        delay()
      }
    }
    
    XCTAssert(interval.value?.duration ?? 0 >= 0.1)
    if let stats = interval.value?.stats {
      XCTAssert(stats.count == 10)
      XCTAssert(stats.total >= 1.0)
      XCTAssert(stats.min >= 0.1)
      XCTAssert(stats.max >= 0.1)
      XCTAssert(stats.average >= 0.1)
    }
  }
  
  func test_metadata() {
    let logger = DLog(metadata: ["value" : 400])
    
    var item = logger.debug("Hello")
    XCTAssert(item?.metadata["value"] as? Int == 400)
    
    let net = logger["NET"]
    net.metadata["key"] = 12345
    item = net.log("Hello")
    XCTAssert(item?.metadata["value"] as? Int == 400)
    XCTAssert(item?.metadata["key"] as? Int == 12345)
  }
  
}

final class FormatTests: XCTestCase {
  
  func test_privacy() {
    let logger = DLog()
    
    let empty = ""
    let cardNumber = "1234 5678 9012 3456"
    let greeting = "Hello World!"
    let number = 1234567890
    
    XCTAssert(logger.log("Default: \(cardNumber)")?.description.match(cardNumber) == true)
    XCTAssert(logger.log("Public: \(cardNumber, privacy: .public)")?.description.match(cardNumber) == true)
    
    XCTAssert(logger.log("Private: \(cardNumber, privacy: .private)")?.description.match("<private>") == true)
    
    XCTAssert(logger.log("Private hash: \(cardNumber, privacy: .private(mask: .hash))")?.description.match("[0-9a-fA-F]+") == true)
    
    XCTAssert(logger.log("Private random: \(empty, privacy: .private(mask: .random))")?.description.match("Private random:$") == true)
    XCTAssert(logger.log("Private random: \(cardNumber, privacy: .private(mask: .random))")?.description.match(cardNumber) == false)
    XCTAssert(logger.log("Private random: \(greeting, privacy: .private(mask: .random))")?.description.match(greeting) == false)
    
    XCTAssert(logger.log("Private redact: \(empty, privacy: .private(mask: .redact))")?.description.match("Private redact:$") == true)
    XCTAssert(logger.log("Private redact: \(cardNumber, privacy: .private(mask: .redact))")?.description.match("0000 0000 0000 0000") == true)
    XCTAssert(logger.log("Private redact: \(greeting, privacy: .private(mask: .redact))")?.description.match("XXXXX XXXXX!") == true)
    
    XCTAssert(logger.log("Private shuffle: \("1 2 3", privacy: .private(mask: .shuffle))")?.description.match("1 2 3") == true)
    XCTAssert(logger.log("Private shuffle: \(cardNumber, privacy: .private(mask: .shuffle))")?.description.match(cardNumber) == false)
    XCTAssert(logger.log("Private shuffle: \(greeting, privacy: .private(mask: .shuffle))")?.description.match(greeting) == false)
    
    XCTAssert(logger.log("Private custom: \(cardNumber, privacy: .private(mask: .custom(value: "<null>")))")?.description.match("<null>") == true)
    
    XCTAssert(logger.log("Private partial: \(empty, privacy: .private(mask: .partial(first: -1, last: -2)))")?.description.match("Private partial:$") == true)
    XCTAssert(logger.log("Private partial: \(cardNumber, privacy: .private(mask: .partial(first: -1, last: -2)))")?.description.match("[\\*]{19}") == true)
    XCTAssert(logger.log("Private partial: \(cardNumber, privacy: .private(mask: .partial(first: 0, last: 0)))")?.description.match("[\\*]{19}") == true)
    XCTAssert(logger.log("Private partial: \(cardNumber, privacy: .private(mask: .partial(first: 1, last: 4)))")?.description.match("1[\\*]{14}3456") == true)
    XCTAssert(logger.log("Private partial: \(cardNumber, privacy: .private(mask: .partial(first: 10, last: 10)))")?.description.match(cardNumber) == true)
    
    XCTAssert(logger.log("Private reduce: \(cardNumber, privacy: .private(mask: .reduce(length: -3)))")?.description.match("...") == true)
    XCTAssert(logger.log("Private reduce: \(cardNumber, privacy: .private(mask: .reduce(length: 0)))")?.description.match("...") == true)
    XCTAssert(logger.log("Private reduce: \(cardNumber, privacy: .private(mask: .reduce(length: 1)))")?.description.match("...6") == true)
    XCTAssert(logger.log("Private reduce: \(cardNumber, privacy: .private(mask: .reduce(length: 2)))")?.description.match("1...6") == true)
    XCTAssert(logger.log("Private reduce: \(cardNumber, privacy: .private(mask: .reduce(length: 7)))")?.description.match("123...3456") == true)
    XCTAssert(logger.log("Private reduce: \(cardNumber, privacy: .private(mask: .reduce(length: 100)))")?.description.match(cardNumber) == true)
    XCTAssert(logger.log("Private reduce: \(greeting, privacy: .private(mask: .reduce(length: 6)))")?.description.match("Hel...ld!") == true)
    
    XCTAssert(logger.log("Private reduce: \(number, privacy: .private(mask: .reduce(length: 6)))")?.description.match("123...890") == true)
  }
  
  func test_date() {
    let logger = DLog()
    
    let date = Date(timeIntervalSince1970: 1645026131) // 2022-02-16 15:42:11 +0000
    
    // Default
    XCTAssert(logger.log("\(date)")?.description.match("2022-02-16 15:42:11 \\+0000") == true)
    
    // Date only
    XCTAssert(logger.log("\(date, format: .date(dateStyle: .short))")?.description.match("2/16/22") == true)
    XCTAssert(logger.log("\(date, format: .date(dateStyle: .medium))")?.description.match("Feb 16, 2022") == true)
    XCTAssert(logger.log("\(date, format: .date(dateStyle: .long))")?.description.match("February 16, 2022") == true)
    XCTAssert(logger.log("\(date, format: .date(dateStyle: .full))")?.description.match("Wednesday, February 16, 2022") == true)
    
    // Time only
    XCTAssert(logger.log("\(date, format: .date(timeStyle: .short))")?.description.match("3:42 PM") == true)
    XCTAssert(logger.log("\(date, format: .date(timeStyle: .medium))")?.description.match("3:42:11 PM") == true)
    XCTAssert(logger.log("\(date, format: .date(timeStyle: .long))")?.description.match("3:42:11 PM GMT") == true)
    XCTAssert(logger.log("\(date, format: .date(timeStyle: .full))")?.description.match("3:42:11 PM Greenwich Mean Time") == true)
    
    // Both
    XCTAssert(logger.log("\(date, format: .date())")?.description.match(Empty) == true) // Empty
    XCTAssert(logger.log("\(date, format: .date(dateStyle: .medium, timeStyle: .short))")?.description.match("Feb 16, 2022 at 3:42 PM") == true)
    
    // Custom
    XCTAssert(logger.log("\(date, format: .dateCustom(format: "dd-MM-yyyy"))")?.description.match("16-02-2022") == true)
    
    // Privacy
    XCTAssert(logger.log("\(date, format: .date(dateStyle: .short), privacy: .private(mask: .redact))")?.description.match("0/00/00") == true)
    
    // Locale
    let locale = Locale(identifier: "en_GB")
    XCTAssert(logger.log("\(date, format: .date(dateStyle: .medium, timeStyle: .short, locale: locale))")?.description.match("16 Feb 2022 at 15:42") == true)
  }
  
  func test_int() {
    let logger = DLog()
    
    let value = 20_234_557
    
    // Default
    XCTAssert(logger.log("\(value)")?.description.match("20234557") == true)
    
    // Binary
    XCTAssert(logger.log("\(8, format: .binary)")?.description.match("1000") == true)
    
    // Octal
    XCTAssert(logger.log("\(10, format: .octal)")?.description.match("12") == true)
    XCTAssert(logger.log("\(10, format: .octal(includePrefix: true))")?.description.match("0o12") == true)
    
    // Hex
    XCTAssert(logger.log("\(value, format: .hex)")?.description.match("134c13d") == true)
    XCTAssert(logger.log("\(value, format: .hex(includePrefix: true))")?.description.match("0x134c13d") == true)
    XCTAssert(logger.log("\(value, format: .hex(uppercase: true))")?.description.match("134C13D") == true)
    XCTAssert(logger.log("\(value, format: .hex(includePrefix: true, uppercase: true))")?.description.match("0x134C13D") == true)
    
    // Byte count
    
    // Count style
    XCTAssert(logger.log("\(1000, format: .byteCount)")?.description.match("1 KB") == true)
    
    XCTAssert(logger.log("\(value, format: .byteCount(countStyle: .file))")?.description.match("20.2 MB") == true)
    XCTAssert(logger.log("\(value, format: .byteCount(countStyle: .memory))")?.description.match("19.3 MB") == true)
    XCTAssert(logger.log("\(value, format: .byteCount(countStyle: .decimal))")?.description.match("20.2 MB") == true)
    XCTAssert(logger.log("\(value, format: .byteCount(countStyle: .binary))")?.description.match("19.3 MB") == true)
    
    // Allowed Units
    XCTAssert(logger.log("\(value, format: .byteCount(allowedUnits: .useBytes))")?.description.match("20,234,557 bytes") == true)
    XCTAssert(logger.log("\(value, format: .byteCount(allowedUnits: .useKB))")?.description.match("20,235 KB") == true)
    XCTAssert(logger.log("\(value, format: .byteCount(allowedUnits: .useGB))")?.description.match("0.02 GB") == true)
    
    // Both
    XCTAssert(logger.log("\(value, format: .byteCount(countStyle: .memory, allowedUnits: .useGB))")?.description.match("0.02 GB") == true)
    
    // Privacy
    XCTAssert(logger.log("\(value, format: .byteCount(allowedUnits: .useMB), privacy: .private(mask: .redact))")?.description.match("00.0 XX") == true)
    
    // Number
    let number = 1_234
    XCTAssert(logger.log("\(number)")?.description.match("\(number)") == true)
    XCTAssert(logger.log("\(number, format: .number)")?.description.match("1,234") == true)
    XCTAssert(logger.log("\(number, format: .number(style: .none))")?.description.match("\(number)") == true)
    XCTAssert(logger.log("\(number, format: .number(style: .decimal))")?.description.match("1,234") == true)
    XCTAssert(logger.log("\(number, format: .number(style: .currency))")?.description.match("\\$1,234\\.00") == true)
    XCTAssert(logger.log("\(number, format: .number(style: .percent))")?.description.match("123,400%") == true)
    XCTAssert(logger.log("\(number, format: .number(style: .scientific))")?.description.match("1.234E3") == true)
    XCTAssert(logger.log("\(number, format: .number(style: .spellOut))")?.description.match("one thousand two hundred thirty-four") == true)
    
    // Privacy
    XCTAssert(logger.log("\(number, format: .number(style: .decimal), privacy: .private(mask: .redact))")?.description.match("0,000") == true)
    
    // Locale
    let locale = Locale(identifier: "en_GB")
    XCTAssert(logger.log("\(number, format: .number(style: .currency, locale: locale))")?.description.match("\\£1,234\\.00") == true)
    // Number
    
    // HTTP
    XCTAssert(logger.log("\(200, format: .httpStatusCode)")?.description.match("HTTP 200 no error") == true)
    XCTAssert(logger.log("\(400, format: .httpStatusCode)")?.description.match("HTTP 400 bad request") == true)
    XCTAssert(logger.log("\(404, format: .httpStatusCode)")?.description.match("HTTP 404 not found") == true)
    XCTAssert(logger.log("\(500, format: .httpStatusCode)")?.description.match("HTTP 500 internal server error") == true)
    
    // IPv4
    let ip4 = 0x0100007f // 16777343
    XCTAssert(logger.log("\(0, format: .ipv4Address)")?.description.match("0.0.0.0") == true)
    XCTAssert(logger.log("\(ip4, format: .ipv4Address)")?.description.match("127.0.0.1") == true)
    XCTAssert(logger.log("\(-ip4, format: .ipv4Address)")?.description.match("127.0.0.1") == false)
    XCTAssert(logger.log("\(0x0101a8c0, format: .ipv4Address)")?.description.match("192.168.1.1") == true)
    
    // Time
    let time = 60 * 60 + 23 * 60 + 15
    XCTAssert(logger.log("\(time, format: .time)")?.description.match("1h 23m 15s") == true)
    XCTAssert(logger.log("\(time, format: .time(unitsStyle: .positional))")?.description.match("1:23:15") == true)
    XCTAssert(logger.log("\(time, format: .time(unitsStyle: .short))")?.description.match("1 hr, 23 min, 15 sec") == true)
    XCTAssert(logger.log("\(time, format: .time(unitsStyle: .full))")?.description.match("1 hour, 23 minutes, 15 seconds") == true)
    XCTAssert(logger.log("\(time, format: .time(unitsStyle: .spellOut))")?.description.match("one hour, twenty-three minutes, fifteen seconds") == true)
    
    // Date
    let timeIntervalSince1970 = 1645026131 // 2022-02-16 15:42:11 +0000
    XCTAssert(logger.log("\(timeIntervalSince1970, format: .date)")?.description.match("2/16/22, 3:42 PM$") == true)
    XCTAssert(logger.log("\(timeIntervalSince1970, format: .date(dateStyle: .short))")?.description.match("2/16/22$") == true)
    XCTAssert(logger.log("\(timeIntervalSince1970, format: .date(timeStyle: .medium))")?.description.match("3:42:11 PM$") == true)
    XCTAssert(logger.log("\(timeIntervalSince1970, format: .date(dateStyle: .short, timeStyle: .short, locale: locale))")?.description.match("16/02/2022, 15:42$") == true)
  }
  
  func test_double() {
    let logger = DLog()
    
    let value = 12.345
    
    // Default
    XCTAssert(logger.log("\(value)")?.description.match("12.345") == true)
    
    // Fixed
    XCTAssert(logger.log("\(value, format: .fixed)")?.description.match("12.345000") == true)
    XCTAssert(logger.log("\(value, format: .fixed(precision: 2))")?.description.match("12.35") == true)
    
    // Hex
    XCTAssert(logger.log("\(value, format: .hex)")?.description.match("1\\.8b0a3d70a3d71p\\+3") == true)
    XCTAssert(logger.log("\(value, format: .hex(includePrefix: true))")?.description.match("0x1\\.8b0a3d70a3d71p\\+3") == true)
    XCTAssert(logger.log("\(value, format: .hex(uppercase: true))")?.description.match("1\\.8B0A3D70A3D71P\\+3") == true)
    XCTAssert(logger.log("\(value, format: .hex(includePrefix: true, uppercase: true))")?.description.match("0x1\\.8B0A3D70A3D71P\\+3") == true)
    
    // Exponential
    XCTAssert(logger.log("\(value, format: .exponential)")?.description.match("1\\.234500e\\+01") == true)
    XCTAssert(logger.log("\(value, format: .exponential(precision: 2))")?.description.match("1\\.23e\\+01") == true)
    
    // Hybrid
    XCTAssert(logger.log("\(value, format: .hybrid)")?.description.match("12.345") == true)
    XCTAssert(logger.log("\(value, format: .hybrid(precision: 1))")?.description.match("1e\\+01") == true)
    
    // Privacy
    XCTAssert(logger.log("\(value, format: .hybrid(precision: 1), privacy: .private(mask: .redact))")?.description.match("0X\\+00") == true)
    
    // Number
    let number = 1_234.56
    XCTAssert(logger.log("\(number)")?.description.match("\(number)") == true)
    
    XCTAssert(logger.log("\(number, format: .number(style: .none))")?.description.match("1235") == true)
    XCTAssert(logger.log("\(number, format: .number(style: .decimal))")?.description.match("1,234.56") == true)
    XCTAssert(logger.log("\(number, format: .number(style: .currency))")?.description.match("\\$1,234\\.56") == true)
    XCTAssert(logger.log("\(number, format: .number(style: .percent))")?.description.match("123,456%") == true)
    XCTAssert(logger.log("\(number, format: .number(style: .scientific))")?.description.match("1.23456E3") == true)
    XCTAssert(logger.log("\(number, format: .number(style: .spellOut))")?.description.match("one thousand two hundred thirty-four point five six") == true)
    
    // Privacy
    XCTAssert(logger.log("\(number, format: .number(style: .decimal), privacy: .private(mask: .redact))")?.description.match("0,000.00") == true)
    
    // Locale
    let locale = Locale(identifier: "en_GB")
    XCTAssert(logger.log("\(number, format: .number(style: .currency, locale: locale))")?.description.match("\\£1,234\\.56") == true)
    // Number
    
    // Time
    let durationWithSecs = 60 * 60 + 23 * 60 + 1.25
    XCTAssert(logger.log("\(durationWithSecs, format: .time)")?.description.match("1h 23m 1.250s$") == true)
    XCTAssert(logger.log("\(durationWithSecs, format: .time(unitsStyle: .positional))")?.description.match("1:23:01.250$") == true)
    XCTAssert(logger.log("\(durationWithSecs, format: .time(unitsStyle: .short))")?.description.match("1 hr, 23 min, 1.250 sec$") == true)
    XCTAssert(logger.log("\(durationWithSecs, format: .time(unitsStyle: .full))")?.description.match("1 hour, 23 minutes, 1.250 second$") == true)
    XCTAssert(logger.log("\(durationWithSecs, format: .time(unitsStyle: .spellOut))")?.description.match("one hour, twenty-three minutes, one second, two hundred fifty milliseconds$") == true)
    XCTAssert(logger.log("\(durationWithSecs, format: .time(unitsStyle: .brief))")?.description.match("1hr 23min 1.250sec$") == true)
    
    let durationNoSecs = 60 * 60 + 23 * 60
    let durationWithMs = 60 * 60 + 23 * 60 + 0.45
    XCTAssert(logger.log("\(durationNoSecs, format: .time)")?.description.match("1h 23m$") == true)
    XCTAssert(logger.log("\(durationWithMs, format: .time)")?.description.match("1h 23m 0.450s$") == true)
    
    // Date
    let dateWithMin = 1645026131.45 // 2022-02-16 15:42:11 +0000
    XCTAssert(logger.log("\(dateWithMin, format: .date)")?.description.match("2/16/22, 3:42 PM$") == true)
    XCTAssert(logger.log("\(dateWithMin, format: .date(dateStyle: .short))")?.description.match("2/16/22$") == true)
    XCTAssert(logger.log("\(dateWithMin, format: .date(timeStyle: .medium))")?.description.match("3:42:11 PM$") == true)
    XCTAssert(logger.log("\(dateWithMin, format: .date(dateStyle: .short, timeStyle: .short, locale: locale))")?.description.match("16/02/2022, 15:42$") == true)
  }

  func test_bool() {
    let logger = DLog()
    
    let value = true
    
    // Default
    XCTAssert(logger.log("\(value)")?.description.match("true") == true)
    
    // Binary
    XCTAssert(logger.log("\(value, format: .binary)")?.description.match("1") == true)
    XCTAssert(logger.log("\(!value, format: .binary)")?.description.match("0") == true)
    
    // Answer
    XCTAssert(logger.log("\(value, format: .answer)")?.description.match("yes") == true)
    XCTAssert(logger.log("\(!value, format: .answer)")?.description.match("no") == true)
    
    // Toggle
    XCTAssert(logger.log("\(value, format: .toggle)")?.description.match("on") == true)
    XCTAssert(logger.log("\(!value, format: .toggle)")?.description.match("off") == true)
  }

  func test_data() {
    let logger = DLog()
    
    // IPv6
    let ipString = "2001:0b28:f23f:f005:0000:0000:0000:000a"
    let ipv6 = IPv6Address(ipString)!
    XCTAssert(logger.log("\(ipv6.rawValue, format: .ipv6Address)")?.description.match("2001:b28:f23f:f005::a$") == true)
    XCTAssert(logger.log("\(Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]), format: .ipv6Address)")?.description.match(Empty) == true)
    
    // Text
    let text = "Hello DLog!"
    var data = text.data(using: .utf8)!
    XCTAssert(logger.log("\(data, format: .text)")?.description.match(text) == true)
    XCTAssert(logger.log("\(Data([255, 2, 3, 4, 5, 6, 7, 8, 9]), format: .text)")?.description.match(Empty) == true)
    
    // UUID
    let uuid = UUID()
    var tuple = uuid.uuid
    data = withUnsafeBytes(of: &tuple) { Data($0) }
    XCTAssert(logger.log("\(data, format: .uuid)")?.description.match(uuid.uuidString) == true)
    XCTAssert(logger.log("\(Data([0, 1, 2, 3]), format: .uuid)")?.description.match(Empty) == true)
    
    // Raw
    data = Data([0xab, 0xcd, 0xef])
    XCTAssert(logger.log("\(data, format: .raw)")?.description.match("ABCDEF") == true)
  }

  func test_concurrent() {
    let logger = DLog()
    
    DispatchQueue.concurrentPerform(iterations: 10) { _ in
      delay([0.1, 0.2, 0.3])
      
      let date = Date(timeIntervalSince1970: 1645026131) // 2022-02-16 15:42:11 +0000
      XCTAssert(logger.log("\(date, format: .date(dateStyle: .short))")?.description.match("2/16/22") == true)
      
      delay([0.1, 0.2, 0.3])
      
      let number = 1_234_567_890
      XCTAssert(logger.log("\(number, format: .number(style: .none))")?.description.match("\(number)") == true)
      
      delay([0.1, 0.2, 0.3])
      
      let value: Int64 = 20_234_557
      XCTAssert(logger.log("\(value, format: .byteCount(countStyle: .file))")?.description.match("20.2 MB") == true)
    }
  }
}

final class OutputTests: XCTestCase {
  
  func test_plain() {
    var config = LogConfig()
    config.style = .plain
    config.options = .all
    let logger = DLog(config: config, metadata: ["a" : 10]) {
      Output {
        print($0)
        let pattern = #"^• \d{2}:\d{2}:\d{2}\.\d{3} \[\d{2}\] \[DLOG\] \[\#($0.type.title)\] <DLogTests.swift:\d+> \{a:10\}"#
        XCTAssert($0.description.match(pattern) == true, $0.description)
      }
    }
    _ = log_all(logger, message: "log")
    delay()
  }
  
  func test_colored() {
    var config = LogConfig()
    config.style = .colored
    config.options = .all
    let logger = DLog(config: config, metadata: ["a" : 10]) {
      Output {
        print($0.description)
        XCTAssert($0.description.match(#"^\u{001b}"#) == true)
      }
    }
    
    _ = log_all(logger, message: "log")
    logger.scope("scope") { _ in delay() }
    logger.interval("interval") { delay() }
    delay()
  }
  
  func test_emoji() {
    var config = LogConfig()
    config.style = .emoji
    config.options = .all
    let log = DLog(config: config, metadata: ["a" : 10]) {
      Output {
        print($0)
        let pattern = #"^• \d{2}:\d{2}:\d{2}\.\d{3} \[\d{2}\] \[DLOG\] \#($0.type.icon) \[\#($0.type.title)\] <DLogTests.swift:\d+> \{a:10\}"#
        XCTAssert($0.description.match(pattern) == true, $0.description)
      }
    }
    _ = log_all(log, message: "log")
    delay()
  }
  
  func test_trace_all() {
    var config = LogConfig()
    config.traceConfig.options = .all
    let logger = DLog(config: config) {
      Output {
        print($0)
        let pattern = #"\{func:test_trace_all,process:\{cpu:\d+%,memory:\d+MB,pid:\d+,threads:\d+\},queue:com.apple.main-thread,stack:\[\{frame:0,symbol:@objc DLogTests.OutputTests.test_trace_all\(\) -> \(\)\}\],thread:\{number:1\}\}$"#
        XCTAssert($0.description.match(pattern) == true)
      }
    }
    logger.trace()
    delay()
  }
  
  func trace(logger: DLog) {
    logger.trace()
  }
  
  func test_trace_function() {
    var config = LogConfig()
    config.traceConfig.funcConfig.params = true
    let logger = DLog(config: config) {
      Output {
        print($0)
        let pattern = #"\{func:trace\(logger:\)"#
        XCTAssert($0.description.match(pattern) == true)
      }
    }
    trace(logger: logger)
    delay()
  }
  
  func test_trace_process_all() {
    var config = LogConfig()
    config.traceConfig.options = .process
    config.traceConfig.processConfig.options = .all
    let logger = DLog(config: config) {
      Output {
        print($0)
        let pattern = #"\{process:\{cpu:\d+%,guid:[^,]+,memory:\d+MB,name:xctest,pid:\d+,threads:\d+,wakeups:\{idle:\d+,interrupt:\d+,timer:\d+\}\}\}$"#
        XCTAssert($0.description.match(pattern) == true)
      }
    }
    logger.trace()
    delay()
  }
  
  func test_trace_stack_all() {
    var config = LogConfig()
    config.traceConfig.options = .stack
    config.traceConfig.stackConfig.options = .all
    config.traceConfig.stackConfig.view = .all
    config.traceConfig.stackConfig.depth = 3
    let logger = DLog(config: config) {
      Output {
        print($0)
        let pattern = #"\{stack:\[\{address:[^,]+,frame:\d+,module:[^,]+,offset:\d+,symbol:@objc DLogTests\.OutputTests\.test_trace_stack_all\(\) -> \(\)\},\{address:[^,]+,frame:\d+,module:CoreFoundation,offset:\d+,symbol:__invoking___\}"#
        XCTAssert($0.description.match(pattern) == true)
      }
    }
    logger.trace()
    delay()
  }
  
  func test_trace_thread_all() {
    var config = LogConfig()
    config.traceConfig.options = .thread
    config.traceConfig.threadConfig.options = .all
    let logger = DLog(config: config) {
      Output {
        print($0)
        let pattern = #"\{thread:\{number:\d+,priority:0\.5,qos:(userInteractive|utility),stackSize:512 KB,tid:\d+\}\}$"#
        XCTAssert($0.description.match(pattern) == true)
      }
    }
    logger.trace()
    delay()
  }
  
  func test_trace_pretty() {
    var config = LogConfig()
    config.traceConfig.style = .pretty
    let logger = DLog(config: config) {
      Output {
        print($0)
        let pattern = #"""
        \{
          func : test_trace_pretty,
          thread : \{
            number : 1
          \}
        \}$
        """#
        XCTAssert($0.description.match(pattern) == true)
      }
    }
    logger.trace()
    delay()
  }
  
  func test_interval_all() {
    var config = LogConfig()
    config.intervalConfig.options = .all
    let logger = DLog(config: config) {
      Output {
        print($0)
        let pattern = #"{average:\#(SECS),count:\d+,duration:\#(SECS),max:\#(SECS),min:\#(SECS),total:\#(SECS)}$"#
        XCTAssert($0.description.match(pattern) == true)
      }
    }
    logger.interval("interval") {
      delay()
    }
  }
  
  func test_std() {
    let logger = DLog {
      Fork {
        StdOut
        StdErr
      }
    }
    let out = read_stdout { logger.trace() }
    XCTAssert(out?.match(#function) == true)
    
    let err = read_stderr { logger.trace() }
    XCTAssert(err?.match(#function) == true)
  }
  
  func test_file() {
    let filePath = "dlog.txt"
    
    do {
      // Recreate file
      let logger = DLog { File(path: filePath) }
      
      logger.trace()
      delay()
      var text = try String(contentsOfFile: filePath)
      XCTAssert(text.split(separator: "\n").count == 1)
      XCTAssert(text.match(#"\[TRACE\] \#(Location) \{func:\#(#function)"#))
      
      // Append
      let logger2 = DLog { File(path: filePath, append: true) }
      
      logger2.debug("debug")
      delay()
      text = try String(contentsOfFile: filePath)
      XCTAssert(text.split(separator: "\n").count == 2)
      XCTAssert(text.match(#"\[DEBUG\] \#(Location) debug$"#))
      
      logger2.interval("interval") { delay() }
      delay()
      text = try String(contentsOfFile: filePath)
      XCTAssert(text.split(separator: "\n").count == 3)
      XCTAssert(text.match(#"\[INTERVAL:interval\] \#(Location) \#(Interval)"#))
    }
    catch {
      XCTFail(error.localizedDescription)
    }
  }
  
  func test_oslog() {
    let logger = DLog { OSLog() }
    
    //let text = read_oslog_stream() {
      logger.trace()
      logger.scope("scope") { $0.debug("debug") }
      logger.interval("interval") { }
    //}
    //XCTAssert(text.match(#function) == true )
  }
  
  func test_output() {
    let isFork = true
    let isFilter = true
    let num = 1
    let isTrue: Bool? = true
    let isNil: Bool? = nil
    let logger = DLog {
      Pipe {
        // if
        if isFork {
          Fork {
            Filter { $0.type == .debug } // Doesn't apply to Output
            Output { print($0) }
          }
        }
        if let _ = isTrue {
          Output { print($0) }
        }
        if let _ = isNil {
          Output { XCTFail($0.description) }
        }
        
        // if-else
        if isFilter {
          Filter { $0.type == .debug }
          Output { XCTAssert($0.type == .debug) }
        }
        else {
          Output { XCTFail($0.description) }
        }
        
        // switch
        switch num {
          case 0:
            Output { XCTFail($0.description) }
          default:
            Output { XCTAssert($0.type == .debug) }
        }
      }
    }
    logger.trace()
    logger.info()
    logger.debug()
    logger.warning()
    logger.error()
    logger.assert(true)
    logger.fault()
    logger.scope("scope") { _ in }
    logger.interval("interval") { }
    delay()
  }
  
  func test() {
    let logger = DLog {
      OSLog(subsystem: "com.myapp.logger")
    }
    logger.debug("message")
  }
}
