//
//  NSView_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 9/17/07.
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

#import "NSView_SKExtensions.h"
#import "SKLineWell.h"
#import "SKFontWell.h"


@implementation NSView (SKExtensions)

- (id)subviewOfClass:(Class)aClass {
	if ([self isKindOfClass:aClass])
		return self;
	
	NSEnumerator *viewEnum = [[self subviews] objectEnumerator];
	NSView *view, *subview;
	
	while (subview = [viewEnum nextObject]) {
		if (view = [subview subviewOfClass:aClass])
			return view;
	}
	return nil;
}

- (void)scrollLineUp {
    NSScrollView *scrollView = [self enclosingScrollView];
    NSView *documentView = [scrollView documentView];
    NSPoint point = [documentView visibleRect].origin;
    point.y -= 4.0 * [scrollView verticalLineScroll];
    [documentView scrollPoint:point];
}

- (void)scrollLineDown {
    NSScrollView *scrollView = [self enclosingScrollView];
    NSView *documentView = [scrollView documentView];
    NSPoint point = [documentView visibleRect].origin;
    point.y += 4.0 * [scrollView verticalLineScroll];
    [documentView scrollPoint:point];
}

- (void)scrollLineRight {
    NSScrollView *scrollView = [self enclosingScrollView];
    NSView *documentView = [scrollView documentView];
    NSPoint point = [documentView visibleRect].origin;
    point.x -= 4.0 * [scrollView horizontalLineScroll];
    [documentView scrollPoint:point];
}

- (void)scrollLineLeft {
    NSScrollView *scrollView = [self enclosingScrollView];
    NSView *documentView = [scrollView documentView];
    NSPoint point = [documentView visibleRect].origin;
    point.x += 4.0 * [scrollView horizontalLineScroll];
    [documentView scrollPoint:point];
}

- (void)deactivateWellSubcontrols {
    [[self subviews] makeObjectsPerformSelector:_cmd];
}

- (id)activeFontWellSubview {
	NSEnumerator *viewEnum = [[self subviews] objectEnumerator];
	NSView *view, *subview;
	
	while (subview = [viewEnum nextObject]) {
		if (view = [subview activeFontWellSubview])
			return view;
	}
	return nil;
}

@end


@interface NSColorWell (SKNSViewExtensions)
@end

@implementation NSColorWell (SKNSViewExtensions)

- (void)deactivateWellSubcontrols {
    [self deactivate];
    [super deactivateWellSubcontrols];
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

- (id)activeFontWellSubview {
    return [self isActive] ? self : [super activeFontWellSubview];
}

@end
