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

typedef struct {
    CGPoint p0;
    CGPoint p1;
} foo;

foo intersection(CGFloat k,CGFloat b, CGPoint p,CGFloat r) {
    
    foo result;
    
    CGFloat a = p.x;
    CGFloat c = b - p.y;
    /*
     y = kx + b;
     (x - a) ^ 2 + (y - py) ^ 2 = r ^ 2
     (x - a) ^ 2 + (kx + c) ^ 2 = r ^ 2
     x^2 - 2ax + a^2 + k^2x^2 + 2ckx + c^2 = r^2
     (1+k^2)x^2 + (2ck - 2a)x + (a^2 + c^2) = r^2
     x^2 + ((2ck - 2a) / (1+k^2))x + ((a^2 + c^2) / (1+k^2)) = r^2 / (a^2 + c^2)
     
     
     (a1 + b1)^2 = c1
     a1^2 + 2a1b1 + b1^2 = c1
     
     b1 = ((2ck - 2a) / (1+k^2)) / 2
     (x + b1)^2 = (r^2 / (a^2 + c^2)) - (((a^2 + c^2) / (1+k^2)) - b1^2)
     
     */
    
    CGFloat b1 = ((2 * c * k - 2 * a) / (1 + pow(k,2))) / 2.0;
    CGFloat c1 = (pow(r, 2) / (pow(a, 2) + pow(c, 2))) - ((pow(a, 2) + pow(c, 2)) / (1 + pow(k, 2)) - pow(b1, 2));
    CGFloat x0 = sqrt(c1) - b1;
    CGFloat x1 = -sqrt(c1) - b1;
    
    CGFloat y0 = k * x0 + b;
    CGFloat y1 = k * x1 + b;
    
    result.p0 = CGPointMake(x0, y0);
    result.p1 = CGPointMake(x1, y1);
    
    return result;
}


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
    
    NSLog(@"w: %f h: %f",size.width,size.height);
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
            
        } completion:^(BOOL finished) {
            
        }];
    }
    
}

- (UIBezierPath *) dragPath:(CGPoint)endPoint percent:(CGFloat)percent{
    CGFloat r0 = 10.0f * (1 - percent);
    CGFloat r1 = 0.5 * MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));

    CGPoint originPoint = [self convertPoint:_touchBeforePoint fromView:self.superview];
    CGPoint centerPoint = [self convertPoint:self.center fromView:self.superview];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:originPoint radius:r0 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    [path addArcWithCenter:centerPoint radius:r1 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    
    CGFloat k,k1,b,b1,b2;
    
    k = (centerPoint.y - originPoint.y) / (centerPoint.x - originPoint.y);
    b = centerPoint.y - k * centerPoint.x;
    k1 = -1.0 / k;
    b1 = centerPoint.y - k1 * centerPoint.x;
    b2 = originPoint.y - k1 * originPoint.x;
    
    foo f1 = intersection(k1, b1, centerPoint, r1);
    foo f2 = intersection(k1, b2, originPoint, r0);
    
    [path moveToPoint:f2.p0];
    [path addLineToPoint:f1.p0];
    [path moveToPoint:f2.p1];
    [path addLineToPoint:f1.p1];
    [path addLineToPoint:f1.p0];
    [path moveToPoint:f2.p0];
    [path addLineToPoint:f2.p1];
    
    
//    [path closePath];
    
    return path;
    
    return [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.bounds.size.height * 0.5];
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
