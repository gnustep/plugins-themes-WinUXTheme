/* WINUXTheme A native Windows XP theme for GNUstep

   Copyright (C) 2010 Free Software Foundation, Inc.

   Written by: Eric Wasylishen <ewasylishen@gmail.com>
   Date: April 2010

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

@implementation WinUXTheme (NSTableHeader)

- (void) drawTableHeaderCell: (NSTableHeaderCell *)cell
                   withFrame: (NSRect)cellFrame
                      inView: (NSView *)controlView
                       state: (GSThemeControlState)state
{  
  // If the scroll view/table view is within a sub-view that is smaller than the window
  // itself we need to be careful when drawing on MSWindows with the WinUXTheme (or any theme
  // using the DC directly on MSWindows).  The HDC is for the ENTIRE window, and direct
  // writes to the HDC could write OUTSIDE of the view that the table is in, overlapping
  // onto areas outside...
  NSTableHeaderView *headerView = (NSTableHeaderView*)controlView;
  NSTableView       *tableView  = [headerView tableView];
  
  if (tableView)
    {
      // Seems like the clip view is optional(?)...
      id superView = (NSClipView*)[tableView superview];
      
      if (superView && ([superView respondsToSelector:@selector(documentVisibleRect)]))
        {
          NSRect clipFrame = [superView documentVisibleRect];
          CGFloat maxWidth = NSMaxX(clipFrame);
          
          // If outside the boundaries of the table view's super (clip) view...
          if (NSMinX(cellFrame) > maxWidth)
            return;
          
          // Do not exceed the bounds of the clip view...
          if (NSMaxX(cellFrame) > maxWidth)
          {
            cellFrame.size.width = maxWidth - cellFrame.origin.x;
#if 0
            NSLog(@"%s:clipping: %@", __PRETTY_FUNCTION__, NSStringFromRect(cellFrame));
#endif
          }
        }
    }
  
  if(!IsThemeActive())
    {
      [super drawTableHeaderCell: cell
                       withFrame: cellFrame
                          inView: (NSView *)controlView
                           state: state];
      return;
    }

  HTHEME hTheme;
  int drawState;

  switch (state)
    {
    case GSThemeHighlightedState:
      drawState = HIS_HOT;
      break;
    case GSThemeSelectedState:
      drawState = HIS_PRESSED;
      break;
    case GSThemeNormalState:
    default:
      drawState = HIS_NORMAL;
      break;
    }
    
  hTheme = [self themeWithClassName: @"header"];
  if (![self drawThemeBackground: hTheme
			  inRect: cellFrame
			    part: HP_HEADERITEM
			   state: drawState])
    {
      [super drawTableHeaderCell: cell
		       withFrame: cellFrame
			  inView: controlView
			   state: state];
    }
  [self releaseTheme: hTheme];
}

- (void) drawTableCornerView: (NSView*)cornerView
                    withClip: (NSRect)aRect
{
  [self drawTableHeaderCell: nil
		  withFrame: aRect
		     inView: nil
		      state: GSThemeNormalState];
}

@end
