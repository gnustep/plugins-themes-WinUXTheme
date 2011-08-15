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
  if(!IsThemeActive())
    {
      return [super buttonMarginsForCell: cell
				   style: style
				   state: state];
    }

  HTHEME hTheme;
  NSWindow *window = [[cell controlView] window];
  HWND hwnd = (HWND)[window windowNumber];

  hTheme = OpenThemeData(hwnd, L"button");
  if (hTheme != NULL)
    {
      BOOL result = NO;
      GSThemeMargins margins = {0, 0, 0, 0};

      if (IsThemePartDefined(hTheme, BP_PUSHBUTTON, 0))
        {
          int drawState = _ButtonStateForThemeControlState(state);
          HDC hDC = GetCurrentHDC();
          MARGINS win32Margins;

          result = (GetThemeMargins(hTheme, hDC, BP_PUSHBUTTON, drawState, 
                                    TMT_CONTENTMARGINS, NULL, &win32Margins) == S_OK);
          if (result)
            {
              margins.left = win32Margins.cxLeftWidth;
	      margins.right = win32Margins.cxRightWidth;
	      margins.top = win32Margins.cyTopHeight;
	      margins.bottom = win32Margins.cyBottomHeight;
            }
          ReleaseCurrentHDC(hDC);
        }

      CloseThemeData(hTheme);
      if (result)
        {
          return margins;
        }
    }

  return [super buttonMarginsForCell: cell
			       style: style 
			       state: state];
}

@end
