/* WINUXTheme A native Windows XP theme for GNUstep

   Copyright (C) 2009-2014 Free Software Foundation, Inc.

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
#import "WIN32VSImageRep.h"
#import "GSWIN32PrintPanel.h"
#import "GSWIN32PageLayout.h"

#include <Commctrl.h>

static inline RECT GSViewRectToWin(NSWindow *win, NSRect r)
{
  NSAffineTransform* ctm = [GSCurrentContext() GSCurrentCTM];

  r = (NSRect)[ctm rectInMatrixSpace: r];
  return GSWindowRectToMS(win, r);
}

@interface NSMenu (WinUXThemePrivate)
- (NSWindow *) window;
@end

@implementation NSMenu (WinUXThemePrivate)
- (NSWindow *) window
{
  return _aWindow;
}
@end

@implementation WinUXTheme

+ (void) initialize
{
  INITCOMMONCONTROLSEX icc;

  // Initialise common controls.
  icc.dwSize = sizeof(icc);
  icc.dwICC = ICC_WIN95_CLASSES;
  InitCommonControlsEx(&icc);

  // Inserting WIN32VSImageRep class for themed images.
  [NSImageRep registerImageRepClass:[WIN32VSImageRep class]];


}

- (void) activate
{
  [super activate];
  [[[NSApp mainMenu] window] orderOut: self];
}

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
      [colors setColor: [NSColor blackColor] // Win32ToGSColor(COLOR_HIGHLIGHTTEXT)
              forKey: @"selectedControlTextColor"];
      [colors setColor: [NSColor lightGrayColor]
              forKey: @"selectedKnobColor"];
      [colors setColor: Win32ToGSColor(COLOR_MENUHILIGHT)
              forKey: @"selectedMenuItemColor"];
      [colors setColor: [NSColor blackColor] // Win32ToGSColor(COLOR_3DHILIGHT)
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
      [colors setColor: Win32ToGSColor(COLOR_3DFACE) // COLOR_WINDOW
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

- (BOOL) drawThemeBackground:(HTHEME)hTheme
		      inRect:(NSRect)rect
		      part:(int)part
		      state:(int)state
{
  HDC hDC;
  RECT winRect;

  if (hTheme == NULL)
    return NO;  

  if ([self isTheme: hTheme
	partDefined: part] == NO)
    return NO;

  winRect = GSViewRectToWin([[GSCurrentContext() focusView] window], rect);
  hDC = GetCurrentHDC();

  if (FAILED(DrawThemeBackground(hTheme, hDC, part, state, &winRect, NULL)))
  {
    ReleaseCurrentHDC(hDC);
    return NO;
  }
  else
  {
    ReleaseCurrentHDC(hDC);
    return YES;
  }
}

- (HTHEME) themeWithClassName:(NSString*)className
{
  HWND hWnd;
  HTHEME hTheme;
  wchar_t* classNameChars;
  
  hWnd = (HWND)[[[NSView focusView] window] windowNumber];
  classNameChars = objc_calloc([className length]+1, sizeof(wchar_t));
  [className getCharacters:classNameChars];
  
  hTheme = OpenThemeData(hWnd, classNameChars);
  
  objc_free(classNameChars);
  return hTheme;
}

- (void) releaseTheme:(HTHEME)hTheme
{
  CloseThemeData(hTheme);
}

- (NSSize) sizeForTheme:(HTHEME)hTheme
                   part:(int)part
                  state:(int)state
                  type:(WIN32ThemeSizeType)sizeType 
{
  int type = TS_MIN;
  SIZE size;

  switch (sizeType)
  {
    case WIN32ThemeSizeMinimum: type= TS_MIN; break;
    case WIN32ThemeSizeBestFit: type = TS_TRUE; break;
    case WIN32ThemeSizeDraw: type = TS_DRAW; break;
  }

  if (FAILED(GetThemePartSize(hTheme, NULL, part, state, NULL, type, &size)))
  {
    [NSException raise:NSInternalInconsistencyException
                format:@"Error calling GetThemePartSize in -[WIN32Theme sizeForTheme:part:state:type:] (hTheme=%p,part=%d,state=%d,type=%d",
                hTheme, part, state, sizeType];
    return NSZeroSize;
  }
  else
    return NSMakeSize(size.cx, size.cy);
}

- (BOOL) isTheme:(HTHEME)hTheme partDefined:(int)part
{
  if (IsThemePartDefined(hTheme, part, 0))
    return YES;
  else 
    return NO;
} 
@end



@implementation GSTheme (PrintPanels)
/**
 * This method returns the print panel class needed by the
 * native environment.
 */
- (Class) printPanelClass
{
  return [GSWIN32PrintPanel class];
}

/**
 * This method returns the page layout class needed by the 
 * native environment.
 */
- (Class) pageLayoutClass
{
  return [GSWIN32PageLayout class];
}

@end
