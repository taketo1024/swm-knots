//
//  EigenLib.m
//  SwiftyAlgebra
//
//  Created by Taketo Sano on 2017/05/26.
//  Copyright © 2017年 Taketo Sano. All rights reserved.
//

#ifdef USE_EIGEN
#import "EigenIntMatrix.h"

#import <iostream>
#import <Eigen/Core>
#import <Eigen/Geometry>

using namespace Eigen;
typedef Matrix<NSInteger, Dynamic, Dynamic, RowMajor> IntMatrix;

@interface _EigenIntMatrix()

@property NSInteger rows;
@property NSInteger cols;
@property Map<IntMatrix> *ins;

@end

@implementation _EigenIntMatrix

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

- (instancetype)mul:(_EigenIntMatrix *)b {
    // TODO
    return self;
}


@end

#endif
