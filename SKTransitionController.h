//
//  SKTransitionController.h
//  Skim
//
//  Created by Christiaan Hofman on 7/15/07.
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

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <Quartz/Quartz.h>

#pragma mark SKTransitionController

// this corresponds to the CGSTransitionType enum
enum {
	SKNoTransition,
    // Core Graphics transitions
	SKFadeTransition,
	SKZoomTransition,
	SKRevealTransition,
	SKSlideTransition,
	SKWarpFadeTransition,
	SKSwapTransition,
	SKCubeTransition,
	SKWarpSwitchTransition,
	SKWarpFlipTransition,
    // Core Image transitions
    SKCoreImageTransition
};
typedef NSUInteger SKAnimationTransitionStyle;

@class CIImage, SKTransitionWindow, SKTransitionView;

@interface SKTransitionController : NSObject {
    SKTransitionWindow *transitionWindow;
    
    NSView *view;
    CIImage *initialImage;
    NSRect imageRect;
    
    NSMutableDictionary *filters;
    
    SKAnimationTransitionStyle transitionStyle;
    CGFloat duration;
    BOOL shouldRestrict;
    
    SKAnimationTransitionStyle currentTransitionStyle;
    CGFloat currentDuration;
    BOOL currentShouldRestrict;
    
    NSArray *pageTransitions;
}

+ (NSArray *)transitionFilterNames;
+ (NSArray *)transitionNames;

+ (NSString *)nameForStyle:(SKAnimationTransitionStyle)style;
+ (SKAnimationTransitionStyle)styleForName:(NSString *)name;

- (id)initWithView:(NSView *)aView;

- (NSView *)view;
- (void)setView:(NSView *)newView;

- (SKAnimationTransitionStyle)transitionStyle;
- (void)setTransitionStyle:(SKAnimationTransitionStyle)style;

- (CGFloat)duration;
- (void)setDuration:(CGFloat)newDuration;

- (BOOL)shouldRestrict;
- (void)setShouldRestrict:(BOOL)flag;

- (NSArray *)pageTransitions;
- (void)setPageTransitions:(NSArray *)newPageTransitions;

- (NSUndoManager *)undoManager;

- (void)prepareAnimationForRect:(NSRect)rect;
- (void)prepareAnimationForRect:(NSRect)rect from:(NSUInteger)fromIndex to:(NSUInteger)toIndex;
- (void)animateForRect:(NSRect)rect forward:(BOOL)forward;

@end
