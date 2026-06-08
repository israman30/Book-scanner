#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "book-scanner-icon" asset catalog image resource.
static NSString * const ACImageNameBookScannerIcon AC_SWIFT_PRIVATE = @"book-scanner-icon";

#undef AC_SWIFT_PRIVATE
