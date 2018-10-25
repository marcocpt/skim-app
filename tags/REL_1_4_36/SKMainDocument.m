//
//  SKMainDocument.m
//  Skim
//
//  Created by Michael McCracken on 12/5/06.
/*
 This software is Copyright (c) 2006-2018
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

#import "SKMainDocument.h"
#import <Quartz/Quartz.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SkimNotes/SkimNotes.h>
#import "SKMainWindowController.h"
#import "SKMainWindowController_Actions.h"
#import "SKPDFDocument.h"
#import "PDFAnnotation_SKExtensions.h"
#import "SKNPDFAnnotationNote_SKExtensions.h"
#import "SKConversionProgressController.h"
#import "SKFindController.h"
#import "NSUserDefaultsController_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKPDFView.h"
#import "SKNoteWindowController.h"
#import "SKPDFSynchronizer.h"
#import "NSString_SKExtensions.h"
#import "SKDocumentController.h"
#import "SKTemplateParser.h"
#import "SKApplicationController.h"
#import "PDFSelection_SKExtensions.h"
#import "SKInfoWindowController.h"
#import "SKLine.h"
#import "SKApplicationController.h"
#import "NSFileManager_SKExtensions.h"
#import "SKFDFParser.h"
#import "NSData_SKExtensions.h"
#import "SKProgressController.h"
#import "NSView_SKExtensions.h"
#import "SKKeychain.h"
#import "SKBookmarkController.h"
#import "PDFPage_SKExtensions.h"
#import "NSGeometry_SKExtensions.h"
#import "SKSnapshotWindowController.h"
#import "NSDocument_SKExtensions.h"
#import "SKApplication.h"
#import "NSResponder_SKExtensions.h"
#import "SKTextFieldSheetController.h"
#import "PDFAnnotationMarkup_SKExtensions.h"
#import "NSWindowController_SKExtensions.h"
#import "NSInvocation_SKExtensions.h"
#import "SKSyncPreferences.h"
#import "NSScreen_SKExtensions.h"
#import "NSURL_SKExtensions.h"
#import "SKFileUpdateChecker.h"
#import "NSError_SKExtensions.h"
#import "PDFDocument_SKExtensions.h"
#import "SKPrintAccessoryController.h"
#import "SKTemporaryData.h"
#import "SKTemplateManager.h"
#import "SKExportAccessoryController.h"
#import "SKAttachmentEmailer.h"
#import "SKAnimatedBorderlessWindow.h"
#import "PDFOutline_SKExtensions.h"

#define BUNDLE_DATA_FILENAME @"data"
#define PRESENTATION_OPTIONS_KEY @"net_sourceforge_skim-app_presentation_options"
#define OPEN_META_TAGS_KEY @"com.apple.metadata:kMDItemOMUserTags"
#define OPEN_META_RATING_KEY @"com.apple.metadata:kMDItemStarRating"

NSString *SKSkimFileDidSaveNotification = @"SKSkimFileDidSaveNotification";

#define SKLastExportedTypeKey @"SKLastExportedType"
#define SKLastExportedOptionKey @"SKLastExportedOption"

#define URL_KEY             @"URL"
#define TYPE_KEY            @"type"
#define SAVEOPERATION_KEY   @"saveOperation"
#define CALLBACK_KEY        @"callback"
#define TMPURL_KEY          @"tmpURL"
#define SKIMNOTES_KEY       @"skimNotes"
#define SKIMTEXTNOTES_KEY   @"skimTextNotes"
#define SKIMRTFNOTES_KEY    @"skimRTFNotes"

#define SOURCEURL_KEY   @"sourceURL"
#define TARGETURL_KEY   @"targetURL"
#define EMAIL_KEY       @"email"

#define SKPresentationOptionsKey    @"PresentationOptions"
#define SKTagsKey                   @"Tags"
#define SKRatingKey                 @"Rating"

static NSString *SKPDFPasswordServiceName = @"Skim PDF password";

enum {
    SKExportOptionDefault,
    SKExportOptionWithoutNotes,
    SKExportOptionWithEmbeddedNotes,
};

enum {
   SKArchiveDiskImageMask = 1,
   SKArchiveEmailMask = 2,
};

enum {
    SKOptionAsk = -1,
    SKOptionNever = 0,
    SKOptionAlways = 1
};


@interface PDFAnnotation (SKPrivateDeclarations)
- (void)setPage:(PDFPage *)newPage;
@end

@interface NSSavePanel (SKPrivateDeclarations)
- (void)toggleOptionsView:(id)sender;
@end

@interface PDFDocument (SKPrivateDeclarations)
- (NSPrintOperation *)getPrintOperationForPrintInfo:(NSPrintInfo *)printInfo autoRotate:(BOOL)autoRotate;
- (NSString *)passwordUsedForUnlocking;
@end

#if SDK_BEFORE(10_7)
@interface PDFDocument (SKLionDeclarations)
- (NSPrintOperation *)printOperationForPrintInfo:(NSPrintInfo *)printInfo scalingMode:(PDFPrintScalingMode)scalingMode autoRotate:(BOOL)autoRotate;
@end

@interface NSDocument (SKLionDeclarations)
- (void)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation completionHandler:(void (^)(NSError *))completionHandler;
@end
#endif

@interface NSDocument (SKPrivateDeclarations)
// private method used as the action for the file format popup in the save panel, decalred so we can override
- (void)changeSaveType:(id)sender;
@end

@interface SKMainDocument (SKPrivate)

- (void)tryToUnlockDocument:(PDFDocument *)document;

- (void)handleWindowWillCloseNotification:(NSNotification *)notification;

- (SKPasswordStatus)getPDFPassword:(NSString **)password item:(id *)itemRef forFileID:(NSString *)fileID;
- (void)setPDFPassword:(NSString *)password item:(id)itemRef forFileID:(NSString *)fileID;

@end

#pragma mark -

@implementation SKMainDocument

@synthesize mainWindowController;
@dynamic pdfDocument, pdfView, synchronizer, snapshots, tags, rating, currentPage, activeNote, richText, selectionSpecifier, selectionQDRect,selectionPage, pdfViewSettings;

+ (BOOL)isPDFDocument { return YES; }

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // shouldn't need this here, but better be safe
    if (fileUpdateChecker)
        SKENSURE_MAIN_THREAD( [fileUpdateChecker terminate]; );
    SKDESTROY(fileUpdateChecker);
    SKDESTROY(synchronizer);
    SKDESTROY(mainWindowController);
    SKDESTROY(pdfData);
    SKDESTROY(originalData);
    SKDESTROY(tmpData);
    SKDESTROY(pageOffsets);
    [super dealloc];
}

- (void)makeWindowControllers{
    mainWindowController = [[SKMainWindowController alloc] init];
    [mainWindowController setShouldCloseDocument:YES];
    [self addWindowController:mainWindowController];
}

- (void)setDataFromTmpData {
    PDFDocument *pdfDoc = [tmpData pdfDocument];
    
    mdFlags.needsPasswordToConvert = [pdfDoc allowsPrinting] == NO || [pdfDoc allowsNotes];
    
    [self tryToUnlockDocument:pdfDoc];
    
    [[self mainWindowController] setPdfDocument:pdfDoc];
    
    [[self mainWindowController] addAnnotationsFromDictionaries:[tmpData noteDicts] removeAnnotations:[self notes] autoUpdate:NO];
    
    if ([tmpData presentationOptions])
        [[self mainWindowController] setPresentationOptions:[tmpData presentationOptions]];
    
    [[self mainWindowController] setTags:[tmpData openMetaTags]];
    
    [[self mainWindowController] setRating:[tmpData openMetaRating]];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController{
    [[self undoManager] disableUndoRegistration];
    
    // set a copy, because we change the printInfo, and we don't want to change the shared instance
    [self setPrintInfo:[[[super printInfo] copy] autorelease]];
    
    [self setDataFromTmpData];
    SKDESTROY(tmpData);
    
    [[self undoManager] enableUndoRegistration];
    
    fileUpdateChecker = [[SKFileUpdateChecker alloc] initForDocument:self];
    // the file update checker starts disabled, setting enabled will start checking if it should
    [fileUpdateChecker setEnabled:YES];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowWillCloseNotification:) 
                                                 name:NSWindowWillCloseNotification object:[[self mainWindowController] window]];
}

- (void)showWindows{
    BOOL wasVisible = [[self mainWindowController] isWindowLoaded] && [[[self mainWindowController] window] isVisible];
    
    [super showWindows];
    
    // Get the search string keyword if available (Spotlight passes this)
    NSAppleEventDescriptor *event = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
    NSString *searchString;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKDisableSearchAfterSpotlighKey] == NO &&
        [event eventID] == kAEOpenDocuments && 
        (searchString = [[event descriptorForKeyword:keyAESearchText] stringValue]) && 
        [@"" isEqualToString:searchString] == NO) {
        if ([searchString length] > 2 && [searchString characterAtIndex:0] == '"' && [searchString characterAtIndex:[searchString length] - 1] == '"') {
            //strip quotes
            searchString = [searchString substringWithRange:NSMakeRange(1, [searchString length] - 2)];
        } else {
            // strip extra search criteria
            NSRange range = [searchString rangeOfString:@":"];
            if (range.location != NSNotFound) {
                range = [searchString rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
                if (range.location != NSNotFound && range.location > 0)
                    searchString = [searchString substringWithRange:NSMakeRange(0, range.location)];
            }
        }
        [[self mainWindowController] displaySearchResultsForString:searchString];
    }
    
    if (wasVisible == NO) {
        // currently PDFView on 10.9 and later initially doesn't display the PDF, messing around like this is a workaround for this bug
        if (RUNNING(10_9)) {
            [[self mainWindowController] toggleStatusBar:nil];
            [[self mainWindowController] toggleStatusBar:nil];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentDidShowNotification object:self];
    }
}

- (void)removeWindowController:(NSWindowController *)windowController {
    if ([windowController isEqual:mainWindowController]) {
        // if the window delegate is nil, windowWillClose: has already cleaned up, and should have called saveRecentDocumentInfo
        // otherwise, windowWillClose: comes after this (as it did on Tiger) and we need to do this now
        if ([mainWindowController isWindowLoaded] && [[mainWindowController window] delegate])
            [self saveRecentDocumentInfo];
        SKDESTROY(mainWindowController);
    }
    [super removeWindowController:windowController];
}

- (void)saveRecentDocumentInfo {
    NSURL *fileURL = [self fileURL];
    NSUInteger pageIndex = [[[self pdfView] currentPage] pageIndex];
    if (fileURL && pageIndex != NSNotFound && [self mainWindowController])
        [[SKBookmarkController sharedBookmarkController] addRecentDocumentForURL:fileURL pageIndex:pageIndex snapshots:[[[self mainWindowController] snapshots] valueForKey:SKSnapshotCurrentSetupKey]];
}

#pragma mark Writing

- (NSString *)fileType {
    mdFlags.gettingFileType = YES;
    NSString *fileType = [super fileType];
    mdFlags.gettingFileType = NO;
    return fileType;
}

- (NSArray *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation {
    if (mdFlags.gettingFileType)
        return [super writableTypesForSaveOperation:saveOperation];
    NSMutableArray *writableTypes = [[[super writableTypesForSaveOperation:saveOperation] mutableCopy] autorelease];
    NSString *type = [self fileType];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    if ([ws type:type conformsToType:SKEncapsulatedPostScriptDocumentType] == NO)
        [writableTypes removeObject:SKEncapsulatedPostScriptDocumentType];
    else
        [writableTypes removeObject:SKPostScriptDocumentType];
    if ([ws type:type conformsToType:SKPostScriptDocumentType] == NO)
        [writableTypes removeObject:SKPostScriptDocumentType];
    if ([ws type:type conformsToType:SKDVIDocumentType] == NO)
        [writableTypes removeObject:SKDVIDocumentType];
    if ([ws type:type conformsToType:SKXDVDocumentType] == NO)
        [writableTypes removeObject:SKXDVDocumentType];
    if (saveOperation == NSSaveToOperation) {
        [[SKTemplateManager sharedManager] resetCustomTemplateTypes];
        [writableTypes addObjectsFromArray:[[SKTemplateManager sharedManager] customTemplateTypes]];
    }
    return writableTypes;
}

- (NSString *)fileNameExtensionForType:(NSString *)typeName saveOperation:(NSSaveOperationType)saveOperation {
    return [super fileNameExtensionForType:typeName saveOperation:saveOperation] ?: [[SKTemplateManager sharedManager] fileNameExtensionForTemplateType:typeName];
}

- (BOOL)canAttachNotesForType:(NSString *)typeName {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    return ([ws type:typeName conformsToType:SKPDFDocumentType] || 
            [ws type:typeName conformsToType:SKPostScriptDocumentType] || 
            [ws type:typeName conformsToType:SKDVIDocumentType] || 
            [ws type:typeName conformsToType:SKXDVDocumentType]);
}

- (void)updateExportAccessoryView {
    NSString *typeName = [self fileTypeFromLastRunSavePanel];
    NSMatrix *matrix = [exportAccessoryController matrix];
    [matrix selectCellWithTag:mdFlags.exportOption];
    if ([self canAttachNotesForType:typeName]) {
        [matrix setHidden:NO];
        if ([[NSWorkspace sharedWorkspace] type:typeName conformsToType:SKPDFDocumentType] && ([[self pdfDocument] isLocked] == NO && [[self pdfDocument] allowsPrinting])) {
            [[matrix cellWithTag:SKExportOptionWithEmbeddedNotes] setEnabled:YES];
        } else {
            [[matrix cellWithTag:SKExportOptionWithEmbeddedNotes] setEnabled:NO];
            if (mdFlags.exportOption == SKExportOptionWithEmbeddedNotes) {
                mdFlags.exportOption = SKExportOptionDefault;
                [matrix selectCellWithTag:SKExportOptionDefault];
            }
        }
    } else {
        [matrix setHidden:YES];
    }
}

- (void)changeSaveType:(id)sender {
    if ([NSDocument instancesRespondToSelector:_cmd])
        [super changeSaveType:sender];
    if (mdFlags.exportUsingPanel && exportAccessoryController)
        [self updateExportAccessoryView];
}

- (void)changeExportOption:(id)sender {
    mdFlags.exportOption = [[sender selectedCell] tag];
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {
    BOOL success = [super prepareSavePanel:savePanel];
    if (success && mdFlags.exportUsingPanel) {
        NSPopUpButton *formatPopup = [[savePanel accessoryView] subviewOfClass:[NSPopUpButton class]];
        if (formatPopup) {
            NSString *lastExportedType = [[NSUserDefaults standardUserDefaults] stringForKey:SKLastExportedTypeKey];
            NSInteger lastExportedOption = [[NSUserDefaults standardUserDefaults] integerForKey:SKLastExportedOptionKey];
            if (lastExportedType) {
                NSInteger idx = [formatPopup indexOfItemWithRepresentedObject:lastExportedType];
                if (idx != -1 && idx != [formatPopup indexOfSelectedItem]) {
                    [formatPopup selectItemAtIndex:idx];
                    [formatPopup sendAction:[formatPopup action] to:[formatPopup target]];
                    [savePanel setAllowedFileTypes:[NSArray arrayWithObjects:[self fileNameExtensionForType:lastExportedType saveOperation:NSSaveToOperation], nil]];
                }
            }
            mdFlags.exportOption = lastExportedOption;
            
            exportAccessoryController = [[SKExportAccessoryController alloc] init];
            [exportAccessoryController addFormatPopUpButton:formatPopup];
            [[exportAccessoryController matrix] setTarget:self];
            [[exportAccessoryController matrix] setAction:@selector(changeExportOption:)];
            [savePanel setAccessoryView:[exportAccessoryController view]];
            [self updateExportAccessoryView];
        }
    }
    return success;
}

- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    // Override so we can determine if this is a save, saveAs or export operation, so we can prepare the correct accessory view
    mdFlags.exportUsingPanel = (saveOperation == NSSaveToOperation);
    // Should already be reset long ago, just to be sure
    mdFlags.exportOption = SKExportOptionDefault;
    [super runModalSavePanelForSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

- (NSArray *)SkimNoteProperties {
    NSArray *array = [[self notes] valueForKey:@"SkimNoteProperties"];
    if (pageOffsets != nil) {
        NSMutableArray *mutableArray = [NSMutableArray array];
        for (NSDictionary *dict in array) {
            NSUInteger pageIndex = [[dict objectForKey:SKNPDFAnnotationPageIndexKey] unsignedIntegerValue];
            NSPointPointer offsetPtr = NSMapGet(pageOffsets, (const void *)pageIndex);
            if (offsetPtr != NULL) {
                NSMutableDictionary *mutableDict = [dict mutableCopy];
                NSRect bounds = NSRectFromString([dict objectForKey:SKNPDFAnnotationBoundsKey]);
                bounds.origin.x -= offsetPtr->x;
                bounds.origin.y -= offsetPtr->y;
                [mutableDict setObject:NSStringFromRect(bounds) forKey:SKNPDFAnnotationBoundsKey];
                [mutableArray addObject:mutableDict];
                [mutableDict release];
            } else {
                [mutableArray addObject:dict];
            }
        }
        array = mutableArray;
    }
    return  array;
}

#ifdef __LP64__
#define PERMISSIONS_MODE(catalogInfo) catalogInfo.permissions.mode
#else
#define PERMISSIONS_MODE(catalogInfo) ((FSPermissionInfo *)catalogInfo.permissions)->mode
#endif

- (void)saveNotesToURL:(NSURL *)absoluteURL forSaveOperation:(NSSaveOperationType)saveOperation {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL saveNotesOK = NO;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKAutoSaveSkimNotesKey]) {
        NSURL *notesURL = [absoluteURL URLReplacingPathExtension:@"skim"];
        BOOL fileExists = [notesURL checkResourceIsReachableAndReturnError:NULL];
        
        if (fileExists && (saveOperation == NSSaveAsOperation || saveOperation == NSSaveToOperation)) {
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" already exists. Do you want to replace it?", @"Message in alert dialog"), [notesURL lastPathComponent]]];
            [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"A file or folder with the same name already exists in %@. Replacing it will overwrite its current contents.", @"Informative text in alert dialog"), [[notesURL URLByDeletingLastPathComponent] lastPathComponent]]];
            [alert addButtonWithTitle:NSLocalizedString(@"Save", @"Button title")];
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Button title")];
            
            saveNotesOK = NSAlertFirstButtonReturn == [alert runModal];
        } else {
            saveNotesOK = YES;
        }
        
        if (saveNotesOK) {
            if ([[self notes] count] > 0)
                saveNotesOK = [self writeSafelyToURL:notesURL ofType:SKNotesDocumentType forSaveOperation:NSSaveToOperation error:NULL];
            else if (fileExists)
                saveNotesOK = [fm removeItemAtURL:notesURL error:NULL];
        }
    }
    
    FSRef fileRef;
    FSCatalogInfo catalogInfo;
    FSCatalogInfoBitmap whichInfo = kFSCatInfoNone;
    
    if (CFURLGetFSRef((CFURLRef)absoluteURL, &fileRef) &&
        noErr == FSGetCatalogInfo(&fileRef, kFSCatInfoNodeFlags | kFSCatInfoPermissions, &catalogInfo, NULL, NULL, NULL)) {
        
        FSCatalogInfo tmpCatalogInfo = catalogInfo;
        if ((catalogInfo.nodeFlags & kFSNodeLockedMask) != 0) {
            tmpCatalogInfo.nodeFlags &= ~kFSNodeLockedMask;
            whichInfo |= kFSCatInfoNodeFlags;
        }
        if ((PERMISSIONS_MODE(catalogInfo) & S_IWUSR) == 0) {
            PERMISSIONS_MODE(tmpCatalogInfo) |= S_IWUSR;
            whichInfo |= kFSCatInfoPermissions;
        }
        if (whichInfo != kFSCatInfoNone)
            (void)FSSetCatalogInfo(&fileRef, whichInfo, &tmpCatalogInfo);
    }
    
    if (NO == [fm writeSkimNotes:[self SkimNoteProperties] textNotes:[self notesString] richTextNotes:[self notesRTFData] toExtendedAttributesAtURL:absoluteURL error:NULL]) {
        NSString *message = saveNotesOK ? NSLocalizedString(@"The notes could not be saved with the PDF at \"%@\". However a companion .skim file was successfully updated.", @"Informative text in alert dialog") :
                                          NSLocalizedString(@"The notes could not be saved with the PDF at \"%@\"", @"Informative text in alert dialog");
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:NSLocalizedString(@"Unable to save notes", @"Message in alert dialog")];
        [alert setInformativeText:[NSString stringWithFormat:message, [absoluteURL lastPathComponent]]];
        [alert runModal];
    }
    
    NSDictionary *options = [[self mainWindowController] presentationOptions];
    [[SKNExtendedAttributeManager sharedManager] removeExtendedAttributeNamed:PRESENTATION_OPTIONS_KEY atPath:[absoluteURL path] traverseLink:YES error:NULL];
    if (options)
        [[SKNExtendedAttributeManager sharedManager] setExtendedAttributeNamed:PRESENTATION_OPTIONS_KEY toPropertyListValue:options atPath:[absoluteURL path] options:kSKNXattrDefault error:NULL];
    
    if (whichInfo != kFSCatInfoNone)
        (void)FSSetCatalogInfo(&fileRef, whichInfo, &catalogInfo);
}

- (void)document:(NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo {
    NSDictionary *info = [(id)contextInfo autorelease];
    NSSaveOperationType saveOperation = [[info objectForKey:SAVEOPERATION_KEY] unsignedIntegerValue];
    NSURL *tmpURL = [info objectForKey:TMPURL_KEY];
    
    if (didSave) {
        NSURL *absoluteURL = [info objectForKey:URL_KEY];
        NSString *typeName = [info objectForKey:TYPE_KEY];
        
        if ([self canAttachNotesForType:typeName] && mdFlags.exportOption == SKExportOptionDefault) {
            // we check for notes and may save a .skim as well:
            [self saveNotesToURL:absoluteURL forSaveOperation:saveOperation];
        } else if ([[NSWorkspace sharedWorkspace] type:typeName conformsToType:SKPDFBundleDocumentType] && tmpURL) {
            // move extra package content like version info to the new location
            NSFileManager *fm = [NSFileManager defaultManager];
            for (NSURL *url in [fm contentsOfDirectoryAtURL:tmpURL includingPropertiesForKeys:nil options:0 error:NULL])
                [fm moveItemAtURL:url toURL:[absoluteURL URLByAppendingPathComponent:[url lastPathComponent]] error:NULL];
        }
    
        if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
            [[self undoManager] removeAllActions];
            [self updateChangeCount:NSChangeCleared];
            [fileUpdateChecker didUpdateFromURL:[self fileURL]];
        }
    
        if ([[self class] isNativeType:typeName] && saveOperation < NSAutosaveOperation)
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:SKSkimFileDidSaveNotification object:[absoluteURL path]];
    } else if (saveOperation == NSSaveOperation) {
        NSArray *skimNotes = [info objectForKey:SKIMNOTES_KEY];
        NSString *textNotes = [info objectForKey:SKIMTEXTNOTES_KEY];
        NSData *rtfNotes = [info objectForKey:SKIMRTFNOTES_KEY];
        if (skimNotes)
            [[NSFileManager defaultManager] writeSkimNotes:skimNotes textNotes:textNotes richTextNotes:rtfNotes toExtendedAttributesAtURL:[self fileURL] error:NULL];
    }
    
    if (tmpURL)
        [[NSFileManager defaultManager] removeItemAtURL:tmpURL error:NULL];
    
    if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
        [fileUpdateChecker setEnabled:YES];
    }
    
    // in case we saved using the panel we should reset this for the next save
    mdFlags.exportUsingPanel = NO;
    mdFlags.exportOption = SKExportOptionDefault;
    
    SKDESTROY(exportAccessoryController);
    
    NSInvocation *invocation = [info objectForKey:CALLBACK_KEY];
    if (invocation) {
        [invocation setArgument:&doc atIndex:2];
        [invocation setArgument:&didSave atIndex:3];
        [invocation invoke];
    }
}

- (NSDictionary *)prepareForSaveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    if (saveOperation == NSSaveOperation || saveOperation == NSSaveAsOperation) {
        [fileUpdateChecker setEnabled:NO];
    } else if (saveOperation == NSSaveToOperation && mdFlags.exportUsingPanel) {
        [[NSUserDefaults standardUserDefaults] setObject:typeName forKey:SKLastExportedTypeKey];
        [[NSUserDefaults standardUserDefaults] setInteger:[self canAttachNotesForType:typeName] ? mdFlags.exportOption : SKExportOptionDefault forKey:SKLastExportedOptionKey];
    }
    // just to make sure
    if (saveOperation != NSSaveToOperation)
        mdFlags.exportOption = SKExportOptionDefault;
    
    NSURL *destURL = [absoluteURL filePathURL];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:typeName, TYPE_KEY, [NSNumber numberWithUnsignedInteger:saveOperation], SAVEOPERATION_KEY, destURL, URL_KEY, nil];
    if (delegate && didSaveSelector) {
        NSInvocation *invocation = [NSInvocation invocationWithTarget:delegate selector:didSaveSelector];
        [invocation setArgument:&contextInfo atIndex:4];
        [info setObject:invocation forKey:CALLBACK_KEY];
    }
    
    if ([ws type:typeName conformsToType:SKPDFBundleDocumentType] && [ws type:[self fileType] conformsToType:SKPDFBundleDocumentType] && [self fileURL] && saveOperation != NSSaveToOperation && saveOperation != NSAutosaveOperation) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *fileURL = [self fileURL];
        NSURL *tmpURL = nil;
        // we move everything that's not ours out of the way, so we can preserve version control info
        NSSet *ourExtensions = [NSSet setWithObjects:@"pdf", @"skim", @"fdf", @"txt", @"text", @"rtf", @"plist", nil];
        for (NSURL *url in [fm contentsOfDirectoryAtURL:fileURL includingPropertiesForKeys:nil options:0 error:NULL]) {
            if ([ourExtensions containsObject:[[url pathExtension] lowercaseString]] == NO) {
                if (tmpURL == nil)
                    tmpURL = [fm URLForDirectory:NSItemReplacementDirectory inDomain:NSUserDomainMask appropriateForURL:fileURL create:YES error:NULL];
                [fm copyItemAtURL:url toURL:[tmpURL URLByAppendingPathComponent:[url lastPathComponent]] error:NULL];
            }
        }
        if (tmpURL)
            [info setObject:tmpURL forKey:TMPURL_KEY];
    }
    
    // There seems to be a bug on 10.9 when saving to an existing file that has a lot of extended attributes
    if (RUNNING_AFTER(10_8) && [self canAttachNotesForType:typeName] && [self fileURL] && saveOperation == NSSaveOperation) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *fileURL = [self fileURL];
        NSArray *skimNotes = [fm readSkimNotesFromExtendedAttributesAtURL:fileURL error:NULL];
        NSString *textNotes = [fm readSkimTextNotesFromExtendedAttributesAtURL:fileURL error:NULL];
        NSData *rtfNotes = [fm readSkimRTFNotesFromExtendedAttributesAtURL:fileURL error:NULL];
        [fm writeSkimNotes:nil textNotes:nil richTextNotes:nil toExtendedAttributesAtURL:fileURL error:NULL];
        if (skimNotes)
            [info setObject:skimNotes forKey:SKIMNOTES_KEY];
        if (textNotes)
            [info setObject:textNotes forKey:SKIMTEXTNOTES_KEY];
        if (rtfNotes)
            [info setObject:rtfNotes forKey:SKIMRTFNOTES_KEY];
    }
    
    return info;
}

// Prepare for saving and use callback to save notes and cleanup
// On 10.7+ all save operations go through this method, so we use this
- (void)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation completionHandler:(void (^)(NSError *))completionHandler {
    
    NSDictionary *info = [self prepareForSaveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation delegate:nil didSaveSelector:NULL contextInfo:NULL];
    
    [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation completionHandler:^(NSError *errorOrNil){
        [self document:self didSave:errorOrNil == nil contextInfo:[info retain]];
        if (completionHandler)
            completionHandler(errorOrNil);
    }];
}

// On 10.6 the above block method does not exist, and instead all save operations should go through this method
// We can't use this on 10.7+ because autosave doesn't seem to use it
// Don't use -saveToURL:ofType:forSaveOperation:error:, because that may return before the actual saving when NSDocument needs to ask the user for permission, for instance to override a file lock
- (void)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
    
    if ([NSDocument instancesRespondToSelector:@selector(saveToURL:ofType:forSaveOperation:completionHandler:)] == NO) {
        NSDictionary *info = [self prepareForSaveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
        
        delegate = self;
        didSaveSelector = @selector(document:didSave:contextInfo:);
        contextInfo = [info retain];
    }
    
    [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

- (NSFileWrapper *)PDFBundleFileWrapperForName:(NSString *)name {
    if ([name isCaseInsensitiveEqual:BUNDLE_DATA_FILENAME])
        name = [name stringByAppendingString:@"1"];
    NSData *data;
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:[NSDictionary dictionary]];
    NSDictionary *info = [[SKInfoWindowController sharedInstance] infoForDocument:self];
    NSDictionary *options = [[self mainWindowController] presentationOptions];
    if (options) {
        info = [[info mutableCopy] autorelease];
        [(NSMutableDictionary *)info setObject:options forKey:SKPresentationOptionsKey];
    }
    [fileWrapper addRegularFileWithContents:pdfData preferredFilename:[name stringByAppendingPathExtension:@"pdf"]];
    if ((data = [[[self pdfDocument] string] dataUsingEncoding:NSUTF8StringEncoding]))
        [fileWrapper addRegularFileWithContents:data preferredFilename:[BUNDLE_DATA_FILENAME stringByAppendingPathExtension:@"txt"]];
    if ((data = [NSPropertyListSerialization dataWithPropertyList:info format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL]))
        [fileWrapper addRegularFileWithContents:data preferredFilename:[BUNDLE_DATA_FILENAME stringByAppendingPathExtension:@"plist"]];
    if ([[self notes] count] > 0) {
        if ((data = [self notesData]))
            [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"skim"]];
        if ((data = [[self notesString] dataUsingEncoding:NSUTF8StringEncoding]))
            [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"txt"]];
        if ((data = [self notesRTFData]))
            [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"rtf"]];
        if ((data = [self notesFDFDataForFile:[name stringByAppendingPathExtension:@"pdf"] fileIDStrings:[[self pdfDocument] fileIDStrings]]))
            [fileWrapper addRegularFileWithContents:data preferredFilename:[name stringByAppendingPathExtension:@"fdf"]];
    }
    return [fileWrapper autorelease];
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    BOOL didWrite = NO;
    NSError *error = nil;
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    if ([ws type:SKPDFDocumentType conformsToType:typeName]) {
        if (mdFlags.exportOption == SKExportOptionWithEmbeddedNotes)
            didWrite = [[self pdfDocument] writeToURL:absoluteURL];
        else
            didWrite = [pdfData writeToURL:absoluteURL options:0 error:&error];
    } else if ([ws type:SKEncapsulatedPostScriptDocumentType conformsToType:typeName] || 
               [ws type:SKDVIDocumentType conformsToType:typeName] || 
               [ws type:SKXDVDocumentType conformsToType:typeName]) {
        if ([ws type:[self fileType] conformsToType:typeName])
            didWrite = [originalData writeToURL:absoluteURL options:0 error:&error];
    } else if ([ws type:SKPDFBundleDocumentType conformsToType:typeName]) {
        NSFileWrapper *fileWrapper = [self PDFBundleFileWrapperForName:[[absoluteURL lastPathComponent] stringByDeletingPathExtension]];
        if (fileWrapper)
            didWrite = [fileWrapper writeToURL:absoluteURL options:0 originalContentsURL:nil error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write file", @"Error description")];
    } else if ([ws type:SKNotesDocumentType conformsToType:typeName]) {
        didWrite = [[NSFileManager defaultManager] writeSkimNotes:[self SkimNoteProperties] toSkimFileAtURL:absoluteURL error:&error];
    } else if ([ws type:SKNotesRTFDocumentType conformsToType:typeName]) {
        NSData *data = [self notesRTFData];
        if (data)
            didWrite = [data writeToURL:absoluteURL options:0 error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes as RTF", @"Error description")];
    } else if ([ws type:SKNotesRTFDDocumentType conformsToType:typeName]) {
        NSFileWrapper *fileWrapper = [self notesRTFDFileWrapper];
        if (fileWrapper)
            didWrite = [fileWrapper writeToURL:absoluteURL options:0 originalContentsURL:nil error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes as RTFD", @"Error description")];
    } else if ([ws type:SKNotesTextDocumentType conformsToType:typeName]) {
        NSString *string = [self notesString];
        if (string)
            didWrite = [string writeToURL:absoluteURL atomically:NO encoding:NSUTF8StringEncoding error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes as text", @"Error description")];
    } else if ([ws type:SKNotesFDFDocumentType conformsToType:typeName]) {
        NSURL *fileURL = [self fileURL];
        if (fileURL && [ws type:[self fileType] conformsToType:SKPDFBundleDocumentType])
            fileURL = [[NSFileManager defaultManager] bundledFileURLWithExtension:@"pdf" inPDFBundleAtURL:fileURL error:NULL];
        NSData *data = [self notesFDFDataForFile:[fileURL lastPathComponent] fileIDStrings:[[self pdfDocument] fileIDStrings]];
        if (data)
            didWrite = [data writeToURL:absoluteURL options:0 error:&error];
        else 
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes as FDF", @"Error description")];
    } else if ([[SKTemplateManager sharedManager] isRichTextBundleTemplateType:typeName]) {
        NSFileWrapper *fileWrapper = [self notesFileWrapperForTemplateType:typeName];
        if (fileWrapper)
            didWrite = [fileWrapper writeToURL:absoluteURL options:0 originalContentsURL:nil error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes using template", @"Error description")];
    } else {
        NSData *data = [self notesDataForTemplateType:typeName];
        if (data)
            didWrite = [data writeToURL:absoluteURL options:0 error:&error];
        else
            error = [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write notes using template", @"Error description")];
    }
    
    if (didWrite == NO && outError != NULL)
        *outError = error ?: [NSError writeFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to write file", @"Error description")];
    
    return didWrite;
}

- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError {
    NSMutableDictionary *dict = [[[super fileAttributesToWriteToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:outError] mutableCopy] autorelease];
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    // only set the creator code for our native types
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SKShouldSetCreatorCodeKey] && 
        ([[self class] isNativeType:typeName] || [typeName isEqualToString:SKNotesDocumentType]))
        [dict setObject:[NSNumber numberWithUnsignedInt:'SKim'] forKey:NSFileHFSCreatorCode];
    
    if ([ws type:typeName conformsToType:SKPDFDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'PDF '] forKey:NSFileHFSTypeCode];
    else if ([ws type:typeName conformsToType:SKPDFBundleDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'PDFD'] forKey:NSFileHFSTypeCode];
    else if ([ws type:typeName conformsToType:SKNotesDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'SKNT'] forKey:NSFileHFSTypeCode];
    else if ([ws type:typeName conformsToType:SKNotesFDFDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'FDF '] forKey:NSFileHFSTypeCode];
    else if ([[absoluteURL pathExtension] isEqualToString:@"rtf"] || [ws type:typeName conformsToType:SKNotesRTFDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'RTF '] forKey:NSFileHFSTypeCode];
    else if ([[absoluteURL pathExtension] isEqualToString:@"txt"] || [ws type:typeName conformsToType:SKNotesTextDocumentType])
        [dict setObject:[NSNumber numberWithUnsignedInt:'TEXT'] forKey:NSFileHFSTypeCode];
    
    return dict;
}

#pragma mark Reading

- (void)setPDFData:(NSData *)data {
    if (pdfData != data) {
        [pdfData release];
        pdfData = [data retain];
    }
    SKDESTROY(pageOffsets);
}

- (void)setOriginalData:(NSData *)data {
    if (originalData != data) {
        [originalData release];
        originalData = [data retain];
    }
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)docType error:(NSError **)outError {
    NSData *inData = nil;
    PDFDocument *pdfDoc = nil;
    NSError *error = nil;
    
    [tmpData release];
    tmpData = [[SKTemporaryData alloc] init];
    
    if ([[NSWorkspace sharedWorkspace] type:docType conformsToType:SKPostScriptDocumentType]) {
        inData = data;
        data = [[SKConversionProgressController newPDFDataWithPostScriptData:data error:&error] autorelease];
    }
    
    if (data)
        pdfDoc = [[SKPDFDocument alloc] initWithData:data];
    
    if (pdfDoc) {
        [self setPDFData:data];
        [tmpData setPdfDocument:pdfDoc];
        [self setOriginalData:inData];
        [pdfDoc release];
        [self updateChangeCount:NSChangeDone];
        return YES;
    } else {
        SKDESTROY(tmpData);
        if (outError != NULL)
            *outError = error ?: [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")];
        return NO;
    }
}

static BOOL isIgnorablePOSIXError(NSError *error) {
    if ([[error domain] isEqualToString:NSPOSIXErrorDomain])
        return [error code] == ENOATTR || [error code] == ENOTSUP || [error code] == EINVAL || [error code] == EPERM || [error code] == EACCES;
    else
        return NO;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)docType error:(NSError **)outError{
    NSData *fileData = nil;
    NSData *data = nil;
    PDFDocument *pdfDoc = nil;
    NSError *error = nil;
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    [tmpData release];
    tmpData = [[SKTemporaryData alloc] init];
    
    if ([ws type:docType conformsToType:SKPDFBundleDocumentType]) {
        NSURL *pdfURL = [[NSFileManager defaultManager] bundledFileURLWithExtension:@"pdf" inPDFBundleAtURL:absoluteURL error:&error];
        if (pdfURL) {
            if ((data = [[NSData alloc] initWithContentsOfURL:pdfURL options:NSDataReadingUncached error:&error]) &&
                (pdfDoc = [[SKPDFDocument alloc] initWithURL:pdfURL])) {
                NSArray *array = [[NSFileManager defaultManager] readSkimNotesFromPDFBundleAtURL:absoluteURL error:&error];
                if (array == nil) {
                    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                    [alert setMessageText:NSLocalizedString(@"Unable to Read Notes", @"Message in alert dialog")];
                    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Skim was not able to read the notes at %@. %@ Do you want to continue to open the PDF document anyway?", @"Informative text in alert dialog"), [[pdfURL path] stringByAbbreviatingWithTildeInPath], [error localizedDescription]]];
                    [alert addButtonWithTitle:NSLocalizedString(@"No", @"Button title")];
                    [alert addButtonWithTitle:NSLocalizedString(@"Yes", @"Button title")];
                    if ([alert runModal] == NSAlertFirstButtonReturn) {
                        SKDESTROY(data);
                        SKDESTROY(pdfDoc);
                        error = [NSError userCancelledErrorWithUnderlyingError:error];
                    }
                } else if ([array count]) {
                    [tmpData setNoteDicts:array];
                }
            }
        }
    } else if ((data = [[NSData alloc] initWithContentsOfURL:absoluteURL options:NSDataReadingUncached error:&error])) {
        if ([ws type:docType conformsToType:SKPDFDocumentType]) {
            pdfDoc = [[SKPDFDocument alloc] initWithURL:absoluteURL];
        } else {
            fileData = data;
            if ((data = [SKConversionProgressController newPDFDataFromURL:absoluteURL ofType:docType error:&error]))
                pdfDoc = [[SKPDFDocument alloc] initWithData:data];
        }
        if (pdfDoc) {
            NSArray *array = [[NSFileManager defaultManager] readSkimNotesFromExtendedAttributesAtURL:absoluteURL error:&error];
            BOOL foundEANotes = [array count] > 0;
            if (foundEANotes) {
                [tmpData setNoteDicts:array];
            } else {
                // we found no notes, see if we had an error finding notes. if EAs were not supported we ignore the error, as we may assume there won't be any notes
                if (array == nil && isIgnorablePOSIXError(error) == NO) {
                    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                    [alert setMessageText:NSLocalizedString(@"Unable to Read Notes", @"Message in alert dialog")];
                    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Skim was not able to read the notes at %@. %@ Do you want to continue to open the PDF document anyway?", @"Informative text in alert dialog"), [[absoluteURL path] stringByAbbreviatingWithTildeInPath], [error localizedDescription]]];
                    [alert addButtonWithTitle:NSLocalizedString(@"No", @"Button title")];
                    [alert addButtonWithTitle:NSLocalizedString(@"Yes", @"Button title")];
                    if ([alert runModal] == NSAlertFirstButtonReturn) {
                        SKDESTROY(fileData);
                        SKDESTROY(data);
                        SKDESTROY(pdfDoc);
                        error = [NSError userCancelledErrorWithUnderlyingError:error];
                    }
                }
            }
            NSInteger readOption = [[NSUserDefaults standardUserDefaults] integerForKey:foundEANotes ? SKReadNonMissingNotesFromSkimFileOptionKey : SKReadMissingNotesFromSkimFileOptionKey];
            if (pdfDoc && readOption != SKOptionNever) {
                NSURL *notesURL = [absoluteURL URLReplacingPathExtension:@"skim"];
                if ([notesURL checkResourceIsReachableAndReturnError:NULL]) {
                    if (readOption == SKOptionAsk) {
                        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                        [alert setMessageText:NSLocalizedString(@"Found Separate Notes", @"Message in alert dialog") ];
                        if (foundEANotes)
                            [alert setInformativeText:NSLocalizedString(@"A Skim notes file with the same name was found.  Do you want Skim to read the notes from this file?", @"Informative text in alert dialog")];
                        else
                            [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Unable to read notes for %@, but a Skim notes file with the same name was found.  Do you want Skim to read the notes from this file?", @"Informative text in alert dialog"), [[absoluteURL path] stringByAbbreviatingWithTildeInPath]]];
                        [[alert addButtonWithTitle:NSLocalizedString(@"Yes", @"Button title")] setTag:SKOptionAlways];
                        [[alert addButtonWithTitle:NSLocalizedString(@"No", @"Button title")] setTag:SKOptionNever];
                        readOption = [alert runModal];
                    }
                    if (readOption == SKOptionAlways) {
                        array = [[NSFileManager defaultManager] readSkimNotesFromSkimFileAtURL:notesURL error:NULL];
                        if ([array count] && [array isEqualToArray:[tmpData noteDicts]] == NO) {
                            [tmpData setNoteDicts:array];
                            [self updateChangeCount:NSChangeDone];
                        }
                    }
                }
            }
        }
    }
    
    if (data) {
        if (pdfDoc) {
            [self setPDFData:data];
            [tmpData setPdfDocument:pdfDoc];
            [self setOriginalData:fileData];
            [pdfDoc release];
            [fileUpdateChecker didUpdateFromURL:absoluteURL];
            
            NSDictionary *dictionary = nil;
            NSArray *array = nil;
            NSNumber *number = nil;
            if ([docType isEqualToString:SKPDFBundleDocumentType]) {
                NSDictionary *info = [NSDictionary dictionaryWithContentsOfURL:[[absoluteURL URLByAppendingPathComponent:BUNDLE_DATA_FILENAME] URLByAppendingPathExtension:@"plist"]];
                if ([info isKindOfClass:[NSDictionary class]]) {
                    dictionary = [info objectForKey:SKPresentationOptionsKey];
                    array = [info objectForKey:SKTagsKey];
                    number = [info objectForKey:SKRatingKey];
                }
            } else {
                SKNExtendedAttributeManager *eam = [SKNExtendedAttributeManager sharedNoSplitManager];
                dictionary = [eam propertyListFromExtendedAttributeNamed:PRESENTATION_OPTIONS_KEY atPath:[absoluteURL path] traverseLink:YES error:NULL];
                array = [eam propertyListFromExtendedAttributeNamed:OPEN_META_TAGS_KEY atPath:[absoluteURL path] traverseLink:YES error:NULL];
                number = [eam propertyListFromExtendedAttributeNamed:OPEN_META_RATING_KEY atPath:[absoluteURL path] traverseLink:YES error:NULL];
            }
            if ([dictionary isKindOfClass:[NSDictionary class]] && [dictionary count])
                [tmpData setPresentationOptions:dictionary];
            if ([array isKindOfClass:[NSArray class]] && [array count])
                [tmpData setOpenMetaTags:array];
            if ([number respondsToSelector:@selector(doubleValue)] && [number doubleValue] > 0.0)
                [tmpData setOpenMetaRating:[number doubleValue]];
        }
        [data release];
    }
    [fileData release];
    
    if ([tmpData pdfDocument] == nil) {
        SKDESTROY(tmpData);
        if (outError)
            *outError = error ?: [NSError readFileErrorWithLocalizedDescription:NSLocalizedString(@"Unable to load file", @"Error description")];
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)revertToContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError{
    NSWindow *mainWindow = [[self mainWindowController] window];
    NSWindow *modalwindow = nil;
    NSModalSession session;
    
    if ([mainWindow attachedSheet] == nil && [mainWindow isMainWindow]) {
        modalwindow = [[SKAnimatedBorderlessWindow alloc] initWithContentRect:NSZeroRect];
        [(SKApplication *)NSApp setUserAttentionDisabled:YES];
        session = [NSApp beginModalSessionForWindow:modalwindow];
        [(SKApplication *)NSApp setUserAttentionDisabled:NO];
    }
    
    BOOL success = [super revertToContentsOfURL:absoluteURL ofType:typeName error:outError];
    
    if (success) {
        [[self undoManager] disableUndoRegistration];
        [self setDataFromTmpData];
        [[self undoManager] enableUndoRegistration];
        [[self undoManager] removeAllActions];
        [fileUpdateChecker reset];
    }
    
    SKDESTROY(tmpData);
    
    if (modalwindow) {
        [NSApp endModalSession:session];
        [modalwindow orderOut:nil];
        [modalwindow release];
    }
    
    return success;
}

#pragma mark Printing

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError {
    NSPrintInfo *printInfo = [[[self printInfo] copy] autorelease];
    [[printInfo dictionary] addEntriesFromDictionary:printSettings];
    
    NSPrintOperation *printOperation = nil;
    PDFDocument *pdfDoc = [self pdfDocument];
    if ([pdfDoc respondsToSelector:@selector(printOperationForPrintInfo:scalingMode:autoRotate:)])
        printOperation = [pdfDoc printOperationForPrintInfo:printInfo scalingMode:kPDFPrintPageScaleNone autoRotate:YES];
    else if ([pdfDoc respondsToSelector:@selector(getPrintOperationForPrintInfo:autoRotate:)])
        printOperation = [pdfDoc getPrintOperationForPrintInfo:printInfo autoRotate:YES];
    
    // NSPrintProtected is a private key that disables the items in the PDF popup of the Print panel, and is set for encrypted documents
    if ([pdfDoc isEncrypted])
        [[[printOperation printInfo] dictionary] setValue:[NSNumber numberWithBool:NO] forKey:@"NSPrintProtected"];
    
    NSPrintPanel *printPanel = [printOperation printPanel];
    [printPanel setOptions:NSPrintPanelShowsCopies | NSPrintPanelShowsPageRange | NSPrintPanelShowsPaperSize | NSPrintPanelShowsOrientation | NSPrintPanelShowsScaling | NSPrintPanelShowsPreview];
    [printPanel addAccessoryController:[[[SKPrintAccessoryController alloc] init] autorelease]];
    
    if (printOperation == nil && outError)
        *outError = [NSError printDocumentErrorWithLocalizedDescription:nil];
    
    return printOperation;
}

#pragma mark Actions

- (void)readNotesFromURL:(NSURL *)notesURL replace:(BOOL)replace {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSString *type = [ws typeOfFile:[notesURL path] error:NULL];
    NSArray *array = nil;
    
    if ([ws type:type conformsToType:SKNotesDocumentType]) {
        array = [NSKeyedUnarchiver unarchiveObjectWithFile:[notesURL path]];
    } else if ([ws type:type conformsToType:SKNotesFDFDocumentType]) {
        NSData *fdfData = [NSData dataWithContentsOfURL:notesURL];
        if (fdfData)
            array = [SKFDFParser noteDictionariesFromFDFData:fdfData];
    }
    
    if (array) {
        [[self mainWindowController] addAnnotationsFromDictionaries:array removeAnnotations:replace ? [self notes] : nil autoUpdate:NO];
        [[self undoManager] setActionName:replace ? NSLocalizedString(@"Replace Notes", @"Undo action name") : NSLocalizedString(@"Add Notes", @"Undo action name")];
    } else
        NSBeep();
}

#define CHECK_BUTTON_OFFSET_X 16.0
#define CHECK_BUTTON_OFFSET_Y 8.0

- (IBAction)readNotes:(id)sender{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    NSURL *fileURL = [self fileURL];
    NSButton *replaceNotesCheckButton = nil;
    NSView *readNotesAccessoryView = nil;
    
    if ([[[self mainWindowController] notes] count]) {
        replaceNotesCheckButton = [[[NSButton alloc] init] autorelease];
        [replaceNotesCheckButton setButtonType:NSSwitchButton];
        [replaceNotesCheckButton setTitle:NSLocalizedString(@"Replace existing notes", @"Check button title")];
        [replaceNotesCheckButton sizeToFit];
        [replaceNotesCheckButton setFrameOrigin:NSMakePoint(CHECK_BUTTON_OFFSET_X, CHECK_BUTTON_OFFSET_Y)];
        readNotesAccessoryView = [[NSView alloc] initWithFrame:NSInsetRect([replaceNotesCheckButton frame], -CHECK_BUTTON_OFFSET_X, -CHECK_BUTTON_OFFSET_Y)];
        [readNotesAccessoryView addSubview:replaceNotesCheckButton];
        [oPanel setAccessoryView:readNotesAccessoryView];
        [replaceNotesCheckButton setState:NSOnState];
        [readNotesAccessoryView release];
        if ([oPanel respondsToSelector:@selector(toggleOptionsView:)])
            [oPanel toggleOptionsView:nil];
    }
    
    [oPanel setDirectoryURL:[fileURL URLByDeletingLastPathComponent]];
    [oPanel setAllowedFileTypes:[NSArray arrayWithObjects:SKNotesDocumentType, nil]];
    [oPanel beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton) {
                NSURL *notesURL = [[oPanel URLs] objectAtIndex:0];
                BOOL replace = (replaceNotesCheckButton && [replaceNotesCheckButton state] == NSOnState);
                [self readNotesFromURL:notesURL replace:replace];
            }
        }];
}

- (void)setPDFData:(NSData *)data pageOffsets:(NSMapTable *)newPageOffsets {
    [[[self undoManager] prepareWithInvocationTarget:self] setPDFData:pdfData pageOffsets:pageOffsets];
    [self setPDFData:data];
    if (newPageOffsets != pageOffsets) {
        [pageOffsets release];
        pageOffsets = [newPageOffsets retain];
    }
}

- (void)convertNotesUsingPDFDocument:(PDFDocument *)pdfDocWithoutNotes {
    [[self mainWindowController] beginProgressSheetWithMessage:[NSLocalizedString(@"Converting notes", @"Message for progress sheet") stringByAppendingEllipsis] maxValue:0];
    
    PDFDocument *pdfDoc = [self pdfDocument];
    NSInteger i, count = [pdfDoc pageCount];
    NSMapTable *offsets = nil;
    NSMutableArray *annotations = nil;
    NSMutableArray *noteDicts = nil;

    for (i = 0; i < count; i++) {
        PDFPage *page = [pdfDoc pageAtIndex:i];
        NSPoint pageOrigin = [page boundsForBox:kPDFDisplayBoxMediaBox].origin;
        
        for (PDFAnnotation *annotation in [[[page annotations] copy] autorelease]) {
            if ([annotation isSkimNote] == NO && [annotation isConvertibleAnnotation]) {
                if (annotations == nil)
                    annotations = [[NSMutableArray alloc] init];
                [annotations addObject:annotation];
                NSDictionary *properties = [annotation SkimNoteProperties];
                if ([[annotation type] isEqualToString:SKNTextString])
                    properties = [SKNPDFAnnotationNote textToNoteSkimNoteProperties:properties];
                if (noteDicts == nil)
                    noteDicts = [[NSMutableArray alloc] init];
                [noteDicts addObject:properties];
            }
        }
        
        if (NSEqualPoints(pageOrigin, NSZeroPoint) == NO) {
            if (offsets == nil)
                offsets = NSCreateMapTable(NSIntegerMapKeyCallBacks, NSOwnedPointerMapValueCallBacks, 0);
            NSPointPointer offsetPtr = NSZoneMalloc([self zone], sizeof(NSPoint));
            *offsetPtr = pageOrigin;
            NSMapInsert(offsets, (const void *)[page pageIndex], offsetPtr);
        }
    }
    
    if (annotations) {
        
        // if pdfDocWithoutNotes was nil, the document was not encrypted, so no need to try to unlock
        if (pdfDocWithoutNotes == nil)
            pdfDocWithoutNotes = [[[PDFDocument alloc] initWithData:pdfData] autorelease];
        
        dispatch_queue_t queue = RUNNING_AFTER(10_11) ? dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) : dispatch_get_main_queue();
        
        dispatch_async(queue, ^{
            
            NSInteger j, jMax = [pdfDocWithoutNotes pageCount];
            
            for (j = 0; j < jMax; j++) {
                PDFPage *page = [pdfDocWithoutNotes pageAtIndex:j];
                
                for (PDFAnnotation *annotation in [[[page annotations] copy] autorelease]) {
                    if ([annotation isSkimNote] == NO && [annotation isConvertibleAnnotation])
                        [page removeAnnotation:annotation];
                }
            }
            
            NSData *data = [pdfDocWithoutNotes dataRepresentation];
            
            [[pdfDocWithoutNotes outlineRoot] clearDocument];

            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[self mainWindowController] addAnnotationsFromDictionaries:noteDicts removeAnnotations:annotations autoUpdate:YES];
                
                [self setPDFData:data pageOffsets:offsets];
                
                [[self undoManager] setActionName:NSLocalizedString(@"Convert Notes", @"Undo action name")];
                
                [offsets release];
                [noteDicts release];
                [annotations release];

                [[self mainWindowController] dismissProgressSheet];
                
                mdFlags.convertingNotes = 0;
            });
        });
        
    } else {
        
        [offsets release];

        [[pdfDocWithoutNotes outlineRoot] clearDocument];
        
        [[self mainWindowController] dismissProgressSheet];
        
        mdFlags.convertingNotes = 0;
    }
}

- (void)beginConvertNotesPasswordSheetForPDFDocument:(PDFDocument *)pdfDoc {
    SKTextFieldSheetController *passwordSheetController = [[[SKTextFieldSheetController alloc] initWithWindowNibName:@"PasswordSheet"] autorelease];
    
    [passwordSheetController beginSheetModalForWindow:[[self mainWindowController] window] completionHandler:^(NSInteger result) {
            if (result == NSOKButton) {
                [[passwordSheetController window] orderOut:nil];
                
                if (pdfDoc && ([pdfDoc allowsNotes] == NO || [pdfDoc allowsPrinting] == NO) &&
                    ([pdfDoc unlockWithPassword:[passwordSheetController stringValue]] == NO || [pdfDoc allowsNotes] == NO || [pdfDoc allowsPrinting] == NO)) {
                    [self beginConvertNotesPasswordSheetForPDFDocument:pdfDoc];
                } else {
                    [self convertNotesUsingPDFDocument:pdfDoc];
                }
            } else {
                [[pdfDoc outlineRoot] clearDocument];
                mdFlags.convertingNotes = 0;
            }
        }];
}

- (void)convertNotesSheetDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertSecondButtonReturn)
        return;
    
    // remove the sheet, to make place for either the password or progress sheet
    [[alert window] orderOut:nil];
    
    mdFlags.convertingNotes = 1;
    
    PDFDocument *pdfDocWithoutNotes = nil;
    
    if (mdFlags.needsPasswordToConvert) {
        pdfDocWithoutNotes = [[[PDFDocument alloc] initWithData:pdfData] autorelease];
        [self tryToUnlockDocument:pdfDocWithoutNotes];
        if ([pdfDocWithoutNotes allowsNotes] == NO || [pdfDocWithoutNotes allowsPrinting] == NO) {
            [self beginConvertNotesPasswordSheetForPDFDocument:pdfDocWithoutNotes];
            return;
        }
    }
    [self convertNotesUsingPDFDocument:pdfDocWithoutNotes];
}

- (BOOL)hasConvertibleAnnotations {
    PDFDocument *pdfDoc = [self pdfDocument];
    NSInteger i, count = [pdfDoc pageCount];
    for (i = 0; i < count; i++) {
        for (PDFAnnotation *annotation in [[pdfDoc pageAtIndex:i] annotations]) {
            if ([annotation isSkimNote] == NO && [annotation isConvertibleAnnotation])
                return YES;
        }
    }
    return NO;
}

- (IBAction)convertNotes:(id)sender {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    if (([ws type:[self fileType] conformsToType:SKPDFDocumentType] == NO && [ws type:[self fileType] conformsToType:SKPDFBundleDocumentType] == NO) ||
        [self hasConvertibleAnnotations] == NO) {
        NSBeep();
        return;
    }
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:NSLocalizedString(@"Convert Notes", @"Alert text when trying to convert notes")];
    [alert setInformativeText:NSLocalizedString(@"This will convert PDF annotations to Skim notes. Do you want to proceed?", @"Informative text in alert dialog")];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", @"Button title")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Button title")];
    [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(convertNotesSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)saveArchiveToURL:(NSURL *)fileURL email:(BOOL)email {
    NSTask *task = [[[NSTask alloc] init] autorelease];
    if ([[fileURL pathExtension] isEqualToString:@"dmg"]) {
        [task setLaunchPath:@"/usr/bin/hdiutil"];
        [task setArguments:[NSArray arrayWithObjects:@"create", @"-srcfolder", [[self fileURL] path], @"-format", @"UDZO", @"-volname", [[fileURL lastPathComponent] stringByDeletingPathExtension], [fileURL path], nil]];
    } else {
        [task setLaunchPath:@"/usr/bin/tar"];
        [task setArguments:[NSArray arrayWithObjects:@"-czf", [fileURL path], [[self fileURL] lastPathComponent], nil]];
    }
    [task setCurrentDirectoryPath:[[[self fileURL] URLByDeletingLastPathComponent] path]];
    [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    
    SKAttachmentEmailer *emailer = nil;
    if (email)
        emailer = [SKAttachmentEmailer attachmentEmailerWithFileURL:fileURL subject:[self displayName] waitingForTask:task];
    
    @try {
        [task launch];
    }
    @catch (id exception) {
        [emailer taskFailed];
    }
}

- (IBAction)saveArchive:(id)sender {
    NSString *ext = ([sender tag] | SKArchiveDiskImageMask) ? @"dmg" : @"tgz";
    NSURL *fileURL = [self fileURL];
    if (fileURL && [fileURL checkResourceIsReachableAndReturnError:NULL] && [self isDocumentEdited] == NO) {
        if (([sender tag] | SKArchiveEmailMask)) {
            NSURL *tmpDirURL = [[NSFileManager defaultManager] uniqueChewableItemsDirectoryURL];
            NSURL *tmpFileURL = [tmpDirURL URLByAppendingPathComponent:[[self fileURL] lastPathComponentReplacingPathExtension:ext]];
            [self saveArchiveToURL:tmpFileURL email:YES];
        } else {
            NSSavePanel *sp = [NSSavePanel savePanel];
            [sp setAllowedFileTypes:[NSArray arrayWithObjects:ext, nil]];
            [sp setCanCreateDirectories:YES];
            [sp setNameFieldStringValue:[fileURL lastPathComponentReplacingPathExtension:ext]];
            [sp beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result){
                    if (NSFileHandlingPanelOKButton == result)
                        [self saveArchiveToURL:[sp URL] email:NO];
                }];
        }
    } else {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:NSLocalizedString(@"You must save this file first", @"Alert text when trying to create archive for unsaved document")];
        [alert setInformativeText:NSLocalizedString(@"The document has unsaved changes, or has not previously been saved to disk.", @"Informative text in alert dialog")];
        [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (IBAction)moveToTrash:(id)sender {
    NSURL *fileURL = [self fileURL];
    if ([fileURL checkResourceIsReachableAndReturnError:NULL]) {
        NSURL *folderURL = [fileURL URLByDeletingLastPathComponent];
        NSString *fileName = [fileURL lastPathComponent];
        NSInteger tag = 0;
        if ([[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[folderURL path] destination:@"" files:[NSArray arrayWithObjects:fileName, nil] tag:&tag])
            [self close];
        else NSBeep();
    } else NSBeep();
}

- (void)revertAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
        NSError *error = nil;
        if (NO == [self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:&error] && [error isUserCancelledError] == NO) {
            [[alert window] orderOut:nil];
            [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];
        }
    }
}

- (void)revertDocumentToSaved:(id)sender { 	 
     if ([self fileURL]) {
         if ([self isDocumentEdited]) {
             [super revertDocumentToSaved:sender]; 	 
         } else if ([fileUpdateChecker fileChangedOnDisk] || 
                    NSOrderedAscending == [[self fileModificationDate] compare:[[[NSFileManager defaultManager] attributesOfItemAtPath:[[self fileURL] path] error:NULL] fileModificationDate]]) {
             NSAlert *alert = [[[NSAlert alloc] init] autorelease];
             [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Do you want to revert to the version of the document \"%@\" on disk?", @"Message in alert dialog"), [[self fileURL] lastPathComponent]]];
             [alert setInformativeText:NSLocalizedString(@"Your current changes will be lost.", @"Informative text in alert dialog")];
             [alert addButtonWithTitle:NSLocalizedString(@"Revert", @"Button title")];
             [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Button title")];
             [alert beginSheetModalForWindow:[[self mainWindowController] window]
                               modalDelegate:self 	 
                              didEndSelector:@selector(revertAlertDidEnd:returnCode:contextInfo:) 	 
                                 contextInfo:NULL]; 	 
        }
    }
}

- (void)performFindPanelAction:(id)sender {
    [[self mainWindowController] performFindPanelAction:sender];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
	if ([anItem action] == @selector(revertDocumentToSaved:)) {
        if ([self fileURL] == nil || [[self fileURL] checkResourceIsReachableAndReturnError:NULL] == NO)
            return NO;
        return [self isDocumentEdited] || [fileUpdateChecker fileChangedOnDisk] ||
               NSOrderedAscending == [[self fileModificationDate] compare:[[[NSFileManager defaultManager] attributesOfItemAtPath:[[self fileURL] path] error:NULL] fileModificationDate]];
    } else if ([anItem action] == @selector(printDocument:)) {
        return [[self pdfDocument] allowsPrinting];
    } else if ([anItem action] == @selector(convertNotes:)) {
        return [[NSWorkspace sharedWorkspace] type:[self fileType] conformsToType:SKPDFDocumentType] && [[self pdfDocument] allowsNotes];
    } else if ([anItem action] == @selector(readNotes:)) {
        return [[self pdfDocument] allowsNotes];
    } else if ([anItem action] == @selector(saveArchive:)) {
        return [self fileURL] && [[self fileURL] checkResourceIsReachableAndReturnError:NULL] && [self isDocumentEdited] == NO;
    } else if ([anItem action] == @selector(moveToTrash:)) {
        return [self fileURL] && [[self fileURL] checkResourceIsReachableAndReturnError:NULL];
    } else if ([anItem action] == @selector(performFindPanelAction:)) {
        if ([[self mainWindowController] interactionMode] == SKPresentationMode)
            return NO;
        switch ([anItem tag]) {
            case NSFindPanelActionShowFindPanel:
                return YES;
            case NSFindPanelActionNext:
            case NSFindPanelActionPrevious:
                return YES;
            case NSFindPanelActionSetFindString:
                return [[[self pdfView] currentSelection] hasCharacters];
            default:
                return NO;
        }
    }
    return [super validateUserInterfaceItem:anItem];
}

- (void)remoteButtonPressed:(NSEvent *)theEvent {
    [[self mainWindowController] remoteButtonPressed:theEvent];
}

#pragma mark Notification handlers

- (void)handleWindowWillCloseNotification:(NSNotification *)notification {
    NSWindow *window = [notification object];
    // ignore when we're switching fullscreen/main windows
    if ([window isEqual:[[window windowController] window]]) {
        [fileUpdateChecker terminate];
        SKDESTROY(fileUpdateChecker);
        [synchronizer terminate];
        [self saveRecentDocumentInfo];
    }
}

#pragma mark Pdfsync support

- (void)setFileURL:(NSURL *)absoluteURL {
    [super setFileURL:absoluteURL];
    
    if ([absoluteURL isFileURL])
        [synchronizer setFileName:[absoluteURL path]];
    else
        [synchronizer setFileName:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SKDocumentFileURLDidChangeNotification object:self];
}

- (SKPDFSynchronizer *)synchronizer {
    if (synchronizer == nil) {
        synchronizer = [[SKPDFSynchronizer alloc] init];
        [synchronizer setDelegate:self];
        [synchronizer setFileName:[[self fileURL] path]];
    }
    return synchronizer;
}

static void replaceInShellCommand(NSMutableString *cmdString, NSString *find, NSString *replace) {
    NSRange range = NSMakeRange(0, 0);
    unichar prevChar, nextChar;
    while (NSMaxRange(range) < [cmdString length]) {
        range = [cmdString rangeOfString:find options:NSLiteralSearch range:NSMakeRange(NSMaxRange(range), [cmdString length] - NSMaxRange(range))];
        if (range.location == NSNotFound)
            break;
        prevChar = range.location > 0 ? [cmdString characterAtIndex:range.location - 1] : 0;
        nextChar = NSMaxRange(range) < [cmdString length] ? [cmdString characterAtIndex:NSMaxRange(range)] : 0;
        if ([[NSCharacterSet letterCharacterSet] characterIsMember:nextChar] == NO) {
            if (prevChar != '\'' || nextChar != '\'')
                replace = [replace stringByEscapingShellChars];
            [cmdString replaceCharactersInRange:range withString:replace];
            range.length = [replace length];
        }
    }
}

- (void)synchronizer:(SKPDFSynchronizer *)aSynchronizer foundLine:(NSInteger)line inFile:(NSString *)file {
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        
        NSString *editorPreset = [[NSUserDefaults standardUserDefaults] stringForKey:SKTeXEditorPresetKey];
        NSString *editorCmd = nil;
        NSString *editorArgs = nil;
        NSMutableString *cmdString = nil;
        
        if (NO == [SKSyncPreferences getTeXEditorCommand:&editorCmd arguments:&editorArgs forPreset:editorPreset]) {
            editorCmd = [[NSUserDefaults standardUserDefaults] stringForKey:SKTeXEditorCommandKey];
            editorArgs = [[NSUserDefaults standardUserDefaults] stringForKey:SKTeXEditorArgumentsKey];
        }
        cmdString = [[editorArgs mutableCopy] autorelease];
        
        if ([editorCmd isAbsolutePath] == NO) {
            NSMutableArray *searchPaths = [NSMutableArray arrayWithObjects:@"/usr/bin", @"/usr/local/bin", nil];
            NSString *path;
            NSString *toolPath;
            NSBundle *appBundle;
            NSFileManager *fm = [NSFileManager defaultManager];
            
            if ([editorPreset isEqualToString:@""] == NO) {
                if ((path = [[NSWorkspace sharedWorkspace] fullPathForApplication:editorPreset]) &&
                    (appBundle = [NSBundle bundleWithPath:path])) {
                    if ((path = [[[appBundle bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Helpers"]))
                        [searchPaths insertObject:path atIndex:0];
                    if ([editorPreset isEqualToString:@"BBEdit"] == NO &&
                        (path = [[appBundle executablePath] stringByDeletingLastPathComponent]))
                        [searchPaths insertObject:path atIndex:0];
                    if ((path = [appBundle resourcePath]))
                        [searchPaths insertObject:path atIndex:0];
                    if ((path = [appBundle sharedSupportPath]))
                        [searchPaths insertObject:path atIndex:0];
                }
            } else {
                [searchPaths addObjectsFromArray:[[[NSFileManager defaultManager] applicationSupportDirectoryURLs] valueForKey:@"path"]];
            }
            
            for (path in searchPaths) {
                toolPath = [path stringByAppendingPathComponent:editorCmd];
                if ([fm isExecutableFileAtPath:toolPath]) {
                    editorCmd = toolPath;
                    break;
                }
                toolPath = [[path stringByAppendingPathComponent:@"bin"] stringByAppendingPathComponent:editorCmd];
                if ([fm isExecutableFileAtPath:toolPath]) {
                    editorCmd = toolPath;
                    break;
                }
            }
        }
        
        replaceInShellCommand(cmdString, @"%line", [NSString stringWithFormat:@"%ld", (long)(line + 1)]);
        replaceInShellCommand(cmdString, @"%file", file);
        replaceInShellCommand(cmdString, @"%output", [[self fileURL] path]);
        
        [cmdString insertString:@"\" " atIndex:0];
        [cmdString insertString:editorCmd atIndex:0];
        [cmdString insertString:@"\"" atIndex:0];
        
        NSWorkspace *ws = [NSWorkspace sharedWorkspace];
        NSString *theUTI = [ws typeOfFile:[[editorCmd stringByStandardizingPath] stringByResolvingSymlinksInPath] error:NULL];
        if ([ws type:theUTI conformsToType:@"com.apple.applescript.script"] || [ws type:theUTI conformsToType:@"com.apple.applescript.text"])
            [cmdString insertString:@"/usr/bin/osascript " atIndex:0];
        
        NSTask *task = [[[NSTask alloc] init] autorelease];
        [task setLaunchPath:@"/bin/sh"];
        [task setCurrentDirectoryPath:[file stringByDeletingLastPathComponent]];
        [task setArguments:[NSArray arrayWithObjects:@"-c", cmdString, nil]];
        [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
        [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
        @try {
            [task launch];
        }
        @catch(id exception) {
            NSLog(@"command failed: %@: %@", cmdString, exception);
        }
    }
}

- (void)synchronizer:(SKPDFSynchronizer *)aSynchronizer foundLocation:(NSPoint)point atPageIndex:(NSUInteger)pageIndex options:(NSInteger)options {
    PDFDocument *pdfDoc = [self pdfDocument];
    if (pageIndex < [pdfDoc pageCount]) {
        PDFPage *page = [pdfDoc pageAtIndex:pageIndex];
        if (options & SKPDFSynchronizerFlippedMask)
            point.y = NSMaxY([page boundsForBox:kPDFDisplayBoxMediaBox]) - point.y;
        [[self pdfView] displayLineAtPoint:point inPageAtIndex:pageIndex showReadingBar:(options & SKPDFSynchronizerShowReadingBarMask) != 0];
    }
}


#pragma mark Accessors

- (SKInteractionMode)systemInteractionMode {
    // only return the real interaction mode when the fullscreen window is on the primary screen, otherwise no need to block main menu and dock
    if ([[[[self mainWindowController] window] screen] isEqual:[NSScreen primaryScreen]])
        return [[self mainWindowController] interactionMode];
    return SKNormalMode;
}

- (PDFDocument *)pdfDocument{
    return [[self mainWindowController] pdfDocument];
}

- (PDFDocument *)placeholderPdfDocument{
    return [[self mainWindowController] placeholderPdfDocument];
}

- (NSDictionary *)currentDocumentSetup {
    NSMutableDictionary *setup = [[[super currentDocumentSetup] mutableCopy] autorelease];
    if ([setup count])
        [setup addEntriesFromDictionary:[[self mainWindowController] currentSetup]];
    return setup;
}

- (void)applySetup:(NSDictionary *)setup {
    if ([self mainWindowController] == nil)
        [self makeWindowControllers];
    [[self mainWindowController] applySetup:setup];
}

- (SKPDFView *)pdfView {
    return [[self mainWindowController] pdfView];
}

- (NSPrintInfo *)printInfo {
    NSPrintInfo *printInfo = [super printInfo];
    if ([[self pdfDocument] pageCount]) {
        PDFPage *page = [[self pdfDocument] pageAtIndex:0];
        NSSize pageSize = [page boundsForBox:kPDFDisplayBoxMediaBox].size;
        BOOL isLandscape = [page rotation] % 180 == 90 ? pageSize.height > pageSize.width : pageSize.width > pageSize.height;
        [printInfo setOrientation:isLandscape ? NSLandscapeOrientation : NSPortraitOrientation];
    }
    return printInfo;
}

- (NSArray *)snapshots {
    return [[self mainWindowController] snapshots];
}

- (NSArray *)tags {
    return [[self mainWindowController] tags] ?: [NSArray array];
}

- (double)rating {
    return [[self mainWindowController] rating];
}

#pragma mark Passwords

- (SKPasswordStatus)getPDFPassword:(NSString **)password item:(id *)itemPtr forFileID:(NSString *)fileID {
    SKPasswordStatus status = [SKKeychain getPassword:password item:itemPtr forService:SKPDFPasswordServiceName account:fileID];
    if (status == SKPasswordStatusNotFound) {
        // try to find an item in the old format
        id oldItem = nil;
        status = [SKKeychain getPassword:password item:&oldItem forService:[@"Skim - " stringByAppendingString:fileID] account:NSUserName()];
        if (status == SKPasswordStatusFound) {
            // update to new format, unless password == NULL, when this is called from setPDFPassword:...
            if (password)
                [self setPDFPassword:nil item:oldItem forFileID:fileID];
            if (itemPtr)
                *itemPtr = oldItem;
        }
    }
    return status;
}

- (void)setPDFPassword:(NSString *)password item:(id)item forFileID:(NSString *)fileID {
    if (item == nil) {
        // if we find an old item we should modify that
        SKPasswordStatus status = [self getPDFPassword:NULL item:&item forFileID:fileID];
        if (status == SKPasswordStatusError)
            return;
    }
    [SKKeychain setPassword:password item:item forService:SKPDFPasswordServiceName account:fileID label:[@"Skim: " stringByAppendingString:[self displayName]] comment:[[self fileURL] path]];
}

- (NSString *)fileIDStringForDocument:(PDFDocument *)document {
    return [[document fileIDStrings] lastObject] ?: [pdfData md5String];
}

- (void)doSavePasswordInKeychain:(NSString *)password {
    NSString *fileID = [self fileIDStringForDocument:[self pdfDocument]];
    if (fileID)
        [self setPDFPassword:password item:nil forFileID:fileID];
}

- (void)passwordAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NSString *password = [(NSString *)contextInfo autorelease];
    if (returnCode == NSAlertFirstButtonReturn)
        [self doSavePasswordInKeychain:password];   
}

- (void)savePasswordInKeychain:(NSString *)password {
    if ([[self pdfDocument] isLocked])
        return;
    
    NSInteger saveOption = [[NSUserDefaults standardUserDefaults] integerForKey:SKSavePasswordOptionKey];
    if (saveOption == SKOptionAlways) {
        [self doSavePasswordInKeychain:password];
    } else if (saveOption == SKOptionAsk) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Remember Password?", @"Message in alert dialog"), nil]];
        [alert setInformativeText:NSLocalizedString(@"Do you want to save this password in your Keychain?", @"Informative text in alert dialog")];
        [alert addButtonWithTitle:NSLocalizedString(@"Yes", @"Button title")];
        [alert addButtonWithTitle:NSLocalizedString(@"No", @"Button title")];
        NSWindow *window = [[self mainWindowController] window];
        if ([window attachedSheet] == nil)
            [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(passwordAlertDidEnd:returnCode:contextInfo:) contextInfo:[password retain]];
        else if (NSAlertFirstButtonReturn == [alert runModal])
            [self doSavePasswordInKeychain:password];
    }
}

- (void)tryToUnlockDocument:(PDFDocument *)document {
    if ([document permissionsStatus] != kPDFDocumentPermissionsOwner) {
        NSString *password = nil;
        if  (SKOptionNever != [[NSUserDefaults standardUserDefaults] integerForKey:SKSavePasswordOptionKey]) {
            NSString *fileID = [self fileIDStringForDocument:document];
            if (fileID)
                [self getPDFPassword:&password item:NULL forFileID:fileID];
        }
        if (password == nil && [[self pdfDocument] respondsToSelector:@selector(passwordUsedForUnlocking)])
            password = [[self pdfDocument] passwordUsedForUnlocking];
        if (password)
            [document unlockWithPassword:password];
    }
}

#pragma mark Scripting support

- (NSArray *)notes {
    return [[self mainWindowController] notes];
}

- (id)valueInNotesWithUniqueID:(NSString *)aUniqueID {
    for (PDFAnnotation *annotation in [[self mainWindowController] notes]) {
        if ([[annotation uniqueID] isEqualToString:aUniqueID])
            return annotation;
    }
    return nil;
}

- (void)insertObject:(PDFAnnotation *)newNote inNotesAtIndex:(NSUInteger)anIndex {
    if ([[self pdfDocument] allowsNotes]) {
        PDFPage *page = [newNote page];
        if (page && [[page annotations] containsObject:newNote] == NO) {
            SKPDFView *pdfView = [self pdfView];
            
            [pdfView addAnnotation:newNote toPage:page];
            [[self undoManager] setActionName:NSLocalizedString(@"Add Note", @"Undo action name")];
        } else {
            [[NSScriptCommand currentCommand] setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
        }
    }
}

- (void)removeObjectFromNotesAtIndex:(NSUInteger)anIndex {
    if ([[self pdfDocument] allowsNotes]) {
        PDFAnnotation *note = [[self notes] objectAtIndex:anIndex];
        
        [[self pdfView] removeAnnotation:note];
        [[self undoManager] setActionName:NSLocalizedString(@"Remove Note", @"Undo action name")];
    }
}

- (PDFPage *)currentPage {
    return [[self pdfView] currentPage];
}

- (void)setCurrentPage:(PDFPage *)page {
    return [[self pdfView] goToPage:page];
}

- (id)activeNote {
    id note = [[self pdfView] activeAnnotation];
    return note;
}

- (void)setActiveNote:(id)note {
    if ([note isEqual:[NSNull null]] == NO && [note isSkimNote])
        [[self pdfView] setActiveAnnotation:note];
}

- (NSTextStorage *)richText {
    PDFDocument *doc = [self pdfDocument];
    NSUInteger i, count = [doc pageCount];
    NSTextStorage *textStorage = [[[NSTextStorage alloc] init] autorelease];
    NSAttributedString *attrString;
    [textStorage beginEditing];
    for (i = 0; i < count; i++) {
        if (i > 0)
            [[textStorage mutableString] appendString:@"\n"];
        if ((attrString = [[doc pageAtIndex:i] attributedString]))
            [textStorage appendAttributedString:attrString];
    }
    [textStorage endEditing];
    return textStorage;
}

- (id)selectionSpecifier {
    PDFSelection *sel = [[self pdfView] currentSelection];
    return [sel hasCharacters] ? [sel objectSpecifier] : [NSArray array];
}

- (void)setSelectionSpecifier:(id)specifier {
    PDFSelection *selection = [PDFSelection selectionWithSpecifier:specifier];
    [[self pdfView] setCurrentSelection:selection];
}

- (NSData *)selectionQDRect {
    Rect qdRect = SKQDRectFromNSRect([[self pdfView] currentSelectionRect]);
    return [NSData dataWithBytes:&qdRect length:sizeof(Rect)];
}

- (void)setSelectionQDRect:(NSData *)inQDRectAsData {
    if ([inQDRectAsData length] == sizeof(Rect)) {
        const Rect *qdBounds = (const Rect *)[inQDRectAsData bytes];
        NSRect newBounds = SKNSRectFromQDRect(*qdBounds);
        [[self pdfView] setCurrentSelectionRect:newBounds];
        if ([[self pdfView] currentSelectionPage] == nil)
            [[self pdfView] setCurrentSelectionPage:[[self pdfView] currentPage]];
    }
}

- (id)selectionPage {
    return [[self pdfView] currentSelectionPage];
}

- (void)setSelectionPage:(PDFPage *)page {
    [[self pdfView] setCurrentSelectionPage:[page isKindOfClass:[PDFPage class]] ? page : nil];
}

- (NSArray *)noteSelection {
    return [[self mainWindowController] selectedNotes];
}

- (void)setNoteSelection:(NSArray *)newNoteSelection {
    return [[self mainWindowController] setSelectedNotes:newNoteSelection];
}

- (NSDictionary *)pdfViewSettings {
    return [[self mainWindowController] currentPDFSettings];
}

- (void)setPdfViewSettings:(NSDictionary *)pdfViewSettings {
    [[self mainWindowController] applyPDFSettings:pdfViewSettings];
}

- (NSInteger)toolMode {
    NSInteger toolMode = [[self pdfView] toolMode];
    if (toolMode == SKNoteToolMode)
        toolMode += [[self pdfView] annotationMode];
    return toolMode;
}

- (void)setToolMode:(NSInteger)newToolMode {
    if (newToolMode >= SKNoteToolMode) {
        [[self pdfView] setAnnotationMode:newToolMode - SKNoteToolMode];
        newToolMode = SKNoteToolMode;
    }
    [[self pdfView] setToolMode:newToolMode];
}

- (NSInteger)scriptingInteractionMode {
    NSInteger mode = [[self mainWindowController] interactionMode];
    return mode == SKLegacyFullScreenMode ? SKFullScreenMode : mode;
}

- (void)setScriptingInteractionMode:(NSInteger)mode {
    if (mode == SKNormalMode) {
        if ([[self mainWindowController] canExitFullscreen] || [[self mainWindowController] canExitPresentation])
            [[self mainWindowController] exitFullscreen];
    } else if (mode == SKFullScreenMode) {
        if ([[self mainWindowController] canEnterFullscreen])
            [[self mainWindowController] enterFullscreen];
    } else if (mode == SKPresentationMode) {
        if ([[self mainWindowController] canEnterPresentation])
            [[self mainWindowController] enterPresentation];
    }
}

- (NSDocument *)presentationNotesDocument {
    return [[self mainWindowController] presentationNotesDocument];
}

- (void)setPresentationNotesDocument:(NSDocument *)document {
    if ([document isPDFDocument] && [document countOfPages] == [self countOfPages] && document != self)
        [[self mainWindowController] setPresentationNotesDocument:document];
}

- (BOOL)isPDFDocument {
    return YES;
}

- (id)newScriptingObjectOfClass:(Class)class forValueForKey:(NSString *)key withContentsValue:(id)contentsValue properties:(NSDictionary *)properties {
    if ([key isEqualToString:@"notes"]) {
        PDFAnnotation *annotation = nil;
        id selSpec = contentsValue ?: [properties objectForKey:SKPDFAnnotationSelectionSpecifierKey];
        PDFPage *page = selSpec ? [[PDFSelection selectionWithSpecifier:selSpec] safeFirstPage] : nil;
        if (page == nil || [page document] != [self pdfDocument]) {
            [[NSScriptCommand currentCommand] setScriptErrorNumber:NSReceiversCantHandleCommandScriptError]; 
        } else {
            annotation = [page newScriptingObjectOfClass:class forValueForKey:key withContentsValue:contentsValue properties:properties];
            if ([annotation respondsToSelector:@selector(setPage:)])
                [annotation performSelector:@selector(setPage:) withObject:page];
        }
        return annotation;
    }
    return [super newScriptingObjectOfClass:class forValueForKey:key withContentsValue:contentsValue properties:properties];
}

- (id)copyScriptingValue:(id)value forKey:(NSString *)key withProperties:(NSDictionary *)properties {
    if ([key isEqualToString:@"notes"]) {
        NSMutableArray *copiedValue = [[NSMutableArray alloc] init];
        for (PDFAnnotation *annotation in value) {
            if ([annotation isMovable] && [[annotation page] document] == [self pdfDocument]) {
                PDFAnnotation *copiedAnnotation = [[PDFAnnotation alloc] initSkimNoteWithProperties:[annotation SkimNoteProperties]];
                [copiedAnnotation registerUserName];
                if ([copiedAnnotation respondsToSelector:@selector(setPage:)])
                    [copiedAnnotation performSelector:@selector(setPage:) withObject:[annotation page]];
                if ([properties count])
                    [copiedAnnotation setScriptingProperties:[copiedAnnotation coerceValue:properties forKey:@"scriptingProperties"]];
                [copiedValue addObject:copiedAnnotation];
            } else {
                // we don't want to duplicate markup
                NSScriptCommand *cmd = [NSScriptCommand currentCommand];
                [cmd setScriptErrorNumber:NSReceiversCantHandleCommandScriptError];
                [cmd setScriptErrorString:@"Cannot duplicate markup note."];
                SKDESTROY(copiedValue);
            }
        }
        return copiedValue;
    }
    return [super copyScriptingValue:value forKey:key withProperties:properties];
}

- (id)handleSaveScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id fileType = [args objectForKey:@"FileType"];
    id file = [args objectForKey:@"File"];
    // we don't want to expose the UTI types to the user, and we allow template file names without extension
    if (fileType && file) {
        NSString *normalizedType = nil;
        NSInteger option = SKExportOptionDefault;
        NSArray *writableTypes = [self writableTypesForSaveOperation:NSSaveToOperation];
        SKTemplateManager *tm = [SKTemplateManager sharedManager];
        if ([fileType isEqualToString:@"PDF"]) {
            normalizedType = SKPDFDocumentType;
        } else if ([fileType isEqualToString:@"PDF With Embedded Notes"]) {
            normalizedType = SKPDFDocumentType;
            option = SKExportOptionWithEmbeddedNotes;
        } else if ([fileType isEqualToString:@"PDF Without Notes"]) {
            normalizedType = SKPDFDocumentType;
            option = SKExportOptionWithoutNotes;
        } else if ([fileType isEqualToString:@"PostScript"]) {
            normalizedType = [[NSWorkspace sharedWorkspace] type:[self fileType] conformsToType:SKEncapsulatedPostScriptDocumentType] ? SKEncapsulatedPostScriptDocumentType : SKPostScriptDocumentType;
        } else if ([fileType isEqualToString:@"PostScript Without Notes"]) {
            normalizedType = [[NSWorkspace sharedWorkspace] type:[self fileType] conformsToType:SKEncapsulatedPostScriptDocumentType] ? SKEncapsulatedPostScriptDocumentType : SKPostScriptDocumentType;
            option = SKExportOptionWithoutNotes;
        } else if ([fileType isEqualToString:@"Encapsulated PostScript"]) {
            normalizedType = SKEncapsulatedPostScriptDocumentType;
        } else if ([fileType isEqualToString:@"Encapsulated PostScript Without Notes"]) {
            normalizedType = SKEncapsulatedPostScriptDocumentType;
            option = SKExportOptionWithoutNotes;
        } else if ([fileType isEqualToString:@"DVI"]) {
            normalizedType = SKDVIDocumentType;
        } else if ([fileType isEqualToString:@"DVI Without Notes"]) {
            normalizedType = SKDVIDocumentType;
            option = SKExportOptionWithoutNotes;
        } else if ([fileType isEqualToString:@"XDV"]) {
            normalizedType = SKXDVDocumentType;
        } else if ([fileType isEqualToString:@"XDV Without Notes"]) {
            normalizedType = SKXDVDocumentType;
            option = SKExportOptionWithoutNotes;
        } else if ([fileType isEqualToString:@"PDF Bundle"]) {
            normalizedType = SKPDFBundleDocumentType;
        } else if ([fileType isEqualToString:@"Skim Notes"]) {
            normalizedType = SKNotesDocumentType;
        } else if ([fileType isEqualToString:@"Notes as Text"]) {
            normalizedType = SKNotesTextDocumentType;
        } else if ([fileType isEqualToString:@"Notes as RTF"]) {
            normalizedType = SKNotesRTFDocumentType;
        } else if ([fileType isEqualToString:@"Notes as RTFD"]) {
            normalizedType = SKNotesRTFDDocumentType;
        } else if ([fileType isEqualToString:@"Notes as FDF"]) {
            normalizedType = SKNotesFDFDocumentType;
        } else if ([writableTypes containsObject:fileType] == NO) {
            normalizedType = [tm templateTypeForDisplayName:fileType];
        }
        if ([writableTypes containsObject:normalizedType] || [[tm customTemplateTypes] containsObject:fileType]) {
            mdFlags.exportOption = option;
            NSMutableDictionary *arguments = [[command arguments] mutableCopy];
            if (normalizedType) {
                fileType = normalizedType;
                [arguments setObject:fileType forKey:@"FileType"];
            }
            // for some reason the default implementation adds the extension twice for template types
            if ([[file pathExtension] isCaseInsensitiveEqual:[tm fileNameExtensionForTemplateType:fileType]])
                [arguments setObject:[file URLByDeletingPathExtension] forKey:@"File"];
            [command setArguments:arguments];
            [arguments release];
        }
    }
    return [super handleSaveScriptCommand:command];
}

- (void)handleRevertScriptCommand:(NSScriptCommand *)command {
    if ([self fileURL] && [[self fileURL] checkResourceIsReachableAndReturnError:NULL]) {
        if ([fileUpdateChecker isUpdatingFile] == NO && [self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:NULL] == NO) {
            [command setScriptErrorNumber:NSInternalScriptError];
            [command setScriptErrorString:@"Revert failed."];
        }
    } else {
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
        [command setScriptErrorString:@"File does not exist."];
    }
}

- (void)handleGoToScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id location = [args objectForKey:@"To"];
    
    if ([location isKindOfClass:[PDFPage class]]) {
        [[self pdfView] goToPage:(PDFPage *)location];
    } else if ([location isKindOfClass:[PDFAnnotation class]]) {
        [[self pdfView] scrollAnnotationToVisible:(PDFAnnotation *)location];
    } else if ([location isKindOfClass:[SKLine class]]) {
        id source = [args objectForKey:@"Source"];
        BOOL showBar = [[args objectForKey:@"ShowReadingBar"] boolValue];
        NSInteger options = showBar ? SKPDFSynchronizerShowReadingBarMask : 0;
        if ([source isKindOfClass:[NSString class]])
            source = [NSURL fileURLWithPath:source];
        else if ([source isKindOfClass:[NSURL class]] == NO)
            source = nil;
        [[self synchronizer] findPageAndLocationForLine:[location index] inFile:[source path] options:options];
    } else {
        PDFSelection *selection = [PDFSelection selectionWithSpecifier:[[command arguments] objectForKey:@"To"]];
        if ([selection hasCharacters]) {
            PDFPage *page = [selection safeFirstPage];
            NSRect bounds = [selection boundsForPage:page];
            [[self pdfView] goToRect:bounds onPage:page];
        }
    }
}

- (id)handleFindScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id text = [args objectForKey:@"Text"];
    id specifier = nil;
    
    if ([text isKindOfClass:[NSString class]] == NO) {
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
        [command setScriptErrorString:@"The text to find is missing or is not a string."];
        return nil;
    } else {
        id from = [[command arguments] objectForKey:@"From"];
        id backward = [args objectForKey:@"Backward"];
        id caseSensitive = [args objectForKey:@"CaseSensitive"];
        PDFSelection *selection = nil;
        NSInteger options = 0;
        
        if (from)
            selection = [PDFSelection selectionWithSpecifier:from];
        
        if ([backward isKindOfClass:[NSNumber class]] && [backward boolValue])
            options |= NSBackwardsSearch;
        if ([caseSensitive isKindOfClass:[NSNumber class]] == NO || [caseSensitive boolValue] == NO)
            options |= NSCaseInsensitiveSearch;
        
        if ((selection = [[self pdfDocument] findString:text fromSelection:selection withOptions:options]))
            specifier = [selection objectSpecifier];
    }
    
    return specifier ?: [NSArray array];
}

- (void)handleShowTeXScriptCommand:(NSScriptCommand *)command {
	NSDictionary *args = [command evaluatedArguments];
    id page = [args objectForKey:@"Page"];
    id pointData = [args objectForKey:@"Point"];
    NSPoint point = NSZeroPoint;
    
    if ([page isKindOfClass:[PDFPage class]] == NO)
        page = [[self pdfView] currentPage];
    if ([pointData isKindOfClass:[NSDate class]] && [pointData length] != sizeof(Point)) {
        const Point *qdPoint = (const Point *)[pointData bytes];
        point = SKNSPointFromQDPoint(*qdPoint);
    } else {
        NSRect bounds = [page boundsForBox:[[self pdfView] displayBox]];
        point = NSMakePoint(NSMidX(bounds), NSMidY(bounds));
    }
    if (page) {
        NSUInteger pageIndex = [page pageIndex];
        PDFSelection *sel = [page selectionForLineAtPoint:point];
        NSRect rect = [sel hasCharacters] ? [sel boundsForPage:page] : NSMakeRect(point.x - 20.0, point.y - 5.0, 40.0, 10.0);
        
        [[self synchronizer] findFileAndLineForLocation:point inRect:rect pageBounds:[page boundsForBox:kPDFDisplayBoxMediaBox] atPageIndex:pageIndex];
    }
}

- (void)handleConvertNotesScriptCommand:(NSScriptCommand *)command {
    if ([[NSWorkspace sharedWorkspace] type:[self fileType] conformsToType:SKPDFDocumentType] == NO && [[NSWorkspace sharedWorkspace] type:[self fileType] conformsToType:SKPDFBundleDocumentType] == NO) {
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
    } else if (mdFlags.convertingNotes || [[self pdfDocument] isLocked]) {
        [command setScriptErrorNumber:NSInternalScriptError];
    } else if ([self hasConvertibleAnnotations]) {
        NSDictionary *args = [command evaluatedArguments];
        NSNumber *wait = [args objectForKey:@"Wait"];
        [self convertNotesSheetDidEnd:nil returnCode:NSAlertFirstButtonReturn contextInfo:NULL];
        if (wait == nil || [wait boolValue])
            while (mdFlags.convertingNotes == 1 && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    }
}

- (void)handleReadNotesScriptCommand:(NSScriptCommand *)command {
    NSDictionary *args = [command evaluatedArguments];
    NSURL *notesURL = [args objectForKey:@"File"];
    if (notesURL == nil) {
        [command setScriptErrorNumber:NSRequiredArgumentsMissingScriptError];
    } else if ([[self pdfDocument] isLocked]) {
        [command setScriptErrorNumber:NSInternalScriptError];
    } else {
        NSNumber *replaceNumber = [args objectForKey:@"Replace"];
        NSString *fileType = [[NSDocumentController sharedDocumentController] typeForContentsOfURL:notesURL error:NULL];
        if ([[NSWorkspace sharedWorkspace] type:fileType conformsToType:SKNotesDocumentType])
            [self readNotesFromURL:notesURL replace:(replaceNumber ? [replaceNumber boolValue] : YES)];
        else
            [command setScriptErrorNumber:NSArgumentsWrongScriptError];
    }
}

@end


@implementation NSWindow (SKScriptingExtensions)

- (void)handleRevertScriptCommand:(NSScriptCommand *)command {
    id document = [[self windowController] document];
    if (document == nil) {
        [command setScriptErrorNumber:NSArgumentsWrongScriptError];
        [command setScriptErrorString:@"Window does not have a document."];
    } else
        [document handleRevertScriptCommand:command];
}

@end