import Foundation
import os.log
import os.activity

// https://nshipster.com/swift-log/
// log stream --predicate 'eventMessage CONTAINS[c] "[dlog]"' --style syslog
// logger: level, filter by files

// assertation


enum Platform {
	case macOS
	case macCatalyst
	case tvOS
	case watchOS
	case iOS
	
	static var current : Platform {
		#if os(OSX)
			return .macOS
		#elseif os(watchOS)
			return .watchOS
		#elseif os(tvOS)
			return .tvOS
		#elseif os(iOS)
			#if targetEnvironment(macCatalyst)
				return .macCatalyst
			#else
				return .iOS
			#endif
		#endif
	}
}

struct DebugKit {
    
}

enum ANSIEscapeCode: String {
    case textBlack = "\u{001B}[30m"
    case textRed = "\u{001B}[31m"
    case textGreen = "\u{001B}[32m"
    case textYellow = "\u{001B}[33m"
    case textBlue = "\u{001B}[34m"
    case textMagenta = "\u{001B}[35m"
    case textCyan = "\u{001B}[36m"
    case textWhite = "\u{001B}[37m"
	
	case backgroundBlack = "\u{001b}[40m"
	case backgrounRed = "\u{001b}[41m"
	case backgroundGreen = "\u{001b}[42m"
	case backgroundYellow = "\u{001b}[43m"
	case backgroundBlue = "\u{001b}[44m"
	case backgroundMagenta = "\u{001b}[45m"
	case backgroundCyan = "\u{001b}[46m"
	case backgroundWhite = "\u{001b}[47m"
	
	case bold = "\u{001b}[1m"
	case underline = "\u{001b}[4m"
	case reversed = "\u{001b}[7m"
	
    case reset = "\u{001B}[0m"
}

extension String {
	func escape(code: ANSIEscapeCode) -> String {
		return "\(code.rawValue)\(self)\(ANSIEscapeCode.reset.rawValue)"
	}
}

extension OSLogType : Hashable {
	public var hashValue: Int {
		switch self {
			case .default:
				return 0
			case .info:
				return 1
			case .debug:
				return 2
			case .error:
				return 3
			case .fault:
				return 4
			default:
				return 0
		}
	}
}

public struct LogType  {
	let icon: Character
	let name: String
	let type: OSLogType
	
	static let trace = LogType(icon: "✳️", name: "TRACE", type: OSLogType.default)
	static let info = LogType(icon: "🚹", name: "INFO", type: OSLogType.info)
	static let debug = LogType(icon: "▶️", name: "DEBUG", type: OSLogType.debug)
	static let error = LogType(icon: "⚠️", name: "ERROR", type: OSLogType.error)
	static let fault = LogType(icon: "❌", name: "FAULT", type: OSLogType.fault)
	
	static let assert = LogType(icon: "🅰️", name: "ASSERT", type: OSLogType.debug)
}

public struct LogMessage {
	let category: String
	let text: String
	let type: LogType
	let time: String
	let scope: DLog.Scope?
	let fileName: String
	let function: String
	let line: UInt
}

public protocol LogOutput {
	func log(message: LogMessage)
	func scope(scope: DLog.Scope, start: Bool, time: String, category: String)
}

public class XConsoleOutput : LogOutput {
	func write(category: String, time: String, padding: String, icon: String, type: LogType, location: String, text: String) {
		print(time, "[\(category)]", padding, icon, "[\(type.name)]", location, text)
	}
	
	public func log(message: LogMessage) {
		var padding = ""
		if let s = message.scope {
			padding = String(repeating: "|\t", count: s.level)
		}
		
		write(category: message.category, time: message.time, padding: padding, icon: "\(message.type.icon)", type: message.type, location: "<\(message.fileName):\(message.line)>", text: message.text)
	}
	
	public func scope(scope: DLog.Scope, start: Bool, time: String, category: String) {
		let icon = start ? "┌" : "└"
		let padding = String(repeating: "|\t", count: scope.level-1) + icon
		
		let interval = Int(scope.time.timeIntervalSinceNow * -1000)
		let ms = !start ? "(\(interval) ms)" : nil
			
		print(time, "[\(category)]", padding, "[\(scope.name)]", ms ?? "")
	}
}

public class TerminalOutput : XConsoleOutput {
	
	struct Colors {
		let textColor: ANSIEscapeCode
		let backgroundColor: ANSIEscapeCode
	}
	
	static let colors = [
		OSLogType.default : Colors(textColor: .textGreen, backgroundColor: .backgroundGreen),
		OSLogType.info : Colors(textColor: .textBlue, backgroundColor: .backgroundBlue),
		OSLogType.debug : Colors(textColor: .textWhite, backgroundColor: .reversed),
		OSLogType.error : Colors(textColor: .textYellow, backgroundColor: .backgroundYellow),
		OSLogType.fault : Colors(textColor: .textRed, backgroundColor: .backgrounRed)
	]
	
	override func write(category: String, time: String, padding: String, icon: String, type: LogType, location: String, text: String) {
		var tag = "[\(type.name)]"
		var file = location.escape(code: .underline)
		var msg = text

		if let color = Self.colors[type.type] {
			tag = tag.escape(code: color.backgroundColor)
			file = file.escape(code: color.textColor)
			msg = msg.escape(code: color.textColor)
		}
		
		print(time, "[\(category)]", padding, tag, file, msg)
	}
}

public class OSLogOutput : LogOutput {
	private var log: OSLog?
	
	private func oslog(category: String) -> OSLog {
		if let l = log {
			return l
		}
		else {
			let subsystem = Bundle.main.bundleIdentifier ?? ""
			log = OSLog(subsystem: subsystem, category: category)
			return log!
		}
	}
	
	public func log(message: LogMessage) {
		let log = oslog(category: message.category)
		
		let location = "<\(message.fileName):\(message.line)>"
		os_log("%s %s", log: log, type: message.type.type, location, message.text)
	}
	
	public func scope(scope: DLog.Scope, start: Bool, time: String, category: String) {
	}
}

public class AdaptiveOutput : LogOutput {
	let output: LogOutput
	
	static var isDebug : Bool {
		var info = kinfo_proc()
		var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
		var size = MemoryLayout<kinfo_proc>.stride
		let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
		assert(junk == 0, "sysctl failed")
		return (info.kp_proc.p_flag & P_TRACED) != 0
	}
	
	static var isTerminal : Bool {
		return ProcessInfo.processInfo.environment["_"] != nil
	}
	
	init() {
		if Self.isDebug {
			output = XConsoleOutput()
		}
		else {
			output  = Self.isTerminal ? TerminalOutput() : OSLogOutput()
		}
	}
	
	public func log(message: LogMessage) {
		output.log(message: message)
	}
	
	public func scope(scope: DLog.Scope, start: Bool, time: String, category: String) {
		output.scope(scope: scope, start: start, time: time, category: category)
	}
}

//public class FileOutput : LogOutput {
//}

//public class FTPOutput : LogOutput {
//}

//public class SQLOutput : LogOutput {
//}

//public class JSONOutput : LogOutput {
//}

public class DLog {
	private let category: String
	private let outputs: [LogOutput]
	private var scopes = [Scope]()
	
	public struct Scope {
		let level: Int
		let name: String
		let time: Date
	}
	
	init(category: String = "DLOG", output: [LogOutput] = [AdaptiveOutput()]) {
		self.category = category
		self.outputs = output
	}
	
	private static let debugDateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "HH:mm:ss:SSS"
		return dateFormatter
	}()
	
	private func log(_ text: String, type: LogType, file: String, function: String, line: UInt) {
		let fileName = NSString(string: file).lastPathComponent
		let time = Self.debugDateFormatter.string(from: Date())
		
		let scope = scopes.last
		
		let message = LogMessage(category: category, text: text, type: type, time: time, scope: scope, fileName: fileName, function: function, line: line)
		
		outputs.forEach {
			$0.log(message: message)
		}
	}
	
	public func trace(_ text: String, file: String = #file, function: String = #function, line: UInt = #line) {
		log(text != "" ? text : function, type: .trace, file: file, function: function, line: line)
	}
	
	public func info(_ text: String, file: String	 = #file, function: String = #function, line: UInt = #line) {
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
	
	public func scope(_ name: String = #function, closure: () -> Void) {
		let date = Date()
		let s = Scope(level: scopes.count + 1, name: name, time: date)
		scopes.append(s)
		
		var time = Self.debugDateFormatter.string(from: date)
		outputs.forEach {
			$0.scope(scope: s, start: true, time: time, category: category)
		}
		
		closure()
		
		time = Self.debugDateFormatter.string(from: Date())
		outputs.forEach {
			$0.scope(scope: s, start: false, time: time, category: category)
		}
		
		_ = scopes.popLast()
	}
}

/*
public func dlog(_ items: String..., icon: Character = "▶️", file: String = #file, function: String = #function, line: UInt = #line) {
	let text = items.count > 0 ? items.joined(separator: " ") : function
	let fileName = NSString(string: file).lastPathComponent
	let time = debugDateFormatter.string(from: Date())
	
	let head = "[\(time)] [DLOG] \(icon) <\(fileName):\(line)>"
	print(head, text)
	
	// https://nshipster.com/swift-log/
	// log stream --predicate 'eventMessage CONTAINS[c] "[dlog]"' --style syslog
	
	
	_os_activity_initiate(UnsafeMutableRawPointer(mutating: #dsohandle), strdup("net"), OS_ACTIVITY_FLAG_DEFAULT,  {
    
	os_log("⚠️  [dlog] os_log %s", type: .fault,  "\(text, color: .red)")
		_os_activity_initiate(UnsafeMutableRawPointer(mutating: #dsohandle), strdup("request"), OS_ACTIVITY_FLAG_DEFAULT,  {
			os_log("%s %s", head, text)
		})
	})
}

public func dlog(error: Error, file: String = #file, function: String = #function, line: UInt = #line) {
	dlog("\("Error: \(error.localizedDescription)", color: .yellow)", icon: "⚠️", file: file, function: function, line: line)
}
// */

public func asyncAfter(_ sec: Double = 0.25, closure: @escaping (() -> Void) ) {
	DispatchQueue.global().asyncAfter(deadline: .now() + sec) {
		closure()
    }
}
