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
      break;

    case NSTexturedRoundedBezelStyle:
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
      margins.left = 3; margins.top = 1; margins.right = 3; margins.bottom = 1;
      break;

    case NSRegularSquareBezelStyle:
      margins.left = 2; margins.top = 2; margins.right = 2; margins.bottom = 2;
      break;

    case NSShadowlessSquareBezelStyle:
      break;

    case NSThickSquareBezelStyle:
      margins.left = 3; margins.top = 3; margins.right = 3; margins.bottom = 3;
      break;

    case NSThickerSquareBezelStyle:
      margins.left = 4; margins.top = 4; margins.right = 4; margins.bottom = 4;
      break;

    case NSCircularBezelStyle:
#if 0
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
      margins.left = 2; margins.top = 3; margins.right = 2; margins.bottom = 3;
      break;

    case NSDisclosureBezelStyle:
    case NSRoundedDisclosureBezelStyle:
    case NSRecessedBezelStyle:
      // FIXME
      margins.left = 3; margins.top = 3; margins.right = 3; margins.bottom = 3;
      break;

    default:
      margins.left = 3; margins.top = 3; margins.right = 3; margins.bottom = 3;
      break;
  }
  return margins;
}

@end
