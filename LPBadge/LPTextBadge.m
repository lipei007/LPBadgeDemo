//
//  LPTextBadge.m
//  LPBadgeDemo
//
//  Created by Jack on 2017/12/27.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import "LPTextBadge.h"

#define Max_Width 30.0f
#define Min_Width 16.0f
#define Text_Size 12.0f
#define Drag_Max 40.0f


@interface LPTextBadge ()
{
    UIColor *_backgroundColor;
    UIColor *_foregroundColor;
    
    // touch
    UIPanGestureRecognizer *_panGesture;
    CGPoint _touchBeginPoint;
    CGPoint _touchBeforePoint;
    BOOL _explosible;
}
@property (nonatomic,strong) CAShapeLayer *originLayer;
@property (nonatomic,strong) CAShapeLayer *borderLayer;
@property (nonatomic,strong) CAShapeLayer *dragLayer;
@property (nonatomic,strong) CATextLayer *valueLayer;
@property (nonatomic,strong) CAEmitterLayer *emitterLayer;

@end

@implementation LPTextBadge


#pragma mark - Utils

+ (CGSize)sizeOfString:(NSString *)string font:(UIFont *)font{
    
    if (string == nil) {
        return CGSizeZero;
    }
    
    NSDictionary *attribute = @{NSFontAttributeName: font};
    
    CGSize resSize = [string boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT)
                                          options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                       attributes:attribute
                                          context:nil].size;
    
    return resSize;
}

#pragma mark - Public

- (void)setBadgeNumber:(NSUInteger)badgeNumber {
    _badgeNumber = badgeNumber;
    
    self.hidden = _badgeNumber == 0;
    
    NSString *text = nil;
    if (_badgeNumber > 99) {
        text = @"99+";
    } else {
        text = [NSString stringWithFormat:@"%lu",badgeNumber];
    }
    
    [self.valueLayer setString:text];
    
    [self updateUI];
}

- (void)setForegroundColor:(UIColor *)foregroundColor {
    _foregroundColor = foregroundColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
}

- (void)explode {
    
    [self startExplode];
    [self performSelector:@selector(stopExplode) withObject:nil afterDelay:0.25];
}

#pragma mark - Private

- (UIColor *)foregroundColor {
    if (_foregroundColor == nil) {
        _foregroundColor = [UIColor whiteColor];
    }
    return _foregroundColor;
}

- (UIColor *)backgroundColor {
    if (_backgroundColor == nil) {
        _backgroundColor = [UIColor redColor];
    }
    return _backgroundColor;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    
    [super willMoveToSuperview:newSuperview];
    
    [self.layer addSublayer:self.originLayer];
    [self.layer addSublayer:self.dragLayer];
    [self.layer addSublayer:self.borderLayer];
    [self.layer addSublayer:self.valueLayer];
    
    [self updateUI];
    
    if (_panGesture == nil) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:_panGesture];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateUI];
}

#pragma mark Frame

- (void)setWidth:(CGFloat)width {
    CGRect bounds = self.bounds;
    bounds.size.width = width;
    self.bounds = bounds;
}

- (void)setHeight:(CGFloat)height {
    CGRect bounds = self.bounds;
    bounds.size.height = height;
    self.bounds = bounds;
}

- (void)updateUI {
    
    CGSize size = [self.class sizeOfString:self.valueLayer.string font:[UIFont systemFontOfSize:Text_Size]];
    CGSize textSize = size;
    if (size.width < Min_Width) {
        size.width = Min_Width;
    }
    
    if (size.height < Min_Width) {
        size.height = Min_Width;
    }
    
    if (size.height > size.width) {
        size.width = size.height;
    }
    
    CGFloat r = size.height * 0.5;
    
    // 更新自身Size
    if (size.width == size.height) {
        [self setWidth:size.width];
    } else {
        [self setWidth:size.width + r];
    }
    [self setHeight:size.height];
    
    // drag layer
    self.borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:r].CGPath;
    
    // borderLayer
    self.dragLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:r].CGPath;
    
    // 更新TextLayer Frame
    CGFloat x = (CGRectGetWidth(self.bounds) - textSize.width) * 0.5,y = (CGRectGetHeight(self.bounds) - textSize.height) * 0.5;
    self.valueLayer.frame = CGRectMake(x, y, textSize.width, textSize.height);
}

#pragma mark Layer

- (CAShapeLayer *)originLayer {
    if (!_originLayer) {
        _originLayer = [CAShapeLayer layer];
        _originLayer.fillColor = self.backgroundColor.CGColor;
        _originLayer.strokeColor = self.backgroundColor.CGColor;
        _originLayer.lineWidth = 0.1f;
    }
    return _originLayer;
}

- (CAShapeLayer *)dragLayer {
    if (!_dragLayer) {
        _dragLayer = [CAShapeLayer layer];
        _dragLayer.fillColor = self.backgroundColor.CGColor;
        _dragLayer.strokeColor = self.backgroundColor.CGColor;
        _dragLayer.lineWidth = 0.1f;
    }
    return _dragLayer;
}

- (CAShapeLayer *)borderLayer {
    if (!_borderLayer) {
        _borderLayer = [CAShapeLayer layer];
        _borderLayer.fillColor = self.backgroundColor.CGColor;
        _borderLayer.strokeColor = self.backgroundColor.CGColor;
        _borderLayer.lineWidth = 0.1f;
    }
    return _borderLayer;
}

- (CATextLayer *)valueLayer {
    if (!_valueLayer) {
        _valueLayer = [CATextLayer layer];
        _valueLayer.foregroundColor = self.foregroundColor.CGColor;
        _valueLayer.contentsScale = [UIScreen mainScreen].scale;
        _valueLayer.alignmentMode = kCAAlignmentCenter;
        _valueLayer.contentsGravity = kCAGravityCenter;
        
        UIFont *font = [UIFont systemFontOfSize:Text_Size];
        CGFontRef fontRef = CGFontCreateWithFontName((__bridge_retained CFStringRef)font.fontName);
        _valueLayer.font = fontRef;
        _valueLayer.fontSize = font.pointSize;
        CGFontRelease(fontRef);
    }
    return _valueLayer;
}

#pragma mark - Touch

- (void)pan:(UIPanGestureRecognizer *)panGesture {
    
    CGPoint point = [panGesture locationInView:self.superview];
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan: {
            [self beginAtPoint:point];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            [self moveToPoint:point];
        }
            break;
            
        default: {
            [self endAtPoint:point];
        }
            break;
    }
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.superview];
    
    _touchBeginPoint = point;
    _touchBeforePoint = self.center;
    [self beginAtPoint:point];
}

- (void)beginAtPoint:(CGPoint)point {
    self.center = _touchBeginPoint;
}

- (void)moveToPoint:(CGPoint)point {
    // 移动
    self.center = point;
    
    CGFloat r = sqrt(pow((point.x - _touchBeginPoint.x),2) + pow((point.y - _touchBeginPoint.y), 2));
    if (r > Drag_Max) {
        _explosible = YES;
    } else {
        _explosible = NO;
    }
    
    if (_explosible) {
        
        // 水滴分离
        self.dragLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.bounds.size.height * 0.5].CGPath;
        self.originLayer.path = nil;
        
    } else {
        
        self.dragLayer.path = [self dragPath:point percent:r / Drag_Max].CGPath;
    }
    
}

- (void)endAtPoint:(CGPoint)point {
    
    
    if (_explosible) {
        
        [self explode];
        
    } else {
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1000 initialSpringVelocity:100 options:UIViewAnimationOptionCurveLinear animations:^{
            
            self.center = _touchBeforePoint;
            self.dragLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.bounds.size.height * 0.5].CGPath;
            self.originLayer.path = nil;
            
        } completion:^(BOOL finished) {
            
        }];
    }
    
}

- (UIBezierPath *) dragPath:(CGPoint)endPoint percent:(CGFloat)percent{
    
    CGFloat r0 = Min_Width * (1 - percent);
    CGFloat r1 = 0.5 * MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    if (r0 < 5.0) {
        r0 = 5.0f;
    }

    CGPoint originPoint = [self convertPoint:_touchBeforePoint fromView:self.superview];
    CGPoint centerPoint = [self convertPoint:self.center fromView:self.superview];
    
    //
    CGFloat distance = sqrt(pow(centerPoint.x - originPoint.x, 2) + pow(centerPoint.y - originPoint.y, 2));
    
    CGFloat sine = (centerPoint.x - originPoint.x) / distance;
    CGFloat cosine = (centerPoint.y - originPoint.y) / distance;
    CGFloat angle = asin(sine);
    
    CGFloat fromRadius = r0 * MAX(0.3, (1 - distance / Drag_Max));
    CGFloat toRadius = r1;
    
    CGPoint fromCenter = originPoint;
    CGPoint toCenter = centerPoint;
    
    // The two points of tangency of referenced view.
    CGPoint fromPoint1 = CGPointMake(fromCenter.x - fromRadius * cosine, fromCenter.y + fromRadius * sine);
    CGPoint fromPoint2 = CGPointMake(fromCenter.x + fromRadius * cosine, fromCenter.y - fromRadius * sine);
    
    // The two points of tangency of referenced snapshot view.
    CGPoint toPoint1 = CGPointMake(toCenter.x - toRadius * cosine, toCenter.y + toRadius * sine);
    CGPoint toPoint2 = CGPointMake(toCenter.x + toRadius * cosine, toCenter.y - toRadius * sine);
    
    // The two points of tangency of curve lines.
    CGPoint controlPoint1 = CGPointMake(fromPoint1.x + (distance / 2) * sine, fromPoint1.y + (distance / 2) * cosine);
    CGPoint controlPoint2 = CGPointMake(fromPoint2.x + (distance / 2) * sine, fromPoint2.y + (distance / 2) * cosine);
    
    UIBezierPath *dampingLayerPath = [UIBezierPath bezierPath];
    
    // Add two curve lines to align both referenced view and referenced snapshot view.
    [dampingLayerPath moveToPoint:fromPoint1];
    [dampingLayerPath addLineToPoint:fromPoint2];
    [dampingLayerPath addQuadCurveToPoint:toPoint2 controlPoint:controlPoint2];
    [dampingLayerPath addLineToPoint:toPoint1];
    [dampingLayerPath addQuadCurveToPoint:fromPoint1 controlPoint:controlPoint1];
    
    UIBezierPath *originLayerPath = [UIBezierPath bezierPath];
    // The origin view replaced by an circle layer, scaled by disitance.
    [originLayerPath addArcWithCenter:fromCenter radius:fromRadius startAngle:angle endAngle:(M_PI * 2 + angle) clockwise:YES];
    
    self.originLayer.path = [originLayerPath CGPath];
    
    return dampingLayerPath;
}

- (void)startExplode {
    
    UIImage *image = [self snapShot];
    
    CAEmitterLayer *emitter = [CAEmitterLayer layer];
    emitter.frame = self.layer.frame;
    
    [self.superview.layer addSublayer:emitter];
    
    //create a particle template
    CAEmitterCell *explosionCell = [CAEmitterCell emitterCell];
    explosionCell.name = @"explosion";
    explosionCell.alphaSpeed = -4.0;
    explosionCell.lifetime = 0.25;//粒子存活的时间,以秒为单位
    explosionCell.lifetimeRange = 0.1;// 可以为这个粒子存活的时间再指定一个范围。0.1s到0.3s
    explosionCell.birthRate = 0;//每秒生成多少个粒子
    explosionCell.velocity = 40.00;//粒子平均初始速度。正数表示竖直向上，负数竖直向下。
    explosionCell.velocityRange = 10.00;//可以再指定一个范围。
    explosionCell.scale = 0.2;
    explosionCell.scaleRange = 0.2;
    explosionCell.contents = (id)image.CGImage;//用图片效果更佳
    explosionCell.emissionRange = M_PI * 2.0;
    
    //configure emitter
    emitter.renderMode = kCAEmitterLayerAdditive;
    emitter.emitterPosition = CGPointMake(emitter.frame.size.width / 2.0, emitter.frame.size.height / 2.0);
    emitter.name = @"emitterLayer";
    emitter.emitterShape = kCAEmitterLayerCircle;
    emitter.emitterMode = kCAEmitterLayerSurface;
    emitter.emitterSize = CGSizeMake(15, 15);
    
    emitter.emitterCells = @[explosionCell];
    
    
    emitter.beginTime = CACurrentMediaTime();
    [emitter setValue:@500 forKeyPath:@"emitterCells.explosion.birthRate"];
    
    self.hidden = YES;
    self.emitterLayer = emitter;
}

- (void)stopExplode {
    [self.emitterLayer setValue:@0 forKeyPath:@"emitterCells.explosion.birthRate"];
    [self.emitterLayer removeFromSuperlayer];
    self.emitterLayer = nil;

    [self removeFromSuperview];
    self.hidden = NO;
    
    if (self.explodeCompletionBlock) {
        self.explodeCompletionBlock();
    }
}

- (UIImage *)snapShot {
    
    UIGraphicsBeginImageContext(CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)));
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.layer renderInContext:context];
    UIImage *snapShot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapShot;
}
@end
