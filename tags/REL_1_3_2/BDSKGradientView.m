//
//  BDSKGradientView.m
//  Bibdesk
//
//  Created by Adam Maxwell on 10/26/05.
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

#import "BDSKGradientView.h"

@interface BDSKGradientView (Private)

- (void)setDefaultColors;

@end

@implementation BDSKGradientView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    [self setDefaultColors];
    return self;
}

- (void)dealloc
{
    [lowerColor release];
    [upperColor release];
    [super dealloc];
}

- (void)drawRect:(NSRect)aRect
{        
    // fill entire view, not just the (possibly clipped) aRect
    if ([[self window] styleMask] & NSClosableWindowMask) {
        NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:lowerColor endingColor:upperColor] autorelease];
        [gradient drawInRect:[self bounds] angle:90.0];
    }
}

- (void)setLowerColor:(NSColor *)color
{
    if (lowerColor != color) {
        [lowerColor release];
        lowerColor = [color retain];
    }
}

- (void)setUpperColor:(NSColor *)color
{
    if (upperColor != color) {
        [upperColor release];
        upperColor = [color retain];
    }
}    

- (NSColor *)lowerColor { return lowerColor; }
- (NSColor *)upperColor { return upperColor; }

// required in order for redisplay to work properly with the controls
- (BOOL)isOpaque{  return ([[self window] styleMask] & NSClosableWindowMask) != 0; }
- (BOOL)isFlipped { return NO; }

@end

@implementation BDSKGradientView (Private)

// provides an example implementation
- (void)setDefaultColors
{
    [self setLowerColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];
    [self setUpperColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
}

@end