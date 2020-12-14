//
//  LogProtocol
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/10/14.
//  Copyright © 2020 Iurii Khvorost. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public protocol LogProtocol {
	func trace(_ text: String?, category: String, file: String, function: String, line: UInt) -> String?
	func info(_ text: String, category: String, file: String, function: String, line: UInt) -> String?
	func debug(_ text: String, category: String, file: String, function: String, line: UInt) -> String?
	func error(_ text: String, category: String, file: String, function: String, line: UInt) -> String?
	func fault(_ text: String, category: String, file: String, function: String, line: UInt) -> String?
	func assert(_ value: Bool, _ text: String, category: String, file: String, function: String, line: UInt) -> String?
	func scope(_ text: String, category: String, file: String, function: String, line: UInt, closure: (() -> Void)?) -> LogScope
	func interval(_ name: StaticString, category: String, file: String, function: String, line: UInt, closure: (() -> Void)?) -> LogInterval
}

extension LogProtocol {
	
	@discardableResult
	func trace(_ text: String? = nil, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		trace(text, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	func info(_ text: String, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		info(text, category: category, file: file, function: function, line: line)
	}
		
	@discardableResult
	func debug(_ text: String, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		debug(text, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	func error(_ text: String, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		error(text, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	func fault(_ text: String, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		fault(text, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	func assert(_ value: Bool, _ text: String, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		assert(value, text, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	func scope(_ text: String, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogScope {
		scope(text, category: category, file: file, function: function, line: line, closure: closure)
	}
	
	@discardableResult
	func interval(_ name: StaticString, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogInterval {
		interval(name, category: category, file: file, function: function, line: line, closure: closure)
	}
	
}
