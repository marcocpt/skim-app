//
//  SKPreferenceController.h
//  Skim
//
//  Created by Christiaan Hofman on 2/10/07.
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

@class SKLineWell, SKFontWell;

@interface SKPreferenceController : NSWindowController {
    IBOutlet NSTabView *tabView;
    IBOutlet NSPopUpButton *updateIntervalPopUpButton;
    IBOutlet NSSlider *thumbnailSizeSlider;
    IBOutlet NSSlider *snapshotSizeSlider;
    IBOutlet NSPopUpButton *texEditorPopUpButton;
    IBOutlet NSButton *revertPDFSettingsButton;
    IBOutlet NSButton *revertFullScreenPDFSettingsButton;
    IBOutlet SKLineWell *textLineWell;
    IBOutlet SKLineWell *lineLineWell;
    IBOutlet SKLineWell *circleLineWell;
    IBOutlet SKLineWell *boxLineWell;
    IBOutlet SKLineWell *freehandLineWell;
    IBOutlet SKFontWell *textNoteFontWell;
    IBOutlet SKFontWell *anchoredNoteFontWell;
    NSDictionary *resettableKeys;
    BOOL isCustomTeXEditor;
    NSInteger updateInterval;
    NSUserDefaults *sud;
    NSUserDefaultsController *sudc;
}

+ (id)sharedPrefenceController;

- (NSUInteger)countOfSizes;
- (NSNumber *)objectInSizesAtIndex:(NSUInteger)anIndex;

- (BOOL)isCustomTeXEditor;
- (void)setCustomTeXEditor:(BOOL)flag;

- (NSInteger)updateInterval;
- (void)setUpdateInterval:(NSInteger)interval;

- (IBAction)changeDiscreteThumbnailSizes:(id)sender;
- (IBAction)changeTeXEditorPreset:(id)sender;

- (IBAction)revertPDFViewSettings:(id)sender;
- (IBAction)revertFullScreenPDFViewSettings:(id)sender;

- (IBAction)changeFont:(id)sender;
- (IBAction)changeAttributes:(id)sender;

- (IBAction)resetAll:(id)sender;
- (IBAction)resetCurrent:(id)sender;

@end
