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

// MARK: Configuration

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

public struct StackOptions: OptionSet {
	public let rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	public static let depth = TraceOptions(rawValue: 1 << 0)
	public static let module = TraceOptions(rawValue: 1 << 1)
}

public struct StackConfig {
	let options: StackOptions = []
	let depth = 0
	// style
}

public struct TraceConfig {
	public var options: TraceOptions
	public var threadOptions: ThreadOptions = []
	public var stack = StackConfig()
	
	public init(options: TraceOptions = .compact) {
		self.options = options
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

public struct ThreadOptions: OptionSet {
	public let rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	public static let priority = ThreadOptions(rawValue: 1 << 0)
	public static let qos = ThreadOptions(rawValue: 1 << 1)
	public static let stackSize = ThreadOptions(rawValue: 1 << 2)
	
	public static let all: ThreadOptions = [.priority, .qos, .stackSize]
}

fileprivate extension Thread {
	
	// <NSThread: 0x100d04870>{number = 1, name = main}
	static let regexThread = try? NSRegularExpression(pattern: "number = ([0-9]+), name = ([^}]+)")
	
	func info(options: ThreadOptions = []) -> String {
		var text = "Thread"
		
		// Description
		let nsString = description as NSString
		if let match = Self.regexThread?.matches(in: description, options: [], range: NSMakeRange(0, nsString.length)).first,
		   match.numberOfRanges == 3 {
			let number = nsString.substring(with: match.range(at: 1))
			text += " \(number)"
			
			let name = nsString.substring(with: match.range(at: 2))
			if name != "(null)" {
				text += " (\(name))"
			}
		}
		
		if options.rawValue != 0 {
			var items = [String]()
			
			// Priority
			if options.contains(.priority) {
				items.append("priority: \(threadPriority)")
			}
			
			// QoS
			if options.contains(.qos) {
				items.append("qos: \"\(qualityOfService.description)\"")
			}
			
			// Stack size
			if options.contains(.stackSize) {
				let size = ByteCountFormatter.string(fromByteCount: Int64(stackSize), countStyle: .memory)
				items.append("stack size: \(size)")
			}
			
			text += ": { \(items.joined(separator: ", ")) }"
		}
		
		return text
	}
}

// MARK: - Stack

// https://github.com/apple/swift/tree/main/include/swift/Demangling
// https://github.com/apple/swift/blob/main/stdlib/public/runtime/Demangle.cpp
fileprivate typealias Swift_Demangle = @convention(c) (_ mangledName: UnsafePointer<UInt8>?,
										   _ mangledNameLength: Int,
										   _ outputBuffer: UnsafeMutablePointer<UInt8>?,
										   _ outputBufferSize: UnsafeMutablePointer<Int>?,
										   _ flags: UInt32) -> UnsafeMutablePointer<Int8>?

fileprivate let _swift_demangle: Swift_Demangle? = {
	let RTLD_DEFAULT = dlopen(nil, RTLD_NOW)
	if let sym = dlsym(RTLD_DEFAULT, "swift_demangle") {
		return unsafeBitCast(sym, to: Swift_Demangle.self)
	}
	return nil
}()

fileprivate func swift_demangle(_ mangled: String) -> String? {
	guard mangled.hasPrefix("$s") else { return nil }
	
	if let cString = _swift_demangle?(mangled, mangled.count, nil, nil, 0) {
		defer { cString.deallocate() }
		return String(cString: cString)
	}
	return nil
}

struct StackItem {
	
	enum ItemType {
		case unknown
		case function
		case closure
		case thunk
		case getter
	}
	
	let depth: Int
	let module: String
	let type: ItemType
	let name: String
	//let params: String = ""
	
	static let regexClosure = try! NSRegularExpression(pattern: "^closure #\\d+")
	static let regexExtension = try! NSRegularExpression(pattern: "(static )?\\(extension in \\S+\\):([^\\(]+)")
	static let regexFunction = try! NSRegularExpression(pattern: "^[^\\(]+")
	
	init(depth: Int, module: String, from text: String) {
		self.depth = depth
		self.module = module
		
		var type: ItemType = .unknown
		var name = text
		
		let range = NSMakeRange(0, text.count)
		
		//*
		// reabstraction thunk helper from @escaping @callee_guaranteed () -> () to @escaping @callee_unowned @convention(block) () -> ()
		if text.hasPrefix("reabstraction") {
			type = .thunk
			name = "thunk"
		}
		// closure #1 () -> Swift.String in (extension in DLog):DLog.LogProtocol.trace(_: @autoclosure () -> Swift.Optional<Swift.String>, options: DLog.TraceOptions, file: Swift.String, function: Swift.String, line: Swift.UInt) -> Swift.Optional<Swift.String>
		// closure #2 () -> () in DLogTests.DLogTests.test_trace() -> ()
		else if let match = Self.regexClosure.matches(in: text, range: range).first {
			type = .closure
			name = (text as NSString).substring(with: match.range)
		}
		// static (extension in DLog):__C.NSThread.(callStack in _2FF057552DC5FD3D49D622420632695F).getter : Swift.String
		// (extension in DLog):DLog.LogProtocol.trace(_: @autoclosure () -> Swift.Optional<Swift.String>, options: DLog.TraceOptions, file: Swift.String, function: Swift.String, line: Swift.UInt) -> Swift.Optional<Swift.String>
		else if let match = Self.regexExtension.matches(in: text, range: range).first, match.numberOfRanges == 3 {
			type = .function
			name = (text as NSString).substring(with: match.range(at: 2))
		}
		// DLog.DLog.log(text: () -> Swift.String, type: DLog.LogType, category: Swift.String, scope: Swift.Optional<DLog.LogScope>, file: Swift.String, function: Swift.String, line: Swift.UInt) -> Swift.Optional<Swift.String>
		else if let match = Self.regexFunction.matches(in: text, range: range).first {
			type = .function
			name = (text as NSString).substring(with: match.range)
		}
		else {
			type = .unknown
			name = text
		}
		// */
		
		self.type = type
		self.name = name
	}
}

// 1 DLogTests 0x00000001034d42ac $s4DLog9traceInfoyS2SF + 812
let regex = try! NSRegularExpression(pattern: "(\\d+)\\s+(\\S+)\\s+0x[0-9a-f]+\\s+([^+]+)")

func callStack(_ callStackSymbols: ArraySlice<String>) -> String {
	var items = [StackItem]()
	
	for line in callStackSymbols {
		if let match = regex.matches(in: line, range: NSMakeRange(0, line.count)).first, match.numberOfRanges == 4 {
			let ns_line = line as NSString
			let depth = Int(ns_line.substring(with: match.range(at: 1))) ?? 0
			
			let module = ns_line.substring(with: match.range(at: 2))
			
			var name = ns_line.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespaces)
			if let demangled = swift_demangle(name) {
				name = demangled
				
				// Double module name
				if let range = name.range(of: "\(module).\(module)") {
					name.replaceSubrange(range, with: module)
				}
			}
			
			let item = StackItem(depth: depth, module: module, from: name)
			items.append(item)
		}
	}
	
	return items.reduce("") { result, item in
		result + "\(item.depth)\t" + item.module + "\t" + item.name + "\n"
	}
}

// Thread: name number
// Queue: label
// Func: name params
// Stack depth
func traceInfo(_ function: String, callStackSymbols: ArraySlice<String>, config: TraceConfig) -> String {
	var items = [String]()
	
	// Thread
	if config.options.contains(.thread) {
		items.append(Thread.current.info())
	}
	
	// Queue
	if config.options.contains(.queue) {
		let label = String(cString: __dispatch_queue_get_label(nil))
		items.append("Queue: \(label)")
	}
	
	// Function
	if config.options.contains(.function) {
		items.append("\(function)")
	}
	
	// Stack
	if config.options.contains(.stack) {
		items.append("Stack: \(callStack(callStackSymbols))")
	}
	
	return items.joined(separator: ", ")
}
