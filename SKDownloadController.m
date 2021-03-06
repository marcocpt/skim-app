//
//  SKDownloadController.m
//  Skim
//
//  Created by Christiaan Hofman on 8/11/07.
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

#import "SKDownloadController.h"
#import "SKDownload.h"
#import "SKProgressCell.h"
#import "NSURL_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKTableView.h"
#import "SKTypeSelectHelper.h"
#import "NSString_SKExtensions.h"
#import "NSMenu_SKExtensions.h"

#define PROGRESS_COLUMN 1
#define RESUME_COLUMN   2
#define CANCEL_COLUMN   3

#define RESUME_COLUMNID @"resume"
#define CANCEL_COLUMNID @"cancel"

#define SKDownloadsWindowFrameAutosaveName @"SKDownloadsWindow"

#define DOWNLOADS_KEY @"downloads"

static char SKDownloadPropertiesObservationContext;

@interface SKDownloadController (SKPrivate)
- (void)startObservingDownloads:(NSArray *)newDownloads;
- (void)endObservingDownloads:(NSArray *)oldDownloads;
@end

@implementation SKDownloadController

static SKDownloadController *sharedDownloadController = nil;

+ (id)sharedDownloadController {
    if (sharedDownloadController == nil)
        [[self alloc] init];
    return sharedDownloadController;
}

+ (id)allocWithZone:(NSZone *)zone {
    return sharedDownloadController ?: [super allocWithZone:zone];
}

- (id)init {
    if (sharedDownloadController == nil && (sharedDownloadController = self = [super initWithWindowNibName:@"DownloadsWindow"])) {
        downloads = [[NSMutableArray alloc] init];
    }
    return sharedDownloadController;
}

- (void)dealloc {
    [self endObservingDownloads:downloads];
    [downloads release];
    [super dealloc];
}

- (id)retain { return self; }

- (id)autorelease { return self; }

- (void)release {}

- (NSUInteger)retainCount { return NSUIntegerMax; }

- (void)windowDidLoad {
    [self setWindowFrameAutosaveName:SKDownloadsWindowFrameAutosaveName];
    
    [tableView setTypeSelectHelper:[SKTypeSelectHelper typeSelectHelper]];
    
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType, SKWeblocFilePboardType, NSStringPboardType, nil]];
}

- (SKDownload *)addDownloadForURL:(NSURL *)aURL {
    SKDownload *download = nil;
    if (aURL) {
        download = [[[SKDownload alloc] initWithURL:aURL delegate:self] autorelease];
        NSInteger row = [self countOfDownloads];
        [[self mutableArrayValueForKey:DOWNLOADS_KEY] addObject:download];
        [download start];
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [tableView scrollRowToVisible:row];
    }
    return download;
}

#pragma mark Accessors

- (NSArray *)downloads {
    return [[downloads copy] autorelease];
}

- (NSUInteger)countOfDownloads {
    return [downloads count];
}

- (SKDownload *)objectInDownloadsAtIndex:(NSUInteger)anIndex {
    return [downloads objectAtIndex:anIndex];
}

- (void)insertObject:(SKDownload *)download inDownloadsAtIndex:(NSUInteger)anIndex {
    [downloads insertObject:download atIndex:anIndex];
    [self startObservingDownloads:[NSArray arrayWithObject:download]];
    [downloads makeObjectsPerformSelector:@selector(removeProgressIndicatorFromSuperview)];
    [tableView setNeedsDisplayInRect:[tableView rectOfRow:PROGRESS_COLUMN]];
}

- (void)removeObjectFromDownloadsAtIndex:(NSUInteger)anIndex {
    SKDownload *download = [downloads objectAtIndex:anIndex];
    [self endObservingDownloads:[NSArray arrayWithObject:download]];
    [download setDelegate:nil];
    [download cancel];
    [downloads removeObjectAtIndex:anIndex];
    [downloads makeObjectsPerformSelector:@selector(removeProgressIndicatorFromSuperview)];
    [tableView setNeedsDisplayInRect:[tableView rectOfRow:PROGRESS_COLUMN]];
}

#pragma mark Actions

- (IBAction)clearDownloads:(id)sender {
    NSInteger i = [self countOfDownloads];
    
    while (i-- > 0) {
        SKDownload *download = [self objectInDownloadsAtIndex:i];
        if ([download status] != SKDownloadStatusDownloading)
            [self removeObjectFromDownloadsAtIndex:i];
    }
}

- (IBAction)cancelDownload:(id)sender {
    SKDownload *download = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : nil;
    
    if (download == nil) {
        NSInteger row = [tableView clickedRow];
        if (row != -1)
            download = [self objectInDownloadsAtIndex:row];
    }
    if (download && [download status] == SKDownloadStatusDownloading)
        [download cancel];
}

- (IBAction)resumeDownload:(id)sender {
    SKDownload *download = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : nil;
    
    if (download == nil) {
        NSInteger row = [tableView clickedRow];
        if (row != -1)
            download = [self objectInDownloadsAtIndex:row];
    }
    if (download && [download status] == SKDownloadStatusCanceled)
        [download resume];
}

- (IBAction)removeDownload:(id)sender {
    SKDownload *download = [sender respondsToSelector:@selector(representedObject)] ? [sender representedObject] : nil;
    
    if (download == nil) {
        NSInteger row = [tableView clickedRow];
        if (row != -1)
            download = [self objectInDownloadsAtIndex:row];
    }
    
    if (download)
        [[self mutableArrayValueForKey:DOWNLOADS_KEY] removeObject:download];
}

- (IBAction)showDownloadPreferences:(id)sender {
    [NSApp beginSheet:preferencesSheet modalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)dismissDownloadsPreferences:(id)sender {
    [NSApp endSheet:preferencesSheet returnCode:[sender tag]];
    [preferencesSheet orderOut:self];
}

- (void)openDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
    } else {
        NSURL *fileURL = [NSURL fileURLWithPath:[download filePath]];
        NSError *error;
        if (nil == [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:YES error:&error])
            [NSApp presentError:error];
    }
}

- (void)revealDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
    } else {
        [[NSWorkspace sharedWorkspace] selectFile:[download filePath] inFileViewerRootedAtPath:nil];
    }
}

- (void)trashDownloadedFile:(id)sender {
    SKDownload *download = [sender representedObject];
    
    if (download && [download status] != SKDownloadStatusFinished) {
        NSBeep();
    } else {
        NSString *filePath = [download filePath];
        NSString *folderPath = [filePath stringByDeletingLastPathComponent];
        NSString *fileName = [filePath lastPathComponent];
        NSInteger tag = 0;
        
        [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:folderPath destination:nil files:[NSArray arrayWithObjects:fileName, nil] tag:&tag];
    }
}

#pragma mark SKDownloadDelegate

- (void)downloadDidEnd:(SKDownload *)download {
    if ([download status] == SKDownloadStatusFinished) {
        NSURL *URL = [NSURL fileURLWithPath:[download filePath]];
        NSError *error = nil;
        id document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:URL display:YES error:&error];
        if (document == nil)
            [NSApp presentError:error];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoRemoveFinishedDownloadsKey]) {
            [[download retain] autorelease];
            [[self mutableArrayValueForKey:DOWNLOADS_KEY] removeObject:download];
            // for the document to note that the file has been deleted
            [document setFileURL:[NSURL fileURLWithPath:[download filePath]]];
            if ([self countOfDownloads] == 0 && [[NSUserDefaults standardUserDefaults] boolForKey:SKAutoCloseDownloadsWindowKey])
                [[self window] close];
        }
    }
}

#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv { return 0; }

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row { return nil; }

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSURLPboardType, SKWeblocFilePboardType, NSStringPboardType, nil]];
    
    if (type) {
        [tv setDropRow:-1 dropOperation:NSTableViewDropOn];
        return NSDragOperationEvery;
    }
    return NSDragOperationNone;
}
       
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSURL *theURL = [NSURL URLFromPasteboardAnyType:pboard];
    
    if ([theURL isFileURL]) {
        if ([[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:theURL display:YES error:NULL])
            return YES;
    } else if (theURL) {
        [self addDownloadForURL:theURL];
        return YES;
    }
    return NO;
}

#pragma mark NSTableViewDelegate

- (void)tableView:(NSTableView *)tv willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *identifier = [tableColumn identifier];
    SKDownload *download = [self objectInDownloadsAtIndex:row];
    
    if ([identifier isEqualToString:CANCEL_COLUMNID]) {
        if ([download canCancel]) {
            [cell setImage:[NSImage imageNamed:@"Cancel"]];
            [cell setAction:@selector(cancelDownload:)];
            [cell setTarget:self];
        } else if ([download canRemove]) {
            [cell setImage:[NSImage imageNamed:@"Delete"]];
            [cell setAction:@selector(removeDownload:)];
            [cell setTarget:self];
        } else {
            [cell setImage:nil];
            [cell setAction:NULL];
            [cell setTarget:nil];
        }
    } else if ([identifier isEqualToString:RESUME_COLUMNID]) {
        if ([download canResume]) {
            [cell setImage:[NSImage imageNamed:@"Resume"]];
            [cell setAction:@selector(resumeDownload:)];
            [cell setTarget:self];
        } else {
            [cell setImage:nil];
            [cell setAction:NULL];
            [cell setTarget:nil];
        }
    }
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
    NSString *toolTip = nil;
    if ([[tableColumn identifier] isEqualToString:CANCEL_COLUMNID]) {
        if ([[self objectInDownloadsAtIndex:row] canCancel])
            toolTip = NSLocalizedString(@"Cancel download", @"Tool tip message");
        else if ([[self objectInDownloadsAtIndex:row] canRemove])
            toolTip = NSLocalizedString(@"Remove download", @"Tool tip message");
    } else if ([[tableColumn identifier] isEqualToString:RESUME_COLUMNID]) {
        if ([[self objectInDownloadsAtIndex:row] canResume])
            toolTip = NSLocalizedString(@"Resume download", @"Tool tip message");
    }
    return toolTip;
}

- (void)tableView:(NSTableView *)aTableView deleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    NSUInteger row = [rowIndexes firstIndex];
    SKDownload *download = [self objectInDownloadsAtIndex:row];
    
    if ([download canCancel])
        [download cancel];
    else if ([download canRemove])
        [self removeObjectFromDownloadsAtIndex:row];
}

- (BOOL)tableView:(NSTableView *)aTableView canDeleteRowsWithIndexes:(NSIndexSet *)rowIndexes {
    return YES;
}

- (void)tableViewPaste:(NSTableView *)tv {
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    NSURL *theURL = [NSURL URLFromPasteboardAnyType:pboard];
    
    if ([theURL isFileURL])
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:theURL display:YES error:NULL];
    else if (theURL)
        [self addDownloadForURL:theURL];
}

- (BOOL)tableViewCanPaste:(NSTableView *)tv {
    return (nil != [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSURLPboardType, SKWeblocFilePboardType, NSStringPboardType, nil]]);
}

- (NSMenu *)tableView:(NSTableView *)aTableView menuForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSMenu *menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    NSMenuItem *menuItem;
    SKDownload *download = [self objectInDownloadsAtIndex:row];
    
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    
    if ([download canCancel]) {
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Cancel", @"Menu item title") action:@selector(cancelDownload:) target:self];
        [menuItem setRepresentedObject:download];
    } else if ([download canRemove]) {
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Remove", @"Menu item title") action:@selector(removeDownload:) target:self];
        [menuItem setRepresentedObject:download];
    }
    if ([download canResume]) {
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Resume", @"Menu item title") action:@selector(resumeDownload:) target:self];
        [menuItem setRepresentedObject:download];
    }
    if ([download status] == SKDownloadStatusFinished) {
        menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Open", @"Menu item title") stringByAppendingEllipsis] action:@selector(openDownloadedFile:) target:self];
        [menuItem setRepresentedObject:download];
        
        menuItem = [menu addItemWithTitle:[NSLocalizedString(@"Reveal", @"Menu item title") stringByAppendingEllipsis] action:@selector(revealDownloadedFile:) target:self];
        [menuItem setRepresentedObject:download];
        
        menuItem = [menu addItemWithTitle:NSLocalizedString(@"Move to Trash", @"Menu item title") action:@selector(trashDownloadedFile:) target:self];
        [menuItem setRepresentedObject:download];
    }
    
    return menu;
}

- (NSArray *)tableView:(NSTableView *)aTableView typeSelectHelperSelectionItems:(SKTypeSelectHelper *)typeSelectHelper {
    return [downloads valueForKey:SKDownloadFileNameKey];
}

#pragma mark KVO

- (void)startObservingDownloads:(NSArray *)newDownloads {
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [newDownloads count])];
    [newDownloads addObserver:self toObjectsAtIndexes:indexes forKeyPath:SKDownloadFileNameKey options:0 context:&SKDownloadPropertiesObservationContext];
    [newDownloads addObserver:self toObjectsAtIndexes:indexes forKeyPath:SKDownloadStatusKey options:0 context:&SKDownloadPropertiesObservationContext];
}

- (void)endObservingDownloads:(NSArray *)oldDownloads {
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [oldDownloads count])];
    [oldDownloads removeObserver:self fromObjectsAtIndexes:indexes forKeyPath:SKDownloadFileNameKey];
    [oldDownloads removeObserver:self fromObjectsAtIndexes:indexes forKeyPath:SKDownloadStatusKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &SKDownloadPropertiesObservationContext) {
        if ([keyPath isEqualToString:SKDownloadFileNameKey]) {
            [[tableView typeSelectHelper] rebuildTypeSelectSearchCache];
        } else if ([keyPath isEqualToString:SKDownloadStatusKey]) {
            NSUInteger row = [downloads indexOfObject:object];
            if (row != NSNotFound)
                [tableView setNeedsDisplayInRect:NSUnionRect([tableView frameOfCellAtColumn:RESUME_COLUMN row:row], [tableView frameOfCellAtColumn:CANCEL_COLUMN row:row])];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
