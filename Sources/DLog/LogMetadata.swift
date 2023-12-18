//  LogMetadata.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 03.07.2022.
//  Copyright © 2022 Iurii Khvorost. All rights reserved.
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
//  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

/// Metadata dictionary type
public typealias Metadata = [String : Any]

extension Metadata {
  func json(quotes: Bool = false, pretty: Bool = false) -> String {
    let options: JSONSerialization.WritingOptions = pretty ? [.sortedKeys, .prettyPrinted] : [.sortedKeys]
    guard self.isEmpty == false,
          let data = try? JSONSerialization.data(withJSONObject: self, options: options),
          let json = String(data: data, encoding: .utf8) else {
      return ""
    }
    return quotes ? json : json.replacingOccurrences(of: "\"", with: "")
  }
}

/// Contextual metadata
@objcMembers
public class LogMetadata: NSObject {
  private var _data = Metadata()
  
  init(data: Metadata = Metadata()) {
    _data = data
  }
  
  var data: Metadata {
    synchronized(self) { _data }
  }
  
  /// Gets and sets a value by a string key to metadata.
  public subscript(name: String) -> Any? {
    get {
      synchronized(self) { _data[name] }
    }
    set {
      synchronized(self) { _data[name] = newValue }
    }
  }
  
  /// Clears metadata
  public func clear() {
    synchronized(self) { _data.removeAll() }
  }
}
