//
//  NetConsole for DLog
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/09/01.
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
import ArgumentParser


class Service : NSObject {
	let name: String
	let debug: Bool
	let service: NetService
	var inputStream: InputStream?
	
	static let bufferSize = 1024
	var buffer = [UInt8](repeating: 0, count: bufferSize)
	
	init(name: String, debug: Bool) {
		self.name = name
		self.debug = debug
		
		service = NetService(domain: "local.", type:"_dlog._tcp.", name: name, port: 0)
		super.init()
		
		service.delegate = self
		service.publish(options: .listenForConnections)
	}
	
	private func log(_ text: String) {
		guard debug else { return }
		print("[NetConsole]", text)
	}
}

extension Service : NetServiceDelegate {
	
	func netServiceDidPublish(_ sender: NetService) {
		log("Published name:'\(sender.name)', domain:'\(sender.domain)', type:'\(sender.type)', port: \(sender.port)")
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

extension Service : StreamDelegate {
	
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

struct NetConsole: ParsableCommand {
	
	static let configuration = CommandConfiguration(abstract: "NetConsole for DLog v.1.0")
	
	@Option(
		name: [.long, .short],
		help: "The name by which the service is identified to the network. The name must be unique and by default it equals \"DLog\". If you pass the empty string (\"\"), the system automatically advertises your service using the computer name as the service name.")
	var name: String?
	
	@Flag(
		name: [.long, .short],
		help: "Enable debug messages.")
	var debug = false
	
	func run() throws {
		let _ = Service(name: name ?? "DLog", debug: debug)
		RunLoop.current.run()
	}
}
NetConsole.main()
