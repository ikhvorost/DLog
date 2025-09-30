//
//  Fork.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2025/05/10.
//  Copyright © 2025 Iurii Khvorost. All rights reserved.
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

/// Represents the fork output that allows for running multiple outputs in parallel.
public struct Fork {
  
  private let outputs: [OutputProtocol]
  
  /// Creates instance of the fork output.
  ///
  ///     let logger = DLog {
  ///       Fork {
  ///         StdOut
  ///         File(path: "test.log")
  ///       }
  ///     }
  ///     logger.log("message")
  ///
  ///   - Parameters:
  ///     - outputs: The list of the outputs to run in parallel.
  public init(@OutputBuilder _ outputs: () -> [OutputProtocol]) {
    self.outputs = outputs()
  }
}

extension Fork: OutputProtocol {
  
  /// Logs the log item
  public func log(item: LogItem) {
    DispatchQueue.concurrentPerform(iterations: outputs.count) { [outputs] in
      outputs[$0].log(item: item)
    }
  }
}
