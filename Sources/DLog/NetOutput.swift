//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 13.08.2020.
//

import Foundation

class NetOutput : NSObject {
	let service: NetService
	var outputStream : OutputStream?
	let output: TextOutput
	var buffer = ""
	
	init(serviceName: String = "DLog", output: TextOutput = ColoredOutput()) {
		service = NetService(domain: "local.", type: "_dlog._tcp.", name: serviceName)
		self.output = output
		
		super.init()
		
		service.delegate = self
		service.resolve(withTimeout: 3)
	}
	
	deinit {
		outputStream?.close()
	}
	
	func send(_ text: String) -> String {
		DispatchQueue.main.async {
			guard let stream = self.outputStream else {
				self.buffer += (self.buffer.isEmpty ? "" : "\n") + text
				return
			}
			
			let str = text + "\n"
			stream.write(str, maxLength: str.lengthOfBytes(using: .utf8))
		}
		
		return text
	}
	
}

extension NetOutput : NetServiceDelegate {
	
	func netServiceDidResolveAddress(_ sender: NetService) {
		print(#function)
		
		if sender.getInputStream(nil, outputStream: &outputStream) {
			assert(outputStream != nil)
			
			outputStream?.schedule(in: .current, forMode: .default)
			outputStream?.open()
			//outputStream?.delegate = self
			
			if !buffer.isEmpty {
				_ = send(buffer)
				buffer = ""
			}
		}
	}
	
	func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
		print(errorDict)
	}
	
	func netServiceDidStop(_ sender: NetService) {
		//print(sender)
	}
}

extension NetOutput : LogOutput {
	public func log(message: LogMessage) -> String {
		send(output.log(message: message))
	}
	
	public func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String {
		send(output.scopeEnter(scope: scope, scopes: scopes))
	}
	
	public func scopeLeave(scope: LogScope, scopes: [LogScope])  -> String {
		send(output.scopeLeave(scope: scope, scopes: scopes))
	}
	
	public func intervalBegin(interval: LogInterval) {
	}
	
	public func intervalEnd(interval: LogInterval) -> String {
		send(output.intervalEnd(interval: interval))
	}
}
