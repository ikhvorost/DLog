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
  static let shared = Stack()
  
  var scopes = [LogScope]()
  
  func stack(level: Int) -> [Bool] {
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
}

/// An object that represents a scope triggered by the user.
///
/// Scope provides a mechanism for grouping log messages.
///
public class LogScope: Log {
  public class Activity {
    public var os_state = os_activity_scope_state_s()
  }
  
  public class Item: Log.Item {
    public let activity: Activity
    public var level: Int
    public var duration: TimeInterval
    
    init(time: Date, category: String, stack: [Bool], type: LogType, location: LogLocation, metadata: Metadata, message: String, config: LogConfig, activity: Activity, level: Int, duration: TimeInterval) {
      self.activity = activity
      self.level = level
      self.duration = duration
      
      super.init(time: time, category: category, stack: stack, type: type, location: location, metadata: metadata, message: message, config: config)
    }
    
    override func padding() -> String {
      let text = super.padding()
      return text.replacingOccurrences(of: "├", with: duration == 0 ? "┌" : "└")
    }
    
    override func typeText() -> String {
      let text = super.typeText()
      return text.replacingOccurrences(of: "[SCOPE]", with: "[SCOPE:\(message)]")
    }
    
    override func data() -> Metadata? {
      duration > 0 ? ["duration": stringFromTimeInterval(duration)] : nil
    }
    
    override func messageText() -> String {
      ""
    }
  }
  
  private let activity = Activity()
  private var location: LogLocation
  
  var start: Date?
  
  public let name: String
  public fileprivate(set) var level = 0
  public fileprivate(set) var duration: TimeInterval = 0
  
  var stack: [Bool]? {
    synchronized(Stack.shared) {
      level > 0 ? Stack.shared.stack(level: level) : nil
    }
  }
  
  init(name: String, logger: DLog, category: String, config: LogConfig, metadata: Metadata?, location: LogLocation) {
    self.name = name
    self.location = location
    super.init(logger: logger, category: category, config: config, metadata: metadata ?? logger.metadata.data)
  }
  
  private func item(type: LogType, stack: [Bool]) -> Item {
    Item(time: Date(), category: category, stack: stack, type: type, location: location, metadata: metadata.data, message: name, config: config, activity: activity, level: level, duration: duration)
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
    synchronized(Stack.shared) {
      guard Stack.shared.scopes.contains(self) == false else {
        return
      }
      let level = (Stack.shared.scopes.map { $0.level }.max() ?? 0) + 1
      let stack = Stack.shared.stack(level: level)
      Stack.shared.scopes.append(self)
      
      self.level = level
      start = Date()
      duration = 0
      location = LogLocation(fileID, file, function, line)
      
      let item = item(type: .scopeEnter, stack: stack)
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
    synchronized(Stack.shared) {
      guard let index = Stack.shared.scopes.firstIndex(of: self) else {
        return
      }
      Stack.shared.scopes.remove(at: index)
      let stack = Stack.shared.stack(level: level)
      
      level = 0
      duration = -(start?.timeIntervalSinceNow ?? 0)
      location = LogLocation(fileID, file, function, line)
      
      let item = item(type: .scopeLeave, stack: stack)
      logger.output?.leave(item: item)
    }
  }
}
