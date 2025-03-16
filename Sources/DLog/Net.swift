//
//  Net.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/08/13.
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

extension NetService: @unchecked @retroactive Sendable {}
extension OutputStream: @unchecked @retroactive Sendable {}

// Log debug messages
fileprivate func _log(_ text: String, debug: Bool = false) {
  if debug {
    print("[NetOutput] \(text)")
  }
}

fileprivate actor ServiceActor {
  private var service: NetService?
  private var outputStream: OutputStream?
  private var buffer = [Log.Item]()
  
  func append(_ item: Log.Item) {
    buffer.append(item)
  }
  
  func send(_ item: Log.Item) {
    let text = item.description
    guard !text.isEmpty else {
      return
    }
      
    if let outputStream {
      let buffer = "\(text)\n"
      outputStream.write(buffer, maxLength: buffer.lengthOfBytes(using: .utf8))
    }
    else {
      buffer.append(item)
    }
  }
  
  func drain() {
    buffer.forEach {
      send($0)
    }
    buffer.removeAll()
  }
  
  func open(service: NetService, outputStream: OutputStream) {
    guard self.service == nil else {
      return
    }
    
    self.service = service
    self.outputStream = outputStream
    outputStream.open()
    
    _log("Connected")
  }
  
  func close(service: NetService) {
    guard self.service == service else {
      return
    }
    outputStream?.close()
    outputStream = nil
    self.service = nil
    
    _log("Disconnected")
  }
  
  func close() {
    if let service {
      close(service: service)
    }
  }
}

/// A target output that sends log messages to `NetConsole` service.
///
/// `NetConsole` service can be run from a command line on your machine and then the output connects and sends your log messages to it.
///
public final class Net: LogOutput {
  private static let type = "_dlog._tcp"
  private static let domain = "local."
  private static let queue = DispatchQueue(label: "dlog.net.queue")
  
  private let name: String
  private let browser = NetServiceBrowser()
  private let serviceActor = ServiceActor()
  
  /// Creates `Net` output object.
  ///
  /// To connect to a specific instance of the service in your network you should provide an unique name to both `NetConsole` and `Net` output.
  ///
  ///		let logger = DLog(Net(name: "MyNetConsole"))
  ///
  /// - Parameters:
  /// 	- name: A name of `NetConsole` service (defaults to `"DLog"`)
  /// 	- source: A source output (defaults to `.textColored`)
  public init(name: String = "DLog") {
    self.name = name
    super.init()
    
    browser.delegate = self
    browser.searchForServices(ofType: Self.type, inDomain: Self.domain)
  }
  
  deinit {
    Task { [serviceActor] in
      await serviceActor.close()
    }
    browser.stop()
  }
  
  // MARK: - LogOutput
  
  override func log(item: Log.Item) {
    super.log(item: item)
    
    if item.type != .intervalBegin {
      // TODO: Passing closure as a 'sending' parameter risks causing data races between code in the current task and concurrent execution of the closure
//      Task {
//        await serviceActor.send(item)
//      }
    }
  }
}

extension Net: NetServiceBrowserDelegate {
  
  /// Tells the delegate that a search is commencing.
  public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
    _log("Begin search name:'\(name)', type:'\(Self.type)', domain:'\(Self.domain)'")
  }
  
  /// Tells the delegate that a search was stopped.
  public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
    _log("Stop search")
  }
  
  /// Tells the delegate that a search was not successful.
  public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
    _log("Error: \(errorDict)")
  }
  
  /// Tells the delegate the sender found a service.
  public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
    var outputStream: OutputStream?
    guard service.name == name,
          service.getInputStream(nil, outputStream: &outputStream), let outputStream
    else {
      return
    }
    
    CFWriteStreamSetDispatchQueue(outputStream, Self.queue)
    outputStream.delegate = self
    
    Task { [serviceActor] in
      await serviceActor.open(service: service, outputStream: outputStream)
    }
  }
  
  /// Tells the delegate a service has disappeared or has become unavailable.
  public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
    Task { [serviceActor] in
      await serviceActor.close(service: service)
    }
  }
}

extension Net: StreamDelegate {
  
  /// The delegate receives this message when a given event has occurred on a given stream.
  public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    switch eventCode {
      case .openCompleted:
        _log("Output stream is opened")
        
      case .hasSpaceAvailable:
        Task { [serviceActor] in
          await serviceActor.drain()
        }
        
      case .errorOccurred:
        if let error = aStream.streamError {
          _log("Error: \(error.localizedDescription)")
        }
        
      default:
        break
    }
  }
}

#endif
