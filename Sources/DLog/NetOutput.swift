//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 13.08.2020.
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

public class NetOutput : LogOutput {
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
		
		output = .textColor
		
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
	
	public override func log(message: LogMessage) -> String? {
		send(super.log(message: message))
	}
	
	public override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String? {
		send(super.scopeEnter(scope: scope, scopes: scopes))
	}
	
	public override func scopeLeave(scope: LogScope, scopes: [LogScope]) -> String? {
		send(super.scopeLeave(scope: scope, scopes: scopes))
	}
	
	public override func intervalEnd(interval: LogInterval) -> String? {
		send(super.intervalEnd(interval: interval))
	}
}

extension NetOutput : NetServiceBrowserDelegate {
	
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

extension NetOutput : StreamDelegate {
	
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
