import Foundation
import os
import os.log
import os.activity

// https://nshipster.com/swift-log/
// log stream --predicate 'eventMessage CONTAINS[c] "[dlog]"' --style syslog
// logger: level, filter by files

// oslog
// .tracev3
// stored /var/db/diagnostics/ with support in /var/db/uuidtext

// TODO:
// + thread safe
// + filtering predicate
// + log category
// + TextOutput with color
// - trace stack
// - reconnection net console
// - cache net log
// - Rest, ftp, sql, json, slack


@objc
public enum LogType : Int {
	case trace
	case info
	case interval
	case scope
	case debug
	case error
	case assert
	case fault
	
	private static let icons: [LogType : String] = [
		.trace : "◽️",
		.info : "✅",
		.debug : "▶️",
		.error : "⚠️",
		.assert : "🅰️",
		.fault : "🆘",
		.interval : "🕒",
		.scope : "#️⃣",
	]
	
	var icon: String {
		Self.icons[self]!
	}
	
	private static let titles: [LogType : String] = [
		.trace : "TRACE",
		.info : "INFO",
		.interval : "INTERVAL",
		.debug : "DEBUG",
		.error : "ERROR",
		.assert : "ASSERT",
		.fault : "FAULT",
	]
	
	var title: String {
		Self.titles[self]!
	}
}

@objcMembers
public class LogItem : NSObject {
	var time: Date?
	let category: String
	let type: LogType
	let fileName: String
	let funcName: String
	let line: UInt
	let text: String
	
	public init(time: Date? = nil, category: String, type: LogType, fileName: String, funcName: String, line: UInt, text: String) {
		self.time = time
		self.category = category
		self.type = type
		self.fileName = fileName
		self.funcName = funcName
		self.line = line
		self.text = text
	}
}

public class LogMessage : LogItem {
	let scopes: [LogScope]
	
	public init(time: Date, category: String, type: LogType, fileName: String, funcName: String, line: UInt, text: String, scopes: [LogScope]) {
		self.scopes = scopes
		super.init(time: time, category: category, type: type, fileName: fileName, funcName: funcName, line: line, text: text)
	}
}

public class LogScope : LogItem {
	weak var log: DLog!
	let uid = UUID()
	var level: Int = 1
	var os_state = os_activity_scope_state_s()
	var entered = false
	
	fileprivate init(log: DLog, category: String, fileName: String, funcName: String, line: UInt, text: String) {
		self.log = log
		super.init(category: category, type: .scope, fileName: fileName, funcName: funcName, line: line, text: text)
	}
	
	deinit {
		log.leave(scope: self)
	}
	
	public func enter() {
		guard !entered else { return }
		entered = true
		
		time = Date()
		log.enter(scope: self)
	}
	
	public func leave() {
		guard entered else { return }
		entered = false
		log.leave(scope: self)
	}
}

public class LogInterval : LogItem {
	weak var log: DLog!
	let name: StaticString
	let scopes: [LogScope]
	
	var count = 0
	var duration: TimeInterval = 0
	var minDuration: TimeInterval = 0
	var maxDuration: TimeInterval = 0
	var avgDuration: TimeInterval = 0
	
	var id : String {
		"\(fileName):\(line)"
	}
	
	// SignpostID
	private var _signpostID: Any? = nil
	@available(OSX 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
	var signpostID: OSSignpostID? {
		set { _signpostID = newValue }
		get { _signpostID as? OSSignpostID }
	}
	
	fileprivate init(log: DLog, category: String, fileName: String, funcName: String, line: UInt, name: StaticString, scopes: [LogScope]) {
		self.log = log
		self.name = name
		self.scopes = scopes
		
		super.init(category: category, type: .interval, fileName: fileName, funcName: funcName, line: line, text: "\(name)")
	}
	
	public func begin() {
		guard time == nil else { return }
	
		time = Date()
		
		log.begin(interval: self)
	}
	
	public func end() {
		guard let time = time else { return }
		
		let timeInterval = time.timeIntervalSinceNow
		let interval = -timeInterval
		count += 1
		duration += interval
		if minDuration == 0 || minDuration > interval {
			minDuration = interval
		}
		if maxDuration == 0 || maxDuration < interval {
			maxDuration = interval
		}
		avgDuration = duration / Double(count)
		
		self.time = nil
		
		log.end(interval: self)
	}
	
	public func event() {
		
	}
}

/// Base output class
public class LogOutput : NSObject {
	public static var text: TextOutput { TextOutput() }
	public static var textColor: TextOutput { TextOutput(color: true) }
	public static var stdout: StandardOutput { StandardOutput() }
	public static var adaptive: AdaptiveOutput { AdaptiveOutput() }
	public static var oslog: OSLogOutput { OSLogOutput() }
	public static func filter(_ block: @escaping (LogItem) -> Bool) -> FilterOutput { FilterOutput(block: block) }
	public static func file(_ filePath: String) -> FileOutput { FileOutput(filePath: filePath) }

	var output: LogOutput!
	
	@discardableResult
	public func log(message: LogMessage) -> String? {
		return output != nil
			? output.log(message: message)
			: nil
	}
	
	@discardableResult
	public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		return output != nil
			? output.scopeEnter(scope: scope, scopes: scopes)
			: nil
	}
	
	@discardableResult
	public func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		return output != nil
			? output.scopeLeave(scope: scope, scopes: scopes)
			: nil
	}
	
	public func intervalBegin(interval: LogInterval) {
		if output != nil {
			output.intervalBegin(interval: interval)
		}
	}
	
	@discardableResult
	public func intervalEnd(interval: LogInterval) -> String? {
		return output != nil
			? output.intervalEnd(interval: interval)
			: nil
	}
}

// Forward pipe
precedencegroup ForwardPipe {
	associativity: left
}
infix operator => : ForwardPipe

extension LogOutput {
	// Forward pipe
	static func => (left: LogOutput, right: LogOutput) -> LogOutput {
		right.output = left
		return right
	}
}

public class LogCategory {
	let log: DLog
	let category: String
	
	public init(log: DLog, category: String) {
		self.log = log
		self.category = category
	}
	
	@discardableResult
	public func trace(_ text: String? = nil, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.trace(text, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func info(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.info(text, category: category, file: file, function: function, line: line)
	}
		
	@discardableResult
	public func debug(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.debug(text, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func error(_ error: Error, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.error(error, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func fault(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.fault(text, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func assert(_ value: Bool, _ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log.assert(value, category: category, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func scope(_ text: String, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogScope {
		log.scope(text, category: category, file: file, function: function, line: line, closure: closure)
	}
	
	@discardableResult
	public func interval(_ name: StaticString, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogInterval {
		log.interval(name, category: category, file: file, function: function, line: line, closure: closure)
	}
}

public class DLog {
	public static let disabled = DLog(nil)
	public static let category = "DLOG"
	
	private let output: LogOutput?
	
	@Atomic private var categories = [String : LogCategory]()
	@Atomic private var scopes = [LogScope]()
	@Atomic private var intervals = [LogInterval]()
	
	subscript(category: String) -> LogCategory {
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
