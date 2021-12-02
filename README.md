# DLog

[![Language: Swift](https://img.shields.io/badge/language-swift-f48041.svg?style=flat)](https://developer.apple.com/swift)
![Platform: iOS 8+/macOS10.11](https://img.shields.io/badge/platform-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20-blue.svg?style=flat)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)
[![build & test](https://github.com/ikhvorost/DLog/actions/workflows/swift.yml/badge.svg?branch=master)](https://github.com/ikhvorost/DLog/actions/workflows/swift.yml)
[![codecov](https://codecov.io/gh/ikhvorost/DLog/branch/master/graph/badge.svg?token=DJLKDA9W1Q)](https://codecov.io/gh/ikhvorost/DLog)
[![swift doc coverage](https://img.shields.io/badge/swift%20doc-100%25-f39f37)](https://github.com/SwiftDocOrg/swift-doc)

<p align="center"><img src="Images/dlog.png" alt="DLog: Modern logger with pipelines for Swift"></p>

DLog is the development logger that supports emoji and colored text output, oslog, pipelines, filtering, scopes, intervals, stack backtrace and more.

- [Getting started](#getting-started)
- [Log levels](#log-levels)
	- [`log`](#log)
	- [`info`](#info)
	- [`trace`](#trace)
	- [`debug`](#debug)
	- [`warning`](#warning)
	- [`error`](#error)
	- [`assert`](#assert)
	- [`fault`](#fault)
- [Scope](#scope)
- [Interval](#interval)
- [Category](#category)
- [Outputs](#outputs)
	- [Text](#text)
	- [Standard](#standard)
	- [File](#file)
	- [OSLog](#oslog)
	- [Net](#net)
- [Pipeline](#pipeline)
- [Filter](#filter)
- [`.disabled`](#disabled)
- [Configuration](#configuration)
	- [`TraceConfiguration`](#traceconfiguration)
		- [`ThreadConfiguration`](#threadconfiguration)
		- [`StackConfiguration`](#stackconfiguration)
	- [`IntervalConfiguration`](#intervalconfiguration)
- [Objective-C](#objective-c)
- [Installation](#installation)
- [License](#license)

## Getting started

By default `DLog` provides basic text console output:

```swift
// Import DLog package
import DLog

// Create the logger
let log = DLog()

// Log a message
log.log("Hello DLog!")
```

Outputs:

```sh
• 23:59:11.710 [DLOG] [LOG] <DLog:12> Hello DLog!
```

Where:
- `•` - start sign (useful for filtering)
- `23:59:11.710` - timestamp (HH:mm:ss.SSS)
- `[DLOG]` - category tag ('DLOG' by default)
- `[LOG]` - log type tag
- `<DLog:12>` - location (fileName:line), without file extension
- `Hello DLog!` - message

`DLog` outputs text logs to `stdout` by default but you can use the other outputs such as: `stderr`, filter, file, OSLog, Net. For instance:

```swift
let log = DLog(.file("path/dlog.txt"))
log.debug("It's a file log!")
```

`Dlog` supports plain (by default), emoji and colored styles for text messages and you can set a needed one:

```swift
let log = DLog(.textEmoji => .stdout)

log.info("Info message")
log.log("Log message")
log.assert(false, "Assert message")
```

Outputs:

```sh
• 00:03:07.179 [DLOG] ✅ [INFO] <DLog:6> Info message
• 00:03:07.181 [DLOG] 💬 [LOG] <DLog:7> Log message
• 00:03:07.181 [DLOG] 🅰️ [ASSERT] <DLog:8> Assert message
```

`=>` is pipeline operator and it can be used for creating a list of outputs:

```swift
let log = DLog(.textEmoji
    => .stdout
    => .filter { $0.type == .error }
    => .file("path/error.log"))
```

All log messages will be written to `stdout` first and the the error messages only to the file.

## Log levels

### `log`

Log a message:

```swift
log.log("App start")
```

Outputs:

```sh
• 23:40:23.545 [DLOG] [LOG] <DLog:12> App start
```

### `info`

Log an information message and helpful data:

```swift
let uuid = UUID().uuidString
log.info("uuid: \(uuid)")
```

Outputs:

```sh
• 23:44:30.702 [DLOG] [INFO] <DLog:13> uuid: 8A71D2B9-29F1-4330-A4C2-69988E3FE172
```

### `trace`

Log the current function name and a message (if it is provided) to help in debugging problems during the development:

```swift
func startup() {
    log.trace("Start")
    log.trace()
}

startup()
```

Outputs:

```sh
• 23:45:31.198 [DLOG] [TRACE] <DLog:13> Start: { func: startup(), thread: { number: 1, name: main } }
• 23:45:31.216 [DLOG] [TRACE] <DLog:14> func: startup(), thread: { number: 1, name: main }
```

### `debug`

Log a debug message to help debug problems during the development:

```swift
let session = URLSession(configuration: .default)
session.dataTask(with: URL(string: "https://apple.com")!) { data, response, error in
    guard let http = response as? HTTPURLResponse else { return }

    let text = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
    log.debug("\(http.url!.absoluteString): \(http.statusCode) - \(text)")
}
.resume()
```

Outputs:

```sh
• 23:49:16.562 [DLOG] [DEBUG] <DLog:17> https://www.apple.com/: 200 - no error
```

### `warning`

Log a warning message that occurred during the execution of your code.

```swift
log.warning("No Internet connection.")
```

Outputs:

```sh
• 23:49:55.757 [DLOG] [WARNING] <DLog:12> No Internet connection.
```

### `error`

Log an error that occurred during the execution of your code.

```swift
let fromURL = URL(fileURLWithPath: "source.txt")
let toURL = URL(fileURLWithPath: "destination.txt")
do {
    try FileManager.default.moveItem(at: fromURL, to: toURL)
}
catch {
    log.error(error.localizedDescription)
}
```

Outputs:

```sh
• 23:50:39.560 [DLOG] [ERROR] <DLog:18> “source.txt” couldn’t be moved to “Macintosh HD” because either the former doesn’t exist, or the folder containing the latter doesn’t exist.
```

### `assert`

Sanity check and log a message (if it is provided) when a condition is false.

```swift
let user = "John"
let password = ""

log.assert(user.isEmpty == false, "User is empty")
log.assert(password.isEmpty == false)
log.assert(password.isEmpty == false, "Password is empty")
```

Outputs:

```sh
• 23:54:19.420 [DLOG] [ASSERT] <DLog:16>
• 23:54:19.422 [DLOG] [ASSERT] <DLog:17> Password is empty

```

### `fault`

Log a critical bug that occurred during the execution in your code.

```swift
guard let modelURL = Bundle.main.url(forResource: "DataModel", withExtension:"momd") else {
    log.fault("Error loading model from bundle")
    abort()
}
```

Outputs:

```sh
• 23:55:07.445 [DLOG] [FAULT] <DLog:13> Error loading model from bundle
```

## Scope

`scope` provides a mechanism for grouping work that's done in your program, so that can see all log messages related to a defined scope of your code in a tree view:

```swift
log.scope("Loading") { scope in
    if let path = Bundle.main.path(forResource: "data", ofType: "json") {
        scope.info("File: \(path)")
        if let data = try? String(contentsOfFile: path) {
            scope.debug("Loaded \(data.count) bytes")
        }
    }
}
```

> NOTE: To pin your messages to a needed scope you should use the provided parameter of the closure that is scope logger.

Outputs:

```sh
• 23:57:13.410 [DLOG] ┌ [Loading]
• 23:57:13.427 [DLOG] | [INFO] <DLog:14> File: path/data.json
• 23:57:13.443 [DLOG] | [DEBUG] <DLog:16> Loaded 121 bytes
• 23:57:13.443 [DLOG] └ [Loading] (0.33)

```

Where:
 - `[Loading]` - a name of the scope
 - `(0.33)` - a time duration of the scope in secs

You can get duration value of a finished scope programatically:

```swift
var scope = log.scope("scope") { _ in
    ...
}

print(scope.duration)
```

It's possible to `enter` and `leave` a scope asynchronously:

```swift
let scope = log.scope("Request")
scope.enter()

let session = URLSession(configuration: .default)
session.dataTask(with: URL(string: "https://apple.com")!) { data, response, error in
    defer {
        scope.leave()
    }

    guard let data = data, let http = response as? HTTPURLResponse else {
        return
    }

    scope.debug("\(http.url!.absoluteString) - HTTP \(http.statusCode)")
    scope.debug("Loaded: \(data.count) bytes")
}
.resume()
```

Outputs:

```sh
• 00:01:24.158 [DLOG] ┌ [Request]
• 00:01:24.829 [DLOG] | [DEBUG] <DLog:25> https://www.apple.com/ - HTTP 200
• 00:01:24.830 [DLOG] | [DEBUG] <DLog:26> Loaded: 74454 bytes
• 00:01:24.830 [DLOG] └ [Request] (0.671)
```

Scopes can be nested one into one and that implements a global stack of scopes:

```swift
log.scope("Loading") { scope1 in
    if let url = Bundle.main.url(forResource: "data", withExtension: "json") {
        scope1.info("File: \(url)")

        if let data = try? Data(contentsOf: url) {
            scope1.debug("Loaded \(data.count) bytes")

            log.scope("Parsing") { scope2 in
                if let items = try? JSONDecoder().decode([Item].self, from: data) {
                    scope2.debug("Parsed \(items.count) items")
                }
            }
        }
    }
}
```

Outputs:

```sh
• 00:03:13.552 [DLOG] ┌ [Loading]
• 00:03:13.554 [DLOG] | [INFO] <DLog:20> File: file:///path/data.json
• 00:03:13.555 [DLOG] | [DEBUG] <DLog:23> Loaded 121 bytes
• 00:03:13.555 [DLOG] | ┌ [Parsing]
• 00:03:13.557 [DLOG] | | [DEBUG] <DLog:27> Parsed 3 items
• 00:03:13.557 [DLOG] | └ [Parsing] (0.2)
• 00:03:13.609 [DLOG] └ [Loading] (0.56)
```

## Interval

`interval` measures performance of your code by a running time and logs a detailed message with accumulated statistics in seconds:

```swift
for _ in 0..<10 {
    log.interval("Sort") {
        var arr = (1...10000).map {_ in arc4random()}
        arr.sort()
    }
}
```

Outputs:

```sh
• 00:05:09.932 [DLOG] [INTERVAL] <DLog:19> Sort: { duration: 0.270, average: 0.270 }
• 00:05:10.162 [DLOG] [INTERVAL] <DLog:19> Sort: { duration: 0.216, average: 0.243 }
• 00:05:10.380 [DLOG] [INTERVAL] <DLog:19> Sort: { duration: 0.215, average: 0.234 }
• 00:05:10.608 [DLOG] [INTERVAL] <DLog:19> Sort: { duration: 0.225, average: 0.231 }
• 00:05:10.829 [DLOG] [INTERVAL] <DLog:19> Sort: { duration: 0.217, average: 0.229 }
• 00:05:11.057 [DLOG] [INTERVAL] <DLog:19> Sort: { duration: 0.225, average: 0.228 }
• 00:05:11.275 [DLOG] [INTERVAL] <DLog:19> Sort: { duration: 0.214, average: 0.226 }
• 00:05:11.497 [DLOG] [INTERVAL] <DLog:19> Sort: { duration: 0.219, average: 0.225 }
• 00:05:11.712 [DLOG] [INTERVAL] <DLog:19> Sort: { duration: 0.212, average: 0.224 }
• 00:05:11.925 [DLOG] [INTERVAL] <DLog:19> Sort: { duration: 0.209, average: 0.222 }
```

Where:
 - `Sort` - a name of the interval
 - `duration` - the current time duration
 - `average` - an average time duration

You can get all metrics values of the interval programatically:

```swift
let interval = log.interval("signpost") {
    ...
}

print(interval.count)
print(interval.duration)
print(interval.total)
print(interval.min)
print(interval.max)
print(interval.avg)
```

To measure asynchronous tasks you can use `begin` and `end` methods:

```swift
let interval = log.interval("Video")
interval.begin()

let asset = AVURLAsset(url: url)
asset.loadValuesAsynchronously(forKeys: ["duration"]) {
    let status = asset.statusOfValue(forKey: "duration", error: nil)
    if status == .loaded {
        log.info("Duration: \(asset.duration.value)")
    }
    interval.end()
}
```

Outputs:

```sh
• 00:10:17.982 [DLOG] [INFO] <DLog:27> Duration: 5532776
• 00:10:17.983 [DLOG] [INTERVAL] <DLog:20> Video: { duration: 2.376, average: 2.376 }
```

## Category

You can define category name to differentiate unique areas and parts of your app and DLog uses this value to categorize and filter related log messages. For example, you might define separate strings for your app’s user interface, data model, and networking code.

```swift
let log = DLog()
let tableLog = log["TABLE"]
let netLog = log["NET"]

log.debug("Refresh")
netLog.debug("Successfully fetched recordings.")
tableLog.debug("Updating with network response.")
```

Outputs:

```sh
• 00:11:30.660 [DLOG] [DEBUG] <DLog:22> Refresh
• 00:11:30.661 [NET] [DEBUG] <DLog:23> Successfully fetched recordings.
• 00:11:30.661 [TABLE] [DEBUG] <DLog:24> Updating with network response.
```

## Outputs

### Text

`Text` is a source output that generates text representation of log messages. It doesn't deliver text to any target outputs (stdout, file etc.) and usually other outputs use it.

It supports thee styles:
- `.plain` - universal plain text
- `.emoji` - text with type icons for info, debug etc. (useful for XCode console)
- `.colored` - colored text with ANSI escape codes (useful for Terminal and files)

```swift
let outputs = [
    "Plain" : Text(style: .plain),
    "Emoji" : Text(style: .emoji),
    "Colored" : Text(style: .colored),
]

for (name, output) in outputs {
    let log = DLog(output)

    print(name)
    print(log.info("info")!)
    print(log.error("error")!)
    print(log.fault("fatal")!)
    print("")
}
```

Outputs:

```sh
Plain
• 00:12:31.718 [DLOG] [INFO] <DLog:25> info
• 00:12:31.719 [DLOG] [ERROR] <DLog:26> error
• 00:12:31.720 [DLOG] [FAULT] <DLog:27> fatal

Emoji
• 00:12:31.720 [DLOG] ✅ [INFO] <DLog:25> info
• 00:12:31.721 [DLOG] ⚠️ [ERROR] <DLog:26> error
• 00:12:31.734 [DLOG] 🆘 [FAULT] <DLog:27> fatal

Colored
[2m•[0m [2m00:12:31.735[0m [34mDLOG[0m [42m[37m INFO [0m [2m[32m<DLog:25>[0m [32minfo[0m
[2m•[0m [2m00:12:31.735[0m [34mDLOG[0m [43m[30m ERROR [0m [2m[33m<DLog:26>[0m [33merror[0m
[2m•[0m [2m00:12:31.735[0m [34mDLOG[0m [41m[37m[5m FAULT [0m [2m[31m<DLog:27>[0m [31mfatal[0m
```

Colored text in Terminal:

<img src="Images/dlog-text-colored.png" alt="DLog: Colored text log in Terminal"><br>

You can also use shortcuts `.textPlain`, `.textEmoji` and `.textColored` to create the output:

```swift
let log = DLog(.textEmoji)
```

### Standard

`Standard` is a target output that can output text messages to POSIX streams:
- `stdout` - Standard Output
- `stderr` - Standard Error

```swift
// Prints to stdout
let logOut = DLog(Standard())

// Prints to stderr
let logErr = DLog(Standard(stream: Darwin.stderr))
```

You can also use shortcuts `.stdout` and `.stderr` to create the output for the logger:

```swift
let log = DLog(.stderr)
log.info("It's error stream")
```

By default `Standard` uses `Text(style: .plain)` output as a source to write text to the streams but you can set other:

```swift
let output = Standard(source: .textEmoji)
let log = DLog(output)

log.info("Emoji")
```

Outputs:

```sh
• 00:15:25.602 [DLOG] ✅ [INFO] <DLog:18> Emoji
```

### File

`File` is a target output that writes text messages to a file by a provided path:

```swift
let file = File(path: "/users/user/dlog.txt")
let log = DLog(file)

log.info("It's a file")
```

By default `File` output clears content of a opened file but if you want to append data to the existed file you should set `append` parameter to `true`:

```swift
let file = File(path: "/users/user/dlog.txt", append: true)
```

You can also use `.file` shortcut to create the output:

```swift
let log = DLog(.file("dlog.txt"))
```

`File` output uses `Text(style: .plain)` as a source by default but you can change it:

```swift
let file = File(path: "/users/user/dlog.txt", source: .textColored)
let log = DLog(file)

log.scope("File") { scope in
    scope.info("It's a file")
}
```
File "dlog.txt":

<img src="Images/dlog-file-colored.png" alt="DLog: Colored text log in a file."><br>

### OSLog

`OSLog` is a target output that writes messages to the Unified Logging System (https://developer.apple.com/documentation/os/logging) that captures telemetry from your app for debugging and performance analysis and then you can use various tools to retrieve log information such as: `Console` and `Instruments` apps, command line tool `log` etc.

To create `OSLog` you can use subsystem strings that identify major functional areas of your app, and you specify them in reverse DNS notation—for example, `com.your_company.your_subsystem_name`. `OSLog` uses `com.dlog.logger` subsystem by default:

```swift
let output1 = OSLog() // subsystem = "com.dlog.logger"
let output2 = OSLog(subsystem: "com.company.app") // subsystem = "com.company.app"
```

You can also use `.oslog` shortcut to create the output:

```swift
let log1 = DLog(.oslog)
let log2 = DLog(.oslog("com.company.app"))
```

All DLog's methods map to the system logger ones with appropriate log levels e.g.:

```swift
let log = DLog(.oslog)

log.log("log")
log.info("info")
log.trace("trace")
log.debug("debug")
log.warning("warning")
log.error("error")
log.assert(false, "assert")
log.fault("fault")
```

Console.app with log levels:

<img src="Images/dlog-oslog-console.png" alt="DLog: Logs in Console.app"><br>

DLog's scopes map to the system logger activities:

```swift
let log = DLog(.oslog)

log.scope("Loading") { scope1 in
    scope1.info("start")
    log.scope("Parsing") { scope2 in
        scope2.debug("Parsed 1000 items")
    }
    scope1.info("finish")
}
```

Console.app with activities:

<img src="Images/dlog-oslog-console-activity.png" alt="DLog: Activities in Console.app"><br>

DLog's intervals map to the system logger signposts:

```swift
let log = DLog(.oslog)

for _ in 0..<10 {
    log.interval("Sorting") {
        let delay = [0.1, 0.2, 0.3].randomElement()!
        Thread.sleep(forTimeInterval: delay)
        log.debug("Sorted")
    }
}
```

Instruments.app with signposts:

<img src="Images/dlog-oslog-instruments-signpost.png" alt="DLog: Signposts in Instruments.app"><br>


### Net

`Net` is a target output that sends log messages to `NetConsole` service that can be run from a command line on your machine. The service is provided as executable inside DLog package and to start it you should run `sh NetConsole.command` (or just click on `NetConsole.command` file) inside the package's folder and then the service starts listening for incoming messages:

```sh
$ sh NetConsole.command # or 'xcrun --sdk macosx swift run'
> [39/39] Linking NetConsole
> NetConsole for DLog v.1.0
```

Then the output connects and sends your log messages to `NetConsole`:

```swift
let log = DLog(Net())

log.scope("Main") { scope1 in
    scope1.trace("Start")
    log.scope("Subtask") { scope2 in
        scope2.info("Validation")
        scope2.error("Token is invalid")
        scope2.debug("Retry")
    }
    scope1.info("Close connection")
}
```

> **iOS 14**: Don't forget to make next changes in your Info.plist to support Bonjour:
> ```xml
> <key>NSLocalNetworkUsageDescription</key>
> <string>Looking for local tcp Bonjour  service</string>
> <key>NSBonjourServices</key>
> <array>
>     <string>_dlog._tcp</string>
> </array>
> ```

Terminal:
<p><img src="Images/dlog-net-console.png" alt="DLog: Colored text log in NetConsole"></p>


By default `Net` uses `Text(style: .colored)` output as a source but you can set other:

```swift
let log = DLog(Net(source: .textEmoji))
```

And you can also use `.net` shortcut to create the output for the logger.

```swift
let log = DLog(.net)
```

To connect to a specific instance of the service in your network you should provide an unique name to both `NetConsole` and `Net` output ("DLog" name is used by default).

To run the `NetConsole` with a specific name run next command:

```sh
sh NetConsole.command -n "MyLogger" # or 'xcrun --sdk macosx swift run NetConsole -n "MyLogger"'
```

In swift code you should set the same name:

```swift
let log = DLog(.net("MyLogger"))
```

More params of `NetConsole` you can look at help:

```sh
sh NetConsole.command --help  # or 'xcrun --sdk macosx swift run NetConsole --help'
OVERVIEW: NetConsole for DLog v.1.0

USAGE: net-console [--name <name>] [--auto-clear] [--debug]

OPTIONS:
  -n, --name <name>       The name by which the service is identified to the network. The name must be unique and by default it equals
                          "DLog". If you pass the empty string (""), the system automatically advertises your service using the computer
                          name as the service name.
  -a, --auto-clear        Clear a terminal on new connection.
  -d, --debug             Enable debug messages.
  -h, --help              Show help information.
```

## Pipeline

As described above `File`, `Net` and `Standard` outputs have `source` parameter in their initializers to set a source output that is very useful if we want to change an output by default:

```swift
let std = Standard(stream: .out, source: .textEmoji)
let log = DLog(std)
```

Actually any output has `source` property:

```swift
let std = Standard()
std.source = .textEmoji
let log = DLog(std)
```

So that it's possible to make a linked list of outputs:

```swift
// Text
let text: LogOutput = .textEmoji

// Standard
let std = Standard()
std.source = text

// File
let file = File(path: "dlog.txt")
file.source = std

let log = DLog(file)
```

Where `text` is a source for `std` and `std` is a source for `file`: text --> std --> file, and now each text message will be sent to both `std` and `file` outputs consecutive.

Lets rewrite this shorter:

```swift
let log = DLog(.textEmoji => .stdout => .file("dlog.txt"))
```

Where `=>` is pipeline operator which defines a combined output from two outputs where the first one is a source and second is a target. So from example above emoji text messages will be written twice: first to standard output and then to the file.

You can combine any needed outputs together and create a final chained output from multiple outputs and your messages will be forwarded to all of them one by one:

```swift
// All log messages will be written:
// 1) as plain text to stdout
// 2) as colored text (with escape codes) to the file

let log = DLog(.textPlain => .stdout => .textColored => .file(path))
```

## Filter

`Filter` or `.filter` represents a pipe output that can filter log messages by next available fields: `time`, `category`, `type`, `fileName`, `funcName`, `line`, `text` and `scope`. You can inject it to your pipeline where you need to log specific data only.

Examples:

1) Log messages to stardard output with 'NET' category only

```swift
let log = DLog(.textPlain => .filter { $0.category == "NET" } => .stdout)
let netLog = log["NET"]

log.info("info")
netLog.info("info")
```

Outputs:

```sh
• 00:17:58.076 [NET] [INFO] <DLog:19> info
```

2) Log debug messages only

```swift
let log = DLog(.textPlain => .filter { $0.type == .debug } => .stdout)

log.trace()
log.info("info")
log.debug("debug")
log.error("error")
```

Outputs:

```sh
• 00:18:23.638 [DLOG] [DEBUG] <DLog:19> debug
```

3) Log messages that contain "hello" string only

```swift
let log = DLog(.textPlain => .filter { $0.text().contains("hello") } => .stdout)

log.debug("debug")
log.log("hello world")
log.info("info")
```

Outputs:

```sh
• 00:19:17.821 [DLOG] [LOG] <DLog:18> hello world
```

3) Log messages which are related to a specific scope:

```swift
let filter = Filter { item in
    let name = "Load"
    if let scope = item as? LogScope {
        return scope.text() == name
    }
    return item.scope?.text() == name
}

let log = DLog(.textPlain => filter => .stdout)

log.trace("trace")
log.scope("Load") { scope1 in
    scope1.debug("debug")

    log.scope("Parse") { scope2 in
        scope2.log("log")
        scope2.info("info")
    }

    scope1.error("error")
}
log.fault("fault")
```

Outputs:

```sh
• 00:19:59.573 [DLOG] ┌ [Load]
• 00:19:59.573 [DLOG] | [DEBUG] <DLog:27> debug
• 00:19:59.586 [DLOG] | [ERROR] <DLog:34> error
• 00:19:59.586 [DLOG] └ [Load] (0.13)
```

## `.disabled`

It is the shared disabled logger constant that doesn't emit any log message and it's very useful when you want to turn off the logger for some build configuration, preference, condition etc.

```swift
// Logging is enabled for `Debug` build configuration only

#if DEBUG
    let log = DLog(.textPlain => .file(path))
#else
    let log = DLog.disabled
#endif
```

The same can be done for disabling unnecessary log categories without commenting or deleting the logger's functions:

```swift
//let netLog = log["NET"]
let netLog = DLog.disabled // Disable "NET" category
```

The disabled logger continue running your code inside scopes and intervals:

```swift
let log = DLog.disabled

log.log("start")
log.scope("scope") { scope in
    scope.debug("debug")

    print("scope code")
}
log.interval("signpost") {
    log.info("info")

    print("signpost code")
}
log.log("finish")
```

Outputs:

```sh
scope code
signpost code
```

## Configuration

You can customize the logger's output by setting which info from the logger should be used. `LogConfiguration` is a root struct to configure the logger which contains common settings for log messages.

For instance you can change the default view of log messages which includes a start sign, category, log type and location:

```swift
let log = DLog()
log.info("Info message")
```

Outputs:

```sh
• 23:53:16.116 [DLOG] [INFO] <DLog:12> Info message
```

To new appearance that includes your start sign and timestamp only:

```swift
var config = DLog.defaultConfiguration // Or: var config = LogConfiguration()
config.sign = ">"
config.options = [.sign, .time]

let log = DLog(configuration: config)

log.info("Info message")
```

Outputs:

```sh
> 00:01:24.380 Info message
```

### `TraceConfiguration`

It contains configuration values regarding to the `trace` method which includes trace view options, thread and stack configurations.

By default `trace` method uses `.compact` view option to produce information about the current function name and thread info:

```swift
let log = DLog()

func doTest() {
    log.trace()
}

doTest()
```

Outputs:

```sh
• 12:20:47.137 [DLOG] [TRACE] <DLog:13> func: doTest(), thread: { number: 1, name: main }
```

But you can change it to show a function and queue names:

```swift
var config = DLog.defaultConfiguration
config.traceConfiguration.options = [.function, .queue]

let log = DLog(configuration: config)

func doTest() {
    log.trace()
}

doTest()
```

Outputs:

```sh
• 12:37:24.101 [DLOG] [TRACE] <DLog:11> func: doTest(), queue: com.apple.main-thread
```

#### `ThreadConfiguration`

The trace configuration has `threadConfiguration` property to change view options of thread info. For instance the logger can print the current QoS of threads.

```swift
var config = DLog.defaultConfiguration
config.traceConfiguration.threadConfiguration.options = [.number, .qos]

let log = DLog(configuration: config)

func doTest() {
    log.trace()
}

doTest()

DispatchQueue.global().async {
    doTest()
}
```

Outputs:

```sh
• 13:01:32.859 [DLOG] [TRACE] <DLog:9> func: doTest(), thread: { number: 1, qos: userInteractive }
• 13:01:32.910 [DLOG] [TRACE] <DLog:9> func: doTest(), thread: { number: 3, qos: userInitiated }
```

#### `StackConfiguration`

The `trace` method can output the call stack backtrace of the current thread at the moment this method was called. To enable this feature you should configure stack view options, style and depth with `stackConfiguration` property:

```swift
var configuration: LogConfiguration = {
    var config = DLog.defaultConfiguration
    config.traceConfiguration.options = [.stack]
    config.traceConfiguration.stackConfiguration.options = [.symbols]
    config.traceConfiguration.stackConfiguration.style = .column
    config.traceConfiguration.stackConfiguration.depth = 3
    return config
}()

let log = DLog(configuration: configuration)

func third() {
    log.trace()
}

func second() {
    third()
}

func first() {
    second()
}

first()
```

Outputs:

```sh
• 23:06:24.092 [DLOG] [TRACE] <AppDelegate:45> stack: [
0: { symbols: Test.third() -> () }
1: { symbols: Test.second() -> () }
2: { symbols: Test.first() -> () } ]
```

> NOTE: A full call stack backtrace is available in Debug mode only.

### `IntervalConfiguration`

You can change the view options of interval statistics with `intervalConfiguration` property of `LogConfiguration` to show needed information such as: `.count`, `.min`, `.max` etc. Or you can use `.all` to output all parameters.

```swift
var config = LogConfiguration()
config.intervalConfiguration.options = [.all]

let log = DLog(configuration: config)

log.interval("signpost") {
    Thread.sleep(forTimeInterval: 3)
}
```

Outputs:

```sh
• 23:26:40.978 [DLOG] [INTERVAL] <DLog:13> signpost: { duration: 3.2, count: 1, total: 3.2, min: 3.2, max: 3.2, average: 3.2 }
```

## Objective-C



## Installation

### XCode project

1. Select `Xcode > File > Swift Packages > Add Package Dependency...`
2. Add package repository: `https://github.com/ikhvorost/DLog.git`
3. Import the package in your source files: `import DLog`

### Swift Package

Add `DLog` package dependency to your `Package.swift` file:

```swift
let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/ikhvorost/DLog.git", from: "1.0.0")
    ],
    targets: [
        .target(name: "YourPackage",
            dependencies: [
                .product(name: "DLog", package: "DLog")
            ]
        ),
        ...
    ...
)
```

## License

DLog is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
