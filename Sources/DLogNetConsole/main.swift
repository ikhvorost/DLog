import Foundation

class DLogNetConsole : NSObject {
	let name: String
	let service: NetService
	var inputStream: InputStream?
	
	static let bufferSize = 1024
	var buffer = [UInt8](repeating: 0, count: bufferSize)
	
	init(name: String = "DLog") {
		self.name = name
		service = NetService(domain: "local.", type:"_dlog._tcp.", name: name, port: 0)
		super.init()
		
		service.delegate = self
		service.publish(options: .listenForConnections)
	}
}

extension DLogNetConsole : NetServiceDelegate {
	func netServiceDidPublish(_ sender: NetService) {
		print("[Published] Name:", name, "Domain:", sender.domain, "Type:", sender.type, "Port:", sender.port)
	}

	func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
		print("[Error]", errorDict)
	}

	func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
		// IP address
		if let addr = sender.addresses?.first {
			//https://stackoverflow.com/questions/12558305/how-to-get-ip-address-from-netservice/18428117
			print("[Connected]", addr)
		}
		else {
			print("[Connected] localhost")
		}
		
		self.inputStream = inputStream
		inputStream.delegate = self
		inputStream.schedule(in: .current, forMode: .default)
		inputStream.open()
	}
}

extension DLogNetConsole : StreamDelegate {
	
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
let service = DLogNetConsole()

print("DLog NetConsole v.1.0")
RunLoop.current.run()

