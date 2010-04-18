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

#ifndef PP_FILL
#define PP_FILL 5
#endif
#ifndef PP_FILLVERT
#define PP_FILLVERT 6
#endif

@implementation WinUXTheme (NSProgressIndicator)

- (NSRect) drawProgressIndicatorBezel: (NSRect)bounds withClip: (NSRect) rect
{
  HTHEME hTheme = [self themeWithClassName: @"progress"];
  //FIXME: use clip rect?

  if (![self drawThemeBackground: hTheme
			  inRect: bounds
			    part: PP_BAR
			   state: 0])
    {
      [super drawProgressIndicatorBezel: bounds withClip: rect];
    }

  [self releaseTheme: hTheme];
  return bounds;
}

- (void) drawProgressIndicatorBarDeterminate: (NSRect)bounds
{
  HTHEME hTheme = [self themeWithClassName: @"progress"];
  int part = (NSWidth(bounds) > NSHeight(bounds)) ? PP_FILL : PP_FILLVERT;

  if (![self drawThemeBackground: hTheme
			  inRect: bounds
			    part: part
			   state: 0])
    {
      [super drawProgressIndicatorBarDeterminate: bounds];
    }

  [self releaseTheme: hTheme];
}

@end
