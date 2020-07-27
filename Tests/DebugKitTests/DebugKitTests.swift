#if !os(watchOS)

import Foundation
import XCTest
@testable import DebugKit

/// String errors
extension String : LocalizedError {
	public var errorDescription: String? { return self }
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
//		//print(ProcessInfo.processInfo.environment)
//	}
	
	// Tests
	
	func test_Trace() {
		//let t = Trace()
	}
	
	func test_Scope() {
		let log = DLog(output: [XConsoleOutput(), OSLogOutput()])
		
		log.trace("trace")
		
		log.scope(name: "Hello") {
			log.trace("trace")
			log.info("info")
			
			log.scope(name: "World") {
				log.debug("debug")
				log.error("Error")
			}
			
			log.fault("Fatal error")
		}
		
		log.trace("trace")
		
	}
}

#endif
