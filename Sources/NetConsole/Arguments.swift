//
//	Arguments.swift
//
//	NetConsole for DLog
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2021/04/09.
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

class Arguments {
  private var arguments = [String : String]()
  
  init() {
    var key: String?
    for param in CommandLine.arguments {
      if param.hasPrefix("-") {
        if key != nil {
          arguments[key!] = ""
        }
        
        key = param
        
        // Last
        if param == CommandLine.arguments.last {
          arguments[key!] = ""
        }
      }
      else {
        if key != nil {
          arguments[key!] = param
          key = nil
        }
      }
    }
  }
  
  func stringValue(forKeys keys: [String], defaultValue: String) -> String {
    for key in keys {
      if let value = arguments[key], !value.isEmpty {
        return value
      }
    }
    return defaultValue
  }
  
  func boolValue(forKeys keys: [String], defaultValue: Bool = false) -> Bool {
    for key in keys {
      if arguments[key] != nil {
        return true
      }
    }
    return false
  }
  
}
