//
//  SKScriptMenu.m
//  Skim
//
//  Created by Christiaan on 4/22/10.
/*
 This software is Copyright (c) 2010
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

#import "SKScriptMenu.h"
#import "NSFileManager_SKExtensions.h"
#import "NSMenu_SKExtensions.h"

#define SCRIPTS_MENU_TITLE  @"Scripts"
#define SCRIPTS_FOLDER_NAME @"Scripts"
#define FILENAME_KEY        @"filename"
#define CONTENT_KEY         @"content"

@interface SKScriptMenu (Private)
- (id)initWithPaths:(NSArray *)scriptFolders;
- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification;
- (NSArray *)directoryContentsAtPath:(NSString *)path recursionDepth:(NSInteger)depth;
- (void)executeScript:(id)sender;
@end

@implementation SKScriptMenu

static SKScriptMenu *sharedMenu = nil;
static menuNeedsUpdate = NO;

+ (void)setupScriptMenu {
    if (sharedMenu)
        return;
    
    NSInteger itemIndex = [[NSApp mainMenu] numberOfItems] - 1;
    if (itemIndex <= 0)
        return;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray *scriptFolders = [NSMutableArray array];
    BOOL isDir;
    
    for (NSString *folder in [fm applicationSupportDirectories]) {
        folder = [folder stringByAppendingPathComponent:SCRIPTS_FOLDER_NAME];
        if ([fm fileExistsAtPath:folder isDirectory:&isDir] && isDir)
            [scriptFolders addObject:folder];
    }
    
    if ([scriptFolders count] == 0)
        return;
    
    sharedMenu = [[self alloc] initWithPaths:scriptFolders];
    NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:SCRIPTS_MENU_TITLE action:NULL keyEquivalent:@""];
    [menuItem setImage:[NSImage imageNamed:@"ScriptMenu"]];
    [menuItem setSubmenu:sharedMenu];
    [[NSApp mainMenu] insertItem:menuItem atIndex:itemIndex];
    [menuItem release];
}

static void fsevents_callback(FSEventStreamRef streamRef, void *clientCallBackInfo, int numEvents, const char *const eventPaths[], const FSEventStreamEventFlags *eventMasks, const uint64_t *eventIDs) {
    menuNeedsUpdate = YES;
}

- (id)initWithPaths:(NSArray *)scriptFolders {
    if (self = [super initWithTitle:SCRIPTS_MENU_TITLE]) {
        sortDescriptors = [[NSArray alloc] initWithObjects:[[[NSSortDescriptor alloc] initWithKey:FILENAME_KEY ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease], nil];
        
        FSEventStreamContext context = {0, NULL, NULL, NULL, NULL};
        streamRef = FSEventStreamCreate(kCFAllocatorDefault,
                                        (FSEventStreamCallback)&fsevents_callback,
                                        &context,
                                        (CFArrayRef)scriptFolders,
                                        kFSEventStreamEventIdSinceNow, // sinceWhen
                                        1.0, // latency
                                        0); // flags
        FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        FSEventStreamStart(streamRef);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillTerminateNotification:) name:NSApplicationWillTerminateNotification object:NSApp];
        [self setDelegate:self];
        menuNeedsUpdate = YES;
    }
    return self;
}

- (id)initWithTitle:(NSString *)aTitle {
    [self release];
    return nil;
}

- (void)handleApplicationWillTerminateNotification:(NSNotification *)notification {
    if (streamRef) {
        FSEventStreamStop(streamRef);
        FSEventStreamInvalidate(streamRef);
        FSEventStreamRelease(streamRef);
        streamRef = NULL;
    }
    [self setDelegate:nil];
}

- (void)updateSubmenu:(NSMenu *)menu withScripts:(NSArray *)scripts {
    static NSSet *scriptExtensions = nil;
    if (scriptExtensions == nil)
        scriptExtensions = [[NSSet alloc] initWithObjects:@"scpt", @"scptd", @"applescript", @"sh", @"csh", @"command", @"py", @"rb", @"pl", @"pm", @"app", @"workflow", nil];
    
    [menu removeAllItems];
    
    for (NSDictionary *scriptInfo in scripts) {
        NSString *scriptFilename = [scriptInfo objectForKey:FILENAME_KEY];
		NSArray *folderContent = [scriptInfo objectForKey:CONTENT_KEY];
        NSString *scriptName = [scriptFilename lastPathComponent];
		NSMenuItem *item;
        
        if (folderContent) {
            NSMenu *submenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:scriptName];
            [menu addItemWithTitle:scriptName submenu:submenu];
            [self updateSubmenu:submenu withScripts:folderContent];
            [submenu release];
        } else {
            if ([scriptExtensions containsObject:[[scriptName pathExtension] lowercaseString]])
                scriptName = [scriptName stringByDeletingPathExtension];
            item = [menu addItemWithTitle:scriptName action:@selector(executeScript:) target:self];
            [item setTarget:self];
            [item setRepresentedObject:scriptFilename];
        }
    }
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (streamRef == NULL || menuNeedsUpdate == NO)
        return;
    
    NSArray *scriptFolders = (NSArray *)FSEventStreamCopyPathsBeingWatched(streamRef);
    NSMutableArray *scripts = [NSMutableArray array];
    for (NSString *folder in scriptFolders)
        [scripts addObjectsFromArray:[self directoryContentsAtPath:folder recursionDepth:0]];
    [scriptFolders release];
    [scripts sortUsingDescriptors:sortDescriptors];
    
    [self updateSubmenu:menu withScripts:scripts];
    
    menuNeedsUpdate = NO;
}

static BOOL isAppleScriptUTI(NSString *theUTI) {
    if (theUTI == NULL)
        return NO;
    return [[NSWorkspace sharedWorkspace] type:theUTI conformsToType:@"com.apple.applescript.script"] ||
           [[NSWorkspace sharedWorkspace] type:theUTI conformsToType:@"com.apple.applescript.text"] ||
           [[NSWorkspace sharedWorkspace] type:theUTI conformsToType:@"com.apple.applescript.script-bundle"];
}

static BOOL isApplicationUTI(NSString *theUTI) {
    if (theUTI == NULL)
        return NO;
    return [[NSWorkspace sharedWorkspace] type:theUTI conformsToType:(id)kUTTypeApplication];
}

static BOOL isAutomatorWorkflowUTI(NSString *theUTI) {
    if (theUTI == NULL)
        return NO;
    return [[NSWorkspace sharedWorkspace] type:theUTI conformsToType:@"com.apple.automator-workflow"];
}

static BOOL isFolderUTI(NSString *theUTI) {
    if (theUTI == NULL)
        return NO;
    return [[NSWorkspace sharedWorkspace] type:theUTI conformsToType:(id)kUTTypeFolder];
}

- (NSArray *)directoryContentsAtPath:(NSString *)path recursionDepth:(NSInteger)depth {
    NSMutableArray *files = [NSMutableArray array];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    for (NSString *file in [fm contentsOfDirectoryAtPath:path error:NULL]) {
        NSString *filePath = [path stringByAppendingPathComponent:file];
        NSDictionary *fileAttributes = [fm attributesOfItemAtPath:filePath error:NULL];
        NSString *fileType = [fileAttributes valueForKey:NSFileType];
        BOOL isDir = [fileType isEqualToString:NSFileTypeDirectory];
        NSString *theUTI = [ws typeOfFile:[[filePath stringByStandardizingPath] stringByResolvingSymlinksInPath] error:NULL];
        
        NSDictionary *dict;
        
        if ([file hasPrefix:@"."]) {
        } else if (isAppleScriptUTI(theUTI) || isApplicationUTI(theUTI) || isAutomatorWorkflowUTI(theUTI) || ([fm isExecutableFileAtPath:filePath] && isDir == NO)) {
            dict = [[NSDictionary alloc] initWithObjectsAndKeys:filePath, FILENAME_KEY, nil];
            [files addObject:dict];
            [dict release];
        } else if (isDir && isFolderUTI(theUTI) && depth < 3) {
            NSArray *content = [self directoryContentsAtPath:filePath recursionDepth:depth + 1];
            if ([content count] > 0) {
                dict = [[NSDictionary alloc] initWithObjectsAndKeys:filePath, FILENAME_KEY, content, CONTENT_KEY, nil];
                [files addObject:dict];
                [dict release];
            }
        }
    }
    [files sortUsingDescriptors:sortDescriptors];
    return files;
}

- (void)executeScript:(id)sender {
    NSString *scriptFilename = [sender representedObject];
    NSString *theUTI = [[NSWorkspace sharedWorkspace] typeOfFile:[[scriptFilename stringByStandardizingPath] stringByResolvingSymlinksInPath] error:NULL];
    
    if (isAppleScriptUTI(theUTI)) {
        NSDictionary *errorDictionary;
        NSAppleScript *script = [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptFilename] error:&errorDictionary] autorelease];
        if (script == nil) {
            NSLog(@"AppleScript file '%@' could not be opened: %@", scriptFilename, errorDictionary);
            NSBeep();
        } else {
            NSAppleEventDescriptor *result = [script executeAndReturnError:&errorDictionary];
            if (result == nil) {
                NSLog(@"AppleScript file '%@' failed to execute: %@", scriptFilename, errorDictionary);
                NSBeep();
            }
        }
    } else if (isApplicationUTI(theUTI)) {
        BOOL result = [[NSWorkspace sharedWorkspace] launchApplication:scriptFilename];
        if (result == NO) {
            NSLog(@"Application '%@' could not be launched", scriptFilename);
            NSBeep();
        }
    } else if (isAutomatorWorkflowUTI(theUTI)) {
        [NSTask launchedTaskWithLaunchPath:@"/usr/bin/automator" arguments:[NSArray arrayWithObjects:scriptFilename, nil]];
    } else if ([[NSFileManager defaultManager] isExecutableFileAtPath:scriptFilename]) {
        [NSTask launchedTaskWithLaunchPath:scriptFilename arguments:[NSArray array]];
    }
}

@end
