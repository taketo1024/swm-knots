//
//  Sample.h
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/26.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Sample : NSObject

+ (void)multiple:(int *)result :(int)aRow :(int)aCol :(int)bCol :(const int[])aGrid :(const int[])bGrid;

@end
