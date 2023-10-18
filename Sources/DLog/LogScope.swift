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
            scopes.first { $0.level == level } != nil
        }
    }
    
    func append(_ scope: LogScope, closure: () -> Void) {
        synchronized(self) {
            guard scopes.contains(scope) == false else {
                return
            }
            let maxLevel = scopes.map{$0.level}.max() ?? 0
            scope.level = maxLevel + 1
            scopes.append(scope)
            closure()
        }
    }
    
    func remove(_ scope: LogScope, closure: () -> Void) {
        synchronized(self) {
            guard let index = scopes.firstIndex(of: scope) else {
                return
            }
            closure()
            scopes.remove(at: index)
            scope.level = 0
        }
    }
}

/// An object that represents a scope triggered by the user.
///
/// Scope provides a mechanism for grouping log messages.
///
public class LogScope: LogProtocol {
    @Atomic var time = Date()
  
    var os_state = os_activity_scope_state_s()
    
    /// A global level in the stack.
    @objc
    public internal(set) var level: Int = 0
    
    /// A time duration.
    @Atomic public private(set) var duration: TimeInterval = 0
    
    /// Scope name.
    @objc
    public let name: String
    
    init(name: String, logger: DLog, category: String, config: LogConfig, metadata: Metadata) {
        self.name = name
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
      time = Date()
      duration = 0
      logger.enter(scope: self)
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
      duration = -time.timeIntervalSinceNow
      logger.leave(scope: self)
    }
}
