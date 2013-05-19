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

#define EP_EDITBORDER_NOSCROLL 6
#define EPSN_NORMAL 1

// a border width of 5 gives a reasonable compromise between Cocoa metrics and looking good
#define COLOR_WELL_BORDER_WIDTH 5.0

@implementation WinUXTheme (NSColorWell)

- (NSRect) drawColorWellBorder: (NSColorWell*)well
                    withBounds: (NSRect)bounds
                      withClip: (NSRect)clipRect
{
  NSRect aRect = bounds;
  GSThemeControlState state;
  
  // FIXME: refactor so more of the work is done in NSColorWell rather than in the theme
  // FIXME: use clipRect?
  
  if ([[well cell] isHighlighted] || [well isActive])
    {
      state = GSThemeHighlightedState;
    }
  else
    {
      state = GSThemeNormalState;
    }
  
  if ([well isBordered])
    {
      HTHEME hTheme = [self themeWithClassName: @"button"];
      int drawState = (state == GSThemeHighlightedState) ? PBS_HOT : PBS_NORMAL;
      
      if (![self drawThemeBackground: hTheme
                              inRect: bounds
                                part: BP_PUSHBUTTON
                               state: drawState])
      {
        [self releaseTheme:hTheme];
        return [super drawColorWellBorder: well withBounds: bounds withClip: clipRect];
      }
      [self releaseTheme:hTheme];
      
      aRect = NSInsetRect(bounds, COLOR_WELL_BORDER_WIDTH, COLOR_WELL_BORDER_WIDTH);
    }
  
  
  if ([well isEnabled])
    {
      HTHEME hTheme = [self themeWithClassName: @"edit"];
      
      if (hTheme)
        {
          if (![self drawThemeBackground: hTheme
                                  inRect: aRect
                                    part: EP_EDITBORDER_NOSCROLL
                                   state: EPSN_NORMAL])
            {
              [self drawGrayBezel: aRect withClip: clipRect];
              aRect = NSInsetRect(aRect, 2.0, 2.0);
            }
          else
            {
              // FIXME: lookup inset from Windows
              aRect = NSInsetRect(aRect, 1.0, 1.0);
            }
          
          // Release the theme...
          [self releaseTheme:hTheme];
        }
    }
  
  return aRect;
}

@end
