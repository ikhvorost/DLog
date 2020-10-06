//
//  File.swift
//  
//
//  Created by Iurii Khvorost on 13.08.2020.
//

import Foundation

// TODO: file cache
public class NetServiceOutput : LogOutput {
	private let service: NetService
	private let queue = DispatchQueue(label: "NetServiceOutput")
	private var outputStream : OutputStream?
	private var buffer = ""
	
	init(serviceName: String = "DLog") {
		service = NetService(domain: "local.", type: "_dlog._tcp.", name: serviceName)
		
		super.init()
		
		output = .textColor
		
		service.delegate = self
		service.resolve(withTimeout: 3)
	}
	
	deinit {
		outputStream?.close()
	}
	
	private func send(_ text: String?) -> String? {
		if let str = text, !str.isEmpty {
			queue.async {
				guard let stream = self.outputStream else {
					self.buffer += (self.buffer.isEmpty ? "" : "\n") + str
					return
				}
				
				let str = str + "\n"
				stream.write(str, maxLength: str.lengthOfBytes(using: .utf8))
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

extension NetServiceOutput : NetServiceDelegate {
	
	public func netServiceDidResolveAddress(_ sender: NetService) {
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
	
	public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
		print(errorDict)
	}
	
	public func netServiceDidStop(_ sender: NetService) {
		//print(sender)
	}
}
