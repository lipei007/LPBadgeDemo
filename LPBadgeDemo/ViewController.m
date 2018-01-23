//
//  ViewController.m
//  LPBadgeDemo
//
//  Created by Jack on 2017/12/27.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import "ViewController.h"
#import "LPTextBadge.h"

@interface ViewController ()
{
    LPTextBadge *_badge;
    UIView *_v;
}
@property (strong, nonatomic) IBOutlet UITextField *tf;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(50, 50, 50, 50)];
    v.backgroundColor = [UIColor blueColor];
    [self.view addSubview:v];
    _v = v;
    
    [self.tf setKeyboardType:UIKeyboardTypeNumberPad];
    
    [self foo];
}

- (void) foo {
    LPTextBadge *badge = [[LPTextBadge alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [badge setBadgeNumber:10];
    [_v addSubview:badge];
    _badge = badge;
    _badge.explodeCompletionBlock = ^{
        _badge = nil;
    };
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)click:(UIButton *)sender {
    if (_badge) {
        [_badge setBadgeNumber:[self.tf.text integerValue]];
    } else{
        [self foo];
    }
}

@end
