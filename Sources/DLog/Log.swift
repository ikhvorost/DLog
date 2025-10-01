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


/// Base logger class
public class Log: @unchecked Sendable {
  let logger = Atomic<DLog?>(nil)
  let category: String
  let config: LogConfig
  
  /// The metadata to attach to the log messages.
  public let metadata: LogMetadata
  
  init(logger: DLog?, category: String, config: LogConfig, metadata: Metadata) {
    self.logger.value = logger
    self.category = category
    self.config = config
    self.metadata = LogMetadata(data: metadata)
  }
  
  var scope: LogScope? {
    self as? LogScope
  }
  
  private func log(message: LogMessage, type: LogType, location: LogLocation) -> LogItem? {
    guard logger.value?.isEnabled == true else {
      return nil
    }
    let item = LogItem(category: category, stack: scope?.stack, type: type, location: location, metadata: metadata.value, message: "\(message)", config: config, activity: scope?.activity)
    logger.value?.log(item: item)
    return item
  }
  
  /// Logs a message that is essential to troubleshoot problems later.
  ///
  /// This method logs the message using the default log level.
  ///
  ///   - Parameters:
  ///     - message: The message to be logged that can be used with any string interpolation literal.
  ///     - fileID: The file ID of the source file (defaults to `#fileID`).
  ///     - file: The file this log message originates from (defaults to `#file`).
  ///     - function: The function this log message originates from (defaults to `#function`).
  ///     - line: The line this log message originates (defaults to `#line`).
  ///
  ///   - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func log(_ message: LogMessage, fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    log(message: message, type: .log, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs a message that is essential to troubleshoot problems later.
  ///
  /// You can pass zero or more items to the function. The textual representation for each item is the same as that
  /// obtained by calling `String(describing: item)`.
  ///
  ///   - Parameters:
  ///     - items: Zero or more items to print.
  ///     - fileID: The file ID of the source file (defaults to `#fileID`).
  ///     - file: The file this log message originates from (defaults to `#file`).
  ///     - function: The function this log message originates from (defaults to `#function`).
  ///     - line: The line this log message originates (defaults to `#line`).
  ///
  ///   - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func log(_ items: Any..., fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    log(message: LogMessage(items: items), type: .log, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs trace information to help debug problems during the development of your code.
  ///
  /// Use it during development to record information that might aid you in debugging problems later.
  ///
  ///   - Parameters:
  ///     - message: The message to be logged that can be used with any string interpolation literal.
  ///     - fileID: The file ID of the source file (defaults to `#fileID`).
  ///     - file: The file this log message originates from (defaults to `#file`).
  ///     - function: The function this log message originates from (defaults to `#function`).
  ///     - line: The line this log message originates (defaults to `#line`).
  ///
  ///   - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func trace(_ message: LogMessage = "", fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogTraceItem? {
    guard logger.value?.isEnabled == true else {
      return nil
    }
    let location = LogLocation(fileID: fileID, file: file, function: function, line: line)
    let stackAddresses = Thread.callStackReturnAddresses.dropFirst(2)
    let item = LogTraceItem(category: category, stack: scope?.stack, location: location, metadata: metadata.value, message: "\(message)", config: config, activity: scope?.activity, stackAddresses: stackAddresses)
    logger.value?.log(item: item)
    return item
  }
  
  /// Logs trace information to help debug problems during the development of your code.
  ///
  /// You can pass zero or more items to the function. The textual representation for each item is the same as that
  /// obtained by calling `String(describing: item)`.
  ///
  ///   - Parameters:
  ///     - items: Zero or more items to print.
  ///     - fileID: The file ID of the source file (defaults to `#fileID`).
  ///     - file: The file this log message originates from (defaults to `#file`).
  ///     - function: The function this log message originates from (defaults to `#function`).
  ///     - line: The line this log message originates (defaults to `#line`).
  ///
  ///   - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func trace(_ items: Any..., fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogTraceItem? {
    trace(LogMessage(items: items), fileID: fileID, file: file, function: function, line: line)
  }
  
  /// Logs a message to help debug problems during the development of your code.
  ///
  /// Use this method during development to record information that might aid you in debugging problems later.
  ///
  ///   - Parameters:
  ///     - message: The message to be logged that can be used with any string interpolation literal.
  ///     - fileID: The file ID of the source file (defaults to `#fileID`).
  ///     - file: The file this log message originates from (defaults to `#file`).
  ///     - function: The function this log message originates from (defaults to `#function`).
  ///     - line: The line this log message originates (defaults to `#line`).
  ///
  ///   - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func debug(_ message: LogMessage, fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    log(message: message, type: .debug, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs a message to help debug problems during the development of your code.
  ///
  /// You can pass zero or more items to the function. The textual representation for each item is the same as that
  /// obtained by calling `String(describing: item)`.
  ///
  /// - Parameters:
  ///   - items: Zero or more items to print.
  ///   - fileID: The file ID of the source file (defaults to `#fileID`).
  ///   - file: The file this log message originates from (defaults to `#file`).
  ///   - function: The function this log message originates from (defaults to `#function`).
  ///   - line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func debug(_ items: Any..., fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    debug(LogMessage(items: items), fileID: fileID, file: file, function: function, line: line)
  }
  
  /// Logs a message that is helpful, but not essential, to diagnose issues with your code.
  ///
  /// Use this method to capture information messages and helpful data.
  ///
  ///   - Parameters:
  ///     - message: The message to be logged that can be used with any string interpolation literal.
  ///     - fileID: The file ID of the source file (defaults to `#fileID`).
  ///     - file: The file this log message originates from (defaults to `#file`).
  ///     - function: The function this log message originates from (defaults to `#function`).
  ///     - line: The line this log message originates (defaults to `#line`).
  ///
  ///   - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func info(_ message: LogMessage, fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    log(message: message, type: .info, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs a message that is helpful, but not essential, to diagnose issues with your code.
  ///
  /// You can pass zero or more items to the function. The textual representation for each item is the same as that
  /// obtained by calling `String(describing: item)`.
  ///
  /// - Parameters:
  ///   - items: Zero or more items to print.
  ///   - fileID: The file ID of the source file (defaults to `#fileID`).
  ///   - file: The file this log message originates from (defaults to `#file`).
  ///   - function: The function this log message originates from (defaults to `#function`).
  ///   - line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func info(_ items: Any..., fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    info(LogMessage(items: items), fileID: fileID, file: file, function: function, line: line)
  }
  
  /// Logs a warning that occurred during the execution of your code.
  ///
  /// Use this method to capture information about things that might result in an error.
  ///
  ///   - Parameters:
  ///     - message: The message to be logged that can be used with any string interpolation literal.
  ///     - fileID: The file ID of the source file (defaults to `#fileID`).
  ///     - file: The file this log message originates from (defaults to `#file`).
  ///     - function: The function this log message originates from (defaults to `#function`).
  ///     - line: The line this log message originates (defaults to `#line`).
  ///
  ///   - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func warning(_ message: LogMessage, fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    log(message: message, type: .warning, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs a warning that occurred during the execution of your code.
  ///
  /// You can pass zero or more items to the function. The textual representation for each item is the same as that
  /// obtained by calling `String(describing: item)`.
  ///
  /// - Parameters:
  ///   - items: Zero or more items to print.
  ///   - fileID: The file ID of the source file (defaults to `#fileID`).
  ///   - file: The file this log message originates from (defaults to `#file`).
  ///   - function: The function this log message originates from (defaults to `#function`).
  ///   - line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func warning(_ items: Any..., fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    warning(LogMessage(items: items), fileID: fileID, file: file, function: function, line: line)
  }
  
  /// Logs an error that occurred during the execution of your code.
  ///
  /// Use this method to report errors.
  ///
  ///   - Parameters:
  ///     - message: The message to be logged that can be used with any string interpolation literal.
  ///     - fileID: The file ID of the source file (defaults to `#fileID`).
  ///     - file: The file this log message originates from (defaults to `#file`).
  ///     - function: The function this log message originates from (defaults to `#function`).
  ///     - line: The line this log message originates (defaults to `#line`).
  ///
  ///   - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func error(_ message: LogMessage, fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    log(message: message, type: .error, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs an error that occurred during the execution of your code.
  ///
  /// You can pass zero or more items to the function. The textual representation for each item is the same as that
  /// obtained by calling `String(describing: item)`.
  ///
  /// - Parameters:
  ///   - items: Zero or more items to print.
  ///   - fileID: The file ID of the source file (defaults to `#fileID`).
  ///   - file: The file this log message originates from (defaults to `#file`).
  ///   - function: The function this log message originates from (defaults to `#function`).
  ///   - line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func error(_ items: Any..., fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    error(LogMessage(items: items), fileID: fileID, file: file, function: function, line: line)
  }
  
  private func assert(_ condition: () -> Bool, message: LogMessage, fileID: StaticString, file: StaticString, function: StaticString, line: UInt) -> LogItem? {
    guard logger.value?.isEnabled == true && condition() == false else {
      return nil
    }
    return log(message: message, type: .assert, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs a traditional C-style assert notice with an optional message.
  ///
  /// Use this function for internal sanity checks.
  ///
  ///   - Parameters:
  ///     - condition: The condition to test.
  ///     - message: A string to print if `condition` is evaluated to `false`. The default is an empty string.
  ///     - fileID: The file ID of the source file (defaults to `#fileID`).
  ///     - file: The file this log message originates from (defaults to `#file`).
  ///     - function: The function this log message originates from (defaults to `#function`).
  ///     - line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func assert(_ condition: @autoclosure () -> Bool, _ message: LogMessage = "", fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    assert(condition, message: message, fileID: fileID, file: file, function: function, line: line)
  }
  
  /// Logs a traditional C-style assert notice with an optional message.
  ///
  /// You can pass zero or more items to the function. The textual representation for each item is the same as that
  /// obtained by calling `String(describing: item)`.
  ///
  /// - Parameters:
  ///   - condition: The condition to test.
  ///   - items: Zero or more items to print.
  ///   - fileID: The file ID of the source file (defaults to `#fileID`).
  ///   - file: The file this log message originates from (defaults to `#file`).
  ///   - function: The function this log message originates from (defaults to `#function`).
  ///   - line: The line this log message originates (defaults to `#line`).
  ///
  /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func assert(_ condition: @autoclosure () -> Bool, _ items: Any..., fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    assert(condition, message: LogMessage(items: items), fileID: fileID, file: file, function: function, line: line)
  }
  
  /// Logs a bug or fault that occurred during the execution of your code.
  ///
  /// Use this method to capture critical errors that occurred during the execution of your code.
  ///
  ///   - Parameters:
  ///     - message: The message to be logged that can be used with any string interpolation literal.
  ///     - fileID: The file ID of the source file (defaults to `#fileID`).
  ///     - file: The file this log message originates from (defaults to `#file`).
  ///     - function: The function this log message originates from (defaults to `#function`).
  ///     - line: The line this log message originates (defaults to `#line`).
  ///
  ///   - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func fault(_ message: LogMessage, fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    log(message: message, type: .fault, location: LogLocation(fileID: fileID, file: file, function: function, line: line))
  }
  
  /// Logs a bug or fault that occurred during the execution of your code.
  ///
  /// You can pass zero or more items to the function. The textual representation for each item is the same as that
  /// obtained by calling `String(describing: item)`.
  ///
  ///   - Parameters:
  ///     - items: Zero or more items to print.
  ///     - fileID: The file ID of the source file (defaults to `#fileID`).
  ///     - file: The file this log message originates from (defaults to `#file`).
  ///     - function: The function this log message originates from (defaults to `#function`).
  ///     - line: The line this log message originates (defaults to `#line`).
  ///
  ///   - Returns: Returns an optional string value indicating whether a log message is generated and processed.
  @discardableResult
  public func fault(_ items: Any..., fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> LogItem? {
    fault(LogMessage(items: items), fileID: fileID, file: file, function: function, line: line)
  }
  
  /// Creates a scope object that can assign log messages to itself.
  ///
  /// Scope provides a mechanism for grouping log messages in your program.
  ///
  ///		  let logger = DLog()
  ///		  logger.scope("Auth") { scope in
  ///		    scope.log("message")
  ///       ...
  ///	      }
  ///
  ///   - Parameters:
  /// 	  - name: The name of new scope object.
  ///     - fileID: The file ID of the source file (defaults to `#fileID`).
  /// 	  - file: The file this log message originates from (defaults to `#file`).
  /// 	  - function: The function this log message originates from (defaults to `#function`).
  /// 	  - line: The line this log message originates (defaults to `#line`).
  /// 	  - closure: A closure to be executed with the scope. The block takes a single `LogScope` parameter and has no return value.
  ///
  /// - Returns: An `LogScope` object for the new scope.
  @discardableResult
  public func scope(_ name: String, fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, closure: ((LogScope) -> Void)? = nil) -> LogScope? {
    guard let logger = logger.value, logger.isEnabled == true else {
      return nil
    }
    let scope = LogScope(name: name, logger: logger, category: category, config: config, metadata: metadata.value, activity: scope?.activity)
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
  ///   - Parameters:
  ///     - name: The name of new interval object.
  ///     - fileID: The file ID of the source file (defaults to `#fileID`).
  ///     - file: The file this log message originates from (defaults to `#file`).
  ///     - function: The function this log message originates from (defaults to `#function`).
  ///     - line: The line this log message originates (defaults to `#line`).
  ///     - closure: A closure to be executed with the interval.
  ///
  ///   - Returns: An `LogInterval` object for the new interval.
  @discardableResult
  public func interval(_ name: StaticString, fileID: StaticString = #fileID, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogInterval? {
    guard let logger = logger.value, logger.isEnabled else {
      return nil
    }
    let location = LogLocation(fileID: fileID, file: file, function: function, line: line)
    let interval = LogInterval(logger: logger, name: name, category: category, config: config, stack: scope?.stack, metadata: metadata.value, location: location)
    if let closure {
      interval.begin(fileID: location.fileID, file: location.file, function: location.function, line: location.line)
      closure()
      interval.end(fileID: location.fileID, file: location.file, function: location.function, line: location.line)
    }
    return interval
  }
}
