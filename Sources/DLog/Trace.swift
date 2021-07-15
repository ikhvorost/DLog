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
	
	public static let thread = Self(rawValue: 1 << 0)
	public static let queue = Self(rawValue: 1 << 1)
	public static let function = Self(rawValue: 1 << 2)
	public static let stack = Self(rawValue: 1 << 3)
	
	public static let compact: Self = [.thread, .function]
	public static let regular: Self = [.thread, .queue, .function]
	public static let all: Self = [.thread, .queue, .function, .stack]
}

public struct ThreadOptions: OptionSet {
	public let rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	public static let number = Self(rawValue: 1 << 0)
	public static let name = Self(rawValue: 1 << 1)
	public static let priority = Self(rawValue: 1 << 2)
	public static let qos = Self(rawValue: 1 << 3)
	public static let stackSize = Self(rawValue: 1 << 4)
	
	public static let compact: Self = [.number, .name]
	public static let regular: Self = [.number, .name, .qos]
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
	
	public static let module = Self(rawValue: 1 << 1)
	public static let symbols = Self(rawValue: 1 << 2)
	
	public static let all: Self = [.module, .symbols]
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
	
	static let names: [QualityOfService : String] = [
		.userInteractive : "userInteractive",
		.userInitiated: "userInitiated",
		.utility: "utility",
		.background: "background",
		.default :  "default",
	]
	
	var description : String {
		return Self.names[self] ?? "unknown"
	}
}

fileprivate extension Thread {
	
	// <NSThread: 0x100d04870>{number = 1, name = main}
	static let regexThread = try! NSRegularExpression(pattern: "number = ([0-9]+), name = ([^}]+)")
	
	func description(config: ThreadConfig) -> String {
		var number = ""
		var name = ""
		let nsString = description as NSString
		if let match = Self.regexThread.matches(in: description, options: [], range: NSMakeRange(0, nsString.length)).first,
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
			
			let fname = String(validatingUTF8: info.dli_fname)!
			let module = (fname as NSString).lastPathComponent
			
			let sname = String(validatingUTF8: info.dli_sname)!
			let name = demangle(sname) ?? sname
			
			return (module, name)
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
