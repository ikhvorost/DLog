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

// TODO: file cache
public class NetOutput : LogOutput {
	private let name: String
	private let browser = NetServiceBrowser()
	private var service: NetService?
	private let queue = DispatchQueue(label: "NetOutput")
	private var outputStream : OutputStream?
	private let buffer = LogBuffer()
	
	init(name: String) {
		self.name = name
		
		super.init()
		
		output = .textColor
		
		browser.delegate = self
		browser.searchForServices(ofType: "_dlog._tcp", inDomain: "local.")
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
				log("Opened")
			
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
