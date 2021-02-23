# DLog

[![Language: Swift](https://img.shields.io/badge/language-swift-f48041.svg?style=flat)](https://developer.apple.com/swift)
![Platform: iOS 8+/macOS10.11](https://img.shields.io/badge/platform-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20|%20Linux-blue.svg?style=flat)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)
![CI](https://github.com/ikhvorost/DLog/workflows/CI/badge.svg)
[![codecov](https://codecov.io/gh/ikhvorost/DLog/branch/master/graph/badge.svg?token=DJLKDA9W1Q)](https://codecov.io/gh/ikhvorost/DLog)
[![swift doc coverage](https://img.shields.io/badge/swift%20doc-100%25-f39f37)](https://github.com/SwiftDocOrg/swift-doc)

<p align="center"><img src="Images/dlog.png" alt="Logger for Swift"></p>

DLog supports emoji and colored text output, oslog, pipelines, filtering, scopes, intervals and more.

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
- [Installation](#installation)
- [License](#license)

## Getting started

By default `DLog` provides basic text console output:

``` swift
// Import DLog package
import DLog

// Create the logger
let log = DLog()

// Log a message
log.log("Hello DLog!")
```

Outputs:

```
• 13:09:25.854 [00] [DLOG] [LOG] <DLog:12> Hello DLog!
```

Where:
- `•` - start sign (useful for filtering)
- `13:12:41.437` - timestamp (HH:mm:ss.SSS)
- `[00]` - global scope level (see Scope)
- `[DLOG]` - category tag ('DLOG' by default)
- `[LOG]` - log type tag
- `<DLog:7>` - location (file:line)
- `Hello DLog!` - message

## Log levels

### `log`

Log a message:

``` swift
log.log("App start")
```

Outputs:

```
13:36:59.086 [00] [DLOG] [LOG] <DLog:7> App start
```

### `info`

Log an information message and helpful data:

``` swift
let uuid = UUID().uuidString
log.info("uuid: \(uuid)")
```

Outputs:

```
13:37:54.934 [00] [DLOG] [INFO] <DLog:8> uuid: 104B6491-B2A8-4043-A5C6-93CEB60864FA
```

### `trace`

Log the current function name and a message (if it is provided) to help in debugging problems during the development:

``` swift
func startup() {
	log.trace("Start")
	log.trace()
}

startup()
```

Outputs:

```
13:38:31.903 [00] [DLOG] [TRACE] <DLog:8> startup() Start
13:38:31.905 [00] [DLOG] [TRACE] <DLog:9> startup()
```

### `debug`

Log a debug message to help debug problems during the development:

``` swift
let session = URLSession(configuration: .default)
session.dataTask(with: URL(string: "https://apple.com")!) { data, response, error in
	guard let http = response as? HTTPURLResponse else { return }

	let text = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
	log.debug("\(http.url!.absoluteString): \(http.statusCode) - \(text)")
}
.resume()
```

Outputs:

```
13:39:41.662 [00] [DLOG] [DEBUG] <DLog:12> https://www.apple.com/: 200 - no error
```

### `warning`

Log a warning message that occurred during the execution of your code.

``` swift
log.warning("No Internet connection.")
```

Outputs:

```
13:44:49.992 [00] [DLOG] [WARNING] <DLog:7> No Internet connection.
```

### `error`

Log an error that occurred during the execution of your code.

``` swift
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

```
13:53:20.398 [00] [DLOG] [ERROR] <DLog:13> “source.txt” couldn’t be moved to “com.apple.dt.playground.stub.iOS_Simulator.DLog-AA29FA84-10A1-45D7-BAEC-FC5402BAFB0C” because either the former doesn’t exist, or the folder containing the latter doesn’t exist.
```

### `assert`

Sanity check and log a message (if it is provided) when a condition is false.

``` swift
let user = "John"
let password = ""

log.assert(user.isEmpty == false, "User is empty")
log.assert(password.isEmpty == false)
log.assert(password.isEmpty == false, "Password is empty")
```

Outputs:

```
13:55:15.108 [00] [DLOG] [ASSERT] <DLog:11>
13:55:15.110 [00] [DLOG] [ASSERT] <DLog:12> Password is empty
```

### `fault`

Log a critical bug that occurred during the execution in your code.

``` swift
guard let modelURL = Bundle.main.url(forResource: "DataModel", withExtension:"momd") else {
	log.fault("Error loading model from bundle")
	abort()
}
```

Outputs:

```
13:56:46.895 [00] [DLOG] [FAULT] <DLog:8> Error loading model from bundle
```

## Scope

`scope` provides a mechanism for grouping work that's done in your program, so that can see all log messages related to a defined scope of your code in a tree view:

``` swift
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

```
• 12:36:43.656 [01] [DLOG] ┌ [Loading]
• 12:36:43.657 [01] [DLOG] |	[INFO] <DLog:8> File: .../data.json
• 12:36:43.658 [01] [DLOG] |	[DEBUG] <DLog:10> Loaded 121 bytes
• 12:36:43.658 [01] [DLOG] └ [Loading] (0.028s)
```

Where:
 - `[01]` - a global level of the scope
 - `[Loading]` - a name of the scope
 - `(0.028s)` - a time duration of the scope

You can get duration value of a finished scope programatically:

```
var scope = log.scope("scope") { _ in
	...
}

print(scope.duration)
```

It's possible to `enter` and `leave` a scope asynchronously:

``` swift
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

```
• 12:42:58.844 [01] [DLOG] ┌ [Request]
• 12:43:00.262 [01] [DLOG] |	[DEBUG] <DLog:19> https://www.apple.com/ - HTTP 200
• 12:43:00.263 [01] [DLOG] |	[DEBUG] <DLog:20> Loaded: 72705 bytes
• 12:43:00.263 [01] [DLOG] └ [Request] (1.418s)
```

Scopes can be nested one into one and that implements a global stack of scopes:

``` swift
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

```
• 12:46:44.729 [01] [DLOG] ┌ [Loading]
• 12:46:44.730 [01] [DLOG] |	[INFO] <DLog:13> File: .../data.json
• 12:46:44.731 [01] [DLOG] |	[DEBUG] <DLog:16> Loaded 121 bytes
• 12:46:44.731 [02] [DLOG] |	┌ [Parsing]
• 12:46:44.739 [02] [DLOG] |	|	[DEBUG] <DLog:20> Parsed 3 items
• 12:46:44.739 [02] [DLOG] |	└ [Parsing] (0.008s)
• 12:46:44.756 [01] [DLOG] └ [Loading] (0.027s)
```

As you can see from the sample above the scopes have different scope nesting levels "Loading" - [01] and "Parsing" - [02] and it's useful for filtering.

## Interval

`interval` measures performance of your code by a running time and logs a detailed message with accumulated statistics:

``` swift
for _ in 0..<10 {
	log.interval("Sort") {
		var arr = (1...10000).map {_ in arc4random()}
		arr.sort()
	}
}
```

Outputs:

```
• 12:14:09.740 [00] [DLOG] [INTERVAL] <DLog:7> Sort - count: 1, duration: 0.342s, total: 0.342s, min: 0.342s, max: 0.342s, avg: 0.342s
• 12:14:10.039 [00] [DLOG] [INTERVAL] <DLog:7> Sort - count: 2, duration: 0.290s, total: 0.632s, min: 0.290s, max: 0.342s, avg: 0.316s
• 12:14:10.302 [00] [DLOG] [INTERVAL] <DLog:7> Sort - count: 3, duration: 0.261s, total: 0.893s, min: 0.261s, max: 0.342s, avg: 0.298s
• 12:14:10.554 [00] [DLOG] [INTERVAL] <DLog:7> Sort - count: 4, duration: 0.250s, total: 1.144s, min: 0.250s, max: 0.342s, avg: 0.286s
• 12:14:10.805 [00] [DLOG] [INTERVAL] <DLog:7> Sort - count: 5, duration: 0.250s, total: 1.393s, min: 0.250s, max: 0.342s, avg: 0.279s
• 12:14:11.061 [00] [DLOG] [INTERVAL] <DLog:7> Sort - count: 6, duration: 0.255s, total: 1.648s, min: 0.250s, max: 0.342s, avg: 0.275s
• 12:14:11.315 [00] [DLOG] [INTERVAL] <DLog:7> Sort - count: 7, duration: 0.252s, total: 1.900s, min: 0.250s, max: 0.342s, avg: 0.271s
• 12:14:11.566 [00] [DLOG] [INTERVAL] <DLog:7> Sort - count: 8, duration: 0.249s, total: 2.149s, min: 0.249s, max: 0.342s, avg: 0.269s
• 12:14:11.816 [00] [DLOG] [INTERVAL] <DLog:7> Sort - count: 9, duration: 0.249s, total: 2.398s, min: 0.249s, max: 0.342s, avg: 0.266s
• 12:14:12.075 [00] [DLOG] [INTERVAL] <DLog:7> Sort - count: 10, duration: 0.257s, total: 2.655s, min: 0.249s, max: 0.342s, avg: 0.265s
```

Where:
 - `Sort` - a name of the interval
 - `count` - a number of calls
 - `duration` - the current time duration
 - `total` - a total time duration
 - `min` - the shortest time duration
 - `max` - the longest time duration
 - `avg` - an average time duration


You can get all metrics values of the interval programatically:

```
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

``` swift
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

```
00:42:25.885 [00] [DLOG] [INFO] <Package.playground:16> Duration: 155000
00:42:25.888 [00] [DLOG] [INTERVAL] <Package.playground:9> Video - count: 1, duration: 0.390s, total: 0.390s, min: 0.390s, max: 0.390s, avg: 0.390s
```

## Category

You can define category name to differentiate unique areas and parts of your app and DLog uses this value to categorize and filter related log messages. For example, you might define separate strings for your app’s user interface, data model, and networking code.

``` swift
let log = DLog()
let tableLog = log["TABLE"]
let netLog = log["NET"]

log.debug("Refresh")
netLog.debug("Successfully fetched recordings.")
tableLog.debug("Updating with network response.")
```

Outputs:

```
16:21:10.777 [00] [DLOG] [DEBUG] <DLog:9> Refresh
16:21:10.779 [00] [NET] [DEBUG] <DLog:10> Successfully fetched recordings.
16:21:10.779 [00] [TABLE] [DEBUG] <DLog:11> Updating with network response.
```

## Outputs

### Text

`Text` is a source output that generates text representation of log messages. It doesn't deliver text to any target outputs (stdout, file etc.) and usually other outputs use it.

It supports thee styles:
- `.plain` - universal plain text
- `.emoji` - text with type icons for info, debug etc. (useful for XCode console)
- `.colored` - colored text with ANSI escape codes (useful for Terminal and files)

``` swift
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

```
Plain
16:25:38.303 [00] [DLOG] [INFO] <DLog:16> info
16:25:38.305 [00] [DLOG] [LOG] <DLog:17> log
16:25:38.311 [00] [DLOG] [FAULT] <DLog:18> fatal

Emoji
16:25:38.312 [00] [DLOG] ✅ [INFO] <DLog:16> info
16:25:38.312 [00] [DLOG] 💬 [LOG] <DLog:17> log
16:25:38.312 [00] [DLOG] 🆘 [FAULT] <DLog:18> fatal

Colored
[2m16:25:38.312[0m [2m[00][0m [34mDLOG[0m [42m[37m INFO [0m [2m[32m<DLog:16>[0m [32minfo[0m
[2m16:25:38.318[0m [2m[00][0m [34mDLOG[0m [47m[30m LOG [0m [2m[37m<DLog:17>[0m [37mlog[0m
[2m16:25:38.318[0m [2m[00][0m [34mDLOG[0m [41m[37m[5m FAULT [0m [2m[31m<DLog:18>[0m [31mfatal[0m
```

Colored text in Terminal:

<img src="Images/dlog-text-colored.png" alt="DLog: Colored log in Terminal"><br>

You can also use shortcuts `.textPlain`, `.textEmoji` and `.textColored` to create the output:

``` swift
let logEmoji = DLog(.textEmoji)
```

### Standard

`Standard` is a target output that can output text messages to POSIX streams:
- `stdout` - Standard Output
- `stderr` - Standard Error

``` swift
// Prints to stdout
let logOut = DLog(Standard())

// Prints to stderr
let logErr = DLog(Standard(stream: Darwin.stderr))
```

You can also use shortcuts `.stdout` and `.stderr` to create the output for the logger:

``` swift
let log = DLog(.stderr)
log.info("It's error stream")
```

By default `Standard` uses `Text(style: .plain)` output as a source to write text to the streams but you can set other:

``` swift
let output = Standard(source: .textEmoji)
let log = DLog(output)

log.info("Emoji")
```

Outputs:

```
17:59:55.516 [00] [DLOG] ✅ [INFO] <DLog:7> Emoji
```

### File

`File` is a target output that writes text messages to a file by a provided path:

``` swift
let file = File(path: "/users/user/dlog.txt")
let log = DLog(file)

log.info("It's a file")
```

By default `File` output clears content of a opened file but if you want to append data to the existed file you should set `append` parameter to `true`:

``` swift
let file = File(path: "/users/user/dlog.txt", append: true)
```

You can also use `.file` shortcut to create the output:

``` swift
let log = DLog(.file("dlog.txt"))
```

`File` output uses `Text(style: .plain)` as a source by default but you can change it:

``` swift
let file = File(path: "/users/user/dlog.txt", source: .textColored)
let log = DLog(file)

log.scope("File") { scope in
	scope.info("It's a file")
}
```
File "dlog.txt":

<img src="Images/dlog-file-colored.png" alt="DLog: Colored text in a file."><br>

### OSLog

`OSLog` is a target output that writes messages to the Unified Logging System (https://developer.apple.com/documentation/os/logging) that captures telemetry from your app for debugging and performance analysis and then you can use various tools to retrieve log information such as: `Console` and `Instruments` apps, command line tool `log` etc.

To create `OSLog` you can use subsystem strings that identify major functional areas of your app, and you specify them in reverse DNS notation—for example, `com.your_company.your_subsystem_name`. `OSLog` uses `com.dlog.logger` subsystem by default:

``` swift
let output1 = OSLog() // subsystem = "com.dlog.logger"
let output2 = OSLog(subsystem: "com.company.app") // subsystem = "com.company.app"
```

You can also use `.oslog` shortcut to create the output:

``` swift
let log1 = DLog(.oslog)
let log2 = DLog(.oslog("com.company.app"))
```

All DLog's methods map to the system logger ones with appropriate log levels e.g.:

``` swift
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

``` swift
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

``` swift
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

```shell
$ sh NetConsole.command # or 'xcrun --sdk macosx swift run'
> [39/39] Linking NetConsole
> NetConsole for DLog v.1.0
```

Then the output connects and sends your log messages to `NetConsole`:

``` swift
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
> 	<string>_dlog._tcp</string>
> </array>
> ```

Terminal:
<p><img src="Images/dlog-net-console.png" alt="DLog: NetConsole"></p>


By default `Net` uses `Text(style: .colored)` output as a source but you can set other:

``` swift
let log = DLog(Net(source: .textEmoji))
```

And you can also use `.net` shortcut to create the output for the logger.

``` swift
let log = DLog(.net)
```

To connect to a specific instance of the service in your network you should provide an unique name to both `NetConsole` and `Net` output ("DLog" name is used by default).

To run the `NetConsole` with a specific name run next command:

``` shell
sh NetConsole.command -n "MyLogger" # or 'xcrun --sdk macosx swift run NetConsole -n "MyLogger"'
```

In swift code you should set the same name:

``` swift
let log = DLog(.net("MyLogger"))
```

More params of `NetConsole` you can look at help:

``` shell
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

``` swift
let std = Standard(stream: .out, source: .textEmoji)
let log = DLog(std)
```

Actually any output has `source` property:

``` swift
let std = Standard()
std.source = .textEmoji
let log = DLog(std)
```

So that it's possible to make a linked list of outputs:

``` swift
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

``` swift
let log = DLog(.textEmoji => .stdout => .file("dlog.txt"))
```

Where `=>` is pipeline operator which defines a combined output from two outputs where the first one is a source and second is a target. So from example above emoji text messages will be written twice: first to standard output and then to the file.

You can combine any needed outputs together and create a final chained output from multiple outputs and your messages will be forwarded to all of them one by one:

``` swift
// All log messages will be written:
// 1) as plain text to stdout
// 2) as colored text (with escape codes) to the file

let log = DLog(.textPlain => .stdout => .textColored => .file(path))
```

## Filter

`Filter` or `.filter` represents a pipe output that can filter log messages by next available fields: `time`, `category`, `type`, `fileName`, `funcName`, `line`, `text` and `scope`. You can inject it to your pipeline where you need to log specific data only.

Examples:

1) Log messages to stardard output with 'NET' category only

``` swift
let log = DLog(.textPlain => .filter { $0.category == "NET" } => .stdout)
let netLog = log["NET"]

log.info("info")
netLog.info("info")
```

Outputs:

```
22:44:56.386 [00] [NET] [INFO] <DLog:8> info
```

2) Log debug messages only

``` swift
let log = DLog(.textPlain => .filter { $0.type == .debug } => .stdout)

log.trace()
log.info("info")
log.debug("debug")
log.error("error")
```

Outputs:

```
22:47:07.865 [00] [DLOG] [DEBUG] <DLog:8> debug
```

3) Log messages that contain "hello" string only

``` swift
let log = DLog(.textPlain => .filter { $0.text.contains("hello") } => .stdout)

log.debug("debug")
log.log("hello world")
log.info("info")
```

Outputs:

```
22:48:30.399 [00] [DLOG] [LOG] <DLog:7> hello world
```

3) Log messages which are related to a specific scope:

``` swift
let filter = Filter { item in
	let name = "Load"
	if let scope = item as? LogScope {
		return scope.text == name
	}
	return item.scope?.text == name
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

```
22:58:16.401 [01] [DLOG] ┌ [Load]
22:58:16.402 [01] [DLOG] |	[DEBUG] <DLog:16> debug
22:58:16.413 [01] [DLOG] |	[ERROR] <DLog:21> error
22:58:16.414 [01] [DLOG] └ [Load] (0.012s)
```

## `.disabled`

It is the shared disabled logger constant that logging any messages and it's very useful when you want to turn off the logger for some build configuration, preference, condition etc.

``` swift
// Logging is enabled for `Debug` build configuration only

#if DEBUG
	let log = DLog(.textPlain => .file(path))
#else
	let log = DLog.disabled
#endif
```

When you disable the logger all your code continue running inside scopes and intervals except of log messages:

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

```
scope code
signpost code
```

## Installation

### XCode project

1. Select `Xcode > File > Swift Packages > Add Package Dependency...`
2. Add package repository: `https://github.com/ikhvorost/DLog.git`
3. Import the package in your source files: `import DLog`

### Swift Package

Add `DLog` package dependency to your `Package.swift` file:

``` swift
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
