#import "DLog.h"

@implementation LogProtocol (PropertyWrapper)

- (LogBlock)log {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self log:^{ return text; } file:file function:func line:line];
    };
}

- (TraceBlock)trace {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line, NSArray<NSNumber*>* addresses){
        return [self trace:^{ return text; } file:file function:func line:line addresses:addresses];
    };
}

- (LogBlock)debug {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self debug:^{ return text; } file:file function:func line:line];
    };
}

- (LogBlock)info {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self info:^{ return text; } file:file function:func line:line];
    };
}

- (LogBlock)warning {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self warning:^{ return text; } file:file function:func line:line];
    };
}

- (LogBlock)error {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self error:^{ return text; } file:file function:func line:line];
    };
}

- (AssertBlock)assert {
    return ^(BOOL condition, NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self assert:^{ return condition; } :^{ return text; } file:file function:func line:line];
    };
}

- (LogBlock)fault {
    return ^(NSString* text, NSString* file, NSString* func, NSUInteger line){
        return [self fault:^{ return text; } file:file function:func line:line];
    };
}

- (ScopeBlock)scope {
    return ^(NSString* name, NSString* file, NSString* func, NSUInteger line, void (^block)(LogScope*)){
        return [self scope:name file:file function:func line:line closure:block];
    };
}

- (IntervalBlock)interval {
    return ^(NSString* name, NSString* file, NSString* func, NSUInteger line, void (^block)()){
        return [self intervalWithName:name file:file function:func line:line closure:block];
    };
}

@end
