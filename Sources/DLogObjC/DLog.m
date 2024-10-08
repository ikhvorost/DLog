#import "DLog.h"


NSString* fileID(NSBundle* bundle, NSString* file) {
  NSString* bundleName = bundle.infoDictionary[(NSString*)kCFBundleNameKey];
  NSString* fileName = file.lastPathComponent;
  return [NSString stringWithFormat:@"%@/%@", bundleName, fileName];
}

/*
 
 @implementation Log (PropertyWrapper)
 
 
 - (LogBlock)log {
 return ^(NSString* text, NSString* fileID, NSString* file, NSString* func, NSUInteger line){
 return [self log:^{ return [[LogMessage alloc] initWithStringLiteral:text]; } fileID:fileID file:file function:func line:line];
 };
 }
 
 - (LogBlock)trace {
 return ^(NSString* text, NSString* fileID, NSString* file, NSString* func, NSUInteger line){
 return [self trace:^{ return [[LogMessage alloc] initWithStringLiteral:text]; } fileID:fileID file:file function:func line:line];
 };
 }
 
 - (LogBlock)debug {
 return ^(NSString* text, NSString* fileID, NSString* file, NSString* func, NSUInteger line){
 return [self debug:^{ return [[LogMessage alloc] initWithStringLiteral:text]; } fileID:fileID file:file function:func line:line];
 };
 }
 
 - (LogBlock)info {
 return ^(NSString* text, NSString* fileID, NSString* file, NSString* func, NSUInteger line){
 return [self info:^{ return [[LogMessage alloc] initWithStringLiteral:text]; } fileID:fileID file:file function:func line:line];
 };
 }
 
 - (LogBlock)warning {
 return ^(NSString* text, NSString* fileID, NSString* file, NSString* func, NSUInteger line){
 return [self warning:^{ return [[LogMessage alloc] initWithStringLiteral:text]; } fileID:fileID file:file function:func line:line];
 };
 }
 
 - (LogBlock)error {
 return ^(NSString* text, NSString* fileID, NSString* file, NSString* func, NSUInteger line){
 return [self error:^{ return [[LogMessage alloc] initWithStringLiteral:text]; } fileID:fileID file:file function:func line:line];
 };
 }
 
 - (AssertBlock)assertion {
 return ^(BOOL condition, NSString* text, NSString* fileID, NSString* file, NSString* func, NSUInteger line){
 return [self assert:^{ return condition; } : ^{ return [[LogMessage alloc] initWithStringLiteral:text]; } fileID:fileID file:file function:func line:line];
 };
 }
 
 - (LogBlock)fault {
 return ^(NSString* text, NSString* fileID, NSString* file, NSString* func, NSUInteger line){
 return [self fault:^{ return [[LogMessage alloc] initWithStringLiteral:text]; } fileID:fileID file:file function:func line:line];
 };
 }
 
 - (ScopeBlock)scope {
 return ^(NSString* name, void (^block)(LogScope*)){
 return [self scope:name metadata:nil closure:block];
 };
 }
 
 - (IntervalBlock)interval {
 return ^(NSString* name, NSString* fileID, NSString* file, NSString* func, NSUInteger line, void (^block)()){
 return [self intervalWithName:name fileID:fileID file:file function:func line:line closure:block];
 };
 }
 
 @end
 
 */
