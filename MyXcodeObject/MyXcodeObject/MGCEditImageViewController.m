//
//  MGCEditImageViewController.m
//  MyXcodeObject
//
//  Created by 陈胜 on 2017/2/22.
//  Copyright © 2017年 陈胜. All rights reserved.
//

#import "MGCEditImageViewController.h"
#import "UIImage+imgCustom.h"

#import <UIKit/UIKit.h>




@interface MGCEditSelectImageView ()

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@property (nonatomic, assign) MGCEditSelectImageViewShapeStyle style;

@end

@implementation MGCEditSelectImageView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (self.superview) {
        
        // 绘制边框，
        CGContextAddRect(context, CGRectMake(-self.frame.origin.x - 1, -self.frame.origin.y - 1, self.superview.frame.size.width + 2, self.superview.frame.size.height + 2));
    }else{
        CGContextAddRect(context, self.bounds);
    }
    
    [self drawShapeContext:context];
    // 设置触笔颜色
    [[UIColor whiteColor] setStroke];
    // 将未选中部分蛇者为阴影半透明颜色
    [[[UIColor blackColor] colorWithAlphaComponent:0.6] setFill];
    CGContextDrawPath(context, kCGPathEOFillStroke);
    
}

#pragma mark - pravate
// 绘制形状
- (void)drawShapeContext:(CGContextRef)context
{
    if (self.width || self.height) {
        if (self.width <= 0 && self.height > 0) {
            self.width = self.height;
        }else if (self.height <= 0 && self.width > 0){
            self.height = self.width;
        }
        
        CGFloat x = (self.frame.size.width - self.width) / 2;
        CGFloat y = (self.frame.size.height - self.height) / 2;
        
        CGRect rect = CGRectMake(x, y, self.width, self.height);
        
        if (self.style == MGCEditSelectImageViewShapeStyle_rect) {
            // 绘制矩形
            CGContextAddRect(context, rect);
        }else if (self.style == MGCEditSelectImageViewShapeStyle_circle){
            // 绘制圆形
            CGContextAddEllipseInRect(context, rect);
        }
    }
    
}

#pragma mark - public
- (void)drawShapeWithWidth:(CGFloat)width height:(CGFloat)height shapeStyle:(MGCEditSelectImageViewShapeStyle)style
{
    self.width = width;
    self.height = height;
    self.style = style;
    
    [self setNeedsDisplay];
}

@end



@interface MGCEditImageViewController ()

@property (nonatomic, strong) UIImageView *imageView;   // 图片视图
@property (nonatomic, strong) MGCEditSelectImageView *selecterView;     // 选择视图
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *selectButton;


@property (nonatomic, assign) CGFloat selectViewScale;         // 默认为1
@property (nonatomic, assign) CGPoint panStarPoint;
@property (nonatomic, assign) CGFloat pinchLastScale;

@end

@implementation MGCEditImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.imageView];
    [self.view addSubview:self.bottomBar];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[_bottomBar]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_bottomBar)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_bottomBar(44)]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_bottomBar)]];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleClickSelectView:)];
    tapGes.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapGes];
    
    UIPinchGestureRecognizer *pinchGes = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomSelectView:)];
    [self.view addGestureRecognizer:pinchGes];
    
    UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveSelectView:)];
    [self.view addGestureRecognizer:panGes];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.selectViewScale = 1;
        self.ratioW_Y = 1;
        self.editStyle = MGCEditSelectImageViewShapeStyle_circle;
        self.panStarPoint = CGPointZero;
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    // 设置图片视图的位置和大小
    [self updateImageViewFram];
    // 更新选择视图的位置
    [self updateSelectViewFramWithCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2)];
    
    // 指定选中区域的大小和图片视图大小的比例
    self.selectViewScale = [self suitableScale];
    // 根据selectViewScale从新绘制选中区域
    [self updateSelectView];
}

#pragma mark - get and set
// 图片视图
- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = [UIColor clearColor];
    }
    return _imageView;
}
// 选择视图（遮挡视图）
- (MGCEditSelectImageView *)selecterView
{
    if (!_selecterView) {
        _selecterView = [[MGCEditSelectImageView alloc] init];
        _selecterView.backgroundColor = [UIColor clearColor];
        _selecterView.userInteractionEnabled = NO;
        _selecterView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _selecterView;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    self.imageView.image = image;
    // 更新图片视图的位置
    [self updateImageViewFram];
}
// 取消按钮
- (UIButton *)cancelButton
{
    if (!_cancelButton) {
        _cancelButton = [self barButtonWithTitle:@"取消"];
        [_cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}
// 确定按钮
- (UIButton *)selectButton
{
    if (!_selectButton) {
        _selectButton = [self barButtonWithTitle:@"使用照片"];
        [_selectButton addTarget:self action:@selector(confirm:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _selectButton;
}
// 底部工具栏
- (UIView *)bottomBar
{
    if (!_bottomBar) {
        _bottomBar = [[UIView alloc] init];
        _bottomBar.backgroundColor = [UIColor clearColor];
        _bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_bottomBar addSubview:self.cancelButton];
        [_bottomBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-20-[_cancelButton]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_cancelButton)]];
        [_bottomBar addConstraint:[NSLayoutConstraint constraintWithItem:self.cancelButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_bottomBar attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        [_bottomBar addSubview:self.selectButton];
        [_bottomBar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_selectButton]-20-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_selectButton)]];
        [_bottomBar addConstraint:[NSLayoutConstraint constraintWithItem:self.selectButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_bottomBar attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    }
    
    return _bottomBar;
}

#pragma mark - private
- (UIButton *)barButtonWithTitle:(NSString *)title
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor = [UIColor clearColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    return button;
}

// 图片和self.view的比例
- (CGFloat)ratioImageToView
{
    CGFloat scaleX = self.image.size.width / self.view.frame.size.width;
    CGFloat scaleY = self.image.size.height  / self.view.frame.size.height;
    return MAX(scaleX, scaleY);
}

// 更新图片视图视图
- (void)updateImageViewFram
{
    // 获取图片和self.view的正确显示比例
    CGFloat maxScale = [self ratioImageToView];
    
    CGFloat width = self.image.size.width / maxScale;
    CGFloat height = self.image.size.height / maxScale;
    
    self.imageView.frame = CGRectMake(0, 0, width, height);
    self.imageView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
}

// 更新选择视图位置和大小
- (void)updateSelectViewFramWithCenter:(CGPoint)center
{
    // 大小设置为父视图的9倍，保证始终覆盖父视图
    self.selecterView.frame = CGRectMake(0, 0, self.view.frame.size.width * 3, self.view.frame.size.height * 3);
    
    // 不需要考虑左右或者上下都超出的情况，因为形状的大小有selectViewScale控制
    if (center.x - self.selecterView.width / 2 < self.imageView.frame.origin.x) {
        center.x = self.imageView.frame.origin.x + self.selecterView.width / 2;
    }else if (center.x + self.selecterView.width / 2 > CGRectGetMaxX(self.imageView.frame)){
        center.x = CGRectGetMaxX(self.imageView.frame) - self.selecterView.width / 2;
    }
    
    if (center.y - self.selecterView.height / 2 < self.imageView.frame.origin.y) {
        center.y = self.imageView.frame.origin.y + self.selecterView.height / 2;
    }else if (center.y + self.selecterView.height / 2 > CGRectGetMaxY(self.imageView.frame)){
        center.y = CGRectGetMaxY(self.imageView.frame) - self.selecterView.height / 2;
    }
    
    self.selecterView.center = center;
}

- (void)updateSelectView
{
    
    if (self.selectViewScale > 1) {
        self.selectViewScale = 1;
    }else if (self.selectViewScale < 0.01){
        self.selectViewScale = 0.01;
    }
    
    CGFloat imageViewRadioW_Y = self.imageView.frame.size.width / self.imageView.frame.size.height;
    
    CGFloat width = 0;
    CGFloat height = 0;
    
    if (imageViewRadioW_Y > self.ratioW_Y) {
        height = self.imageView.frame.size.height * self.selectViewScale;
        width = height * self.ratioW_Y;
    }else{
        width = self.imageView.frame.size.width * self.selectViewScale;
        height = width / self.ratioW_Y;
    }
    
    [self.selecterView drawShapeWithWidth:width height:height shapeStyle:self.editStyle];
}

// 根据给出的最合适的宽度和宽高比，计算最合适的选择形状的和图片视图的比例
- (CGFloat)suitableScale
{
    if (self.suitableWidth > 0) {
        
        CGFloat suitableHeight = self.suitableWidth / self.ratioW_Y;
        return MIN(MAX(suitableHeight / self.imageView.frame.size.height, self.suitableWidth / self.imageView.frame.size.width), 1) ;
        
    }else{
        return 1;
    }
}

#pragma mark - action

// 双击试，回复最合适的大小，并置于中心
- (void)doubleClickSelectView:(UITapGestureRecognizer *)sender
{
    self.selectViewScale = [self suitableScale];
    [self updateSelectView];
    self.selecterView.center = self.view.center;
}

// 缩放选择区域
- (void)zoomSelectView:(UIPinchGestureRecognizer *)sender
{
    if (self.pinchLastScale == 0) {
        self.pinchLastScale = sender.scale;
        return;
    }
    
    sender.scale = sender.scale - self.pinchLastScale + 1;
    CGFloat scale = self.selectViewScale * sender.scale;
    self.selectViewScale = scale > 1 ? 1 : scale;
    [self updateSelectView];
    
    [self updateSelectViewFramWithCenter:self.selecterView.center];
    
    self.pinchLastScale = sender.scale;
    
}

// 移动选择区域，实则移动整个选择视图
- (void)moveSelectView:(UIPanGestureRecognizer *)sender
{
    CGPoint startCenter = self.selecterView.center;
    
    CGRect shapeFramToSeleView = [self.selecterView convertRect:CGRectMake(self.selecterView.frame.size.width / 2 - self.selecterView.width / 2, self.selecterView.frame.size.height / 2 - self.selecterView.height / 2, self.selecterView.width, self.selecterView.height) toView:self.view];
    BOOL startPointInShapeRect = self.panStarPoint.x >= shapeFramToSeleView.origin.x && self.panStarPoint.y >= shapeFramToSeleView.origin.y && self.panStarPoint.x <= CGRectGetMaxX(shapeFramToSeleView) && self.panStarPoint.y <= CGRectGetMaxY(shapeFramToSeleView);
    
    CGPoint gesCenter = [sender locationInView:sender.view];
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        if (startPointInShapeRect) {
            CGPoint center = gesCenter;
            [self updateSelectViewFramWithCenter:center];
            self.panStarPoint = gesCenter;
        }
    }else if (sender.state == UIGestureRecognizerStateEnded){
        self.panStarPoint = CGPointZero;
    }else if (sender.state == UIGestureRecognizerStateBegan){
        self.panStarPoint = gesCenter;
    }
    
    if (self.selecterView.center.x != startCenter.x || self.selecterView.center.y != startCenter.y) {
        [self updateSelectView];
    }
}

- (void)confirm:(UIButton *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(editDidFinsh:originalImage:editImage:)]) {
        [self.delegate editDidFinsh:self originalImage:self.image editImage:[self editImage]];
    }
}

- (void)cancel:(UIButton *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(editCancel:origiinalImage:)]) {
        [self.delegate editCancel:self origiinalImage:self.image];
    }
}

- (UIImage *)editImage
{
    CGFloat ratioImageToView = [self ratioImageToView];
    CGRect selectToImageView = [self.selecterView convertRect:CGRectMake(self.selecterView.frame.size.width / 2 - self.selecterView.width / 2, self.selecterView.frame.size.height / 2 - self.selecterView.height / 2, self.selecterView.width, self.selecterView.height) toView:self.imageView];
    CGFloat ratio = ratioImageToView;
    CGRect resultRect = CGRectMake(selectToImageView.origin.x * ratio, selectToImageView.origin.y * ratio, selectToImageView.size.width * ratio, selectToImageView.size.height * ratio);
    
    return [self.image cutFromRect:resultRect];
}






@end
