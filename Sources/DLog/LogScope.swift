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


/// An object that represents a scope triggered by the user.
///
/// Scope provides a mechanism for grouping log messages.
///
public final class LogScope: Log, @unchecked Sendable {
  
  private static let scopes = Atomic([LogScope]())
  
  private let activity = Atomic(os_activity_scope_state_s())
  private let start = Atomic(Date())
  
  var stack: [Bool]? {
    level > 0 ? Self.stack(scopes: Self.scopes.value, level: level) : nil
  }
  
  public let name: String
  
  // Level
  public var level: Int {
    _level.value
  }
  private let _level = Atomic(0)
  
  // Duration
  public var duration: TimeInterval {
    _duration.value
  }
  private let _duration = Atomic(0.0)
  
  private static func stack(scopes: [LogScope], level: Int) -> [Bool] {
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

  init(name: String, logger: DLog, category: String, config: LogConfig, metadata: Metadata, location: LogLocation) {
    self.name = name
    super.init(logger: logger, category: category, config: config, metadata: metadata)
  }
  
  private func item(type: LogType, location: LogLocation, stack: [Bool]) -> LogScopeItem {
    let message = LogMessage(stringLiteral: name)
    return LogScopeItem(category: category, stack: stack, type: type, location: location, metadata: metadata.value, message: message, config: config, activity: activity, level: level, duration: duration)
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
  public func enter(fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) {
    Self.scopes.sync {
      guard $0.contains(self) == false else {
        return
      }
      
      let level = ($0.map { $0.level }.max() ?? 0) + 1
      let stack = Self.stack(scopes: $0, level: level)
      $0.append(self)
      
      _level.value = level
      start.value = Date()
      _duration.value = 0
      
      let location = LogLocation(fileID: fileID, file: file, function: function, line: line)
      let item = item(type: .scopeEnter, location: location, stack: stack)
      logger.value?.log(item: item)
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
  public func leave(fileID: String = #fileID, file: String = #file, function: String = #function, line: UInt = #line) {
    Self.scopes.sync {
      guard let index = $0.firstIndex(of: self) else {
        return
      }
      $0.remove(at: index)
      let stack = Self.stack(scopes: $0, level: level)
      
      _level.value = 0
      _duration.value = -start.value.timeIntervalSinceNow
      
      let location = LogLocation(fileID: fileID, file: file, function: function, line: line)
      let item = item(type: .scopeLeave, location: location, stack: stack)
      logger.value?.log(item: item)
    }
  }
}

extension LogScope: Equatable {
  
  public static func == (lhs: LogScope, rhs: LogScope) -> Bool {
    lhs === rhs
  }
}
