import Foundation
import XCTest
@testable import DLog

/// String errors
extension String : LocalizedError {
	public var errorDescription: String? { return self }
}

func asyncAfter(_ sec: Double = 0.25, closure: @escaping (() -> Void) ) {
	DispatchQueue.global().asyncAfter(deadline: .now() + sec, execute: closure)
}

class FilterOutput : LogOutput {
	let type: LogType
	
	init(type: LogType) {
		self.type = type
		super.init()
	}
	
	override func log(message: LogMessage) -> String {
		return message.type == type ? output.log(message: message) : ""
	}
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
	
	var log: DLog!
	
	override func setUp() {
		super.setUp()
		
		//let log = DLog.adaptive
		//let log = DLog.disabled
		log = DLog(output: TextOutput() => StandardOutput() => FileOutput(filePath: "/users/iurii/dlog.txt"))
		//log = DLog(outputs: TextOutput() => StandardOutput())
		//log = DLog(outputs: TextOutput() => FilterOutput(type: .info) => StandardOutput())
		//log = DLog(outputs: ColoredOutput() => NetServiceOutput())
	}
	
	// Tests
	
	func test_LogTypes() {
		log.trace()
		log.info("info")
		log.interval("interval") {}
		log.debug("debug")
		log.error("error")
		log.assert(false, "assert text")
		log.fault("fatal error")
	}
	
	func test_ScopeStack() {
		log.trace()
		
		log.scope("scope1") {
			self.log.info("scope1 start")
			
			self.log.scope("scope2") {
				self.log.debug("scope2 start")
				
				self.log.scope("scope3") {
					self.log.error("scope3")
				}
				self.log.fault("scope2")
			}
			
			self.log.trace("scope1 end")
		}
		
		self.log.trace("no scope")
	}
	
	func test_ScopeDoubleEnter() {
		let scope1 = log.scope("Scope-1")
		
		scope1.enter()
		scope1.enter()
		
		//XCTAssert(log.scopes.count == 1)
		
		log.info("scope1")
		
		scope1.leave()
	}

	func test_ScopeCreate() {
		wait(timeout: 3) { exp in
			
			let scope1 = self.log.scope("Scope-1")
			let scope2 = self.log.scope("Scope-2")
			let scope3 = self.log.scope("Scope-3")
			
			self.log.trace("no scope")
			
			scope1.enter()
			
			self.log.info("scope1 start")
			
			scope2.enter()
			
			self.log.info("scope2 start")
			
			asyncAfter(2) {
				scope3.enter()
				
				self.log.debug("scope3 start")
				
				self.log.debug("scope1 end")
				
				scope1.leave()
				
				self.log.error("scope2 end")
				
				scope2.leave()
				
				self.log.fault("scope3 end")
				
				scope3.leave()
				
				self.log.trace("no scope")
				
				exp.fulfill()
			}
		}
	}
	
	func test_Interval() {
		
		log.scope("Scope 1"){
			self.log.interval("Interval 1") {
				sleep(1)
				self.log.trace("Loop 1")
			}
			
			for _ in 0..<2 {
			self.log.scope("Scope 2") {
				self.log.interval("Interval 2") {
					sleep(1)
					self.log.info("Loop 2")
				}
			}
			}
			
			self.log.interval("Interval 3") {
				sleep(1)
				self.log.trace("Loop 3")
			}
		}
	}
	
	func test_IntervalCreate() {
		wait { exp in
			let interval = log.interval("Interval 1")
			
			interval.begin()
			
			asyncAfter {
				interval.end()
				
				
				exp.fulfill()
			}
		}
	}
}
