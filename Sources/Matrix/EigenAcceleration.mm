//
//  EigenLib.m
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/26.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

#import "EigenAcceleration.h"
#import <iostream>

@implementation EigenAcceleration

static BOOL enabled = false;
+ (BOOL)enabled {
    return enabled;
}

+ (void)enable:(BOOL)flag {
#if __has_include(<Eigen/Core>)
    std::cout << (flag ? "EigenAcceleration enabled!" : "EigenAcceleration disabled.") << std::endl;
    enabled = flag;
#else
    std::cout << "[Error] Eigen not available! Must include library by `git submodule update --init`" << std::endl;
#endif
}

@end

#if __has_include(<Eigen/Core>)

#import <Eigen/Core>
#import <Eigen/Geometry>

using namespace Eigen;
typedef Matrix<NSInteger, Dynamic, Dynamic, RowMajor> IntMatrix;

@interface EigenIntMatrix()

@property NSInteger rows;
@property NSInteger cols;
@property Map<IntMatrix> *ins;

@end

@implementation EigenIntMatrix

+ (BOOL)isEnabled {
    return enabled;
}

+ (void)enable:(BOOL)flag {
    enabled = flag;
}

- (instancetype)initWithRows:(NSInteger)rows cols:(NSInteger)cols grid:(const NSInteger [])grid {
    _rows = rows;
    _cols = cols;
    _ins = new Map<IntMatrix>(const_cast<NSInteger *>(grid), rows, cols);
    std::cout << "create\n" << *_ins << std::endl;
    return self;
}

- (void)dealloc {
    std::cout << "delete\n" << *_ins << std::endl;
    delete _ins;
}

- (instancetype)mul:(EigenIntMatrix *)b {
    // TODO
    return self;
}

+ (void)multiple:(NSInteger *)result :(NSInteger)aRow :(NSInteger)aCol :(NSInteger)bCol :(const NSInteger[])aGrid :(const NSInteger[])bGrid {
    Map<IntMatrix>a(const_cast<NSInteger *>(aGrid), aRow, aCol);
    Map<IntMatrix>b(const_cast<NSInteger *>(bGrid), aCol, bCol);
    Map<IntMatrix>(result, aRow, bCol) = a * b;
}

@end

#else

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"

@implementation EigenIntMatrix
@end

#pragma clang diagnostic pop

#endif
