import Foundation
import XCTest
/*@testable*/ import DLog

// MARK: - Utils

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
let CategoryTag = #"\[DLOG\]"#

let LogTag = #"\[LOG\]"#
let TraceTag = #"\[TRACE\]"#
let DebugTag = #"\[DEBUG\]"#
let InfoTag = #"\[INFO\]"#
let WarningTag = #"\[WARNING\]"#
let ErrorTag = #"\[ERROR\]"#
let AssertTag = #"\[ASSERT\]"#
let FaultTag = #"\[FAULT\]"#

let Location = "<DLogTests.swift:[0-9]+>"

final class DLogTests: XCTestCase {
	
	func wait(count: Int, timeout: TimeInterval = 1, name: String = #function, closure: ([XCTestExpectation]) -> Void) {
		let expectations = (0..<count).map { _ in expectation(description: name) }
		
		closure(expectations)
		
		wait(for: expectations, timeout: timeout)
	}
	
	func wait(_ timeout: TimeInterval = 1, name: String = #function, closure: (XCTestExpectation) -> Void) {
		wait(count: 1, timeout: timeout, name: name) { expectations in
			closure(expectations[0])
		}
	}
	
	// MARK: Tests -
	
	func testAll(_ log: LogProtocol, categoryTag: String = CategoryTag) {
		let scope = #"(\|\t)?"#
		
		XCTAssert(log.log("log")?.match(#"\#(categoryTag) \#(scope)\#(LogTag) \#(Location) log"#) == true)
		
		XCTAssert(log.trace()?.match(#"\#(categoryTag) \#(scope)\#(TraceTag) \#(Location) testAll"#) == true)
		XCTAssert(log.debug("debug")?.match(#"\#(categoryTag) \#(scope)\#(DebugTag) \#(Location) debug"#) == true)
		
		XCTAssert(log.info("info")?.match(#"\#(categoryTag) \#(scope)\#(InfoTag) \#(Location) info"#) == true)
		
		XCTAssert(log.warning("warning")?.match(#"\#(categoryTag) \#(scope)\#(WarningTag) \#(Location) warning"#) == true)
		XCTAssert(log.error("error")?.match(#"\#(categoryTag) \#(scope)\#(ErrorTag) \#(Location) error"#) == true)
		
		XCTAssertNil(log.assert(true, "assert"))
		XCTAssert(log.assert(false)?.match(#"\#(categoryTag) \#(scope)\#(AssertTag) \#(Location)"#) == true)
		XCTAssert(log.assert(false, "assert")?.match(#"\#(categoryTag) \#(scope)\#(AssertTag) \#(Location) assert"#) == true)
		XCTAssert(log.fault("fault")?.match(#"\#(categoryTag) \#(scope)\#(FaultTag) \#(Location) fault"#) == true)
		
		XCTAssert(read_stdout { log.scope("scope") { delay() } }?.match(#"\#(categoryTag) \#(scope)└ \[scope\] \(0\.[0-9]{3}s\)"#) == true)
		XCTAssert(read_stdout { log.interval("signpost") { delay() } }?.match(#"\#(categoryTag) \#(scope)\[INTERVAL\] \#(Location) \[signpost\] Count: 1, Total: 0\.[0-9]{3}s, Min: 0\.[0-9]{3}s, Max: 0\.[0-9]{3}s, Avg: 0\.[0-9]{3}s"#) == true)
	}
	
	func test_Log() {
		let log = DLog()
		testAll(log)
	}
	
	// MARK: - Scope
	
	func test_Scope() {
		let log = DLog()
		
		log.scope("scope") {
			self.testAll($0)
		}
	}
	
	func test_ScopeStack() {
		let log = DLog()
		
		XCTAssert(log.debug("no scope")?.match(#"\[00\] \#(CategoryTag) \#(DebugTag) \#(Location) no scope"#) == true)
		
		log.scope("scope1") {
			XCTAssert(log.info("scope1 start")?.match(#"\[01\] \#(CategoryTag) \|\t\#(InfoTag) \#(Location) scope1 start"#) == true)
			
			log.scope("scope2") {
				XCTAssert(log.debug("scope2 start")?.match(#"\[02\] \#(CategoryTag) \|\t\|\t\#(DebugTag) \#(Location) scope2 start"#) == true)
				
				log.scope("scope3") {
					XCTAssert(log.error("scope3")?.match(#"\[03\] \#(CategoryTag) \|\t\|\t\|\t\#(ErrorTag) \#(Location) scope3"#) == true)
				}
				
				XCTAssert(log.fault("scope2")?.match(#"\[02\] \#(CategoryTag) \|\t\|\t\#(FaultTag) \#(Location) scope2"#) == true)
			}
			
			XCTAssert(log.trace("scope1 end")?.match(#"\[01\] \#(CategoryTag) \|\t\#(TraceTag) \#(Location) scope1 end"#) == true)
		}
		
		XCTAssert(log.trace("no scope")?.match(#"\[00\] \#(CategoryTag) \#(TraceTag) \#(Location) no scope"#) == true)
	}
	
	func test_ScopeEnterLeave() {
		let log = DLog()
			
		let scope1 = log.scope("scope 1")
		let scope2 = log.scope("scope 2")
		let scope3 = log.scope("scope 3")
		
		log.trace("no scope")
		
		scope1.enter()
		XCTAssert(log.info("1")?.match(#"\#(CategoryTag) \|\t\#(InfoTag) \#(Location) 1"#) == true)
		
		scope2.enter()
		XCTAssert(log.info("2")?.match(#"\#(CategoryTag) \|\t\|\t\#(InfoTag) \#(Location) 2"#) == true)
		
		scope3.enter()
		XCTAssert(log.info("3")?.match(#"\#(CategoryTag) \|\t\|\t\|\t\#(InfoTag) \#(Location) 3"#) == true)
		
		scope1.leave()
		XCTAssert(log.debug("3")?.match(#"\#(CategoryTag) \t\|\t\|\t\#(DebugTag) \#(Location) 3"#) == true)
		
		scope2.leave()
		XCTAssert(log.error("3")?.match(#"\#(CategoryTag) \t\t\|\t\#(ErrorTag) \#(Location) 3"#) == true)
		
		scope3.leave()
		XCTAssert(log.fault("no scope")?.match(#"\#(CategoryTag) \#(FaultTag) \#(Location) no scope"#) == true)
	}
	
	func test_ScopeDoubleEnter() {
		let log = DLog()
		
		let scope1 = log.scope("My Scope")
		
		scope1.enter()
		scope1.enter()
		
		XCTAssert(log.trace()?.match(#"\#(CategoryTag) \|\t\#(TraceTag) \#(Location) \#(#function)"#) == true)
		
		scope1.leave()
		scope1.leave()
		
		scope1.enter()
		XCTAssert(log.trace()?.match(#"\#(CategoryTag) \|\t\#(TraceTag) \#(Location) \#(#function)"#) == true)
		scope1.leave()
		
		XCTAssert(log.trace()?.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) \#(#function)"#) == true)
	}
	
	func test_ScopeConcurent() {
		let log = DLog()
		
		for i in 1...10 {
			DispatchQueue.global().async {
				log.scope("Scope \(i)") { delay(); $0.debug("scope \(i)") }
			}
		}
		
		delay(1)
	}
	
	func test_ScopeDuration() {
		let log = DLog()
		
		var scope = log.scope("scope1") {
			delay()
		}
		XCTAssert(0.25 <= scope.duration)
		
		scope = log.scope("scope2")
		scope.enter()
		delay()
		scope.leave()
		XCTAssert(0.25 <= scope.duration)
	}

	// MARK: - Interval
	
	func test_Interval() {
		let log = DLog()
		
		XCTAssert(read_stdout {
			log.interval("signpost") {
				delay()
			}
		}?.match(#"\[signpost\] Count: 1, Total: 0\.[0-9]{3}s, Min: 0\.[0-9]{3}s, Max: 0\.[0-9]{3}s, Avg: 0\.[0-9]{3}s"#) == true)
	}
	
	func test_IntervalBeginEnd() {
		let log = DLog()
		
		XCTAssert(read_stdout {
			let interval = log.interval("signpost")
			interval.begin()
			delay()
			interval.end()
		}?.match(#"\[signpost\] Count: 1, Total: 0\.[0-9]{3}s, Min: 0\.[0-9]{3}s, Max: 0\.[0-9]{3}s, Avg: 0\.[0-9]{3}s"#) == true)
		
		// Double begin/end
		XCTAssert(read_stdout {
			let interval = log.interval("signpost")
			interval.begin()
			interval.begin()
			delay()
			interval.end()
			interval.end()
		}?.match(#"\[signpost\] Count: 1, Total: 0\.[0-9]{3}s, Min: 0\.[0-9]{3}s, Max: 0\.[0-9]{3}s, Avg: 0\.[0-9]{3}s"#) == true)
		
	}
	
	func test_IntervalStatistics() {
		let log = DLog()

		let interval = log.interval("signpost") {
			delay()
		}
		XCTAssert(interval.count == 1)
		XCTAssert(0.25 <= interval.duration)
		XCTAssert(0.25 <= interval.minDuration)
		XCTAssert(0.25 <= interval.maxDuration)
		XCTAssert(0.25 <= interval.avgDuration)
		
		interval.begin()
		delay()
		interval.end()
		XCTAssert(interval.count == 2)
		XCTAssert(0.5 <= interval.duration)
		XCTAssert(0.25 <= interval.minDuration)
		XCTAssert(0.25 <= interval.maxDuration)
		XCTAssert(0.25 <= interval.avgDuration)
	}
	
	func test_IntervalConcurent() {
		let log = DLog()
		
		for i in 0..<10 {
			DispatchQueue.global().async {
				log.interval("Signpost") { delay(); log.debug("\(i)") }
			}
		}
		
		delay(1)
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
		
		XCTAssert(log.trace()?.match(#"\#(CategoryTag) #️⃣ \#(TraceTag) \#(Location) \#(#function)"#) == true)
		XCTAssert(log.debug("debug")?.match(#"\#(CategoryTag) ▶️ \#(DebugTag) \#(Location) debug"#) == true)
		
		XCTAssert(log.info("info")?.match(#"\#(CategoryTag) ✅ \#(InfoTag) \#(Location) info"#) == true)
		
		XCTAssert(log.warning("warning")?.match(#"\#(CategoryTag) ⚠️ \#(WarningTag) \#(Location) warning"#) == true)
		XCTAssert(log.error("error")?.match(#"\#(CategoryTag) ⚠️ \#(ErrorTag) \#(Location) error"#) == true)
		
		XCTAssert(log.assert(false)?.match(#"\#(CategoryTag) 🅰️ \#(AssertTag) \#(Location)"#) == true)
		XCTAssert(log.fault("fault")?.match(#"\#(CategoryTag) 🆘 \#(FaultTag) \#(Location) fault"#) == true)
		
		XCTAssert(read_stdout { log.scope("My Scope") {} }?.match(#"\[My Scope\]"#) == true)
		XCTAssert(read_stdout { log.interval("My Interval") {} }?.match(#"🕒 \[INTERVAL\]"#) == true)
	}
	
	func test_textColored() {
		let log = DLog(.textColored => .stdout)
		
		let reset = "\u{001b}[0m"
		XCTAssert(log.trace()?.contains(reset) == true)
		XCTAssert(log.info("info")?.contains(reset) == true)
		XCTAssert(log.debug("debug")?.contains(reset) == true)
		XCTAssert(log.error("error")?.contains(reset) == true)
		XCTAssert(log.assert(false, "assert")?.contains(reset) == true)
		XCTAssert(log.fault("fault")?.contains(reset) == true)
		
		XCTAssert(read_stdout { log.scope("scope") {} }?.contains(reset) == true)
		XCTAssert(read_stdout { log.interval("interval") {} }?.contains(reset) == true)
	}
	
	// MARK: - Standard
	
	func test_stdOutErr() {
		let logOut = DLog(.stdout)
		XCTAssert(read_stdout { logOut.trace() }?.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) \#(#function)"#) == true)
		
		let logErr = DLog(.stderr)
		XCTAssert(read_stderr { logErr.trace() }?.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) \#(#function)"#) == true)
	}
	
	// MARK: - File
	
	func test_File() {
		let filePath = "dlog.txt"
		let log = DLog(.textPlain => .file(filePath))
		log.trace()
		
		delay(0.1)
		
		do {
			let text = try String(contentsOfFile: filePath)
			print(text)
			XCTAssert(text.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) \#(#function)"#))
		}
		catch {
			XCTFail(error.localizedDescription)
		}
	}
	
	// MARK: - OSLog, NetConsole
	
	// MARK: - Filter
	
	func test_Filter() {
		// Time
		let timeLog = DLog(.textPlain => .filter { $0.time != nil } => .stdout)
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
		XCTAssertNil(read_stdout { typeLog.scope("scope") {} })
		
		// File name
		let fileLog = DLog(.textPlain => .filter { $0.fileName == "DLogTests.swift" } => .stdout)
		XCTAssertNotNil(fileLog.info("info"))
		
		// Func name
		let funcLog = DLog(.textPlain => .filter { $0.funcName == "test_Filter()" } => .stdout)
		XCTAssertNotNil(funcLog.info("info"))
		
		// Line
		let lineLog = DLog(.textPlain => .filter { $0.line > #line } => .stdout)
		XCTAssertNotNil(lineLog.info("info"))
		
		// Text
		let textLog = DLog(.textPlain => .filter { $0.text.contains("hello") } => .stdout)
		XCTAssertNotNil(textLog.info("hello world"))
		XCTAssertNotNil(textLog.debug("hello"))
		XCTAssertNil(textLog.info("info"))
		XCTAssertNil(read_stdout { textLog.interval("interval") { delay(0.3) } })
		XCTAssertNotNil(read_stdout { textLog.interval("hello interval") { Thread.sleep(forTimeInterval: 0.3) } })
		XCTAssertNil(read_stdout { textLog.scope("scope") {} })
		XCTAssertNotNil(read_stdout { textLog.scope("scope hello") {} })
		
		// Scope
		let scopeLog = DLog(.textPlain => .filter { ($0 as? LogScope)?.text == "Load" || $0.scope?.text == "Load" } => .stdout)
		//let scopeLog = DLog(.textPlain => .filter { $0.scope?.level == 1 } => .stdout)
		XCTAssertNil(scopeLog.info("info"))
		XCTAssertNotNil(read_stdout {
			scopeLog.scope("Load") {
				XCTAssertNotNil(scopeLog.debug("load"))
				XCTAssertNotNil(scopeLog.error("load"))
				XCTAssertNil(read_stdout {
					scopeLog.scope("Parse") {
						XCTAssertNil(scopeLog.debug("parse"))
						XCTAssertNil(scopeLog.error("parse"))
					}
				})
			}
		})
		XCTAssertNil(scopeLog.fault("fault"))
	}
	
	// MARK: - Disabled
	
	func test_Disabled() {
		let test: (LogProtocol) -> Void = { log in
			log.log("log")
			log.trace()
			log.debug("debug")
			log.info("info")
			log.warning("warning")
			log.error("error")
			log.fault("fatal")
			log.assert(false, "assert")
			log.scope("scope") { }
			log.interval("interval") { }
		}
		
		let log = DLog.disabled
		let scope = log.scope("scope")
		let netLog = log["NET"]
		
		XCTAssertNil(
			read_stdout {
				test(log)
				test(netLog)
				test(scope)
			}
		)
		
		wait(count: 5) { exps in
			log.scope("scope") { exps[0].fulfill() }
			log.interval("interval") { exps[1].fulfill() }
			
			scope.scope("child") { exps[2].fulfill() }
			
			netLog.scope("scope") { exps[3].fulfill() }
			netLog.interval("interval") { exps[4].fulfill() }
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
		
		let scope = log.scope("test") {
			let netLog = log["NET"]
			netLog.log("log")
			netLog.trace()
			netLog.debug("debug")
			netLog.info("info")
			netLog.warning("warning")
			netLog.error("error")
			netLog.assert(false)
			netLog.fault("fault")
			netLog.scope("scope") {  }
			netLog.interval("signpost") {  }
			
			log.log("log")
			log.trace()
			log.debug("debug")
			log.info("info")
			log.warning("warning")
			log.error("error")
			log.assert(false)
			log.fault("fault")
			log.scope("scope") {  }
			log.interval("signpost") {  }
		}
		
		XCTAssert(scope.duration < 0.1)
	}
}
