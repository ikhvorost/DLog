import Foundation

class DLogNetService : NSObject {
	let service: NetService
	var inputStream: InputStream?
	
	static let bufferSize = 1024
	var buffer = [UInt8](repeating: 0, count: bufferSize)
	
	init(name: String = "DLog") {
		service = NetService(domain: "local.", type:"_dlog._tcp.", name: name, port: 0)
		super.init()
		
		service.delegate = self
		service.publish(options: .listenForConnections)
	}
}

extension DLogNetService : NetServiceDelegate {
	func netServiceDidPublish(_ sender: NetService) {
		print("Domain:", sender.domain, "Type:", sender.type, "Port:", sender.port)
	}

	func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
		print(errorDict)
	}
	
	func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
		print(errorDict)
	}
	
	func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
		/* IP address
		print(sender.addresses)
		if let data = sender.addresses?.first {
			var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
			data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Void in
					let sockaddrPtr = pointer.bindMemory(to: sockaddr.self)
					guard let unsafePtr = sockaddrPtr.baseAddress else { return }
					guard getnameinfo(unsafePtr, socklen_t(data.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else {
						return
					}
			}
			let ipAddress = String(cString:hostname)
			print(ipAddress)
			
			print("Accept:", ipAddress)
		}
		// */
		
		self.inputStream = inputStream
		inputStream.delegate = self
		inputStream.schedule(in: .current, forMode: .default)
		inputStream.open()
		
		// Clear
		print("\u{001b}c")
	}
	
	func netServiceDidStop(_ sender: NetService) {
		//print(#function)
	}
}

extension DLogNetService : StreamDelegate {
	
	func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
		if eventCode == .hasBytesAvailable {
			guard let stream = inputStream else { return }
			
			while stream.hasBytesAvailable {
				let count = stream.read(&buffer, maxLength: Self.bufferSize)
				if count > 0 {
					if let text = String(bytes: buffer[0..<count], encoding: .utf8) {
						print(text, terminator: "")
					}
				}
			}
		}
		
	}
}

// Run
let service = DLogNetService()

print("DLog Net Service v.1.0")
RunLoop.current.run()

