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

fileprivate func demangle(_ mangled: String) -> String? {
	guard mangled.hasPrefix("$s") else { return nil }
	
    if let cString = Dynamic.swift_demangle?(mangled, mangled.count, nil, nil, 0) {
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

func traceInfo(title: String?, function: String, addresses: ArraySlice<NSNumber>, traceConfig: TraceConfig) -> String {
	
	let items: [(TraceOptions, String, () -> String)] = [
		(.function, "func", { function }),
		(.queue, "queue", { "\(String(cString: __dispatch_queue_get_label(nil)))" }),
		(.thread, "thread", { "\(Thread.current.description(config: traceConfig.threadConfig))" }),
		(.stack, "stack", { "\(stack(addresses, config: traceConfig.stackConfig))" }),
	]
	
	return jsonDescription(title: title ?? "", items: items, options: traceConfig.options)
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

extension Array where Element == String {
    func joinedCompact() -> String {
        compactMap { $0.isEmpty ? nil : $0 }.joined(separator: " ")
    }
}

func dictionary<Option: OptionSet>(from items: [(Option, String, () -> Any)], options: Option) -> [String : Any] {
    let keyValues: [(String, Any)] = items
        .compactMap {
            if options.contains($0.0 as! Option.Element) {
                let key = $0.1
                let value = $0.2()
                return (key, value)
            }
            return nil
        }
    return Dictionary(uniqueKeysWithValues: keyValues)
}
