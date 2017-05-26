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

@implementation Sample

- (void)run {
    using namespace Eigen;
    
    Matrix3d A, B;
    
    A << 3.0, 6.0, 3.0,
    2.0, 1.0, 2.0,
    1.0, 2.0, 1.0;
    int k = 0;
    
    B << 1.0, 0.0, 0.0,
    -A(k+1,k)/A(k,k), 1.0, 0.0,
    -A(k+2,k)/A(k,k), 0.0, 1.0;
    
    
    std::cout << "m\n" << B * A << std::endl;
}

@end
