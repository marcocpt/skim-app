//
//  NSMenu_SKExtensions.m
//  Skim
//
//  Created by Christiaan Hofman on 6/11/08.
/*
 This software is Copyright (c) 2008
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

#import "NSMenu_SKExtensions.h"


@implementation NSMenu (SKExtensions)

- (NSMenuItem *)supermenuItem {
    NSMenu *supermenu = [self supermenu];
    NSInteger idx = [supermenu indexOfItemWithSubmenu:self];
    return idx == -1 ? nil : [supermenu itemAtIndex:idx];
}

- (NSMenuItem *)insertItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget atIndex:(NSInteger)anIndex {
    NSMenuItem *item = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:aString action:aSelector target:aTarget];
    [self insertItem:item atIndex:anIndex];
    [item release];
    return item;
}

- (NSMenuItem *)addItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget {
    return [self insertItemWithTitle:aString action:aSelector target:aTarget atIndex:[self numberOfItems]];
}

- (NSMenuItem *)insertItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget tag:(NSInteger)aTag atIndex:(NSInteger)anIndex {
    NSMenuItem *item = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:aString action:aSelector target:aTarget tag:aTag];
    [self insertItem:item atIndex:anIndex];
    [item release];
    return item;
}

- (NSMenuItem *)addItemWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget tag:(NSInteger)aTag {
    return [self insertItemWithTitle:aString action:aSelector target:aTarget tag:aTag atIndex:[self numberOfItems]];
}

- (NSMenuItem *)insertItemWithTitle:(NSString *)aString image:(NSImage *)anImage action:(SEL)aSelector target:(id)aTarget tag:(NSInteger)aTag atIndex:(NSInteger)anIndex {
    NSMenuItem *item = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:aString image:anImage action:aSelector target:aTarget tag:aTag];
    [self insertItem:item atIndex:anIndex];
    [item release];
    return item;
}

- (NSMenuItem *)addItemWithTitle:(NSString *)aString image:(NSImage *)anImage action:(SEL)aSelector target:(id)aTarget tag:(NSInteger)aTag {
    return [self insertItemWithTitle:aString image:anImage action:aSelector target:aTarget tag:aTag atIndex:[self numberOfItems]];
}

- (NSMenuItem *)insertItemWithTitle:(NSString *)aString submenu:(NSMenu *)aSubmenu atIndex:(NSInteger)anIndex {
    NSMenuItem *item = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:aString submenu:aSubmenu];
    [self insertItem:item atIndex:anIndex];
    [item release];
    return item;
}

- (NSMenuItem *)addItemWithTitle:(NSString *)aString submenu:(NSMenu *)aSubmenu {
    return [self insertItemWithTitle:aString submenu:aSubmenu atIndex:[self numberOfItems]];
}

@end


@implementation NSMenuItem (SKExtensions)

- (id)initWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget {
    return [self initWithTitle:aString image:nil action:aSelector target:aTarget tag:0];
}

- (id)initWithTitle:(NSString *)aString action:(SEL)aSelector target:(id)aTarget tag:(NSInteger)aTag {
    return [self initWithTitle:aString image:nil action:aSelector target:aTarget tag:aTag];
}

- (id)initWithTitle:(NSString *)aString image:(NSImage *)anImage action:(SEL)aSelector target:(id)aTarget tag:(NSInteger)aTag {
    if (self = [self initWithTitle:aString action:aSelector keyEquivalent:@""]) {
        [self setImage:anImage];
        [self setTarget:aTarget];
        [self setTag:aTag];
    }
    return self;
}

- (id)initWithTitle:(NSString *)aString submenu:(NSMenu *)aSubmenu {
    if (self = [self initWithTitle:aString action:NULL keyEquivalent:@""]) {
        [self setSubmenu:aSubmenu];
    }
    return self;
}

@end
