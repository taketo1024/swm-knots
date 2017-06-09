//
//  EigenLib.h
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/26.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

#ifdef USE_EIGEN

#import <Foundation/Foundation.h>

@interface _EigenIntMatrix: NSObject

- (instancetype _Nonnull)initWithRows:(NSInteger)rows cols:(NSInteger)cols grid:(const NSInteger[_Nonnull])grid;
- (instancetype _Nonnull)mul:(_EigenIntMatrix *_Nonnull)b;

@end

#endif
