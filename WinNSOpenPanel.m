/* WINUXTheme A native Windows XP theme for GNUstep
   
   Native open save panel support for GNUstep.
   
   Copyright (C) 2009 Free Software Foundation, Inc.

   Written by: Gregory Casamento <greg.casamento@gmail.com>
   Date: Mar 2010

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

#if defined ( __MINGW64__ ) || defined ( _MSC_VER )
#define interface struct
#endif
#import <shlobj.h>
#if defined ( __MINGW64__ ) || defined ( _MSC_VER )
#undef interface
#endif

#import <commdlg.h>
#import <windows.h>
#import "WinUXTheme.h"

@interface NSDocument (WinUXTheme)
- (IBAction) changeSaveType: (id)sender;
@end

// Flag to indicate that a folder was selected.
#define FOLDER_SELECTED 0xFFFFFFFF
#define FILE_BUFFER_SIZE 9128
/**
 * Callback function to handle events from the save/open dialog.
 */
UINT_PTR CALLBACK filepanel_dialog_hook(HWND win,
					UINT msg,
					WPARAM wp,
					LPARAM lp)
{
  static BOOL didFolderChange;
  
  if(msg == WM_INITDIALOG)
    { 
      didFolderChange = NO;
      return (UINT_PTR)TRUE;
    }
  else if(msg == WM_NOTIFY)
    {
      OFNOTIFYW *ofnw = (void *)lp;
      
      if(ofnw->hdr.code == CDN_FOLDERCHANGE)
	{
	  if(didFolderChange == YES)
	    {
	      unichar  foldername[MAX_PATH+1]; // maximum path len + NULL
	      NSArray *fileTypes = nil; 
	      int      len = 0;
	      
	      /*
	       * Get the array of types we can select
	       */
	      fileTypes = (NSArray *)(ofnw->lpOFN->lCustData);
	      len = SendMessage(GetParent(win),
				CDM_GETFOLDERPATH,MAX_PATH,
				(LPARAM)foldername)-1;
	      if(len > 0)
		{
		  NSString *filename = 
		    [NSString stringWithCharacters: foldername
					    length: len];
		  NSString *ext = [filename pathExtension];
		  if([fileTypes containsObject: ext])
		    {
		      // Indicate that a folder was selected and
		      // set it's name in the file section.
		      ofnw->lpOFN->lCustData = FOLDER_SELECTED;
		      ofnw->lpOFN->nFileOffset = 0; // Reset the fileOffset to the begining
		      wcscpy(ofnw->lpOFN->lpstrFile, foldername);
		      
		      // If we're opening a folder, then close and
		      // return.
		      PostMessage(GetParent(win),
				  WM_SYSCOMMAND,
				  SC_CLOSE,
				  0);
		    }
		}	      
	    }	  
	  didFolderChange = YES;
	}
      return (UINT_PTR)TRUE;
    } 
  return (UINT_PTR)FALSE;
}

/**
 * Build a filter string out of an array of types.
 */
unichar *filter_string_from_types(NSArray *types)
{
  if(types == nil || [types count] == 0 ||
     ([types count] == 1 && [[types objectAtIndex: 0] isEqualToString: @"All"]))
    {
      return L"All (*.*)\0*.*\0";
    }
  
  int x = 0;
  id type = nil;
  NSArray *typeExts = nil;
  NSEnumerator *en = nil;
  NSString *str = nil;
  NSDocumentController *dc = [NSDocumentController sharedDocumentController];
  NSMutableString *filterString = [NSMutableString string];
  NSMutableArray *names = [NSMutableArray array];
  NSMutableArray *exts = [NSMutableArray array];
  
  // Add one entry for all types (only for Open panels).
  if ([[types objectAtIndex: 0] isEqualToString: @"All"])
    {
      NSMutableArray *data = [NSMutableArray array];
      
      for (x = 1; x < [types count]; x++)
	{
	  if (![data containsObject: [types objectAtIndex: x]])
	    {
	      [data addObject: [types objectAtIndex: x]];
	    }
	}    
      [names addObject: @"All"];
      [exts addObject: data];
    }
  
  // Get the names and the corresponding extensions
  en = [types objectEnumerator];
  while ((type = [en nextObject]))
    {
      if ([type isEqualToString: @"All"])
	continue;
      
      str = [dc typeFromFileExtension: type];
      if (str != nil)
	{
	  if (![names containsObject: [dc displayNameForType: str]])
	    {
	      NSMutableArray *data = [NSMutableArray array];
	      
	      typeExts = [dc fileExtensionsFromType: str];
	      
	      for (x = 0; x < [typeExts count]; x++)
		{
		  if (![data containsObject: [typeExts objectAtIndex: x]])
		    {
		      [data addObject: [typeExts objectAtIndex: x]];
		    }
		}
	      
	      [names addObject: [dc displayNameForType: str]];
	      [exts addObject: data];
	    }
	}
      else
	{
	  [names addObject: type];
	  [exts addObject: [NSArray arrayWithObject: type]];
	}
    }
  
  // Build the string, adding one entry for each type
  x = 0;
  en = [names objectEnumerator];
  while((type = [en nextObject]) != nil)
    { 
      [filterString appendFormat:@"%@ (*.%@)+*.%@+",
                    type,
	    [[exts objectAtIndex: x] componentsJoinedByString: @"; *."],
	    [[exts objectAtIndex: x] componentsJoinedByString: @";*."]];
      
      x++;
    }
  
  // Add the nulls...
  unichar *fs = (unichar *)[filterString cStringUsingEncoding: 
					   NSUnicodeStringEncoding];
  int i = 0;
  for (i = 0; i < [filterString length]; i++)
    {
      char c = fs[i];
      if(c == '+')
	{
	  fs[i] = '\0';
	}
    }
  
  return fs;
}

/**
 * Create an array of filenames from the \0 delimited 
 * string returned by windows.
 */
NSMutableArray *array_from_filenames(unichar *filename_list,
				     unsigned int initial_offset)
{
  unsigned int len = wcslen(filename_list);
  unsigned int offset = initial_offset;
  NSMutableArray *filenames = [NSMutableArray arrayWithCapacity: 10];
  NSString *file = [NSString stringWithCharacters: filename_list
					   length: len];
  
  if(offset < [file length])
    {
      file = [file stringByStandardizingPath];
      file = [file mutableCopy];
      [(NSMutableString *)file replaceOccurrencesOfString:@"\\" 
					       withString:@"/" options: 0 range:NSMakeRange(0, [file length])];
      [filenames addObject: file];
    }
  else
    {
      while([file length] > 0)
	{
	  unichar *fn = filename_list + offset; // next filename...
	  
	  file = [[NSString stringWithCharacters: fn length: wcslen(fn)]
		   stringByStandardizingPath];
	  file = [file mutableCopy];
	  [(NSMutableString *)file replaceOccurrencesOfString:@"\\" 
						   withString:@"/" options: 0 range:NSMakeRange(0, [file length])];
	  if([file length] > 0)
	    {
	      [filenames addObject: file];
	      offset += ([file length] + 1); // move to the next one
	    }
	}
    }
  
  return filenames;
}

static void _purgeEvents()
{
  // Purge any events in the event queue. We allow a small time for incoming events
  // to arrive from the backend.
  NSDate *nearFuture = [NSDate dateWithTimeIntervalSinceNow:0.1];
  while (([NSApp nextEventMatchingMask: NSAnyEventMask
			     untilDate: nearFuture
				inMode: NSDefaultRunLoopMode
			       dequeue: YES]) != nil)
    ; // do nothing, just discard events
}

unsigned long long unilen(unichar *chars)
{
  unsigned long long length = 0;
  if(NULL == chars) return length;
  
  while(NULL != chars[length])
    length++;
  
  return length;
}

@interface WinNSOpenPanel : NSOpenPanel
{
  unichar szFile[FILE_BUFFER_SIZE];
  OPENFILENAMEW ofn;
  BROWSEINFO folderBrowser;
  NSArray *filenames;
  NSString *filename;
}
@end

@interface WinNSSavePanel : NSSavePanel
{
  unichar szFile[FILE_BUFFER_SIZE];
  OPENFILENAMEW ofn;
  NSString *filename;
}
@end


@implementation WinNSOpenPanel
- (id) init
{
  if((self = [super init]) != nil)
    {
      // Initial values for OPENFILENAMEW structure
      memset(&ofn, 0, sizeof(ofn));
      ofn.lStructSize = sizeof(ofn);
      ofn.lpstrFile = szFile;
      ofn.lpstrFile[0] = '\0';
      ofn.nMaxFile = FILE_BUFFER_SIZE;
      ofn.lpstrFileTitle = NULL;
      ofn.nMaxFileTitle = 0;
      ofn.lpstrInitialDir = NULL;
      ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY |
	OFN_EXPLORER | OFN_ENABLEHOOK;
      ofn.lpfnHook = (void *)filepanel_dialog_hook;
      
      // initialize filenames array
      filenames = [[NSMutableArray alloc] initWithCapacity: 10];
      
      // Initialize folderBroswers structure
      folderBrowser.pidlRoot = NULL; // Starting root - Use Desktop
      folderBrowser.pszDisplayName = (LPTSTR)szFile;
      folderBrowser.lpszTitle = "";
      folderBrowser.ulFlags = BIF_EDITBOX | BIF_NEWDIALOGSTYLE;
      folderBrowser.lpfn = NULL;
      folderBrowser.lParam = 0;
    }
  return self;
}

- (void) dealloc
{
  RELEASE(filenames);
  [super dealloc];
}

/** <p>Returns the absolute path of the file selected by the user.</p>
 */
#ifndef _MSC_VER
- (NSString*) filename
{
  ASSIGN(_fullFileName, filename);
  return [super filename];
}
#endif

- (NSArray*) filenames
{
  return filenames;
}

- (NSInteger) runModalForDirectory: (NSString *)path
                        file: (NSString *)name
                       types: (NSArray *)fileTypes
            relativeToWindow: (NSWindow*)window
{
  BOOL flag = YES;
  int result = NSOKButton;
  
  NSArray *types = nil;
  
  // Arbitrary Folder Browser (not with explicit extension) is a different call in Windows Land
  if ([self canChooseDirectories] && ![self canChooseFiles]) 
    {
      LPITEMIDLIST pidl;
      folderBrowser.hwndOwner = (HWND)[window windowNumber];
      
      pidl = SHBrowseForFolder(&folderBrowser);
      if(pidl == NULL || !SHGetPathFromIDList(pidl,(LPSTR)szFile))
	{
	  result = NSCancelButton;
	}
      else
	{
	  NSString *file = [[NSString stringWithCString:(const char *) szFile encoding: NSUTF8StringEncoding]
			     stringByStandardizingPath];
	  file = [file stringByReplacingOccurrencesOfString:@"\\" withString:@"/"]; 
	  ASSIGN(filenames, [NSArray arrayWithObject:file]);
	  ASSIGN(filename, file);
	  [self setDirectory: filename];
	}
      
      _purgeEvents(); // remove any events that came through while panel was running
      return result;
    }
  
  if ([fileTypes count] > 1)
    {
      types = [NSArray arrayWithObject: @"All"];
      types = [types arrayByAddingObjectsFromArray: fileTypes];
    }
  else
    types = fileTypes;
  
  ofn.hwndOwner = (HWND)[window windowNumber];
  ofn.lpstrFilter = (unichar *)filter_string_from_types(types);
  ofn.nFilterIndex = 1;
  
  ofn.lpstrTitle = (unichar *)[[self title] cStringUsingEncoding: NSUnicodeStringEncoding];
  if ([name length])
    {
      NSString *file = [name lastPathComponent];
      wcscpy(szFile, (const unichar *) [file cStringUsingEncoding: NSUnicodeStringEncoding]);
    }
  else 
    {
      szFile[0] = '\0';
    }
  
  if ([path length]) 
    { // Convert to Windows
      path = [path stringByReplacingOccurrencesOfString:@"/" withString:@"\\"];
      ofn.lpstrInitialDir = (unichar *)[path cStringUsingEncoding: NSUnicodeStringEncoding];
    }
  else {
    ofn.lpstrInitialDir = NULL;
  }
  ofn.lCustData = (LPARAM)types;
  
  // Turn on multiple selection, if it's requested.
  if([self allowsMultipleSelection]) 
    {
      ofn.Flags |= OFN_ALLOWMULTISELECT;
    }
  else 
    {
      ofn.Flags &= ~OFN_ALLOWMULTISELECT;
    }
  
  flag = GetOpenFileNameW(&ofn);
  
  if(!flag && ofn.lCustData != FOLDER_SELECTED)
    {
      DWORD errorCode = CommDlgExtendedError();
      if (errorCode)
        {
          NSLog(@"%s:open panel error: %d\n", __PRETTY_FUNCTION__, errorCode);
        }
      result = NSCancelButton;
    }
  else
    {
      NSArray *files = [NSArray arrayWithArray:			     
				  array_from_filenames(ofn.lpstrFile,
						       ofn.nFileOffset)];
      
      if([files count] > 0)
	{
	  ASSIGN(filenames, files);
	  ASSIGN(filename, [files objectAtIndex: 0]);
	  [self setDirectory: [filename stringByDeletingLastPathComponent]];
	}
    }
  
  _purgeEvents(); // remove any events that came through while panel was running
  return result;
}

- (NSInteger) runModalForDirectory: (NSString *)path
			file: (NSString *)name
		       types: (NSArray *)fileTypes
{
  return [self runModalForDirectory: path
			       file: name
			      types: fileTypes
		   relativeToWindow: [NSApp keyWindow]];
}

- (NSInteger) runModalForDirectory: (NSString *)path
			file: (NSString *)name
	    relativeToWindow: (NSWindow*)window
{
  return [self runModalForDirectory: path
			       file: name
			      types: [self allowedFileTypes]];
}

- (NSInteger) runModalForDirectory: (NSString*)path 
			file: (NSString*)name
{
  return [self runModalForDirectory: path
			       file: name
			      types: [self allowedFileTypes]];
}

// This won't run as a true sheet but it will run the Native Windows Open Panel
// and then call the appropriate didEndSelector on finish
- (void)beginSheetForDirectory:(NSString *)path 
	file:(NSString *) name 
	types:(NSArray *)fileTypes 
	modalForWindow:(NSWindow *)docWindow 
	modalDelegate:(id)modalDelegate 
	didEndSelector:(SEL)didEndSelector 
	contextInfo:(void *)contextInfo 
{
  int ret = [self runModalForDirectory: path file: name types: fileTypes relativeToWindow: docWindow]; 
  if (modalDelegate && [modalDelegate respondsToSelector: didEndSelector])
    {
      void (*didEnd)(id, SEL, id, int, void*);
      didEnd = (void (*)(id, SEL, id, int, void*))[modalDelegate methodForSelector: didEndSelector];
      didEnd(modalDelegate, didEndSelector, self, ret, contextInfo);
    }
}

@end

@implementation WinNSSavePanel
- (id) init
{
  if((self = [super init]) != nil)
    {
      // Initial values for OPENFILENAMEW structure
      memset(&ofn, 0, sizeof(ofn));
      ofn.lStructSize = sizeof(ofn);
      ofn.lpstrFile = szFile;
      ofn.lpstrFile[0] = '\0';
      ofn.nMaxFile = FILE_BUFFER_SIZE;
      ofn.lpstrFileTitle = NULL;
      ofn.nMaxFileTitle = 0;
      ofn.lpstrInitialDir = NULL;
      ofn.Flags = OFN_PATHMUSTEXIST | OFN_HIDEREADONLY |
        OFN_EXPLORER | OFN_ENABLEHOOK;
      ofn.lpfnHook = (void *)filepanel_dialog_hook;
      ofn.lpstrCustomFilter = NULL;
    }
  return self;
}

/** <p>Returns the absolute path of the file selected by the user.</p>
 */
#ifndef _MSC_VER
- (NSString*) filename
{
  ASSIGN(_fullFileName, filename);
  return [super filename];
}
#endif

- (NSString *) nameFieldStringValue
{
  return [[NSString stringWithCharacters: szFile
				  length: unilen(szFile)] lastPathComponent];
}

- (void) setNameFieldStringValue: (NSString*)value
{
  wcscpy(szFile, (const unichar *)[value cStringUsingEncoding: NSUnicodeStringEncoding]);
}

- (int) runModalForDirectory: (NSString *)path
			file: (NSString *)name
		       types: (NSArray *)fileTypes
	    relativeToWindow: (NSWindow*)window
{
  NSUInteger i, j;
  BOOL flag = YES;
  int result = NSOKButton;
  NSDocumentController *dc = [NSDocumentController sharedDocumentController];
  NSDocument *doc = nil;
  NSArray *types = nil, *names = nil, *exts = nil;
  NSMutableArray *tps= [NSMutableArray array];

  // Get a valid document
  if ([dc currentDocument] != nil)
    {
      doc  = [dc currentDocument];
    }
  else if ([[dc documents] count])
    {
      doc = [[dc documents] objectAtIndex: 0];
    }

  // Get all writable types, not only the current type. For the case when
  // the user wants change the format of the file
  if ([[self title] isEqualToString: _(@"Save As")])
    {
      names = [doc writableTypesForSaveOperation: NSSaveAsOperation];
    }
  else if ([[self title] isEqualToString: _(@"Save To")])
    {
      names = [doc writableTypesForSaveOperation: NSSaveToOperation];
    }
  else
    {
      names = [doc writableTypesForSaveOperation: NSSaveOperation];
    }
    
  // Check for presence of fileTypes and add...
  if ([fileTypes count] == 0)
    {
      // fileTypes not specified, add from current documents allowed types
      for (i = 0; i < [names count]; i++)
        {
          exts = [dc fileExtensionsFromType: [names objectAtIndex: i]];
      
          for (j = 0; j < [exts count]; j++)
            {
              if (![tps containsObject: [exts objectAtIndex: j]])
                {
                  [tps addObject: [exts objectAtIndex: j]];
                }
            }
        }
    } 
  else 
    {
      for (i = 0; i < [fileTypes count]; ++i)
        {
          if ([tps indexOfObject:[fileTypes objectAtIndex:i]] == NSNotFound)
            [tps addObject:[fileTypes objectAtIndex:i]];
        }
    }
  types = [NSArray arrayWithArray: tps];


  ofn.hwndOwner = (HWND)[window windowNumber];
  
  ofn.lpstrFilter = (unichar *)filter_string_from_types(types);
  
  // Select the current type - '0' indicates use first one defined in 'lpstrFilter' list...
  // This will be the 'All' case ONLY if types has no entries...
  ofn.nFilterIndex = 0;
  
  // Setup the initial title...
  ofn.lpstrTitle = (unichar *)[[self title] cStringUsingEncoding: NSUnicodeStringEncoding];
  if ([name length]) {
    NSString *file = [name lastPathComponent];
    wcscpy(szFile, (const unichar *)[file cStringUsingEncoding: NSUnicodeStringEncoding]);
  }
  else {
    szFile[0] = '\0';
  }
	
  if ([path length]) {
	path = [path stringByReplacingOccurrencesOfString:@"/" withString:@"\\"];
	ofn.lpstrInitialDir = (unichar *)[path cStringUsingEncoding: NSUnicodeStringEncoding];
  }
  else {
	ofn.lpstrInitialDir = NULL;
  }
  
  ofn.lCustData = (LPARAM)types;

  flag = GetSaveFileNameW(&ofn);
  if(!flag && ofn.lCustData != FOLDER_SELECTED)
    {
      DWORD errorCode = CommDlgExtendedError();
      if (errorCode)
      {
        NSLog(@"%s:save panel error: %d\n", __PRETTY_FUNCTION__, errorCode);
      }
      result = NSCancelButton;
    }
  else
    {
      NSArray *files = [NSArray arrayWithArray:			     
				  array_from_filenames(ofn.lpstrFile,
						       ofn.nFileOffset)];
      NSPopUpButton *popup = [NSPopUpButton new];

      [popup addItemWithTitle: @"None"];
      if ([types count] > 0)
	{
	  [[popup itemAtIndex: 0] setRepresentedObject:
			     [dc typeFromFileExtension:
				   [types objectAtIndex: ofn.nFilterIndex - 1]]];
	}
      [popup selectItemAtIndex: 0];
      [doc changeSaveType: [popup autorelease]];
 
      if([files count] > 0)
	{
    if ([types count] > 0)
      [super setRequiredFileType: [types objectAtIndex: ofn.nFilterIndex - 1]];
	  ASSIGN(filename, [files objectAtIndex: 0]);
	  [self setDirectory: [filename stringByDeletingLastPathComponent]];
	}
    }
  _purgeEvents(); // remove any events that came through while panel was running
  return result;
}

- (NSInteger) runModalForDirectory: (NSString *)path
			file: (NSString *)name
		       types: (NSArray *)fileTypes
{
  return [self runModalForDirectory: path
			       file: name
			      types: fileTypes
		   relativeToWindow: [NSApp keyWindow]];
}

- (NSInteger) runModalForDirectory: (NSString *)path
			file: (NSString *)name
	    relativeToWindow: (NSWindow*)window
{
  return [self runModalForDirectory: path
			       file: name
			      types: [self allowedFileTypes]];
}

- (NSInteger) runModalForDirectory: (NSString*)path 
			file: (NSString*)name
{
  return [self runModalForDirectory: path
			       file: name
			      types: [self allowedFileTypes]];
}

// This won't run as a  true sheet but it will run the Native Windows Save Panel
// and then call the appropriate didEndSelector on finish
- (void)beginSheetForDirectory:(NSString *)path 
	file:(NSString *)name
	modalForWindow:(NSWindow *)docWindow 
	modalDelegate:(id)modalDelegate 
	didEndSelector:(SEL)didEndSelector 
	contextInfo:(void *)contextInfo {
	int ret = [self runModalForDirectory: path file: name relativeToWindow: docWindow];

	if (modalDelegate && [modalDelegate respondsToSelector: didEndSelector]) {
      void (*didEnd)(id, SEL, id, int, void*);
      didEnd = (void (*)(id, SEL, id, int, void*))[modalDelegate methodForSelector: didEndSelector];
      didEnd(modalDelegate, didEndSelector, self, ret, contextInfo);
    }
}

@end

@implementation WinUXTheme (OpenSavePanels)
- (Class) openPanelClass
{
  return [WinNSOpenPanel class];
}

- (Class) savePanelClass
{
  return [WinNSSavePanel class];
}
@end

