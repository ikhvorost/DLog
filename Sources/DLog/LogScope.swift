//
//  LogScope.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2021/12/08.
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


fileprivate class Stack {
  var scopes = [LogScope]()
}

/// An object that represents a scope triggered by the user.
///
/// Scope provides a mechanism for grouping log messages.
///
public class LogScope: Log {
  private static var stack = Stack()
  
  private let activity = Activity()
  private var location: LogLocation
  
  public let name: String
  public fileprivate(set) var level = 0
  public fileprivate(set) var time = Date()
  public fileprivate(set) var duration: TimeInterval = 0
  
  var item: Item? {
    synchronized(Self.stack) {
      guard level > 0 else {
        return nil
      }
      let stack = Self.stack(level: level)
      return item(stack: stack)
    }
  }
  
  private static func stack(level: Int) -> [Bool] {
    var stack = [Bool](repeating: false, count: level - 1)
    Self.stack.scopes.map { $0.level }
      .map { $0 - 1}
      .forEach {
        if $0 < stack.count {
          stack[$0] = true
        }
      }
    return stack
  }
  
  init(name: String, logger: DLog, category: String, config: LogConfig, metadata: Metadata?, location: LogLocation) {
    self.name = name
    self.location = location
    super.init(logger: logger, category: category, config: config, metadata: metadata ?? logger.metadata.data)
  }
  
  private func item(stack: [Bool]) -> Item {
    Item(name: name,
         category: category,
         level: level,
         stack: stack,
         time: time,
         duration: duration,
         config: config,
         activity: activity,
         metadata: metadata.data,
         location: location)
  }
  
  /// Start a scope.
  ///
  /// A scope can be created and then used for logging grouped log messages.
  ///
  ///     let logger = DLog()
  ///     let scope = logger.scope("Auth")
  ///     scope.enter()
  ///
  ///     scope.log("message")
  ///     ...
  ///
  ///     scope.leave()
  ///
  @objc
  public func enter(fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) {
    synchronized(Self.stack) {
      guard Self.stack.scopes.contains(self) == false else {
        return
      }
      let level = (Self.stack.scopes.map { $0.level }.max() ?? 0) + 1
      let stack = Self.stack(level: level)
      Self.stack.scopes.append(self)
      
      self.level = level
      time = Date()
      duration = 0
      location = LogLocation(fileID, file, function, line)
      
      let item = item(stack: stack)
      logger.output?.enter(item: item)
    }
  }
  
  /// Finish a scope.
  ///
  /// A scope can be created and then used for logging grouped log messages.
  ///
  ///     let logger = DLog()
  ///     let scope = logger.scope("Auth")
  ///     scope.enter()
  ///
  ///     scope.log("message")
  ///     ...
  ///
  ///     scope.leave()
  ///
  @objc
  public func leave(fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) {
    synchronized(Self.stack) {
      guard let index = Self.stack.scopes.firstIndex(of: self) else {
        return
      }
      Self.stack.scopes.remove(at: index)
      let stack = Self.stack(level: level)
      
      duration = -time.timeIntervalSinceNow
      location = LogLocation(fileID, file, function, line)
      
      let item = item(stack: stack)
      logger.output?.leave(item: item)
    }
  }
}

extension LogScope {
  
  public class Activity {
    public var os_state = os_activity_scope_state_s()
  }
  
  public struct Item: CustomStringConvertible {
    public let name: String
    public let category: String
    public let level: Int
    public let stack: [Bool]
    public let time: Date
    public let duration: TimeInterval
    public let config: LogConfig
    public let activity: Activity
    public let metadata: Metadata
    public let location: LogLocation
    
    public var description: String {
      let isStart = duration == 0
      
      var sign = { "\(self.config.sign)" }
      var time = isStart
        ? LogItem.dateFormatter.string(from: time)
        : LogItem.dateFormatter.string(from: time.addingTimeInterval(duration))
      var category = { "[\(self.category)]" }
      var level = { String(format: "[%02d]", self.level) }
      let padding: () -> String = {
        self.stack
          .map { $0 ? "| " : "  " }
          .joined()
          .appending(isStart ? "┌" : "└")
      }
      var type = { "" }
      let ms = isStart ? nil : "(\(stringFromTimeInterval(duration)))"
      var scope = { "[\(name)] \(ms ?? "")" }
      var location = { "<\(self.location.fileName):\(self.location.line)>" }
      var metadata = { self.metadata.json() }
      
      switch config.style {
        case .plain:
          break
          
        case .colored:
          sign = { "\(self.config.sign)".color(.dim) }
          time = time.color(.dim)
          level = { String(format: "[%02d]", self.level).color(.dim) }
          category = { self.category.color(.textBlue) }
          
          let l = location
          location = { l().color(.dim) }
          
          let m = metadata
          metadata = { m().color(.dim) }
          
          scope = { "[\(name.color(.textMagenta))] \((ms ?? "").color(.dim))" }
          
        case .emoji:
          type = { "\(isStart ? "⬇️" : "⬆️")" }
      }
      
      let items: [(LogOptions, () -> String)] = [
        (.sign, sign),
        (.time, { time }),
        (.level, level),
        (.category, category),
        (.padding, padding),
        (.type, type),
        (.scope, scope),
        (.location, location),
        (.metadata, metadata)
      ]
      return LogItem.logPrefix(items: items, options: config.options)
    }
  }
}
