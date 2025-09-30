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


/// Represents the file output that allows for writing in a file.
public struct File {

  private let file: FileHandle?
  
  /// Creates the target file output object associated with the specified file.
  ///
  /// You can use the file output to write text messages to a file by a provided path.
  ///
  ///     let logger = DLog {
  ///       File(path: "log.txt")
  ///     }
  ///     logger.log("message")
  ///
  ///   - Parameters:
  /// 	  - path: The path to the file to access.
  /// 	  - append: `true` if the file output object should append log messages to the end of an existing file or `false`
  ///     if you want to clear one.
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
}

extension File: OutputProtocol {
  /// Logs the log item
  public func log(item: LogItem) {
    guard let file, item.type != .intervalBegin else {
      return
    }
    
    let text = item.description
    if !text.isEmpty, let data = "\(text)\n".data(using: .utf8) {
      file.write(data)
    }
  }
}
