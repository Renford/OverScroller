//
//  ScrollViewHandler.m
//  ScrollViewHandler
//
//  Created by Ole Begemann on 16.04.14.
//  Copyright (c) 2014 Ole Begemann. All rights reserved.
//  Parts of the class are based on https://github.com/grp/ScrollViewHandler/blob/custom-scroll-with-pop/ScrollViewHandler/ScrollViewHandler.m

#import "ScrollViewHandler.h"
#import "CSCDynamicItem.h"

static CGFloat rubberBandDistance(CGFloat offset, CGFloat dimension) {

    const CGFloat constant = 0.55f;
    CGFloat result = (constant * fabs(offset) * dimension) / (dimension + constant * fabs(offset));
    // The algorithm expects a positive offset, so we have to negate the result if the offset was negative.
    return offset < 0.0f ? -result : result;
}

@interface ScrollViewHandler () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) CGRect bounds;
@property (nonatomic, assign) CGRect startBounds;
@property (nonatomic, assign) CGPoint lastPointInBounds;
@property (nonatomic, assign) CGSize contentSize;

@property (nonatomic, strong, readwrite) UIView *scrollView;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic,   weak) UIDynamicItemBehavior *decelerationBehavior;
@property (nonatomic,   weak) UIAttachmentBehavior *springBehavior;
@property (nonatomic, strong) CSCDynamicItem *dynamicItem;

@end

@implementation ScrollViewHandler

- (instancetype)initWithScrollView:(UIView *)scrollView {
    if (self = [super init]) {
        self.scrollView = scrollView;
        [self commonInitForScrollViewHandler];
    }
    
    return self;
}


- (void)commonInitForScrollViewHandler
{
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.scrollView addGestureRecognizer:panGestureRecognizer];

    panGestureRecognizer.delegate = self;
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.scrollView];
    self.dynamicItem = [[CSCDynamicItem alloc] init];
    
//    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(linkUpdated:)];
//    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)linkUpdated:(CADisplayLink *)link {
    NSLog(@"point: %@", NSStringFromCGPoint(self.dynamicItem.center));
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *panGestureRecognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint velocity = [panGestureRecognizer velocityInView:self.scrollView];
        if(fabs(velocity.x) > fabs(velocity.y)) {
            if ([self.delegate respondsToSelector:@selector(handler:shouldBeginScroll:)]) {
                return [self.delegate handler:self shouldBeginScroll:panGestureRecognizer];
            }
            return YES;
        } else {
            return NO;
        }
    }
    
    return YES;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return NO;
    }
    return YES;
}


- (void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecognizer
{
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            self.startBounds = self.bounds;
            [self.animator removeAllBehaviors];
        }
            // fall through
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [panGestureRecognizer translationInView:self.scrollView];
            CGRect bounds = self.startBounds;

            if (!self.scrollHorizontal) {
                translation.x = 0.0;
            }
            if (!self.scrollVertical) {
                translation.y = 0.0;
            }

            CGFloat newBoundsOriginX = bounds.origin.x - translation.x;
            CGFloat minBoundsOriginX = 0.0;
            CGFloat maxBoundsOriginX = self.contentSize.width - bounds.size.width;
            CGFloat constrainedBoundsOriginX = fmax(minBoundsOriginX, fmin(newBoundsOriginX, maxBoundsOriginX));
            CGFloat rubberBandedX = rubberBandDistance(newBoundsOriginX - constrainedBoundsOriginX, CGRectGetWidth(self.bounds));
            bounds.origin.x = constrainedBoundsOriginX + rubberBandedX;

            CGFloat newBoundsOriginY = bounds.origin.y - translation.y;
            CGFloat minBoundsOriginY = 0.0;
            CGFloat maxBoundsOriginY = self.contentSize.height - bounds.size.height;
            CGFloat constrainedBoundsOriginY = fmax(minBoundsOriginY, fmin(newBoundsOriginY, maxBoundsOriginY));
            CGFloat rubberBandedY = rubberBandDistance(newBoundsOriginY - constrainedBoundsOriginY, CGRectGetHeight(self.bounds));
            bounds.origin.y = constrainedBoundsOriginY + rubberBandedY;

            self.bounds = bounds;
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            CGPoint velocity = [panGestureRecognizer velocityInView:self.scrollView];
            velocity.x = -velocity.x;
            velocity.y = -velocity.y;

            if (![self scrollHorizontal] || [self outsideBoundsMinimum] || [self outsideBoundsMaximum]) {
                velocity.x = 0;
            }
            if (![self scrollVertical] || [self outsideBoundsMinimum] || [self outsideBoundsMaximum]) {
                velocity.y = 0;
            }

            self.dynamicItem.center = self.bounds.origin;
            UIDynamicItemBehavior *decelerationBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.dynamicItem]];
            [decelerationBehavior addLinearVelocity:velocity forItem:self.dynamicItem];
            decelerationBehavior.resistance = 2.0;

            __weak typeof(self)weakSelf = self;
            decelerationBehavior.action = ^{
                // IMPORTANT: If the deceleration behavior is removed, the bounds' origin will stop updating. See other possible ways of updating origin in the accompanying blog post.
                CGRect bounds = weakSelf.bounds;
                bounds.origin = weakSelf.dynamicItem.center;
                weakSelf.bounds = bounds;
            };

            [self.animator addBehavior:decelerationBehavior];
            self.decelerationBehavior = decelerationBehavior;
        }
            break;

        default:
            break;
    }
}

- (void)setMaxOffsetX:(CGFloat)maxOffsetX {
    [self setContentMaxX:maxOffsetX];
}

- (CGFloat)maxOffsetX {
    return _contentMaxX;
}

- (void)setContentMaxX:(CGFloat)contentMaxX {
    if (_contentMaxX == contentMaxX) {
        return;
    }
    
    _contentMaxX = contentMaxX;
    self.contentSize = CGSizeMake(_contentMaxX, self.scrollView.bounds.size.height);

    CGRect b = CGRectZero;
    b.size = self.scrollView.bounds.size;
    self.bounds = b;
}

- (void)setBounds:(CGRect)bounds
{
    if (CGRectEqualToRect(_bounds, bounds)) {
        return;
    }
    
    _bounds = bounds;
    
    if (([self outsideBoundsMinimum] || [self outsideBoundsMaximum]) &&
        (self.decelerationBehavior && !self.springBehavior)) {

        CGPoint target = [self anchor];

        UIAttachmentBehavior *springBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.dynamicItem attachedToAnchor:target];
        // Has to be equal to zero, because otherwise the bounds.origin wouldn't exactly match the target's position.
        springBehavior.length = 0;
        // These two values were chosen by trial and error.
        springBehavior.damping = 1;
        springBehavior.frequency = 2;

        [self.animator addBehavior:springBehavior];
        self.springBehavior = springBehavior;
    }

    if (![self outsideBoundsMinimum] && ![self outsideBoundsMaximum]) {
        self.lastPointInBounds = bounds.origin;
    }
    
    [self postOffsetX];
}

- (void)postOffsetX {
    if (self.updater != nil) {
        self.updater(self.offsetX);
    }
}


- (CGFloat)offsetX {
    return self.bounds.origin.x;
}

- (void)setOffsetX:(CGFloat)offsetX {
    if (offsetX == self.bounds.origin.x) {
        return;
    }
    CGRect newBounds = self.bounds;
    newBounds.origin.x = offsetX;
    
    self.bounds = newBounds;
}

- (BOOL)scrollVertical
{
    return self.contentSize.height > CGRectGetHeight(self.bounds);
}

- (BOOL)scrollHorizontal
{
    return self.contentSize.width > CGRectGetWidth(self.bounds);
}

- (CGPoint)maxBoundsOrigin
{
    return CGPointMake(self.contentSize.width - self.bounds.size.width,
                       self.contentSize.height - self.bounds.size.height);
}

- (BOOL)outsideBoundsMinimum
{
    return self.bounds.origin.x < 0.0 || self.bounds.origin.y < 0.0;
}

- (BOOL)outsideBoundsMaximum
{
    CGPoint maxBoundsOrigin = [self maxBoundsOrigin];
    return self.bounds.origin.x > maxBoundsOrigin.x || self.bounds.origin.y > maxBoundsOrigin.y;
}

- (CGPoint)anchor
{
    CGRect bounds = self.bounds;
    CGPoint maxBoundsOrigin = [self maxBoundsOrigin];

    CGFloat deltaX = self.lastPointInBounds.x - bounds.origin.x;
    CGFloat deltaY = self.lastPointInBounds.y - bounds.origin.y;

    // solves a system of equations: y_1 = ax_1 + b and y_2 = ax_2 + b
    CGFloat a = deltaY / deltaX;
    CGFloat b = self.lastPointInBounds.y - self.lastPointInBounds.x * a;

    CGFloat leftBending = -bounds.origin.x;
    CGFloat topBending = -bounds.origin.y;
    CGFloat rightBending = bounds.origin.x - maxBoundsOrigin.x;
    CGFloat bottomBending = bounds.origin.y - maxBoundsOrigin.y;

    // Updates anchor's `y` based on already set `x`, i.e. y = f(x)
    void(^solveForY)(CGPoint*) = ^(CGPoint *anchor) {
        // Updates `y` only if there was a vertical movement. Otherwise `y` based on current `bounds.origin` is already correct.
        if (deltaY != 0) {
            anchor->y = a * anchor->x + b;
        }
    };
    // Updates anchor's `x` based on already set `y`, i.e. x =  f^(-1)(y)
    void(^solveForX)(CGPoint*) = ^(CGPoint *anchor) {
        if (deltaX != 0) {
            anchor->x = (anchor->y - b) / a;
        }
    };

    CGPoint anchor = bounds.origin;

    if (bounds.origin.x < 0.0 && leftBending > topBending && leftBending > bottomBending) {
        anchor.x = 0;
        solveForY(&anchor);
    } else if (bounds.origin.y < 0.0 && topBending > leftBending && topBending > rightBending) {
        anchor.y = 0;
        solveForX(&anchor);
    } else if (bounds.origin.x > maxBoundsOrigin.x && rightBending > topBending && rightBending > bottomBending) {
        anchor.x = maxBoundsOrigin.x;
        solveForY(&anchor);
    } else if (bounds.origin.y > maxBoundsOrigin.y) {
        anchor.y = maxBoundsOrigin.y;
        solveForX(&anchor);
    }

    return anchor;
}

@end
