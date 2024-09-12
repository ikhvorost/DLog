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

fileprivate class ScopeStack {
  static let shared = ScopeStack()
  
  private var scopes = [LogScope]()
  
  private func _stack(level: Int) -> [Bool] {
    var stack = [Bool](repeating: false, count: level - 1)
    scopes.map { $0.level }
      .map { $0 - 1}
      .forEach {
        if $0 < stack.count {
          stack[$0] = true
        }
      }
    return stack
  }
  
  func stack(level: Int) -> [Bool] {
    synchronized(self) {
      _stack(level: level)
    }
  }
  
  func append(scope: LogScope, complete: (Int, [Bool]) -> Void) {
    synchronized(self) {
      guard scopes.contains(scope) == false else {
        return
      }
      let level = (scopes.map { $0.level }.max() ?? 0) + 1
      let stack = _stack(level: level)
      scopes.append(scope)
      complete(level, stack)
    }
  }
  
  func remove(scope: LogScope, complete: ([Bool]) -> Void) {
    synchronized(self) {
      guard let index = scopes.firstIndex(of: scope) else {
        return
      }
      scopes.remove(at: index)
      let stack = _stack(level: scope.level)
      complete(stack)
    }
  }
}

/// An object that represents a scope triggered by the user.
///
/// Scope provides a mechanism for grouping log messages.
///
public class LogScope: Log {
  let activity = Activity()
  
  public let name: String
  public fileprivate(set) var level = 0
  public fileprivate(set) var time = Date()
  public fileprivate(set) var duration: TimeInterval = 0
  
  var item: Item? {
    guard level > 0 else {
      return nil
    }
    let stack = ScopeStack.shared.stack(level: level)
    return item(stack: stack)
  }
  
  init(name: String, logger: DLog, category: String, config: LogConfig, metadata: Metadata) {
    self.name = name
    super.init(logger: logger, category: category, config: config, metadata: metadata)
    self._scope = self
  }
  
  private func item(stack: [Bool]) -> Item {
    Item(name: name, category: category, level: level, stack: stack, time: time, duration: duration, config: config, activity: activity)
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
  public func enter() {
    ScopeStack.shared.append(scope: self) { level, stack in
      self.level = level
      time = Date()
      duration = 0
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
  public func leave() {
    ScopeStack.shared.remove(scope: self) { stack in
      duration = -time.timeIntervalSinceNow
      let item = item(stack: stack)
      logger.output?.leave(item: item)
      level = 0
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
    
    public var description: String {
      let isStart = duration == 0
      
      var sign = { "\(self.config.sign)" }
      var time = isStart
        ? LogItem.dateFormatter.string(from: time)
        : LogItem.dateFormatter.string(from: time.addingTimeInterval(duration))
      let ms = !isStart ? "(\(stringFromTimeInterval(duration)))" : nil
      var category = { "[\(self.category)]" }
      var level = { String(format: "[%02d]", self.level) }
      let padding: () -> String = {
        self.stack
          .map { $0 ? "| " : "  " }
          .joined()
          .appending(isStart ? "┌" : "└")
      }
      var text = "[\(name)] \(ms ?? "")"
      
      switch config.style {
        case .emoji, .plain:
          break
          
        case .colored:
          sign = { "\(self.config.sign)".color(.dim) }
          time = time.color(.dim)
          level = { String(format: "[%02d]", self.level).color(.dim) }
          category = { self.category.color(.textBlue) }
          text = "[\(name.color(.textMagenta))] \((ms ?? "").color(.dim))"
      }
      
      let items: [(LogOptions, () -> String)] = [
        (.sign, sign),
        (.time, { time }),
        (.level, level),
        (.category, category),
        (.padding, padding),
      ]
      let prefix = LogItem.logPrefix(items: items, options: config.options)
      return prefix.isEmpty ? text : "\(prefix) \(text)"
    }
  }
}
