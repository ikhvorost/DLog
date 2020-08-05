import Foundation
import XCTest
@testable import DebugKit

/// String errors
extension String : LocalizedError {
	public var errorDescription: String? { return self }
}

func asyncAfter(_ sec: Double = 0.25, closure: @escaping (() -> Void) ) {
	DispatchQueue.global().asyncAfter(deadline: .now() + sec, execute: closure)
}

final class DebugKitTests: XCTestCase {
	
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
	
//	override func setUp() {
//		super.setUp()
//	}
	
	// Tests
	
	let log = DLog() // Adaptive
	//let log = DLog(outputs: [OSLogOutput()])
	//let log = DLog.disabled
	
	func test_LogTypes() {
		log.trace()
		log.info("info")
		log.debug("debug")
		log.error("Error")
		log.fault("Fatal error")
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
		
		log.trace("no scope")
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
		wait { exp in
			
			let scope1 = log.scope("Scope-1")
			let scope2 = log.scope("Scope-2")
			let scope3 = log.scope("Scope-3")
			
			log.debug("no scope")
			
			scope1.enter()
			
			log.info("scope1 start")
			
			scope2.enter()
			
			log.info("scope2 start")
			
			asyncAfter {
				scope3.enter()
				
				self.log.debug("scope3 start")
				
				self.log.debug("scope1 end")
				
				scope1.leave()
				
				self.log.debug("scope2 end")
				
				scope2.leave()
				
				self.log.debug("scope3 end")
				
				scope3.leave()
				
				self.log.error("no scope")
				
				exp.fulfill()
			}
		}
	}
}
