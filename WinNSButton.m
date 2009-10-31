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

- (void) drawButton: (NSRect) frame 
                 in: (NSCell*) cell 
               view: (NSView*) view 
              style: (int) style 
              state: (GSThemeControlState) state 
{
  HTHEME hTheme;
  NSWindow *window = [view window];
  HWND hwnd = (HWND)[window windowNumber];

  hTheme = OpenThemeData(hwnd, L"button");
  if (hTheme != NULL)
    {
      BOOL result = NO;
          
      if (IsThemePartDefined(hTheme, BP_PUSHBUTTON, 0))
        {
          int drawState;
          HDC hDC = GetCurrentHDC();
          RECT winRect = GSWindowRectToMS(window, [view convertRect: frame toView: nil]);
          
          switch (state)
            {
            case GSThemeHighlightedState:
              drawState = PBS_DEFAULTED;
              break;
            case GSThemeSelectedState:
              drawState = PBS_PRESSED;
              break;
            case GSThemeNormalState:
            default:
              drawState = PBS_NORMAL;
              break;
            }
      
          result = (DrawThemeBackground(hTheme, hDC, BP_PUSHBUTTON, drawState, 
                                        &winRect, NULL) == S_OK);
          ReleaseCurrentHDC(hDC);
        }

      CloseThemeData(hTheme);
      if (result)
        {
          return;
        }
    }

  [super drawButton: frame 
         in: cell 
         view: view 
         style: style 
         state: state];
}

- (NSSize) buttonBorderForCell: (NSCell*)cell
			 style: (int)style 
			 state: (GSThemeControlState)state
{
  HTHEME hTheme;
  NSWindow *window = [[cell controlView] window];
  HWND hwnd = (HWND)[window windowNumber];

  hTheme = OpenThemeData(hwnd, L"button");
  if (hTheme != NULL)
    {
      BOOL result = NO;
      NSSize size;

      if (IsThemePartDefined(hTheme, BP_PUSHBUTTON, 0))
        {
          int drawState;
          HDC hDC = GetCurrentHDC();
          MARGINS win32Margins;

          switch (state)
            {
            case GSThemeHighlightedState:
              drawState = PBS_DEFAULTED;
              break;
            case GSThemeSelectedState:
              drawState = PBS_PRESSED;
              break;
            case GSThemeNormalState:
            default:
              drawState = PBS_NORMAL;
              break;
            }
      
          result = (GetThemeMargins(hTheme, hDC, BP_PUSHBUTTON, drawState, 
                                    TMT_CONTENTMARGINS, NULL, &win32Margins) == S_OK);
          if (result)
            {
              size = NSMakeSize(win32Margins.cxLeftWidth + win32Margins.cxRightWidth, 
                                win32Margins.cyTopHeight + win32Margins.cyBottomHeight);
            }
          ReleaseCurrentHDC(hDC);
        }

      CloseThemeData(hTheme);
      if (result)
        {
          return size;
        }
    }

  return [super buttonBorderForCell: cell
                style: style 
                state: state];
}

@end
