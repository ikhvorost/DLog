//
//  DLog.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/06/03.
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


/// The central class to emit log messages to specified outputs using one of the methods corresponding to a log level.
///
public class DLog: LogProtocol {
	
	private let output: LogOutput?

	/// The shared disabled logger.
	///
	/// Using this constant prevents from logging messages.
	///
	/// 	let logger = DLog.disabled
	///
	@objc
	public static let disabled = DLog(nil)
    
    /// Creates a logger object that assigns log messages to a specified category.
	///
	/// You can define category name to differentiate unique areas and parts of your app and DLog uses this value
	/// to categorize and filter related log messages.
	///
	/// 	let logger = DLog()
	///     let netLogger = logger["NET"]
	///     let netLogger.log("Hello Net!")
	///
    /// - Parameters:
    ///     - name: Name of category.
	@objc
	public subscript(name: String) -> LogProtocol {
        category(name: name)
	}
    
    /// Creates a logger object with a configuration that assigns log messages to a specified category.
    ///
    /// You can define category name to differentiate unique areas and parts of your app and DLog uses this value
    /// to categorize and filter related log messages.
    ///
    ///     var config = LogConfig()
    ///     config.sign = ">"
    ///
    ///     let logger = DLog()
    ///     let netLogger = logger.category(name: "NET", config: config)
    ///
    /// - Parameters:
    ///     - name: Name of category.
    ///     - config: Configuration of category.
    public func category(name: String, config: LogConfig? = nil, metadata: Metadata? = nil) -> LogProtocol {
        LogProtocol(logger: self, category: name, config: config ?? self.config, metadata: metadata ?? self.metadata.data)
    }

	/// Creates the logger instance with a target output object.
	///
	/// Create an instance and use it to log text messages about your app’s behaviour and to help you assess the state
	/// of your app later. You also can choose a target output and a log level to indicate the severity of that message.
	///
	/// 	let logger = DLog()
	///     logger.log("Hello DLog!")
	///
	/// - Parameters:
	/// 	- output: A target output object. If it is omitted the logger uses `stdout` by default.
	///
    public init(_ output: LogOutput? = .stdout, config: LogConfig = LogConfig(), metadata: Metadata = Metadata()) {
		self.output = output
        super.init(logger: nil, category: "DLOG", config: config, metadata: metadata)
        self.logger = self
	}
    
    /// Creates the logger instance with a list of linked outputs for both swift and objective-c code.
    ///
    /// Swift:
    ///
    ///     let logger = DLog([.textPlain, .stdout])
    ///
    /// Objective-C:
    ///
    ///     DLog* logger = [[DLog alloc] initWithOutputs:@[LogOutput.textPlain, filter, LogOutput.stdOut]];
    ///
    /// - Parameters:
    ///     - outputs: An array of outputs.
    ///
    @objc
    public convenience init(outputs: [LogOutput]) {
        var output: LogOutput?
        
        if outputs.count == 0 {
            output = .stdout
        }
        else {
            output = outputs.count == 1
                ? outputs.first
                : outputs.reduce(.textPlain, =>)
        }

        self.init(output)
    }
    
    /// Creates the default logger.
    @objc
    public convenience init() {
        self.init(_:config:metadata:)()
	}

	// Scope

	func enter(scope: LogScope) {
		guard let out = output else { return }
    ScopeStack.shared.append(scope) {
      out.scopeEnter(scope: scope)
    }
	}

	func leave(scope: LogScope) {
		guard let out = output else { return }
    ScopeStack.shared.remove(scope) {
      out.scopeLeave(scope: scope)
    }
	}

	// Interval
	
	func begin(interval: LogInterval) {
		guard let out = output else { return }
		out.intervalBegin(interval: interval)
	}

	func end(interval: LogInterval) {
		guard let out = output else { return }
		out.intervalEnd(interval: interval)
	}

    func log(message: @escaping () -> LogMessage, type: LogType, category: String, config: LogConfig, scope: LogScope?, metadata: Metadata, file: String, function: String, line: UInt) -> String? {
        guard let out = output else { return nil }
        let item = LogItem(type: type, category: category, config: config, scope: scope, metadata: metadata, file: file, funcName: function, line: line, message: message)
		return out.log(item: item)
	}
}
