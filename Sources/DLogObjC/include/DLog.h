@import DLog;

#define STATIC_CONST(type, code) ^type() { \
	static type object; \
	static dispatch_once_t onceToken; \
	dispatch_once(&onceToken, ^{ \
		object = code; \
	}); \
	return object; \
};

#define __params(format, ...) ((format) != nil ? [NSString stringWithFormat: (format), ##__VA_ARGS__] : @""),\
	@(__FILE__).lastPathComponent, @(__FUNCTION__), __LINE__

#define log(format, ...) log(__params(format, ##__VA_ARGS__))
#define trace(format, ...) trace(__params(format, ##__VA_ARGS__), NSThread.callStackReturnAddresses)
#define debug(format, ...) debug(__params(format, ##__VA_ARGS__))
#define info(format, ...) info(__params(format, ##__VA_ARGS__))
#define warning(format, ...) warning(__params(format, ##__VA_ARGS__))
#define error(format, ...) error(__params(format, ##__VA_ARGS__))
#define assert(condition, format, ...) assert((condition), __params(format, ##__VA_ARGS__))
#define fault(format, ...) fault(__params(format, ##__VA_ARGS__))

