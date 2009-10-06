//
//  SKPTSinkTransitionFilter.m
//  SinkTransition
//
//  Created by Christiaan on 10/6/09.
//  Copyright Christiaan Hofman 2009. All rights reserved.
//

#import "SKPTSinkTransitionFilter.h"
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation SKPTSinkTransitionFilter

static CIKernel *_SKPTSinkTransitionFilterKernel = nil;

- (id)init
{
    if(_SKPTSinkTransitionFilterKernel == nil)
    {
		NSBundle    *bundle = [NSBundle bundleForClass:NSClassFromString(@"SKPTSinkTransitionFilter")];
		NSStringEncoding encoding = NSUTF8StringEncoding;
		NSError     *error = nil;
		NSString    *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"SKPTSinkTransitionFilterKernel" ofType:@"cikernel"] encoding:encoding error:&error];
		NSArray     *kernels = [CIKernel kernelsWithString:code];

		_SKPTSinkTransitionFilterKernel = [[kernels objectAtIndex:0] retain];
    }
    return [super init];
}

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:

        [NSDictionary dictionaryWithObjectsAndKeys:
            [CIVector vectorWithX:150.0 Y:150.0], kCIAttributeDefault,
            kCIAttributeTypePosition,          kCIAttributeType,
            nil],                              @"inputCenter",
 
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
            [NSNumber numberWithDouble:  1.0], kCIAttributeMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:  1.0], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:  0.0], kCIAttributeDefault,
            [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
            kCIAttributeTypeTime,              kCIAttributeType,
            nil],                              @"inputTime",

        nil];
}

- (CGRect)regionOf:(int)sampler destRect:(CGRect)R userInfo:(CISampler *)img {
    return [img extent];
}

// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage
{
    float t = [inputTime floatValue];
    CISampler *src = [CISampler samplerWithImage:t < 0.5 ? inputImage : inputTargetImage];
    
    NSArray *arguments = [NSArray arrayWithObjects:src, inputCenter, [NSNumber numberWithFloat:1.0 - fabs(2.0 * t - 1.0)], nil];
    NSDictionary *options  = [NSDictionary dictionaryWithObjectsAndKeys:[src definition], kCIApplyOptionDefinition, src, kCIApplyOptionUserInfo, nil];
    
    [_SKPTSinkTransitionFilterKernel setROISelector:@selector(regionOf:forRect:userInfo:)];
    
    return [self apply:_SKPTSinkTransitionFilterKernel arguments:arguments options:options];
}

@end
