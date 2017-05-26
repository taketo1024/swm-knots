//
//  Sample.h
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/26.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Sample : NSObject

+ (void)multiple:(NSInteger *)result :(NSInteger)aRow :(NSInteger)aCol :(NSInteger)bCol :(const NSInteger[])aGrid :(const NSInteger[])bGrid;

@end

