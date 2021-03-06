//
//  NSBezierPath_BDSKExtensions.h
//  Bibdesk
//
//  Created by Adam Maxwell on 10/22/05.
/*
 This software is Copyright (c) 2005-2009-2008
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
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
#import <Cocoa/Cocoa.h>


@interface NSBezierPath (BDSKExtensions)

+ (void)fillRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (void)strokeRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (NSBezierPath *)bezierPathWithRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (void)fillLeftRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (void)strokeLeftRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (NSBezierPath *)bezierPathWithLeftRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (void)fillRightRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (void)strokeRightRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (NSBezierPath *)bezierPathWithRightRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (void)fillTopRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (void)strokeTopRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (NSBezierPath *)bezierPathWithTopRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (void)fillBottomRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (void)strokeBottomRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;
+ (NSBezierPath *)bezierPathWithBottomRoundRectInRect:(NSRect)rect radius:(CGFloat)radius;

+ (void)drawHighlightInRect:(NSRect)rect radius:(CGFloat)radius lineWidth:(CGFloat)lineWidth color:(NSColor *)color;

+ (void)fillHorizontalOvalAroundRect:(NSRect)rect;
+ (void)strokeHorizontalOvalAroundRect:(NSRect)rect;
+ (NSBezierPath*)bezierPathWithHorizontalOvalAroundRect:(NSRect)rect;

+ (void)fillStarInRect:(NSRect)rect;
+ (void)fillInvertedStarInRect:(NSRect)rect;
+ (NSBezierPath *)bezierPathWithStarInRect:(NSRect)rect;
+ (NSBezierPath *)bezierPathWithInvertedStarInRect:(NSRect)rect;

- (NSRect)nonEmptyBounds;

- (NSPoint)associatedPointForElementAtIndex:(NSUInteger)anIndex;

@end
