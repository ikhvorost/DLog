//  LogData.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2025/01/04.
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
//  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

typealias LogData = [String : Any]

extension LogData {
  
  static func data<Option: OptionSet>(from items: [(Option, String, Any)], options: Option) -> LogData {
    let keyValues: [(String, Any)] = items
      .compactMap { (option: Option, key: String, value: Any) in
        // Option
        assert(option is Option.Element)
        guard options.contains(option as! Option.Element) else {
          return nil
        }
        
        // Key
        assert(key.isEmpty == false)
        
        // Value
        if let text = value as? String, text.isEmpty {
          return nil
        }
        else if let dict = value as? LogData, dict.isEmpty {
          return nil
        }
        
        return (key, value)
      }
    return Dictionary(uniqueKeysWithValues: keyValues)
  }
}

extension Dictionary {
  
  func json(pretty: Bool = false) -> String {
    guard count > 0 else {
      return ""
    }
    let options: JSONSerialization.WritingOptions = pretty ? [.sortedKeys, .prettyPrinted] : [.sortedKeys]
    guard self.isEmpty == false,
          let data = try? JSONSerialization.data(withJSONObject: self, options: options),
          let json = String(data: data, encoding: .utf8) else {
      return ""
    }
    return json.replacingOccurrences(of: "\"", with: "")
  }
}
