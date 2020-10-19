//
//  Net
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/08/13.
//  Copyright © 2020 Iurii Khvorost. All rights reserved.
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


private class LogBuffer {
	private static let linesCount = 1000
	
	@Atomic private var stack = [String]()
	
	var text: String? {
		stack.reduce(nil) { text, line in
			"\(text ?? "")\(line)\n"
		}
	}
	
	func append(text: String) {
		stack.append(text)
		if stack.count > Self.linesCount {
			_ = stack.removeFirst()
		}
	}
	
	func clear() {
		stack.removeAll()
	}
}

public class Net : LogOutput {
	private static let type = "_dlog._tcp"
	private static let domain = "local."
	
	private let name: String
	private let debug: Bool
	private let browser = NetServiceBrowser()
	private var service: NetService?
	private let queue = DispatchQueue(label: "NetOutput")
	private var outputStream : OutputStream?
	private let buffer = LogBuffer()
	
	init(name: String, debug: Bool) {
		self.name = name
		self.debug = debug
		
		super.init()
		
		output = .coloredText
		
		browser.delegate = self
		browser.searchForServices(ofType: Self.type, inDomain: Self.domain)
	}
	
	deinit {
		outputStream?.close()
		browser.stop()
	}
	
	@discardableResult
	private func send(_ text: String?, newline: Bool = true) -> String? {
		if let str = text, !str.isEmpty {
			queue.async {
				if let stream = self.outputStream {
					let data = str + (newline ? "\n" : "")
					stream.write(data, maxLength: data.lengthOfBytes(using: .utf8))
				}
				else {
					self.buffer.append(text: str)
				}
			}
		}
		
		return text
	}
	
	private func log(_ text: String) {
		guard debug else { return }
		print("[NetOutput] \(text)")
	}
	
	// MARK: - LogOutput
	
	override func log(message: LogMessage) -> String? {
		send(super.log(message: message))
	}
	
	override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		send(super.scopeEnter(scope: scope, scopes: scopes))
	}
	
	override func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		send(super.scopeLeave(scope: scope, scopes: scopes))
	}
	
	override func intervalEnd(interval: LogInterval) -> String? {
		send(super.intervalEnd(interval: interval))
	}
}

extension Net : NetServiceBrowserDelegate {
	
	public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
		log("Begin search name:'\(name)', type:'\(Self.type)', domain:'\(Self.domain)'")
	}
	
	public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
		log("Stop search")
	}
	
	public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
		log("Error: \(errorDict)")
	}
	
	public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
		guard service.name == self.name,
			  self.service == nil,
			  service.getInputStream(nil, outputStream: &outputStream)
		else { return }
		
		log("Connected")
		
		self.service = service
		//self.service?.delegate = self
		//self.service?.resolve(withTimeout: 10)
		
		CFWriteStreamSetDispatchQueue(outputStream, queue)
		outputStream?.delegate = self
		outputStream?.open()
	}
	
	public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
		guard self.service == service else { return }
		
		outputStream?.close()
		outputStream = nil
		self.service = nil
		
		log("Disconnected")
	}
}

//extension NetOutput : NetServiceDelegate {
//
//	public func netServiceDidResolveAddress(_ sender: NetService) {
//		print(sender.addresses?.first)
//	}
//
//}

extension Net : StreamDelegate {
	
	public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
		switch eventCode{
			case .openCompleted:
				log("Output stream is opened")
			
			case .hasSpaceAvailable:
				if let text = buffer.text {
					send(text, newline: false)
					buffer.clear()
				}
				
			case .errorOccurred:
				if let error = aStream.streamError {
					log("Error: \(error.localizedDescription)")
				}
			
			default:
				break
		}
	}
}
