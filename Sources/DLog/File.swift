//
//  File.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/08/12.
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

/// Target output for a file.
///
public class File: LogOutput {
  private let file: FileHandle?
  private let queue = DispatchQueue(label: "dlog.file.queue")
  
  /// Initializes and returns the target file output object associated with the specified file.
  ///
  /// You can use the file output to write text messages to a file by a provided path.
  ///
  ///		let file = File(path: "/users/user/dlog.txt")
  /// 	let logger = DLog(file)
  ///		logger.info("It's a file")
  ///
  /// - Parameters:
  /// 	- path: The path to the file to access.
  /// 	- append: `true` if the file output object should append log messages to the end of an existing file or `false` if you want to clear one.
  /// 	- source: A source output object, if it is omitted, the file output takes `Text` plain output as a source output.
  ///
  public init(path: String, append: Bool = false) {
    let fileManager = FileManager.default
    if append == false {
      try? fileManager.removeItem(atPath: path)
    }
    
    if fileManager.fileExists(atPath: path) == false {
      let dir = NSString(string: path).deletingLastPathComponent
      try? fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
      
      fileManager.createFile(atPath: path, contents: nil, attributes: nil)
    }
    
    file = FileHandle(forWritingAtPath: path)
    
    if append {
      file?.seekToEndOfFile()
    }
  }
  
  private func write(_ text: @escaping @autoclosure () -> String) {
    queue.async {
      let text = text()
      if !text.isEmpty, let data = (text + "\n").data(using: .utf8) {
        self.file?.write(data)
      }
    }
  }
  
  // MARK: - LogOutput
  
  override func log(item: LogItem) {
    super.log(item: item)
    write(item.text())
  }
  
  override func enter(scopeItem: LogScopeItem) {
    super.enter(scopeItem: scopeItem)
    write("\(scopeItem)")
  }
  
  override func leave(scopeItem: LogScopeItem) {
    super.leave(scopeItem: scopeItem)
    write("\(scopeItem)")
  }
  
  override func begin(interval: LogInterval) {
    super.begin(interval: interval)
  }
  
  override func end(interval: LogInterval) {
    super.end(interval: interval)
    write(interval.text())
  }
}
