//
//  SKSnapshotWindow.m
//  Skim
//
//  Created by Christiaan Hofman on 3/7/13.
/*
 This software is Copyright (c) 2013
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

#import "SKSnapshotWindow.h"
#import <Quartz/Quartz.h>
#import "SKSnapshotPDFView.h"
#import "SKSnapshotWindowController.h"

#define MIN_WINDOW_COORDINATE -160000

@interface NSWindow (SKPrivate)
- (id)_updateButtonsForModeChanged;
@end

@implementation SKSnapshotWindow

@dynamic windowImage;

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
    self = [super initWithContentRect:contentRect styleMask:styleMask backing:bufferingType defer:deferCreation];
    if (self) {
        [[self standardWindowButton:NSWindowMiniaturizeButton] setEnabled:YES];
    }
    return self;
}

- (id)_updateButtonsForModeChanged {
    id rv = [super _updateButtonsForModeChanged];
    [[self standardWindowButton:NSWindowMiniaturizeButton] setEnabled:YES];
    return rv;
}

- (void)miniaturize:(id)sender {
    [[self windowController] miniaturize];
}

- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen {
    if (disableConstrainToScreen)
        return frameRect;
    return [super constrainFrameRect:frameRect toScreen:screen];
}

- (NSImage *)windowImage {
    NSRect frame = [self frame];
    BOOL visible = [self isVisible];
    if (visible == NO) {
        disableConstrainToScreen = YES;
        [self setFrameOrigin:NSMakePoint(MIN_WINDOW_COORDINATE, MIN_WINDOW_COORDINATE)];
        [self orderBack:nil];
        [self displayIfNeeded];
        disableConstrainToScreen = NO;
    }
    CGImageRef cgImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, (CGWindowID)[self windowNumber], kCGWindowImageBoundsIgnoreFraming);
    if (visible == NO) {
        [self orderOut:nil];
        [self setFrameOrigin:frame.origin];
    }
    NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:NSZeroSize];
    [image setDataRetained:YES];
    [image setCacheMode:NSImageCacheNever];
    CGImageRelease(cgImage);
    return [image autorelease];
}

- (void)awakeFromNib {
	// Overrides the parent attribute of the placard so that it belongs to the window.
	NSView *popup = [pdfView scalePopUpButton];
	[NSAccessibilityUnignoredDescendant(popup) accessibilitySetOverrideValue:NSAccessibilityUnignoredAncestor(self) forAttribute:NSAccessibilityParentAttribute];
	[NSAccessibilityUnignoredDescendant(popup) accessibilitySetOverrideValue:NSLocalizedString(@"Zoom", @"Zoom pop-up menu description") forAttribute:NSAccessibilityDescriptionAttribute];
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
	// Overrides the children attribute to add the placard to the children of the window.
	if([attribute isEqualToString:NSAccessibilityChildrenAttribute])
		return [[super accessibilityAttributeValue:attribute] arrayByAddingObject:NSAccessibilityUnignoredDescendant([pdfView scalePopUpButton])];
	else
		return [super accessibilityAttributeValue:attribute];
}

@end
