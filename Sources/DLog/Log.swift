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
///
@objcMembers
public class Log: NSObject {
  weak var logger: DLog!
  let category: String
  let config: LogConfig
  
  /// Contextual metadata
  public let metadata: LogMetadata
  
  init(logger: DLog?, category: String, config: LogConfig, metadata: Metadata) {
    self.logger = logger
    self.category = category
    self.config = config
    self.metadata = LogMetadata(data: metadata)
  }
  
  private func stack() -> [Bool]? {
    if let scope = self as? LogScope {
      return scope.stack
    }
    return nil
  }
  
  private func log(message: LogMessage, type: LogType, category: String, config: LogConfig, metadata: @autoclosure @escaping () -> [Metadata], location: LogLocation) -> LogItem? {
    guard let output = logger.output else {
      return nil
    }
    let item = LogItem(message: message.text, type: type, category: category, config: config, stack: stack(), metadata: metadata, location: location)
    output.log(item: item)
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
  public func log(_ message: LogMessage, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> LogItem? {
    log(message: message, type: .log, category: category, config: config, metadata: [self.metadata.data], location: LogLocation(fileID, file, function, line))
  }
  
  private func trace(message: LogMessage, traceInfo: TraceInfo, traceConfig: TraceConfig?, location: LogLocation) -> LogItem? {
    var config = config
    if let traceConfig {
      config.traceConfig = traceConfig
    }
    
    let metadata: () -> [Metadata] = {[
      self.metadata.data,
      traceMetadata(location: location, traceInfo: traceInfo, traceConfig: config.traceConfig)
    ]}
    return log(message: message, type: .trace, category: category, config: config, metadata: metadata(), location: location)
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
  public func trace(_ message: LogMessage = "", config: TraceConfig? = nil, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> LogItem? {
    let traceInfo = TraceInfo()
    return trace(message: message, traceInfo: traceInfo, traceConfig: config, location: LogLocation(fileID, file, function, line))
  }
  
  /// Logs trace information to help debug problems during the development of your code.
  @discardableResult
  public func trace(_ message: LogMessage, fileID: String, file: String, function: String, line: UInt) -> LogItem? {
    let traceInfo = TraceInfo()
    return trace(message: message, traceInfo: traceInfo, traceConfig: nil, location: LogLocation(fileID, file, function, line))
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
  public func debug(_ message: LogMessage, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> LogItem? {
    log(message: message, type: .debug, category: category, config: config, metadata: [self.metadata.data],  location: LogLocation(fileID, file, function, line))
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
  public func info(_ message: LogMessage, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> LogItem? {
    log(message: message, type: .info, category: category, config: config, metadata: [self.metadata.data], location: LogLocation(fileID, file, function, line))
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
  public func warning(_ message: LogMessage, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> LogItem? {
    log(message: message, type: .warning, category: category, config: config, metadata: [self.metadata.data], location: LogLocation(fileID, file, function, line))
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
  public func error(_ message: LogMessage, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> LogItem? {
    log(message: message, type: .error, category: category, config: config, metadata: [self.metadata.data], location: LogLocation(fileID, file, function, line))
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
  public func assert(_ condition: @autoclosure () -> Bool, _ message: LogMessage = "", fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> LogItem? {
    guard logger.output != nil && !condition() else {
      return nil
    }
    return log(message: message, type: .assert, category: category, config: config, metadata: [self.metadata.data], location: LogLocation(fileID, file, function, line))
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
  public func fault(_ message: LogMessage, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) -> LogItem? {
    log(message: message, type: .fault, category: category, config: config, metadata: [self.metadata.data], location: LogLocation(fileID, file, function, line))
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
  public func scope(_ name: String, metadata: Metadata? = nil, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line, closure: ((LogScope) -> Void)? = nil) -> LogScope? {
    guard logger.output != nil else {
      return nil
    }
    let location = LogLocation(fileID, file, function, line)
    let scope = LogScope(name: name, logger: logger, category: category, config: config, metadata: metadata, location: location)
    if let block = closure {
      scope.enter(fileID: fileID, file: file, function: function, line: line)
      block(scope)
      scope.leave(fileID: fileID, file: file, function: function, line: line)
    }
    return scope
  }
  
  private func interval(message: String, staticName: StaticString?, intervalConfig: IntervalConfig?, location: LogLocation, closure: (() -> Void)?) -> LogInterval? {
    guard logger.output != nil else {
      return nil
    }
    
    var config = config
    if let intervalConfig {
      config.intervalConfig = intervalConfig
    }
    
    let interval = LogInterval(logger: logger, message: message, staticName: staticName, category: category, config: config, stack: stack(), metadata: metadata.data, location: location)
    if let block = closure {
      interval.begin(fileID: location.fileID, file: location.file, function: location.function, line: location.line)
      block()
      interval.end(fileID: location.fileID, file: location.file, function: location.function, line: location.line)
    }
    return interval
  }
  
  /// Creates an interval object that logs a detailed message with accumulated statistics.
  ///
  /// Logs a point of interest in your code as time intervals for debugging performances.
  ///
  ///		let logger = DLog()
  ///		logger.interval("Sorting") {
  ///			...
  ///		}
  ///
  /// - Parameters:
  /// 	- name: The name of new interval object.
  /// 	- file: The file this log message originates from (defaults to `#file`).
  /// 	- function: The function this log message originates from (defaults to `#function`).
  /// 	- line: The line this log message originates (defaults to `#line`).
  /// 	- closure: A closure to be executed with the interval.
  ///
  /// - Returns: An `LogInterval` object for the new interval.
  ///
  @discardableResult
  public func interval(_ name: StaticString = "", config: IntervalConfig? = nil, fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogInterval? {
    interval(message: "\(name)", staticName: name, intervalConfig: config, location: LogLocation(fileID, file, function, line), closure: closure)
  }
  
  /// Creates an interval object that logs a detailed message with accumulated statistics.
  @discardableResult
  public func interval(message: String, fileID: String, file: String, function: String, line: UInt, closure: (() -> Void)?) -> LogInterval? {
    interval(message: message, staticName: nil, intervalConfig: nil, location: LogLocation(fileID, file, function, line), closure: closure)
  }
}

extension Log {
  
  public class Item: CustomStringConvertible {
    public let time: Date
    public let category: String
    public let stack: [Bool]?
    public let type: LogType
    public let location: LogLocation
    public let metadata: Metadata
    public let message: String
    public let config: LogConfig
    
    init(time: Date, category: String, stack: [Bool]?, type: LogType, location: LogLocation, metadata: Metadata, message: String, config: LogConfig) {
      self.time = time
      self.category = category
      self.stack = stack
      self.type = type
      self.location = location
      self.metadata = metadata
      self.message = message
      self.config = config
    }
    
    func padding() -> String {
      guard let stack else {
        return ""
      }
      return stack
        .map { $0 ? "| " : "  " }
        .joined()
        .appending("├")
    }
    
    func typeText() -> String {
      let tag = LogItem.tags[self.type]!
      return switch config.style {
        case .plain:
          "[\(type.title)]"
          
        case .colored:
          " \(type.title) ".color(tag.colors)
          
        case .emoji:
          "\(type.icon) [\(type.title)]"
      }
    }
    
    func data() -> Metadata? {
      nil
    }
    
    func messageText() -> String {
      let tag = LogItem.tags[self.type]!
      return switch config.style {
        case .plain, .emoji:
          message
          
        case .colored:
          message.color(tag.textColor)
      }
    }
    
    public var description: String {
      var sign = "\(config.sign)"
      var time = LogItem.dateFormatter.string(from: self.time)
      var level = String(format: "[%02d]", self.stack?.count ?? 0)
      var category = "[\(self.category)]"
      var location = "<\(self.location.fileName):\(self.location.line)>"
      var metadata = self.metadata.json()
      var data = data()?.json() ?? ""
      
      switch config.style {
        case .plain, .emoji:
          break
          
        case .colored:
          let tag = LogItem.tags[self.type]!
          
          sign = sign.color(.dim)
          time = time.color(.dim)
          level = level.color(.dim)
          category = category.color(.textBlue)
          location = location.color([.dim, tag.textColor])
          metadata = metadata.color(.dim)
          data = data.color(.dim)
      }
      
      let items: [(LogOptions, String)] = [
        (.sign, sign),
        (.time, time),
        (.level, level),
        (.category, category),
        (.padding, padding()),
        (.type, typeText()),
        (.location, location),
        (.metadata, metadata),
        (.data, data),
        (.message, messageText()),
      ]
      return LogItem.logPrefix(items: items, options: config.options)
    }
  }
}
