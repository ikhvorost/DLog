import Foundation
import XCTest
import DLog
//@testable import DLog

// MARK: - Extensions

/// String errors
extension String : LocalizedError {
	public var errorDescription: String? { return self }
}

extension String {
    func match(_ pattern: String) -> Bool {
		self.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

extension DispatchSemaphore {
	static func Lock() -> DispatchSemaphore {
		return DispatchSemaphore(value: 0)
	}
	
	static func Mutex() -> DispatchSemaphore {
		return DispatchSemaphore(value: 1)
	}
}

extension XCTestCase {

	func wait(count: UInt, timeout: TimeInterval = 1, repeat r: UInt = 1, name: String = #function, closure: ([XCTestExpectation]) -> Void) {
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

func delay(_ sec: Double = 0.25) {
	Thread.sleep(forTimeInterval: sec)
}

func asyncAfter(_ sec: Double = 0.25, closure: @escaping (() -> Void) ) {
	DispatchQueue.global().asyncAfter(deadline: .now() + sec, execute: closure)
}

/// Get text standard output
func readStream(file: Int32, stream: UnsafeMutablePointer<FILE>, block: () -> Void) -> String? {
	var result: String?
	
    // Set pipe
	let pipe = Pipe()
    let original = dup(file);
    setvbuf(stream, nil, _IONBF, 0)
    dup2(pipe.fileHandleForWriting.fileDescriptor, file)
	
    pipe.fileHandleForReading.readabilityHandler = { handle in
		if let text = String(data: handle.availableData, encoding: .utf8) {
			result = (result != nil) ? (result! + text) : text
		}
    }
    
    block()
	
	delay()
	
	// Revert
	fflush(stream)
	dup2(original, file)
	close(original)
	
	// Print
	print(result ?? "", terminator: "")
    
	return result
}

func read_stdout(_ block: () -> Void) -> String? {
	readStream(file: STDOUT_FILENO, stream: stdout, block: block)
}

func read_stderr(_ block: () -> Void) -> String? {
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

let Location = "<DLogTests:[0-9]+>"
let SECS = #"[0-9]+\.[0-9]{3}"#
let Interval = #"\{ duration: \#(SECS), average: \#(SECS) \}"#

fileprivate func testAll(_ logger: LogProtocol, categoryTag: String = CategoryTag) {
	let padding = #"[\|\s]+"#
	
	XCTAssert(logger.log("log")?.match(#"\#(categoryTag)\#(padding)\#(LogTag) \#(Location) log"#) == true)
	
	XCTAssert(logger.trace()?.match(#"\#(categoryTag)\#(padding)\#(TraceTag) \#(Location) func: testAll\(_:categoryTag:\), thread: \{ number: 1, name: main \}"#) == true)
	XCTAssert(logger.trace("start")?.match(#"\#(categoryTag)\#(padding)\#(TraceTag) \#(Location) start: \{ func: testAll\(_:categoryTag:\), thread: \{ number: 1, name: main \} \}"#) == true)
	
	XCTAssert(logger.debug("debug")?.match(#"\#(categoryTag)\#(padding)\#(DebugTag) \#(Location) debug"#) == true)
	
	XCTAssert(logger.info("info")?.match(#"\#(categoryTag)\#(padding)\#(InfoTag) \#(Location) info"#) == true)
	
	XCTAssert(logger.warning("warning")?.match(#"\#(categoryTag)\#(padding)\#(WarningTag) \#(Location) warning"#) == true)
	XCTAssert(logger.error("error")?.match(#"\#(categoryTag)\#(padding)\#(ErrorTag) \#(Location) error"#) == true)
	
	XCTAssertNil(logger.assert(true, "assert"))
	XCTAssert(logger.assert(false)?.match(#"\#(categoryTag)\#(padding)\#(AssertTag) \#(Location)"#) == true)
	XCTAssert(logger.assert(false, "assert")?.match(#"\#(categoryTag)\#(padding)\#(AssertTag) \#(Location) assert"#) == true)
	XCTAssert(logger.fault("fault")?.match(#"\#(categoryTag)\#(padding)\#(FaultTag) \#(Location) fault"#) == true)
	
	XCTAssert(read_stdout { logger.scope("scope") { _ in delay() } }?.match(#"\#(categoryTag)\#(padding)└ \[scope\] \(0\.[0-9]{3}\)"#) == true)
	XCTAssert(read_stdout { logger.interval("signpost") { delay() } }?.match(#"\#(categoryTag)\#(padding)\[INTERVAL\] \#(Location) signpost: \#(Interval)"#) == true)
}

final class DLogTests: XCTestCase {
	
	// MARK: Tests -
	
	func test_Log() {
		let log = DLog()
		testAll(log)
	}
	
	// MARK: - Category
	
	func test_Category() {
		let log = DLog()
		let netLog = log["NET"]
		
		testAll(netLog, categoryTag: #"\[NET\]"#)
	}
	
	// MARK: - Text
	
	func test_textPlain() {
		let log = DLog()
		
		testAll(log)
	}
	
	func test_textEmoji() {
		let log = DLog(.textEmoji => .stdout)
		
		XCTAssert(log.log("log")?.match(#"\#(CategoryTag) 💬 \#(LogTag) \#(Location) log"#) == true)
		
		XCTAssert(log.trace()?.match(#"\#(CategoryTag) #️⃣ \#(TraceTag) \#(Location) func: \#(#function)"#) == true)
		XCTAssert(log.debug("debug")?.match(#"\#(CategoryTag) ▶️ \#(DebugTag) \#(Location) debug"#) == true)
		
		XCTAssert(log.info("info")?.match(#"\#(CategoryTag) ✅ \#(InfoTag) \#(Location) info"#) == true)
		
		XCTAssert(log.warning("warning")?.match(#"\#(CategoryTag) ⚠️ \#(WarningTag) \#(Location) warning"#) == true)
		XCTAssert(log.error("error")?.match(#"\#(CategoryTag) ⚠️ \#(ErrorTag) \#(Location) error"#) == true)
		
		XCTAssert(log.assert(false)?.match(#"\#(CategoryTag) 🅰️ \#(AssertTag) \#(Location)"#) == true)
		XCTAssert(log.fault("fault")?.match(#"\#(CategoryTag) 🆘 \#(FaultTag) \#(Location) fault"#) == true)
		
		XCTAssert(read_stdout { log.scope("My Scope") { _ in } }?.match(#"\[My Scope\]"#) == true)
		XCTAssert(read_stdout { log.interval("My Interval") {} }?.match(#"🕒 \[INTERVAL\]"#) == true)
	}
	
	func test_textColored() {
		var config = DLog.defaultConfiguration
		config.options = .all
		let log = DLog(.textColored => .stdout, configuration: config)
		
		let reset = "\u{001b}[0m"
		XCTAssert(log.trace()?.contains(reset) == true)
		XCTAssert(log.info("info")?.contains(reset) == true)
		XCTAssert(log.debug("debug")?.contains(reset) == true)
		XCTAssert(log.error("error")?.contains(reset) == true)
		XCTAssert(log.assert(false, "assert")?.contains(reset) == true)
		XCTAssert(log.fault("fault")?.contains(reset) == true)
		
		XCTAssert(read_stdout { log.scope("scope") { _ in } }?.contains(reset) == true)
		XCTAssert(read_stdout { log.interval("interval") {} }?.contains(reset) == true)
	}
	
	// MARK: - Standard
	
	func test_stdOutErr() {
		let logOut = DLog(.stdout)
		XCTAssert(read_stdout { logOut.trace() }?.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) func: \#(#function)"#) == true)
		
		let logErr = DLog(.stderr)
		XCTAssert(read_stderr { logErr.trace() }?.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) func: \#(#function)"#) == true)
	}
	
	// MARK: - File
	
	func test_File() {
		let filePath = "dlog.txt"
		let log = DLog(.textPlain => .file(filePath, append: true))
		log.trace()
		
		delay(0.1)
		
		do {
			let text = try String(contentsOfFile: filePath)
			print(text)
			XCTAssert(text.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) func: \#(#function)"#))
		}
		catch {
			XCTFail(error.localizedDescription)
		}
	}
	
	// MARK: - OSLog
	
	func test_oslog() {
		let log = DLog(.oslog)
		XCTAssertNotNil(log.debug("oslog"))
		
		let log2 = DLog(.oslog("com.dlog.test"))
		XCTAssertNotNil(log2.debug("oslog"))
	}
	
	// MARK: - Net
	
	func test_net() {
		let log = DLog(.net)
		XCTAssertNotNil(log.debug("oslog"))
		
		log.scope("hello") { scope in
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
	
	// MARK: - Filter
	
	func test_Filter() {
		// Time
		let timeLog = DLog(.textPlain => .filter { $0.time < Date() } => .stdout)
		XCTAssertNotNil(timeLog.info("info"))
		
		// Category
		let categoryLog = DLog(.textPlain => .filter { $0.category == "NET" } => .stdout)
		XCTAssertNil(categoryLog.info("info"))
		let netLog = categoryLog["NET"]
		XCTAssertNotNil(netLog.info("info"))
		
		// Type
		let typeLog = DLog(.textPlain => .filter { $0.type == .debug } => .stdout)
		XCTAssertNil(typeLog.trace())
		XCTAssertNil(typeLog.info("info"))
		XCTAssertNotNil(typeLog.debug("debug"))
		XCTAssertNil(read_stdout { typeLog.scope("scope") { _ in } })
		
		// File name
		let fileLog = DLog(.textPlain => .filter { $0.fileName == "DLogTests" } => .stdout)
		XCTAssertNotNil(fileLog.info("info"))
		
		// Func name
		let funcLog = DLog(.textPlain => .filter { $0.funcName == "test_Filter()" } => .stdout)
		XCTAssertNotNil(funcLog.info("info"))
		
		// Line
		let lineLog = DLog(.textPlain => .filter { $0.line > #line } => .stdout)
		XCTAssertNotNil(lineLog.info("info"))
		
		// Text
		let textLog = DLog(.textPlain => .filter { $0.text().contains("hello") } => .stdout)
		XCTAssertNotNil(textLog.info("hello world"))
		XCTAssertNotNil(textLog.debug("hello"))
		XCTAssertNil(textLog.info("info"))
		XCTAssertNil(read_stdout { textLog.interval("interval") { delay(0.3) } })
		XCTAssertNotNil(read_stdout { textLog.interval("hello interval") { Thread.sleep(forTimeInterval: 0.3) } })
		XCTAssertNil(read_stdout { textLog.scope("scope") { _ in } })
		XCTAssertNotNil(read_stdout { textLog.scope("scope hello") { _ in } })
		
		// Scope
		let scopeLog = DLog(.textPlain => .filter { ($0 as? LogScope)?.text() == "Load" || $0._scope?.text() == "Load" } => .stdout)
		//let scopeLog = DLog(.textPlain => .filter { $0.scope?.level == 1 } => .stdout)
		XCTAssertNil(scopeLog.info("info"))
		XCTAssertNotNil(read_stdout {
			scopeLog.scope("Load") { scope in
				XCTAssertNotNil(scope.debug("load"))
				XCTAssertNotNil(scope.error("load"))
				XCTAssertNil(read_stdout {
					scopeLog.scope("Parse") { scope in
						XCTAssertNil(scope.debug("parse"))
						XCTAssertNil(scope.error("parse"))
					}
				})
			}
		})
		XCTAssertNil(scopeLog.fault("fault"))
	}
	
	// MARK: - Disabled
	
	func test_Disabled() {
		
		let failBool: () -> Bool = {
			XCTFail()
			return false
		}
		
		let failString: () -> String = {
			XCTFail()
			return ""
		}
		
		let test: (LogProtocol, XCTestExpectation) -> Void = { log, expectation in
			log.log(failString())
			log.trace(failString())
			log.debug("\(failString())")
			log.info(failString())
			log.warning(failString())
			log.error(failString())
			log.fault(failString())
			log.assert(failBool(), failString())
			log.scope("scope") { _ in expectation.fulfill() }
			log.interval("interval") { expectation.fulfill() }
		}
		
		let log = DLog.disabled
		let scope = log.scope("scope")
		let netLog = log["NET"]
		
		wait { expectation in
			expectation.expectedFulfillmentCount = 6
			
			XCTAssertNil(
				read_stdout {
					test(log, expectation)
					test(netLog, expectation)
					test(scope, expectation)
				}
			)
		}
	}
	
	
	// MARK: - Thread safe
	// categories, scopes, interavls
	
	func test_NonBlock() {
		let log = DLog(.textPlain
						=> .stdout
						=> .file("dlog.txt")
						=> .oslog
						=> .filter { $0.type == .debug }
						=> .net)
		
		let netLog = log["NET"]
		netLog.log("log")
		netLog.trace()
		netLog.debug("debug")
		netLog.info("info")
		netLog.warning("warning")
		netLog.error("error")
		netLog.assert(false)
		netLog.fault("fault")
		netLog.scope("scope") { _ in }
		netLog.interval("signpost") {  }
		
		let scope = log.scope("test") { scope in
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
		var config = DLog.defaultConfiguration
		config.options = []
		
		let log = DLog(configuration: config)
		
		XCTAssert(log.trace()?.match(#"^func: test_ConfigEmpty\(\), thread: \{ number: 1, name: main \}$"#) == true)
	}
	
	func test_ConfigAll() {
		var config = DLog.defaultConfiguration
		config.options = .all
		
		let log = DLog(configuration: config)
		
		XCTAssert(log.trace()?.match(#"\#(Sign) \#(Time) \#(Level) \#(CategoryTag) \#(TraceTag) \#(Location) func: test_ConfigAll\(\), thread: \{ number: 1, name: main \}"#) == true)
	}
}

final class IntervalTests: XCTestCase {
	
	func test_Interval() {
		let log = DLog()
		
		XCTAssert(read_stdout {
			log.interval("signpost") {
				delay()
			}
		}?.match(#"signpost: \#(Interval)"#) == true)
	}
	
	func test_IntervalBeginEnd() {
		let log = DLog()
		
		XCTAssert(read_stdout {
			let interval = log.interval("signpost")
			interval.begin()
			delay()
			interval.end()
		}?.match(#"signpost: \#(Interval)"#) == true)
		
		// Double begin/end
		XCTAssert(read_stdout {
			let interval = log.interval("signpost")
			interval.begin()
			interval.begin()
			delay()
			interval.end()
			interval.end()
		}?.match(#"signpost: \#(Interval)"#) == true)
	}
	
	func test_IntervalStatistics() {
		let log = DLog()

		let interval = log.interval("Signpost") {
			delay()
		}
		XCTAssert(interval.count == 1)
		XCTAssert(0.25 <= interval.duration)
		XCTAssert(0.25 <= interval.total)
		XCTAssert(0.25 <= interval.min)
		XCTAssert(0.25 <= interval.max)
		XCTAssert(0.25 <= interval.avg)
		
		interval.begin()
		delay()
		interval.end()
		XCTAssert(interval.count == 2)
		XCTAssert(0.25 <= interval.duration)
		XCTAssert(0.5 <= interval.total)
		XCTAssert(0.25 <= interval.min)
		XCTAssert(0.25 <= interval.max)
		XCTAssert(0.25 <= interval.avg)
	}
	
	func test_IntervalConcurrent() {
		var config = DLog.defaultConfiguration
		config.intervalConfiguration.options = .all
		let log = DLog(configuration: config)
		
		for i in 0..<10 {
			DispatchQueue.global().async {
				log.interval("Signpost") { delay(); log.debug("\(i)") }
			}
		}
		
		delay(1)
	}
	
	func test_IntervalNameEmpty() {
		let log = DLog()
		
		XCTAssert(read_stdout {
			log.interval("") {
				delay()
			}
		}?.match(#"> duration: \#(SECS), average: \#(SECS)$"#) == true)
	}
	
	func test_IntervalConfigEmpty() {
		var config = DLog.defaultConfiguration
		config.intervalConfiguration.options = []
		
		let log = DLog(configuration: config)
		
		XCTAssert(read_stdout {
			log.interval("signpost") {
				delay()
			}
		}?.match(#"signpost$"#) == true)
	}
	
	func test_IntervalConfigAll() {
		var config = DLog.defaultConfiguration
		config.intervalConfiguration.options = .all
		
		let log = DLog(configuration: config)
		
		XCTAssert(read_stdout {
			log.interval("signpost") {
				delay()
			}
		}?.match(#"signpost: \{ duration: \#(SECS), count: [0-9]+, total: \#(SECS), min: \#(SECS), max: \#(SECS), average: \#(SECS) \}"#) == true)
	}
}

final class ScopeTests: XCTestCase {
	
	func test_Scope() {
		let log = DLog()
		
		log.scope("scope") {
			testAll($0)
		}
	}
	
	func test_ScopeConfigEmpty() {
		var config = DLog.defaultConfiguration
		config.options = []
		let log = DLog(configuration: config)
		
		log.scope("scope") {
			XCTAssert($0.trace()?.match(#"^func: test_ScopeConfigEmpty\(\), thread: \{ number: 1, name: main \}"#) == true)
		}
	}
	
	func test_ScopeStack() {
		var config = DLog.defaultConfiguration
		config.options = .all
		
		let log = DLog(configuration: config)
		
		XCTAssert(log.debug("no scope")?.match(#"\[00\] \#(CategoryTag) \#(DebugTag) \#(Location) no scope"#) == true)
		
		log.scope("scope1") { scope1 in
			XCTAssert(scope1.info("scope1 start")?.match(#"\[01\] \#(CategoryTag) \| \#(InfoTag) \#(Location) scope1 start"#) == true)
			
			log.scope("scope2") { scope2 in
				XCTAssert(scope2.debug("scope2 start")?.match(#"\[02\] \#(CategoryTag) \| | \#(DebugTag) \#(Location) scope2 start"#) == true)
				
				log.scope("scope3") { scope3 in
					XCTAssert(scope3.error("scope3")?.match(#"\[03\] \#(CategoryTag) \| \| \| \#(ErrorTag) \#(Location) scope3"#) == true)
				}
				
				XCTAssert(scope2.fault("scope2")?.match(#"\[02\] \#(CategoryTag) \| \| \#(FaultTag) \#(Location) scope2"#) == true)
			}
			
			XCTAssert(scope1.trace("scope1 end")?.match(#"\[01\] \#(CategoryTag) \| \#(TraceTag) \#(Location) scope1 end"#) == true)
		}
		
		XCTAssert(log.trace("no scope")?.match(#"\[00\] \#(CategoryTag) \#(TraceTag) \#(Location) no scope"#) == true)
	}
	
	func test_ScopeNotEntered() {
		let log = DLog()
		let scope1 = log.scope("scope 1")
		XCTAssert(scope1.trace()?.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) func: \#(#function)"#) == true)
	}
	
	func test_ScopeEnterLeave() {
		let log = DLog()
			
		let scope1 = log.scope("scope 1")
		let scope2 = log.scope("scope 2")
		let scope3 = log.scope("scope 3")
		
		log.trace("no scope")
		
		scope1.enter()
		XCTAssert(scope1.info("1")?.match(#"\#(CategoryTag) \| \#(InfoTag) \#(Location) 1"#) == true)
		
		scope2.enter()
		XCTAssert(scope2.info("2")?.match(#"\#(CategoryTag) \| \| \#(InfoTag) \#(Location) 2"#) == true)
		
		scope3.enter()
		XCTAssert(scope3.info("3")?.match(#"\#(CategoryTag) \| \| \| \#(InfoTag) \#(Location) 3"#) == true)
		
		scope1.leave()
		XCTAssert(scope3.debug("3")?.match(#"\#(CategoryTag)   \| \| \#(DebugTag) \#(Location) 3"#) == true)
		
		scope2.leave()
		XCTAssert(scope3.error("3")?.match(#"\#(CategoryTag)     \| \#(ErrorTag) \#(Location) 3"#) == true)
		
		scope3.leave()
		XCTAssert(log.fault("no scope")?.match(#"\#(CategoryTag) \#(FaultTag) \#(Location) no scope"#) == true)
	}
	
	func test_ScopeDoubleEnter() {
		let log = DLog()
		
		let scope1 = log.scope("My Scope")
		
		scope1.enter()
		scope1.enter()
		
		XCTAssert(scope1.trace()?.match(#"\#(CategoryTag) \| \#(TraceTag) \#(Location) func: \#(#function)"#) == true)
		
		scope1.leave()
		scope1.leave()
		
		scope1.enter()
		XCTAssert(scope1.trace()?.match(#"\#(CategoryTag) \| \#(TraceTag) \#(Location) func: \#(#function)"#) == true)
		scope1.leave()

		XCTAssert(log.trace()?.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) func: \#(#function)"#) == true)
	}
	
	func test_ScopeConcurrent() {
		let log = DLog()
		
		for i in 1...10 {
			DispatchQueue.global().async {
				log.scope("Scope \(i)") { $0.debug("scope \(i)") }
			}
		}
		
		delay(1)
	}
	
	func test_ScopeDuration() {
		let log = DLog()
		
		var scope = log.scope("scope1") { _ in
			delay()
		}
		XCTAssert(0.25 <= scope.duration)
		
		scope = log.scope("scope2")
		scope.enter()
		delay()
		scope.leave()
		XCTAssert(0.25 <= scope.duration)
	}
}

final class TraceTests: XCTestCase {
	
	func test_Trace() {
		let log = DLog()
		
		XCTAssert(log.trace()?.match(#"func: test_Trace\(\), thread: \{ number: 1, name: main \}$"#) == true)
	}
		
	func test_TraceText() {
		let log = DLog()
		
		XCTAssert(log.trace("trace")?.match(#"trace: \{ func: test_TraceText\(\), thread: \{ number: 1, name: main \} \}$"#) == true)
	}
	
	func test_TraceFunction() {
		var config = DLog.defaultConfiguration
		config.traceConfiguration.options = .function
		
		let log = DLog(configuration: config)
		
		XCTAssert(log.trace()?.match(#"func: test_TraceFunction"#) == true)
	}
	
	func test_TraceQoS() {
		var config = DLog.defaultConfiguration
		config.traceConfiguration.options = [.thread, .queue]
		config.traceConfiguration.threadConfiguration.options = .all
		
		let log = DLog(configuration: config)
		
		XCTAssert(log.trace()?.match(#"com.apple.main-thread"#) == true)
		
		let queues = [
			#"com.apple.root.background-qos"# : DispatchQueue.global(qos: .background),
			#"com.apple.root.utility-qos"# : DispatchQueue.global(qos: .utility),
			#"com.apple.root.default-qos"# : DispatchQueue.global(qos: .default),
			#"com.apple.root.user-initiated-qos"# : DispatchQueue.global(qos: .userInitiated),
			#"com.apple.root.user-interactive-qos"# : DispatchQueue.global(qos: .userInteractive),
			#"serial"# : DispatchQueue(label: "serial"),
			#"concurrent"# : DispatchQueue(label: "concurrent", attributes: .concurrent)
		]
		for (label, queue) in queues {
			queue.async {
				XCTAssert(log.trace()?.match(label) == true)
			}
		}
	}
	
	func test_TraceThreadMain() {
		var config = DLog.defaultConfiguration
		config.traceConfiguration.options = .thread
		
		let log = DLog(configuration: config)
		
		XCTAssert(log.trace()?.match(#"thread: \{ number: 1, name: main \}$"#) == true)
	}
	
	func test_TraceThreadDetach() {
		var config = DLog.defaultConfiguration
		config.traceConfiguration.options = .thread
		
		let log = DLog(configuration: config)
		
		Thread.detachNewThread {
			XCTAssert(log.trace()?.match(#"thread: \{ number: \d+ \}$"#) == true)
		}
		
		delay()
	}
	
	func test_TraceThreadAll() {
		var config = DLog.defaultConfiguration
		config.traceConfiguration.options = .thread
		config.traceConfiguration.threadConfiguration.options = .all
		
		let log = DLog(configuration: config)
		
		XCTAssert(log.trace()?.match(#"thread: \{ number: \d+, name: \S+, priority: \S+, qos: [^,]+, stackSize: \d+ KB \}$"#) == true)
	}
	
	func test_TraceThreadOptionsEmpty() {
		var config = DLog.defaultConfiguration
		config.traceConfiguration.options = .thread
		config.traceConfiguration.threadConfiguration.options = []
		
		let log = DLog(configuration: config)
		
		XCTAssert(log.trace()?.match(#"> $"#) == true)
	}
	
	func test_TraceStack() {
		var config = DLog.defaultConfiguration
		config.traceConfiguration.options = .stack

		let log = DLog(configuration: config)
		
		XCTAssert(log.trace()?.match(#"stack: \[ 0: \{ symbols:"#) == true)
	}
	
	func test_TraceStackAll() {
		var config = DLog.defaultConfiguration
		config.traceConfiguration.options = .stack
		config.traceConfiguration.stackConfiguration.options = .all
		config.traceConfiguration.stackConfiguration.depth = 1

		let log = DLog(configuration: config)
		
		XCTAssert(log.trace()?.match(#"stack: \[ 0: \{ module: \S+, address: 0x[0-9a-f]{16}, symbols: implicit closure #1 \(\) throws -> Swift.Bool in DLogTests.TraceTests.test_TraceStackAll\(\) -> \(\), offset: \d+ \} \]$"#) == true)
		
		return
	}
	
	func test_TraceStackStyleColumn() {
		var config = DLog.defaultConfiguration
		config.traceConfiguration.options = .stack
		config.traceConfiguration.stackConfiguration.style = .column
		
		let log = DLog(configuration: config)
		
		XCTAssert(log.trace()?.match(#"stack: \[\n0: \{ symbols: implicit closure #1 \(\) throws -> Swift.Bool in DLogTests.TraceTests.test_TraceStackStyleColumn\(\) -> \(\) \}"#) == true)
	}
	
	
	func test_TraceConfigEmpty() {
		var config = DLog.defaultConfiguration
		config.traceConfiguration.options = []
		
		let log = DLog(configuration: config)
		
		XCTAssert(log.trace()?.match(#"\#(Location) $"#) == true)
	}
	
	func test_TraceConfigAll() {
		var config = DLog.defaultConfiguration
		config.traceConfiguration.options = .all

		let log = DLog(configuration: config)

		XCTAssert(log.trace()?.match(#"\#(Location) func: test_TraceConfigAll\(\), queue: com.apple.main-thread, thread: \{ number: 1, name: main \}, stack: \[ 0: \{ symbols:"#) == true)
	}
}
