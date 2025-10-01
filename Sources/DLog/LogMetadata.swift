//
//  LogMetadata.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2025/10/01.
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

/// Metadata value type
public typealias MetadataValue = Sendable & Codable

/// Metadata type
public typealias Metadata = [String : MetadataValue]

/// The type that represents a metadata you attach to the log messages.
public final class LogMetadata {
  private let data: Atomic<Metadata>
  
  init(data: Metadata) {
    self.data = Atomic(data)
  }
  
  /// The metadata dictionary
  public var value: Metadata {
    data.value
  }
  
  /// Accesses the metadata value for a custom key.
  public subscript(key: String) -> MetadataValue? {
    set {
      data.sync { $0[key] = newValue }
    }
    get {
      data.sync { $0[key] }
    }
  }
  
  /// Clear the metadata
  public func removeAll() {
    data.sync { $0.removeAll() }
  }
}
