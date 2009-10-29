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
#import <GNUstepGUI/GSDisplayServer.h>
#import "WinUXTheme.h"

// Import Windows headers for theme management.
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0501 // Minimal target is Windows XP
#include <windows.h>
#include <uxtheme.h>
#include <tmschema.h>

// These colours are missing for mingw
#ifndef COLOR_MENUHILIGHT
#define COLOR_MENUHILIGHT 29
#endif
#ifndef COLOR_MENUBAR
#define COLOR_MENUBAR 30
#endif

@interface NSObject (WIN32GState)
- (HDC) getHDC;
- (void) releaseHDC:(HDC)hdc;
@end

@interface NSObject (GSGraphicsContext)
- (id) currentGState;
@end

/*
 * See http://msdn.microsoft.com/en-us/library/ms724371(VS.85).aspx
 * for possible values for nIndex.
 */
static inline NSColor *Win32ToGSColor(int nIndex)
{
  DWORD color = GetSysColor(nIndex);
  float red, green, blue;

  red = ((float)GetRValue(color)) / 255.0;
  green = ((float)GetGValue(color)) / 255.0;
  blue = ((float)GetBValue(color)) / 255.0;

  return [NSColor colorWithDeviceRed: red
                  green: green
                  blue: blue
                  alpha: 1.0];
}

/*
 * See WIN32Geometry.h for this code
 */
static inline RECT
GSWindowRectToMS(NSWindow *window, NSRect r0)
{
  NSGraphicsContext *ctxt;
  RECT rect;
  float h, l, r, t, b;
  RECT r1;
  HWND hwnd = (HWND)[window windowNumber];

  GetClientRect(hwnd, &rect);
  h = rect.bottom - rect.top;
  [GSServerForWindow(window) styleoffsets: &l : &r : &t : &b 
                    : [window styleMask]];

  r1.left = r0.origin.x - l;
  r1.bottom = h - r0.origin.y + b;
  r1.right = r1.left + r0.size.width;
  r1.top = r1.bottom - r0.size.height;

  return r1;
}

static inline HDC GetCurrentHDC()
{
  return (HDC)[[GSCurrentContext() currentGState] getHDC]; 
}

static inline void ReleaseCurrentHDC(HDC hdc)
{
  [[GSCurrentContext() currentGState] releaseHDC: hdc];
}

@implementation WinUXTheme

- (NSColorList*) colors
{
  static NSColorList *colors = nil;

  if (colors == nil)
    {
      colors = [[NSColorList alloc] initWithName: @"System"
                                    fromFile: nil];

      [colors setColor: Win32ToGSColor(COLOR_MENU)
              forKey: @"controlBackgroundColor"];
      [colors setColor: Win32ToGSColor(COLOR_BTNFACE)
              forKey: @"controlColor"];
      [colors setColor: Win32ToGSColor(COLOR_3DHILIGHT)
              forKey: @"controlHighlightColor"];
      [colors setColor: Win32ToGSColor(COLOR_3DLIGHT)
              forKey: @"controlLightHighlightColor"];
      [colors setColor: Win32ToGSColor(COLOR_3DSHADOW)
              forKey: @"controlShadowColor"];
      [colors setColor: Win32ToGSColor(COLOR_3DDKSHADOW)
              forKey: @"controlDarkShadowColor"];
      [colors setColor: Win32ToGSColor(COLOR_WINDOWTEXT)
              forKey: @"controlTextColor"];
      [colors setColor: Win32ToGSColor(COLOR_GRAYTEXT)
              forKey: @"disabledControlTextColor"];
      [colors setColor: [NSColor grayColor]
              forKey: @"gridColor"];
      [colors setColor: [NSColor lightGrayColor]
              forKey: @"headerColor"];
      [colors setColor: [NSColor blackColor]
              forKey: @"headerTextColor"];
      [colors setColor: Win32ToGSColor(COLOR_HIGHLIGHT)
              forKey: @"highlightColor"];
      [colors setColor: [NSColor blackColor]
              forKey: @"keyboardFocusIndicatorColor"];
      [colors setColor: Win32ToGSColor(COLOR_3DFACE)
              forKey: @"knobColor"];
      [colors setColor: Win32ToGSColor(COLOR_SCROLLBAR)
              forKey: @"scrollBarColor"];
      [colors setColor: Win32ToGSColor(COLOR_HIGHLIGHT)
              forKey: @"selectedControlColor"];
      [colors setColor: Win32ToGSColor(COLOR_HIGHLIGHTTEXT)
              forKey: @"selectedControlTextColor"];
      [colors setColor: [NSColor lightGrayColor]
              forKey: @"selectedKnobColor"];
      [colors setColor: Win32ToGSColor(COLOR_MENUHILIGHT)
              forKey: @"selectedMenuItemColor"];
      [colors setColor: Win32ToGSColor(COLOR_3DHILIGHT)
              forKey: @"selectedMenuItemTextColor"];
      [colors setColor: Win32ToGSColor(COLOR_HIGHLIGHT)
              forKey: @"selectedTextBackgroundColor"];
      [colors setColor: Win32ToGSColor(COLOR_HIGHLIGHTTEXT)
              forKey: @"selectedTextColor"];
      [colors setColor: Win32ToGSColor(COLOR_3DSHADOW)
              forKey: @"shadowColor"];
      [colors setColor: [NSColor whiteColor]
              forKey: @"textBackgroundColor"];
      [colors setColor: Win32ToGSColor(COLOR_WINDOWTEXT)
              forKey: @"textColor"];
      [colors setColor: Win32ToGSColor(COLOR_WINDOW)
              forKey: @"windowBackgroundColor"];
      [colors setColor: Win32ToGSColor(COLOR_WINDOWFRAME)
              forKey: @"windowFrameColor"];
      [colors setColor: Win32ToGSColor(COLOR_CAPTIONTEXT)
              forKey: @"windowFrameTextColor"];
      [colors setColor: [NSColor blackColor]
              forKey: @"alternateSelectedControlColor"];
      [colors setColor: [NSColor whiteColor]
              forKey: @"alternateSelectedControlTextColor"];
      [colors setColor: [NSColor whiteColor]
              forKey: @"rowBackgroundColor"];
      [colors setColor: [NSColor lightGrayColor]
              forKey: @"alternateRowBackgroundColor"];
      [colors setColor: [NSColor lightGrayColor]
              forKey: @"secondarySelectedControlColor"];
    }

  return colors;
}

@end

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

