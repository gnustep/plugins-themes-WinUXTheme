/* WINUXTheme A native Windows XP theme for GNUstep

   Copyright (C) 2009-2014 Free Software Foundation, Inc.

   Written by: Fred Kiefer <FredKiefer@gmx.de>
   Date: October 2009

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

#ifndef GNUstep_WINUXTHEME_H
#define GNUstep_WINUXTHEME_H

#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <GNUstepGUI/GSTheme.h>

// Import Windows headers for theme management.
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0501 // Minimal target is Windows XP

#ifndef _WIN32_IE
#define _WIN32_IE    0x0401
#endif

#include <windows.h>
#include <uxtheme.h>
#ifdef _MSC_VER
#include <vssym32.h>
#else
#include <tmschema.h>
#endif

// These colours are missing for mingw
#ifndef COLOR_MENUHILIGHT
 #define COLOR_MENUHILIGHT 29
#endif
#ifndef COLOR_MENUBAR
#define COLOR_MENUBAR 30
#endif

typedef enum WIN32ThemeSizeType
{
  WIN32ThemeSizeBestFit,
  WIN32ThemeSizeMinimum,
  WIN32ThemeSizeDraw
} WIN32ThemeSizeType;

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

static inline POINT
GSScreenPointToMS(NSPoint p)
{
  POINT p1;
  int screen_height = GetSystemMetrics(SM_CYSCREEN);

  p1.x = p.x;
  p1.y = screen_height - p.y;
  return p1;
}

static inline HDC GetCurrentHDC()
{
  return (HDC)[[GSCurrentContext() currentGState] getHDC]; 
}

static inline void ReleaseCurrentHDC(HDC hdc)
{
  [[GSCurrentContext() currentGState] releaseHDC: hdc];
}


@interface WinUXTheme: GSTheme
- (BOOL) drawThemeBackground:(HTHEME)hTheme 
                      inRect:(NSRect)rect 
                        part:(int)part 
                       state:(int)state;
- (HTHEME) themeWithClassName:(NSString*)className;
- (void) releaseTheme:(HTHEME)hTheme;
- (NSSize) sizeForTheme:(HTHEME)hTheme
                   part:(int)part
                  state:(int)state
  		   type:(WIN32ThemeSizeType)sizeType;
- (BOOL) isTheme:(HTHEME)hTheme partDefined:(int)part;
@end

#endif
