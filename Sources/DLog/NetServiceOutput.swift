//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 13.08.2020.
//

import Foundation

class NetServiceOutput : LogOutput {
	let service: NetService
	var outputStream : OutputStream?
	var buffer = ""
	
	init(serviceName: String = "DLog") {
		service = NetService(domain: "local.", type: "_dlog._tcp.", name: serviceName)
		
		super.init()
		
		self.output = ColoredOutput()
		
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
	
	// MARK: - LogOutput
	
	override func log(message: LogMessage) -> String {
		send(output.log(message: message))
	}
	
	override func scopeEnter(scope: LogScope, scopes: [LogScope]) -> String {
		send(output.scopeEnter(scope: scope, scopes: scopes))
	}
	
	override func scopeLeave(scope: LogScope, scopes: [LogScope])  -> String {
		send(output.scopeLeave(scope: scope, scopes: scopes))
	}
	
	override func intervalBegin(interval: LogInterval) {
	}
	
	override func intervalEnd(interval: LogInterval) -> String {
		send(output.intervalEnd(interval: interval))
	}
	
}

extension NetServiceOutput : NetServiceDelegate {
	
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
