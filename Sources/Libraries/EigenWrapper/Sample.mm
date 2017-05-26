//
//  Sample.m
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/26.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

#import "Sample.h"

#import <iostream>
#import <Eigen/Core>
#import <Eigen/Geometry>

using namespace Eigen;
typedef Matrix<NSInteger, Dynamic, Dynamic, RowMajor> MXi;

@implementation Sample

+ (void)multiple:(NSInteger *)result :(NSInteger)aRow :(NSInteger)aCol :(NSInteger)bCol :(const NSInteger[])aGrid :(const NSInteger[])bGrid {
    Map<MXi>a(const_cast<NSInteger *>(aGrid), aRow, aCol);
    Map<MXi>b(const_cast<NSInteger *>(bGrid), aCol, bCol);
    Map<MXi>(result, aRow, bCol) = a * b;
}

@end
