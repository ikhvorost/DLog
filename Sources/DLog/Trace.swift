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

/// Indicates which info from threads should be used.
public struct ThreadOptions: OptionSet {
	/// The corresponding value of the raw type.
	public let rawValue: Int
	
	/// Creates a new option set from the given raw value.
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	/// Number
	public static let number = Self(0)
	
	/// Name (if it exists)
	public static let name = Self(1)
	
	/// Priority
	public static let priority = Self(2)
	
	/// QoS
	public static let qos = Self(3)
	
	/// Stack size
	public static let stackSize = Self(4)
	
	/// Compact: `.number` and `.name`
	public static let compact: Self = [.number, .name]
	
	/// Regular: `.number`, `.name` and `.qos`
	public static let regular: Self = [.number, .name, .qos]
}

/// Contains configuration values regarding to thread info.
public struct ThreadConfig {
	
	/// Set which info from threads should be used. Default value is `ThreadOptions.compact`.
	public var options: ThreadOptions = .compact
}

/// Indicates which info from stacks should be used.
public struct StackOptions: OptionSet {
	/// The corresponding value of the raw type.
	public let rawValue: Int
	
	/// Creates a new option set from the given raw value.
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	/// Module name
	public static let module = Self(0)
	
	/// Address
	public static let address = Self(1)
	
	/// Stack symbols
	public static let symbols = Self(2)
	
	/// Offset
	public static let offset = Self(3)
}

/// View style of stack info
public enum StackViewStyle {
	/// Flat view
	case flat
	
	/// Column view
	case column
}

/// Contains configuration values regarding to stack info
public struct StackConfig {
	/// Set which info from stacks should be used. Default value is `StackOptions.symbols`.
	public var options: StackOptions = .symbols
	
	/// Depth of stack
	public var depth = 0
	
	/// View style of stack
	public var style: StackViewStyle = .flat
}

/// Indicates which info from the `trace` method should be used.
public struct TraceOptions: OptionSet {
	/// The corresponding value of the raw type.
	public let rawValue: Int
	
	/// Creates a new option set from the given raw value.
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	/// Thread
	public static let thread = Self(0)
	
	/// Queue
	public static let queue = Self(1)
	
	/// Function
	public static let function = Self(2)
	
	/// Stack
	public static let stack = Self(3)
	
	/// Compact: `.thread` and `.function`
	public static let compact: Self = [.thread, .function]
	
	/// Regular: `.thread`, `.queue` and `.function`
	public static let regular: Self = [.thread, .queue, .function]
}

/// Contains configuration values regarding to the `trace` method.
public struct TraceConfig {
	/// Set which info from the `trace` method should be used. Default value is `TraceOptions.compact`.
	public var options: TraceOptions = .compact
	
	/// Configuration of thread info
	public var threadConfig = ThreadConfig()
	
	/// Configuration of stack info
	public var stackConfig = StackConfig()
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
        precondition(Self.names[self] != nil)
        return Self.names[self]!
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
		.compactMap { address -> (String, UInt, String, UInt)? in
			let pointer = UnsafeRawPointer(bitPattern: address.uintValue)
			guard dladdr(pointer, &info) != 0 else {
				return nil
			}
			
			let fname = String(validatingUTF8: info.dli_fname)!
			let module = (fname as NSString).lastPathComponent
			
			let sname = String(validatingUTF8: info.dli_sname)!
			let name = demangle(sname) ?? sname
			
			let offset = address.uintValue - UInt(bitPattern: info.dli_saddr)
			
			return (module, address.uintValue, name, offset)
		}
		.prefix(config.depth > 0 ? config.depth : addresses.count)
		.enumerated()
		.map { item in
			let items: [(StackOptions, String, () -> String)] = [
				(.module, "module", { "\(item.element.0)" }),
				(.address, "address", { String(format:"0x%016llx", item.element.1) }),
				(.symbols, "symbols", { "\(item.element.2)" }),
				(.offset, "offset", { "\(item.element.3)" }),
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
		(.thread, "thread", { "\(Thread.current.description(config: config.threadConfig))" }),
		(.stack, "stack", { "\(stack(addresses, config: config.stackConfig))" }),
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
