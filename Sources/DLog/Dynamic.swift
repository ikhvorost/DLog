//
//  Dynamic.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2022/03/30.
//  Copyright © 2020 Iurii Khvorost. All rights reserved.
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
import os


typealias Swift_Demangle = @convention(c) (_ mangledName: UnsafePointer<UInt8>?,
                                                       _ mangledNameLength: Int,
                                                       _ outputBuffer: UnsafeMutablePointer<UInt8>?,
                                                       _ outputBufferSize: UnsafeMutablePointer<Int>?,
                                                       _ flags: UInt32) -> UnsafeMutablePointer<Int8>?
/// Dynamic shared object
class Dynamic {
    
    // Constants
    static let dso = UnsafeMutableRawPointer(mutating: #dsohandle)
    private static let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)
    
    private static func dynamic<T>(symbol: String) -> T {
        guard let sym = dlsym(RTLD_DEFAULT, symbol) else {
            fatalError("\(symbol) is NOT found!")
        }
        return unsafeBitCast(sym, to: T.self)
    }
   
    // Functions
    static let OS_ACTIVITY_CURRENT: os_activity_t = dynamic(symbol: "_os_activity_current")
    static let swift_demangle: Swift_Demangle = dynamic(symbol: "swift_demangle")
}
