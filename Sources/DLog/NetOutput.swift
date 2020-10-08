//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 13.08.2020.
//

import Foundation

// TODO: file cache
public class NetOutput : LogOutput {
	private let name: String
	private let browser = NetServiceBrowser()
	private var service: NetService?
	private let queue = DispatchQueue(label: "NetOutput")
	private var outputStream : OutputStream?
	@Atomic private var buffer = ""
	
	init(name: String) {
		self.name = name
		
		super.init()
		
		output = .textColor
		
		browser.delegate = self
		browser.searchForServices(ofType: "_dlog._tcp", inDomain: "local.")
	}
	
	deinit {
		outputStream?.close()
	}
	
	@discardableResult
	private func send(_ text: String?) -> String? {
		if let str = text, !str.isEmpty {
			queue.async {
				guard let stream = self.outputStream else {
					self.buffer += (self.buffer.isEmpty ? "" : "\n") + str
					return
				}
				
				let data = str + "\n"
				stream.write(data, maxLength: data.lengthOfBytes(using: .utf8))
			}
		}
		
		return text
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
		
		NSLog("[NetOutput] connected")
		
		self.service = service
		
		CFWriteStreamSetDispatchQueue(outputStream, queue)
		outputStream?.delegate = self
		outputStream?.open()
	}
	
	public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
		guard self.service == service else { return }
		
		outputStream?.close()
		outputStream = nil
		self.service = nil
		
		NSLog("[NetOutput] disconnected")
	}
}


extension NetOutput : StreamDelegate {
	
	public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
		if eventCode == .hasSpaceAvailable {
			if !buffer.isEmpty {
				send(buffer)
				buffer = ""
			}
		}
	}
}
