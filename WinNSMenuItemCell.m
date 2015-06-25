/* WINUXTheme A native Windows XP theme for GNUstep

   Copyright (C) 2010 Free Software Foundation, Inc.

   Written by: Gregory Casamento
   Date: January 2010
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

@implementation WinUXTheme (NSMenuItemCell)
- (void) drawBorderAndBackgroundForMenuItemCell: (NSMenuItemCell *)cell
                                      withFrame: (NSRect)frame
                                         inView: (NSView *)view
                                          state: (GSThemeControlState)state
                                   isHorizontal: (BOOL)isHorizontal
{
  if(!IsThemeActive())
    {
      [super drawBorderAndBackgroundForMenuItemCell: cell
					  withFrame: frame
					     inView: view
					      state: state
				       isHorizontal: isHorizontal];
      return;
    }

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

	  if([view isKindOfClass: [NSMenuView class]])
	    result = YES;
	  else
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
}
@end
