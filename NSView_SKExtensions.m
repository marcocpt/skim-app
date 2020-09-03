//
//  NSView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 9/17/07.
/*
 This software is Copyright (c) 2007-2020
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

#import "NSView_SKExtensions.h"
#import "SKLineWell.h"
#import "SKFontWell.h"

#if SDK_BEFORE(10_10)

typedef NS_ENUM(NSInteger, NSVisualEffectMaterial) {
    NSVisualEffectMaterialAppearanceBased = 0,
    NSVisualEffectMaterialLight = 1,
    NSVisualEffectMaterialDark = 2,
    NSVisualEffectMaterialTitlebar = 3,
    NSVisualEffectMaterialSelection = 4
};
typedef NS_ENUM(NSInteger, NSVisualEffectBlendingMode) {
    NSVisualEffectBlendingModeBehindWindow,
    NSVisualEffectBlendingModeWithinWindow,
};
typedef NS_ENUM(NSInteger, NSVisualEffectState) {
    NSVisualEffectStateFollowsWindowActiveState,
    NSVisualEffectStateActive,
    NSVisualEffectStateInactive,
};
@class NSVisualEffectView : NSView
@property NSVisualEffectMaterial material;
@property (readonly) NSBackgroundStyle interiorBackgroundStyle;
@property NSVisualEffectBlendingMode blendingMode;
@property NSVisualEffectState state;
@property(retain) NSImage *maskImage;
@end

#endif

@implementation NSView (SKExtensions)

- (id)subviewOfClass:(Class)aClass {
	if ([self isKindOfClass:aClass])
		return self;
	
	NSView *view;
	
	for (NSView *subview in [self subviews]) {
		if ((view = [subview subviewOfClass:aClass]))
			return view;
	}
	return nil;
}

- (void)deactivateWellSubcontrols {
    [[self subviews] makeObjectsPerformSelector:_cmd];
}

- (void)deactivateColorWellSubcontrols {
    [[self subviews] makeObjectsPerformSelector:_cmd];
}

- (SKFontWell *)activeFontWell {
	SKFontWell *fontWell;
    for (NSView *subview in [self subviews]) {
        if ((fontWell = [subview activeFontWell]))
            return fontWell;
    }
    return nil;
}

- (CGFloat)backingScale {
    if ([self respondsToSelector:@selector(convertSizeToBacking:)])
        return [self convertSizeToBacking:NSMakeSize(1.0, 1.0)].width;
    return 1.0;
}

- (NSRect)convertRectToScreen:(NSRect)rect {
    return [[self window] convertRectToScreen:[self convertRect:rect toView:nil]];
}

- (NSRect)convertRectFromScreen:(NSRect)rect {
    return [self convertRect:[[self window] convertRectFromScreen:rect] fromView:nil];
}

- (NSPoint)convertPointToScreen:(NSPoint)point {
    NSRect rect = NSZeroRect;
    rect.origin = [self convertPoint:point toView:nil];
    return [[self window] convertRectToScreen:rect].origin;
}

- (NSPoint)convertPointFromScreen:(NSPoint)point {
    NSRect rect = NSZeroRect;
    rect.origin = point;
    return [self convertPoint:[[self window] convertRectFromScreen:rect].origin fromView:nil];
}

- (NSBitmapImageRep *)bitmapImageRepCachingDisplayInRect:(NSRect)rect {
    NSBitmapImageRep *imageRep = [self bitmapImageRepForCachingDisplayInRect:rect];
    [self cacheDisplayInRect:rect toBitmapImageRep:imageRep];
    return imageRep;
}

static inline NSVisualEffectMaterial safeMaterial(SKVisualEffectMaterial material) {
    if (RUNNING_BEFORE(10_14)) {
        if (material > SKVisualEffectMaterialUltraDark) {
            if (material == SKVisualEffectMaterialHUDWindow || material == SKVisualEffectMaterialFullScreenUI || material == SKVisualEffectMaterialUnderWindowBackground || material == SKVisualEffectMaterialUnderPageBackground)
                material = SKVisualEffectMaterialDark;
            else
                material = SKVisualEffectMaterialAppearanceBased;
        } else if (RUNNING_BEFORE(10_11) && (material > SKVisualEffectMaterialSelection && material < SKVisualEffectMaterialMediumLight)) {
            material = SKVisualEffectMaterialAppearanceBased;
        }
    }
    return (NSVisualEffectMaterial)material;
}

+ (NSView *)visualEffectViewWithMaterial:(SKVisualEffectMaterial)material active:(BOOL)active blendInWindow:(BOOL)blendInWindow {
    Class aClass = NSClassFromString(@"NSVisualEffectView");
    if (aClass == NO)
        return nil;
    NSView *view = [[[aClass alloc] init] autorelease];
    [(NSVisualEffectView *)view setMaterial:safeMaterial(material)];
    if (active)
        [(NSVisualEffectView *)view setState:NSVisualEffectStateActive];
    if (blendInWindow)
        [(NSVisualEffectView *)view setBlendingMode:NSVisualEffectBlendingModeWithinWindow];
    return view;
}

- (void)applyMaskImageWithDrawingHandler:(void (^)(NSRect dstRect))drawingHandler {
    if ([self respondsToSelector:@selector(setMaskImage:)]) {
        NSRect rect = [self bounds];
        rect.origin = NSZeroPoint;
        NSImage *mask = [[NSImage alloc] initWithSize:rect.size];
        [mask lockFocus];
        [[NSColor blackColor] set];
        drawingHandler(rect);
        [mask unlockFocus];
        [mask setTemplate:YES];
        [(NSVisualEffectView *)self setMaskImage:mask];
        [mask release];
    }
}

- (void)applyVisualEffectMaterial:(SKVisualEffectMaterial)material {
    if ([self respondsToSelector:@selector(setMaterial:)]) {
        [(NSVisualEffectView *)self setMaterial:safeMaterial(material)];
    }
}

@end


@interface NSColorWell (SKNSViewExtensions)
@end

@implementation NSColorWell (SKNSViewExtensions)

- (void)deactivateWellSubcontrols {
    [self deactivate];
    [super deactivateWellSubcontrols];
}

- (void)deactivateColorWellSubcontrols {
    [self deactivate];
    [super deactivateColorWellSubcontrols];
}

@end


@interface SKLineWell (SKNSViewExtensions)
@end

@implementation SKLineWell (SKNSViewExtensions)

- (void)deactivateWellSubcontrols {
    [self deactivate];
    [super deactivateWellSubcontrols];
}

@end


@interface SKFontWell (SKNSViewExtensions)
@end

@implementation SKFontWell (SKNSViewExtensions)

- (void)deactivateWellSubcontrols {
    [self deactivate];
    [super deactivateWellSubcontrols];
}

- (SKFontWell *)activeFontWell {
    if ([self isActive])
        return self;
    return [super activeFontWell];
}

@end
