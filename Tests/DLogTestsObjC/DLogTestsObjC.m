#import <XCTest/XCTest.h>

@import DLogObjC;

#define let __auto_type const
#define var __auto_type

#pragma mark - Extentions

@implementation NSString (RegularExpression)

- (BOOL)match:(NSString*)pattern {
  return [self rangeOfString:pattern options:NSRegularExpressionSearch].location != NSNotFound;
}

@end

@implementation NSThread (Delay)

+ (void)sleep:(NSTimeInterval)ti {
  [self sleepForTimeInterval: ti];
}

+ (void)sleep {
  [self sleep: 0.25];
}

@end

#pragma mark - Utils

//#define Sign @"•"
//#define Time @"\\d{2}:\\d{2}:\\d{2}\\.\\d{3}"
#define CategoryTag @"\\[DLOG\\]"
#define Padding @"[\\|\\├\\s]+"
#define LevelTag @"\\[\\S+\\] "
#define Location @"<DLogTestsObjC.m:\\d+> "

static NSString* matchString(NSString* category, NSString* text) {
  return [NSString stringWithFormat:@"%@" Padding LevelTag Location @"%@", (category ?: CategoryTag), text];
}

typedef void (^VoidBlock)(void);

static NSString* readStream(int file, FILE* stream, VoidBlock block) {
  __block NSMutableString* result = nil;
  
  let pipe = [NSPipe new];
  
  let original = dup(file);
  setvbuf(stream, nil, _IONBF, 0);
  dup2(pipe.fileHandleForWriting.fileDescriptor, file);
  
  pipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle* handle) {
    let text = [[NSString alloc] initWithData:handle.availableData encoding: NSUTF8StringEncoding];
    
    if (result == nil) {
      result = [NSMutableString new];
    }
    if (text.length) {
      [result appendString:text];
    }
  };
  
  block();
  
  [NSThread sleep];
  
  // Revert
  fflush(stream);
  dup2(original, file);
  close(original);
  
  // Print
  if (result != nil) {
    printf("%s", result.UTF8String);
  }
  
  return result;
}

static NSString* read_stdout(VoidBlock block) {
  return readStream(STDOUT_FILENO, stdout, block);
}

static NSString* read_stderr(VoidBlock block) {
  return readStream(STDERR_FILENO, stderr, block);
}

#pragma mark - Tests

static void testAll(LogProtocol* logger, NSString *category) {
  XCTAssertNotNil(logger);
  
  XCTAssertTrue([logger.log(@"log") match:matchString(category, @"log$")]);
  XCTAssertTrue([logger.log(@"log %d", 123) match:matchString(category, @"log 123$")]);
  XCTAssertTrue([logger.log(@"%@ %@", @"hello", @"world") match:matchString(category, @"hello world$")]);
  
  XCTAssertTrue([logger.trace() match:matchString(category, @"\\{func:testAll,thread:\\{name:main,number:1\\}\\}$")]);
  XCTAssertTrue([logger.trace(@"trace") match:matchString(category, @"\\{func:testAll,thread:\\{name:main,number:1\\}\\} trace$")]);
  XCTAssertTrue([logger.trace(@"trace%d", 1) match:matchString(category, @"\\{func:testAll,thread:\\{name:main,number:1\\}\\} trace1$")]);
  
  XCTAssertTrue([logger.debug(@"debug") match:matchString(category, @"debug$")]);
  XCTAssertTrue([logger.info(@"info") match:matchString(category, @"info$")]);
  XCTAssertTrue([logger.warning(@"warning") match:matchString(category, @"warning$")]);
  XCTAssertTrue([logger.error(@"error") match:matchString(category, @"error$")]);
  
  XCTAssertNil(logger.assertion(YES));
  XCTAssertNil(logger.assertion(YES, @"assert$"));
  XCTAssertNil(logger.assertion(YES, @"assert %d", 1));
  XCTAssertNotNil(logger.assertion(NO));
  XCTAssertTrue([logger.assertion(NO, @"assert") match:matchString(category, @"assert$")]);
  XCTAssertTrue([logger.assertion(NO, @"assert%d", 1) match:matchString(category, @"assert1$")]);
  
  XCTAssertTrue([logger.fault(@"fault") match:matchString(category, @"fault$")]);
  XCTAssertTrue([logger.fault(@"fault%d", 1) match:matchString(category, @"fault1$")]);
}

@interface DLogTestsObjC : XCTestCase
@end

@implementation DLogTestsObjC

- (void)test_Log {
  let logger = [DLog new];
  testAll(logger, nil);
}

- (void)test_trace_func_params:(LogProtocol *)logger text:(NSString *)text value:(NSInteger)value {
  XCTAssertNotNil(logger);
  XCTAssertTrue([logger.trace() match:matchString(nil, @"\\{func:test_trace_func_params,thread:\\{name:main,number:1\\}\\}$")]);
}

- (void)test_trace_func {
  let logger = [DLog new];
  XCTAssertTrue([logger.trace() match:matchString(nil, @"\\{func:test_trace_func,thread:\\{name:main,number:1\\}\\}$")]);
  [self test_trace_func_params:logger text:@"Hello" value:100];
}

- (void)test_LogWithOutputs {
  let logger = [[DLog alloc] initWithOutputs:@[]];
  XCTAssert([read_stdout(^{ logger.trace(); }) match: @"test_LogWithOutputs"]);
}

- (void)test_Category {
  let logger = [DLog new];
  
  let net = logger[@"NET"];
  XCTAssertNotNil(net);
  
  testAll(net, @"\\[NET\\]");
}

- (void)test_Emoji {
  let logger = [[DLog alloc] initWithOutputs:@[LogOutput.textEmoji, LogOutput.stdOut]];
  
  XCTAssertTrue([logger.log(@"log") match:@"💬"]);
  XCTAssertTrue([logger.trace() match:@"#️⃣"]);
  XCTAssertTrue([logger.debug(@"debug") match:@"▶️"]);
  XCTAssertTrue([logger.info(@"info") match:@"✅"]);
  XCTAssertTrue([logger.warning(@"warning") match:@"⚠️"]);
  XCTAssertTrue([logger.error(@"error") match:@"⚠️"]);
  XCTAssertTrue([logger.assertion(NO) match:@"🅰️"]);
  XCTAssertTrue([logger.fault(@"fault") match:@"🆘"]);
}

- (void)test_stdOutErr {
  let logOut = [[DLog alloc] initWithOutputs:@[LogOutput.textPlain, LogOutput.stdOut]];
  XCTAssert([read_stdout(^{ logOut.trace(); }) match: @"test_stdOutErr"]);
  
  let logErr = [[DLog alloc] initWithOutputs:@[LogOutput.textPlain, LogOutput.stdErr]];
  XCTAssert([read_stderr(^{ logErr.trace(); }) match: @"test_stdOutErr"]);
}

- (void)test_scope {
  let logger = [DLog new];
  
  var scope = logger.scope(@"Scope 1", ^(LogScope* scope) {
    testAll(scope, nil);
  });
  XCTAssertNotNil(scope);
  
  scope = logger.scope(@"Scope 2");
  XCTAssertNotNil(scope);
  
  let text = read_stdout(^{
    [scope enter];
    testAll(scope, nil);
    [scope leave];
  });
  XCTAssertTrue([text match:@"└ \\[Scope 2\\] \\(0\\.\\d+s\\)"]);
}

- (void)test_Interval {
  let logger = [DLog new];
  
  let interval = logger.interval(@"interval", ^{
    [NSThread sleep];
  });
  
  XCTAssertTrue(interval.duration >= 0.25);
  
  let text = read_stdout(^{
    [interval begin];
    [NSThread sleep];
    [interval end];
  });
  XCTAssertTrue([text match:@"\\{average:[0-9]+\\.[0-9]{3}s,duration:[0-9]+\\.[0-9]{3}s\\} interval$"]);
}

- (void)test_AllOutputs {
  let outputs = @[
    LogOutput.textPlain,
    LogOutput.textEmoji,
    LogOutput.textColored,
    LogOutput.stdOut,
    LogOutput.stdErr,
    LogOutput.oslog,
    [LogOutput oslog:@"com.dlog.objc"],
    [LogOutput filterWithItem:^BOOL(LogItem* logItem) {
      return logItem.type == LogTypeDebug;
    }],
    [LogOutput file:@"dlog.txt" append:NO],
    [LogOutput net],
    [LogOutput net:@"dlog"],
  ];
  
  for (LogOutput* output in outputs) {
    let logger = [[DLog alloc] initWithOutputs:@[output]];
    logger.debug(@"debug");
  }
  
  [NSThread sleep];
}

- (void)test_filter {
  let filterItem = [LogOutput filterWithItem:^BOOL(LogItem* logItem) {
    return
    [logItem.time compare:NSDate.now] == NSOrderedAscending &&
    [logItem.category isEqualToString:@"DLOG"] &&
    [logItem.scope.name isEqualToString:@"Scope"] &&
    logItem.type == LogTypeDebug &&
    [logItem.fileName isEqualToString:@"DLogTestsObjC.m"] &&
    [logItem.funcName isEqualToString:@"-[DLogTestsObjC test_filter]"] &&
    (logItem.line > __LINE__) &&
    [logItem.text isEqualToString:@"debug"];
  }];
  
  let filterScope = [LogOutput filterWithScope:^BOOL(LogScope* scope) {
    return [scope.name isEqualToString:@"Scope"];
  }];
  
  XCTAssertNotNil(filterItem);
  
  let logger = [[DLog alloc] initWithOutputs:@[LogOutput.textPlain, filterItem, filterScope, LogOutput.stdOut]];
  
  let scope = logger.scope(@"Scope");
  XCTAssertNotNil(scope);
  [scope enter];
  
  XCTAssert([scope.debug(@"debug") match:matchString(nil, @"debug")]);
  XCTAssertFalse([scope.log(@"log") match:matchString(nil, @"log")]);
  
  [scope leave];
}

- (void)test_Disabled {
  let logger = DLog.disabled;
  
  let text = read_stdout(^{
    logger.log(@"log");
    logger.trace();
    logger.debug(@"debug");
    logger.info(@"info");
    logger.warning(@"warning");
    logger.error(@"error");
    logger.assertion(NO);
    logger.fault(@"fault");
    logger.scope(@"scope", ^(LogScope* scope) {
      scope.error(@"error");
    });
    logger.interval(@"interval", ^{ [NSThread sleep]; });
  });
  XCTAssertNil(text);
}

- (void)test_metadata {
  let logger = [DLog new];
  
  logger.metadata[@"id"] = @12345;
  XCTAssert([logger.debug(@"debug") match:@"\\(id:12345\\)"]);
  
  logger.metadata[@"id"] = nil;
  logger.metadata[@"name"] = @"Bob";
  XCTAssert([logger.debug(@"debug") match:@"\\(name:Bob\\)"]);
  
  // Category
  let net = logger[@"NET"];
  XCTAssert([net.debug(@"debug") match:@"\\(name:Bob\\)"]);
  [net.metadata clear];
  XCTAssert([net.debug(@"debug") match:@"\\(name:Bob\\)"] == NO);
  
  XCTAssert([logger.debug(@"debug") match:@"\\(name:Bob\\)"]);
  
  // Scope
  var scope = logger.scope(@"Scope", ^(LogScope* scope) {
    XCTAssert([scope.debug(@"debug") match:@"\\(name:Bob\\)"]);
    scope.metadata[@"name"] = nil;
    XCTAssert([scope.debug(@"debug") match:@"\\(name:Bob\\)"] == NO);
    scope.metadata[@"id"] = @12345;
    XCTAssert([scope.debug(@"debug") match:@"\\(id:12345\\)"]);
  });
  
  XCTAssert([logger.debug(@"debug") match:@"\\(name:Bob\\)"]);
}

@end
