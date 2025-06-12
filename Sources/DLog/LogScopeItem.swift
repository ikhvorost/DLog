//
//  LogScopeItem.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2025/05/14.
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
import os.log


public final class LogScopeItem: LogItem, @unchecked Sendable {
  let activity: Atomic<os_activity_scope_state_s>
  
  public let level: Int
  public let duration: TimeInterval
  
  init(category: String, stack: [Bool], type: LogType, location: LogLocation, metadata: Metadata, message: String, config: LogConfig, activity: Atomic<os_activity_scope_state_s>, level: Int, duration: TimeInterval) {
    self.activity = activity
    self.level = level
    self.duration = duration
    
    super.init(category: category, stack: stack, type: type, location: location, metadata: metadata, message: message, config: config)
  }
  
  override func padding() -> String {
    let text = super.padding()
    return text.replacingOccurrences(of: "├", with: duration == 0 ? "┌" : "└")
  }
  
  override func typeText() -> String {
    let text = super.typeText()
    return text.replacingOccurrences(of: "[SCOPE]", with: "[SCOPE:\(message)]")
  }
  
  override func data() -> String? {
    duration > 0
      ? ["duration": stringFromTimeInterval(duration)].json()
      : nil
  }
  
  override func messageText() -> String {
    ""
  }
}
