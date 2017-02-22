//
//  MGCEditImageViewController.h
//  MyXcodeObject
//
//  Created by 陈胜 on 2017/2/22.
//  Copyright © 2017年 陈胜. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger, MGCEditSelectImageViewShapeStyle) {
    MGCEditSelectImageViewShapeStyle_rect,
    MGCEditSelectImageViewShapeStyle_circle,
};

// 遮挡视图（目前只支持矩形和圆形，其它形状可以类似实现）
@interface MGCEditSelectImageView : UIView
@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat height;

@property (nonatomic, readonly) MGCEditSelectImageViewShapeStyle style;

/** * 画形状 * * @param width 宽度、长半径 * @param height 高度、短半径 * @param style 形状类型，当画矩形时，若width或者height中的一个为0，那么画正方形，当画椭圆时，若width或者height为0时，画圆 */
- (void)drawShapeWithWidth:(CGFloat)width height:(CGFloat)height shapeStyle:(MGCEditSelectImageViewShapeStyle)style;

@end



@class MGCEditImageViewController;

@protocol MGCEditImageViewControllerDelegate <NSObject>

// 编辑完成
- (void)editDidFinsh:(MGCEditImageViewController *)controller originalImage:(UIImage *)originalImage editImage:(UIImage *)editImage;
// 编辑取消
- (void)editCancel:(MGCEditImageViewController *)controller origiinalImage:(UIImage *)originalImage;

@end

@interface MGCEditImageViewController : UIViewController

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) MGCEditSelectImageViewShapeStyle editStyle;      //
@property (nonatomic, assign) CGFloat ratioW_Y;                 // 宽高比 // 默认为1
@property (nonatomic, assign) CGFloat suitableWidth;            // 最适合的宽度，或者直径

@property (nonatomic, weak) id<MGCEditImageViewControllerDelegate>delegate;

@end
