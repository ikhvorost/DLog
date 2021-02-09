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
	
	// LogProtocol
	var category: String
	
	init(log: DLog, category: String) {
		self.log = log
		self.category = category
	}
}

extension LogCategory: LogProtocol {
	
	var scope: LogScope? {
		log.scope
	}
	
	func log(_ text: String, type: LogType, category: String, scope: LogScope?, file: String, function: String, line: UInt) -> String?  {
		log.log(text, type: type, category: category, scope: scope, file: file, function: function, line: line)
	}
	
	func scope(_ text: String, category: String, file: String, function: String, line: UInt, closure: ((LogScope) -> Void)?) -> LogScope {
		log.scope(text, category: category, file: file, function: function, line: line, closure: closure)
	}
	
	func interval(_ name: StaticString, category: String, scope: LogScope?, file: String, function: String, line: UInt, closure: (() -> Void)? = nil) -> LogInterval {
		log.interval(name, category: category, scope: scope, file: file, function: function, line: line, closure: closure)
	}
}
