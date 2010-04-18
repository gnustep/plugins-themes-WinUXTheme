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

@implementation WinUXTheme (NSStepper)

- (void) drawStepperCell: (NSCell*)cell
               withFrame: (NSRect)cellFrame
                  inView: (NSView*)controlView
             highlightUp: (BOOL)highlightUp
           highlightDown: (BOOL)highlightDown
{
  HTHEME hTheme = [self themeWithClassName: @"spin"];
  NSRect top, bottom;
  int topState, bottomState;

  bottom = cellFrame;
  bottom.size.height /= 2.0;
  top = bottom;
  top.origin.y += top.size.height;

  if ([controlView isFlipped])
    {
      NSRect temp = top;
      top = bottom;
      bottom = temp;
    }

  topState = highlightUp ? UPS_PRESSED : UPS_NORMAL;
  bottomState = highlightDown ? UPS_PRESSED : UPS_NORMAL;

  if (![self drawThemeBackground: hTheme
			  inRect: top
			    part: SPNP_UP
			   state: topState] || 
      ![self drawThemeBackground: hTheme
			  inRect: bottom
			    part: SPNP_DOWN
			   state: bottomState])
    {
      [super drawStepperCell: cell
		   withFrame: cellFrame
		      inView: controlView
		 highlightUp: highlightUp
	       highlightDown: highlightDown];
    }

  [self releaseTheme: hTheme];
}

@end
