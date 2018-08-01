//
//  ScrollViewHandler.h
//  ScrollViewHandler
//
//  Created by Ole Begemann on 16.04.14.
//  Copyright (c) 2014 Ole Begemann. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ScrollViewHandlerUpdater)(CGFloat);

@interface ScrollViewHandler : NSObject

@property (nonatomic, assign) CGFloat maxOffsetX;
@property (nonatomic,   copy) ScrollViewHandlerUpdater updater;
@property (nonatomic, assign) CGFloat offsetX;
@property (nonatomic, strong, readonly) UIView *scrollView;

- (instancetype)initWithScrollView:(UIView *)scrollView;

@end
