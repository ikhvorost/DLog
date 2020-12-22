//
//  DLog
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/06/03.
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

func synchronized<T : AnyObject, U>(_ obj: T, closure: () -> U) -> U {
	objc_sync_enter(obj)
	defer {
		objc_sync_exit(obj)
	}
	return closure()
}

@propertyWrapper
class Atomic<T> {
	private var value: T

	init(wrappedValue value: T) {
		self.value = value
	}

	var wrappedValue: T {
		get {
			synchronized(self) { value }
		}
		set {
			synchronized(self) { value = newValue }
		}
	}
}

public class DLog {
	/// The shared disabled log.
	///
	/// Using this constant prevents logging a message.
	public static let disabled = DLog(nil)
	
	public static let category = "DLOG"
	
	private let output: LogOutput?
	
	@Atomic private var categories = [String : LogCategory]()
	@Atomic private var scopes = [LogScope]()
	@Atomic private var intervals = [LogInterval]()
	
	public subscript(category: String) -> LogCategory {
		if let log = categories[category] {
			return log
		}
		let log = LogCategory(log: self, category: category)
		categories[category] = log
		return log
	}
	
	public init(_ output: LogOutput? = .stdout) {
		self.output = output
	}
	
	@discardableResult
	private func log(_ text: String, type: LogType, category: String, file: String, function: String, line: UInt) -> String? {
		guard let out = output else { return nil }
		
		let fileName = NSString(string: file).lastPathComponent
		let message = LogMessage(
			time: Date(),
			category: category,
			type: type,
			fileName: fileName,
			funcName: function,
			line: line,
			text: text,
			scopes: scopes)
		return out.log(message: message)
	}
	
	func enter(scope: LogScope) {
		guard let out = output else { return }
		
		synchronized(self) {
			if let last = scopes.last {
				scope.level = last.level + 1
			}
			scopes.append(scope)
		
			out.scopeEnter(scope: scope, scopes: scopes)
		}
	}
	
	func leave(scope: LogScope) {
		guard let out = output else { return }
		
		synchronized(self) {
			
			if scopes.contains(where: { $0.uid == scope.uid }) {
				out.scopeLeave(scope: scope, scopes: scopes)
			
				scopes.removeAll { $0.uid == scope.uid }
			}
		}
	}
	
	func begin(interval: LogInterval) {
		guard let out = output else { return }
	
		out.intervalBegin(interval: interval)
	}
	
	func end(interval: LogInterval) {
		guard let out = output else { return }
		
		out.intervalEnd(interval: interval)
	}
	
	private func interval(id: String, name: StaticString, category: String, file: String, function: String, line: UInt, scopes: [LogScope]) -> LogInterval {
		if let interval = intervals.first(where: { $0.id == id }) {
			return interval
		}
		else {
			let interval = LogInterval(log: self,
									   category: category,
									   fileName: file,
									   funcName: function,
									   line: line,
									   name: name,
									   scopes: scopes)
			intervals.append(interval)
			return interval
		}
	}
}

extension DLog : LogProtocol {
	
	public func trace(_ text: String?, category: String, file: String, function: String, line: UInt) -> String? {
		log(text ?? function, type: .trace, category: category, file: file, function: function, line: line)
	}
	
	public func info(_ text: String, category: String, file: String, function: String, line: UInt) -> String? {
		log(text, type: .info, category: category, file: file, function: function, line: line)
	}
	
	public func debug(_ text: String, category: String, file: String, function: String, line: UInt) -> String? {
		log(text, type: .debug, category: category, file: file, function: function, line: line)
	}
	
	public func error(_ text: String, category: String, file: String, function: String, line: UInt) -> String? {
		log(text, type: .error, category: category, file: file, function: function, line: line)
	}
	
	public func fault(_ text: String, category: String, file: String, function: String, line: UInt) -> String? {
		log(text, type: .fault, category: category, file: file, function: function, line: line)
	}
	
	public func assert(_ value: Bool, _ text: String = "", category: String, file: String, function: String, line: UInt) -> String? {
		guard !value else { return nil }
		return log(text, type: .assert, category: category, file: file, function: function, line: line)
	}
	
	public func scope(_ text: String, category: String, file: String, function: String, line: UInt, closure: (() -> Void)?) -> LogScope {
		let fileName = NSString(string: file).lastPathComponent
		let scope = LogScope(log: self,
							 category: category,
							 fileName: fileName,
							 funcName: function,
							 line: line,
							 text: text)
		
		guard closure != nil else {
			return scope
		}
	
		scope.enter()
		
		closure?()
		
		scope.leave()
		
		return scope
	}
	
	public func interval(_ name: StaticString, category: String, file: String, function: String, line: UInt, closure: (() -> Void)?) -> LogInterval {
		let fileName = NSString(string: file).lastPathComponent
		let id = "\(fileName):\(line)"
		
		let sp = interval(id: id, name: name, category: category, file: fileName, function: function, line: line, scopes: scopes)
	
		guard closure != nil else {
			return sp
		}
	
		sp.begin()
		
		closure?()
		
		sp.end()
		
		return sp
	}
}
