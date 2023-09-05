//
//  NSArrayTransformer.m
//  ZeroTV
//
//  Created by Jeremy Blaker on 9/5/23.
//

#import "NSArrayTransformer.h"

@implementation NSArrayTransformer

+ (Class)transformedValueClass
{
    return [NSArray class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

//- (id)transformedValue:(id)value
//{
//    // Implement the transformation from raw to property representation
//    // Return the transformed value
//}
//
//- (id)reverseTransformedValue:(id)value
//{
//    // Implement the reverse transformation from property to raw representation
//    // Return the reverse transformed value
//}

@end
