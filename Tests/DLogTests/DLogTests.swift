import Foundation
import XCTest
@testable import DLog

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

/// Get text from stdout
func stdoutText(_ block: () -> Void) -> String? {
	var result: String?
	
    // Save original output
    let original = dup(STDOUT_FILENO);

    setvbuf(stdout, nil, _IONBF, 0)
	let pipe = Pipe()
    dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
	
	let lock = DispatchSemaphore.Lock()
    
    pipe.fileHandleForReading.readabilityHandler = { handle in
		if let text = String(data: handle.availableData, encoding: .utf8) {
			// Print to stderr because stdout is piped
			fputs(text, stderr)
			
			result = text
			
			lock.signal()
		}
    }
    
    block()
	
	_ = lock.wait(timeout: .now() + 1)
    
    // Revert
    fflush(stdout)
    dup2(original, STDOUT_FILENO)
    close(original)
	
	return result
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
		
		XCTAssert(log.trace()!.match(#"\#(categoryTag) \#(TraceTag) \#(Location) testAll()"#))
		XCTAssert(log.info("info")!.match(#"\#(categoryTag) \#(InfoTag) \#(Location) info"#))
		XCTAssert(log.debug("debug")!.match(#"\#(categoryTag) \#(DebugTag) \#(Location) debug"#))
		XCTAssert(log.error("error")!.match(#"\#(categoryTag) \#(ErrorTag) \#(Location) error"#))
		XCTAssertNil(log.assert(true, "assert"))
		XCTAssert(log.assert(false, "assert")!.match(#"\#(categoryTag) \#(AssertTag) \#(Location) assert"#))
		XCTAssert(log.fault("fault")!.match(#"\#(categoryTag) \#(FaultTag) \#(Location) fault"#))
		
		XCTAssert(stdoutText { log.scope("scope") {}; delay() }!.match(#"\#(categoryTag) └ \[scope\] \(0\.[0-9]{3}s\)"#))
		XCTAssert(stdoutText { log.interval("signpost") { delay(1) }; delay() }!.match(#"\#(categoryTag) \[INTERVAL\] \#(Location) \[signpost\] Count: 1, Total: 1\.[0-9]{3}s, Min: 1\.[0-9]{3}s, Max: 1\.[0-9]{3}s, Avg: 1\.[0-9]{3}s"#))
	}
	
	func test_Log() {
		testAll(DLog())
	}
	
	// MARK: - Scope
	
	func test_Scope() {
		let log = DLog()
		
		XCTAssert(stdoutText { log.scope("scope") {} }!.match(#"\[scope\]"#))
	}
	
	func test_ScopeStack() {
		let log = DLog()
		
		log.scope("scope1") {
			XCTAssert(log.info("scope1 start")!.match(#"\#(CategoryTag) \|\t\#(InfoTag) \#(Location) scope1 start"#))
			
			log.scope("scope2") {
				XCTAssert(log.debug("scope2 start")!.match(#"\#(CategoryTag) \|\t\|\t\#(DebugTag) \#(Location) scope2 start"#))
				
				log.scope("scope3") {
					XCTAssert(log.error("scope3")!.match(#"\#(CategoryTag) \|\t\|\t\|\t\#(ErrorTag) \#(Location) scope3"#))
				}
				
				XCTAssert(log.fault("scope2")!.match(#"\#(CategoryTag) \|\t\|\t\#(FaultTag) \#(Location) scope2"#))
			}
			
			XCTAssert(log.trace("scope1 end")!.match(#"\#(CategoryTag) \|\t\#(TraceTag) \#(Location) scope1 end"#))
		}
		
		XCTAssert(log.trace("no scope")!.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) no scope"#))
	}
	
	func test_ScopeEnterLeave() {
		let log = DLog()
			
		let scope1 = log.scope("Scope-1")
		let scope2 = log.scope("Scope-2")
		let scope3 = log.scope("Scope-3")
		
		log.trace("no scope")
		
		scope1.enter()
		XCTAssert(log.info("scope1 start")!.match(#"\#(CategoryTag) \|\t\#(InfoTag) \#(Location) scope1 start"#))
		
		scope2.enter()
		XCTAssert(log.info("scope2 start")!.match(#"\#(CategoryTag) \|\t\|\t\#(InfoTag) \#(Location) scope2 start"#))
		
		scope3.enter()
		XCTAssert(log.info("scope3 start")!.match(#"\#(CategoryTag) \|\t\|\t\|\t\#(InfoTag) \#(Location) scope3 start"#))
		
		scope1.leave()
		XCTAssert(log.debug("scope1 ended")!.match(#"\#(CategoryTag) \t\|\t\|\t\#(DebugTag) \#(Location) scope1 ended"#))
		
		scope2.leave()
		XCTAssert(log.error("scope2 ended")!.match(#"\#(CategoryTag) \t\t\|\t\#(ErrorTag) \#(Location) scope2 ended"#))
		
		scope3.leave()
		XCTAssert(log.fault("scope3 ended")!.match(#"\#(CategoryTag) \#(FaultTag) \#(Location) scope3 ended"#))
	}
	
	func test_ScopeDoubleEnter() {
		let log = DLog()
		
		let scope1 = log.scope("My Scope")
		
		scope1.enter()
		scope1.enter()
		
		XCTAssert(log.trace()!.match(#"\#(CategoryTag) \|\t\#(TraceTag) \#(Location) test_ScopeDoubleEnter()"#))
		
		scope1.leave()
		scope1.leave()
		
		scope1.enter()
		XCTAssert(log.trace()!.match(#"\#(CategoryTag) \|\t\#(TraceTag) \#(Location) test_ScopeDoubleEnter()"#))
		scope1.leave()
		
		XCTAssert(log.trace()!.match(#"\#(CategoryTag) \#(TraceTag) \#(Location) test_ScopeDoubleEnter"#))
	}

	// MARK: - Interval
	
	func test_Interval() {
		let log = DLog()
		
		XCTAssert(stdoutText {
			log.interval("signpost") {
				delay(1)
			}
		}!.match(#"\[signpost\] Count: 1, Total: 1\.[0-9]{3}s, Min: 1\.[0-9]{3}s, Max: 1\.[0-9]{3}s, Avg: 1\.[0-9]{3}s"#))
	}
	
	func test_IntervalBeginEnd() {
		let log = DLog()
		
		XCTAssert(stdoutText {
			let interval = log.interval("signpost")
			interval.begin()
			delay(1)
			interval.end()
		}!.match(#"\[signpost\] Count: 1, Total: 1\.[0-9]{3}s, Min: 1\.[0-9]{3}s, Max: 1\.[0-9]{3}s, Avg: 1\.[0-9]{3}s"#))
		
		// Double begin/end
		XCTAssert(stdoutText {
			let interval = log.interval("signpost")
			interval.begin()
			interval.begin()
			delay(1)
			interval.end()
			interval.end()
		}!.match(#"\[signpost\] Count: 1, Total: 1\.[0-9]{3}s, Min: 1\.[0-9]{3}s, Max: 1\.[0-9]{3}s, Avg: 1\.[0-9]{3}s"#))
		
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
		
		XCTAssert(log.trace()!.match(#"\#(CategoryTag) ⚛️ \#(TraceTag) \#(Location) test_textEmoji()"#))
		XCTAssert(log.info("info")!.match(#"\#(CategoryTag) ✅ \#(InfoTag) \#(Location) info"#))
		XCTAssert(log.debug("debug")!.match(#"\#(CategoryTag) ▶️ \#(DebugTag) \#(Location) debug"#))
		XCTAssert(log.error("error")!.match(#"\#(CategoryTag) ⚠️ \#(ErrorTag) \#(Location) error"#))
		XCTAssert(log.assert(false)!.match(#"\#(CategoryTag) 🅰️ \#(AssertTag) \#(Location)"#))
		XCTAssert(log.fault("fatal")!.match(#"\#(CategoryTag) 🆘 \#(FaultTag) \#(Location) fatal"#))
		
		XCTAssert(stdoutText { log.scope("My Scope") {} }!.match(#"\[My Scope\]"#))
		XCTAssert(stdoutText { log.interval("My Interval") {} }!.match(#"🕒 \[INTERVAL\]"#))
	}
	
	func test_textColored() {
		let log = DLog(.textColored => .stdout)
		
		XCTAssert(log.trace()!.contains(ANSIEscapeCode.reset.rawValue))
		XCTAssert(log.info("info")!.contains(ANSIEscapeCode.reset.rawValue))
		XCTAssert(log.debug("debug")!.contains(ANSIEscapeCode.reset.rawValue))
		XCTAssert(log.error("error")!.contains(ANSIEscapeCode.reset.rawValue))
		XCTAssert(log.assert(false, "assert")!.contains(ANSIEscapeCode.reset.rawValue))
		XCTAssert(log.fault("fault")!.contains(ANSIEscapeCode.reset.rawValue))
		
		XCTAssert(stdoutText { log.scope("scope") {} }!.contains(ANSIEscapeCode.reset.rawValue))
		XCTAssert(stdoutText { log.interval("interval") {} }!.contains(ANSIEscapeCode.reset.rawValue))
	}
	
	// MARK: - Standard
	
	func test_stdOut() {
		let log = DLog(.stdout)
	}
	
	
	// MARK: - Filter
	
	func test_Filter() {
		// Time
		let timeLog = DLog(.text => .filter { $0.time != nil } => .stdout)
		XCTAssertNotNil(timeLog.info("info"))
		
		// Category
		let categoryLog = DLog(.text => .filter { $0.category == "NET" } => .stdout)
		XCTAssertNil(categoryLog.info("info"))
		let netLog = categoryLog["NET"]
		XCTAssertNotNil(netLog.info("info"))
		
		// Type
		let typeLog = DLog(.text => .filter { $0.type == .debug } => .stdout)
		XCTAssertNil(typeLog.trace())
		XCTAssertNil(typeLog.info("info"))
		XCTAssertNotNil(typeLog.debug("debug"))
		XCTAssertNil(stdoutText { typeLog.scope("scope") {} })
		
		// File name
		let fileLog = DLog(.text => .filter { $0.fileName == "DLogTests.swift" } => .stdout)
		XCTAssertNotNil(fileLog.info("info"))
		
		// Func name
		let funcLog = DLog(.text => .filter { $0.funcName == "test_Filter()" } => .stdout)
		XCTAssertNotNil(funcLog.info("info"))
		
		// Line
		let lineLog = DLog(.text => .filter { $0.line > #line } => .stdout)
		XCTAssertNotNil(lineLog.info("info"))
		
		// Text
		let textLog = DLog(.text => .filter { $0.text.contains("hello") } => .stdout)
		XCTAssertNotNil(textLog.info("hello world"))
		XCTAssertNotNil(textLog.debug("hello"))
		XCTAssertNil(textLog.info("info"))
		XCTAssertNil(stdoutText { textLog.interval("interval") { delay(0.3) } })
		XCTAssertNotNil(stdoutText { textLog.interval("hello interval") { Thread.sleep(forTimeInterval: 0.3) } })
		XCTAssertNil(stdoutText { textLog.scope("scope") {} })
		XCTAssertNotNil(stdoutText { textLog.scope("scope hello") {} })
		
		//delay(0.3)
	}
	
	func test_File() {
		let filePath = "dlog.txt"
		let log = DLog(.text => .file(filePath))
		log.trace()
		
		delay(0.1)
		do {
			let text = try String(contentsOfFile: filePath)
			XCTAssert(text.match("\(#function)"))
		}
		catch {
			XCTFail(error.localizedDescription)
		}
	}
	
	func test_Disabled() {
		let log = DLog.disabled
		
		XCTAssertNil(
			stdoutText {
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
	
	func test_NetConsole() {
		wait(5) { exp in
			let log = DLog(.net)
			log.trace()
			log.info("info")
			log.debug("debug")
		
			asyncAfter(4) {
				log.error("error")
				log.assert(false)
				exp.fulfill()
			}
		}
	}	
	
	// MARK: - Thread safe
	// categories, scopes, interavls
	
	func test_Concurent() {
		let log = DLog()
		
		let queue = DispatchQueue(label: "Concurent", attributes: .concurrent)
		
		for i in 0..<10 {
			//let scope = log.scope("Scope")
			queue.async {
				log.interval("Concurent") {  }
				log.info("\(i)")
			}
		}
		
		wait { exp in
			delay(1)
			exp.fulfill()
		}
	}
	
	func test_NonBlock() {
		let log = DLog(.stdout
						=> .oslog
						=> .file("dlog.txt")
						=> .filter { $0.type == .debug }
						=> .textColored
						=> .net)
		
		let time = Date()
		
		log.trace()
		log.info("info")
		log.debug("debug")
		log.error("error")
		log.scope("scope") {
			log.assert(false)
		}
		log.interval("interval") {
			log.fault("fault")
		}
		
		let interval = -time.timeIntervalSinceNow
		print("Interval: \(interval)")
		XCTAssert(interval < 0.1)
		
		wait { exp in
			asyncAfter(0.5) {
				exp.fulfill()
			}
		}
	}
}
