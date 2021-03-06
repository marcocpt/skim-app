//
//  SKDocumentController.h
//  Skim
//
//  Created by Christiaan Hofman on 5/21/07.
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

// these functions are compatible for 10.4 and 10.5

extern BOOL SKIsPDFDocumentType(NSString *docType);
extern BOOL SKIsPDFBundleDocumentType(NSString *docType);
extern BOOL SKIsEmbeddedPDFDocumentType(NSString *docType);
extern BOOL SKIsBarePDFDocumentType(NSString *docType);
extern BOOL SKIsNotesDocumentType(NSString *docType);
extern BOOL SKIsNotesTextDocumentType(NSString *docType);
extern BOOL SKIsNotesRTFDocumentType(NSString *docType);
extern BOOL SKIsNotesRTFDDocumentType(NSString *docType);
extern BOOL SKIsNotesFDFDocumentType(NSString *docType);
extern BOOL SKIsPostScriptDocumentType(NSString *docType);
extern BOOL SKIsBarePostScriptDocumentType(NSString *docType);
extern BOOL SKIsDVIDocumentType(NSString *docType);
extern BOOL SKIsBareDVIDocumentType(NSString *docType);
extern BOOL SKIsFolderDocumentType(NSString *docType);

extern NSString *SKNormalizedDocumentType(NSString *docType);

extern NSString *SKPDFDocumentType;
extern NSString *SKPDFBundleDocumentType;
extern NSString *SKEmbeddedPDFDocumentType;
extern NSString *SKBarePDFDocumentType;
extern NSString *SKNotesDocumentType;
extern NSString *SKNotesTextDocumentType;
extern NSString *SKNotesRTFDocumentType;
extern NSString *SKNotesRTFDDocumentType;
extern NSString *SKNotesFDFDocumentType;
extern NSString *SKPostScriptDocumentType;
extern NSString *SKBarePostScriptDocumentType;
extern NSString *SKDVIDocumentType;
extern NSString *SKBareDVIDocumentType;
extern NSString *SKFolderDocumentType;

extern NSString *SKDocumentSetupAliasKey;
extern NSString *SKDocumentSetupFileNameKey;

extern NSString *SKDocumentControllerDidAddDocumentNotification;
extern NSString *SKDocumentControllerDidRemoveDocumentNotification;
extern NSString *SKDocumentDidShowNotification;

@interface SKDocumentController : NSDocumentController {
    NSArray *customExportTemplateFiles;
}

- (void)newDocumentFromClipboard:(id)sender;
// this method may return an SKDownload instance
- (id)openDocumentWithContentsOfPasteboard:(NSPasteboard *)pboard error:(NSError **)outError;
- (id)openDocumentWithImageFromPasteboard:(NSPasteboard *)pboard error:(NSError **)outError;
// this method may return an SKDownload instance
- (id)openDocumentWithURLFromPasteboard:(NSPasteboard *)pboard error:(NSError **)outError;
- (id)openDocumentWithSetup:(NSDictionary *)setup error:(NSError **)outError;

- (NSArray *)customExportTemplateFiles;
- (NSArray *)customExportTemplateFilesResetting;

@end
