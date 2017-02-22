//
//  UIImage+imgCustom.m
//  MyXcodeObject
//
//  Created by 陈胜 on 2017/2/22.
//  Copyright © 2017年 陈胜. All rights reserved.
//

#import "UIImage+imgCustom.h"

@implementation UIImage (imgCustom)
//  裁剪图片
//  裁剪图片
- (UIImage *)cutFromRect:(CGRect)rect
{
    UIGraphicsBeginImageContext(CGSizeMake(self.size.width, self.size.height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddRect(context, rect);
    CGContextClip(context);
    
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContext(rect.size);
    context = UIGraphicsGetCurrentContext();
    [newImage drawInRect:CGRectMake(-rect.origin.x, -rect.origin.y, self.size.width, self.size.height)];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
