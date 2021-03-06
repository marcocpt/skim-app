//
//  SKSegmentedControl.m
//  Skim
//
//  Created by Christiaan Hofman on 10/19/08.
/*
 This software is Copyright (c) 2008-2009
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

#import "SKSegmentedControl.h"
#import "NSImage_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"

#define CAPSULE_HEIGHT  23.0
#define TEXTURED_HEIGHT 25.0

@implementation SKSegmentedControl

+ (Class)cellClass {
    return [self instancesRespondToSelector:@selector(setSegmentStyle:)] ? [super cellClass] : [SKSegmentedCell class];
}

- (id)initWithFrame:(NSRect)frameRect {
    frameRect.size.height = [self respondsToSelector:@selector(setSegmentStyle:)] ? CAPSULE_HEIGHT : TEXTURED_HEIGHT;
    if (self = [super initWithFrame:frameRect]) {
        if ([self respondsToSelector:@selector(setSegmentStyle:)])
            [self setSegmentStyle:NSSegmentStyleCapsule];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        NSRect frame = [self frame];
        if ([self respondsToSelector:@selector(setSegmentStyle:)]) {
            [self setSegmentStyle:NSSegmentStyleCapsule];
            frame.size.height = CAPSULE_HEIGHT;
        } else {
            if ([[self cell] isKindOfClass:[[[self class] cellClass] class]] == NO) {
                NSSegmentedCell *cell = [[[[[self class] cellClass] alloc] init] autorelease];
                id oldCell = [self cell];
                NSUInteger i, count = [self segmentCount];
                
                [cell setSegmentCount:count];
                [cell setTrackingMode:[oldCell trackingMode]];
                [cell setAction:[oldCell action]];
                [cell setTarget:[oldCell target]];
                [cell setTag:[oldCell tag]];
                [cell setEnabled:[oldCell isEnabled]];
                [cell setBezeled:NO];
                [cell setBordered:NO];
                
                for (i = 0; i < count; i++) {
                    [cell setWidth:[oldCell widthForSegment:i] forSegment:i];
                    [cell setImage:[oldCell imageForSegment:i] forSegment:i];
                    [cell setLabel:[oldCell labelForSegment:i] forSegment:i];
                    [cell setToolTip:[oldCell toolTipForSegment:i] forSegment:i];
                    [cell setEnabled:[oldCell isEnabledForSegment:i] forSegment:i];
                    [cell setSelected:[oldCell isSelectedForSegment:i] forSegment:i];
                    [cell setMenu:[oldCell menuForSegment:i] forSegment:i];
                    [cell setTag:[oldCell tagForSegment:i] forSegment:i];
                }
                
                [self setCell:cell];
            }
            frame.size.height = TEXTURED_HEIGHT;
        }
        [self setFrame:frame];
    }
    return self;
}

@end


@interface NSSegmentedCell (SKApplePrivateDeclarations)
- (NSInteger)_trackingSegment;
- (NSInteger)_keySegment;
@end


#define SEGMENT_HEIGHT          23.0
#define SEGMENT_HEIGHT_OFFSET   1.0
#define SEGMENT_CAP_WIDTH       15.0
#define SEGMENT_CAP_EXTRA_WIDTH 3.0
#define SEGMENT_SLIVER_WIDTH    1.0

@implementation SKSegmentedCell

- (BOOL)isPressedSegment:(NSInteger)segment {
    return ([self trackingMode] != NSSegmentSwitchTrackingMomentary && [self isSelectedForSegment:segment] && [self isEnabledForSegment:segment]) || 
		   ([self respondsToSelector:@selector(_trackingSegment)] && segment == [self _trackingSegment]);
}

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)controlView {
    NSInteger i, count = [self segmentCount];
    NSInteger keySegment = [self respondsToSelector:@selector(_keySegment)] && [[controlView window] isKeyWindow] && [[controlView window] firstResponder] == controlView ? [self _keySegment] : -1;
    NSRect rect = SKCenterRectVertically(frame, SEGMENT_HEIGHT, [controlView isFlipped]), keyRect = NSZeroRect;
    
    for (i = 0; i < count; i++) {
        NSRect sideRect, midRect;
        NSRect capRect = NSMakeRect(0.0, 0.0, SEGMENT_CAP_WIDTH, SEGMENT_HEIGHT);
        NSRect sliverRect = NSMakeRect(0.0, 0.0, SEGMENT_SLIVER_WIDTH, SEGMENT_HEIGHT);
        rect.size.width = [self widthForSegment:i];
        midRect = rect;
        NSImage *image = [NSImage imageNamed:[self isPressedSegment:i] ? @"Segment_CapPress" : @"Segment_Cap"];
        if (i == 0) {
            rect.size.width += SEGMENT_CAP_EXTRA_WIDTH;
            NSDivideRect(rect, &sideRect, &midRect, SEGMENT_CAP_WIDTH, NSMinXEdge);
            [image drawMirroredAndFlipped:[controlView isFlipped] inRect:sideRect fromRect:capRect operation:NSCompositeSourceOver fraction:1.0];
        }
        if (i == count - 1) {
            rect.size.width += SEGMENT_CAP_EXTRA_WIDTH;
            midRect.size.width += SEGMENT_CAP_EXTRA_WIDTH;
            NSDivideRect(midRect, &sideRect, &midRect, SEGMENT_CAP_WIDTH, NSMaxXEdge);
            [image drawFlipped:[controlView isFlipped] inRect:sideRect fromRect:capRect operation:NSCompositeSourceOver fraction:1.0];
        } else {
            NSDivideRect(midRect, &sideRect, &midRect, -SEGMENT_SLIVER_WIDTH, NSMaxXEdge);
            NSDivideRect(midRect, &sideRect, &midRect, SEGMENT_SLIVER_WIDTH, NSMaxXEdge);
            NSImage *sepImage = [NSImage imageNamed:[self isPressedSegment:i] || [self isPressedSegment:i + 1] ? @"Segment_DividerPress" : @"Segment_Divider"];
            [sepImage drawFlipped:[controlView isFlipped] inRect:sideRect fromRect:sliverRect operation:NSCompositeSourceOver fraction:1.0];
        }
        if (NSWidth(midRect) > 0.0) {
            [image drawFlipped:[controlView isFlipped] inRect:midRect fromRect:sliverRect operation:NSCompositeSourceOver fraction:1.0];
        }
        if (keySegment == i)
            NSDivideRect(rect, &sideRect, &keyRect, SEGMENT_HEIGHT_OFFSET, [controlView isFlipped] ? NSMaxYEdge : NSMinYEdge);
        rect.origin.x = NSMaxX(rect) + SEGMENT_SLIVER_WIDTH;
    }
    
    if (NSIsEmptyRect(keyRect) == NO) {
		[NSGraphicsContext saveGraphicsState];
		NSSetFocusRingStyle(NSFocusRingOnly);
        NSBezierPath *path = [NSBezierPath bezierPath];
        if (keySegment == 0) {
            [path moveToPoint:NSMakePoint(NSMaxX(keyRect), NSMaxY(keyRect))];
            [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(keyRect), NSMaxY(keyRect)) toPoint:NSMakePoint(NSMinX(keyRect), NSMidY(keyRect)) radius:0.5 * (SEGMENT_HEIGHT - SEGMENT_HEIGHT_OFFSET)];
            [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(keyRect), NSMinY(keyRect)) toPoint:NSMakePoint(NSMaxX(keyRect), NSMinY(keyRect)) radius:0.5 * (SEGMENT_HEIGHT - SEGMENT_HEIGHT_OFFSET)];
            [path lineToPoint:NSMakePoint(NSMaxX(keyRect), NSMinY(keyRect))];
            [path closePath];
        } else if (keySegment == count - 1) {
            [path moveToPoint:NSMakePoint(NSMinX(keyRect), NSMinY(keyRect))];
            [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(keyRect), NSMinY(keyRect)) toPoint:NSMakePoint(NSMaxX(keyRect), NSMidY(keyRect)) radius:0.5 * (SEGMENT_HEIGHT - SEGMENT_HEIGHT_OFFSET)];
            [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(keyRect), NSMaxY(keyRect)) toPoint:NSMakePoint(NSMinX(keyRect), NSMaxY(keyRect)) radius:0.5 * (SEGMENT_HEIGHT - SEGMENT_HEIGHT_OFFSET)];
            [path lineToPoint:NSMakePoint(NSMinX(keyRect), NSMaxY(keyRect))];
            [path closePath];
        } else {
            [path appendBezierPathWithRect:keyRect];
        }
        [path fill];
		[NSGraphicsContext restoreGraphicsState];
    }
    
    [self drawInteriorWithFrame:[self drawingRectForBounds:frame] inView:controlView];
}

- (BOOL) _isTextured { return YES; }

- (void)setControlSize:(NSControlSize)size {}

@end
