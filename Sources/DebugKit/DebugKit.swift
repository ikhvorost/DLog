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
// signpost 📍
// - assert
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
	case debug = "DEBUG"
	case error = "ERROR"
	case fault = "FAULT"
	case assert = "ASSERT"
	//case signpost
	
	private static let icons: [LogType : String] = [
		.trace : "◻️",
		.info : "✅",
		.debug : "▶️",
		.error : "⚠️",
		.fault : "🆘",
		.assert : "🅰️",
		//.signpost : "📍",
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
	let time = Date()
	let category: String
	var os_state = os_activity_scope_state_s()
	
	init(log: DLog, name: String, category: String) {
		self.log = log
		self.name = name
		self.category = category
	}
	
	deinit {
		log?.leave(scope: self)
	}
	
	public func enter() {
		log?.enter(scope: self)
	}
	
	public func leave() {
		log?.leave(scope: self)
	}
}

public class LogSignpost {
	let name: String
	var count = 0
	let duration: TimeInterval = 0
	let minDutation: TimeInterval = 0
	let avgDutation: TimeInterval = 0
	let maxDutation: TimeInterval = 0
	
	init(_ name: String) {
		self.name = name
	}
	
	public func begin() {
		count += 1
	}
	
	public func end() {
		
	}
	
	public func event() {
		
	}
}

public protocol LogOutput {
	@discardableResult func log(message: LogMessage) -> String
	@discardableResult func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String
	@discardableResult func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String
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
	let category: String
	private let outputs: [LogOutput]
	//private var level = .debug
	private var scopes = [LogScope]()
	
	public static let disabled = DLog(category: "DISABLED", outputs: [])
	
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
		
		guard !scopes.contains(where: { $0.uid == scope.uid }) else { return }
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
	
	//public func fail(_ text: String, file: String = #file, function: String = #function, line: UInt = #line)
	
	@discardableResult
	public func scope(_ name: String, _ closure: (() -> Void)? = nil) -> LogScope {
		let scope = LogScope(log: self, name: name, category: category)
		
		guard closure != nil else {
			return scope
		}
	
		scope.enter()
		
		closure?()
		
		scope.leave()
		
		return scope
	}
	
	public func signpost(_ name: String) {
		
	}
}
