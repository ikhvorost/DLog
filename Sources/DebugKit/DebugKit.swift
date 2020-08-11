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

// Tasks
// - Text ouput + Console/Terminal/File output/FTP/REST etc


let debugDateFormatter: DateFormatter = {
	let dateFormatter = DateFormatter()
	dateFormatter.dateFormat = "HH:mm:ss.SSS"
	return dateFormatter
}()


struct DebugKit {
    
}

public enum LogType : String {
	case trace = "TRACE"
	case info  = "INFO"
	case interval = "INTERVAL"
	case debug = "DEBUG"
	case error = "ERROR"
	case assert = "ASSERT"
	case fault = "FAULT"
	
	private static let icons: [LogType : String] = [
		.trace : "🏁",
		.info : "✅",
		.interval : "⏱",
		.debug : "▶️",
		.error : "⚠️",
		.assert : "🅰️",
		.fault : "🆘",
	]
	
	var icon: String {
		Self.icons[self]!
	}
}

public struct LogMessage {
	let category: String
	let text: String
	let type: LogType
	let time: String
	let fileName: String
	let function: String
	let line: UInt
	let scopes: [LogScope]
}

public class LogScope {
	let uid = UUID()
	weak var log: DLog?
	var level: Int = 1
	let name: String
	var time: Date?
	let category: String
	var os_state = os_activity_scope_state_s()
	var entered = false
	
	init(log: DLog, name: String, category: String) {
		self.log = log
		self.name = name
		self.category = category
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

public protocol LogOutput {
	@discardableResult func log(message: LogMessage) -> String
	
	@discardableResult func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String
	@discardableResult func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String
	
	func intervalBegin(interval: LogInterval)
	@discardableResult func intervalEnd(interval: LogInterval) -> String
}

//public class FileOutput : LogOutput {
//}

//public class RestOutput : LogOutput {
//}

//public class FTPOutput : LogOutput {
//}

//public class SQLOutput : LogOutput {
//}

//public class JSONOutput : LogOutput {
//}

public class DLog {
	public static let disabled = DLog(category: "DISABLED", outputs: [])
	
	let category: String
	private let outputs: [LogOutput]
	private var scopes = [LogScope]()
	private var intervals = [LogInterval]()
	
	//private var level = .debug
	
	private var enabled : Bool  {
		get { outputs.count > 0 }
	}
	
	public init(category: String = "DLOG", outputs: [LogOutput] = [AdaptiveOutput()]) {
		self.category = category
		self.outputs = outputs
	}
	
	private func log(_ text: String, type: LogType, file: String, function: String, line: UInt) {
		guard enabled else { return }
		
		let fileName = NSString(string: file).lastPathComponent
		let time = debugDateFormatter.string(from: Date())
		
		let message = LogMessage(category: category,
								 text: text,
								 type: type,
								 time: time,
								 fileName: fileName,
								 function: function,
								 line: line,
								 scopes: scopes)
		outputs.forEach {
			$0.log(message: message)
		}
	}
	
	func enter(scope: LogScope) {
		guard enabled else { return }
		
		if let last = scopes.last {
			scope.level = last.level + 1
		}
		scopes.append(scope)
	
		outputs.forEach { $0.scopeEnter(scope: scope, scopes: scopes) }
	}
	
	func leave(scope: LogScope) {
		guard enabled else { return }
		
		if scopes.contains(where: { $0.uid == scope.uid }) {
			outputs.forEach { $0.scopeLeave(scope: scope, scopes: scopes) }
		
			scopes.removeAll { $0.uid == scope.uid }
		}
	}
	
	func begin(interval: LogInterval) {
		guard enabled else { return }
	
		outputs.forEach { $0.intervalBegin(interval: interval) }
	}
	
	func end(interval: LogInterval) {
		guard enabled else { return }
		
		outputs.forEach { $0.intervalEnd(interval: interval) }
	}
	
	// MARK: - public
	
	public func trace(_ text: String = "", file: String = #file, function: String = #function, line: UInt = #line) {
		log(text != "" ? text : function, type: .trace, file: file, function: function, line: line)
	}
	
	public func info(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) {
		log(text, type: .info, file: file, function: function, line: line)
	}
	
	public func debug(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) {
		log(text, type: .debug, file: file, function: function, line: line)
	}
	
	public func error(_ error: Error, file: String = #file, function: String = #function, line: UInt = #line) {
		log(error.localizedDescription, type: .error, file: file, function: function, line: line)
	}
	
	public func fault(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) {
		log(text, type: .fault, file: file, function: function, line: line)
	}
	
	public func assert(_ value: Bool, _ text: String = " ", file: String = #file, function: String = #function, line: UInt = #line) {
		if !value {
			log(text, type: .assert, file: file, function: function, line: line)
		}
	}
	
	@discardableResult
	public func scope(_ name: String, closure: (() -> Void)? = nil) -> LogScope {
		let scope = LogScope(log: self, name: name, category: category)
		
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
