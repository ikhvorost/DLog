#if !os(watchOS)

import Foundation
import XCTest
@testable import DebugKit

/// String errors
extension String : LocalizedError {
	public var errorDescription: String? { return self }
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
	
	func test_Auto() {
		let log = DLog()
		log.trace()
		log.info("info")
		log.debug("debug")
		log.error("Error")
		log.fault("Fatal error")
	}
}

#endif
