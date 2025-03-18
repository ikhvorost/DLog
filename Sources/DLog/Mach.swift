//
//  Mach.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2023/12/18.
//  Copyright © 2023 Iurii Khvorost. All rights reserved.
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

#if swift(>=6.0)
@preconcurrency import Darwin.Mach
#endif

struct TaskInfo {
  
  private static func taskInfo<T>(_ info: T, _ flavor: Int32) -> T {
    var info = info
    var count = mach_msg_type_number_t(MemoryLayout<T>.size / MemoryLayout<natural_t>.size)
    _ = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(flavor), $0, &count)
      }
    }
    return info
  }
  
  static var power: task_power_info { taskInfo(task_power_info(), TASK_POWER_INFO) }
  static var vm: task_vm_info { taskInfo(task_vm_info(), TASK_VM_INFO) }
}


struct ThreadInfo {
  
  private static func threadInfo<T>(_ thread: thread_act_t, _ info: T, _ flavor: Int32) -> T {
    var info = info
    var count = mach_msg_type_number_t(MemoryLayout<T>.size / MemoryLayout<natural_t>.size)
    _ = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        thread_info(thread, thread_flavor_t(flavor), $0, &count)
      }
    }
    return info
  }
  
  static func basic(thread: thread_act_t) -> thread_basic_info {
    threadInfo(thread, thread_basic_info(), THREAD_BASIC_INFO)
  }
}

func threadsInfo() -> (cpuUsage: Int32, threadsCount: UInt32) {
  var thread_list: thread_act_array_t?
  var thread_count: mach_msg_type_number_t = 0
  task_threads(mach_task_self_, &thread_list, &thread_count)
  
  defer {
    if thread_count > 0 {
      let size = MemoryLayout<thread_t>.size * Int(thread_count)
      vm_deallocate(mach_task_self_, vm_address_t(thread_list!.pointee), vm_size_t(size))
    }
  }
  
  var cpu_usage: Int32 = 0
  for i in 0..<Int(thread_count) {
    let basic = ThreadInfo.basic(thread: thread_list![i])
    if basic.flags & TH_FLAGS_IDLE == 0 {
      cpu_usage += basic.cpu_usage
    }
  }
  return (cpu_usage * 100 / TH_USAGE_SCALE, thread_count)
}
