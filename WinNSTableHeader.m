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
