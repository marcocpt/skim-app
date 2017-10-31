//
//  PDFSelection_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 4/24/07.
/*
 This software is Copyright (c) 2007-2010
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

#import "PDFSelection_SKExtensions.h"
#import "NSString_SKExtensions.h"
#import "NSParagraphStyle_SKExtensions.h"
#import "PDFPage_SKExtensions.h"
#import "SKStringConstants.h"
#import "SKMainDocument.h"
#import "NSPointerArray_SKExtensions.h"

#define ELLIPSIS_CHARACTER 0x2026

@interface PDFSelection (PDFSelectionPrivateDeclarations)
// defined on 10.6
- (NSIndexSet *)indexOfCharactersOnPage:(PDFPage *)page;
// defined and used on 10.4 & 10.5
- (NSInteger)numberOfRangesOnPage:(PDFPage *)page;
- (NSRange)rangeAtIndex:(NSInteger)index onPage:(PDFPage *)page;
@end


@implementation PDFSelection (SKExtensions)

// returns the label of the first page (if the selection spans multiple pages)
- (NSString *)firstPageLabel { 
    return [[self safeFirstPage] displayLabel];
}

- (NSString *)cleanedString {
	return [[[self string] stringByRemovingAliens] stringByCollapsingWhitespaceAndNewlinesAndRemovingSurroundingWhitespaceAndNewlines];
}

- (NSAttributedString *)contextString {
    PDFSelection *extendedSelection = [self copy];
	NSMutableAttributedString *attributedSample;
	NSString *searchString = [self cleanedString];
	NSString *sample;
    NSMutableString *attributedString;
	NSString *ellipse = [NSString stringWithFormat:@"%C", ELLIPSIS_CHARACTER];
	NSRange foundRange;
    NSDictionary *attributes;
    NSNumber *fontSizeNumber = [[NSUserDefaults standardUserDefaults] objectForKey:SKTableFontSizeKey];
	CGFloat fontSize = fontSizeNumber ? [fontSizeNumber doubleValue] : 0.0;
    
	// Extend selection.
	[extendedSelection extendSelectionAtStart:10];
	[extendedSelection extendSelectionAtEnd:50];
	
    // get the cleaned string
    sample = [extendedSelection cleanedString];
    
	// Finally, create attributed string.
 	attributedSample = [[NSMutableAttributedString alloc] initWithString:sample];
    attributedString = [attributedSample mutableString];
    [attributedString insertString:ellipse atIndex:0];
    [attributedString appendString:ellipse];
	
	// Find instances of search string and "bold" them.
	foundRange = [sample rangeOfString:searchString options:NSCaseInsensitiveSearch];
    if (foundRange.location != NSNotFound) {
        // Bold the text range where the search term was found.
        attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont boldSystemFontOfSize:fontSize], NSFontAttributeName, nil];
        [attributedSample setAttributes:attributes range:NSMakeRange(foundRange.location + 1, foundRange.length)];
        [attributes release];
    }
    
	attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSParagraphStyle defaultTruncatingTailParagraphStyle], NSParagraphStyleAttributeName, nil];
	// Add paragraph style.
    [attributedSample addAttributes:attributes range:NSMakeRange(0, [attributedSample length])];
	// Clean.
	[attributes release];
	[extendedSelection release];
	
	return [attributedSample autorelease];
}

- (PDFDestination *)destination {
    PDFDestination *destination = nil;
    PDFPage *page = [self safeFirstPage];
    if (page) {
        NSRect bounds = [self boundsForPage:page];
        destination = [[[PDFDestination alloc] initWithPage:page atPoint:NSMakePoint(NSMinX(bounds), NSMaxY(bounds))] autorelease];
    }
    return destination;
}

- (NSUInteger)safeIndexOfFirstCharacterOnPage:(PDFPage *)page {
    if ([self respondsToSelector:@selector(indexOfCharactersOnPage:)]) {
        NSIndexSet *indexes = [self indexOfCharactersOnPage:page];
        if (indexes)
            return [indexes firstIndex];
    } else if ([self respondsToSelector:@selector(numberOfRangesOnPage:)] && [self respondsToSelector:@selector(rangeAtIndex:onPage:)]) {
        NSInteger n = [self numberOfRangesOnPage:page];
        if (n)
            return [self rangeAtIndex:0 onPage:page].location;
    }
    return NSNotFound;
}

- (NSUInteger)safeIndexOfLastCharacterOnPage:(PDFPage *)page {
    if ([self respondsToSelector:@selector(indexOfCharactersOnPage:)]) {
        NSIndexSet *indexes = [self indexOfCharactersOnPage:page];
        if (indexes)
            return [indexes lastIndex];
    } else if ([self respondsToSelector:@selector(numberOfRangesOnPage:)] && [self respondsToSelector:@selector(rangeAtIndex:onPage:)]) {
        NSInteger n = [self numberOfRangesOnPage:page];
        if (n)
            return NSMaxRange([self rangeAtIndex:n - 1 onPage:page]);
    }
    return NSNotFound;
}

- (NSArray *)safeRangesOnPage:(PDFPage *)page {
    if ([self respondsToSelector:@selector(indexOfCharactersOnPage:)]) {
        NSIndexSet *indexes = [self indexOfCharactersOnPage:page];
        NSUInteger idx = [indexes firstIndex];
        NSUInteger prevIdx = NSNotFound;
        NSRange range = NSMakeRange(NSNotFound, 0);
        NSMutableArray *ranges = [NSMutableArray array];
        while (idx != NSNotFound) {
            if (prevIdx == NSNotFound || idx != prevIdx + 1) {
                if (range.length)
                    [ranges addObject:[NSValue valueWithRange:range]];
                range = NSMakeRange(idx, 1);
            } else {
                range.length++;
            }
            prevIdx = idx;
            idx = [indexes indexGreaterThanIndex:idx];
        }
        if (range.length)
            [ranges addObject:[NSValue valueWithRange:range]];
        return ranges;
    } else if ([self respondsToSelector:@selector(numberOfRangesOnPage:)] && [self respondsToSelector:@selector(rangeAtIndex:onPage:)]) {
        NSInteger i, iMax = [self numberOfRangesOnPage:page];
        NSMutableArray *ranges = [NSMutableArray array];
        for (i = 0; i < iMax; i++)
            [ranges addObject:[NSValue valueWithRange:[self rangeAtIndex:i onPage:page]]];
        return ranges;
    }
    return nil;
}

- (PDFPage *)safeFirstPage {
    if ([self respondsToSelector:@selector(indexOfCharactersOnPage:)]) {
        for (PDFPage *page in [self pages]) {
            if ([[self indexOfCharactersOnPage:page] firstIndex] != NSNotFound)
                return page;
        }
    } else if ([self respondsToSelector:@selector(numberOfRangesOnPage:)] && [self respondsToSelector:@selector(rangeAtIndex:onPage:)]) {
        for (PDFPage *page in [self pages]) {
            NSInteger i, count = [self numberOfRangesOnPage:page];
            for (i = 0; i < count; i++) {
                if ([self rangeAtIndex:i onPage:page].length > 0)
                    return page;
            }
        }
    } else {
        for (PDFPage *page in [self pages]) {
            if (NSIsEmptyRect([self boundsForPage:page]) == NO)
                return page;
        }
    }
    return nil;
}

- (PDFPage *)safeLastPage {
    if ([self respondsToSelector:@selector(indexOfCharactersOnPage:)]) {
        for (PDFPage *page in [self pages]) {
            if ([[self indexOfCharactersOnPage:page] firstIndex] != NSNotFound)
                return page;
        }
    } else if ([self respondsToSelector:@selector(numberOfRangesOnPage:)] && [self respondsToSelector:@selector(rangeAtIndex:onPage:)]) {
        for (PDFPage *page in [self pages]) {
            NSInteger i, count = [self numberOfRangesOnPage:page];
            for (i = 0; i < count; i++) {
                if ([self rangeAtIndex:i onPage:page].length > 0)
                    return page;
            }
        }
    } else {
        for (PDFPage *page in [self pages]) {
            if (NSIsEmptyRect([self boundsForPage:page]) == NO)
                return page;
        }
    }
    return nil;
}

- (BOOL)hasCharacters {
    if ([self respondsToSelector:@selector(indexOfCharactersOnPage:)]) {
        for (PDFPage *page in [self pages]) {
            if ([[self indexOfCharactersOnPage:page] firstIndex] != NSNotFound)
                return YES;
        }
        return NO;
    } else if ([self respondsToSelector:@selector(numberOfRangesOnPage:)] && [self respondsToSelector:@selector(rangeAtIndex:onPage:)]) {
        for (PDFPage *page in [self pages]) {
            NSInteger i, count = [self numberOfRangesOnPage:page];
            for (i = 0; i < count; i++) {
                if ([self rangeAtIndex:i onPage:page].length > 0)
                    return YES;
            }
        }
        return NO;
    } else {
        return [[self string] length] > 0;
    }
}

static inline NSRange rangeOfSubstringOfStringAtIndex(NSString *string, NSArray *substrings, NSUInteger anIndex) {
    NSUInteger length = [string length];
    NSRange range = NSMakeRange(0, 0);
    
    if (anIndex >= [substrings count])
        return NSMakeRange(NSNotFound, 0);
    for (NSString *substring in substrings) {
        NSRange searchRange = NSMakeRange(NSMaxRange(range), length - NSMaxRange(range));
        if ([substring length] == 0)
            continue;
        range = [string rangeOfString:substring options:NSLiteralSearch range:searchRange];
        if (range.location == NSNotFound)
            return NSMakeRange(NSNotFound, 0);
    }
    return range;
}

static NSArray *characterRangesAndContainersForSpecifier(NSScriptObjectSpecifier *specifier, BOOL continuous, BOOL continuousContainers) {
    if ([specifier isKindOfClass:[NSScriptObjectSpecifier class]] == NO)
        return nil;
    
    NSMutableArray *rangeDicts = [NSMutableArray array];
    NSString *key = [specifier key];
    
    if ([key isEqualToString:@"characters"] || [key isEqualToString:@"words"] || [key isEqualToString:@"paragraphs"] || [key isEqualToString:@"attributeRuns"]) {
        
        // get the richText specifier and textStorage
        NSArray *dicts = characterRangesAndContainersForSpecifier([specifier containerSpecifier], continuousContainers, continuousContainers);
        if ([dicts count] == 0)
            return nil;
        
        for (NSMutableDictionary *dict in dicts) {
            NSTextStorage *containerText = [dict objectForKey:@"text"];
            NSPointerArray *textRanges = [dict objectForKey:@"ranges"];
            NSUInteger ri, numRanges = [textRanges count];
            NSPointerArray *ranges = [[NSPointerArray alloc] initForRangePointers];
            
            for (ri = 0; ri < numRanges; ri++) {
                NSRange textRange = *(NSRange *)[textRanges pointerAtIndex:ri];
                NSTextStorage *textStorage = nil;
                if (NSEqualRanges(textRange, NSMakeRange(0, [containerText length])))
                    textStorage = [containerText retain];
                else
                    textStorage = [[NSTextStorage alloc] initWithAttributedString:[containerText attributedSubstringFromRange:textRange]];
                
                // now get the ranges, which can be any kind of specifier
                NSInteger startIndex, endIndex, i, count, *indices;
                NSPointerArray *tmpRanges = [[NSPointerArray alloc] initForRangePointers];
                
                if ([specifier isKindOfClass:[NSPropertySpecifier class]]) {
                    // this should be the full range of characters, words, or paragraphs
                    NSRange range = NSMakeRange(0, [[textStorage valueForKey:key] count]);
                    if (range.length)
                        [tmpRanges addPointer:&range];
                } else if ([specifier isKindOfClass:[NSRangeSpecifier class]]) {
                    // somehow getting the indices as for the general case sometimes leads to an exception for NSRangeSpecifier, so we get the indices of the start/endSpecifiers
                    NSScriptObjectSpecifier *startSpec = [(NSRangeSpecifier *)specifier startSpecifier];
                    NSScriptObjectSpecifier *endSpec = [(NSRangeSpecifier *)specifier endSpecifier];
                    
                    if (startSpec || endSpec) {
                        if (startSpec) {
                            indices = [startSpec indicesOfObjectsByEvaluatingWithContainer:textStorage count:&count];
                            startIndex = count ? indices[0] : -1;
                        } else {
                            startIndex = 0;
                        }
                        if (endSpec) {
                            indices = [endSpec indicesOfObjectsByEvaluatingWithContainer:textStorage count:&count];
                            endIndex = count ? indices[count - 1] : -1;
                        } else {
                            endIndex = [[textStorage valueForKey:key] count] - 1;
                        }
                        if (startIndex >= 0 && endIndex >= 0) {
                            NSRange range = NSMakeRange(MIN(startIndex, endIndex), MAX(startIndex, endIndex) + 1 - MIN(startIndex, endIndex));
                            [tmpRanges addPointer:&range];
                        }
                    }
                } else {
                    // this handles other objectSpecifiers (index, middel, random, relative, whose). It can contain several ranges, e.g. for aan NSWhoseSpecifier
                    indices = [specifier indicesOfObjectsByEvaluatingWithContainer:textStorage count:&count];
                    NSRange range = NSMakeRange(0, 0);
                    for (i = 0; i < count; i++) {
                        NSUInteger idx = indices[i];
                        if (range.length = 0 || idx > NSMaxRange(range)) {
                            if (range.length)
                                [tmpRanges addPointer:&range];
                            range = NSMakeRange(idx, 1);
                        } else {
                            ++(range.length);
                        }
                    }
                    if (range.length)
                        [tmpRanges addPointer:&range];
                }
                
                count = [tmpRanges count];
                if (count == 0) {
                } else if ([key isEqualToString:@"characters"]) {
                    for (i = 0; i < count; i++) {
                        NSRange range = *(NSRange *)[tmpRanges pointerAtIndex:i];
                        range.location += textRange.location;
                        range = NSIntersectionRange(range, textRange);
                        if (range.length) {
                            if (continuous) {
                                [ranges addPointer:&range];
                            } else {
                                NSUInteger j;
                                for (j = range.location; j < NSMaxRange(range); j++) {
                                    NSRange r = NSMakeRange(j, 1);
                                    [ranges addPointer:&r];
                                }
                            }
                        }
                    }
                } else {
                    // translate from subtext ranges to character ranges
                    NSString *string = [textStorage string];
                    NSArray *substrings = [[textStorage valueForKey:key] valueForKey:@"string"];
                    if ([substrings count]) {
                        for (i = 0; i < count; i++) {
                            NSRange range = *(NSRange *)[tmpRanges pointerAtIndex:i];
                            startIndex = MIN(range.location, [substrings count] - 1);
                            endIndex = MIN(NSMaxRange(range) - 1, [substrings count] - 1);
                            if (endIndex == startIndex) endIndex = -1;
                            if (continuous) {
                                range = rangeOfSubstringOfStringAtIndex(string, substrings, startIndex);
                                if (range.location == NSNotFound)
                                    continue;
                                startIndex = range.location;
                                if (endIndex >= 0) {
                                    range = rangeOfSubstringOfStringAtIndex(string, substrings, endIndex);
                                    if (range.location == NSNotFound)
                                        continue;
                                }
                                endIndex = NSMaxRange(range) - 1;
                                range = NSMakeRange(textRange.location + startIndex, endIndex + 1 - startIndex);
                                [ranges addPointer:&range];
                            } else {
                                if (endIndex == -1) endIndex = startIndex;
                                NSInteger j;
                                for (j = startIndex; j <= endIndex; j++) {
                                    range = rangeOfSubstringOfStringAtIndex(string, substrings, j);
                                    if (range.location == NSNotFound)
                                        continue;
                                    range.location += textRange.location;
                                    [ranges addPointer:&range];
                                }
                            }
                        }
                    }
                }
                
                [tmpRanges release];
                [textStorage release];
            }
            
            if ([ranges count]) {
                [dict setObject:ranges forKey:@"ranges"];
                [rangeDicts addObject:dict];
            }
            [ranges release];
        }
        
    } else {
        
        NSScriptClassDescription *classDesc = [specifier keyClassDescription];
        if ([[classDesc className] isEqualToString:@"rich text"]) {
            if ([[[specifier containerClassDescription] toManyRelationshipKeys] containsObject:key])
                return nil;
            specifier = [specifier containerSpecifier];
        } else {
            key = [classDesc defaultSubcontainerAttributeKey];
            if (key == nil || [[[classDesc classDescriptionForKey:key] className] isEqualToString:@"rich text"] == NO)
                return nil;
        }
        
        NSArray *containers = [specifier objectsByEvaluatingSpecifier];
        if (containers && [containers isKindOfClass:[NSArray class]] == NO)
            containers = [NSArray arrayWithObject:containers];
        if ([containers count] == 0)
            return nil;
        
        for (id container in containers) {
            NSTextStorage *containerText = [container valueForKey:key];
            if ([containerText isKindOfClass:[NSTextStorage class]] == NO || [containerText length] == 0)
                continue;
            NSPointerArray *ranges = [[NSPointerArray alloc] initForRangePointers];
            NSRange range = NSMakeRange(0, [containerText length]);
            [ranges addPointer:&range];
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:ranges, @"ranges", containerText, @"text", container, @"container", nil];
            [rangeDicts addObject:dict];
            [dict release];
            [ranges release];
        }
        
    }
    
    return rangeDicts;
}

+ (id)selectionWithSpecifier:(id)specifier {
    return [self selectionWithSpecifier:specifier onPage:nil];
}

+ (id)selectionWithSpecifier:(id)specifier onPage:(PDFPage *)aPage {
    if (specifier == nil || [specifier isEqual:[NSNull null]])
        return nil;
    if ([specifier isKindOfClass:[NSArray class]] == NO)
        specifier = [NSArray arrayWithObject:specifier];
    if ([specifier count] == 1) {
        NSScriptObjectSpecifier *spec = [specifier objectAtIndex:0];
        if ([spec isKindOfClass:[NSPropertySpecifier class]]) {
            NSString *key = [spec key];
            if ([[NSSet setWithObjects:@"characters", @"words", @"paragraphs", @"attributeRuns", @"richText", @"pages", nil] containsObject:key] == NO) {
                // this allows to use selection properties directly
                specifier = [spec objectsByEvaluatingSpecifier];
                if ([specifier isKindOfClass:[NSArray class]] == NO)
                    specifier = [NSArray arrayWithObject:specifier];
            }
        }
    }
    
    NSMutableArray *selections = [NSMutableArray array];
    
    for (NSScriptObjectSpecifier *spec in specifier) {
        if ([spec isKindOfClass:[NSScriptObjectSpecifier class]] == NO)
            continue;
        
        NSArray *dicts = characterRangesAndContainersForSpecifier(spec, YES, NO);
        PDFDocument *doc = nil;
        
        for (NSDictionary *dict in dicts) {
            id container = [dict objectForKey:@"container"];
            NSPointerArray *ranges = [dict objectForKey:@"ranges"];
            NSUInteger i, numRanges = [ranges count];
            
            if ([container isKindOfClass:[SKMainDocument class]] && (doc == nil || [doc isEqual:[container pdfDocument]])) {
                
                PDFDocument *document = [container pdfDocument];
                NSUInteger aPageIndex = (aPage ? [aPage pageIndex] : NSNotFound), page, numPages = [document pageCount];
                NSUInteger *pageLengths = NSZoneMalloc(NSDefaultMallocZone(), numPages * sizeof(NSUInteger));
                
                for (page = 0; page < numPages; page++)
                    pageLengths[page] = NSNotFound;
                
                for (i = 0; i < numRanges; i++) {
                    NSRange range = *(NSRange *)[ranges pointerAtIndex:i];
                    NSUInteger pageStart = 0, startPage = NSNotFound, endPage = NSNotFound, startIndex = NSNotFound, endIndex = NSNotFound;
                    
                    for (page = 0; (page < numPages) && (pageStart < NSMaxRange(range)); page++) {
                        if (pageLengths[page] == NSNotFound)
                            pageLengths[page] = [[[document pageAtIndex:page] attributedString] length];
                        if ((aPageIndex == NSNotFound || page == aPageIndex) && pageLengths[page] && range.location < pageStart + pageLengths[page]) {
                            if (startPage == NSNotFound && startIndex == NSNotFound) {
                                startPage = page;
                                startIndex = MAX(pageStart, range.location) - pageStart;
                            }
                            if (startPage != NSNotFound && startIndex != NSNotFound) {
                                endPage = page;
                                endIndex = MIN(NSMaxRange(range) - pageStart, pageLengths[page]) - 1;
                            }
                        }
                        pageStart += pageLengths[page] + 1; // text of pages is separated by newlines, see -[SKMainDocument richText]
                    }
                    
                    if (startPage != NSNotFound && startIndex != NSNotFound && endPage != NSNotFound && endIndex != NSNotFound) {
                        PDFSelection *sel = [document selectionFromPage:[document pageAtIndex:startPage] atCharacterIndex:startIndex toPage:[document pageAtIndex:endPage] atCharacterIndex:endIndex];
                        if ([sel hasCharacters]) {
                            [selections addObject:sel];
                            doc = document;
                        }
                    }
                }
                
                NSZoneFree(NSDefaultMallocZone(), pageLengths);
                
            } else if ([container isKindOfClass:[PDFPage class]] && (aPage == nil || [aPage isEqual:container]) && (doc == nil || [doc isEqual:[container document]])) {
                
                for (i = 0; i < numRanges; i++) {
                    PDFSelection *sel;
                    NSRange range = *(NSRange *)[ranges pointerAtIndex:i];
                    if (range.length && (sel = [container selectionForRange:range]) && [sel hasCharacters]) {
                        [selections addObject:sel];
                        doc = [container document];
                    }
                }
                
            }
        }
    }
    
    PDFSelection *selection = nil;
    if ([selections count]) {
        selection = [selections objectAtIndex:0];
        if ([selections count] > 1) {
            [selections removeObjectAtIndex:0];
            [selection addSelections:selections];
        }
    }
    return selection;
}

static inline void addSpecifierWithCharacterRangeAndPage(NSMutableArray *ranges, NSRange range, PDFPage *page) {
    NSRangeSpecifier *rangeSpec = nil;
    NSIndexSpecifier *startSpec = nil;
    NSIndexSpecifier *endSpec = nil;
    NSScriptObjectSpecifier *textSpec = [[NSPropertySpecifier alloc] initWithContainerSpecifier:[page objectSpecifier] key:@"richText"];
    
    if (textSpec) {
        if (startSpec = [[NSIndexSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" index:range.location]) {
            if (range.length == 1) {
                [ranges addObject:startSpec];
            } else if ((endSpec = [[NSIndexSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" index:NSMaxRange(range) - 1]) &&
                       (rangeSpec = [[NSRangeSpecifier alloc] initWithContainerClassDescription:[textSpec keyClassDescription] containerSpecifier:textSpec key:@"characters" startSpecifier:startSpec endSpecifier:endSpec])) {
                [ranges addObject:rangeSpec];
                [rangeSpec release];
            }
            [startSpec release];
            [endSpec release];
        }
        [textSpec release];
    }
}

- (id)objectSpecifier {
    NSMutableArray *ranges = [NSMutableArray array];
    for (PDFPage *page in [self pages]) {
        NSRange lastRange = NSMakeRange(0, 0);
        for (NSValue *value in [self safeRangesOnPage:page]) {
            NSRange range = [value rangeValue];
            if (range.length == 0) {
            } else if (lastRange.length == 0) {
                lastRange = range;
            } else if (NSMaxRange(lastRange) == range.location) {
                lastRange.length += range.length;
            } else {
                addSpecifierWithCharacterRangeAndPage(ranges, lastRange, page);
                lastRange = range;
            }
        }
        if (lastRange.length)
            addSpecifierWithCharacterRangeAndPage(ranges, lastRange, page);
    }
    return ranges;
}

@end