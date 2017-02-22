//
//  ViewController.m
//  MyXcodeObject
//
//  Created by 陈胜 on 2017/2/20.
//  Copyright © 2017年 陈胜. All rights reserved.
//

#import "ViewController.h"
#import "MGCEditImageViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

   
}
- (IBAction)goEditImgVC:(id)sender {
    
    
    MGCEditImageViewController * vc = [[MGCEditImageViewController alloc]init];
    vc.image = [UIImage imageNamed:@"健康调查"];
    vc.ratioW_Y = 1;
    vc.suitableWidth = 100;
    vc.editStyle = MGCEditSelectImageViewShapeStyle_circle;
    [self presentViewController:vc animated:YES completion:nil];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
