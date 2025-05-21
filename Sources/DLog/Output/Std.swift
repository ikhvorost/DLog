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
public struct Std {
  
  private nonisolated(unsafe) let stream: UnsafeMutablePointer<FILE>
  private let terminator: String

  public init(stream: UnsafeMutablePointer<FILE>, terminator: String = "\n") {
    self.stream = stream
    self.terminator = terminator
  }
}

extension Std: Output {
  
  public func log(item: LogItem) {
    guard item.type != .intervalBegin else {
      return
    }
    
    let text = item.description
    if !text.isEmpty {
      fputs("\(text)\(terminator)", stream)
    }
  }
}

public var StdOut: Std {
  Std(stream: Darwin.stdout)
}

public var StdErr: Std {
  Std(stream: Darwin.stderr)
}
