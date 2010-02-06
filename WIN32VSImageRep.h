#ifndef WIN32VSIMAGEREP_H
#define WIN32VSIMAGEREP_H

@class NSImageRep;
#include <AppKit/NSImageRep.h>

@interface WIN32VSImageRep : NSImageRep
{
  NSString* themeClass;
  int part;
  int state;
}

+ (NSArray*) imageUnfilteredFileTypes;
+ (NSArray*) imageUnfilteredPasteboardTypes;

+ (BOOL) canInitWithData:(NSData*)data;

- (id) initWithData:(NSData*)data;
- (BOOL) draw;
- (void) dealloc;
@end

#endif
