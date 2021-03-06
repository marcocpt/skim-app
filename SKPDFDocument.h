//
//  SKPDFDocument.h
//  Skim
//
//  Created by Michael McCracken on 12/5/06.
/*
 This software is Copyright (c) 2006-2009
 Michael O. McCracken. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Michael O. McCracken nor the names of any
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

extern NSString *SKSkimFileDidSaveNotification;

enum {
    SKScriptingDisplaySinglePage = '1Pg ',
    SKScriptingDisplaySinglePageContinuous = '1PgC',
    SKScriptingDisplayTwoUp = '2Up ',
    SKScriptingDisplayTwoUpContinuous = '2UpC'
};

enum {
    SKScriptingMediaBox = 'Mdia',
    SKScriptingCropBox = 'Crop'
};


extern NSDictionary *SKScriptingPDFViewSettingsFromPDFViewSettings(NSDictionary *settings);
extern NSDictionary *SKPDFViewSettingsFromScriptingPDFViewSettings(NSDictionary *settings);


@class PDFDocument, SKMainWindowController, SKPDFView, SKPDFSynchronizer, SKLine, SKProgressController, SKTemporaryData;

@interface SKPDFDocument : NSDocument
{
    IBOutlet NSView *readNotesAccessoryView;
    IBOutlet NSButton *replaceNotesCheckButton;
    
    SKMainWindowController *mainWindowController;
    
    NSButton *autoRotateButton;
    
    // variables to be saved:
    NSData *pdfData;
    NSData *psOrDviData;
    
    // temporary variables:
    SKTemporaryData *tmpData;
    
    SKProgressController *progressController;
    
    SKPDFSynchronizer *synchronizer;
    NSString *watchedFile;
    
    struct _docFlags {
        unsigned int autoUpdate : 1;
        unsigned int disableAutoReload : 1;
        unsigned int isSaving : 1;
        unsigned int isUpdatingFile : 1;
        unsigned int receivedFileUpdateNotification : 1;
        unsigned int fileChangedOnDisk : 1;
        unsigned int exportUsingPanel : 1;
    } docFlags;
    
    // only used for network filesystems; fileUpdateTimer is not retained by the doc
    NSDate *lastModifiedDate;
    NSTimer *fileUpdateTimer;
}

- (void)undoableActionDoesntDirtyDocument;

- (IBAction)readNotes:(id)sender;
- (IBAction)convertNotes:(id)sender;
- (IBAction)saveArchive:(id)sender;
- (IBAction)saveDiskImage:(id)sender;
- (IBAction)emailArchive:(id)sender;
- (IBAction)emailDiskImage:(id)sender;

- (SKMainWindowController *)mainWindowController;
- (PDFDocument *)pdfDocument;

- (SKPDFView *)pdfView;

- (NSData *)notesData;
- (NSString *)notesFDFString;
- (NSString *)notesFDFStringForFile:(NSString *)filename;

- (NSArray *)fileIDStrings;

- (void)savePasswordInKeychain:(NSString *)password;

- (NSDictionary *)currentDocumentSetup;

- (void)applySetup:(NSDictionary *)setup;

- (SKPDFSynchronizer *)synchronizer;

- (NSArray *)snapshots;

- (NSArray *)tags;
- (double)rating;

- (NSArray *)pages;
- (NSUInteger)countOfPages;
- (PDFPage *)objectInPagesAtIndex:(NSUInteger)index;
- (NSArray *)notes;
- (void)insertInNotes:(PDFAnnotation *)newNote;
- (void)insertObject:(PDFAnnotation *)newNote inNotesAtIndex:(NSUInteger)anIndex;
- (void)removeObjectFromNotesAtIndex:(NSUInteger)anIndex;
- (PDFPage *)currentPage;
- (void)setCurrentPage:(PDFPage *)page;
- (id)activeNote;
- (void)setActiveNote:(id)note;
- (NSTextStorage *)richText;
- (id)selectionSpecifier;
- (void)setSelectionSpecifier:(id)specifier;
- (NSData *)selectionQDRect;
- (void)setSelectionQDRect:(NSData *)inQDBoundsAsData;
- (id)selectionPage;
- (void)setSelectionPage:(PDFPage *)page;
- (void)handleRevertScriptCommand:(NSScriptCommand *)command;
- (void)handleGoToScriptCommand:(NSScriptCommand *)command;
- (id)handleFindScriptCommand:(NSScriptCommand *)command;
- (void)handleShowTeXScriptCommand:(NSScriptCommand *)command;
- (void)handleConvertNotesScriptCommand:(NSScriptCommand *)command;

@end


@interface NSWindow (SKScriptingExtensions)
- (void)handleRevertScriptCommand:(NSScriptCommand *)command;
@end
