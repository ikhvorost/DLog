//  LogMetadata.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 03.07.2022.
//  Copyright © 2022 Iurii Khvorost. All rights reserved.
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
//  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

public typealias Metadata = [String : Any]

extension Metadata {
    func json(parenthesis: Bool = false, quotes: Bool = false) -> String {
        guard self.isEmpty == false,
              let data = try? JSONSerialization.data(withJSONObject: self, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
                  return ""
              }
        var result = json
        if parenthesis {
            let start = json.index(after: json.startIndex)
            let end = json.index(before: json.endIndex)
            result = "(\(json[start..<end]))"
        }
        return quotes ? result : result.replacingOccurrences(of: "\"", with: "")
    }
}

@objcMembers
public class LogMetadata: NSObject {
    var data = Metadata()
    
    init(data: Metadata = Metadata()) {
        self.data = data
    }
    
    public subscript(name: String) -> Any? {
        get {
            synchronized(self) { data[name] }
        }
        set {
            synchronized(self) { data[name] = newValue}
        }
    }
    
    public func clear() {
        synchronized(self) {
            data.removeAll()
        }
    }
}
