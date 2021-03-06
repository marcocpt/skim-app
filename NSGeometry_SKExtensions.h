//
//  NSGeometry_SKExtensions.h
//  Skim
//
//  Created by Christiaan Hofman on 8/22/07.
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


static inline NSPoint SKIntegralPoint(NSPoint point) {
    return NSMakePoint(SKRound(point.x), SKRound(point.y));
}

static inline NSPoint SKAddPoints(NSPoint aPoint, NSPoint bPoint) {
    return NSMakePoint(aPoint.x + bPoint.x, aPoint.y + bPoint.y);
}

static inline NSPoint SKSubstractPoints(NSPoint aPoint, NSPoint bPoint) {
    return NSMakePoint(aPoint.x - bPoint.x, aPoint.y - bPoint.y);
}

static inline NSPoint SKBottomLeftPoint(NSRect rect) {
    return NSMakePoint(NSMinX(rect), NSMinY(rect));
}

static inline NSPoint SKBottomRightPoint(NSRect rect) {
    return NSMakePoint(NSMaxX(rect), NSMinY(rect));
}

static inline NSPoint SKTopLeftPoint(NSRect rect) {
    return NSMakePoint(NSMinX(rect), NSMaxY(rect));
}

static inline NSPoint SKTopRightPoint(NSRect rect) {
    return NSMakePoint(NSMaxX(rect), NSMaxY(rect));
}

static inline NSPoint SKCenterPoint(NSRect rect) {
    return NSMakePoint(NSMidX(rect), NSMidY(rect));
}

static inline NSSize SKMakeSquareSize(CGFloat width) {
    return NSMakeSize(width, width);
}

static inline NSRect SKRectFromPoints(NSPoint aPoint, NSPoint bPoint) {
    NSRect rect;
    rect.origin.x = SKMin(aPoint.x, bPoint.x);
    rect.origin.y = SKMin(aPoint.y, bPoint.y);
    rect.size.width = SKMax(aPoint.x, bPoint.x) - NSMinX(rect);
    rect.size.height = SKMax(aPoint.y, bPoint.y) - NSMinY(rect);
    return rect;
}

static inline NSRect SKIntegralRectFromPoints(NSPoint aPoint, NSPoint bPoint) {
    NSRect rect;
    rect.origin.x = SKFloor(SKMin(aPoint.x, bPoint.x));
    rect.origin.y = SKFloor(SKMin(aPoint.y, bPoint.y));
    rect.size.width = SKCeil(SKMax(aPoint.x, bPoint.x) - NSMinX(rect));
    rect.size.height = SKCeil(SKMax(aPoint.y, bPoint.y) - NSMinY(rect));
    return rect;
}

static inline NSRect SKRectFromCenterAndPoint(NSPoint center, NSPoint point) {
    NSRect rect;
    rect.size.width = 2.0 * SKAbs(center.x - point.x);
    rect.size.height = 2.0 * SKAbs(center.y - point.y);
    rect.origin.x = center.x - 0.5 * NSWidth(rect);
    rect.origin.y = center.y - 0.5 * NSHeight(rect);
    return rect;
}

static inline NSRect SKRectFromCenterAndSize(NSPoint center, NSSize size) {
    NSRect rect;
    rect.origin.x = center.x - 0.5 * size.width;
    rect.origin.y = center.y - 0.5 * size.height;
    rect.size = size;
    return rect;
}

#pragma mark -

extern NSPoint SKConstrainPointInRect(NSPoint point, NSRect boundary);
extern NSRect SKConstrainRect(NSRect rect, NSRect boundary);
extern NSRect SKIntersectionRect(NSRect rect, NSRect boundary);

extern NSRect SKCenterRect(NSRect rect, NSSize size, BOOL flipped);
extern NSRect SKCenterRectVertically(NSRect rect, CGFloat height, BOOL flipped);
extern NSRect SKCenterRectHorizontally(NSRect rect, CGFloat width);

#pragma mark -

extern BOOL SKPointNearLineFromPointToPoint(NSPoint point, NSPoint startPoint, NSPoint endPoint, CGFloat pointDelta, CGFloat lineDelta);

#pragma mark -

static inline
Rect SKQDRectFromNSRect(NSRect nsRect) {
    Rect qdRect;
    qdRect.left = SKRound(NSMinX(nsRect));
    qdRect.bottom = SKRound(NSMinY(nsRect));
    qdRect.right = SKRound(NSMaxX(nsRect));
    qdRect.top = SKRound(NSMaxY(nsRect));
    return qdRect;
}

static inline
NSRect SKNSRectFromQDRect(Rect qdRect) {
    NSRect nsRect;
    nsRect.origin.x = (CGFloat)qdRect.left;
    nsRect.origin.y = (CGFloat)qdRect.bottom;
    nsRect.size.width = (CGFloat)(qdRect.right - qdRect.left);
    nsRect.size.height = (CGFloat)(qdRect.top - qdRect.bottom);
    return nsRect;
}


static inline
Point SKQDPointFromNSPoint(NSPoint nsPoint) {
    Point qdPoint;
    qdPoint.h = SKRound(nsPoint.x);
    qdPoint.v = SKRound(nsPoint.y);
    return qdPoint;
}

static inline
NSPoint SKNSPointFromQDPoint(Point qdPoint) {
    NSPoint nsPoint;
    nsPoint.x = (CGFloat)qdPoint.h;
    nsPoint.y = (CGFloat)qdPoint.v;
    return nsPoint;
}
