import Foundation

public class DLog {
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
		
		if let last = scopes.last {
			scope.level = last.level + 1
		}
		scopes.append(scope)
	
		out.scopeEnter(scope: scope, scopes: scopes)
	}
	
	func leave(scope: LogScope) {
		guard let out = output else { return }
		
		if scopes.contains(where: { $0.uid == scope.uid }) {
			out.scopeLeave(scope: scope, scopes: scopes)
		
			scopes.removeAll { $0.uid == scope.uid }
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
	
	@discardableResult
	public func trace(_ text: String? = nil, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log(text ?? function, type: .trace, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func info(_ text: String, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log(text, type: .info, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func debug(_ text: String, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log(text, type: .debug, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func error(_ error: Error, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log(error.localizedDescription, type: .error, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func fault(_ text: String, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log(text, type: .fault, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func assert(_ value: Bool, _ text: String = "", category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		guard !value else { return nil }
		return log(text, type: .assert, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func scope(_ text: String, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogScope {
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
	
	@discardableResult
	public func interval(_ name: StaticString, category: String = DLog.category, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogInterval {
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
