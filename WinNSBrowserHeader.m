/* WINUXTheme A native Windows XP theme for GNUstep

   Copyright (C) 2010 Free Software Foundation, Inc.

   Written by: Eric Wasylishen <ewasylishen@gmail.com>
   Date: April 2010

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

@implementation WinUXTheme (NSBrowserHeader)

- (void) drawBrowserHeaderCell: (NSCell*)cell
	 	     withFrame: (NSRect)rect
			inView: (NSView*)view;
{
  // Draw nothing. This looks most appropriate to me.
}

- (NSRect) browserHeaderDrawingRectForCell: (NSCell*)cell
				 withFrame: (NSRect)rect
{
  return NSInsetRect(rect, 0, 0);
}

@end
