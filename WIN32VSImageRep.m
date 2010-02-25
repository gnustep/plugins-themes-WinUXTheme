#include <AppKit/NSImage.h>
#include <AppKit/NSImageRep.h>
#include <AppKit/NSPasteboard.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>

#include "WinUXTheme.h"
#include "WIN32VSImageRep.h"

#define FOURCC_LENGTH	6
#define FOURCC_CODE   	"W32VSR"

@interface WIN32VSImageRep (Private)

- (void) _updateImageWidthAndHeight;
- (BOOL) _testPartAndStateIndices;

@end

@implementation WIN32VSImageRep

+ (NSArray*) imageUnfilteredFileTypes
{
  NSDebugLog(@"WIN32VSR +imageUnfilteredFileTypes.");
  return [NSArray arrayWithObject:@"w32vsr"];
}

+ (NSArray*) imageUnfilteredPasteboardTypes
{
  NSDebugLog(@"WIN32VSR +imageUnfilteredPasteboardTypes");
  return [NSArray arrayWithObjects:NSStringPboardType,
    NSFileContentsPboardType,
    nil];
}

+ (BOOL) canInitWithData:(NSData*)data
{
  NSDebugLog(@"WIN32VSR +canInitWithData:");
  if ([data length] >= FOURCC_LENGTH)
  {
    char fourcc[FOURCC_LENGTH+1];
    
    [data getBytes:(void*)fourcc length:FOURCC_LENGTH];
    fourcc[FOURCC_LENGTH] = '\0';
    if (strncmp(fourcc, FOURCC_CODE, FOURCC_LENGTH)==0)
      return YES;
  }
  return NO;
}

+ (NSImageRep*) imageRepWithData:(NSData*)data
{
  NSDebugLog(@"WIN32VSR +imageRepWithData");
  return [[self alloc] initWithData:data];
}

- (id) retain
{
  NSDebugLog(@"WIN32VSR -retain");
  return [super retain];
}

- (id) init
{
  NSDebugLog(@"WIN32VSR -init");
  return [super init];
}

- (void) encodeWithCoder:(NSCoder*)coder
{
  NSDebugLog(@"WIN32VSR -encodeWithCoder");
  [super encodeWithCoder:coder];
  if ([coder allowsKeyedCoding])
  {
    [coder encodeObject:themeClass forKey:@"WIN32ThemeClass"];
    [coder encodeInt:part forKey:@"WIN32ThemePart"];
    [coder encodeInt:state forKey:@"WIN32ThemeState"];
  }
  else
  {
    [coder encodeObject:themeClass];
    [coder encodeValueOfObjCType:@encode(int) at:&part];
    [coder encodeValueOfObjCType:@encode(int) at:&state];
  }
}

- (id) initWithCoder:(NSCoder*)coder
{
  NSDebugLog(@"WIN32VSR -initWithCoder");
  self = [super initWithCoder:coder];
  if (self)
  {
    if ([coder allowsKeyedCoding])
    {
      themeClass = RETAIN([coder decodeObjectForKey:@"WIN32ThemeClass"]);
      NSAssert([themeClass isKindOfClass:[NSString class]], @"themeClass is not a string in keyed archiver");
      part = [coder decodeIntForKey:@"WIN32ThemePart"];
      state = [coder decodeIntForKey:@"WIN32ThemeState"];
    }
    else
    {
      themeClass = RETAIN([coder decodeObject]);
      NSAssert([themeClass isKindOfClass:[NSString class]], @"themeClass is not a string");
      [coder decodeValueOfObjCType:@encode(int) at:&part];
      [coder decodeValueOfObjCType:@encode(int) at:&state];
    }
    
    if ([self _testPartAndStateIndices] == NO)
    {
      [self dealloc];
      return nil;
    } 
    [self _updateImageWidthAndHeight];
  }
  return self;
}

- (id) initWithData:(NSData*)data
{
  NSDebugLog(@"WIN32VSR -initWithData:");
  self = [super init];
  if (self==nil)
    return nil;
  
  if ([data length] > FOURCC_LENGTH)
  {
    NSMutableString *chars = [[NSMutableString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSDictionary *info;
    
    if (chars==nil)
      return nil;

    [chars deleteCharactersInRange:NSMakeRange(0, FOURCC_LENGTH)];
    
    info = [chars propertyList];
    if (info==nil)
    {
      RELEASE(chars);
      return nil;
    }
    
    self->themeClass = [(NSString*)[info objectForKey:@"Class"] retain];
    self->part = [[info objectForKey:@"Part"] intValue];
    self->state = [[info objectForKey:@"State"] intValue];

    // Make sure these part and state indices are valid. This is needed for
    // Windows XP, which does not contain the same theme classes, parts and
    // states as Windows Vista. This should cause a fallback where the theme
    // engine will not load this "image" and use whatever already exists.
    if ([self _testPartAndStateIndices] == NO)
    {
      RELEASE(chars);
      DESTROY(self);
      return nil;
    }

    // Change our image width and height based upon what windows tells
    // us.
    [self _updateImageWidthAndHeight];

    RELEASE(chars);
    NSDebugLog(@"Successfully loaded WIN32ImageRep object.");
    return self;
  }
  return nil;
}

- (id) copyWithZone:(NSZone*)zone
{
  NSDebugLog(@"WIN32VSR -copyWithZone");
  WIN32VSImageRep* c = [super copyWithZone:zone];
  TEST_RETAIN(c->themeClass);
  
  [self _updateImageWidthAndHeight];
  return c;
}

- (BOOL) draw
{
  NSDebugLog(@"WIN32VSR -draw: Draw WIN32VSImageRep %@ %d %d", themeClass, part, state); 
  HTHEME hTheme;
  BOOL res;
  WinUXTheme *themeEngine;

  themeEngine = (WinUXTheme*)[GSTheme theme];

  hTheme = [themeEngine themeWithClassName:themeClass];
  res = [themeEngine  drawThemeBackground:hTheme
    inRect:NSMakeRect(0.,0.,[self pixelsWide],[self pixelsHigh])
    part:part
    state:state
    ];
  [themeEngine releaseTheme:hTheme];
  
  return res;
}

- (void) dealloc
{
  NSDebugLog(@"WIN32VSR -dealloc");
  [themeClass release];
  [super dealloc];
}
@end

@implementation WIN32VSImageRep (Private)

- (void) _updateImageWidthAndHeight
{
  if ([[GSTheme theme] class] != [WinUXTheme class])
    return;

  WinUXTheme* theme = (WinUXTheme*)[GSTheme theme];
  HTHEME hTheme;
  //int width, height;
  NSSize size;
  
  hTheme = [theme themeWithClassName:themeClass];
  //size = [theme defaultSizeForTheme:hTheme part:part state:state];
  size = [theme sizeForTheme:hTheme part:part state:state type:WIN32ThemeSizeBestFit];
  //[theme releaseTheme:hTheme];
  //width = [theme intForTheme:hTheme part:part state:state property:TMT_WIDTH];
  //height = [theme intForTheme:hTheme part:part state:state property:TMT_HEIGHT];
 
  [self setPixelsHigh:size.height];
  [self setPixelsWide:size.width];
  [self setSize:size]; // lets assume that pixels == size
  [theme releaseTheme:hTheme];
}

- (BOOL) _testPartAndStateIndices
{
  HTHEME hTheme;
  WinUXTheme *win32Theme = (WinUXTheme*)[GSTheme theme];
  BOOL result = NO;

  hTheme = [win32Theme themeWithClassName:themeClass];
  if (hTheme)
  {
    result = [win32Theme isTheme:hTheme partDefined:part];
    [win32Theme releaseTheme:hTheme];
  }
  return result;
}
@end
