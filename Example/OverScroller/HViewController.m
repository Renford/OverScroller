//
//  HViewController.m
//  OverScroller
//
//  Created by aelam on 07/31/2018.
//  Copyright (c) 2018 aelam. All rights reserved.
//

@import OverScroller;

#import "HViewController.h"

@interface HViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) ScrollViewHandler *scrollViewHandler;

@end

@implementation HViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIView *scrollView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 375, 375)];
    scrollView.layer.borderWidth = 1;
    [self.view addSubview:scrollView];
    
    self.scrollViewHandler = [[ScrollViewHandler alloc] initWithScrollView: scrollView];
    self.scrollViewHandler.maxOffsetX = 1000;
    
    UIScrollView *scrollView2 =[[UIScrollView alloc] initWithFrame:CGRectMake(0, 375, 375, 300)];
    scrollView2.contentSize = CGSizeMake(1000, 1000);
    scrollView2.layer.borderWidth = 1;
    scrollView2.layer.borderColor = [UIColor redColor].CGColor;
    [self.view addSubview:scrollView2];
    scrollView2.delegate = self;
    NSLog(@"%@", NSStringFromCGRect(scrollView2.bounds));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"%@", scrollView);
    NSLog(@"%@", NSStringFromCGRect(scrollView.bounds));
}

@end
