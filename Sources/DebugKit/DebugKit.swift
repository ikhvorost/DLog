import Foundation
import os.log
import os.activity

// https://nshipster.com/swift-log/
// log stream --predicate 'eventMessage CONTAINS[c] "[dlog]"' --style syslog
// logger: level, filter by files

// assertation


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

public protocol LogHandler {
	func log(text: String, type: LogType, time: String, fileName: String, function: String, line: UInt)
}

public class XCConsoleLogHandler : LogHandler {
	public func log(text: String, type: LogType, time: String, fileName: String, function: String, line: UInt) {
		print(time, "[DLOG]", type.icon, "[\(type.name)]", "<\(fileName):\(line)>", text)
	}
}

public class TerminalLogHandler : LogHandler {
	
	struct Colors {
		let textColor: ANSIEscapeCode
		let backgroundColor: ANSIEscapeCode
	}
	
	static let colors = [
		OSLogType.default : Colors(textColor: .textGreen, backgroundColor: .backgroundGreen),
		OSLogType.info : Colors(textColor: .textBlue, backgroundColor: .backgroundBlue),
		OSLogType.debug : Colors(textColor: .textWhite, backgroundColor: .backgroundWhite),
		OSLogType.error : Colors(textColor: .textYellow, backgroundColor: .backgroundYellow),
		OSLogType.fault : Colors(textColor: .textRed, backgroundColor: .backgrounRed)
	]
	
	public func log(text: String, type: LogType, time: String, fileName: String, function: String, line: UInt) {
		var tag = "[\(type.name)]"
		var location = "<\(fileName):\(line)>".escape(code: .underline)
		var msg = text
		
		if let color = Self.colors[type.type] {
			tag = tag.escape(code: color.backgroundColor)
			location = location.escape(code: color.textColor)
			msg = msg.escape(code: color.textColor)
		}
		
		print(time, "[DLOG]", type.icon, tag, location, msg)
	}
}

public class AutoLogHandler : LogHandler {
	let handler: LogHandler
	
	enum Platform {
		case macOS
		case macCatalyst
		case tvOS
		case watchOS
		case iOS
	}
	
	static var platform : Platform {
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
			handler = XCConsoleLogHandler()
		}
		else {
			handler  = Self.isTerminal ? TerminalLogHandler() : OSLogHandler()
		}
	}
	
	public func log(text: String, type: LogType, time: String, fileName: String, function: String, line: UInt) {
		handler.log(text: text, type: type, time: time, fileName: fileName, function: function, line: line)
	}
}

public class OSLogHandler : LogHandler {
	//let oslog = OSLog(subsystem: "com.mycompany.myapp", category: "myapp")
	
	public func log(text: String, type: LogType, time: String, fileName: String, function: String, line: UInt) {
		let location = "<\(fileName):\(line)>"
		os_log("%s %s", type: type.type, location, text)
	}
}

//public class FileLogHandler : LogHandler {
//}

//public class FTPLogHandler : LogHandler {
//}

//public class SQLLogHandler : LogHandler {
//}

//public class JSONLogHandler : LogHandler {
//}

class DLog {
	let handlers: [LogHandler]
	
	init(handlers: [LogHandler] = [AutoLogHandler()]) {
		self.handlers = handlers
	}
	
	private let debugDateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "HH:mm:ss:SSS"
		return dateFormatter
	}()
	
	private func log(_ text: String, type: LogType, file: String, function: String, line: UInt) {
		let fileName = NSString(string: file).lastPathComponent
		let time = debugDateFormatter.string(from: Date())
		
		handlers.forEach {
			$0.log(text: text, type: type, time: time, fileName: fileName, function: function, line: line)
		}
	}
	
	public func trace(_ text: String = "", file: String = #file, function: String = #function, line: UInt = #line) {
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
}

/*
public func dlog(_ items: String..., icon: Character = "▶️", file: String = #file, function: String = #function, line: UInt = #line) {
	let text = items.count > 0 ? items.joined(separator: " ") : function
	let fileName = NSString(string: file).lastPathComponent
	let time = debugDateFormatter.string(from: Date())
	
	let head = "[\(time)] [DLOG] \(icon) <\(fileName):\(line)>"
	print(head, text)
	//NSLog(text)
	print("\("⚠️ [dlog] print", color: .red)")
	
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
*/

public func asyncAfter(_ sec: Double = 0.25, closure: @escaping (() -> Void) ) {
	DispatchQueue.global().asyncAfter(deadline: .now() + sec) {
		closure()
    }
}
