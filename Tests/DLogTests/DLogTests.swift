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
let TraceTag = #"\[TRACE\]"#
let InfoTag = #"\[INFO\]"#
let DebugTag = #"\[DEBUG\]"#
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
		
		XCTAssert(log.trace()?.match(#"\#(categoryTag) \#(TraceTag) \#(Location) testAll"#) == true)
		XCTAssert(log.info("info")?.match(#"\#(categoryTag) \#(InfoTag) \#(Location) info"#) == true)
		XCTAssert(log.debug("debug")?.match(#"\#(categoryTag) \#(DebugTag) \#(Location) debug"#) == true)
		XCTAssert(log.error("error")?.match(#"\#(categoryTag) \#(ErrorTag) \#(Location) error"#) == true)
		XCTAssertNil(log.assert(true, "assert"))
		XCTAssert(log.assert(false, "assert")?.match(#"\#(categoryTag) \#(AssertTag) \#(Location) assert"#) == true)
		XCTAssert(log.fault("fault")?.match(#"\#(categoryTag) \#(FaultTag) \#(Location) fault"#) == true)
		
		XCTAssert(read_stdout { log.scope("scope") { delay() } }?.match(#"\#(categoryTag) └ \[scope\] \(0\.[0-9]{3}s\)"#) == true)
		XCTAssert(read_stdout { log.interval("signpost") { delay() } }?.match(#"\#(categoryTag) \[INTERVAL\] \#(Location) \[signpost\] Count: 1, Total: 0\.[0-9]{3}s, Min: 0\.[0-9]{3}s, Max: 0\.[0-9]{3}s, Avg: 0\.[0-9]{3}s"#) == true)
	}
	
	func test_Log() {
		let log = DLog()
		testAll(log)
	}
	
	// MARK: - Scope
	
	func test_Scope() {
		let log = DLog()
		
		XCTAssert(read_stdout { log.scope("scope") {} }?.match(#"\[scope\]"#) == true)
	}
	
	func test_ScopeStack() {
		let log = DLog()
		
		log.scope("scope1") {
			XCTAssert(log.info("scope1 start")?.match(#"\#(CategoryTag) \|\t\#(InfoTag) \#(Location) scope1 start"#) == true)
			
			log.scope("scope2") {
				XCTAssert(log.debug("scope2 start")?.match(#"\#(CategoryTag) \|\t\|\t\#(DebugTag) \#(Location) scope2 start"#) == true)
				
				log.scope("scope3") {
					XCTAssert(log.error("scope3")?.match(#"\#(CategoryTag) \|\t\|\t\|\t\#(ErrorTag) \#(Location) scope3"#) == true)
				}
				
				XCTAssert(log.fault("scope2")?.match(#"\#(CategoryTag) \|\t\|\t\#(FaultTag) \#(Location) scope2"#) == true)
			}
			
			XCTAssert(log.trace("scope1 end")?.match(#"\#(CategoryTag) \|\t\#(TraceTag) \#(Location) scope1 end"#) == true)
		}
		
		XCTAssert(log.trace("no scope")?.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) no scope"#) == true)
	}
	
	func test_ScopeEnterLeave() {
		let log = DLog()
			
		let scope1 = log.scope("Scope-1")
		let scope2 = log.scope("Scope-2")
		let scope3 = log.scope("Scope-3")
		
		log.trace("no scope")
		
		scope1.enter()
		XCTAssert(log.info("scope1 start")?.match(#"\#(CategoryTag) \|\t\#(InfoTag) \#(Location) scope1 start"#) == true)
		
		scope2.enter()
		XCTAssert(log.info("scope2 start")?.match(#"\#(CategoryTag) \|\t\|\t\#(InfoTag) \#(Location) scope2 start"#) == true)
		
		scope3.enter()
		XCTAssert(log.info("scope3 start")?.match(#"\#(CategoryTag) \|\t\|\t\|\t\#(InfoTag) \#(Location) scope3 start"#) == true)
		
		scope1.leave()
		XCTAssert(log.debug("scope1 ended")?.match(#"\#(CategoryTag) \t\|\t\|\t\#(DebugTag) \#(Location) scope1 ended"#) == true)
		
		scope2.leave()
		XCTAssert(log.error("scope2 ended")?.match(#"\#(CategoryTag) \t\t\|\t\#(ErrorTag) \#(Location) scope2 ended"#) == true)
		
		scope3.leave()
		XCTAssert(log.fault("scope3 ended")?.match(#"\#(CategoryTag) \#(FaultTag) \#(Location) scope3 ended"#) == true)
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
	
	func test_ScopeDuration() {
		let log = DLog()
		
		var scope = log.scope("scope1") {
			delay()
		}
		XCTAssert(0.25 <= scope.duration && scope.duration <= 0.26)
		
		scope = log.scope("scope2")
		scope.enter()
		delay()
		scope.leave()
		XCTAssert(0.25 <= scope.duration && scope.duration <= 0.26)
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
		XCTAssert(0.25 <= interval.duration && interval.duration <= 0.26)
		XCTAssert(0.25 <= interval.minDuration && interval.minDuration <= 0.26)
		XCTAssert(0.25 <= interval.maxDuration && interval.maxDuration <= 0.26)
		XCTAssert(0.25 <= interval.avgDuration && interval.avgDuration <= 0.26)
		
		interval.begin()
		delay()
		interval.end()
		XCTAssert(interval.count == 2)
		XCTAssert(0.5 <= interval.duration && interval.duration <= 0.51)
		XCTAssert(0.25 <= interval.minDuration && interval.minDuration <= 0.26)
		XCTAssert(0.25 <= interval.maxDuration && interval.maxDuration <= 0.26)
		XCTAssert(0.25 <= interval.avgDuration && interval.avgDuration <= 0.26)
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
		
		XCTAssert(log.trace()?.match(#"\#(CategoryTag) ⚛️ \#(TraceTag) \#(Location) \#(#function)"#) == true)
		XCTAssert(log.info("info")?.match(#"\#(CategoryTag) ✅ \#(InfoTag) \#(Location) info"#) == true)
		XCTAssert(log.debug("debug")?.match(#"\#(CategoryTag) ▶️ \#(DebugTag) \#(Location) debug"#) == true)
		XCTAssert(log.error("error")?.match(#"\#(CategoryTag) ⚠️ \#(ErrorTag) \#(Location) error"#) == true)
		XCTAssert(log.assert(false)?.match(#"\#(CategoryTag) 🅰️ \#(AssertTag) \#(Location)"#) == true)
		XCTAssert(log.fault("fatal")?.match(#"\#(CategoryTag) 🆘 \#(FaultTag) \#(Location) fatal"#) == true)
		
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
	}
	
	// MARK: - Disabled
	
	func test_Disabled() {
		let log = DLog.disabled
		
		XCTAssertNil(
			read_stdout {
				log.trace()
				log.info("info")
				log.debug("debug")
				log.error("error")
				log.fault("fatal")
				log.assert(false, "assert")
				log.scope("scope") { }
				log.interval("interval") { }
			}
		)
		
		wait(count: 2) { exps in
			log.scope("scope") { exps[0].fulfill() }
			log.interval("interval") { exps[1].fulfill() }
		}
	}
	
	
	// MARK: - Thread safe
	// categories, scopes, interavls
	
	func test_Concurent() {
		let log = DLog()
		
		let queue = DispatchQueue(label: "Concurent", attributes: .concurrent)
		
		for i in 0..<10 {
			queue.async {
				log.scope("Concurent") { log.debug("\(i)") }
			}
			queue.async {
				log.interval("Concurent") { log.debug("\(i)") }
			}
		}
		
		delay(1)
	}
	
	func test_NonBlock() {
		let log = DLog(.textPlain
						=> .stdout
						=> .file("dlog.txt")
						=> .oslog
						=> .filter { $0.type == .debug }
						=> .net)
		
		let scope = log.scope("test") {
			log.trace()
			log.info("info")
			log.debug("debug")
			log.error("error")
			log.assert(false)
			log.fault("fault")
			log.scope("scope") {  }
			log.interval("interval") {  }
		}
		
		XCTAssert(scope.duration < 0.02)
	}
}
