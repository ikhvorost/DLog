//
//  Filter.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/08/30.
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

/// Middleware output for filtering
///
public class Filter: LogOutput {
  
  private let itemHandler: ((Log.Item) -> Bool)?
  private let intervalHandler: ((LogInterval.Item) -> Bool)?
  private let scopeHandler: ((LogScope.Item) -> Bool)?
  
  /// Initializes a filter output that evaluates using a specified block object.
  ///
  /// Represents a pipe middleware output that can filter log messages by available fields of an evaluated object.
  ///
  ///		// Logs debug messages only
  ///		let logger = DLog(.textPlain => .filter { $0.type == .debug } => .stdout)
  ///
  /// - Parameters:
  /// 	- block: The block is applied to the object to be evaluated.
  ///
  public init(item: ((Log.Item) -> Bool)? = nil, interval: ((LogInterval.Item) -> Bool)? = nil, scope: ((LogScope.Item) -> Bool)? = nil) {
    self.itemHandler = item
    self.intervalHandler = interval
    self.scopeHandler = scope
  }
  
  // MARK: - LogOutput
  
  override func log(item: Log.Item) {
    guard itemHandler == nil || itemHandler?(item) == true else {
      return
    }
    super.log(item: item)
  }
  
  override func enter(item: LogScope.Item) {
    guard scopeHandler == nil || scopeHandler?(item) == true else {
      return
    }
    super.enter(item: item)
  }
  
  override func leave(item: LogScope.Item) {
    guard scopeHandler == nil || scopeHandler?(item) == true else {
      return
    }
    super.enter(item: item)
  }
  
  override func begin(interval: LogInterval.Item) {
    guard intervalHandler == nil || intervalHandler?(interval) == true else {
      return
    }
    super.begin(interval: interval)
  }
  
  override func end(interval: LogInterval.Item) {
    guard intervalHandler == nil || intervalHandler?(interval) == true else {
      return
    }
    super.end(interval: interval)
  }
}
