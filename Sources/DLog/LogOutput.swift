//
//  LogOutput
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/10/14.
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

/// Base output class
public class LogOutput : NSObject {
	public static var text: Text { Text(style: .plain) }
	public static var textEmoji: Text { Text(style: .emoji) }
	public static var textColored: Text { Text(style: .colored) }
	
	public static var stdout: Standard { Standard(stream: .out) }
	public static var stderr: Standard { Standard(stream: .err) }
	
	public static var oslog: OSLog { OSLog() }
	public static func oslog(_ subsystem: String) -> OSLog { OSLog(subsystem: subsystem) }
	
	public static var net: Net { Net() }
	
	public static func filter(_ block: @escaping (LogItem) -> Bool) -> Filter { Filter(block: block) }
	public static func file(_ path: String, append: Bool = false) -> File { File(path: path, append: append) }
	public static func net(_ name: String) -> Net { Net(name: name) }

	public var source: LogOutput!
	
	init(source: LogOutput?) {
		self.source = source
	}
	
	@discardableResult
	func log(message: LogMessage) -> String? {
		return source != nil
			? source.log(message: message)
			: nil
	}
	
	@discardableResult
	func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		return source != nil
			? source.scopeEnter(scope: scope, scopes: scopes)
			: nil
	}
	
	@discardableResult
	func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		return source != nil
			? source.scopeLeave(scope: scope, scopes: scopes)
			: nil
	}
	
	func intervalBegin(interval: LogInterval) {
		if source != nil {
			source.intervalBegin(interval: interval)
		}
	}
	
	@discardableResult
	func intervalEnd(interval: LogInterval) -> String? {
		return source != nil
			? source.intervalEnd(interval: interval)
			: nil
	}
}

// Forward pipe
precedencegroup ForwardPipe {
	associativity: left
}
infix operator => : ForwardPipe

extension LogOutput {
	// Forward pipeg
	public static func => (left: LogOutput, right: LogOutput) -> LogOutput {
		right.source = left
		return right
	}
}
