import Foundation
import XCTest
import DLog
import Network
/*@testable*/ import DLog


// MARK: - Extensions

#if swift(>=6.0)
extension String: @retroactive Error {}
extension String: @retroactive LocalizedError {
  public var errorDescription: String? { return self }
}
#else
extension String: Error {}
extension String: LocalizedError {
  public var errorDescription: String? { return self }
}
#endif

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
fileprivate func readStream(file: Int32, stream: UnsafeMutablePointer<FILE>, block: () -> Void) -> String? {
  let buffer = AtomicArray([String]())
  
  // Set pipe
  let pipe = Pipe()
  let original = dup(file);
  setvbuf(stream, nil, _IONBF, 0)
  dup2(pipe.fileHandleForWriting.fileDescriptor, file)
  
  pipe.fileHandleForReading.readabilityHandler = { handle in
    if let text = String(data: handle.availableData, encoding: .utf8) {
      buffer.append(text)
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


// Patterns

let Sign = #"•"#
let Time = #"\d{2}:\d{2}:\d{2}\.\d{3}"#
let Level = #"\[\d{2}\]"#

let CategoryTag = #"\[DLOG\]"#

let LogTag = #"\[LOG\]"#
let TraceTag = #"\[TRACE\]"#
let DebugTag = #"\[DEBUG\]"#
let InfoTag = #"\[INFO\]"#
let WarningTag = #"\[WARNING\]"#
let ErrorTag = #"\[ERROR\]"#
let AssertTag = #"\[ASSERT\]"#
let FaultTag = #"\[FAULT\]"#

let IntervalTag = #"\[INTERVAL\]"#

let Location = "<DLogTests.swift:[0-9]+>"
let SECS = #"[0-9]+\.[0-9]{3}s"#
let Interval = #"\{average:\#(SECS),duration:\#(SECS)\}"#

let Empty = ">$"

fileprivate struct TestLog {
  let item: LogItem?
  let type: LogType
}

fileprivate func log_all(_ log: Log, message: LogMessage) -> [TestLog] {
  return [
    TestLog(item: log.log(message), type: .log),
    TestLog(item: log.log("\(message)"), type: .log),
    
    TestLog(item: log.trace(message), type: .trace),
    TestLog(item: log.trace("\(message)"), type: .trace),
    
    TestLog(item: log.debug(message), type: .debug),
    TestLog(item: log.debug("\(message)"), type: .debug),
    
    TestLog(item: log.info(message), type: .info),
    TestLog(item: log.info("\(message)"), type: .info),
    
    TestLog(item: log.warning(message), type: .warning),
    TestLog(item: log.warning("\(message)"), type: .warning),
    
    TestLog(item: log.error(message), type: .error),
    TestLog(item: log.error("\(message)"), type: .error),
    
    TestLog(item: log.assert(false, message), type: .assert),
    TestLog(item: log.assert(false, "\(message)"), type: .assert),
    
    TestLog(item: log.fault(message), type: .fault),
    TestLog(item: log.fault("\(message)"), type: .fault),
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
      XCTAssert($0.item == nil)
    }
    
    XCTAssert(logger.scope("scope") == nil)
    XCTAssert(logger.interval("interval") == nil)
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
    let log = DLog()
    
    let i = 10
    let f = 1.1
    let b = true
    let item = log.log("Hello", i, f, b)
    XCTAssert(item?.message == "Hello 10 1.1 true")
  }
  
  func test_trace() {
    var config = LogConfig()
    config.traceConfig.options = .all
    config.traceConfig.threadConfig.options = []
    config.traceConfig.style = .pretty
    let log = DLog(config: config)
    
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
  
  func test_logAll() {
    let log = DLog(metadata: ["a" : 10])
    log.metadata["a"] = 20
    log.metadata["b"] = "20"
       
    log_all(log, message: "log").forEach {
      XCTAssert($0.item!.time <= Date())
      XCTAssert($0.item?.category == "DLOG")
      XCTAssert($0.item?.stack == nil)
      XCTAssert($0.item?.type == $0.type)
      
      XCTAssert($0.item?.location.fileID.string == "DLogTests/DLogTests.swift")
      XCTAssert($0.item?.location.file.string == "DLogTests/DLogTests.swift")
      XCTAssert($0.item?.location.function.string == "log_all(_:message:)")
      XCTAssert($0.item!.location.line < #line)
      XCTAssert($0.item?.location.moduleName == "DLogTests")
      XCTAssert($0.item?.location.fileName == "DLogTests.swift")
      
      XCTAssert($0.item?.metadata.count == 2)
      XCTAssert($0.item?.metadata["a"] as? Int == 20)
      XCTAssert($0.item?.metadata["b"] as? String == "20")
      
      XCTAssert($0.item?.message == "log")
    }
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
  
  func test_file() {
    let filePath = "dlog.txt"
    
    do {
      // Recreate file
      let logger = DLog { File(path: filePath) }
      
      logger.trace()
      delay()
      var text = try String(contentsOfFile: filePath)
      XCTAssert(text.split(separator: "\n").count == 1)
      XCTAssert(text.match(#"\#(TraceTag) \#(Location) \{func:\#(#function)"#))
      
      // Append
      let logger2 = DLog { File(path: filePath, append: true) }
      
      logger2.debug("debug")
      delay()
      text = try String(contentsOfFile: filePath)
      XCTAssert(text.split(separator: "\n").count == 2)
      XCTAssert(text.match(#"\#(DebugTag) \#(Location) debug$"#))
      
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
  
  func test_pipe_fork_filter() {
    let logger = DLog {
      Pipe {
        Fork {
          Filter { $0.type == .debug } // Doesn't apply
          StdOut
        }
        Filter { $0.type == .debug }
        Filter {
          XCTAssert($0.type == .debug)
          return true
        }
        StdOut
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

/*
fileprivate func testAll(_ logger: Log, categoryTag: String = CategoryTag, metadata: String = "") {
  let padding = #"[\|\├\s]+"#
  
  XCTAssert(logger.log("log")?.match(#"\#(categoryTag)\#(padding)\#(LogTag) \#(Location)\#(metadata) log"#) == true)
  
  XCTAssert(logger.trace()?.match(#"\#(categoryTag)\#(padding)\#(TraceTag) \#(Location)\#(metadata) \{func:testAll,thread:\{name:main,number:1\}"#) == true)
  XCTAssert(logger.trace("start")?.match(#"\#(categoryTag)\#(padding)\#(TraceTag) \#(Location)\#(metadata) \{func:testAll,thread:\{name:main,number:1\}\} start"#) == true)
  
  XCTAssert(logger.debug("debug")?.match(#"\#(categoryTag)\#(padding)\#(DebugTag) \#(Location)\#(metadata) debug"#) == true)
  
  XCTAssert(logger.info("info")?.match(#"\#(categoryTag)\#(padding)\#(InfoTag) \#(Location)\#(metadata) info"#) == true)
  
  XCTAssert(logger.warning("warning")?.match(#"\#(categoryTag)\#(padding)\#(WarningTag) \#(Location)\#(metadata) warning"#) == true)
  XCTAssert(logger.error("error")?.match(#"\#(categoryTag)\#(padding)\#(ErrorTag) \#(Location)\#(metadata) error"#) == true)
  
  XCTAssertNil(logger.assert(true))
  XCTAssertNil(logger.assert(true, "assert"))
  XCTAssert(logger.assert(false)?.match(#"\#(categoryTag)\#(padding)\#(AssertTag) \#(Location)\#(metadata)"#) == true)
  XCTAssert(logger.assert(false, "assert")?.match(#"\#(categoryTag)\#(padding)\#(AssertTag) \#(Location)\#(metadata) assert"#) == true)
  
  XCTAssert(logger.fault("fault")?.match(#"\#(categoryTag)\#(padding)\#(FaultTag) \#(Location)\#(metadata) fault"#) == true)
  
  XCTAssert(read_stdout { logger.scope("scope") { _ in delay() } }?.match(#"\#(categoryTag)\#(padding)└ \[scope\] \(\#(SECS)\)"#) == true)
  XCTAssert(read_stdout { logger.interval("signpost") { delay() } }?.match(#"\#(categoryTag)\#(padding)\[INTERVAL\] \#(Location)\#(metadata) \#(Interval) signpost$"#) == true)
}
 
final class DLogTests: XCTestCase {
  
  // MARK: Tests -
  
  func test_Log() {
    let logger = DLog()
    testAll(logger)
  }
  
  // MARK: - Category
  
  func test_Category() {
    let logger = DLog()
    let netLogger = logger["NET"]
    
    testAll(netLogger, categoryTag: #"\[NET\]"#)
  }
  
  // MARK: - Text
  
  func test_textEmoji() {
    let logger = DLog(.textEmoji => .stdout)
    
    XCTAssert(logger.log("log")?.match(#"\#(CategoryTag) 💬 \#(LogTag) \#(Location) log"#) == true)
    
    XCTAssert(logger.trace()?.match(#"\#(CategoryTag) #️⃣ \#(TraceTag) \#(Location) \{func:\#(#function)"#) == true)
    XCTAssert(logger.debug("debug")?.match(#"\#(CategoryTag) ▶️ \#(DebugTag) \#(Location) debug"#) == true)
    
    XCTAssert(logger.info("info")?.match(#"\#(CategoryTag) ✅ \#(InfoTag) \#(Location) info"#) == true)
    
    XCTAssert(logger.warning("warning")?.match(#"\#(CategoryTag) ⚠️ \#(WarningTag) \#(Location) warning"#) == true)
    XCTAssert(logger.error("error")?.match(#"\#(CategoryTag) ⚠️ \#(ErrorTag) \#(Location) error"#) == true)
    
    XCTAssertNil(logger.assert(true))
    XCTAssert(logger.assert(false)?.match(#"\#(CategoryTag) 🅰️ \#(AssertTag) \#(Location)"#) == true)
    XCTAssert(logger.fault("fault")?.match(#"\#(CategoryTag) 🆘 \#(FaultTag) \#(Location) fault"#) == true)
    
    XCTAssert(read_stdout { logger.scope("My Scope") { _ in } }?.match(#"\[My Scope\]"#) == true)
    XCTAssert(read_stdout { logger.interval("My Interval") {} }?.match(#"🕒 \[INTERVAL\]"#) == true)
  }
  
  func test_textColored() {
    var config = LogConfig()
    config.options = .all
    let logger = DLog(.textColored => .stdout, config: config)
    
    let reset = "\u{001b}[0m"
    XCTAssert(logger.trace()?.contains(reset) == true)
    XCTAssert(logger.info("info")?.contains(reset) == true)
    XCTAssert(logger.debug("debug")?.contains(reset) == true)
    XCTAssert(logger.error("error")?.contains(reset) == true)
    XCTAssert(logger.assert(false, "assert")?.contains(reset) == true)
    XCTAssert(logger.fault("fault")?.contains(reset) == true)
    
    XCTAssert(read_stdout { logger.scope("scope") { _ in } }?.contains(reset) == true)
    XCTAssert(read_stdout { logger.interval("interval") {} }?.contains(reset) == true)
  }
  
  // MARK: - Standard
  
  func test_stdout_err() {
    let logOut = DLog(.stdout)
    XCTAssert(read_stdout { logOut.trace() }?.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) \{func:\#(#function)"#) == true)
    
    let logErr = DLog(.stderr)
    XCTAssert(read_stderr { logErr.trace() }?.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) \{func:\#(#function)"#) == true)
  }
  
  // MARK: - File
  
  func test_File() {
    let filePath = "dlog.txt"
    
    do {
      // Recreate file
      let logger = DLog(.textPlain => .file(filePath, append: false))
      logger.trace()
      delay(0.1)
      var text = try String(contentsOfFile: filePath)
      XCTAssert(text.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) \{func:\#(#function)"#))
      
      // Append
      let logger2 = DLog(.textPlain => .file(filePath, append: true))
      logger2.debug("debug")
      delay(0.1)
      text = try String(contentsOfFile: filePath)
      XCTAssert(text.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) \{func:\#(#function)"#))
      XCTAssert(text.match(#"\#(CategoryTag) \#(DebugTag) \#(Location) debug$"#))
    }
    catch {
      XCTFail(error.localizedDescription)
    }
  }
  
  // MARK: - OSLog
  
  func test_oslog() {
    let logger = DLog(.oslog)
    XCTAssertNotNil(logger.debug("debug"))
    logger.interval("signpost") {
      logger.debug("signpost")
    }
    
    
    let log2 = DLog(.oslog("com.dlog.test"))
    XCTAssertNotNil(log2.debug("debug"))
  }
  
  // MARK: - Net
#if !os(watchOS)
  func test_net() {
    let logger = DLog(.net)
    XCTAssertNotNil(logger.debug("oslog"))
    
    logger.scope("hello") { scope in
      scope.log("log")
      scope.debug("debug")
      scope.trace()
      scope.warning("warning")
      scope.error("error")
      scope.assert(false, "assert")
      scope.fault("fatal")
      scope.interval("interval") {
        delay()
      }
    }
    
    //		wait { exp in
    //		}
    
    let log2 = DLog(.net("MyName"))
    XCTAssertNotNil(log2.debug("oslog"))
  }
#endif
  
  // MARK: - Filter
  
  func test_Filter() {
    // Time
    let timeLogger = DLog(.textPlain => .filter(item: { $0.time < Date() }) => .stdout)
    XCTAssertNotNil(timeLogger.info("info"))
    
    // Category
    let categoryLogger = DLog(.textPlain => .filter { $0.category == "NET" } => .stdout)
    XCTAssertNil(categoryLogger.info("info"))
    let netLogger = categoryLogger["NET"]
    XCTAssertNotNil(netLogger.info("info"))
    
    // Type
    let typeLogger = DLog(.textPlain => .filter { $0.type == .debug } => .stdout)
    XCTAssertNil(typeLogger.trace())
    XCTAssertNil(typeLogger.info("info"))
    XCTAssertNotNil(typeLogger.debug("debug"))
    
    // File name
    let fileLogger = DLog(.textPlain => .filter { $0.location.fileName == "DLogTests.swift" } => .stdout)
    XCTAssertNotNil(fileLogger.info("info"))
    
    // Func name
    let funcLogger = DLog(.textPlain => .filter { $0.location.function == "test_Filter()" } => .stdout)
    XCTAssertNotNil(funcLogger.info("info"))
    
    // Line
    let lineLogger = DLog(.textPlain => .filter { $0.location.line > #line } => .stdout)
    XCTAssertNotNil(lineLogger.info("info"))
    
    // Text
    let textLogger = DLog(.textPlain => .filter { $0.message.contains("hello") } => .stdout)
    XCTAssertNotNil(textLogger.info("hello world"))
    XCTAssertNotNil(textLogger.debug("hello"))
    XCTAssertNil(textLogger.info("info"))
    XCTAssertNil(read_stdout { textLogger.interval("interval") { delay(0.3) } })
    XCTAssertNotNil(read_stdout { textLogger.interval("hello interval") { Thread.sleep(forTimeInterval: 0.3) } })
    
    // Scope
    let scopeLogger = DLog(.textPlain => .filter { $0.name == "scope" } => .stdout)
    XCTAssertNil(read_stdout { scopeLogger.scope("load") { _ in } })
    XCTAssertNotNil(read_stdout { scopeLogger.scope("load") { $0.log("load") } })
    XCTAssertNotNil(read_stdout { scopeLogger.scope("scope") { $0.log("scope") } })
    
    // Item & Scope
    let filter = Filter(isItem: { $0.scope?.name == "Load" }, isScope: { $0.name == "Load" })
    let itemScopeLogger = DLog(.textPlain => filter => .stdout)
    XCTAssertNil(itemScopeLogger.info("info"))
    XCTAssertNotNil(read_stdout {
      itemScopeLogger.scope("Load") { scope in
        XCTAssertNotNil(scope.debug("load"))
        XCTAssertNotNil(scope.error("load"))
        XCTAssertNil(read_stdout {
          scope.scope("Parse") { scope in
            XCTAssertNil(scope.debug("parse"))
            XCTAssertNil(scope.error("parse"))
          }
        })
      }
    })
    XCTAssertNil(itemScopeLogger.fault("fault"))
    
    // Metadata
    let metadataLogger = DLog(.textPlain
                              => .filter { (item: LogItem) in item.metadata.first?["id"] as? Int == 12345 }
                              => .stdout)
    metadataLogger.metadata["id"] = 12
    XCTAssertNil(metadataLogger.log("load"))
    metadataLogger.metadata["id"] = 12345
    XCTAssertNotNil(metadataLogger.log("load"))
    metadataLogger.metadata.clear()
    XCTAssertNil(metadataLogger.log("load"))
  }
  
  // MARK: - Disabled
  
  func test_Disabled() {
    
    let failBool: () -> Bool = {
      XCTFail()
      return false
    }
    
    let failMessage: () -> LogMessage = {
      XCTFail()
      return ""
    }
    
    let test: (Log, XCTestExpectation) -> Void = { logger, expectation in
      logger.log(failMessage())
      logger.trace(failMessage())
      logger.debug("\(failMessage())")
      logger.info(failMessage())
      logger.warning(failMessage())
      logger.error(failMessage())
      logger.fault(failMessage())
      logger.assert(failBool(), failMessage())
      logger.scope("scope") { _ in expectation.fulfill() }
      logger.interval("interval") { expectation.fulfill() }
    }
    
    let logger = DLog.disabled
    let scope = logger.scope("scope")
    let netLogger = logger["NET"]
    
    wait { expectation in
      expectation.expectedFulfillmentCount = 6
      
      XCTAssertNil(
        read_stdout {
          test(logger, expectation)
          test(netLogger, expectation)
          test(scope, expectation)
        }
      )
    }
  }
  
  // MARK: - Thread safe
  // categories, scopes, interavls
  
  func test_NonBlock() {
    let logger = DLog(.textPlain
                      => .stdout
                      => .file("dlog.txt")
                      => .oslog
                      => .filter { $0.type == .debug }
    )
    
    let netLogger = logger["NET"]
    netLogger.log("log")
    netLogger.trace()
    netLogger.debug("debug")
    netLogger.info("info")
    netLogger.warning("warning")
    netLogger.error("error")
    netLogger.assert(false)
    netLogger.fault("fault")
    netLogger.scope("scope") { _ in }
    netLogger.interval("signpost") {  }
    
    let scope = logger.scope("test") { scope in
      scope.log("log")
      scope.trace()
      scope.debug("debug")
      scope.info("info")
      scope.warning("warning")
      scope.error("error")
      scope.assert(false)
      scope.fault("fault")
      scope.scope("scope") { _ in }
      scope.interval("signpost") {  }
    }
    
    XCTAssert(scope.duration < 0.2)
  }
  
  // MARK: - Config
  
  func test_ConfigEmpty() {
    var config = LogConfig()
    config.options = []
    
    let logger = DLog(config: config)
    
    XCTAssert(logger.trace("trace") == "trace")
    
    logger.scope("scope") {
      XCTAssert($0.trace("trace") == "trace")
    }
  }
  
  func test_ConfigAll() {
    var config = LogConfig()
    config.options = .all
    
    let logger = DLog(config: config)
    
    XCTAssert(logger.trace()?.match(#"\#(Sign) \#(Time) \#(Level) \#(CategoryTag) \#(TraceTag) \#(Location) \{func:test_ConfigAll,thread:\{name:main,number:1\}\}$"#) == true)
  }
  
  func test_ConfigCategory() {
    let logger = DLog()
    
    let viewLogger = logger["VIEW"]
    
    var config = LogConfig()
    config.sign = ">"
    config.options = [.sign, .time, .category, .type, .level]
    config.traceConfig.options = .queue
    config.intervalConfig.options = .total
    
    let netLogger = logger.category(name: "NET", config: config)
    
    // Trace
    XCTAssert(logger.trace()?.match(#"\#(Sign) \#(Time) \#(CategoryTag) \#(TraceTag) \#(Location) \{func:test_ConfigCategory,thread:\{name:main,number:1\}\}$"#) == true)
    XCTAssert(viewLogger.trace()?.match(#"\#(Sign) \#(Time) \[VIEW\] \#(TraceTag) \#(Location) \{func:test_ConfigCategory,thread:\{name:main,number:1\}\}$"#) == true)
    XCTAssert(netLogger.trace()?.match(#"> \#(Time) \#(Level) \[NET\] \#(TraceTag)$"#) == true) // No metadata
    
    // Interval
    XCTAssert(read_stdout { logger.interval("signpost") { delay() }}?.match(#"\#(Sign) \#(Time) \#(CategoryTag) \#(IntervalTag) \#(Location) \#(Interval) signpost$"#) == true)
    XCTAssert(read_stdout { viewLogger.interval("signpost") { delay() }}?.match(#"\#(Sign) \#(Time) \[VIEW\] \#(IntervalTag) \#(Location) \#(Interval) signpost$"#) == true)
    XCTAssert(read_stdout { netLogger.interval("signpost") { delay() }}?.match(#"> \#(Time) \#(Level) \[NET\] \#(IntervalTag) signpost$"#) == true) // No metadata
  }
}

final class MetadataTests: XCTestCase {
  
  let idText = #"\{id:12345\}"#
  let nameText = #"\{name:Bob\}"#
  let idNameText = #"\{id:12345,name:Bob\}"#
  
  func test_metadata() {
    let logger = DLog()
    logger.metadata["id"] = 12345
    testAll(logger, metadata: #" \#(idText)"#)
    
    logger.metadata["id"] = nil
    testAll(logger)
    
    logger.metadata["id"] = 12345
    logger.metadata["name"] = "Bob"
    testAll(logger, metadata: #" \#(idNameText)"#)
    
    logger.metadata.clear()
    testAll(logger)
  }
  
  func test_metadata_category() {
    let logger = DLog(metadata: ["id" : 12345])
    XCTAssert(logger.metadata["id"] as? Int == 12345)
    XCTAssert(logger.log("log")?.match(idText) == true)
    
    // Category with inherited metadata
    let net = logger["NET"]
    XCTAssert(net.log("log")?.match(idText) == true)
    net.metadata["name"] = "Bob"
    XCTAssert(net.log("log")?.match(idNameText) == true)
    net.metadata.clear()
    XCTAssert(net.log("log")?.match(idNameText) == false)
    
    XCTAssert(logger.log("log")?.match(idText) == true)
    
    // Category with own metadata
    let ui = logger.category(name: "UI", metadata: ["name" : "Bob"])
    XCTAssert(ui.log("log")?.match(nameText) == true)
    ui.metadata.clear()
    XCTAssert(ui.log("log")?.match(idText) == false)
    
    XCTAssert(logger.log("log")?.match(idText) == true)
  }
  
  func test_metadata_scope() {
    let logger = DLog()
    logger.metadata["id"] = 12345
    XCTAssert(logger.log("log")?.match(idText) == true)
    
    // Scope with inherited metadata
    logger.scope("scope") { scope in
      XCTAssert(scope.log("log")?.match(self.idText) == true)
      scope.metadata["name"] = "Bob"
      XCTAssert(scope.log("log")?.match(self.idNameText) == true)
      scope.metadata.clear()
      XCTAssert(scope.log("log")?.match(self.idNameText) == false)
    }
    
    XCTAssert(logger.log("log")?.match(idText) == true)
    
    // Scope with own metadata
    logger.scope("scope", metadata: ["name" : "Bob"]) { scope in
      XCTAssert(scope.log("log")?.match(self.nameText) == true)
      scope.metadata.clear()
      XCTAssert(scope.log("log")?.match(self.nameText) == false)
    }
    
    XCTAssert(logger.log("log")?.match(idText) == true)
  }
  
  func test_metadata_config() {
    var config = LogConfig()
    config.options = [.compact]
    let logger = DLog(config: config)
    
    logger.metadata["id"] = 12345
    XCTAssert(logger.log("log")?.match(idText) == false)
  }
}

final class FormatTests: XCTestCase {
  
  func test_literals() {
    let logger = DLog()
    
    XCTAssert(logger.log(1)?.match("1$") == true) // int
    XCTAssert(logger.log(2.0)?.match("2.0$") == true) // float
    XCTAssert(logger.log(true)?.match("true$") == true) // bool
    XCTAssert(logger.log("text")?.match("text$") == true) // string
    XCTAssert(logger.log([1, "2", 3.0])?.match("\\[1, \"2\", 3.0\\]$") == true) // array
    XCTAssert(logger.log([1 : 1, "2" : "2", 3 : 3.0])?.match("\\[\\(1, 1\\), \\(\"2\", \"2\"\\), \\(3, 3.0\\)\\]$") == true) // dictionary
  }
  
  func test_logMessage() {
    let logger = DLog()
    
    // Any
    let text: Any = "some text"
    XCTAssert(logger.debug("\(text)")?.match("some text") == true)
    
    // Error
    let error = NSError(domain: "domain", code: 100, userInfo: [NSLocalizedDescriptionKey : "error"])
    XCTAssert(logger.error("\(error)")?.match("Error Domain=domain Code=100 \"error\" UserInfo=\\{NSLocalizedDescription=error\\}") == true)
    XCTAssert(logger.error("\(error as Error)")?.match("Error Domain=domain Code=100 \"error\" UserInfo=\\{NSLocalizedDescription=error\\}") == true)
    XCTAssert(logger.error("\(error.localizedDescription)")?.match("error") == true)
    
    // Enum
    enum MyEnum { case one, two }
    let myEnum = MyEnum.one
    XCTAssert(logger.error("\(myEnum)")?.match("one") == true)
    XCTAssert(logger.error("\(MyEnum.one)")?.match("one") == true)
    
    // OptionSet
    XCTAssert(logger.error("\(NSCalendar.Options.matchLast)")?.match("NSCalendarOptions\\(rawValue: 8192\\)") == true)
    
    // Notification
    let notification = Notification.Name.NSCalendarDayChanged
    XCTAssert(logger.debug("\(notification.rawValue)")?.match("NSCalendarDayChanged") == true)
    
    // Array
    let array = [1, 2, 3]
    XCTAssert(logger.debug("\(array)")?.match("\\[1, 2, 3\\]") == true)
  }
}

final class IntervalTests: XCTestCase {
  
  func test_interval() {
    let logger = DLog()
    
    XCTAssert(read_stdout {
      logger.interval() { delay() }
    }?.match(#"\#(Interval)$"#) == true)
    
    XCTAssert(read_stdout {
      logger.interval("signpost") { delay() }
    }?.match(#"\#(Interval) signpost$"#) == true)
  }
  
  func test_IntervalBeginEnd() {
    let logger = DLog()
    
    XCTAssert(read_stdout {
      let interval = logger.interval("signpost")
      interval.begin()
      delay()
      interval.end()
    }?.match(#"\#(Interval) signpost$"#) == true)
    
    // Double begin/end
    XCTAssert(read_stdout {
      let interval = logger.interval("signpost")
      interval.begin()
      interval.begin()
      delay()
      interval.end()
      interval.end()
    }?.match(#"\#(Interval) signpost$"#) == true)
  }
  
  func test_IntervalStatistics() {
    let logger = DLog()
    
    let interval = logger.interval("Signpost") {
      delay()
    }
    let statistics1 = interval.statistics
    XCTAssert(statistics1.count == 1)
    XCTAssert(0.25 <= interval.duration)
    XCTAssert(0.25 <= statistics1.total)
    XCTAssert(0.25 <= statistics1.min)
    XCTAssert(0.25 <= statistics1.max)
    XCTAssert(0.25 <= statistics1.average)
    
    interval.begin()
    delay()
    interval.end()
    let statistics2 = interval.statistics
    XCTAssert(statistics2.count == 2)
    XCTAssert(0.25 <= interval.duration)
    XCTAssert(0.5 <= statistics2.total)
    XCTAssert(0.25 <= statistics2.min)
    XCTAssert(0.25 <= statistics2.max)
    XCTAssert(0.25 <= statistics2.average)
  }
  
  func test_IntervalConcurrent() {
    var config = LogConfig()
    config.intervalConfig.options = .all
    let logger = DLog(config: config)
    
    wait(count: 10) { expectations in
      for i in 0..<10 {
        DispatchQueue.global().async {
          let interval = logger.interval("signpost") {
            delay();
          }
          XCTAssert(interval.duration >= 0.25)
          expectations[i].fulfill()
        }
      }
    }
  }
  
  func test_IntervalNameEmpty() {
    let logger = DLog()
    
    XCTAssert(read_stdout {
      logger.interval("") {
        delay()
      }
    }?.match(#"\#(Interval)$"#) == true)
  }
  
  func test_intervalConfig_custom() {
    let logger = DLog()
    
    var config = IntervalConfig()
    config.options = .total
    
    XCTAssert(read_stdout {
      logger.interval("signpost", config: config) { delay() }
    }?.match(#"\{total:\#(SECS)\} signpost$"#) == true)
  }
  
  func test_IntervalConfigEmpty() {
    var config = LogConfig()
    config.intervalConfig.options = []
    
    let logger = DLog(config: config)
    
    XCTAssert(read_stdout {
      logger.interval("signpost") {
        delay()
      }
    }?.match(#"> signpost$"#) == true)
  }
  
  func test_Interval_Config_All() {
    var config = LogConfig()
    config.intervalConfig.options = .all
    
    let logger = DLog(config: config)
    
    XCTAssert(read_stdout {
      logger.interval("signpost") {
        delay()
      }
    }?.match(#"\{average:\#(SECS),count:[0-9]+,duration:\#(SECS),max:\#(SECS),min:\#(SECS),total:\#(SECS)\} signpost$"#) == true)
  }
}

final class ScopeTests: XCTestCase {
  
  func test_scope() {
    let logger = DLog()
    
    logger.scope("scope") {
      testAll($0)
    }
  }
  
  func test_scope_stack() {
    var config = LogConfig()
    config.options = .all
    
    let logger = DLog(config: config)
    
    XCTAssert(logger.debug("no scope")?.match(#"\[00\] \#(CategoryTag) \#(DebugTag) \#(Location) no scope"#) == true)
    
    logger.scope("scope1") { scope1 in
      XCTAssert(scope1.info("scope1 start")?.match(#"\[01\] \#(CategoryTag) ├ \#(InfoTag) \#(Location) scope1 start"#) == true)
      
      logger.scope("scope2") { scope2 in
        XCTAssert(scope2.debug("scope2 start")?.match(#"\[02\] \#(CategoryTag) │ ├ \#(DebugTag) \#(Location) scope2 start"#) == true)
        
        logger.scope("scope3") { scope3 in
          XCTAssert(scope3.error("scope3")?.match(#"\[03\] \#(CategoryTag) │ │ ├ \#(ErrorTag) \#(Location) scope3"#) == true)
        }
        
        XCTAssert(scope2.fault("scope2")?.match(#"\[02\] \#(CategoryTag) │ ├ \#(FaultTag) \#(Location) scope2"#) == true)
      }
      
      XCTAssert(scope1.trace("scope1 end")?.match(#"\[01\] \#(CategoryTag) ├ \#(TraceTag) \#(Location) \{func:test_scope_stack,thread:\{name:main,number:1\}\} scope1 end$"#) == true)
    }
    
    XCTAssert(logger.trace("no scope")?.match(#"\[00\] \#(CategoryTag) \#(TraceTag) \#(Location) \{func:test_scope_stack,thread:\{name:main,number:1\}\} no scope$"#) == true)
  }
  
  func test_scope_not_entered() {
    let logger = DLog()
    let scope1 = logger.scope("scope 1")
    XCTAssert(scope1.trace()?.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) \{func:\#(#function)"#) == true)
  }
  
  func test_scope_enter_leave() {
    let logger = DLog()
    
    let scope1 = logger.scope("scope 1")
    let scope2 = logger.scope("scope 2")
    let scope3 = logger.scope("scope 3")
    
    logger.trace("no scope")
    
    scope1.enter()
    XCTAssert(scope1.info("1")?.match(#"\#(CategoryTag) ├ \#(InfoTag) \#(Location) 1"#) == true)
    
    scope2.enter()
    XCTAssert(scope2.info("2")?.match(#"\#(CategoryTag) │ ├ \#(InfoTag) \#(Location) 2"#) == true)
    
    scope3.enter()
    XCTAssert(scope3.info("3")?.match(#"\#(CategoryTag) │ │ ├ \#(InfoTag) \#(Location) 3"#) == true)
    
    scope1.leave()
    XCTAssert(scope3.debug("3")?.match(#"\#(CategoryTag)   │ ├ \#(DebugTag) \#(Location) 3"#) == true)
    
    scope2.leave()
    XCTAssert(scope3.error("3")?.match(#"\#(CategoryTag)     ├ \#(ErrorTag) \#(Location) 3"#) == true)
    
    scope3.leave()
    XCTAssert(logger.fault("no scope")?.match(#"\#(CategoryTag) \#(FaultTag) \#(Location) no scope"#) == true)
  }
  
  func test_scope_double_enter() {
    let logger = DLog()
    
    let scope1 = logger.scope("My Scope")
    
    scope1.enter()
    scope1.enter()
    
    XCTAssert(scope1.trace()?.match(#"\#(CategoryTag) ├ \#(TraceTag) \#(Location) \{func:\#(#function)"#) == true)
    
    scope1.leave()
    scope1.leave()
    
    scope1.enter()
    XCTAssert(scope1.trace()?.match(#"\#(CategoryTag) ├ \#(TraceTag) \#(Location) \{func:\#(#function)"#) == true)
    scope1.leave()
    
    XCTAssert(logger.trace()?.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) \{func:\#(#function)"#) == true)
  }
  
  func test_scope_concurrent() {
    let logger = DLog()
    
    wait(count: 10) { expectations in
      for i in 1...10 {
        DispatchQueue.global().async {
          logger.scope("Scope \(i)") {
            $0.debug("scope \(i)")
            expectations[i-1].fulfill()
          }
        }
      }
    }
  }
  
  func test_scope_duration() {
    let logger = DLog()
    
    var scope = logger.scope("scope1") { _ in
      delay()
    }
    XCTAssert(0.25 <= scope.duration)
    
    scope = logger.scope("scope2")
    scope.enter()
    delay()
    scope.leave()
    XCTAssert(0.25 <= scope.duration)
  }
  
  func test_disabled_category() {
    let logger = DLog()
    let category = DLog.disabled
    
    category.scope("scope1") { scope1 in
      scope1.scope("scope2") { scope2 in
        logger.scope("scope3") { scope3 in
          XCTAssert(scope3.debug("log")?.match(#"\#(CategoryTag) ├ \#(DebugTag) \#(Location) log"#) == true)
        }
      }
    }
  }
}

final class TraceTests: XCTestCase {
  
  func test_trace() {
    let logger = DLog()
    XCTAssert(logger.trace()?.match(#"\{func:test_trace,thread:\{name:main,number:1\}\}$"#) == true)
    XCTAssert(logger.trace("trace")?.match(#"\{func:test_trace,thread:\{name:main,number:1\}\} trace$"#) == true)
  }
  
  func test_trace_process() {
    var config = LogConfig()
    config.traceConfig.options = .process
    let logger = DLog(config: config)
    XCTAssert(logger.trace()?.match(#"\{process:\{cpu:\d+%,memory:\d+MB,pid:\d+,threads:\d+\}\}"#) == true)
  }
  
  func test_trace_process_all() {
    var config = LogConfig()
    config.traceConfig.options = .process
    config.traceConfig.processConfig.options = .all
    
    let logger = DLog(config: config)
    XCTAssert(logger.trace()?.match(#"\{process:\{cpu:\d+%,guid:[^,]+,memory:\d+MB,name:[^,]+,pid:\d+,threads:\d+,wakeups:\{idle:\d+,interrupt:\d+,timer:\d+\}\}\}"#) == true)
  }
  
  func test_trace_func_only() {
    var config = LogConfig()
    config.traceConfig.options = .function
    let logger = DLog(config: config)
    XCTAssert(logger.trace()?.match(#"\{func:test_trace_func_only\}"#) == true)
  }
  
  @discardableResult
  func funcWithParams(_ logger: Log, a: Int, b: Int, c: Float) -> String? {
    logger.trace()
  }
  
  func test_trace_func_no_params() {
    var config = LogConfig()
    config.traceConfig.options = .function
    let logger = DLog(config: config)
    
    let result = funcWithParams(logger, a: 1, b: 2, c: 3)
    XCTAssert(result?.match(#"\{func:funcWithParams\}"#) == true)
  }
  
  func test_trace_func_params() {
    var config = LogConfig()
    config.traceConfig.options = .function
    config.traceConfig.funcConfig.params = true
    let logger = DLog(config: config)
    
    let result = funcWithParams(logger, a: 1, b: 2, c: 3)
    XCTAssert(result?.match(#"\{func:funcWithParams\(_:a:b:c:\)\}"#) == true)
  }
  
  func test_trace_queue_qos() {
    var config = LogConfig()
    config.traceConfig.options = [.queue, .thread]
    config.traceConfig.threadConfig.options = .qos
    let logger = DLog(config: config)
    
    
    XCTAssert(logger.trace()?.match(#"\{queue:com.apple.main-thread"#) == true)
    
    let queues: [(String, DispatchQueue)] = [
      ("com.apple.root.background-qos", DispatchQueue.global(qos: .background)),
      ("com.apple.root.utility-qos", DispatchQueue.global(qos: .utility)),
      ("com.apple.root.default-qos", DispatchQueue.global(qos: .default)),
      ("com.apple.root.user-initiated-qos", DispatchQueue.global(qos: .userInitiated)),
      ("com.apple.root.user-interactive-qos", DispatchQueue.global(qos: .userInteractive)),
      ("serial", DispatchQueue(label: "serial")),
      ("concurrent", DispatchQueue(label: "concurrent", attributes: .concurrent))
    ]
    wait(count: queues.count) { expectations in
      for (i , (label, queue)) in queues.enumerated() {
        queue.async {
          XCTAssert(logger.trace()?.match(label) == true)
          expectations[i].fulfill()
        }
      }
    }
  }
  
  func test_trace_thread_detach() {
    var config = LogConfig()
    config.traceConfig.options = .thread
    let logger = DLog(config: config)
    
    wait { expectation in
      Thread.detachNewThread {
        XCTAssert(logger.trace()?.match(#"\{thread:\{number:\d+\}\}$"#) == true)
        expectation.fulfill()
      }
    }
  }
  
  func test_trace_thread_all() {
    var config = LogConfig()
    config.traceConfig.options = .thread
    config.traceConfig.threadConfig.options = .all
    let logger = DLog(config: config)
    XCTAssert(logger.trace()?.match(#"\{thread:\{name:main,number:1,priority:0\.\d,qos:[^,]+,stackSize:\d+ KB\,tid:\d+\}\}$"#) == true)
  }
  
  func test_trace_thread_options_empty() {
    var config = LogConfig()
    config.traceConfig.options = .thread
    config.traceConfig.threadConfig.options = []
    let logger = DLog(config: config)
    XCTAssert(logger.trace()?.match(Empty) == true)
  }
  
  func test_trace_stack() {
    var config = LogConfig()
    config.traceConfig.options = .stack
    
    let logger = DLog(config: config)
    let text = logger.trace()
    XCTAssert(text?.match(#"\{stack:\[\{frame:0,symbol:DLogTests\.TraceTests\.test_trace_stack\(\) -> \(\)\}"#) == true)
  }
  
  func test_trace_stack_depth_all_pretty() {
    var config = LogConfig()
    config.traceConfig.options = .stack
    config.traceConfig.stackConfig.options = .all
    config.traceConfig.stackConfig.depth = 1
    config.traceConfig.style = .pretty
    
    let logger = DLog(config: config)
    let text = logger.trace()
    
    let format = #"""
        \{
          stack : \[
            \{
              address : 0x[0-9a-f]+,
              frame : 0,
              module : DLog[^,]+,
              offset : \d+,
              symbol : DLogTests\.TraceTests\.test_trace_stack_depth_all_pretty\(\) -> \(\)
            \}
          \]
        \}
        """#
    XCTAssert(text?.match(format) == true)
  }
  
  func test_trace_custom_config() {
    let logger = DLog()
    
    var config = TraceConfig()
    config.options = .function
    
    XCTAssert(logger.trace(config: config)?.match(#"\{func:test_trace_custom_config\}$"#) == true)
  }
  
  func test_trace_config_empty() {
    var config = LogConfig()
    config.traceConfig.options = []
    let logger = DLog(config: config)
    XCTAssert(logger.trace()?.match(Empty) == true)
  }
  
  func test_trace_config_all() {
    var config = LogConfig()
    config.traceConfig.options = .all
    config.traceConfig.stackConfig.view = .all
    let logger = DLog(config: config)
    let text = logger.trace()
    XCTAssert(text?.match(#"\#(Location) \{func:test_trace_config_all,process:\{cpu:\d+%,memory:\d+MB,pid:\d+,threads:\d+\},queue:com\.apple\.main-thread,stack:\[\{frame:\d+,symbol:DLogTests\.TraceTests\.test_trace_config_all\(\) -> \(\)\}"#) == true)
  }
}
*/
