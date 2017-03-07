//
//  SKPTBlindsTransitionFilter.h
//  BlindsTransition
//
//  Created by Christiaan on 10/6/09.
//  Copyright Christiaan Hofman 2009. All rights reserved.

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>


@interface SKPTBlindsTransitionFilter : CIFilter
{
    CIImage     *inputImage;
    CIImage     *inputTargetImage;
    NSNumber    *inputWidth;
    NSNumber    *inputTime;
}

@end