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
typedef Matrix<int, Dynamic, Dynamic, RowMajor> MXi;

@implementation Sample

+ (void)multiple:(int *)result :(int)aRow :(int)aCol :(int)bCol :(const int[])aGrid :(const int[])bGrid {
    Map<MXi>a(const_cast<int *>(aGrid), aRow, aCol);
    Map<MXi>b(const_cast<int *>(bGrid), aCol, bCol);
    Map<MXi>(result, aRow, bCol) = a * b;
}

@end
