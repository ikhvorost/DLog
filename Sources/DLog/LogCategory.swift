//
//  LogCategory.swift
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

/// Creates a logger object that assigns log messages to a specified category.
///
/// You can define category name to differentiate unique areas and parts of your app and the logger can use this value
/// to categorize and filter related log messages.
///
/// 	let log = DLog()
/// 	let netLog = log["NET"]
/// 	let netLog.log("Hello Net!")
///
public class LogCategory: NSObject, LogProtocol {
	init(logger: DLog, category: String) {
		params = LogParams(logger: logger, category: category, scope: nil)
	}
	
	// MARK: - LogProtocol
	
	/// LogProtocol parameters
	public let params: LogParams
	
	@objc
	public lazy var log: LogClosure = { (text, file, function, line) in
		(self as LogProtocol).log(text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var trace: TraceClosure = { (text, file, function, line, addresses) in
		(self as LogProtocol).trace(text, file: file, function: function, line: line, addresses: addresses)
	}
	
	@objc
	public lazy var debug: LogClosure = { (text, file, function, line) in
		(self as LogProtocol).debug(text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var info: LogClosure = { (text, file, function, line) in
		(self as LogProtocol).info(text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var warning: LogClosure = { (text, file, function, line) in
		(self as LogProtocol).warning(text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var error: LogClosure = { (text, file, function, line) in
		(self as LogProtocol).error(text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var assert: AssertClosure = { (condition, text, file, function, line) in
		(self as LogProtocol).assert(condition, text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var fault: LogClosure = { (text, file, function, line) in
		(self as LogProtocol).fault(text, file: file, function: function, line: line)
	}
	
	@objc
	public lazy var scope: ScopeClosure = { (name, file, function, line, closure) in
		(self as LogProtocol).scope(name, file: file, function: function, line: line, closure: closure)
	}
}
