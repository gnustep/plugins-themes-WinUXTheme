//
//  WinNSTabViewItem.m
//  WinUXTheme
//
//  Created by Marcian Lytwyn on 1/9/18.
//  Copyright © 2018 Marcian Lytwyn. All rights reserved.
//

#import "WinUXTheme.h"

@implementation WinUXTheme (NSTabView)

static int _TabStateForThemeControlState(NSTabState state)
{
  switch (state)
  {
    case NSPressedTab:
      return TIS_FOCUSED;
    case NSSelectedTab:
      return TIS_SELECTED;
    case NSBackgroundTab:
    default:
      return TIS_NORMAL;
  }
}

- (void) drawTabViewBezelRect: (NSRect)aRect
                  tabViewType: (NSTabViewType)type
                       inView: (NSView *)view
{
  if (!IsThemeActive())
    {
      [super drawTabViewBezelRect: aRect
                      tabViewType: type
                           inView: view];
    }
  else
    {
      HTHEME hTheme = [self themeWithClassName: @"tab"];
      
      if (hTheme == NULL)
        {
          // Default to GSTheme...
          [super drawTabViewBezelRect: aRect
                          tabViewType: type
                               inView: view];
        }
      else
      {
        if (![self drawThemeBackground: hTheme
                                inRect: aRect
                                  part: TABP_BODY
                                 state: 0])
        {
          // Default to GSTheme...
          [super drawTabViewBezelRect: aRect
                          tabViewType: type
                               inView: view];
        }
        
        [self releaseTheme: hTheme];
      }
    }
}

- (void) drawTabViewRect: (NSRect)rect
                  inView: (NSView *)view
               withItems: (NSArray *)items
            selectedItem: (NSTabViewItem *)selected
{
  if (!IsThemeActive())
    {
      [super drawTabViewRect: rect
                      inView: view
                   withItems: items
                selectedItem: selected];
    }
  else
    {
      // Using tab class...
      HTHEME hTheme = [self themeWithClassName: @"tab"];

      if (hTheme == NULL)
        {
          // Default to GSTheme...
          [super drawTabViewRect: rect
                          inView: view
                       withItems: items
                    selectedItem: selected];
        }
      else
        {
          static const CGFloat  FRAME_ADJUST = 6.0;
          static const CGFloat  FRAME_LEFT_EDGE = 3.0;
          static const CGFloat  FRAME_RIGHT_EDGE = 3.0;
          
          const NSTabViewType   type      = [(NSTabView *)view tabViewType];
          const BOOL            truncate  = [(NSTabView *)view allowsTruncatedLabels];
          const NSRect          bounds    = [view bounds];
          NSRect                aRect     = [self tabViewBackgroundRectForBounds: bounds tabViewType: type];
          const CGFloat         tabHeight = [self tabHeightForType: type];
          int                   part      = TABP_TABITEMBOTHEDGE;
          NSPoint               iP        = NSZeroPoint;
          id                    item      = nil;
          id                    firstItem = [items firstObject];
          id                    lastItem  = [items lastObject];
          NSInteger             itemCount = [items count];

          if (type == NSTopTabsBezelBorder)
            iP = NSMakePoint(rect.origin.x, bounds.origin.y);
          else
            iP = NSMakePoint(rect.origin.x, NSMaxY(aRect));
          NSWarnMLog(@"rect: %@ bounds %@ aRect: %@ iP: %@", NSStringFromRect(rect),
                     NSStringFromRect(bounds), NSStringFromRect(aRect), NSStringFromPoint(iP));
          
          // Draw the background...use super as Windows Theming may not match GNUstep GSTheme
          // for processing that DOES NOT include WinUXTheme...
          [super drawTabViewBezelRect: aRect tabViewType: type inView: view];
          
          // Loop thru tab items and draw each one...
          for (item in items)
            {
              const NSSize s = [item sizeOfLabel: truncate];
              NSRect tabFrame = NSMakeRect(iP.x, iP.y, s.width+FRAME_ADJUST, tabHeight);
              NSRect labelFrame = NSMakeRect(iP.x+(FRAME_ADJUST/2), iP.y, s.width, tabHeight);
              int drawState = _TabStateForThemeControlState([item tabState]);
              
              if (item == firstItem) // could be one item in this case...
                part = ((itemCount == 1) ? TABP_TABITEMBOTHEDGE : TABP_TABITEMLEFTEDGE);
              else if (item == lastItem)
                part = TABP_TABITEMRIGHTEDGE;
              else // Middle item - no edge...
                part = TABP_TABITEM;
              
              // Draw the part...
              [self drawThemeBackground: hTheme inRect: tabFrame part: part state: drawState];

              // Label
              [item drawLabel: truncate inRect: labelFrame];
              
              // Update frame values...
              iP.x += tabFrame.size.width;
            }
          
          [self releaseTheme: hTheme];
        }
    }
}

@end
