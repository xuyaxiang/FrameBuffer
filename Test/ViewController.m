//
//  ViewController.m
//  Test
//
//  Created by enghou on 17/4/14.
//  Copyright © 2017年 xyxorigation. All rights reserved.
//

#import "ViewController.h"
#import "MyOpenGLESView.h"
@interface ViewController ()
@property(nonatomic,strong)MyOpenGLESView *glView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect size = [[UIScreen mainScreen] bounds];
    _glView = [[MyOpenGLESView alloc] initWithFrame:size];
    [_glView Initialize:8 GreenSize:8 BlueSize:8 AlphaSize:8 DepthSize:16 StencilSize:0 SamplesSize:0];
    [self.view addSubview:_glView];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
