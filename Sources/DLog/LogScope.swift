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
public class LogScope : LogItem {
    let uid = UUID()
    var os_state = os_activity_scope_state_s()
    @Atomic var entered = false
    
    /// A global level of a scope
    internal(set) public var level: Int = 0
    
    /// A time duration of a scope
    private(set) public var duration: TimeInterval = 0
        
    init(params: LogParams, file: String, funcName: String, line: UInt, name: @escaping () -> LogMessage) {
        super.init(params: params, type: .scope, file: file, funcName: funcName, line: line, message: name)
        self.params.scope = self
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
        guard !entered else { return }
        entered.toggle()
        
        time = Date()
        duration = 0
        params.logger.enter(scope: self)
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
        guard entered else { return }
        entered.toggle()
        
        duration = -time.timeIntervalSinceNow
        
        params.logger.leave(scope: self)
    }
}
