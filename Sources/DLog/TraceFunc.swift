//
//  TraceFunc.swift
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


/// Contains configuration values regarding to func info.
public struct FuncConfig {
  
  // Params of a function
  public var params = false
}

func funcInfo(function: String, config: FuncConfig) -> String {
  let isObjC = function.hasPrefix("-[")
  if isObjC {
    var funcName = function
    if let range = funcName.range(of: #"[^\s]+\]"#, options: [.regularExpression]) {
      funcName = String(function[range].dropLast())
    }
    if config.params == false, let index = funcName.firstIndex(of: ":") {
      funcName = String(funcName[funcName.startIndex..<index])
    }
    return funcName
  }
  else {
    if config.params == false {
      if let range = function.range(of: #"^[^\(]+"#, options: [.regularExpression]) {
        return String(function[range])
      }
    }
  }
  return function
}
