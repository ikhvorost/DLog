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
public struct StackOptions: OptionSet, Sendable {
  /// The corresponding value of the raw type.
  public let rawValue: Int
  
  /// Creates a new option set from the given raw value.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  /// Address
  public static let address = Self(0)
  
  /// Frame
  public static let frame = Self(1)
  
  /// Module name
  public static let module = Self(2)
  
  /// Offset
  public static let offset = Self(3)
  
  /// Stack symbol
  public static let symbol = Self(4)
}

/// Contains configuration values regarding to stack view
public enum StackView {
  /// Show frames for all modules and libraries
  case all
  
  /// Show frames for the current module only
  case module
}

/// Contains configuration values regarding to stack info
public struct StackConfig {
  /// Set which info from stacks should be used. Default value is `StackOptions.symbol`.
  public var options: StackOptions = [.frame, .symbol]
  
  /// Depth of stack
  public var depth = 0
  
  /// View of stack
  public var view: StackView = .module
}

fileprivate func swift_demangle(_ mangled: String) -> String? {
  guard mangled.hasPrefix("$s"), let cString = Dynamic.swift_demangle?(mangled, mangled.count, nil, nil, 0) else {
    return nil
  }
  
  defer { cString.deallocate() }
  return String(cString: cString)
}

func stackMetadata(moduleName: String, stackAddresses: ArraySlice<NSNumber>, config: StackConfig) -> [LogData] {
  stackAddresses
    .compactMap { item -> (address: UInt, module: String, offset: UInt, symbol: String)? in
      let address = item.uintValue
      var info = dl_info()
      guard dladdr(UnsafeRawPointer(bitPattern: address), &info) != 0,
            let module = NSString(utf8String: info.dli_fname)?.lastPathComponent,
            let symbol = String(validatingCString: info.dli_sname)
      else {
        return nil
      }
      
      let offset = address - UInt(bitPattern: info.dli_saddr)
      return (address, module, offset, symbol)
    }
    .prefix(config.depth > 0 ? config.depth : stackAddresses.count)
    .enumerated()
    .filter {
      guard config.view == .module else {
        return true
      }

      let module = $0.element.module
      
      return module == moduleName
        ? true
        : module.replacingOccurrences(of: "Package", with: "") == moduleName // Fix: swift test
    }
    .map { item in
      let items: [(StackOptions, String, Any)] = [
        (.address, "address", String(format:"0x%llx", item.element.address)),
        (.frame, "frame", item.offset),
        (.module, "module", item.element.module),
        (.offset, "offset", item.element.offset),
        (.symbol, "symbol", swift_demangle(item.element.symbol) ?? item.element.symbol),
      ]
      return LogData.data(from: items, options: config.options)
    }
}
