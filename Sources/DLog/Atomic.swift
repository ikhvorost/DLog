//
//  Atomic.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2021/02/04.
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

@discardableResult
func synchronized<T>(_ obj: AnyObject, body: () -> T) -> T {
  objc_sync_enter(obj)
  defer {
    objc_sync_exit(obj)
  }
  return body()
}

public class Atomic<T>: @unchecked Sendable {
  fileprivate var _value: T
  
  public init(_ value: T) {
    _value = value
  }
  
  public var value: T {
    get {
      synchronized(self) { _value }
    }
    set {
      synchronized(self) { _value = newValue }
    }
  }
  
  public func sync<U>(_ body: (inout T) -> U) -> U {
    synchronized(self) { body(&_value) }
  }
}

public final class AtomicDictionary<K: Hashable, V>: Atomic<Dictionary<K, V>>, @unchecked Sendable {
  
  public subscript(key: K) -> V? {
    get {
      sync { $0[key] }
    }
    set {
      sync { $0[key] = newValue }
    }
  }
  
  public func removeAll() {
    sync { $0.removeAll() }
  }
}

