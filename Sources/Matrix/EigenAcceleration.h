//
//  EigenLib.h
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/26.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EigenAcceleration: NSObject
+ (BOOL)enabled;
+ (void)enable:(BOOL)flag;
@end

@interface EigenIntMatrix: NSObject

- (instancetype _Nonnull)initWithRows:(NSInteger)rows cols:(NSInteger)cols grid:(const NSInteger[_Nonnull])grid;
- (instancetype _Nonnull)mul:(EigenIntMatrix *_Nonnull)b;

// TODO remove
+ (void)multiple:(NSInteger *_Nonnull)result :(NSInteger)aRow :(NSInteger)aCol :(NSInteger)bCol :(const NSInteger[_Nonnull])aGrid :(const NSInteger[_Nonnull])bGrid;

@end
