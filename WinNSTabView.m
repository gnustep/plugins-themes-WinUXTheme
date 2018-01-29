//
//  WinNSTabView.m
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

- (CGFloat) tabHeightForType: (NSTabViewType)type
{
  HTHEME  hTheme = [self themeWithClassName: @"tab"];
  NSSize  size   = NSMakeSize(0, 17.0);
  if (hTheme == NULL)
  {
    // Default to GSTheme...
    size.height = [super tabHeightForType: type];
  }
  else
  {
    size = [self sizeForTheme: hTheme part: TABP_TABITEM state: TIS_NORMAL type: WIN32ThemeSizeBestFit];
    [self releaseTheme: hTheme];
  }
  return size.height;
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
      // Ensure the requested drawing rectangle includes the tab area...
      const NSTabViewType type      = [(NSTabView *)view tabViewType];
      const CGFloat       tabHeight = [self tabHeightForType: type];
      const NSRect        bounds    = [view bounds];
      const NSRect        frame     = [view frame];
      NSRect              aRect     = [self tabViewBackgroundRectForBounds: bounds tabViewType: type];
      NSPoint             iP        = ((type == NSTopTabsBezelBorder) ?
                                       NSMakePoint(bounds.origin.x, bounds.origin.y) :
                                       NSMakePoint(rect.origin.x, NSMaxY(aRect)));
      const NSRect        check     = NSMakeRect(iP.x, iP.y, bounds.size.width, tabHeight);
      NSDebugMLLog(@"WinNSTabView", @"frame: %@ rect: %@ check: %@ intersection: %@",
                   NSStringFromRect(frame),
                   NSStringFromRect(rect), NSStringFromRect(check),
                   NSStringFromRect(NSIntersectionRect(rect, check)));

      // Avoid drawing tabs if the tab view part is NOT in the requested rectangle...
      if (NSIntersectsRect(rect, check))
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
              static const CGFloat  FRAME_ADJUST = 12.0;
              
              NSGraphicsContext    *ctxt = GSCurrentContext();
              const NSTabViewType   type      = [(NSTabView *)view tabViewType];
              const BOOL            truncate  = [(NSTabView *)view allowsTruncatedLabels];
              int                   part      = TABP_TABITEMBOTHEDGE;
              id                    item      = nil;
              id                    firstItem = [items firstObject];
              id                    lastItem  = [items lastObject];
              NSInteger             itemCount = [items count];
              NSDebugMLLog(@"WinNSTabView", @"rect: %@ aRect: %@",
                           NSStringFromRect(rect), NSStringFromRect(aRect));
              
              // Save the current graphics context state...
              //DPSgsave(ctxt);

              // Draw the background...
#if 0
              [self drawTabViewBezelRect: aRect tabViewType: type inView: view];
#else
              // FIXME: Use super as Windows Theming may not match GNUstep GSTheme
              // for processing that DOES NOT include WinUXTheme...
              // Unfortunately this means we're mixing HDC and GNUstep drawing but
              // unavoidable for now...
              [super drawTabViewBezelRect: bounds tabViewType: type inView: view];
#endif
              
              // Loop thru tab items and draw each one...
              for (item in items)
                {
                  const NSSize s = [item sizeOfLabel: truncate];
                  NSRect tabFrame = NSMakeRect(iP.x, iP.y, s.width+FRAME_ADJUST, tabHeight);
                  NSRect labelFrame = NSMakeRect(iP.x+(FRAME_ADJUST/2), iP.y, s.width, tabHeight);
                  int drawState = _TabStateForThemeControlState([item tabState]);
                  NSDebugMLLog(@"WinNSTabView", @"label: %@ tabFrame: %@ labelFrame: %@ intersection: %@",
                               [item label],
                               NSStringFromRect(tabFrame), NSStringFromRect(labelFrame),
                               NSStringFromRect(NSIntersectionRect(rect, tabFrame)));

                  // Avoid drawing a tab if the view part is NOT in the requested rectangle...
                  if (NSIntersectsRect(rect, tabFrame))
                    {
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
                    }
                  
                  // Update frame values...
                  iP.x += tabFrame.size.width;
                }
              
              // Draw the background fill for the rest of the tab rectangle area...
              if (iP.x < NSMaxX(bounds))
                {
                  NSRect tabFrame = NSMakeRect(iP.x, iP.y, NSMaxX(bounds) - iP.x, tabHeight);
                  
#if 0
                  [self drawThemeBackground: hTheme inRect: tabFrame part: TABP_BODY state: 0];
#else
                  // FIXME: Use super as Windows Theming may not match GNUstep GSTheme
                  // for processing that DOES NOT include WinUXTheme...
                  // Unfortunately this means we're mixing HDC and GNUstep drawing but
                  // unavoidable for now...
                  [self drawTabFillInRect: tabFrame forPart: GSTabBackgroundFill type: type];
#endif
                }
              
              // Save the current graphics context state...
              //DPSgrestore(ctxt);

              [self releaseTheme: hTheme];
            }
        }
    }
}

@end
