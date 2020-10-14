import Foundation


class NetConsole : NSObject {
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
	
	private func log(_ text: String) {
		print("[NetConsole]", text)
	}
}

extension NetConsole : NetServiceDelegate {
	
	func netServiceDidPublish(_ sender: NetService) {
		log("Published name: \(name), domain: \(sender.domain), type: \(sender.type), port: \(sender.port)")
	}

	func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
		log("Error: \(errorDict)")
	}

	func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
		guard self.inputStream == nil else {
			// Reject connection
			inputStream.open(); outputStream.open()
			inputStream.close(); outputStream.close()
			return
		}
		
		self.inputStream = inputStream
		inputStream.delegate = self
		inputStream.schedule(in: .current, forMode: .default)
		inputStream.open()
		
		log("Connected")
	}
}

extension NetConsole : StreamDelegate {
	
	func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
		switch eventCode {
			case .openCompleted:
				log("Opened")
				
			case .hasBytesAvailable:
				guard let stream = inputStream else { return }
				
				while stream.hasBytesAvailable {
					let count = stream.read(&buffer, maxLength: Self.bufferSize)
					if count > 0 {
						if let text = String(bytes: buffer[0..<count], encoding: .utf8) {
							print(text, terminator: "")
						}
					}
				}
			
			case .errorOccurred:
				if let error = aStream.streamError {
					log("Error: \(error.localizedDescription)")
				}
				
			case .endEncountered:
				inputStream = nil
				log("Disconnected")
				
			default:
				break;
		}
	}
}

// Run
let service = NetConsole()

print("DLog NetConsole v.1.0")
RunLoop.current.run()
