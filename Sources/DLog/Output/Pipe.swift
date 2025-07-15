//
//  Pipe.swift
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


public struct Pipe {
  
  let outputs: [OutputProtocol]
  
  public init(@OutputBuilder _ outputs: () -> [OutputProtocol]) {
    self.outputs = outputs()
  }
}

extension Pipe: OutputProtocol {
  
  public func log(item: LogItem) {
    for output in outputs {
      if let filter = output as? Filter, filter.isPipeable(item) == false {
        break
      }
      output.log(item: item)
    }
  }
}
