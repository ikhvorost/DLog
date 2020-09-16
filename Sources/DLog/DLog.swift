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
// - thread safe
// - filtering predicate
// - log category
// - TextOutput with color
// - reconnection net console

@objc
public enum LogType : Int {
	case trace
	case info
	case interval
	case debug
	case error
	case assert
	case fault
	
	private static let icons: [LogType : String] = [
		.trace : "◽️",
		.info : "✅",
		.interval : "🕒",
		.debug : "▶️",
		.error : "⚠️",
		.assert : "🅰️",
		.fault : "🆘",
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
public class FilterItem : NSObject {
	let category: String
	let text: String
	let fileName: String
	let functionName: String
	let line: UInt
	
	public init(category: String, text: String, fileName: String, functionName: String, line: UInt) {
		self.category = category
		self.text = text
		self.fileName = fileName
		self.functionName = functionName
		self.line = line
	}
}

public class LogMessage : FilterItem {
	let type: LogType
	let time: Date
	let scopes: [LogScope]
	
	public init(category: String, text: String, type: LogType, time: Date, fileName: String, functionName: String, line: UInt, scopes: [LogScope]) {
		self.type = type
		self.time = time
		self.scopes = scopes
		
		super.init(category: category, text: text, fileName: fileName, functionName: functionName, line: line)
	}
}

@objcMembers
public class LogScope : FilterItem {
	let uid = UUID()
	weak var log: DLog?
	var level: Int = 1
	var time: Date?
	var os_state = os_activity_scope_state_s()
	var entered = false
	
	init(log: DLog, category: String, text: String, fileName: String, functionName: String, line: UInt) {
		self.log = log
		
		super.init(category: category, text: text, fileName: fileName, functionName: functionName, line: line)
	}
	
	deinit {
		log?.leave(scope: self)
	}
	
	public func enter() {
		guard !entered else { return }
		entered = true
		
		time = Date()
		log?.enter(scope: self)
	}
	
	public func leave() {
		guard entered else { return }
		entered = false
		log?.leave(scope: self)
	}
}

public class LogInterval {
	weak var log: DLog?
	
	let name: StaticString
	
	let category: String
	let file: String
	let function: String
	let line: UInt
	
	let scopes: [LogScope]
	
	var startTime: Date?
	
	var count = 0
	var duration: TimeInterval = 0
	var minDuration: TimeInterval = 0
	var maxDuration: TimeInterval = 0
	var avgDuration: TimeInterval = 0
	
	var id : String {
		"\(file):\(line)"
	}
	
	// SignpostID
	private var _signpostID: Any? = nil
	@available(OSX 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
	var signpostID: OSSignpostID? {
		set { _signpostID = newValue }
		get { _signpostID as? OSSignpostID }
	}
	
	init(log: DLog, name: StaticString, category: String, file: String, function: String, line: UInt, scopes: [LogScope]) {
		self.log = log
		self.name = name
		self.category = category
		self.file = file
		self.function = function
		self.line = line
		self.scopes = scopes
	}
	
	public func begin() {
		guard startTime == nil else { return }
	
		startTime = Date()
		
		log?.begin(interval: self)
	}
	
	public func end() {
		guard let time = startTime else { return }
		
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
		
		startTime = nil
		
		log?.end(interval: self)
	}
	
	public func event() {
		
	}
}

// TODO: Rest, ftp, sql, json, slack

/// Base output class
public class LogOutput : NSObject {
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

public class DLog {
	public static let disabled = DLog(output: nil)
	public static let standard = DLog(output: StandardOutput())
	public static let adaptive = DLog(output: AdaptiveOutput())
	public static let oslog = DLog(output: OSLogOutput())

	private let category: String
	private let output: LogOutput?
	
	@Atomic private var scopes = [LogScope]()
	@Atomic private var intervals = [LogInterval]()
	
	static var isDebug : Bool {
		var info = kinfo_proc()
		var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
		var size = MemoryLayout<kinfo_proc>.stride
		sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
		//assert(junk == 0, "sysctl failed")
		return (info.kp_proc.p_flag & P_TRACED) != 0
	}
	
	public init(category: String = "DLOG", output: LogOutput?) {
		self.category = category
		self.output = output
	}
	
	@discardableResult
	private func log(_ text: String, type: LogType, file: String, function: String, line: UInt) -> String? {
		guard let out = output else { return nil }
		
		let message = LogMessage(category: category,
								 text: text,
								 type: type,
								 time: Date(),
								 fileName: NSString(string: file).lastPathComponent,
								 functionName: function,
								 line: line,
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
	public func trace(_ text: String? = nil, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log(text ?? function, type: .trace, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func info(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log(text, type: .info, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func debug(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log(text, type: .debug, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func error(_ error: Error, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log(error.localizedDescription, type: .error, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func fault(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		log(text, type: .fault, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func assert(_ value: Bool, _ text: String = " ", file: String = #file, function: String = #function, line: UInt = #line) -> String? {
		guard !value else { return nil }
		return log(text, type: .assert, file: file, function: function, line: line)
	}
	
	@discardableResult
	public func scope(_ text: String, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogScope {
		let scope = LogScope(log: self,
							 category: category,
							 text: text,
							 fileName: NSString(string: file).lastPathComponent,
							 functionName: function,
							 line: line)
		
		guard closure != nil else {
			return scope
		}
	
		scope.enter()
		
		closure?()
		
		scope.leave()
		
		return scope
	}
	
	private func interval(id: String, name: StaticString, file: String, function: String, line: UInt, scopes: [LogScope]) -> LogInterval {
		if let interval = intervals.first(where: { $0.id == id }) {
			return interval
		}
		else {
			let interval = LogInterval(log: self, name: name, category: category, file: file, function: function, line: line, scopes: scopes)
			intervals.append(interval)
			return interval
		}
	}
	
	@discardableResult
	public func interval(_ name: StaticString, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogInterval {
		let fileName = NSString(string: file).lastPathComponent
		let id = "\(fileName):\(line)"
		
		let sp = interval(id: id, name: name, file: fileName, function: function, line: line, scopes: scopes)
	
		guard closure != nil else {
			return sp
		}
	
		sp.begin()
		
		closure?()
		
		sp.end()
		
		return sp
	}
}
