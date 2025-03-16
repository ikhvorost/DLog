//
//  LogOutput.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/10/14.
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


// Forward pipe
precedencegroup ForwardPipe {
  associativity: left
}
/// Pipeline operator which defines a combined output from two outputs
/// where the first one is a source and second is a target
infix operator => : ForwardPipe


/// A base output class.
@objcMembers
public class LogOutput: NSObject {
  
  /// Creates `Standard` output for `stdout` stream.
  @objc(stdOut)
  public static var stdout: Standard { Standard() }
  
  /// Creates `Standard` output for `stderr` stream.
  @objc(stdErr)
  public static var stderr: Standard { Standard(stream: Darwin.stderr) }
  
  /// Creates `OSLog` output with default subsystem name: `com.dlog.logger`.
  public static var oslog: OSLog { OSLog() }
  
  /// Creates `OSLog` output with a subsystem name.
  public static func oslog(subsystem: String) -> OSLog { OSLog(subsystem: subsystem) }
  
  /// Creates `Filter` output for log items.
  public static func filter(handler: @escaping (Log.Item) -> Bool) -> Filter { Filter(handler: handler) }
    
  /// Creates `File` output with a file path to write.
  public static func file(path: String, append: Bool = false) -> File { File(path: path, append: append) }
  
#if !os(watchOS)
  /// Creates `Net` output for default service name: `DLog`.
  public static var net: Net { Net() }
  
  /// Creates `Net` output for a service name.
  public static func net(name: String) -> Net { Net(name: name) }
#endif
  
  private var next: LogOutput?
  
  /// Forward pipe operator
  ///
  /// The operator allows to create a list of linked outputs.
  ///
  ///   let logger = DLog(.textEmoji => .stdout => .file("dlog.txt"))
  ///
  public static func => (left: LogOutput, right: LogOutput) -> LogOutput {
    left.next = right
    return right
  }
  
  func log(item: Log.Item) {
    next?.log(item: item)
  }
}
