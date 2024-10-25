/* WINUXTheme A native Windows theme for GNUstep
   
   Native Menu support.
   
   Copyright (C) 2009-2017 Free Software Foundation, Inc.

   Written by: Gregory Casamento <greg.casamento@gmail.com>
               Riccardo Mottola <rm@gnu.org>
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSWindowDecorationView.h>
#import "WinUXTheme.h"
#include <windows.h>
#include <math.h>

// static HMENU windows_menu = 0;
static UINT menu_tag = 0;
static NSMapTable *itemMap = 0;
static NSLock *menuLock = nil;


@interface NSWindow (WinMenuPrivate)
- (GSWindowDecorationView *) windowView;
- (void) _setMenu: (NSMenu *) menu;
@end

#ifndef _MSC_VER
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
#endif

NSMenuItem *itemForTag(UINT tag, NSMapTable *itemMap)
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
HMENU r_build_menu_for_itemmap(NSMenu *menu, BOOL asPopUp, BOOL notPullDown, NSMapTable *itemMap)
{
  NSArray *array = [menu itemArray];
  NSEnumerator *en = [array objectEnumerator];
  NSMenuItem *item = nil;
  HMENU result = 0;
  UINT flags = 0;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *cmdMod  = [defaults stringForKey: @"GSFirstCommandKey"];
  NSString *altMod  = [defaults stringForKey: @"GSFirstAlternateKey"];
  NSString *ctrlMod = [defaults stringForKey: @"GSFirstControlKey"];
  NSString *shiftMod = [defaults stringForKey: @"GSFirstShiftKey"];
  const unichar ellipsis = 0x2026;
  BOOL skipFirstItem = (asPopUp && [[menu _owningPopUp] pullsDown]); // leave first item off of pull-downs

  // if unspecified, map to default...
  if(cmdMod == nil || [cmdMod isEqual: @"NoSymbol"])
    {
      cmdMod = @"Control_L"; // Since the default on Windows is Control
    }
  if(altMod == nil || [altMod isEqual: @"NoSymbol"])
    {
      altMod = @"Alt_R";
    }
  if(ctrlMod == nil || [ctrlMod isEqual: @"NoSymbol"])
    {
      ctrlMod = @"Control_R";
    }
  if(shiftMod == nil || [shiftMod isEqual: @"NoSymbol"])
    {
      shiftMod = @"Shift";
    }

  // Map the internal names to the common ones...
  if([altMod isEqual: @"Control_L"])
    {
      altMod = @"Ctrl";
    }
  if([ctrlMod isEqual: @"Control_L"])
    {
      ctrlMod = @"Ctrl";
    }
  if([cmdMod isEqual: @"Control_L"])
    {
      cmdMod = @"Ctrl";
    }
  if([altMod isEqual: @"Control_R"])
    {
      altMod = @"Ctrl";
    }
  if([ctrlMod isEqual: @"Control_R"])
    {
      ctrlMod = @"Ctrl";
    }
  if([cmdMod isEqual: @"Control_R"])
    {
      cmdMod = @"Ctrl";
    }
  if([altMod isEqual: @"Alt_L"])
    {
      altMod = @"Alt";
    }
  if([ctrlMod isEqual: @"Alt_L"])
    {
      ctrlMod = @"Alt";
    }
  if([cmdMod isEqual: @"Alt_L"])
    {
      cmdMod = @"Alt";
    }
  if([altMod isEqual: @"Alt_R"])
    {
      altMod = @"Alt";
    }
  if([ctrlMod isEqual: @"Alt_R"])
    {
      ctrlMod = @"Alt";
    }
  if([cmdMod isEqual: @"Alt_R"])
    {
      cmdMod = @"Alt";
    }

  if(menu == nil)
    return 0; 
  
  if(asPopUp)
    {
      result = CreatePopupMenu();
    }
  else
    {
      result = CreateMenu();
    }
  while ((item = (NSMenuItem *)[en nextObject]) != nil)
    {
      NSString *title = nil;
      UINT s = 0;

      if (skipFirstItem)
        {
          skipFirstItem = NO; // only skip the first item
          continue;
        }

      // if we have a submenu then make it a popup, if not it's a normal item.
      if([item hasSubmenu])
	{
	  NSMenu *smenu = [item submenu];
	  flags = MF_STRING | MF_POPUP;
	  s = (UINT)r_build_menu_for_itemmap(smenu, asPopUp, notPullDown, itemMap);
	}
      else if([item isSeparatorItem])
	{
	  flags = MF_SEPARATOR;
	}
      else
	{
	  flags = MF_STRING;
	  s = menu_tag++;
   	  if (([item action] == NULL || [item target] == nil) && notPullDown && asPopUp)
            {
	      NSPopUpButtonCell *popup = [menu _owningPopUp];
              if (popup != nil)
	        {
	          [item setAction: @selector(_popUpItemAction:)];
	          [item setTarget: popup];
	        }
            }
	  NSMapInsert(itemMap, (const void *)s, item);
	}

      NSCharacterSet *functionKeyCharacterSet = [NSCharacterSet characterSetWithRange:NSMakeRange(NSF1FunctionKey, NSF35FunctionKey - NSF1FunctionKey)];
	
      // Don't attempt to display special characters in the title bar
      if([[item keyEquivalent] length] > 0 &&
         ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:[[item keyEquivalent] characterAtIndex:0]] ||
		  [[NSCharacterSet punctuationCharacterSet] characterIsMember:[[item keyEquivalent] characterAtIndex:0]] ||
		  [[NSCharacterSet symbolCharacterSet] characterIsMember:[[item keyEquivalent] characterAtIndex:0]] ||
		  [functionKeyCharacterSet characterIsMember:[[item keyEquivalent] characterAtIndex:0]]))
	{
	  NSString *modifier = @"";
	  int mask = [item keyEquivalentModifierMask];
	  NSString *keyEquivalent = [item keyEquivalent];

	  if(mask & NSCommandKeyMask)
	    {
	      modifier = [[modifier stringByAppendingString: cmdMod]
			   stringByAppendingString: @"+"];
	      
	    }
	  if(mask & NSAlternateKeyMask)
	    {
	      modifier = [[modifier stringByAppendingString: altMod]
			   stringByAppendingString: @"+"];
	      
	    }
	  if(mask & NSControlKeyMask)
	    {
	      modifier = [[modifier stringByAppendingString: ctrlMod]
			   stringByAppendingString: @"+"];
	      
	    }
	  if(mask & NSShiftKeyMask || ([keyEquivalent characterAtIndex:0] >= 'A' && 
				       [keyEquivalent characterAtIndex:0] <= 'Z') )
	    {
	      modifier = [[modifier stringByAppendingString: shiftMod]
			   stringByAppendingString: @"+"];
	      
	    }

	  if ([keyEquivalent characterAtIndex:0] >= NSF1FunctionKey && [keyEquivalent characterAtIndex:0] <= NSF35FunctionKey)
	    {
	      keyEquivalent = [NSString stringWithFormat:@"F%d", [keyEquivalent characterAtIndex:0] - NSF1FunctionKey + 1];
	    }

	  title = [NSString stringWithFormat: @"%@\t%@%@", 
			    [item title],
			    modifier,
			    [keyEquivalent uppercaseString]]; // Convention on windows is show cap letters 
	}
      else
	{
	  title = [NSString stringWithFormat: @"%@",
			    [item title]];
	}

      // Replace the ellipsis character with '...'
      title = [title stringByReplacingOccurrencesOfString: 
		    [[[NSString alloc] initWithCharacters: &ellipsis length: 1] autorelease]
					       withString: @"..."];

      // If it's enabled and not a seperator or a supermenu (unless submenu is empty),
      // determine if it's enabled and set it's state accordingly.
      if([item isSeparatorItem] == NO &&
         ([item hasSubmenu] == NO || [[item submenu] numberOfItems] == 0) )
        {
          flags |= MF_ENABLED; // ([item isEnabled]?MF_ENABLED:MF_GRAYED); // shouldn't this be :MF_GRAYED|MF_DISABLED ?
          // For PopUpButtons we don't set the flag on the state but on selection
	  if (notPullDown && asPopUp)
	    {
	      if (item == [[menu _owningPopUp] selectedItem])
		{
		  flags |= MF_CHECKED;
		}
	    }
	  else if ([item state] == NSOnState)
            flags |= MF_CHECKED; // set checkmark
        }

      const wchar_t *ctitle = (wchar_t*)[title cStringUsingEncoding: NSUTF16StringEncoding];
      AppendMenuW(result, flags, (UINT)s, ctitle);
    }  

  return result;
}

HMENU r_build_menu(NSMenu *menu, BOOL asPopup, BOOL notPullDown)
{
  return r_build_menu_for_itemmap(menu, asPopup, notPullDown, itemMap);
}

void build_menu(HWND win)
{
  if (win != NULL)
    {
      HMENU windows_menu = NULL;

      // Reset the tags...
      menu_tag = 100;

      // if the map is initialized, free it.
      if (itemMap != nil)
        {
          NSFreeMapTable(itemMap);
        }

      // Create the map
      itemMap = NSCreateMapTable(NSIntMapKeyCallBacks,
               NSObjectMapValueCallBacks, 50);

      // Recursively build the menu and set it on the window device.
      windows_menu = r_build_menu([NSApp mainMenu], NO, NO);
      SetMenu(win, windows_menu);
    }
}

void delete_menu(HWND win)
{
  if (win != NULL)
    {
      HMENU menu = GetMenu(win);
      if(menu)
        {
          // Iterate over the menu bar and delete all items.
//          while(DeleteMenu(menu, 0, MF_BYPOSITION));
          
          // Destroy the menu itself
          DestroyMenu(menu);
        }
    }
}

@implementation WinUXTheme (NSMenu)
- (void) updateMenu: (NSMenu *)menu
          forWindow: (NSWindow *)window
{
  if(menu != nil && window != nil && [window windowNumber] != 0)
    {
      HWND win = (HWND)[window windowNumber];
      GSWindowDecorationView *wv = [window windowView];

      delete_menu(win);
      build_menu(win);

      if(![wv hasMenu])
        {
          float h = 0.0;
          
          [window _setMenu: menu];
          h = [self menuHeightForWindow: window];
          [wv setHasMenu: YES];
          [wv changeWindowHeight: h];
        }
    }
}

- (void) setMenu: (NSMenu *)menu
       forWindow: (NSWindow *)window
{
  if(menu != nil && window != nil)
    {
      [self updateMenu: menu
             forWindow: window];
    }
}

- (void) processCommand: (void *)context usingItemMap:(NSMapTable*)itemMap
{
  WPARAM wParam = (WPARAM)context;
  UINT tag = LOWORD(wParam);
  NSMenuItem *item = itemForTag(tag, itemMap);
  SEL action = [item action];
  id target = [item target];
  
  // send the action....
  [NSApp sendAction: action
                 to: target
               from: item];
  
  // HACK: since we are outside of the NSApplication runloop, the menus won't
  // be updated automatically
  
  [[NSApp mainMenu] update];
  [[NSApp servicesMenu] update];
}

- (void) processCommand: (void *)context
{
  [self processCommand:context usingItemMap:itemMap];
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

      est_menu_width = (8.0 * letters);
      ratio = est_menu_width / rect.size.width;
      rows = ceil(ratio);
      height = rows * bar; 
    }

  return height;
}

- (void) updateAllWindowsWithMenu: (NSMenu *)menu
{
  NSEnumerator *en = [[NSApp windows] objectEnumerator];
  id            o = nil;

  while ((o = [en nextObject]) != nil)
    {
      if([o canBecomeMainWindow])
	{
	  [self updateMenu: menu forWindow: o];
	}
    }
}

- (void) rightMouseDisplay: (NSMenu *)menu
                  forEvent: (NSEvent *)theEvent
{
  NSWindow *mainWin = ([theEvent window] ? [theEvent window] : [NSApp mainWindow]);
  NSWindow *keyWin  = [NSApp keyWindow];
  NSWindow *theWin  = ((mainWin == nil) ? keyWin : mainWin);
  NSPoint   point   = [theWin convertBaseToScreen: [theEvent locationInWindow]];
  NSRect    frame   = NSMakeRect(point.x, point.y, 0, 0);
  
  // Use common method for displaying the menu...
  [self displayPopUpMenu: [menu menuRepresentation]
           withCellFrame: frame
       controlViewWindow: theWin
           preferredEdge: NSMinXEdge
            selectedItem: 0];
}

- (void) displayPopUpMenu: (NSMenuView *)mr
            withCellFrame: (NSRect)cellFrame
        controlViewWindow: (NSWindow *)cvWin
            preferredEdge: (NSRectEdge)edge
             selectedItem: (int)selectedItem
{
  BOOL     fake = NO;
  NSMenu  *menu = [mr menu];
  
  // Need menu for display...
  if (menu == nil)
    return;
  
  NSPopUpButtonCell *cell = [menu _owningPopUp];
  if (cell)
    fake = ![cell pullsDown];

  // Create a temporary item map for this popup sequence...
  NSMapTable *itemMap = NSCreateMapTable(NSIntMapKeyCallBacks,
                                         NSObjectMapValueCallBacks, 50);

  [menu update];
  
  HMENU     hmenu  = r_build_menu_for_itemmap(menu, YES, fake, itemMap);
  NSWindow *theWin = ((cvWin == nil) ? [NSApp mainWindow] : cvWin);
  HWND      win    = (HWND)[theWin windowNumber];
  NSPoint   point  = cellFrame.origin;
  POINT     p      = GSScreenPointToMS(point);
  int       x      = p.x;
  int       y      = p.y;

  // The TrackPopupMenu is a blocking call with or without the TPM_RETURNCMD flag...
  // The TPM_RETURNCMD allows us to process the menu item here instead of
  // handling a windows message...
  DWORD result = TrackPopupMenu(hmenu,
                                TPM_LEFTALIGN | TPM_RETURNCMD,
                                x,
                                y,
                                0,
                                win,
                                NULL);
  
  // Process the result, if any...
  if (result == 0)
    {
      // User either cancelled (via click elsewhere) or there was an error...
      DWORD status = GetLastError();
      if (status && (status != ERROR_INVALID_HANDLE))
        NSWarnMLog(@"error processing popup menu - status: %d", status);
      
      // Purge the mouse click if the user clicked somewhere that caused the menu to go away...
      [NSApp nextEventMatchingMask: NSLeftMouseDownMask | NSLeftMouseUpMask | NSMouseMovedMask
                         untilDate: [NSDate distantFuture]
                            inMode: NSEventTrackingRunLoopMode
                           dequeue: YES];
    }
  else
    {
      // Process the menu item selected...
      [self processCommand:(void*)result usingItemMap:itemMap];
    }
  
  // Cleanup...
  DestroyMenu(hmenu);
  NSFreeMapTable(itemMap);
}

- (BOOL) doesProcessEventsForPopUpMenu
{
  // this theme handles popUpMenu events
  return YES;
}

@end
 
/**
 * Draw menu views as boxes instead of groups of buttons.
 */
@implementation WinUXTheme (NSMenuView)
- (void) drawBackgroundForMenuView: (NSMenuView*)menuView
                         withFrame: (NSRect)bounds
                         dirtyRect: (NSRect)dirtyRect
                        horizontal: (BOOL)horizontal 
{
  NSString  *name = horizontal ? GSMenuHorizontalBackground : 
    GSMenuVerticalBackground;
  GSDrawTiles *tiles = [self tilesNamed: name state: GSThemeNormalState];
 
  if (tiles == nil)
    {
      NSRectEdge sides[] = {NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge,
			    NSMinYEdge, NSMaxXEdge};
      float      grays[] = {NSBlack, NSBlack, NSBlack, NSBlack, 
			    NSDarkGray, NSDarkGray};

     [[NSColor whiteColor] set];
     NSRectFill(NSIntersectionRect(bounds, dirtyRect));
     NSDrawTiledRects(bounds, dirtyRect, sides, grays, 2);
    }
  else
    {
      [self fillRect: bounds
           withTiles: tiles
          background: [NSColor clearColor]];
    }
}
@end
