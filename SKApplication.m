//
//  SKApplication.m
//  Skim
//
//  Created by Christiaan Hofman on 2/15/07.
/*
 This software is Copyright (c) 2007-2009
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

#import "SKApplication.h"
#import "SKPDFDocument.h"
#import "SKPDFView.h"
#import "NSString_SKExtensions.h"
#import "NSMenu_SKExtensions.h"
#import "NSResponder_SKExtensions.h"

NSString *SKApplicationStartsTerminatingNotification = @"SKApplicationStartsTerminatingNotification";

@interface NSApplication (NSApplicationPrivateDeclarations)
- (id)handleOpenScriptCommand:(NSScriptCommand *)command;
@end


@implementation SKApplication

- (BOOL)isUserAttentionDisabled {
    return userAttentionDisabled;
}

- (void)setUserAttentionDisabled:(BOOL)flag {
    userAttentionDisabled = flag;
}

- (NSInteger)requestUserAttention:(NSRequestUserAttentionType)requestType {
    return userAttentionDisabled ? 0 : [super requestUserAttention:requestType];
}

- (void)sendEvent:(NSEvent *)anEvent {
    if ([anEvent type] == NSScrollWheel && ([anEvent modifierFlags] & NSAlternateKeyMask)) {
        id target = [self targetForAction:@selector(magnifyWheel:)];
        if (target) {
            [target performSelector:@selector(magnifyWheel:) withObject:anEvent];
            return;
        }
    } else if ([anEvent type] == NSApplicationDefined && [anEvent subtype] == SKRemoteButtonEvent) {
        id target = [self targetForAction:@selector(remoteButtonPressed:)];
        if (target == nil) {
            target = [[NSDocumentController sharedDocumentController] currentDocument];
            if ([target respondsToSelector:@selector(remoteButtonPressed:)] == NO)
                target = nil;
        }
        if (target) {
            [target performSelector:@selector(remoteButtonPressed:) withObject:anEvent];
            return;
        }
    }
    [super sendEvent:anEvent];
}

- (IBAction)terminate:(id)sender {
    NSNotification *notification = [NSNotification notificationWithName:SKApplicationStartsTerminatingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    if ([[self delegate] respondsToSelector:@selector(applicationStartsTerminating:)])
        [[self delegate] applicationStartsTerminating:notification];
    [super terminate:sender];
}

- (void)reorganizeWindowsItem:(NSWindow *)aWindow {
    NSMenu *windowsMenu = [self windowsMenu];
    NSWindowController *windowController = [aWindow windowController];
    NSWindowController *mainWindowController = [[[[aWindow windowController] document] windowControllers] objectAtIndex:0];
    NSInteger numberOfItems = [windowsMenu numberOfItems];
    NSInteger itemIndex = [windowsMenu indexOfItemWithTarget:aWindow andAction:@selector(makeKeyAndOrderFront:)];
    
    if (itemIndex != -1) {
        NSMenuItem *item = [windowsMenu itemAtIndex:itemIndex];
        NSString *title = [item title];
        
        if ([windowController document] == nil) {
            NSInteger anIndex = numberOfItems;
            while (anIndex--) {
                NSMenuItem *anItem = [windowsMenu itemAtIndex:anIndex];
                if ([anItem isSeparatorItem] ||
                    [[[anItem target] windowController] document] != nil ||
                    [[anItem title] caseInsensitiveCompare:title] == NSOrderedAscending)
                    break;
            }
            ++anIndex;
            if (itemIndex != anIndex) {
                if (itemIndex < anIndex)
                    anIndex--;
                [item retain];
                [windowsMenu removeItem:item];
                [windowsMenu insertItem:item atIndex:anIndex];
                [item release];
            }
            if (anIndex > 0 && [[windowsMenu itemAtIndex:anIndex - 1] isSeparatorItem] == NO && [[[[windowsMenu itemAtIndex:anIndex - 1] target] windowController] document] != nil)
                [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:anIndex];
        } else if ([windowController isEqual:mainWindowController]) {
            NSMutableArray *subitems = [NSMutableArray array];
            NSMenuItem *anItem;
            NSInteger anIndex = numberOfItems;
            NSInteger nextIndex = numberOfItems;
            
            while (anIndex--) {
                anItem = [windowsMenu itemAtIndex:anIndex];
                if (anItem != item && [anItem action] == @selector(makeKeyAndOrderFront:)) {
                    id target = [anItem target];
                    NSWindowController *aMainWindowController = [[[[target windowController] document] windowControllers] objectAtIndex:0];
                    if ([aMainWindowController isEqual:mainWindowController]) {
                        [subitems insertObject:anItem atIndex:0];
                        [windowsMenu removeItemAtIndex:anIndex];
                        nextIndex--;
                        if (itemIndex > anIndex)
                            itemIndex--;
                    } else if ([aMainWindowController isEqual:[target windowController]]) {
                        NSComparisonResult comparison = [[anItem title] caseInsensitiveCompare:title];
                        if (comparison == NSOrderedDescending)
                            nextIndex = anIndex;
                    } else if ([[target windowController] document] == nil) {
                        nextIndex = anIndex;
                    }
                }
            }
            
            if (itemIndex != nextIndex) {
                [item retain];
                [windowsMenu removeItemAtIndex:itemIndex];
                if (nextIndex > itemIndex)
                    nextIndex--;
                if (itemIndex < [windowsMenu numberOfItems] && [[windowsMenu itemAtIndex:itemIndex] isSeparatorItem] && 
                    (itemIndex == [windowsMenu numberOfItems] - 1 || (itemIndex > 0 && [[windowsMenu itemAtIndex:itemIndex - 1] isSeparatorItem]))) {
                    [windowsMenu removeItemAtIndex:itemIndex];
                    if (nextIndex > itemIndex)
                        nextIndex--;
                }
                itemIndex = nextIndex++;
                [windowsMenu insertItem:item atIndex:itemIndex];
                [item release];
            }
            if (itemIndex > 1 && [[windowsMenu itemAtIndex:itemIndex - 1] isSeparatorItem] == NO) {
                [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:itemIndex];
                nextIndex++;
            }
            
            NSEnumerator *itemEnum = [subitems objectEnumerator];
            while (anItem = [itemEnum nextObject])
                [windowsMenu insertItem:anItem atIndex:nextIndex++];
            
            if (nextIndex < [windowsMenu numberOfItems] && [[windowsMenu itemAtIndex:nextIndex] isSeparatorItem] == NO)
                [windowsMenu insertItem:[NSMenuItem separatorItem] atIndex:nextIndex];
            
        } else {
            NSInteger mainIndex = [windowsMenu indexOfItemWithTarget:[mainWindowController window] andAction:@selector(makeKeyAndOrderFront:)];
            NSInteger anIndex = mainIndex;
            
            [item setIndentationLevel:1];
            
            if (anIndex >= 0) {
                while (++anIndex < numberOfItems) {
                    NSMenuItem *anItem = [windowsMenu itemAtIndex:anIndex];
                    if ([anItem isSeparatorItem] || [[anItem title] caseInsensitiveCompare:title] == NSOrderedDescending)
                        break;
                }
                if (itemIndex != anIndex - 1) {
                    if (itemIndex < anIndex)
                        anIndex--;
                    [item retain];
                    [windowsMenu removeItem:item];
                    [windowsMenu insertItem:item atIndex:anIndex];
                    [item release];
                }
            }
        }
    }
    
    // shouldn't be necessary, but just be sure. There have been reports of extra separators being inserted after a "swipe" event
    [[self windowsMenu] removeDoubleSeparators];
}

- (void)addWindowsItem:(NSWindow *)aWindow title:(NSString *)aString filename:(BOOL)isFilename {
    NSInteger itemIndex = [[self windowsMenu] indexOfItemWithTarget:aWindow andAction:@selector(makeKeyAndOrderFront:)];
    
    [super addWindowsItem:aWindow title:aString filename:isFilename];
    
    if (itemIndex == -1)
        [self reorganizeWindowsItem:aWindow];
}

- (void)changeWindowsItem:(NSWindow *)aWindow title:(NSString *)aString filename:(BOOL)isFilename {
    [super changeWindowsItem:aWindow title:aString filename:isFilename];
    
    [self reorganizeWindowsItem:aWindow];
}

- (void)removeWindowsItem:(NSWindow *)aWindow {
    [super removeWindowsItem:aWindow];
    
    [[self windowsMenu] removeDoubleSeparators];
}

#pragma mark Scripting support

- (NSArray *)allOrderedDocuments {
    return [super orderedDocuments];
}

- (NSArray *)orderedDocuments {
    NSMutableArray *orderedDocuments = [[[super orderedDocuments] mutableCopy] autorelease];
    NSInteger i = [orderedDocuments count];
    
    while (i--)
        if ([[orderedDocuments objectAtIndex:i] isKindOfClass:[SKPDFDocument class]] == NO)
            [orderedDocuments removeObjectAtIndex:i];
    
    return orderedDocuments;
}

@end
