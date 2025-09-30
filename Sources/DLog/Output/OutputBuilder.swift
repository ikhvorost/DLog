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

/// A custom parameter attribute that constructs outputs from closures.
@resultBuilder
public struct OutputBuilder {
  
  /// Required by every result builder to build combined results from statement blocks.
  public static func buildBlock(_ outputs: [OutputProtocol]...) -> [OutputProtocol] {
    outputs.flatMap { $0 }
  }
  
  /// If declared, provides contextual type information for statement
  /// expressions to translate them into partial results.
  public static func buildExpression(_ output: OutputProtocol) -> [OutputProtocol] {
    [output]
  }
  
  /// Enables support for `if` statements that do not have an `else`.
  public static func buildOptional(_ outputs: [OutputProtocol]?) -> [OutputProtocol] {
    outputs ?? []
  }
  
  /// With buildEither(second:), enables support for `if-else` and `switch`
  /// statements by folding conditional results into a single result.
  public static func buildEither(first outputs: [OutputProtocol]) -> [OutputProtocol] {
    outputs
  }
  
  /// With buildEither(first:), enables support for 'if-else' and 'switch'
  /// statements by folding conditional results into a single result.
  public static func buildEither(second outputs: [OutputProtocol]) -> [OutputProtocol] {
    outputs
  }
}
