//
//  LogCategory
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


public class LogCategory {
	let log: DLog
	let category: String
	
	public init(log: DLog, category: String) {
		self.log = log
		self.category = category
	}
}

extension LogCategory: LogProtocol {
	
	@discardableResult
	public func trace(_ text: String? = nil, category: String = "", file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.trace(text, category: self.category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func info(_ text: String, category: String = "", file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.info(text, category: self.category, file: file, function: function, line: line)
	}
		
	@discardableResult
	public func debug(_ text: String, category: String = "", file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.debug(text, category: self.category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func error(_ text: String, category: String = "", file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.error(text, category: self.category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func fault(_ text: String, category: String = "", file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.fault(text, category: self.category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func assert(_ value: Bool, _ text: String, category: String = "", file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.assert(value, text, category: self.category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func scope(_ text: String, category: String = "", file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogScope {
		log.scope(text, category: self.category, file: file, function: function, line: line, closure: closure)
	}
	
	@discardableResult
	public func interval(_ name: StaticString, category: String = "", file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogInterval {
		log.interval(name, category: self.category, file: file, function: function, line: line, closure: closure)
	}
}
