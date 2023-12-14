//
//  Trace.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2021/04/15.
//  Copyright © 2021 Iurii Khvorost. All rights reserved.
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

fileprivate func queue() -> String {
  String(cString: __dispatch_queue_get_label(nil))
}

func traceMetadata(text: String?, function: String, addresses: ArraySlice<NSNumber>, traceConfig: TraceConfig) -> String {
  let items: [(TraceOptions, String, () -> Any)] = [
    (.process, "process", { process(config: traceConfig.processConfig) }),
    (.thread, "thread", { thread(config: traceConfig.threadConfig) }),
    (.queue, "queue", { queue() }),
    (.function, "func", { `func`(function: function, config: traceConfig.funcConfig) }),
    (.stack, "stack", { stack(addresses, config: traceConfig.stackConfig) }),
  ]
  let dict = dictionary(from: items, options: traceConfig.options)
  let pretty = traceConfig.style == .pretty
  return [dict.json(pretty: pretty), text ?? ""].joinedCompact()
}

extension Array where Element == String {
  func joinedCompact() -> String {
    compactMap { $0.isEmpty ? nil : $0 }
      .joined(separator: " ")
  }
}

func dictionary<Option: OptionSet>(from items: [(Option, String, () -> Any)], options: Option) -> [String : Any] {
  let keyValues: [(String, Any)] = items
    .compactMap {
      guard options.contains($0.0 as! Option.Element) else {
        return nil
      }
      let key = $0.1
      let value = $0.2()
      
      if let text = value as? String, text.isEmpty {
        return nil
      }
      else if let dict = value as? [String : Any], dict.isEmpty {
        return nil
      }
      
      return (key, value)
    }
  return Dictionary(uniqueKeysWithValues: keyValues)
}
