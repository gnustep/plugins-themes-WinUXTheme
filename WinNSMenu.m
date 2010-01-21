/* WINUXTheme A native Windows XP theme for GNUstep
   
   Native Menu support.
   
   Copyright (C) 2009 Free Software Foundation, Inc.

   Written by: Gregory Casamento <greg.casamento@gmail.com>
   Date: Jan 2010

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
#import <GNUstepGUI/GSWindowDecorationView.h>
#import "WinUXTheme.h"
#include <windows.h>

static HMENU windows_menu = 0;
static UINT menu_tag = 0;
static NSMapTable *itemMap = 0;

@interface NSWindow (WinMenuPrivate)
- (GSWindowDecorationView *) windowView;
@end

@implementation NSWindow (WinMenuPrivate)
- (GSWindowDecorationView *) windowView
{
  return _wv;
}
@end

NSMenuItem *itemForTag(UINT tag)
{
  return (NSMenuItem *)NSMapGet(itemMap,(const void *)tag);
}

// find all subitems for the given items...
HMENU r_build_menu(NSMenu *menu)
{
  NSArray *array = [menu itemArray];
  NSEnumerator *en = [array objectEnumerator];
  NSMenuItem *item = nil;
  HMENU result = 0;
  UINT flags = 0;
  
  if(menu == nil)
    return 0; 
  
  result = CreateMenu();
  while ((item = (NSMenuItem *)[en nextObject]) != nil)
    {
      NSString *title = nil; // [item title];
      const char *ctitle; // = [title UTF8String];
      // char key[50]; // = [[item keyEquivalent] UTF8String];
      // char *modifier;
      NSString *modifier = @"";
      UINT s = 0;

      // if we have a submenu then make it a popup, if not it's a normal item.
      if([item hasSubmenu])
	{
	  NSMenu *smenu = [item submenu];
	  flags = MF_STRING | MF_POPUP;
	  s = (UINT)r_build_menu(smenu);
	}
      else if([item isSeparatorItem])
	{
	  flags = MF_SEPARATOR;
	}
      else
	{
	  flags = MF_STRING;
	  s = menu_tag++;
	  NSMapInsert(itemMap, (const void *)s, item);
	}

      if([[item keyEquivalent] isEqualToString: @""] == NO)
	{
	  switch([item keyEquivalentModifierMask])
	    {
	    case NSShiftKeyMask:
	      modifier = @"Shift";
	      break;
	    case NSControlKeyMask:
	      modifier = @"Ctrl";
	      break;
	    case NSCommandKeyMask:
	      modifier = @"Alt";
	      break;
	    case NSAlternateKeyMask:
	      modifier = @"AltGr";
	      break;
	    default:
	      modifier = @"Alt";
	      break;
	    }
	  
	  title = [NSString stringWithFormat: @"%@\t%@-%@",
			    [item title],
			    modifier,
			    [item keyEquivalent]];
	}
      else
	{
	  title = [NSString stringWithFormat: @"%@",
			    [item title]];
	}

      ctitle = [title cStringUsingEncoding: NSUTF8StringEncoding];
      AppendMenu(result, flags, (UINT)s, ctitle);
    }  

  return result;
}

void build_menu(HWND win)
{
  // Reset the tags...
  menu_tag = 100;

  // if the map is initialized, free it.
  if (itemMap != nil)
    {
      NSFreeMapTable(itemMap);
    }

  // Create the map
  itemMap = NSCreateMapTable(NSIntMapKeyCallBacks,
			     NSNonRetainedObjectMapValueCallBacks, 50);

  // Recursively build the menu and set it on the window device.
  windows_menu = r_build_menu([NSApp mainMenu]);
  SetMenu(win, windows_menu);
}

@implementation WinUXTheme (NSMenu)
- (void) setMenu: (NSMenu *)menu
       forWindow: (NSWindow *)window
{
  HWND win = (HWND)[window windowNumber];

  if(GetMenu(win) == NULL)
    {     
      build_menu(win);
      
      [[window windowView] setHasMenu: YES];
      [[window windowView] changeWindowHeight: 
		    [self menuHeightForWindow: window]];
    }
}

- (void) processCommand: (void *)context
{
  WPARAM wParam = (WPARAM)context;
  UINT tag = LOWORD(wParam);
  NSMenuItem *item = itemForTag(tag);
  SEL action = [item action];
  id target = [item target];
  
  // send the action....
  [NSApp sendAction: action
		 to: target
	       from: item];
}

- (float) menuHeightForWindow: (NSWindow *)window
{
  /*
  BOOL succeeded = NO;
  MENUBARINFO mbi;
  HWND win = (HWND)[window windowNumber];
  RECT bar;
  float menuHeight = 0.0;

  mbi.cbSize = sizeof(MENUBARINFO);
  succeeded = GetMenuBarInfo(win,OBJID_CLIENT,0,&mbi);
  bar = mbi.rcBar;
  menuHeight = (float)(bar.bottom - bar.top);

  // temporarily override...
  return 20;
  */

  return (float)GetSystemMetrics(SM_CYMENU);
}
@end
