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

class ScopeStack {
  static let shared = ScopeStack()
  
  private var scopes = [LogScope]()
  
  func exists(level: Int) -> Bool {
    synchronized(self) {
      scopes.first { $0.item.level == level } != nil
    }
  }
  
  func append(scope: LogScope, closure: (Int) -> Void) {
    synchronized(self) {
      guard scopes.contains(scope) == false else {
        return
      }
      let maxLevel = scopes.map { $0.item.level } .max() ?? 0
      scopes.append(scope)
      closure(maxLevel + 1)
    }
  }
  
  func remove(scope: LogScope, closure: () -> Void) {
    synchronized(self) {
      guard let index = scopes.firstIndex(of: scope) else {
        return
      }
      closure()
      scopes.remove(at: index)
    }
  }
}

public class Activity {
  public var os_state = os_activity_scope_state_s()
}

public struct LogScopeItem: Sendable, CustomStringConvertible {
  public let activity = Activity()
  public let name: String
  public let category: String
  
  public fileprivate(set) var level: Int = 0
  public fileprivate(set) var time = Date()
  public fileprivate(set) var duration: TimeInterval = 0
  
  let config: LogConfig
  
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
      let text = (1..<self.level)
        .map { ScopeStack.shared.exists(level: $0) ? "| " : "  " }
        .joined()
      return "\(text)\(isStart ? "┌" : "└")"
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

/// An object that represents a scope triggered by the user.
///
/// Scope provides a mechanism for grouping log messages.
///
public class LogScope: Log {
  var item: LogScopeItem
  
  init(name: String, logger: DLog, category: String, config: LogConfig, metadata: Metadata) {
    item = LogScopeItem(name: name, category: category, config: config)
    super.init(logger: logger, category: category, config: config, metadata: metadata)
    self._scope = self
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
    ScopeStack.shared.append(scope: self) { level in
      item.time = Date()
      item.duration = 0
      item.level = level
      logger.output?.enter(scopeItem: item)
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
    ScopeStack.shared.remove(scope: self) {
      item.duration = -item.time.timeIntervalSinceNow
      logger.output?.leave(scopeItem: item)
      item.level = 0
    }
  }
}
