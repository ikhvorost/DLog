//
//  OutputBuilder.swift
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


@resultBuilder
public struct OutputBuilder {
  
  public static func buildBlock(_ outputs: [Output]...) -> [Output] {
    outputs.flatMap { $0 }
  }
  
  /// Add support for both single and collections of constraints.
  public static func buildExpression(_ output: Output) -> [Output] {
    [output]
  }
  
  public static func buildExpression(_ output: [Output]) -> [Output] {
    output
  }
  
  /// Add support for optionals.
  public static func buildOptional(_ outputs: [Output]?) -> [Output] {
    outputs ?? []
  }
  
  /// Add support for if statements.
  public static func buildEither(first outputs: [Output]) -> [Output] {
    outputs
  }
  
  public static func buildEither(second outputs: [Output]) -> [Output] {
    outputs
  }
}
