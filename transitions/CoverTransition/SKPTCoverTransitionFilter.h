//
//  SKPTCoverTransitionFilter.h
//  CoverTransition
//
//  Created by Christiaan on 10/6/09.
//  Copyright Christiaan Hofman 2009. All rights reserved.

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>


@interface SKPTCoverTransitionFilter : CIFilter
{
    CIImage     *inputImage;
    CIImage     *inputTargetImage;
    CIVector    *inputExtent;
    NSNumber    *inputAngle;
    NSNumber    *inputTime;
}
@end
