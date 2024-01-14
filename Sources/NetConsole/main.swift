//
//	main.swift
//
//	NetConsole for DLog
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

#if !os(watchOS)

class Service : NSObject {

  enum ANSIEscapeCode: String {
    case reset = "\u{001b}[0m"
    case clear = "\u{001b}c"
    
    case bold = "\u{001b}[1m"
    case dim = "\u{001b}[2m"
    case underline = "\u{001b}[4m"
    case blink = "\u{001b}[5m"
    case reversed = "\u{001b}[7m"
  }
  
  let name: String
  let debug: Bool
  let autoClear: Bool
  
  let service: NetService
  var inputStream: InputStream?
  
  static let bufferSize = 1024
  var buffer = [UInt8](repeating: 0, count: bufferSize)
  
  deinit {
    log("deinit")
  }
  
  init(name: String, debug: Bool, autoClear: Bool) {
    self.name = name
    self.debug = debug
    self.autoClear = autoClear
    
    service = NetService(domain: "local.", type:"_dlog._tcp.", name: name, port: 0)
    super.init()
    
    service.delegate = self
    service.publish(options: .listenForConnections)
  }
  
  private func log(_ text: String) {
    guard debug else { return }
    
    print("\(ANSIEscapeCode.dim.rawValue)[NetConsole]", text, ANSIEscapeCode.reset.rawValue)
  }
  
  private func reject(inputStream: InputStream, outputStream: OutputStream) {
    inputStream.open(); outputStream.open()
    inputStream.close(); outputStream.close()
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
      reject(inputStream: inputStream, outputStream: outputStream)
      return
    }
    
    self.inputStream = inputStream
    inputStream.delegate = self
    inputStream.schedule(in: .current, forMode: .default)
    inputStream.open()
    
    if autoClear {
      print(ANSIEscapeCode.clear.rawValue)
    }
    
    log("Connected")
  }
}

extension Service : StreamDelegate {
  
  func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    switch eventCode {
      case .openCompleted:
        log("Input stream is opened")
        
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
        log("Input stream is ended")
        
      default:
        break;
    }
  }
}

// Arguments

let arguments = Arguments()

let overview = "NetConsole v.1.1"

var help = arguments.boolValue(forKeys: ["--help", "-h"])
guard !help else {
  print(
"""
OVERVIEW: \(overview)

USAGE: netconsole [--name <name>] [--auto-clear] [--debug]

OPTIONS:
  -n, --name <name>		The name by which the service is identified to the network. The name must be unique and by default it equals
    "DLog". If you pass the empty string (""), the system automatically advertises your service using the computer
    name as the service name.
  -a, --auto-clear		Clear a terminal on new connection.
  -d, --debug			Enable debug messages.
  -h, --help			Show help information.
"""
  )
  exit(EXIT_SUCCESS)
}

var name = arguments.stringValue(forKeys: ["--name", "-n"], defaultValue: "DLog")
var autoClear = arguments.boolValue(forKeys: ["--auto-clear", "-a"])
var debug = arguments.boolValue(forKeys: ["--debug", "-d"])

let _ = Service(name: name, debug: debug, autoClear: autoClear)

print(overview)

RunLoop.main.run()

#endif
