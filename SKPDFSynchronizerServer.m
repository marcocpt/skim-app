//
//  SKPDFSynchronizerServer.m
//  Skim
//
//  Created by Christiaan Hofman on 1/11/09.
/*
 This software is Copyright (c) 2009
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

#import "SKPDFSynchronizerServer.h"
#import "SKPDFSynchronizer.h"
#import <libkern/OSAtomic.h>
#import "SKPDFSyncRecord.h"
#import "NSCharacterSet_SKExtensions.h"
#import "NSScanner_SKExtensions.h"
#import <Carbon/Carbon.h>
#import "Files_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "SKCFCallBacks.h"
#import "SKRuntime.h"

#define PDFSYNC_TO_PDF(coord) ((CGFloat)coord / 65536.0)

// Offset of coordinates in PDFKit and what pdfsync tells us. Don't know what they are; is this implementation dependent?
static NSPoint pdfOffset = {0.0, 0.0};

#define SKPDFSynchronizerPdfsyncExtension @"pdfsync"
static NSArray *SKPDFSynchronizerTexExtensions = nil;

struct SKServerFlags {
    volatile int32_t shouldKeepRunning;
    volatile int32_t serverReady;
};

#pragma mark -

@implementation SKPDFSynchronizerServer

+ (void)initialize {
    SKINITIALIZE;
    SKPDFSynchronizerTexExtensions = [[NSArray alloc] initWithObjects:@"tex", @"ltx", @"latex", @"ctx", @"lyx", nil];
}

- (id)init {
    if (self = [super init]) {
        fileName = nil;
        syncFileName = nil;
        lastModDate = nil;
        isPdfsync = YES;
        
        pages = nil;
        lines = nil;
        
        filenames = nil;
        scanner = NULL;
        
        // these will be set when the background thread sets up
        connection = nil;
        clientProxy = nil;
        
        serverFlags = NSZoneCalloc(NSDefaultMallocZone(), 1, sizeof(struct SKServerFlags));
        serverFlags->shouldKeepRunning = 1;
        serverFlags->serverReady = 0;
        
        stopRunning = NO;
    }
    return self;
}

- (void)dealloc {
    NSZoneFree(NSDefaultMallocZone(), serverFlags);
    [pages release];
    [lines release];
    [filenames release];
    [fileName release];
    [syncFileName release];
    [lastModDate release];
    [super dealloc];
}

#pragma mark DO Server

#pragma mark | Thread safe accessors

- (BOOL)shouldKeepRunning {
    OSMemoryBarrier();
    return serverFlags->shouldKeepRunning == 1;
}

- (void)setShouldKeepRunning:(BOOL)flag {
    int32_t old = flag ? 0 : 1, new = flag ? 1 : 0;
    OSAtomicCompareAndSwap32Barrier(old, new, (int32_t *)&serverFlags->shouldKeepRunning);
}

#pragma mark | Running the server

- (void)runDOServerForPorts:(NSArray *)ports {
    // detach a new thread to run this
    NSAssert(connection == nil, @"server is already running");
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    @try {
        // we'll use this to communicate between threads on the localhost
        connection = [[NSConnection alloc] initWithReceivePort:[ports objectAtIndex:0] sendPort:[ports objectAtIndex:1]];
        if (connection == nil)
            @throw @"Unable to get default connection";
        [connection setRootObject:self];
        
        clientProxy = [[connection rootProxy] retain];
        [clientProxy setProtocolForProxy:@protocol(SKPDFSynchronizerClient)];
        // handshake, this sets the proxy at the other side
        [clientProxy setServerProxy:self];
        
        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&serverFlags->serverReady);
        
        NSRunLoop *rl = [NSRunLoop currentRunLoop];
        BOOL didRun;
        
        // see http://lists.apple.com/archives/cocoa-dev/2006/Jun/msg01054.html for a helpful explanation of NSRunLoop
        do {
            [pool release];
            pool = [NSAutoreleasePool new];
            didRun = [rl runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (stopRunning == NO && didRun);
    }
    @catch(id exception) {
        NSLog(@"Discarding exception \"%@\" raised in object %@", exception, self);
        // allow the main thread to continue, anyway
        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&serverFlags->serverReady);
    }
    @finally {
        // clean up the connection in the server thread
        [connection setRootObject:nil];
        
        // this frees up the CFMachPorts created in -init
        [[connection receivePort] invalidate];
        [[connection sendPort] invalidate];
        [connection invalidate];
        [connection release];
        connection = nil;
        
        [clientProxy release];
        clientProxy = nil;    
        
        if (scanner) {
            synctex_scanner_free(scanner);
            scanner = NULL;
        }
        
        [pool release];
    }
}

- (void)startDOServerForPorts:(NSArray *)ports {
    [NSThread detachNewThreadSelector:@selector(runDOServerForPorts:) toTarget:self withObject:ports];
    
    // wait till the server is set up
    do {
        if (NO == [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]])
            [self setShouldKeepRunning:NO];
        OSMemoryBarrier();
    } while (serverFlags->serverReady == 0 && serverFlags->shouldKeepRunning == 1);
}

#pragma mark | Server protocol

- (oneway void)stopRunning {
    stopRunning = YES;
}

#pragma mark Finding and Parsing

#pragma mark | Thread safe accessors

- (NSString *)fileName {
    NSString *file = nil;
    @synchronized(self) {
        file = [[fileName retain] autorelease];
    }
    return file;
}

- (void)setFileName:(NSString *)newFileName {
    // we compare filenames in canonical form throughout, so we need to make sure fileName also is in canonical form
    newFileName = [[newFileName stringByResolvingSymlinksInPath] stringByStandardizingPath];
    @synchronized(self) {
        if (fileName != newFileName) {
            if ([fileName isEqualToString:newFileName] == NO) {
                [syncFileName release];
                syncFileName = nil;
                [lastModDate release];
                lastModDate = nil;
            }
            [fileName release];
            fileName = [newFileName retain];
        }
    }
}

- (NSString *)syncFileName {
    NSString *file = nil;
    @synchronized(self) {
        file = [[syncFileName retain] autorelease];
    }
    return file;
}

- (void)setSyncFileName:(NSString *)newSyncFileName {
    @synchronized(self) {
        if (syncFileName != newSyncFileName) {
            [syncFileName release];
            syncFileName = [newSyncFileName retain];
        }
        [lastModDate release];
        lastModDate = [(syncFileName ? SKFileModificationDateAtPath(syncFileName) : nil) retain];
    }
}

- (NSDate *)lastModDate {
    NSDate *date = nil;
    @synchronized(self) {
        date = [[lastModDate retain] autorelease];
    }
    return date;
}

#pragma mark | Support

- (NSString *)sourceFileForFileName:(NSString *)file isTeX:(BOOL)isTeX removeQuotes:(BOOL)removeQuotes {
    if (removeQuotes && [file length] > 2 && [file characterAtIndex:0] == '"' && [file characterAtIndex:[file length] - 1] == '"')
        file = [file substringWithRange:NSMakeRange(1, [file length] - 2)];
    if ([file isAbsolutePath] == NO)
        file = [[[self fileName] stringByDeletingLastPathComponent] stringByAppendingPathComponent:file];
    if (isTeX && SKFileExistsAtPath(file) == NO && [SKPDFSynchronizerTexExtensions containsObject:[[file pathExtension] lowercaseString]] == NO) {
        NSEnumerator *texExtensions = [SKPDFSynchronizerTexExtensions objectEnumerator];
        NSString *extension;
        while (extension = [texExtensions nextObject]) {
            NSString *tryFile = [file stringByAppendingPathExtension:extension];
            if (SKFileExistsAtPath(tryFile)) {
                file = tryFile;
                break;
            }
        }
    }
    // the docs say -stringByStandardizingPath uses -stringByResolvingSymlinksInPath, but it doesn't 
    return [[file stringByResolvingSymlinksInPath] stringByStandardizingPath];
}

- (NSString *)sourceFileForFileSystemRepresentation:(const char *)fileRep isTeX:(BOOL)isTeX {
    NSString *file = (NSString *)CFStringCreateWithFileSystemRepresentation(NULL, fileRep);
    return [self sourceFileForFileName:[file autorelease] isTeX:isTeX removeQuotes:NO];
}

#pragma mark | PDFSync

- (BOOL)loadPdfsyncFile:(NSString *)theFileName {

    if (pages)
        [pages removeAllObjects];
    else
        pages = [[NSMutableArray alloc] init];
    if (lines)
        [lines removeAllObjects];
    else
        lines = (NSMutableDictionary *)CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kSKCaseInsensitiveStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    [self setSyncFileName:theFileName];
    isPdfsync = YES;
    
    NSString *pdfsyncString = [NSString stringWithContentsOfFile:theFileName encoding:NSUTF8StringEncoding error:NULL];
    BOOL rv = NO;
    
    if ([pdfsyncString length]) {
        
        SKPDFSyncRecords *records = [[SKPDFSyncRecords alloc] init];
        NSMutableArray *files = [[NSMutableArray alloc] init];
        NSString *file;
        NSInteger recordIndex, line, pageIndex;
        CGFloat x, y;
        SKPDFSyncRecord *record;
        NSMutableArray *array;
        unichar ch;
        NSScanner *sc = [[NSScanner alloc] initWithString:pdfsyncString];
        
        [sc setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([sc scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&file] &&
            [sc scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL]) {
            
            file = [self sourceFileForFileName:file isTeX:YES removeQuotes:YES];
            [files addObject:file];
            
            array = [[NSMutableArray alloc] init];
            [lines setObject:array forKey:file];
            [array release];
            
            // we ignore the version
            if ([sc scanString:@"version" intoString:NULL] && [sc scanInt:NULL]) {
                
                [sc scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
                
                while ([self shouldKeepRunning] && [sc scanCharacter:&ch]) {
                    
                    switch (ch) {
                        case 'l':
                            if ([sc scanInt:&recordIndex] && [sc scanInt:&line]) {
                                // we ignore the column
                                [sc scanInt:NULL];
                                record = [records recordForIndex:recordIndex];
                                [record setFile:file];
                                [record setLine:line];
                                [[lines objectForKey:file] addObject:record];
                            }
                            break;
                        case 'p':
                            // we ignore * and + modifiers
                            if ([sc scanString:@"*" intoString:NULL] == NO)
                                [sc scanString:@"+" intoString:NULL];
                            if ([sc scanInt:&recordIndex] && [sc scanFloat:&x] && [sc scanFloat:&y]) {
                                record = [records recordForIndex:recordIndex];
                                [record setPageIndex:[pages count] - 1];
                                [record setPoint:NSMakePoint(PDFSYNC_TO_PDF(x) + pdfOffset.x, PDFSYNC_TO_PDF(y) + pdfOffset.y)];
                                [[pages lastObject] addObject:record];
                            }
                            break;
                        case 's':
                            // start of a new page, the scanned integer should always equal [pages count]+1
                            if ([sc scanInt:&pageIndex] == NO) pageIndex = [pages count] + 1;
                            while (pageIndex > (NSInteger)[pages count]) {
                                array = [[NSMutableArray alloc] init];
                                [pages addObject:array];
                                [array release];
                            }
                            break;
                        case '(':
                            // start of a new source file
                            if ([sc scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&file]) {
                                file = [self sourceFileForFileName:file isTeX:YES removeQuotes:YES];
                                [files addObject:file];
                                if ([lines objectForKey:file] == nil) {
                                    array = [[NSMutableArray alloc] init];
                                    [lines setObject:array forKey:file];
                                    [array release];
                                }
                            }
                            break;
                        case ')':
                            // closing of a source file
                            if ([files count]) {
                                [files removeLastObject];
                                file = [files lastObject];
                            }
                            break;
                        default:
                            // shouldn't reach
                            break;
                    }
                    
                    [sc scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
                    [sc scanCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:NULL];
                }
                
                NSSortDescriptor *lineSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"line" ascending:YES] autorelease];
                NSSortDescriptor *xSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"x" ascending:YES] autorelease];
                NSSortDescriptor *ySortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"y" ascending:NO] autorelease];
                
                [[lines allValues] makeObjectsPerformSelector:@selector(sortUsingDescriptors:)
                                                   withObject:[NSArray arrayWithObjects:lineSortDescriptor, nil]];
                [pages makeObjectsPerformSelector:@selector(sortUsingDescriptors:)
                                       withObject:[NSArray arrayWithObjects:ySortDescriptor, xSortDescriptor, nil]];
                
                 rv = [self shouldKeepRunning];
            }
        }
        
        [records release];
        [files release];
        [sc release];
    }
    
    return rv;
}

- (BOOL)pdfsyncFindFileLine:(NSInteger *)linePtr file:(NSString **)filePtr forLocation:(NSPoint)point inRect:(NSRect)rect pageBounds:(NSRect)bounds atPageIndex:(NSUInteger)pageIndex {
    BOOL rv = NO;
    if (pageIndex < [pages count]) {
        
        SKPDFSyncRecord *record = nil;
        SKPDFSyncRecord *beforeRecord = nil;
        SKPDFSyncRecord *afterRecord = nil;
        NSMutableDictionary *atRecords = [NSMutableDictionary dictionary];
        NSEnumerator *recordEnum = [[pages objectAtIndex:pageIndex] objectEnumerator];
        
        while (record = [recordEnum nextObject]) {
            if ([record line] == 0)
                continue;
            NSPoint p = [record point];
            if (p.y > NSMaxY(rect)) {
                beforeRecord = record;
            } else if (p.y < NSMinY(rect)) {
                afterRecord = record;
                break;
            } else if (p.x < NSMinX(rect)) {
                beforeRecord = record;
            } else if (p.x > NSMaxX(rect)) {
                afterRecord = record;
                break;
            } else {
                [atRecords setObject:record forKey:[NSNumber numberWithFloat:SKAbs(p.x - point.x)]];
            }
        }
        
        record = nil;
        if ([atRecords count]) {
            NSNumber *nearest = [[[atRecords allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0];
            record = [atRecords objectForKey:nearest];
        } else if (beforeRecord && afterRecord) {
            NSPoint beforePoint = [beforeRecord point];
            NSPoint afterPoint = [afterRecord point];
            if (beforePoint.y - point.y < point.y - afterPoint.y)
                record = beforeRecord;
            else if (beforePoint.y - point.y > point.y - afterPoint.y)
                record = afterRecord;
            else if (beforePoint.x - point.x < point.x - afterPoint.x)
                record = beforeRecord;
            else if (beforePoint.x - point.x > point.x - afterPoint.x)
                record = afterRecord;
            else
                record = beforeRecord;
        } else if (beforeRecord) {
            record = beforeRecord;
        } else if (afterRecord) {
            record = afterRecord;
        }
        
        if (record) {
            *linePtr = [record line];
            *filePtr = [record file];
            rv = YES;
        }
    }
    return rv;
}

- (BOOL)pdfsyncFindPage:(NSUInteger *)pageIndexPtr location:(NSPoint *)pointPtr forLine:(NSInteger)line inFile:(NSString *)file {
    BOOL rv = NO;
    NSArray *theLines = [lines objectForKey:file];
    if (theLines) {
        
        SKPDFSyncRecord *record = nil;
        SKPDFSyncRecord *beforeRecord = nil;
        SKPDFSyncRecord *afterRecord = nil;
        SKPDFSyncRecord *atRecord = nil;
        NSEnumerator *recordEnum = [theLines objectEnumerator];
        
        while (record = [recordEnum nextObject]) {
            if ([record pageIndex] == NSNotFound)
                continue;
            NSInteger l = [record line];
            if (l < line) {
                beforeRecord = record;
            } else if (l > line) {
                afterRecord = record;
                break;
            } else {
                atRecord = record;
                break;
            }
        }
        
        if (atRecord) {
            record = atRecord;
        } else if (beforeRecord && afterRecord) {
            NSInteger beforeLine = [beforeRecord line];
            NSInteger afterLine = [afterRecord line];
            if (beforeLine - line > line - afterLine)
                record = afterRecord;
            else
                record = beforeRecord;
        } else if (beforeRecord) {
            record = beforeRecord;
        } else if (afterRecord) {
            record = afterRecord;
        }
        
        if (record) {
            *pageIndexPtr = [record pageIndex];
            *pointPtr = [record point];
            rv = YES;
        }
    }
    return rv;
}

#pragma mark | SyncTeX

- (BOOL)loadSynctexFileForFile:(NSString *)theFileName {
    BOOL rv = NO;
    if (scanner)
        synctex_scanner_free(scanner);
    scanner = synctex_scanner_new_with_output_file([theFileName fileSystemRepresentation]);
    if (scanner) {
        [self setSyncFileName:[self sourceFileForFileSystemRepresentation:synctex_scanner_get_synctex(scanner) isTeX:NO]];
        if (filenames)
            [filenames removeAllObjects];
        else
            filenames = (NSMutableDictionary *)CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kSKCaseInsensitiveStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        NSString *filename;
        synctex_node_t node = synctex_scanner_input(scanner);
        do {
            filename = [(NSString *)CFStringCreateWithFileSystemRepresentation(NULL, synctex_scanner_get_name(scanner, synctex_node_tag(node))) autorelease];
            [filenames setObject:filename forKey:[self sourceFileForFileName:filename isTeX:YES removeQuotes:NO]];
        } while (node = synctex_node_next(node));
        isPdfsync = NO;
        rv = [self shouldKeepRunning];
    }
    return rv;
}

- (BOOL)synctexFindFileLine:(NSInteger *)linePtr file:(NSString **)filePtr forLocation:(NSPoint)point inRect:(NSRect)rect pageBounds:(NSRect)bounds atPageIndex:(NSUInteger)pageIndex {
    BOOL rv = NO;
    if (synctex_edit_query(scanner, (int)pageIndex + 1, point.x, NSMaxY(bounds) - point.y) > 0) {
        synctex_node_t node = synctex_next_result(scanner);
        if (node) {
            *linePtr = MAX(synctex_node_line(node), 1) - 1;
            *filePtr = [self sourceFileForFileSystemRepresentation:synctex_scanner_get_name(scanner, synctex_node_tag(node)) isTeX:YES];
            rv = YES;
        }
    }
    return rv;
}

- (BOOL)synctexFindPage:(NSUInteger *)pageIndexPtr location:(NSPoint *)pointPtr forLine:(NSInteger)line inFile:(NSString *)file {
    BOOL rv = NO;
    NSString *filename = [filenames objectForKey:file] ?: [file lastPathComponent];
    if (synctex_display_query(scanner, [filename fileSystemRepresentation], (int)line + 1, 0) > 0) {
        synctex_node_t node = synctex_next_result(scanner);
        if (node) {
            NSUInteger page = synctex_node_page(node);
            *pageIndexPtr = MAX(page, 1u) - 1;
            *pointPtr = NSMakePoint(synctex_node_visible_h(node), synctex_node_visible_v(node));
            rv = YES;
        }
    }
    return rv;
}

#pragma mark | Generic

- (BOOL)loadSyncFileIfNeeded {
    NSString *theFileName = [self fileName];
    BOOL rv = NO;
    
    if (theFileName) {
        NSString *theSyncFileName = [self syncFileName];
        
        if (theSyncFileName && SKFileExistsAtPath(theSyncFileName)) {
            NSDate *modDate = SKFileModificationDateAtPath(theFileName);
            NSDate *currentModDate = [self lastModDate];
        
            if (currentModDate && [modDate compare:currentModDate] != NSOrderedDescending)
                rv = YES;
            else if (isPdfsync)
                rv = [self loadPdfsyncFile:theSyncFileName];
            else
                rv = [self loadSynctexFileForFile:theFileName];
        } else {
            rv = [self loadSynctexFileForFile:theFileName];
            if (rv == NO) {
                theSyncFileName = [theFileName stringByReplacingPathExtension:SKPDFSynchronizerPdfsyncExtension];
                if (SKFileExistsAtPath(theSyncFileName))
                    rv = [self loadPdfsyncFile:theSyncFileName];
            }
        }
    }
    return rv;
}

#pragma mark || Server protocol

- (oneway void)findFileAndLineForLocation:(NSPoint)point inRect:(NSRect)rect pageBounds:(NSRect)bounds atPageIndex:(NSUInteger)pageIndex {
    if ([self shouldKeepRunning] && [self loadSyncFileIfNeeded]) {
        NSInteger foundLine = 0;
        NSString *foundFile = nil;
        BOOL success = NO;
        
        if (isPdfsync)
            success = [self pdfsyncFindFileLine:&foundLine file:&foundFile forLocation:point inRect:rect pageBounds:bounds atPageIndex:pageIndex];
        else
            success = [self synctexFindFileLine:&foundLine file:&foundFile forLocation:point inRect:rect pageBounds:bounds atPageIndex:pageIndex];
        
        if (success && [self shouldKeepRunning])
            [clientProxy foundLine:foundLine inFile:foundFile];
    }
}

- (oneway void)findPageAndLocationForLine:(NSInteger)line inFile:(bycopy NSString *)file options:(NSInteger)options {
    if (file && [self shouldKeepRunning] && [self loadSyncFileIfNeeded]) {
        NSUInteger foundPageIndex = NSNotFound;
        NSPoint foundPoint = NSZeroPoint;
        BOOL success = NO;
        
        file = [self sourceFileForFileName:file isTeX:YES removeQuotes:NO];
        
        if (isPdfsync)
            success = [self pdfsyncFindPage:&foundPageIndex location:&foundPoint forLine:line inFile:file];
        else
            success = [self synctexFindPage:&foundPageIndex location:&foundPoint forLine:line inFile:file];
        
        if (success && [self shouldKeepRunning]) {
            if (isPdfsync)
                options &= ~SKPDFSynchronizerFlippedMask;
            else
                options |= SKPDFSynchronizerFlippedMask;
            [clientProxy foundLocation:foundPoint atPageIndex:foundPageIndex options:options];
        }
    }
}

@end
