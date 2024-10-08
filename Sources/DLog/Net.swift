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

private class LogBuffer {
  private static let linesCount = 1000
  
  private var stack = [String]()
  
  var text: String? {
    synchronized(self) {
      stack.reduce(nil) { text, line in
        "\(text ?? "")\(line)\n"
      }
    }
  }
  
  func append(text: String) {
    synchronized(self) {
      stack.append(text)
      if stack.count > Self.linesCount {
        _ = stack.removeFirst()
      }
    }
  }
  
  func clear() {
    synchronized(self) {
      stack.removeAll()
    }
  }
}

/// A target output that sends log messages to `NetConsole` service.
///
/// `NetConsole` service can be run from a command line on your machine and then the output connects and sends your log messages to it.
///
public class Net: LogOutput {
  private static let type = "_dlog._tcp"
  private static let domain = "local."
  
  private let name: String
  private let browser = NetServiceBrowser()
  private var service: NetService?
  private let queue = DispatchQueue(label: "dlog.net.queue")
  private var outputStream : OutputStream?
  private let buffer = LogBuffer()
  
  var debug = false
  
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
    outputStream?.close()
    browser.stop()
  }
  
  private func send(_ text: @escaping @autoclosure () -> String, newline: Bool = true) {
    queue.async {
      let text = text()
      guard !text.isEmpty else {
        return
      }
      
      if let stream = self.outputStream {
        let data = text + (newline ? "\n" : "")
        stream.write(data, maxLength: data.lengthOfBytes(using: .utf8))
      }
      else {
        self.buffer.append(text: text)
      }
    }
  }
  
  // Log debug messages
  private func log(_ text: String) {
    guard debug else { return }
    print("[NetOutput] \(text)")
  }
  
  // MARK: - LogOutput
  
  override func log(item: LogItem) {
    super.log(item: item)
    send(item.text())
  }
  
  override func enter(item: LogScope.Item) {
    super.enter(item: item)
    send("\(item)")
  }
  
  override func leave(item: LogScope.Item) {
    super.leave(item: item)
    send("\(item)")
  }
  
  override func begin(interval: LogInterval.Item) {
    super.begin(interval: interval)
  }
  
  override func end(interval: LogInterval.Item) {
    super.end(interval: interval)
    send("\(interval)")
  }
}

extension Net : NetServiceBrowserDelegate {
  
  /// Tells the delegate that a search is commencing.
  public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
    log("Begin search name:'\(name)', type:'\(Self.type)', domain:'\(Self.domain)'")
  }
  
  /// Tells the delegate that a search was stopped.
  public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
    log("Stop search")
  }
  
  /// Tells the delegate that a search was not successful.
  public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
    log("Error: \(errorDict)")
  }
  
  /// Tells the delegate the sender found a service.
  public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
    guard service.name == self.name,
          self.service == nil,
          service.getInputStream(nil, outputStream: &outputStream)
    else { return }
    
    log("Connected")
    
    self.service = service
    
    CFWriteStreamSetDispatchQueue(outputStream, queue)
    outputStream?.delegate = self
    outputStream?.open()
  }
  
  /// Tells the delegate a service has disappeared or has become unavailable.
  public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
    guard self.service == service else { return }
    
    outputStream?.close()
    outputStream = nil
    self.service = nil
    
    log("Disconnected")
  }
}

extension Net : StreamDelegate {
  
  /// The delegate receives this message when a given event has occurred on a given stream.
  public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    switch eventCode {
      case .openCompleted:
        log("Output stream is opened")
        
      case .hasSpaceAvailable:
        if let text = buffer.text {
          send(text, newline: false)
          buffer.clear()
        }
        
      case .errorOccurred:
        if let error = aStream.streamError {
          log("Error: \(error.localizedDescription)")
        }
        
      default:
        break
    }
  }
}

#endif
