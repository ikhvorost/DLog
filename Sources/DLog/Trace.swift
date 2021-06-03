//
//  Trace.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2021/04/15.
//  Copyright © 2021 Iurii Khvorost. All rights reserved.
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

// MARK: - Configuration

public struct TraceOptions: OptionSet {
	public let rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	public static let thread = TraceOptions(rawValue: 1 << 0)
	public static let queue = TraceOptions(rawValue: 1 << 1)
	public static let function = TraceOptions(rawValue: 1 << 2)
	public static let stack = TraceOptions(rawValue: 1 << 3)
	
	public static let compact: TraceOptions = [.thread, .function]
	public static let regular: TraceOptions = [.thread, .queue, .function]
	public static let all: TraceOptions = [.thread, .queue, .function, .stack]
}

public struct ThreadOptions: OptionSet {
	public let rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	public static let number = ThreadOptions(rawValue: 1 << 0)
	public static let name = ThreadOptions(rawValue: 1 << 1)
	public static let priority = ThreadOptions(rawValue: 1 << 2)
	public static let qos = ThreadOptions(rawValue: 1 << 3)
	public static let stackSize = ThreadOptions(rawValue: 1 << 4)
	
	public static let compact: ThreadOptions = [.number, .name]
	public static let regular: ThreadOptions = [.number, .name, .qos]
	public static let all: ThreadOptions = [.number, .name, .qos, .priority, .stackSize]
}

public struct ThreadConfig {
	public var options: ThreadOptions
	
	public init(options: ThreadOptions = .compact) {
		self.options = options
	}
}

public struct StackOptions: OptionSet {
	public let rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	public static let module = StackOptions(rawValue: 1 << 1)
	public static let symbols = StackOptions(rawValue: 1 << 2)
	
	public static let all: StackOptions = [.module, .symbols]
}

public enum StackStyle {
	case flat
	case column
}

public struct StackConfig {
	public var options: StackOptions
	public var depth: Int
	public var style: StackStyle
	
	public init(options: StackOptions = .symbols, depth: Int = 0, style: StackStyle = .flat) {
		self.options = options
		self.depth = depth
		self.style = style
	}
}

public struct TraceConfig {
	public var options: TraceOptions
	public var thread: ThreadConfig
	public var stack: StackConfig
	
	public init(options: TraceOptions = .compact, thread: ThreadConfig = ThreadConfig(), stack: StackConfig = StackConfig()) {
		self.options = options
		self.thread = thread
		self.stack = stack
	}
}

// MARK: - Thread

fileprivate extension QualityOfService {
	
	var description : String {
		switch self {
			case .userInteractive:
				return "user interactive"
			case .userInitiated:
				return "user initiated"
			case .utility:
				return "utility"
			case .background:
				return "background"
			case .default:
				return "background"
			default:
				return "unknown"
		}
	}
}

fileprivate extension Thread {
	
	// <NSThread: 0x100d04870>{number = 1, name = main}
	static let regexThread = try? NSRegularExpression(pattern: "number = ([0-9]+), name = ([^}]+)")
	
	func description(config: ThreadConfig) -> String {
		var number = ""
		var name = ""
		let nsString = description as NSString
		if let match = Self.regexThread?.matches(in: description, options: [], range: NSMakeRange(0, nsString.length)).first,
		   match.numberOfRanges == 3 {
			number = nsString.substring(with: match.range(at: 1))
			name = nsString.substring(with: match.range(at: 2))
			if name == "(null)" {
				name = ""
			}
		}
		
		let items: [(ThreadOptions, String, () -> String)] = [
			(.number, "number", { number }),
			(.name, "name", { name }),
			(.priority, "priority", { "\(self.threadPriority)" }),
			(.qos, "qos", { "\(self.qualityOfService.description)" }),
			(.stackSize, "stackSize", { "\(ByteCountFormatter.string(fromByteCount: Int64(self.stackSize), countStyle: .memory))" }),
		]
		
		return jsonDescription(title: "", items: items, options: config.options, braces: true)
	}
}

// MARK: - Stack

fileprivate typealias Swift_Demangle = @convention(c) (_ mangledName: UnsafePointer<UInt8>?,
													   _ mangledNameLength: Int,
													   _ outputBuffer: UnsafeMutablePointer<UInt8>?,
													   _ outputBufferSize: UnsafeMutablePointer<Int>?,
													   _ flags: UInt32) -> UnsafeMutablePointer<Int8>?

fileprivate let swift_demangle: Swift_Demangle? = {
	let RTLD_DEFAULT = dlopen(nil, RTLD_NOW)
	if let sym = dlsym(RTLD_DEFAULT, "swift_demangle") {
		return unsafeBitCast(sym, to: Swift_Demangle.self)
	}
	return nil
}()

fileprivate func demangle(_ mangled: String) -> String? {
	guard mangled.hasPrefix("$s") else { return nil }
	
	if let cString = swift_demangle?(mangled, mangled.count, nil, nil, 0) {
		defer { cString.deallocate() }
		return String(cString: cString)
	}
	return nil
}

/*
struct StackItem {
	let module: String
	let name: String
	
	static let regexClosure = try! NSRegularExpression(pattern: "^closure #\\d+")
	static let regexExtension = try! NSRegularExpression(pattern: "(static )?\\(extension in \\S+\\):([^\\(]+)")
	static let regexFunction = try! NSRegularExpression(pattern: "^[^\\(]+")
	
	init(module: String, from text: String) {
		self.module = module
		
		var name = text
		
		let range = NSMakeRange(0, text.count)
		
		//*
		// reabstraction thunk helper from @escaping @callee_guaranteed () -> () to @escaping @callee_unowned @convention(block) () -> ()
		if text.hasPrefix("reabstraction") {
			name = "thunk"
		}
		// closure #1 () -> Swift.String in (extension in DLog):DLog.LogProtocol.trace(_: @autoclosure () -> Swift.Optional<Swift.String>, options: DLog.TraceOptions, file: Swift.String, function: Swift.String, line: Swift.UInt) -> Swift.Optional<Swift.String>
		// closure #2 () -> () in DLogTests.DLogTests.test_trace() -> ()
		else if let match = Self.regexClosure.matches(in: text, range: range).first {
			name = (text as NSString).substring(with: match.range)
		}
		// static (extension in DLog):__C.NSThread.(callStack in _2FF057552DC5FD3D49D622420632695F).getter : Swift.String
		// (extension in DLog):DLog.LogProtocol.trace(_: @autoclosure () -> Swift.Optional<Swift.String>, options: DLog.TraceOptions, file: Swift.String, function: Swift.String, line: Swift.UInt) -> Swift.Optional<Swift.String>
		else if let match = Self.regexExtension.matches(in: text, range: range).first, match.numberOfRanges == 3 {
			name = (text as NSString).substring(with: match.range(at: 2))
		}
		// DLog.DLog.log(text: () -> Swift.String, type: DLog.LogType, category: Swift.String, scope: Swift.Optional<DLog.LogScope>, file: Swift.String, function: Swift.String, line: Swift.UInt) -> Swift.Optional<Swift.String>
		else if let match = Self.regexFunction.matches(in: text, range: range).first {
			name = (text as NSString).substring(with: match.range)
		}
		else {
			name = text
		}
		// */

		self.name = name
	}
}
*/

fileprivate func stack(_ addresses: ArraySlice<NSNumber>, config: StackConfig) -> String {
	var info = dl_info()
	
	var separator = "\n"
	if case .flat = config.style {
		separator = ", "
	}
	
	let text = addresses
		.dropLast(config.depth > 0 ? addresses.count - config.depth : 0)
		.compactMap { addr -> (String, String)? in
			guard dladdr(UnsafeRawPointer(bitPattern: addr.uintValue), &info) > 0 else {
				return nil
			}
			
			var module: String?
			if let dli_fname = info.dli_fname, let fname = String(validatingUTF8: dli_fname) {
				module = (fname as NSString).lastPathComponent
			}
			
			var name: String?
			if let dli_sname = info.dli_sname, let sname = String(validatingUTF8: dli_sname) {
				name = sname
				
				// Swift
				if let demangled = demangle(sname) {
					name = demangled
				}
			}
			
			if module != nil && name != nil {
				return (module!, name!)
			}
			
			return nil
		}
		.enumerated()
		.map { item in
			let items: [(StackOptions, String, () -> String)] = [
				(.module, "module", { "\(item.element.0)" }),
				(.symbols, "symbols", { "\(item.element.1)" }),
			]
			
			return jsonDescription(title: "\(item.offset)", items: items, options: config.options)
		}
		.joined(separator: separator)
	
	if case .flat = config.style {
		return "[ \(text) ]"
	}
	
	return "[\n\(text) ]"
}

func traceInfo(title: String?, function: String, addresses: ArraySlice<NSNumber>, config: TraceConfig) -> String {
	
	let items: [(TraceOptions, String, () -> String)] = [
		(.function, "func", { function }),
		(.queue, "queue", { "\(String(cString: __dispatch_queue_get_label(nil)))" }),
		(.thread, "thread", { "\(Thread.current.description(config: config.thread))" }),
		(.stack, "stack", { "\(stack(addresses, config: config.stack))" }),
	]
	
	return jsonDescription(title: title ?? "", items: items, options: config.options)
}

func jsonDescription<Option: OptionSet>(title: String, items: [(Option, String, () -> String)], options: Option, braces: Bool = false) -> String {
	let text = items
		.compactMap {
			if options.contains($0.0 as! Option.Element) {
				let name = $0.1
				let text = $0.2()
				if !text.isEmpty {
					return "\(name): \(text)"
				}
			}
			return nil
		}
		.joined(separator: ", ")
	
	guard !title.isEmpty || !text.isEmpty else { return "" }
	
	if title.isEmpty && !text.isEmpty {
		return braces ? "{ \(text) }" : text
	}
	else if !title.isEmpty && text.isEmpty {
		return title
	}
	
	return "\(title): { \(text) }"
}
