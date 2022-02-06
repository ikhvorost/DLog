#import "DLog.h"

@implementation LogProtocol (PropertyWrapper)

- (LogBlock)log {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self log:^{ return [LogMessage message:text]; } file:file function:func line:line];
    };
}

- (TraceBlock)trace {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line, NSArray<NSNumber*>* addresses){
        return [self trace:^{ return [LogMessage message:text]; } file:file function:func line:line addresses:addresses];
    };
}

- (LogBlock)debug {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self debug:^{ return [LogMessage message:text]; } file:file function:func line:line];
    };
}

- (LogBlock)info {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self info:^{ return [LogMessage message:text]; } file:file function:func line:line];
    };
}

- (LogBlock)warning {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self warning:^{ return [LogMessage message:text]; } file:file function:func line:line];
    };
}

- (LogBlock)error {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self error:^{ return [LogMessage message:text]; } file:file function:func line:line];
    };
}

- (AssertBlock)assertion {
    return ^(BOOL condition, NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self assert:^{ return condition; } : ^{ return [LogMessage message:text]; } file:file function:func line:line];
    };
}

- (LogBlock)fault {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self fault:^{ return [LogMessage message:text]; } file:file function:func line:line];
    };
}

- (ScopeBlock)scope {
    return ^(NSString* name, NSString* file, NSString* func, NSUInteger line, void (^block)(LogScope*)){
        return [self scope:^{ return [LogMessage message:name]; } file:file function:func line:line closure:block];
    };
}

- (IntervalBlock)interval {
    return ^(NSString* name, NSString* file, NSString* func, NSUInteger line, void (^block)()){
        return [self intervalWithName:name file:file function:func line:line closure:block];
    };
}

@end
