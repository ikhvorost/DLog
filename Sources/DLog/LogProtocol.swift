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
	var logger: DLog { get }
	var category: String { get }
	var currentScope: LogScope? { get }
}

extension LogProtocol {
	
	@discardableResult
	public func log(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		logger.log(text: text, type: .log, category: category, scope: currentScope, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func trace(_ text: String? = nil, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		logger.log(text: text ?? function, type: .trace, category: category, scope: currentScope, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func debug(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		logger.log(text: text, type: .debug, category: category, scope: currentScope, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func info(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		logger.log(text: text, type: .info, category: category, scope: currentScope, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func warning(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		logger.log(text: text, type: .warning, category: category, scope: currentScope, file: file, function: function, line: line)
	}
		
	@discardableResult
	public func error(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		logger.log(text: text, type: .error, category: category, scope: currentScope, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func assert(_ value: Bool, _ text: String = "", file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		guard !value else { return nil }
		return logger.log(text: text, type: .assert, category: category, scope: currentScope, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func fault(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		logger.log(text: text, type: .fault, category: category, scope: currentScope, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func scope(_ text: String, file: String = #file, function: String = #function, line: UInt = #line, closure: ((LogScope) -> Void)? = nil) -> LogScope {
		logger.scope(text: text, category: category, file: file, function: function, line: line, closure: closure)
	}
	
	@discardableResult
	public func interval(_ name: StaticString, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogInterval {
		logger.interval(name: name, category: category, scope: currentScope, file: file, function: function, line: line, closure: closure)
	}
}
