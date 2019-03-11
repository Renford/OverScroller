//
//  ScrollViewHandler.h
//  ScrollViewHandler
//
//  Created by Ole Begemann on 16.04.14.
//  Copyright (c) 2014 Ole Begemann. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ScrollViewHandler;

@protocol ScrollViewHandlerDelegate<NSObject>

- (BOOL)handler:(ScrollViewHandler *)handler shouldBeginScroll:(UIGestureRecognizer *)gestureRecognizer;

@end

typedef void(^ScrollViewHandlerUpdater)(CGFloat);

@interface ScrollViewHandler : NSObject

@property (nonatomic, assign) CGFloat contentMaxX;
@property (nonatomic, assign) CGFloat maxOffsetX __deprecated;
@property (nonatomic,   copy) ScrollViewHandlerUpdater updater;
@property (nonatomic, assign) CGFloat offsetX;
@property (nonatomic, strong, readonly) UIView *scrollView;
@property (nonatomic, weak) id<ScrollViewHandlerDelegate> delegate;

- (instancetype)initWithScrollView:(UIView *)scrollView;

@end
