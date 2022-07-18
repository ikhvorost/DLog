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
#define Padding @"[\\|\\s]+"
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
	XCTAssertNotNil(logger);
    
    testAll(logger, nil);
}

- (void)test_LogWithOutputs {
    let logger = [[DLog alloc] initWithOutputs:@[]];
    XCTAssertNotNil(logger);
    
    XCTAssert([read_stdout(^{ logger.trace(); }) match: @"test_LogWithOutputs"]);
}

- (void)test_Category {
    let logger = [DLog new];
    XCTAssertNotNil(logger);
    
    let net = logger[@"NET"];
    XCTAssertNotNil(net);
    
    testAll(net, @"\\[NET\\]");
}

- (void)test_Emoji {
    let logger = [[DLog alloc] initWithOutputs:@[LogOutput.textEmoji, LogOutput.stdOut]];
    XCTAssertNotNil(logger);
    
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

- (void)test_Scope {
	let logger = [DLog new];
	XCTAssertNotNil(logger);
	
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
	XCTAssertNotNil(logger);
	
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
        [LogOutput filter:^BOOL(LogItem* logItem) {
            return logItem.type == LogTypeDebug;
        }],
        [LogOutput file:@"dlog.txt" append:NO],
        [LogOutput net],
        [LogOutput net:@"dlog"],
    ];
    
    for (LogOutput* output in outputs) {
        let logger = [[DLog alloc] initWithOutputs:@[output]];
        XCTAssertNotNil(logger);
        
        logger.debug(@"debug");
    }
    
    [NSThread sleep];
}

- (void)test_Filter {
    let filter = [LogOutput filter:^BOOL(LogItem* logItem) {
        if ([logItem isKindOfClass:LogScope.class]) {
            return [logItem.text isEqualToString:@"Scope"];
        }
        
        return
            [logItem.time compare:NSDate.now] == NSOrderedAscending &&
            [logItem.category isEqualToString:@"DLOG"] &&
            [logItem.scope.text isEqualToString:@"Scope"] &&
            logItem.type == LogTypeDebug &&
            [logItem.fileName isEqualToString:@"DLogTestsObjC.m"] &&
            [logItem.funcName isEqualToString:@"-[DLogTestsObjC test_Filter]"] &&
            (logItem.line > __LINE__) &&
            [logItem.text isEqualToString:@"debug"];
    }];
    XCTAssertNotNil(filter);
    
    let logger = [[DLog alloc] initWithOutputs:@[LogOutput.textPlain, filter, LogOutput.stdOut]];
    XCTAssertNotNil(logger);
    
    let scope = logger.scope(@"Scope");
    XCTAssertNotNil(scope);
    [scope enter];
    
    XCTAssert([scope.debug(@"debug") match:matchString(nil, @"debug")]);
    XCTAssertFalse([scope.log(@"log") match:matchString(nil, @"log")]);
    
    [scope leave];
}

- (void)test_Disabled {
    let logger = DLog.disabled;
    XCTAssertNotNil(logger);
 
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

@end
