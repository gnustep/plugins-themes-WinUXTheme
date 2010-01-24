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
#include <math.h>

static HMENU windows_menu = 0;
static UINT menu_tag = 0;
static NSMapTable *itemMap = 0;
static NSLock *menuLock = nil;

@interface NSWindow (WinMenuPrivate)
- (GSWindowDecorationView *) windowView;
- (void) _setMenu: (NSMenu *) menu;
@end

@implementation NSWindow (WinMenuPrivate)
- (GSWindowDecorationView *) windowView
{
  return _wv;
}

- (void) _setMenu: (NSMenu *) menu
{
  [super setMenu: menu];
}
@end

NSMenuItem *itemForTag(UINT tag)
{
  return (NSMenuItem *)NSMapGet(itemMap,(const void *)tag);
}

void initialize_lock()
{
  if(menuLock == nil)
    {
      menuLock = [[NSLock alloc] init];
    }
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
      NSString *title = nil;
      const char *ctitle;
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

      // If it's enabled and not a seperator or a supermenu,
      // determine if it's enabled and set it's state accordingly.
      if([item isSeparatorItem] == NO &&
	 [item hasSubmenu] == NO)
	{
	  flags |= ([item isEnabled]?MF_ENABLED:MF_GRAYED);
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

void delete_menu(HWND win)
{
  HMENU menu = GetMenu(win);
  if(menu)
    {
      // Iterate over the menu bar and delete all
      // items.
      while(DeleteMenu(menu, 0, MF_BYPOSITION));
    }
}

@implementation WinUXTheme (NSMenu)
- (void) updateMenu: (NSMenu *)menu
	  forWindow: (NSWindow *)window
{
  if(menu != nil && window != nil)
    {
      HWND win = (HWND)[window windowNumber];
      initialize_lock();
      [menuLock lock];

      delete_menu(win);
      build_menu(win);
      [menuLock unlock];
      NSLog(@"menu = %@, window = %@", menu, window);
    }
}

- (void) setMenu: (NSMenu *)menu
       forWindow: (NSWindow *)window
{
  if(menu != nil && window != nil)
    {
      HWND win = (HWND)[window windowNumber];
      
      if(GetMenu(win) == NULL)
	{ 
	  float h = 0.0;
	  
	  [self updateMenu: menu
		 forWindow: window];
	  
	  [window _setMenu: menu];
	  h = [self menuHeightForWindow: window];      
	  [[window windowView] setHasMenu: YES];
	  [[window windowView] changeWindowHeight: h]; 
	}
    }
}

- (void) processCommand: (void *)context
{
  [menuLock lock];
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
  [menuLock unlock];
}

- (float) menuHeightForWindow: (NSWindow *)window
{
  NSArray *items = [[window menu] itemArray];
  float height = 0.0;

  if([items count] > 0)
    {
      NSEnumerator *en = [items objectEnumerator];
      id obj = nil;
      float est_menu_width = 0.0; 
      float ratio = 0.0; 
      int rows = 0 ; 
      int letters = 0;
      int bar = GetSystemMetrics(SM_CYMENU);
      NSRect rect = [window frame];
  
      /**
       * This calculation is something of a hack.
       * It will count up the number of letters in the top level
       * menu and determine if that can overflow the width of the window.
       */
      while ((obj = [en nextObject]) != nil)
	{
	  letters += [[obj title] length];
	  letters += 2; // the 1 character pad on each side.
	}      

      est_menu_width = (6.0 * letters);
      ratio = est_menu_width / rect.size.width;
      rows = ceil(ratio);
      height = rows * bar; 
    }

  return height;
}
@end
