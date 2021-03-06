//
//  NSBezierPath_BDSKExtensions.m
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

#import "NSBezierPath_BDSKExtensions.h"


@implementation NSBezierPath (BDSKExtensions)

// code from http://www.cocoadev.com/index.pl?NSBezierPathCategory
// removed UK rect function calls, changed spacing/alignment

+ (void)fillRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    NSBezierPath *p = [self bezierPathWithRoundRectInRect:rect radius:radius];
    [p fill];
}


+ (void)strokeRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    NSBezierPath *p = [self bezierPathWithRoundRectInRect:rect radius:radius];
    [p stroke];
}

+ (NSBezierPath *)bezierPathWithRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    // Make sure radius doesn't exceed a maximum size to avoid artifacts:
    radius = SKMin(radius, 0.5f * SKMin(NSHeight(rect), NSWidth(rect)));
    
    // Make sure silly values simply lead to un-rounded corners:
    if( radius <= 0 )
        return [self bezierPathWithRect:rect];
    
    NSRect innerRect = NSInsetRect(rect, radius, radius); // Make rect with corners being centers of the corner circles.
    NSBezierPath *path = [self bezierPath];
    
    [path removeAllPoints];    
    
    // Now draw our rectangle:
    [path moveToPoint: NSMakePoint(NSMinX(innerRect) - radius, NSMinY(innerRect))];
    
    // Bottom left (origin):
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(innerRect), NSMinY(innerRect)) radius:radius startAngle:180.0 endAngle:270.0];
    // Bottom edge and bottom right:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(innerRect), NSMinY(innerRect)) radius:radius startAngle:270.0 endAngle:360.0];
    // Right edge and top right:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(innerRect), NSMaxY(innerRect)) radius:radius startAngle:0.0  endAngle:90.0 ];
    // Top edge and top left:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(innerRect), NSMaxY(innerRect)) radius:radius startAngle:90.0  endAngle:180.0];
    // Left edge:
    [path closePath];
    
    return path;
}

+ (void)fillLeftRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    NSBezierPath *p = [self bezierPathWithLeftRoundRectInRect:rect radius:radius];
    [p fill];
}


+ (void)strokeLeftRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    NSBezierPath *p = [self bezierPathWithLeftRoundRectInRect:rect radius:radius];
    [p stroke];
}

+ (NSBezierPath *)bezierPathWithLeftRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    // Make sure radius doesn't exceed a maximum size to avoid artifacts:
    radius = SKMin(radius, SKMin(0.5f * NSHeight(rect), NSWidth(rect)));
    
    // Make sure silly values simply lead to un-rounded corners:
    if( radius <= 0 )
        return [self bezierPathWithRect:rect];
    
    NSRect ignored, innerRect;
    NSDivideRect(NSInsetRect(rect, 0.0, radius), &ignored, &innerRect, radius, NSMinXEdge); // Make rect with corners being centers of the corner circles.
    NSBezierPath *path = [self bezierPath];
    
    [path removeAllPoints];    
    
    // Now draw our rectangle:
    [path moveToPoint: NSMakePoint(NSMaxX(rect), NSMinY(rect))];
    
    // Right edge:
    [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
    // Top edge and top left:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(innerRect), NSMaxY(innerRect)) radius:radius startAngle:90.0  endAngle:180.0];
    // Left edge and bottom left:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(innerRect), NSMinY(innerRect)) radius:radius startAngle:180.0  endAngle:270.0 ];
    // Bottom edge:
    [path closePath];
    
    return path;
}

+ (void)fillRightRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    NSBezierPath *p = [self bezierPathWithRightRoundRectInRect:rect radius:radius];
    [p fill];
}


+ (void)strokeRightRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    NSBezierPath *p = [self bezierPathWithRightRoundRectInRect:rect radius:radius];
    [p stroke];
}

+ (NSBezierPath *)bezierPathWithRightRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    // Make sure radius doesn't exceed a maximum size to avoid artifacts:
    radius = SKMin(radius, SKMin(0.5f * NSHeight(rect), NSWidth(rect)));
    
    // Make sure silly values simply lead to un-rounded corners:
    if( radius <= 0 )
        return [self bezierPathWithRect:rect];
    
    NSRect ignored, innerRect;
    NSDivideRect(NSInsetRect(rect, 0.0, radius), &ignored, &innerRect, radius, NSMaxXEdge); // Make rect with corners being centers of the corner circles.
    NSBezierPath *path = [self bezierPath];
    
    [path removeAllPoints];    
    
    // Now draw our rectangle:
    [path moveToPoint: NSMakePoint(NSMinX(rect), NSMaxY(rect))];
    
    // Left edge:
    [path lineToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
    // Bottom edge and bottom right:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(innerRect), NSMinY(innerRect)) radius:radius startAngle:270.0 endAngle:360.0];
    // Right edge and top right:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(innerRect), NSMaxY(innerRect)) radius:radius startAngle:0.0  endAngle:90.0 ];
    // Top edge:
    [path closePath];
    
    return path;
}

+ (void)fillTopRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    NSBezierPath *p = [self bezierPathWithTopRoundRectInRect:rect radius:radius];
    [p fill];
}


+ (void)strokeTopRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    NSBezierPath *p = [self bezierPathWithTopRoundRectInRect:rect radius:radius];
    [p stroke];
}

+ (NSBezierPath *)bezierPathWithTopRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    // Make sure radius doesn't exceed a maximum size to avoid artifacts:
    radius = SKMin(radius, SKMin(NSHeight(rect), 0.5f * NSWidth(rect)));
    
    // Make sure silly values simply lead to un-rounded corners:
    if( radius <= 0 )
        return [self bezierPathWithRect:rect];
    
    NSRect ignored, innerRect;
    NSDivideRect(NSInsetRect(rect, radius, 0.0), &ignored, &innerRect, radius, NSMaxYEdge); // Make rect with corners being centers of the corner circles.
    NSBezierPath *path = [self bezierPath];
    
    [path removeAllPoints];    
    
    // Now draw our rectangle:
    [path moveToPoint: NSMakePoint(NSMinX(rect), NSMinY(rect))];
    
    // Bottom edge:
    [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect))];
    // Right edge and top right:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(innerRect), NSMaxY(innerRect)) radius:radius startAngle:0.0  endAngle:90.0 ];
    // Top edge and top left:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(innerRect), NSMaxY(innerRect)) radius:radius startAngle:90.0  endAngle:180.0];
    // Left edge:
    [path closePath];
    
    return path;
}

+ (void)fillBottomRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    NSBezierPath *p = [self bezierPathWithBottomRoundRectInRect:rect radius:radius];
    [p fill];
}


+ (void)strokeBottomRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    NSBezierPath *p = [self bezierPathWithBottomRoundRectInRect:rect radius:radius];
    [p stroke];
}

+ (NSBezierPath *)bezierPathWithBottomRoundRectInRect:(NSRect)rect radius:(CGFloat)radius
{
    // Make sure radius doesn't exceed a maximum size to avoid artifacts:
    radius = SKMin(radius, SKMin(NSHeight(rect), 0.5f * NSWidth(rect)));
    
    // Make sure silly values simply lead to un-rounded corners:
    if( radius <= 0 )
        return [self bezierPathWithRect:rect];
    
    NSRect ignored, innerRect;
    NSDivideRect(NSInsetRect(rect, radius, 0.0), &ignored, &innerRect, radius, NSMinYEdge); // Make rect with corners being centers of the corner circles.
    NSBezierPath *path = [self bezierPath];
    
    [path removeAllPoints];    
    
    // Now draw our rectangle:
    [path moveToPoint: NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
    
    // Top edge:
    [path lineToPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect))];
    // Left edge and bottom left:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(innerRect), NSMinY(innerRect)) radius:radius startAngle:180.0 endAngle:270.0];
    // Bottom edge and bottom right:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(innerRect), NSMinY(innerRect)) radius:radius startAngle:270.0 endAngle:360.0];
    // Left edge:
    [path closePath];
    
    return path;
}

+ (void)drawHighlightInRect:(NSRect)rect radius:(CGFloat)radius lineWidth:(CGFloat)lineWidth color:(NSColor *)color
{
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundRectInRect:NSInsetRect(rect, 0.5 * lineWidth, 0.5 * lineWidth) radius:radius];
    [path setLineWidth:lineWidth];
    [[color colorWithAlphaComponent:0.2] setFill];
    [[color colorWithAlphaComponent:0.8] setStroke];
    [path fill];
    [path stroke];
}

+ (void)fillHorizontalOvalAroundRect:(NSRect)rect
{
    NSBezierPath *p = [self bezierPathWithHorizontalOvalAroundRect:rect];
    [p fill];
}


+ (void)strokeHorizontalOvalAroundRect:(NSRect)rect
{
    NSBezierPath *p = [self bezierPathWithHorizontalOvalAroundRect:rect];
    [p stroke];
}

+ (NSBezierPath *)bezierPathWithHorizontalOvalAroundRect:(NSRect)rect
{
    CGFloat radius = 0.5f * rect.size.height;
    NSBezierPath *path = [self bezierPath];
    
    [path removeAllPoints];
    
    // Now draw our rectangle:
    [path moveToPoint: NSMakePoint(NSMinX(rect), NSMaxY(rect))];
    
    // Left half circle:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMidY(rect)) radius:radius startAngle:90.0 endAngle:270.0];
    // Bottom edge and right half circle:
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMidY(rect)) radius:radius startAngle:-90.0 endAngle:90.0];
    // Top edge:
    [path closePath];
    
    return path;
}

+ (void)fillStarInRect:(NSRect)rect{
    [[self bezierPathWithStarInRect:rect] fill];
}

+ (void)fillInvertedStarInRect:(NSRect)rect{
    [[self bezierPathWithInvertedStarInRect:rect] fill];
}

+ (NSBezierPath *)bezierPathWithStarInRect:(NSRect)rect{
    CGFloat centerX = NSMidX(rect);
    CGFloat centerY = NSMidY(rect);
    CGFloat radiusX = 0.5 * NSWidth(rect);
    CGFloat radiusY = 0.5 * NSHeight(rect);
    NSInteger i = 0;
    NSBezierPath *path = [self bezierPath];
    
    [path removeAllPoints];
    
    [path moveToPoint: NSMakePoint(NSMidX(rect), NSMaxY(rect))];
    while(++i < 5)
        [path lineToPoint:NSMakePoint(centerX + sin(0.8 * M_PI * i) * radiusX, centerY + cos(0.8 * M_PI * i) * radiusY)];
    [path closePath];
    
    return path;
}

+ (NSBezierPath *)bezierPathWithInvertedStarInRect:(NSRect)rect{
    CGFloat centerX = NSMidX(rect);
    CGFloat centerY = NSMidY(rect);
    CGFloat radiusX = 0.5 * NSWidth(rect);
    CGFloat radiusY = 0.5 * NSHeight(rect);
    NSInteger i;
    NSBezierPath *path = [self bezierPath];
    
    [path removeAllPoints];
    
    [path moveToPoint:NSMakePoint(NSMidX(rect), NSMinY(rect))];
    for(i = 1; i < 5; i++)
        [path lineToPoint:NSMakePoint(centerX + sinf(0.8 * M_PI * i) * radiusX, centerY - cosf(0.8 * M_PI * i) * radiusY)];
    [path closePath];
    
    return path;
}

- (NSPoint)associatedPointForElementAtIndex:(NSUInteger)anIndex {
    NSPoint points[3];
    if (NSCurveToBezierPathElement == [self elementAtIndex:anIndex associatedPoints:points])
        return points[2];
    else
        return points[0];
}

- (NSRect)nonEmptyBounds {
    NSRect bounds = [self bounds];
    if (NSIsEmptyRect(bounds) && [self elementCount]) {
        NSPoint point, minPoint = NSZeroPoint, maxPoint = NSZeroPoint;
        NSUInteger i, count = [self elementCount];
        for (i = 0; i < count; i++) {
            point = [self associatedPointForElementAtIndex:i];
            if (i == 0) {
                minPoint = maxPoint = point;
            } else {
                minPoint.x = SKMin(minPoint.x, point.x);
                minPoint.y = SKMin(minPoint.y, point.y);
                maxPoint.x = SKMax(maxPoint.x, point.x);
                maxPoint.y = SKMax(maxPoint.y, point.y);
            }
        }
        bounds = NSMakeRect(minPoint.x - 0.1, minPoint.y - 0.1, maxPoint.x - minPoint.x + 0.2, maxPoint.y - minPoint.y + 0.2);
    }
    return bounds;
}

@end

