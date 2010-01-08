/* WINUXTheme A native Windows XP theme for GNUstep

   Copyright (C) 2009 Free Software Foundation, Inc.

   Written by: Fred Kiefer <FredKiefer@gmx.de>
               Riccardo Mottola <rmottola@users.sf.net>
   Date: October 2009
   Based on ideas:
   Copyright (C) 2007 Christopher Armstrong 

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#import <AppKit/AppKit.h>

#import "WinUXTheme.h"


@interface WIN32ScrollerButtonCell : NSButtonCell
{
  WinUXTheme* _theme;
  NSScrollerPart _part;
  BOOL _horizontal;
}

- (id) initWithTheme:(WinUXTheme*)theme scrollerPart:(NSScrollerPart)part horizontal:(BOOL)h;
- (void) dealloc;
- (void) highlight:(BOOL)flag withFrame:(NSRect)frame inView:(NSView*)view;
- (void) drawWithFrame:(NSRect)frame inView:(NSView*)view;
- (int) _partForPart:(NSScrollerPart)part;
@end

@implementation WIN32ScrollerButtonCell 
- (id) initWithTheme:(WinUXTheme*)theme scrollerPart:(NSScrollerPart)part horizontal:(BOOL)h
{
  self = [super init];
  if (!self) return nil;

  _theme = RETAIN(theme);
  _part = part;
  _horizontal = h;
  return self;
}

- (void) dealloc
{
  RELEASE(_theme);
  [super dealloc];
}

- (int) _partForPart:(NSScrollerPart)part
{
  switch (part)
  {
    case NSScrollerKnob:
      return SBP_THUMBBTNVERT;
    case NSScrollerKnobSlot:
      return SBP_UPPERTRACKVERT;
    case NSScrollerIncrementLine:
    case NSScrollerDecrementLine:  
      return SBP_ARROWBTN;
    default:
      return 0;
  }
}

- (void) highlight:(BOOL)flag withFrame:(NSRect)frame inView:(NSView*)view
{
  HTHEME hTheme;
  NSWindow *window = [view window];
  HWND hwnd = (HWND)[window windowNumber];

  hTheme = OpenThemeData(hwnd, L"scrollbar");
  
  if (IsThemePartDefined(hTheme, [self _partForPart:_part], 0))
  {
    NSLog(@"Draw scroller part.");
    int part;
    BOOL result;

    switch (_part)
    {
      case NSScrollerKnob:
  
        result = [_theme drawThemeBackground:hTheme
          inRect:frame
          part: _horizontal ? SBP_THUMBBTNHORZ : SBP_THUMBBTNVERT
          state: flag ? SCRBS_PRESSED : SCRBS_NORMAL
          ];
        result = [_theme drawThemeBackground:hTheme
          inRect:frame
          part: _horizontal ? SBP_GRIPPERHORZ : SBP_GRIPPERVERT
          state: flag ? SCRBS_PRESSED : SCRBS_NORMAL];
        break;
      case NSScrollerKnobSlot:
        result = [_theme drawThemeBackground:hTheme
          inRect: frame
          part: _horizontal ? SBP_UPPERTRACKHORZ : SBP_UPPERTRACKVERT
          state: flag ? SCRBS_PRESSED : SCRBS_NORMAL
          ];
        break;
      case NSScrollerIncrementLine:
      case NSScrollerDecrementLine:
        if (_part==NSScrollerIncrementLine)
        {
          if (_horizontal)
            part = flag ? ABS_RIGHTPRESSED : ABS_RIGHTNORMAL;
          else
            part = flag ? ABS_DOWNPRESSED : ABS_DOWNNORMAL;
        }
        else
        {
          if (_horizontal)
            part = flag ? ABS_LEFTPRESSED : ABS_LEFTNORMAL;
          else
            part = flag ? ABS_UPPRESSED : ABS_UPNORMAL;
            
        }
        result = [_theme drawThemeBackground:hTheme
          inRect: frame
          part: SBP_ARROWBTN
          state: part 
          ];
        break;
      default:
        break;
    }    
    
    if (result)
      return;
  }
  else
  {
    NSLog(@"No theme part defined.");
  }
}
- (void) drawWithFrame:(NSRect)frame inView:(NSView*)view
{
  [self highlight:NO withFrame:frame inView:view];
}
@end


@implementation WinUXTheme (NSScroller)

- (NSButtonCell *) cellForScrollerArrow: (NSScrollerArrow)arrow
			     horizontal: (BOOL)horizontal
{
    WIN32ScrollerButtonCell *cell;
    NSScrollerPart part;
    NSString *cellName;

    if (arrow==NSScrollerIncrementArrow)
      {
	part = NSScrollerIncrementLine;
	if (horizontal)
	  cellName = @"HorizontalIncrementArrow";
	else
	  cellName = @"VerticalIncrementArrow";
      }
    else
      {
	part = NSScrollerDecrementLine;
	if (horizontal)
	  cellName = @"HorizontalDecrementArrow";
	else
	  cellName = @"VerticalDecrementArrow";
      }
    cell = [[WIN32ScrollerButtonCell alloc] initWithTheme:self scrollerPart:part
      horizontal:horizontal];

    [self setName: cellName forElement: cell temporary:YES];
    return [cell autorelease];
}

- (NSCell*) cellForScrollerKnob:(BOOL)horizontal
{
    WIN32ScrollerButtonCell *cell;
    NSString *cellName;

    if (horizontal)
      cellName = @"HorizontalScrollerKnob";
    else
      cellName = @"VerticalScrollerKnob";

    cell = [[WIN32ScrollerButtonCell alloc] initWithTheme:self scrollerPart:NSScrollerKnob
					    horizontal:horizontal];


    [self setName: cellName forElement: cell temporary:YES];
    return [cell autorelease];
}



- (NSCell*) cellForScrollerKnobSlot:(BOOL)horizontal
{
    WIN32ScrollerButtonCell *cell;
    NSString *cellName;

    if (horizontal)
      cellName = @"HorizontalScrollerKnobSlot";
    else
      cellName = @"VerticalScrollerKnobSlot";

    cell = [[WIN32ScrollerButtonCell alloc] initWithTheme:self scrollerPart:NSScrollerKnobSlot
					    horizontal:horizontal];

    [self setName: cellName forElement: cell temporary:YES];
    return [cell autorelease];

}



@end  
