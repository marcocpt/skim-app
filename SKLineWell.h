//
//  SKLineWell.h
//  Skim
//
//  Created by Christiaan Hofman on 6/22/07.
/*
 This software is Copyright (c) 2007-2008
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
#import <Quartz/Quartz.h>

extern NSString *SKLineStylePboardType;

extern NSString *SKLineWellLineWidthKey;
extern NSString *SKLineWellStyleKey;
extern NSString *SKLineWellDashPatternKey;
extern NSString *SKLineWellStartLineStyleKey;
extern NSString *SKLineWellEndLineStyleKey;

typedef enum _SKLineWellDisplayStyle {
    SKLineWellDisplayStyleLine,
    SKLineWellDisplayStyleRectangle,
    SKLineWellDisplayStyleOval
} SKLineWellDisplayStyle;

@interface SKLineWell : NSControl {
    float lineWidth;
    PDFBorderStyle style;
    NSArray *dashPattern;
    PDFLineStyle startLineStyle;
    PDFLineStyle endLineStyle;
    SKLineWellDisplayStyle displayStyle;
    BOOL active;
    BOOL canActivate;
    BOOL isHighlighted;
    BOOL existsActiveLineWell;
    
    id target;
    SEL action;
    
    NSMutableDictionary *bindingInfo;
    
    BOOL updatingFromLineInspector;
    BOOL updatingFromBinding;
    
    id titleUIElement;
}

- (void)activate:(BOOL)exclusive;
- (void)deactivate;

- (BOOL)isActive;

- (BOOL)canActivate;
- (void)setCanActivate:(BOOL)flag;

- (BOOL)isHighlighted;
- (void)setHighlighted:(BOOL)flag;

- (SKLineWellDisplayStyle)displayStyle;
- (void)setDisplayStyle:(SKLineWellDisplayStyle)newStyle;

- (float)lineWidth;
- (void)setLineWidth:(float)width;
- (PDFBorderStyle)style;
- (void)setStyle:(PDFBorderStyle)newStyle;
- (NSArray *)dashPattern;
- (void)setDashPattern:(NSArray *)pattern;

- (PDFLineStyle)startLineStyle;
- (void)setStartLineStyle:(PDFLineStyle)newStyle;
- (PDFLineStyle)endLineStyle;
- (void)setEndLineStyle:(PDFLineStyle)newStyle;

- (void)lineInspectorLineWidthChanged:(NSNotification *)notification;
- (void)lineInspectorLineStyleChanged:(NSNotification *)notification;
- (void)lineInspectorDashPatternChanged:(NSNotification *)notification;
- (void)lineInspectorStartLineStyleChanged:(NSNotification *)notification;
- (void)lineInspectorEndLineStyleChanged:(NSNotification *)notification;

@end
