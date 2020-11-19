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
	
	//MARK: Tests -
	
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
				log.scope("scope") {}
				log.interval("interval") {}
			}
		)
	}
	
	func test_PlainText() {
		let log = DLog()
		
		XCTAssert(log.trace()!.match(#"\[DLOG\] \[TRACE\] <DLogTests.swift:[0-9]+>"#))
		XCTAssert(log.info("info")!.match(#"\[DLOG\] \[INFO\] <DLogTests.swift:[0-9]+> info"#))
		XCTAssert(log.debug("debug")!.match(#"\[DLOG\] \[DEBUG\] <DLogTests.swift:[0-9]+> debug"#))
		XCTAssert(log.error("error")!.match(#"\[DLOG\] \[ERROR\] <DLogTests.swift:[0-9]+> error"#))
		XCTAssert(log.assert(false)!.match(#"\[DLOG\] \[ASSERT\] <DLogTests.swift:[0-9]+>"#))
		XCTAssert(log.assert(true, "assert text") == nil)
		XCTAssert(log.fault("fatal error")!.match(#"\[DLOG\] \[FAULT\] <DLogTests.swift:[0-9]+> fatal error"#))
		XCTAssert(stdoutText { log.interval("My Interval") { delay()} }?.match(#"\[My Interval\]"#) == true)
		XCTAssert(stdoutText { log.scope("My Scope"){ delay() } }?.match(#"\[My Scope\]"#) == true)
	}
	
	func test_EmojiText() {
		let log = DLog(.textEmoji => .stdout)
		
		XCTAssert(log.trace()!.match(#"\[DLOG\] ⚛️ \[TRACE\] <DLogTests.swift:[0-9]+>"#))
		XCTAssert(log.info("info")!.match(#"\[DLOG\] ✅ \[INFO\] <DLogTests.swift:[0-9]+> info"#))
		XCTAssert(log.debug("debug")!.match(#"\[DLOG\] ▶️ \[DEBUG\] <DLogTests.swift:[0-9]+> debug"#))
		XCTAssert(log.error("error")!.match(#"\[DLOG\] ⚠️ \[ERROR\] <DLogTests.swift:[0-9]+> error"#))
		XCTAssert(log.assert(false)!.match(#"\[DLOG\] 🅰️ \[ASSERT\] <DLogTests.swift:[0-9]+>"#))
		XCTAssert(log.assert(true, "assert text") == nil)
		XCTAssert(log.fault("fatal error")!.match(#"\[DLOG\] 🆘 \[FAULT\] <DLogTests.swift:[0-9]+> fatal error"#))
		XCTAssert(stdoutText { log.interval("My Interval") { delay() } }?.match(#"🕒 \[INTERVAL\]"#) == true)
		XCTAssert(stdoutText { log.scope("My Scope"){ delay() } }?.match(#"\[My Scope\]"#) == true)
	}
	
	func test_ColoredText() {
		let log = DLog(.textColored => .stdout)
		
		XCTAssert(log.trace()!.contains(ANSIEscapeCode.reset.rawValue))
		XCTAssert(log.info("info")!.contains(ANSIEscapeCode.reset.rawValue))
		XCTAssert(log.debug("debug")!.contains(ANSIEscapeCode.reset.rawValue))
		XCTAssert(log.error("error")!.contains(ANSIEscapeCode.reset.rawValue))
		XCTAssert(log.assert(false, "assert")!.contains(ANSIEscapeCode.reset.rawValue))
		XCTAssert(log.fault("fault")!.contains(ANSIEscapeCode.reset.rawValue))
		XCTAssert(stdoutText { log.interval("interval"){ delay() } }?.contains(ANSIEscapeCode.reset.rawValue) == true)
		XCTAssert(stdoutText { log.scope("scope"){ delay() } }?.contains(ANSIEscapeCode.reset.rawValue) == true)
	}
	
	func test_Category() {
		let log = DLog()
		XCTAssert(log.trace()!.match(#"\[DLOG\]"#))
		
		let netLog = log["NET"]
		XCTAssert(netLog.trace()!.match(#"\[NET\]"#))
		XCTAssert(netLog.info("info")!.match(#"\[NET\]"#))
		XCTAssert(netLog.debug("debug")!.match(#"\[NET\]"#))
		XCTAssert(netLog.error("error")!.match(#"\[NET\]"#))
		XCTAssert(netLog.fault("fault")!.match(#"\[NET\]"#))
		XCTAssert(netLog.assert(false, "assert")!.match(#"\[NET\]"#))
		XCTAssert(stdoutText { netLog.scope("scope") { } }?.match(#"\[NET\]"#) == true)
		XCTAssert(stdoutText { netLog.interval("interval") { } }?.match(#"\[NET\]"#) == true)
	}
	
	func test_ScopeStack() {
		let log = DLog()
		
		log.scope("scope1") {
			XCTAssert(log.info("scope1 start")!.match(#"\[DLOG\] \|\t✅ \[INFO\] <DLogTests.swift:[0-9]+> scope1 start"#))
			
			log.scope("scope2") {
				XCTAssert(log.debug("scope2 start")!.match(#"\[DLOG\] \|\t\|\t▶️ \[DEBUG\] <DLogTests.swift:[0-9]+> scope2 start"#))
				
				log.scope("scope3") {
					XCTAssert(log.error("scope3")!.match(#"\[DLOG\] \|\t\|\t\|\t⚠️ \[ERROR\] <DLogTests.swift:[0-9]+> scope3"#))
				}
				
				XCTAssert(log.fault("scope2")!.match(#"\[DLOG\] \|\t\|\t🆘 \[FAULT\] <DLogTests.swift:[0-9]+> scope2"#))
			}
			
			XCTAssert(log.trace("scope1 end")!.match(#"\[DLOG\] \|\t◽️ \[TRACE\] <DLogTests.swift:[0-9]+> scope1 end"#))
		}
		
		XCTAssert(log.trace("no scope")!.match(#"\[DLOG\] ◽️ \[TRACE\] <DLogTests.swift:[0-9]+> no scope"#))
	}
	
	func test_ScopeDoubleEnter() {
		let log = DLog()
		
		let scope1 = log.scope("My Scope")
		
		scope1.enter()
		scope1.enter()
		
		XCTAssert(log.trace()!.match(#"\[DLOG\] \|\t◽️ \[TRACE\] <DLogTests.swift:[0-9]+> test_ScopeDoubleEnter()"#))
		
		scope1.leave()
		scope1.leave()
		
		XCTAssert(log.trace()!.match(#"\[DLOG\] ◽️ \[TRACE\] <DLogTests.swift:[0-9]+> test_ScopeDoubleEnter"#))
	}

	func test_ScopeCreate() {
		let log = DLog()
			
		let scope1 = log.scope("Scope-1")
		let scope2 = log.scope("Scope-2")
		let scope3 = log.scope("Scope-3")
		
		log.trace("no scope")
		
		scope1.enter()
		
		XCTAssert(log.info("scope1 start")!.match(#"\[DLOG\] \|\t✅ \[INFO\] <DLogTests.swift:[0-9]+> scope1 start"#))
		
		scope2.enter()
		
		XCTAssert(log.info("scope2 start")!.match(#"\[DLOG\] \|\t\|\t✅ \[INFO\] <DLogTests.swift:[0-9]+> scope2 start"#))
		
		scope3.enter()
		
		XCTAssert(log.info("scope3 start")!.match(#"\[DLOG\] \|\t\|\t\|\t✅ \[INFO\] <DLogTests.swift:[0-9]+> scope3 start"#))
		
		scope1.leave()
		
		XCTAssert(log.debug("scope1 ended")!.match(#"\[DLOG\] \t\|\t\|\t▶️ \[DEBUG\] <DLogTests.swift:[0-9]+> scope1 ended"#))
		
		scope2.leave()
		
		XCTAssert(log.error("scope2 ended")!.match(#"\[DLOG\] \t\t\|\t⚠️ \[ERROR\] <DLogTests.swift:[0-9]+> scope2 ended"#))
		
		scope3.leave()
		
		XCTAssert(log.fault("scope3 ended")!.match(#"\[DLOG\] 🆘 \[FAULT\] <DLogTests.swift:[0-9]+> scope3 ended"#))
	}

	
	func test_IntervalCreate() {
		let log = DLog()
		
		wait { exp in
			let interval = log.interval("Interval 1")
			
			interval.begin()
			
			asyncAfter {
				interval.end()
				
				exp.fulfill()
			}
		}
	}
	
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
						=> .net(debug: true))
		
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
		XCTAssert(interval < 0.01)
		
		wait { exp in
			asyncAfter(0.5) {
				exp.fulfill()
			}
		}
	}
	
	func test_Adaptive() {
		let log = DLog(.adaptive)
		
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
	}
}
