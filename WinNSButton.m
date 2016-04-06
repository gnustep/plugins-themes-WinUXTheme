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

@implementation WinUXTheme (NSButton)

static int _ButtonStateForThemeControlState(GSThemeControlState state)
{
  switch (state)
    {
    case GSThemeHighlightedState:
      return PBS_DEFAULTED;
    case GSThemeSelectedState:
      return PBS_PRESSED;
    case GSThemeDisabledState:
      return PBS_DISABLED;
    case GSThemeNormalState:
    default:
      return PBS_NORMAL;
    }
}

- (void) drawButton: (NSRect) frame 
                 in: (NSCell*) cell 
               view: (NSView*) view 
              style: (int) style 
              state: (GSThemeControlState) state 
{
  if(!IsThemeActive())
    {
      [super drawButton: frame
		     in: cell
		   view: view
		  style: style
		  state: state];
      return;
    }

  HTHEME hTheme = [self themeWithClassName: @"button"];
  int drawState = _ButtonStateForThemeControlState(state);
 

  if (![self drawThemeBackground: hTheme
			  inRect: frame
			    part: BP_PUSHBUTTON
			   state: drawState])
    {
      [super drawButton: frame 
		     in: cell 
		   view: view 
		  style: style 
		  state: state];
    }
  
  [self releaseTheme: hTheme];
}

- (GSThemeMargins) buttonMarginsForCell: (NSCell*)cell
                                  style: (int)style
                                  state: (GSThemeControlState)state
{
  GSThemeMargins margins = { 0 };
  
  switch (style)
  {
    case NSRoundRectBezelStyle:
      margins = [super buttonMarginsForCell:cell style:style state:state];
      break;

    case NSTexturedRoundedBezelStyle:
      if ([cell imagePosition] == NSNoImage)
      {
        if ([cell controlSize] == NSRegularControlSize)
        {
          margins.left = 10; margins.top = 7; margins.right = 10; margins.bottom = 7;
        }
        else if ([cell controlSize] == NSSmallControlSize)
        {
          margins.left = 8; margins.top = 6; margins.right = 8; margins.bottom = 6;
        }
      }
      break;

    case NSRoundedBezelStyle:
      {
        if ([cell controlSize] == NSRegularControlSize)
        {
          margins.left = 10; margins.top = 7; margins.right = 10; margins.bottom = 7;
        }
        else if ([cell controlSize] == NSSmallControlSize)
        {
          margins.left = 8; margins.top = 6; margins.right = 8; margins.bottom = 6;
        }
      }
      break;

    case NSTexturedSquareBezelStyle:
      margins = [super buttonMarginsForCell:cell style:style state:state];
      break;

    case NSRegularSquareBezelStyle:
      break;

    case NSShadowlessSquareBezelStyle:
    case NSThickSquareBezelStyle:
    case NSThickerSquareBezelStyle:
      // Currently defaulting to super's margins...
      margins = [super buttonMarginsForCell:cell style:style state:state];
      break;

    case NSCircularBezelStyle:
#if 0 // Apple doesn't seem to inset and/or draw a border around these...
      {
        if ([cell controlSize] == NSRegularControlSize)
        {
          margins.left = 10; margins.top = 9; margins.right = 10; margins.bottom = 9;
        }
        else if ([cell controlSize] == NSSmallControlSize)
        {
          margins.left = 8; margins.top = 7; margins.right = 8; margins.bottom = 7;
        }
        else if ([cell controlSize] == NSMiniControlSize)
        {
          margins.left = 7; margins.top = 6; margins.right = 7; margins.bottom = 6;
        }
      }
#endif
      break;

    case NSHelpButtonBezelStyle:
    case NSDisclosureBezelStyle:
    case NSRoundedDisclosureBezelStyle:
    case NSRecessedBezelStyle:
      // Currently defaulting to super's margins...

    default:
      margins = [super buttonMarginsForCell:cell style:style state:state];
      break;
  }
  return margins;
}

@end
