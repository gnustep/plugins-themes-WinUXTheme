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

#import <commdlg.h>
#import <windows.h>
#import "WinUXTheme.h"

// Flag to indicate that a folder was selected.
#define FOLDER_SELECTED 0xFFFFFFFF

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
  if(types == nil)
    {
      return L"All (*.*)\0*.*\0";
    }

  NSMutableSet *set = [NSMutableSet set];
  NSEnumerator *en = nil;
  id type = nil;
  NSDocumentController *dc = [NSDocumentController sharedDocumentController];
  NSString *filterString = @""; //"All (*.*)+*.*+";

  [set addObjectsFromArray: types];
  en = [set objectEnumerator];

  // build the string...
  while((type = [en nextObject]) != nil)
    {
      NSString *displayName = [dc displayNameForType: type];
      NSString *typeString = [NSString stringWithFormat: @"%@ (*.%@)+*.%@+",
				       displayName, type, type];
      filterString = [filterString stringByAppendingString: typeString];
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
      [filenames addObject: file];
    }
  else
    {
      while([file length] > 0)
	{
	  unichar *fn = filename_list + offset; // next filename...

	  file = [[NSString stringWithCharacters: fn
					 length: wcslen(fn)]
		   stringByStandardizingPath];
	  if([file length] > 0)
	    {
	      [filenames addObject: file];
	      offset += ([file length] + 1); // move to the next one
	    }
	}
    }

  return filenames;
}

@interface WinNSOpenPanel : NSOpenPanel
{
  unichar szFile[1024];
  OPENFILENAMEW ofn;
  NSArray *filenames;
  NSString *filename;
  NSString *directory;
}
@end

@interface WinNSSavePanel : NSSavePanel
{
  unichar szFile[1024];
  OPENFILENAMEW ofn;
  NSString *filename;
  NSString *directory;
}
@end


@implementation WinNSOpenPanel
- (id) init
{
  if((self = [super init]) != nil)
    {
      // Initial values for OPENFILENAMEW structure
      ofn.lStructSize = sizeof(ofn);
      ofn.lpstrFile = szFile;
      ofn.lpstrFile[0] = '\0';
      ofn.nMaxFile = 1024;
      ofn.lpstrFileTitle = NULL;
      ofn.nMaxFileTitle = 0;
      ofn.lpstrInitialDir = NULL;
      ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY |
	OFN_EXPLORER | OFN_ENABLEHOOK;
      ofn.lpfnHook = (void *)filepanel_dialog_hook;

      // initialize filenames array
      filenames = [[NSMutableArray alloc] initWithCapacity: 10];
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
- (NSString*) filename
{
  ASSIGN(_fullFileName, filename);
  return [super filename];
}

- (NSArray*) filenames
{
  return filenames;
}

- (int) runModalForDirectory: (NSString *)path
			file: (NSString *)name
		       types: (NSArray *)fileTypes
	    relativeToWindow: (NSWindow*)window
{
  BOOL flag = YES;
  int result = NSOKButton;
  NSDocumentController *dc = [NSDocumentController sharedDocumentController];
  NSString *fileType = [[dc fileExtensionsFromType: [dc defaultType]] objectAtIndex: 0];
  NSMutableSet *typeset = [NSMutableSet set];
  NSArray *types = nil; 

  [typeset addObjectsFromArray: fileTypes];
  types = [typeset allObjects];

  ofn.hwndOwner = (HWND)[window windowNumber];
  ofn.lpstrFilter = (unichar *)filter_string_from_types(types);
  ofn.nFilterIndex = [types indexOfObject: fileType] + 1;
  ofn.lpstrTitle = (unichar *)[[self title] cStringUsingEncoding: 
					      NSUnicodeStringEncoding];
  ofn.lCustData = (LPARAM)types;

  // Turn on multiple selection, if it's requested.
  if([self allowsMultipleSelection])
    {
      ofn.Flags |= OFN_ALLOWMULTISELECT;
    }

  flag = GetOpenFileNameW(&ofn);
  if(!flag && ofn.lCustData != FOLDER_SELECTED)
    {
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
	  ASSIGN(directory, 
		 [filename stringByDeletingLastPathComponent]);
	}
    }

  return result;
}

- (int) runModalForDirectory: (NSString *)path
			file: (NSString *)name
		       types: (NSArray *)fileTypes
{
  return [self runModalForDirectory: path
			       file: name
			      types: fileTypes
		   relativeToWindow: [NSApp keyWindow]];
}

- (int) runModalForDirectory: (NSString *)path
			file: (NSString *)name
	    relativeToWindow: (NSWindow*)window
{
  return [self runModalForDirectory: path
			       file: name
			      types: [self allowedFileTypes]];
}

- (int) runModalForDirectory: (NSString*)path 
			file: (NSString*)name
{
  return [self runModalForDirectory: path
			       file: name
			      types: [self allowedFileTypes]];
}
@end

@implementation WinNSSavePanel
- (id) init
{
  if((self = [super init]) != nil)
    {
      // Initial values for OPENFILENAMEW structure
      ofn.lStructSize = sizeof(ofn);
      ofn.lpstrFile = szFile;
      ofn.lpstrFile[0] = '\0';
      ofn.nMaxFile = 1024;
      ofn.lpstrFileTitle = NULL;
      ofn.nMaxFileTitle = 0;
      ofn.lpstrInitialDir = NULL;
      ofn.Flags = OFN_PATHMUSTEXIST | OFN_HIDEREADONLY |
	OFN_EXPLORER | OFN_ENABLEHOOK;
      ofn.lpfnHook = (void *)filepanel_dialog_hook;
    }
  return self;
}

/** <p>Returns the absolute path of the file selected by the user.</p>
*/
- (NSString*) filename
{
  ASSIGN(_fullFileName, filename);
  return [super filename];
}

- (int) runModalForDirectory: (NSString *)path
			file: (NSString *)name
		       types: (NSArray *)fileTypes
	    relativeToWindow: (NSWindow*)window
{
  BOOL flag = YES;
  int result = NSOKButton;
  NSDocumentController *dc = [NSDocumentController sharedDocumentController];
  NSString *fileType = [[dc fileExtensionsFromType: [dc defaultType]] objectAtIndex: 0];
  NSMutableSet *typeset = [NSMutableSet set];
  NSArray *types = nil; 

  [typeset addObjectsFromArray: fileTypes];
  types = [typeset allObjects];

  ofn.hwndOwner = (HWND)[window windowNumber];
  ofn.lpstrFilter = (unichar *)filter_string_from_types(types);
  ofn.nFilterIndex = [types indexOfObject: fileType] + 1;
  ofn.lpstrTitle = (unichar *)[[self title] cStringUsingEncoding: 
					      NSUnicodeStringEncoding];
  ofn.lCustData = (LPARAM)types;

  flag = GetSaveFileNameW(&ofn);
  if(!flag && ofn.lCustData != FOLDER_SELECTED)
    {
      result = NSCancelButton;
    }
  else
    {
      NSArray *files = [NSArray arrayWithArray:			     
				  array_from_filenames(ofn.lpstrFile,
						       ofn.nFileOffset)];
 
      if([files count] > 0)
	{
	  [super setRequiredFileType: [types objectAtIndex: ofn.nFilterIndex - 1]];
	  ASSIGN(filename, [files objectAtIndex: 0]);
	  ASSIGN(directory, [filename stringByDeletingLastPathComponent]);
	}
    }

  return result;
}

- (int) runModalForDirectory: (NSString *)path
			file: (NSString *)name
		       types: (NSArray *)fileTypes
{
  return [self runModalForDirectory: path
			       file: name
			      types: fileTypes
		   relativeToWindow: [NSApp keyWindow]];
}

- (int) runModalForDirectory: (NSString *)path
			file: (NSString *)name
	    relativeToWindow: (NSWindow*)window
{
  return [self runModalForDirectory: path
			       file: name
			      types: [self allowedFileTypes]];
}

- (int) runModalForDirectory: (NSString*)path 
			file: (NSString*)name
{
  return [self runModalForDirectory: path
			       file: name
			      types: [self allowedFileTypes]];
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

