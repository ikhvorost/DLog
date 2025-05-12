//
//  Log.swift
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


public typealias MetadataKey = String
public typealias MetadataValue = Sendable & Codable
public typealias Metadata = [MetadataKey : MetadataValue]


/// Base logger class
public class Log: @unchecked Sendable {
  let logger = AtomicWeak<DLog>()
  let category: String
  let config: LogConfig
  
  /// Contextual metadata
  public let metadata: AtomicDictionary<MetadataKey, MetadataValue>
  
  init(logger: DLog?, category: String, config: LogConfig, metadata: Metadata) {
    self.logger.value = logger
    self.category = category
    self.config = config
    self.metadata = AtomicDictionary(metadata)
  }
  
  private func stack() -> [Bool]? {
    if let scope = self as? LogScope {
      return scope.stack
    }
    return nil
  }
  
  private func log(message: LogMessage, type: LogType, location: LogLocation) -> Log.Item? {
    guard logger.value?.isEnabled == true else {
      return nil
    }
    let item = Log.Item(category: category, stack: stack(), type: type, location: location, metadata: metadata.value, message: message.text, config: config)
    logger.value?.log(item: item)
    return item
  }
  
  /// Logs a message that is essential to troubleshoot problems later.
  ///
  /// This method logs the message using the default log level.
  ///
  ///		let logger = DLog()
  ///		logger.log("message")
  ///
  /// - Parameters:
  /// 	- message: The message to be logged that can be used with any string interpolation literal.
  /// 	- file: The file this log message originates from (defaults to `#file`).
  /// 	- function: The function this log message originates from (defaults to `#function`).
  /// 	- line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  ///
  @discardableResult
  public func log(_ message: LogMessage, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> Log.Item? {
    log(message: message, type: .log, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs trace information to help debug problems during the development of your code.
  ///
  /// Use it during development to record information that might aid you in debugging problems later.
  ///
  ///		let logger = DLog()
  ///		logger.trace("message")
  ///
  /// - Parameters:
  /// 	- message: The message to be logged that can be used with any string interpolation literal.
  /// 	- file: The file this log message originates from (defaults to `#file`).
  /// 	- function: The function this log message originates from (defaults to `#function`).
  /// 	- line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  ///
  @discardableResult
  public func trace(_ message: LogMessage = "", fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> LogTrace? {
    guard logger.value?.isEnabled == true else {
      return nil
    }
    let location = LogLocation(fileID: fileID, file: file, function: function, line: line)
    let item = LogTrace(category: category, stack: stack(), location: location, metadata: metadata.value, message: message.text, config: config)
    logger.value?.log(item: item)
    return item
  }
  
  /// Logs a message to help debug problems during the development of your code.
  ///
  /// Use this method during development to record information that might aid you in debugging problems later.
  ///
  ///		let logger = DLog()
  ///		logger.debug("message")
  ///
  /// - Parameters:
  /// 	- message: The message to be logged that can be used with any string interpolation literal.
  /// 	- file: The file this log message originates from (defaults to `#file`).
  /// 	- function: The function this log message originates from (defaults to `#function`).
  /// 	- line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  ///
  @discardableResult
  public func debug(_ message: LogMessage, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> Log.Item? {
    log(message: message, type: .debug, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs a message that is helpful, but not essential, to diagnose issues with your code.
  ///
  /// Use this method to capture information messages and helpful data.
  ///
  ///		let logger = DLog()
  ///		logger.info("message")
  ///
  /// - Parameters:
  /// 	- message: The message to be logged that can be used with any string interpolation literal.
  /// 	- file: The file this log message originates from (defaults to `#file`).
  /// 	- function: The function this log message originates from (defaults to `#function`).
  /// 	- line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  ///
  @discardableResult
  public func info(_ message: LogMessage, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> Log.Item? {
    log(message: message, type: .info, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs a warning that occurred during the execution of your code.
  ///
  /// Use this method to capture information about things that might result in an error.
  ///
  ///		let logger = DLog()
  ///		logger.warning("message")
  ///
  /// - Parameters:
  /// 	- message: The message to be logged that can be used with any string interpolation literal.
  /// 	- file: The file this log message originates from (defaults to `#file`).
  /// 	- function: The function this log message originates from (defaults to `#function`).
  /// 	- line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  ///
  @discardableResult
  public func warning(_ message: LogMessage, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> Log.Item? {
    log(message: message, type: .warning, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs an error that occurred during the execution of your code.
  ///
  /// Use this method to report errors.
  ///
  ///		let logger = DLog()
  ///		logger.error("message")
  ///
  /// - Parameters:
  /// 	- message: The message to be logged that can be used with any string interpolation literal.
  /// 	- file: The file this log message originates from (defaults to `#file`).
  /// 	- function: The function this log message originates from (defaults to `#function`).
  /// 	- line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  ///
  @discardableResult
  public func error(_ message: LogMessage, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> Log.Item? {
    log(message: message, type: .error, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs a traditional C-style assert notice with an optional message.
  ///
  /// Use this function for internal sanity checks.
  ///
  ///		let logger = DLog()
  ///		logger.assert(condition, "message")
  ///
  /// - Parameters:
  /// 	- condition: The condition to test.
  /// 	- message: A string to print if `condition` is evaluated to `false`. The default is an empty string.
  /// 	- file: The file this log message originates from (defaults to `#file`).
  /// 	- function: The function this log message originates from (defaults to `#function`).
  /// 	- line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  ///
  @discardableResult
  public func assert(_ condition: @autoclosure () -> Bool, _ message: LogMessage = "", fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> Log.Item? {
    guard logger.value?.isEnabled == true && !condition() else {
      return nil
    }
    return log(message: message, type: .assert, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs a bug or fault that occurred during the execution of your code.
  ///
  /// Use this method to capture critical errors that occurred during the execution of your code.
  ///
  ///		let logger = DLog()
  ///		logger.fault("message")
  ///
  /// - Parameters:
  /// 	- message: The message to be logged that can be used with any string interpolation literal.
  /// 	- file: The file this log message originates from (defaults to `#file`).
  /// 	- function: The function this log message originates from (defaults to `#function`).
  /// 	- line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  ///
  @discardableResult
  public func fault(_ message: LogMessage, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> Log.Item? {
    log(message: message, type: .fault, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Creates a scope object that can assign log messages to itself.
  ///
  /// Scope provides a mechanism for grouping log messages in your program.
  ///
  ///		let logger = DLog()
  ///		logger.scope("Auth") { scope in
  ///			scope.log("message")
  ///		}
  ///
  /// - Parameters:
  /// 	- name: The name of new scope object.
  /// 	- file: The file this log message originates from (defaults to `#file`).
  /// 	- function: The function this log message originates from (defaults to `#function`).
  /// 	- line: The line this log message originates (defaults to `#line`).
  /// 	- closure: A closure to be executed with the scope. The block takes a single `LogScope` parameter and has no return value.
  ///
  /// - Returns: An `LogScope` object for the new scope.
  ///
  @discardableResult
  public func scope(_ name: String, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line, closure: (@Sendable (LogScope) -> Void)? = nil) -> LogScope? {
    guard let logger = logger.value, logger.isEnabled == true else {
      return nil
    }
    let location = LogLocation(fileID: fileID, file: file, function: function, line: line)
    let scope = LogScope(name: name, logger: logger, category: category, config: config, metadata: metadata.value, location: location)
    if let closure {
      scope.enter(fileID: fileID, file: file, function: function, line: line)
      closure(scope)
      scope.leave(fileID: fileID, file: file, function: function, line: line)
    }
    return scope
  }
  
  /// Creates an interval object that logs a detailed message with accumulated statistics.
  ///
  /// Logs a point of interest in your code as time intervals for debugging performances.
  ///
  ///    let logger = DLog()
  ///    logger.interval("Sorting") {
  ///      ...
  ///    }
  ///
  /// - Parameters:
  ///   - name: The name of new interval object.
  ///   - file: The file this log message originates from (defaults to `#file`).
  ///   - function: The function this log message originates from (defaults to `#function`).
  ///   - line: The line this log message originates (defaults to `#line`).
  ///   - closure: A closure to be executed with the interval.
  ///
  /// - Returns: An `LogInterval` object for the new interval.
  ///
  @discardableResult
  public func interval(_ name: StaticString, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line, closure: (@Sendable () -> Void)? = nil) -> LogInterval? {
    guard let logger = logger.value, logger.isEnabled else {
      return nil
    }
    let location = LogLocation(fileID: fileID, file: file, function: function, line: line)
    let interval = LogInterval(logger: logger, name: name, category: category, config: config, stack: stack(), metadata: metadata.value, location: location)
    if let closure {
      interval.begin(fileID: location.fileID, file: location.file, function: location.function, line: location.line)
      closure()
      interval.end(fileID: location.fileID, file: location.file, function: location.function, line: location.line)
    }
    return interval
  }
}
