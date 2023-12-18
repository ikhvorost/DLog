//
//  TraceStack.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2023/12/14.
//  Copyright © 2023 Iurii Khvorost. All rights reserved.
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

/// Indicates which info from stacks should be used.
public struct StackOptions: OptionSet {
  /// The corresponding value of the raw type.
  public let rawValue: Int
  
  /// Creates a new option set from the given raw value.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  /// Module name
  public static let module = Self(0)
  
  /// Address
  public static let address = Self(1)
  
  /// Stack symbols
  public static let symbols = Self(2)
  
  /// Offset
  public static let offset = Self(3)
  
  /// Frame
  public static let frame = Self(4)
}

/// Contains configuration values regarding to stack info
public struct StackConfig {
  /// Set which info from stacks should be used. Default value is `StackOptions.symbols`.
  public var options: StackOptions = .symbols
  
  /// Depth of stack
  public var depth = 0
}

fileprivate func demangle(_ mangled: String) -> String? {
  guard mangled.hasPrefix("$s") else { return nil }
  
  if let cString = Dynamic.swift_demangle?(mangled, mangled.count, nil, nil, 0) {
    defer { cString.deallocate() }
    return String(cString: cString)
  }
  return nil
}

func stackMetadata(stackAddresses: ArraySlice<NSNumber>, config: StackConfig) -> [Metadata] {
  var info = dl_info()
  
  return stackAddresses
    .compactMap { address -> (String, UInt, String, UInt)? in
      let pointer = UnsafeRawPointer(bitPattern: address.uintValue)
      guard dladdr(pointer, &info) != 0 else {
        return nil
      }
      
      let fname = String(validatingUTF8: info.dli_fname)!
      let module = (fname as NSString).lastPathComponent
      
      let sname = String(validatingUTF8: info.dli_sname)!
      let name = demangle(sname) ?? sname
      
      let offset = address.uintValue - UInt(bitPattern: info.dli_saddr)
      
      return (module, address.uintValue, name, offset)
    }
    .prefix(config.depth > 0 ? config.depth : stackAddresses.count)
    .enumerated()
    .map { item in
      let items: [(StackOptions, String, () -> Any)] = [
        (.module, "module", { "\(item.element.0)" }),
        (.address, "address", { String(format:"0x%016llx", item.element.1) }),
        (.symbols, "symbols", { "\(item.element.2)" }),
        (.offset, "offset", { "\(item.element.3)" }),
        (.frame, "frame", { "\(item.offset)" }),
      ]
      let dict = dictionary(from: items, options: config.options)
      return dict
    }
}
