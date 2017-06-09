//
//  EigenLib.h
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/26.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

// To enable Eigen,
//   1. `git submodule update`
//   2. add `USE_EIGEN=1` to Preprocessor Macros.
//   3. add `-DUSE_EIGEN` to Other Swift Compiler Flags.

#ifdef USE_EIGEN

#import <Foundation/Foundation.h>

@interface EigenLib : NSObject

+ (void)multiple:(NSInteger *)result :(NSInteger)aRow :(NSInteger)aCol :(NSInteger)bCol :(const NSInteger[])aGrid :(const NSInteger[])bGrid;

@end

#endif
