//
//  BDSKApplication.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/26/06.
/*
 This software is Copyright (c) 2006,2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BDSKApplication.h"
#import "BDAlias.h"
#import "NSMenu_BDSKExtensions.h"

@interface NSWindow (BDSKApplication)
// these are implemented in AppKit as private methods
- (void)undo:(id)obj;
- (void)redo:(id)obj;
@end

@implementation BDSKApplication

- (IBAction)terminate:(id)sender {
    NSArray *fileNames = [[[NSDocumentController sharedDocumentController] documents] valueForKeyPath:@"@distinctUnionOfObjects.fileName"];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[fileNames count]];
    NSEnumerator *fEnum = [fileNames objectEnumerator];
    NSString *fileName;
    while(fileName = [fEnum nextObject]){
        NSData *data = [[BDAlias aliasWithPath:fileName] aliasData];
        if(data)
            [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:fileName, @"fileName", data, @"_BDAlias", nil]];
        else
            [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:fileName, @"fileName", nil]];
    }
    [[OFPreferenceWrapper sharedPreferenceWrapper] setObject:array forKey:BDSKLastOpenFileNamesKey];
    
    [super terminate:sender];
}

// workaround for AppKit bug in target determination for undo in sheets, compare 
// http://developer.apple.com/documentation/Cocoa/Conceptual/NSPersistentDocumentTutorial/08_CreationSheet/chapter_9_section_6.html 

- (id)targetForAction:(SEL)anAction to:(id)aTarget from:(id)sender{
    if (anAction == @selector(undo:) || anAction == @selector(redo:)) {
        NSWindow *keyWindow = [self keyWindow];
        if ([keyWindow isSheet] && [keyWindow respondsToSelector:anAction])
            return keyWindow;
    }
    return [super targetForAction:anAction to:aTarget from:sender];
}

- (BOOL)sendAction:(SEL)anAction to:(id)theTarget from:(id)sender{
    if (anAction == @selector(undo:) || anAction == @selector(redo:)) {
        NSWindow *keyWindow = [self keyWindow];
        if ([keyWindow isSheet] && [keyWindow respondsToSelector:anAction])
            return [super sendAction:anAction to:keyWindow from:sender];
    }
    return [super sendAction:anAction to:theTarget from:sender];
}

- (void)addWindowsItem:(NSWindow *)aWindow title:(NSString *)aString filename:(BOOL)isFilename {
    NSMenu *windowsMenu = [self windowsMenu];
    int itemIndex = [windowsMenu indexOfItemWithTarget:aWindow];
    
    [super addWindowsItem:aWindow title:aString filename:isFilename];
    
    if (itemIndex >= 0)
        return;
    
    NSWindowController *windowController = [aWindow windowController];
    NSWindowController *mainWindowController = [[[windowController document] windowControllers] objectAtIndex:0];
    int numberOfItems = [windowsMenu numberOfItems];
    
    itemIndex = [windowsMenu indexOfItemWithTarget:aWindow];
    
    if ([windowController document] == nil) {
        int index = numberOfItems;
        while (index-- && [[windowsMenu itemAtIndex:index] isSeparatorItem] == NO && 
               [[[[windowsMenu itemAtIndex:index] target] windowController] document] == nil) {}
        if (index >= 0) {
            if (itemIndex < index) {
                NSMenuItem *item = [[windowsMenu itemAtIndex:itemIndex] retain];
                [windowsMenu removeItem:item];
                [windowsMenu insertItem:item atIndex:index];
                [item release];
                index--;
            }
            if ([[windowsMenu itemAtIndex:index] isSeparatorItem] == NO)
                [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:index + 1];
        }
    } else if ([windowController isEqual:mainWindowController]) {
        if (itemIndex + 1 < numberOfItems && [[windowsMenu itemAtIndex:itemIndex + 1] isSeparatorItem] == NO)
            [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:itemIndex + 1];
        if ([[windowsMenu itemAtIndex:itemIndex - 1] isSeparatorItem] == NO)
            [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:itemIndex];
    } else {
        int index = [windowsMenu indexOfItemWithTarget:[mainWindowController window]];
        NSMenuItem *item = [windowsMenu itemAtIndex:itemIndex];
        
        [item setIndentationLevel:1];
        
        if (index >= 0) {
            while (++index < numberOfItems && [[windowsMenu itemAtIndex:index] isSeparatorItem] == NO) {}
            [item retain];
            [windowsMenu removeItem:item];
            [windowsMenu insertItem:item atIndex:itemIndex < index ? --index : index];
            [item release];
        }
    }
}

- (void)changeWindowsItem:(NSWindow *)aWindow title:(NSString *)aString filename:(BOOL)isFilename {
    [super changeWindowsItem:aWindow title:aString filename:isFilename];
    
    NSWindowController *windowController = [aWindow windowController];
    NSWindowController *mainWindowController = [[[windowController document] windowControllers] objectAtIndex:0];
    int itemIndex = [[self windowsMenu] indexOfItemWithTarget:aWindow];
    NSMenuItem *item = itemIndex >= 0 ? [[self windowsMenu] itemAtIndex:itemIndex] : nil;
    
    if ([windowController document] && [windowController isEqual:mainWindowController] == NO)
        [item setIndentationLevel:1];
}

- (void)removeWindowsItem:(NSWindow *)aWindow {
    int index = [[self windowsMenu] indexOfItemWithTarget:aWindow];
    [super removeWindowsItem:aWindow];
    if ((index >= 0) && (index < [[self windowsMenu] numberOfItems]) && 
        [[[self windowsMenu] itemAtIndex:index - 1] isSeparatorItem])
        [[self windowsMenu] removeItemAtIndex:index - 1];
}

@end
