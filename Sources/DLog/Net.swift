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

#if swift(>=6.0)
extension NetService: @retroactive @unchecked Sendable {}
extension OutputStream: @retroactive @unchecked Sendable {}
extension NetServiceBrowser: @retroactive @unchecked Sendable {}
#else
extension NetService: @unchecked Sendable {}
extension OutputStream: @unchecked Sendable {}
#endif

// Log debug messages
fileprivate func _log(_ text: String, debug: Bool = false) {
  if debug {
    print("[NetOutput] \(text)")
  }
}

/// A target output that sends log messages to `NetConsole` service.
///
/// `NetConsole` service can be run from a command line on your machine and then the output connects and sends your log messages to it.
///
public final class Net: LogOutput, @unchecked Sendable {
  private static let type = "_dlog._tcp"
  private static let domain = "local."
  private static let queue = DispatchQueue(label: "dlog.net.queue")
  
  private let name: String
  private let browser = NetServiceBrowser()
  
  private let service = Atomic<NetService?>(nil)
  private let outputStream = Atomic<OutputStream?>(nil)
  private let hasSpaceAvailable = Atomic(false)
  private let buffer = AtomicArray([Log.Item]())
  
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
    outputStream.value?.close()
    browser.stop()
  }
  
  private static func send(item: Log.Item, outputStream: OutputStream) {
    queue.async {
      let text = item.description
      guard !text.isEmpty else {
        return
      }
      
      let buffer = "\(text)\n"
      outputStream.write(buffer, maxLength: buffer.lengthOfBytes(using: .utf8))
    }
  }
  
  // MARK: - LogOutput
  
  override func log(item: Log.Item) {
    super.log(item: item)
    
    guard item.type != .intervalBegin else {
      return
    }
    
    if let outputStream = outputStream.value, hasSpaceAvailable.value {
      Self.send(item: item, outputStream: outputStream)
    }
    else {
      buffer.append(item)
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
    
    self.service.value = service
    self.outputStream.value = outputStream
    outputStream.open()
    
    _log("Connected")
  }
  
  /// Tells the delegate a service has disappeared or has become unavailable.
  public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
    outputStream.value?.close()
    outputStream.value = nil
    self.service.value = nil
    
    _log("Disconnected")
  }
}

extension Net: StreamDelegate {
  
  /// The delegate receives this message when a given event has occurred on a given stream.
  public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    switch eventCode {
      case .openCompleted:
        _log("Output stream is opened")
        
      case .hasSpaceAvailable:
        if let outputStream = outputStream.value {
          buffer.sync {
            $0.forEach {
              Self.send(item: $0, outputStream: outputStream)
            }
            $0.removeAll()
          }
        }
        hasSpaceAvailable.value = true
        
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
