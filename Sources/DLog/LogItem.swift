//
//  LogItem.swift
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
import os.log


/// Logging levels.
public enum LogType : Int {
	/// The default log level.
	///
	/// Use this level to capture non critical information.
	case log
	
	/// The informational log level.
	///
	/// Use this level to capture information messages and helpful data.
	case info
	
	/// The trace log level.
	///
	/// Use this level to capture the current function name to help in debugging problems during the development.
	case trace
	
	/// The debug log level.
	///
	/// Use this level to capture information that may be useful during development or while troubleshooting a specific problem.
	case debug
	
	/// The warning log level.
	///
	/// Use this level to capture information about things that might result in an error.
	case warning
	
	/// The error log level.
	///
	/// Use this log level to report errors.
	case error
	
	/// The assert log level.
	///
	/// Use this log level for sanity checks.
	case assert
	
	/// The fault log level.
	///
	/// Use this level only to capture system-level or multi-process information when reporting system errors.
	case fault
	
	/// The interval log level.
	case interval
	/// The scope log level.
	case scope
}

public class LogItem {
	public var time: Date?
	public let category: String
	public let scope: LogScope?
	public let type: LogType
	public let fileName: String
	public let funcName: String
	public let line: UInt
	public let text: String

	public init(time: Date? = nil, category: String, scope: LogScope?, type: LogType, fileName: String, funcName: String, line: UInt, text: String) {
		self.time = time
		self.category = category
		self.scope = scope
		self.type = type
		self.fileName = fileName
		self.funcName = funcName
		self.line = line
		self.text = text
	}
}

public class LogScope : LogItem, LogProtocol {
	let logger: DLog
	
	/// LogProtocol parameters
	public lazy var params = LogParams(logger: logger, category: category, scope: self)
	
	internal(set) public var level: Int = 0
	
	let uid = UUID()
	var os_state = os_activity_scope_state_s()
	@Atomic var entered = false
	
	private(set) public var duration: TimeInterval = 0
	
	init(logger: DLog, category: String, fileName: String, funcName: String, line: UInt, name: String) {
		self.logger = logger
		super.init(category: category, scope: nil, type: .scope, fileName: fileName, funcName: funcName, line: line, text: name)
	}
	
	deinit {
		logger.leave(scope: self)
	}
	
	public func enter() {
		guard !entered else { return }
		entered.toggle()
		
		time = Date()
		duration = 0
		logger.enter(scope: self)
	}
	
	public func leave() {
		guard entered else { return }
		entered.toggle()
		
		if let t = time {
			duration = -t.timeIntervalSinceNow
		}
		
		logger.leave(scope: self)
	}
}

public class LogInterval : LogItem {
	let logger: DLog
	let name: StaticString
	
	@Atomic var begun = false
	
	private(set) public var count = 0
	private(set) public var duration: TimeInterval = 0
	private(set) public var minDuration: TimeInterval = 0
	private(set) public var maxDuration: TimeInterval = 0
	private(set) public var avgDuration: TimeInterval = 0
	
	var id : String {
		"\(fileName):\(line)"
	}
	
	// SignpostID
	private var _signpostID: Any? = nil
	var signpostID: OSSignpostID? {
		set { _signpostID = newValue }
		get { _signpostID as? OSSignpostID }
	}
	
	init(logger: DLog, category: String, scope: LogScope?, fileName: String, funcName: String, line: UInt, name: StaticString) {
		self.logger = logger
		self.name = name
		
		super.init(category: category, scope: scope, type: .interval, fileName: fileName, funcName: funcName, line: line, text: "\(name)")
	}
	
	public func begin() {
		guard !begun else { return }
		begun.toggle()
	
		time = Date()
		logger.begin(interval: self)
	}
	
	public func end() {
		guard begun, let time = time else { return }
		begun.toggle()
		
		let interval = -time.timeIntervalSinceNow
		count += 1
		duration += interval
		if minDuration == 0 || minDuration > interval {
			minDuration = interval
		}
		if maxDuration == 0 || maxDuration < interval {
			maxDuration = interval
		}
		avgDuration = duration / Double(count)
		
		logger.end(interval: self)
	}
}
