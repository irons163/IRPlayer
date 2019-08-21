//
//  IRGestureControl.m
//  IRPlayer
//
//  Created by Phil on 2019/8/19.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "IRGestureControl.h"
#import "IRGLTransformController.h"
#import "IRGLView.h"
#import "IRGLProgram2D.h"
#import "IRGLRenderMode.h"
#import "IRBounceController.h"

//typedef NS_ENUM(NSInteger, IRScrollDirectionType){
//    None, //default
//    Left,
//    Right,
//    Up,
//    Down
//};

@interface IRGestureControl ()<IRGLRenderModeDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UITapGestureRecognizer *singleTap;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;
@property (nonatomic, strong) UIPanGestureRecognizer *panGR;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGR;
//@property (nonatomic) IRPanDirection panDirection;
//@property (nonatomic) IRPanLocation panLocation;
//@property (nonatomic) IRPanMovingDirection panMovingDirection;
@property (nonatomic, weak) IRGLView *targetView;

@end

@implementation IRGestureControl {
    UITapGestureRecognizer *tapGr;
    BOOL isTouchedInProgram;
    //Smooth Scroll
    CGPoint finalPoint;
    CGPoint alreadyPoint;
    CGFloat slideDuration;
    CADisplayLink *timer;
    NSTimeInterval startTimestamp;
    NSTimeInterval lastTimestamp;
    BOOL didHorizontalBoundsBonce, didVerticalBoundsBonce;
    BOOL isPaned;
    IRBounceController *bounce;
}

- (void)addGestureToView:(IRGLView *)view {
    self.targetView = view;
//    self.targetView.multipleTouchEnabled = YES;
//    [self.singleTap requireGestureRecognizerToFail:self.doubleTap];
//    [self.singleTap  requireGestureRecognizerToFail:self.panGR];
//    [self.targetView addGestureRecognizer:self.singleTap];
//    [self.targetView addGestureRecognizer:self.doubleTap];
//    [self.targetView addGestureRecognizer:self.panGR];
//    [self.targetView addGestureRecognizer:self.pinchGR];
    [self initDefaultValue];
}

- (void)removeGestureToView:(UIView *)view {
//    [view removeGestureRecognizer:self.singleTap];
//    [view removeGestureRecognizer:self.doubleTap];
//    [view removeGestureRecognizer:self.panGR];
//    [view removeGestureRecognizer:self.pinchGR];
}

-(void)initDefaultValue{
    self.swipeEnable = YES;
    
    UIPanGestureRecognizer* gr = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                         action:@selector(didPan:)];
    gr.delegate = self;
    [self.targetView addGestureRecognizer:gr];
    
    UIPinchGestureRecognizer *pinchGr = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(didPinch:)];
    [self.targetView addGestureRecognizer:pinchGr];
    
    UIRotationGestureRecognizer *rotateGr = [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                                                         action:@selector(didRotate:)];
    [self.targetView addGestureRecognizer:rotateGr];
    
    tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(didDoubleTap:)];
    [tapGr setNumberOfTapsRequired:2];
    [self.targetView addGestureRecognizer:tapGr];
    
    tapGr.delegate = self;
    
    isTouchedInProgram = NO;
    
    self.doubleTapEnable = YES;
    
    bounce = [[IRBounceController alloc] init];
    [bounce addBounceToView:self.targetView];
    
    timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)tick:(CADisplayLink *)sender {
    if (CGPointEqualToPoint(finalPoint, CGPointZero)) {
        return;
    }
    
    if(startTimestamp == 0) {
        startTimestamp = sender.timestamp;
    }
    
    CGFloat duration = MIN(slideDuration, sender.timestamp - startTimestamp);
    //    CGFloat persentage = pow(duration / slideDuration, 1);
    CGFloat persentage = duration / slideDuration;
    persentage = -1 * persentage*(persentage-2); // quadratic easing out
    /* //cubic easing out
     persentage -= 1;
     persentage = persentage*persentage*persentage + 1;
     */
    CGFloat moveX = finalPoint.x * persentage - alreadyPoint.x;
    CGFloat moveY = finalPoint.y * persentage - alreadyPoint.y;
    
    alreadyPoint.x += moveX;
    alreadyPoint.y += moveY;
    
    if(isPaned)
        [self.targetView scrollByDx:moveX*[[UIScreen mainScreen] scale] dy:-1*moveY*[[UIScreen mainScreen] scale]];
    else{
        [_currentMode.shiftController shiftDegreeX:moveX degreeY:-1*moveY];
        [self.targetView render:nil];
    }
    
    if(CGPointEqualToPoint(finalPoint, alreadyPoint)){
        [self resetSmoothScroll];
        if(self.delegate)
            [self.delegate glViewDidEndDecelerating:self.targetView];
    }
}

-(void)resetSmoothScroll{
    finalPoint = CGPointZero;
    alreadyPoint = CGPointZero;
    startTimestamp = 0;
    didHorizontalBoundsBonce = NO;
    didVerticalBoundsBonce = NO;
}

- (void)calculateSmoothScroll:(CGPoint)velocity {
    CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
    CGFloat slideMult = magnitude / 200;
    NSLog(@"magnitude: %f, slideMult: %f", magnitude, slideMult);
    
    float slideFactor = 0.05 * slideMult; // Increase for more of a slide
    finalPoint = CGPointMake(0 + (velocity.x * slideFactor),
                             0 + (velocity.y * slideFactor));
    slideDuration = slideFactor*2;
}

-(void)shiftDegreeX:(float)degreeX degreeY:(float)degreeY{
    CGFloat unmoveYetX = finalPoint.x - alreadyPoint.x;
    CGFloat unmoveYetY = finalPoint.y - alreadyPoint.y;
    degreeX += unmoveYetX;
    degreeY += -1*unmoveYetY;
    
    [self resetSmoothScroll];
    isPaned = NO;
    
    finalPoint = CGPointMake(degreeX,
                             -1*degreeY);
    slideDuration = 0.5;
}

-(void)didScrollToBounds:(IRGLTransformControllerScrollToBounds)bounds withProgram:(IRGLProgram2D *)program;{
    CGFloat moveX = finalPoint.x - alreadyPoint.x;
    CGFloat moveY = finalPoint.y - alreadyPoint.y;
    
    IRScrollDirectionType scrollDirectionType = None;
    
    
    
    switch (bounds) {
        case IRGLTransformControllerScrollToHorizontalBounds:
            moveY = 0;
            break;
        case IRGLTransformControllerScrollToVerticalBounds:
            moveX = 0;
            break;
        case IRGLTransformControllerScrollToHorizontalandVerticalBounds:
            
            break;
            
        default:
            moveX = 0;
            moveY = 0;
            break;
    }
    
    if(moveX > 0)
        scrollDirectionType = Right;
    else if(moveX < 0)
        scrollDirectionType = Left;
    
    if(!didHorizontalBoundsBonce && (scrollDirectionType == Left || scrollDirectionType == Right)){
        [bounce removeAndAddAnimateWithScrollValue:moveX byScrollDirection:scrollDirectionType];
        didHorizontalBoundsBonce = YES;
    }
    
    if(moveY > 0)
        scrollDirectionType = Down;
    else if(moveY < 0)
        scrollDirectionType = Up;
    
    if(!didVerticalBoundsBonce && (scrollDirectionType == Up || scrollDirectionType == Down)){
        [bounce removeAndAddAnimateWithScrollValue:moveY byScrollDirection:scrollDirectionType];
        didVerticalBoundsBonce = YES;
    }
    
    if(self.delegate)
        [self.delegate glViewDidScrollToBounds:self.targetView];
}

- (void)setCurrentMode:(IRGLRenderMode *)currentMode {
    _currentMode = currentMode;
    if(_currentMode.program)
        _currentMode.program.delegate = self;
    _currentMode.delegate = self;
}

#pragma mark - Gesture Callback

- (void)didPan:(UIPanGestureRecognizer*)gr
{
    NSLog(@"didPan, state %zd",gr.state);
    
    isPaned = YES;
    [self resetSmoothScroll];
    
    if ((UIGestureRecognizerStateCancelled == gr.state ||
         UIGestureRecognizerStateFailed == gr.state))
    {
        isTouchedInProgram = NO;
        
        if(self.delegate)
            [self.delegate glViewDidEndDragging:self.targetView willDecelerate:NO];
    }
    else if(UIGestureRecognizerStateEnded == gr.state){
        isTouchedInProgram = NO;
        
        CGPoint velocity = [gr velocityInView:self.targetView];
        [self calculateSmoothScroll:velocity];
        
        if(self.delegate)
            [self.delegate glViewDidEndDragging:self.targetView willDecelerate:CGPointEqualToPoint(velocity, CGPointZero)];
    }
    else if(UIGestureRecognizerStateBegan == gr.state){
        CGPoint touchedPoint = [gr locationInView:self.targetView];
        touchedPoint.x *= [UIScreen mainScreen].scale;
        touchedPoint.y = self.targetView.frame.size.height - touchedPoint.y;
        touchedPoint.y *= [UIScreen mainScreen].scale;
        isTouchedInProgram = [_currentMode.program touchedInProgram:touchedPoint];
    }else{
        if(!isTouchedInProgram)
            return;
        
        if(self.delegate)
            [self.delegate glViewWillBeginDragging:self.targetView];
        
        CGPoint screenOffset = [(UIPanGestureRecognizer*)gr translationInView:self.targetView];
        
        [self.targetView scrollByDx:screenOffset.x*[[UIScreen mainScreen] scale] dy:-1*screenOffset.y*[[UIScreen mainScreen] scale]];
        
        [(UIPanGestureRecognizer*)gr setTranslation:CGPointZero inView:self.targetView];
    }
}

- (void)didPinch:(UIPinchGestureRecognizer*)sender{
    NSLog(@"didPinch %f state %zd",sender.scale,sender.state);
    
    if ((UIGestureRecognizerStateCancelled == sender.state ||
         UIGestureRecognizerStateEnded == sender.state ||
         UIGestureRecognizerStateFailed == sender.state))
    {
        isTouchedInProgram = NO;
    }else if(UIGestureRecognizerStateBegan == sender.state){
        CGPoint touchedPoint = [sender locationInView:self.targetView];
        touchedPoint.x *= [UIScreen mainScreen].scale;
        touchedPoint.y = self.targetView.frame.size.height - touchedPoint.y;
        touchedPoint.y *= [UIScreen mainScreen].scale;
        isTouchedInProgram = [_currentMode.program touchedInProgram:touchedPoint];
    }else{
        if(!isTouchedInProgram)
            return;
        if(sender.numberOfTouches < 2)
            return;
        
        CGPoint p1 = [sender locationOfTouch:0 inView:self.targetView];
        CGPoint p2 = [sender locationOfTouch:1 inView:self.targetView];
        
        [self.targetView updateScopeByFx:(p1.x + p2.x) / 2 fy:(p1.y + p2.y) / 2 dsx:sender.scale dsy:sender.scale];
        
        sender.scale = 1;
    }
}

- (void)didRotate:(UIRotationGestureRecognizer*)gr
{
    NSLog(@"didRotate, state %zd",gr.state);
    if ((UIGestureRecognizerStateCancelled == gr.state ||
         UIGestureRecognizerStateEnded == gr.state ||
         UIGestureRecognizerStateFailed == gr.state))
    {
        isTouchedInProgram = NO;
    }
    else if(UIGestureRecognizerStateBegan == gr.state){
        CGPoint touchedPoint = [gr locationInView:self.targetView];
        touchedPoint.x *= [UIScreen mainScreen].scale;
        touchedPoint.y = self.targetView.frame.size.height - touchedPoint.y;
        touchedPoint.y *= [UIScreen mainScreen].scale;
        isTouchedInProgram = [_currentMode.program touchedInProgram:touchedPoint];
    }else{
        if(!isTouchedInProgram)
            return;
        
        if(self.delegate)
            [self.delegate glViewWillBeginDragging:nil];
        
        NSLog(@"rotate:%f",gr.rotation);
        
        [self updateRotation:gr.rotation];
        
        gr.rotation = 0;
        
        if(self.delegate)
            [self.delegate glViewDidEndDragging:nil willDecelerate:NO];
        
        //    if(self.delegate)
        //        [self.delegate scrollViewDidEndDecelerating:nil];
    }
}

-(void) updateRotation:(float)rotateRadians{
    [_currentMode.program didRotate: -1 * rotateRadians];
    [self.targetView render:nil];
}

- (void)didDoubleTap:(UITapGestureRecognizer*)gr
{
    NSLog(@"didDoubleTap, state %zd",gr.state);
    
    isTouchedInProgram = NO;
    
    CGPoint touchedPoint = [gr locationInView:self.targetView];
    touchedPoint.x *= [UIScreen mainScreen].scale;
    touchedPoint.y = self.targetView.frame.size.height - touchedPoint.y;
    touchedPoint.y *= [UIScreen mainScreen].scale;
    isTouchedInProgram = [_currentMode.program touchedInProgram:touchedPoint];
    
    if(!isTouchedInProgram)
        return;
    
    _currentMode.program.doResetToDefaultScaleBlock = ^BOOL(IRGLProgram2D *program) {
        if(CGPointEqualToPoint([program getCurrentScale], CGPointMake(1.0,1.0)))
            return NO;

        [program setDefaultScale:1.0];

        return YES;
    };
    
    [_currentMode.program didDoubleTap];
    
    [_currentMode update]; //It for multi_4P, not a good method, should modify future.
    
    [self.targetView render:nil];
}

- (void)programDidCreate:(IRGLProgram2D *)program {
    program.delegate = self;
}

@end
