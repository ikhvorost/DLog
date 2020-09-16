import Foundation
import XCTest
@testable import DLog


/// String errors
extension String : LocalizedError {
	public var errorDescription: String? { return self }
}

extension String {
    func match(_ pattern: String) -> Bool {
		self.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

func asyncAfter(_ sec: Double = 0.25, closure: @escaping (() -> Void) ) {
	DispatchQueue.global().asyncAfter(deadline: .now() + sec, execute: closure)
}

final class DLogTests: XCTestCase {
	
	func wait(count: Int, timeout: TimeInterval = 1, name: String = #function, closure: ([XCTestExpectation]) -> Void) {
		let expectations = (0..<count).map { _ in expectation(description: name) }
		
		closure(expectations)
		
		wait(for: expectations, timeout: timeout)
	}
	
	func wait(timeout: TimeInterval = 1, name: String = #function, closure: (XCTestExpectation) -> Void) {
		wait(count: 1, timeout: timeout, name: name) { expectations in
			closure(expectations[0])
		}
	}
	
	//MARK: Tests -
	
	func test_Disabled() {
		let log = DLog.disabled
		
		XCTAssert(log.trace() == nil)
		XCTAssert(log.debug("debug") == nil)
		XCTAssert(log.fault("fatal") == nil)
	}
	
	func test_LogTypes() {
		let log = DLog.standard
		
		XCTAssert(log.trace()!.match(#"\[DLOG\] ◽️ \[TRACE\] <DLogTests.swift:[0-9]+> test_LogTypes"#))
		XCTAssert(log.info("info")!.match(#"\[DLOG\] ✅ \[INFO\] <DLogTests.swift:[0-9]+> info"#))
		XCTAssert(log.debug("debug")!.match(#"\[DLOG\] ▶️ \[DEBUG\] <DLogTests.swift:[0-9]+> debug"#))
		XCTAssert(log.error("error")!.match(#"\[DLOG\] ⚠️ \[ERROR\] <DLogTests.swift:[0-9]+> error"#))
	
		XCTAssert(log.assert(false, "assert text")!.match(#"\[DLOG\] 🅰️ \[ASSERT\] <DLogTests.swift:[0-9]+> assert text"#))
		XCTAssert(log.assert(true, "assert text") == nil)
		
		XCTAssert(log.fault("fatal error")!.match(#"\[DLOG\] 🆘 \[FAULT\] <DLogTests.swift:[0-9]+> fatal error"#))
		
		for _ in 0..<10 {
			let i = TimeInterval.random(in: 0.1...0.3)
			let interval = log.interval("My Interval") {
				Thread.sleep(forTimeInterval: i)
			}
			XCTAssert("\(interval.name)" == "My Interval")
		}
		
		let scope = log.scope("My Scope") {}
		XCTAssert(scope.text == "My Scope")
	}
	
	func test_ScopeStack() {
		let log = DLog.standard
		
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
		let log = DLog.standard
		
		let scope1 = log.scope("My Scope")
		
		scope1.enter()
		scope1.enter()
		
		XCTAssert(log.trace()!.match(#"\[DLOG\] \|\t◽️ \[TRACE\] <DLogTests.swift:[0-9]+> test_ScopeDoubleEnter()"#))
		
		scope1.leave()
		scope1.leave()
		
		XCTAssert(log.trace()!.match(#"\[DLOG\] ◽️ \[TRACE\] <DLogTests.swift:[0-9]+> test_ScopeDoubleEnter"#))
	}

	func test_ScopeCreate() {
		let log = DLog.standard
			
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
		let log = DLog.standard
		
		wait { exp in
			let interval = log.interval("Interval 1")
			
			interval.begin()
			
			asyncAfter {
				interval.end()
				
				exp.fulfill()
			}
		}
	}
	
	func test_File() {
		//log = DLog(output: TextOutput() => StandardOutput() => ColoredOutput() => FileOutput(filePath: "/users/iurii/dlog.txt"))
	}
	
	func test_Filter() {
		// Filter
		
		//let category: String
		
		// Text
		//let log = DLog(output: TextOutput() => FilterOutput(query: "text CONTAINS[c] 'hello'") => StandardOutput())
		let log = DLog(output: TextOutput() => FilterOutput { $0.text.lowercased().contains("hello") } => StandardOutput())
		XCTAssertNotNil(log.info("hello world"))
		XCTAssertNil(log.info("start"))
		log.scope("Hello") {
			XCTAssertNotNil(log.info("hello"))
			XCTAssertNil(log.info("start"))
		}
		
		log.scope("Start") {
			XCTAssertNotNil(log.info("hello"))
			XCTAssertNil(log.info("start"))
		}
		
		// Type
		//log = DLog(output: TextOutput() => FilterOutput(query: "type >= \(LogType.error.rawValue)") => StandardOutput())
		
		// File name
		//log = DLog(output: TextOutput() => FilterOutput(query: "fileName = 'DLogTests.swift'") => StandardOutput())
		
		// Func name
		//log = DLog(output: TextOutput() => FilterOutput(query: "functionName = 'test_LogTypes()'") => StandardOutput())
		
		// Line
		//log = DLog(output: TextOutput() => FilterOutput(query: "line = 58") => StandardOutput())
	}
	
	func test_NetConsole() {
		// Net
		//log = DLog(output: ColoredOutput() => NetServiceOutput())
	}
	
	func test_Concurent() {
		let log = DLog.standard
		
		let queue = DispatchQueue(label: "Concurent", attributes: .concurrent)
		
		
		for i in 0..<10 {
			//let scope = log.scope("Scope")
			queue.async {
				log.interval("Concurent") {  }
				log.info("\(i)")
			}
		}
		
		wait(timeout: 1) { exp in
			sleep(1)
			exp.fulfill()
		}
	}
}
