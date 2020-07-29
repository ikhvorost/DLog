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

class Trace {
	let name: String
	
	init(name: String = #function) {
		self.name = name
		print("+", name)
	}
	
	deinit {
		print("-", name)
	}
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
	
	//let log = DLog() // Adaptive
	let log = DLog(output: [OSLogOutput()])
	
	func test_LogTypes() {
		log.trace("trace")
		log.info("info")
		log.debug("debug")
		log.error("Error")
		log.fault("Fatal error")
	}
	
	func test_ScopeStack() {
		log.trace("no scope")
		
		log.scope("scope1") {
			log.trace("scope1 start")
			
			log.scope("scope2") {
				log.debug("scope2 start")
				log.error("scope2 end")
			}
			
			log.trace("scope1 end")
		}
		
		log.trace("no scope")
	}
	
	func test_ScopeCreate() {
		wait { exp in
			
			let scope = log.scopeCreate("Scope")
			
			log.info("no scope")
			
			log.scopeEnter(scope)
			
			log.info("scope start")
			
			asyncAfter {
				self.log.info("scope end")
				
				self.log.scopeLeave(scope)
				
				self.log.info("no scope")
				
				exp.fulfill()
			}
		}
	}
}
