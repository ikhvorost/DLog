//
//  Standard.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/08/03.
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

/// A target output that can output text messages to POSIX streams.
///
public class Standard: LogOutput {
  
  let stream: UnsafeMutablePointer<FILE>
  let queue = DispatchQueue(label: "dlog.std.queue")
  
  /// Creates `Standard` output object.
  ///
  /// 	let logger = DLog(Standard())
  /// 	logger.info("It's standard output")
  ///
  /// - Parameters:
  ///		- stream: POSIX stream: `Darwin.stdout`, `Darwin.stderr`.
  ///		- source: A source output (defaults to `.textPlain`).
  ///
  public init(stream: UnsafeMutablePointer<FILE> = Darwin.stdout) {
    self.stream = stream
  }
  
  private func echo(_ text: @escaping @autoclosure () -> String) {
    queue.async {
      let text = text()
      if !text.isEmpty {
        fputs(text + "\n", self.stream)
      }
    }
  }
  
  // MARK: - LogOutput
  
  override func log(item: LogItem) {
    super.log(item: item)
    echo(item.text())
  }
  
  override func enter(item: LogScope.Item) {
    super.enter(item: item)
    echo("\(item)")
  }
  
  override func leave(item: LogScope.Item) {
    super.leave(item: item)
    echo("\(item)")
  }
  
  override func begin(interval: LogInterval.Item) {
    super.begin(interval: interval)
  }
  
  override func end(interval: LogInterval.Item) {
    super.end(interval: interval)
    echo("\(interval)")
  }
}
