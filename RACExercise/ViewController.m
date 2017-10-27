//
//  ViewController.m
//  RACExercise
//
//  Created by cocoa on 2017/9/11.
//  Copyright © 2017年 wangbingyan. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa.h>

@interface ViewController ()
@property(strong, nonatomic) UITextField *name;
@property(strong, nonatomic) UITextField *password;
@property(strong, nonatomic) UIButton *sign;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _name = [[UITextField alloc] initWithFrame:CGRectMake(15, 100, 200, 40)];
    _name.placeholder = @"name";
    _name.layer.borderColor = [UIColor grayColor].CGColor;
    _name.layer.borderWidth = 1;
    [self.view addSubview:_name];
    
    _password = [[UITextField alloc] initWithFrame:CGRectMake(14, 200, 200, 40)];
    [_password setPlaceholder:@"password"];
    _password.layer.borderColor = [UIColor grayColor].CGColor;
    _password.layer.borderWidth = 1;
    [self.view addSubview:_password];
    
    _sign = [[UIButton alloc] initWithFrame:CGRectMake(15, 300, 100, 40)];
    [_sign setTitle:@"sign" forState:UIControlStateNormal];
    _sign.layer.borderColor = [UIColor brownColor].CGColor;
    _sign.layer.borderWidth = 1;
    [_sign setBackgroundColor:[UIColor grayColor]];
    [self.view addSubview:_sign];
    _sign.enabled = NO;
    
    UITextField *searchbar = [[UITextField alloc] initWithFrame:CGRectMake(15, 400, 300, 40)];
    searchbar.placeholder = @"search";
    searchbar.layer.borderColor = [UIColor blueColor].CGColor;
    searchbar.layer.borderWidth = 1;
    [self.view addSubview:searchbar];
    
    RACSignal *passSignal = [[_password.rac_textSignal map:^id(NSString *value) {
        return @(value.length);
    }] filter:^BOOL(NSNumber *value) {
        return value.integerValue >= 6;
    }];
    
    @weakify(self)
    [passSignal subscribeNext:^(id x) {
        @strongify(self)
        self.password.backgroundColor = [UIColor purpleColor];
    }];
    
    RACSignal *nameSignal = [[_name.rac_textSignal map:^id(NSString *value) {
        return @(value.length);
    }] filter:^BOOL(NSNumber *value) {
        return value.integerValue >= 3;
    }];
    
    [nameSignal subscribeNext:^(id x) {
        @strongify(self)
        self.name.backgroundColor = [UIColor purpleColor];
    }];
    
    [[RACSignal combineLatest:@[passSignal, nameSignal]
                       reduce:^id(NSNumber*usernameValid, NSNumber *passwordValid){
                           return @([usernameValid boolValue]&&[passwordValid boolValue]);
                       }] subscribeNext:^(NSNumber *x) {
                           @strongify(self)
                           if ([x boolValue]) {
                               self.sign.enabled = YES;
                               self.sign.backgroundColor = [UIColor orangeColor];
                           }
                       }];
    
    [[[[_sign rac_signalForControlEvents:UIControlEventTouchUpInside] doNext:^(id x) {
        self.sign.enabled = NO;
        self.sign.backgroundColor = [UIColor grayColor];
    }] flattenMap:^RACStream *(id value) {
        return [self signSignal];
    }] subscribeNext:^(id x) {
        self.sign.enabled = YES;
        self.sign.backgroundColor = [UIColor orangeColor];
        NSLog(@"sign result: %@", x);
    }];
    
//    [[[[[[[self requestAuthority] then:^RACSignal *{
//        return searchbar.rac_textSignal;
//    }] filter:^BOOL(NSString *value) {
//        return [self validValue:value];
//    }] throttle:0.5]
//    flattenMap:^RACStream *(id value) {
//        return [self searchValue:value];
//    }]
//    deliverOn:[RACScheduler mainThreadScheduler]]
//    subscribeNext:^(id x) {
//        NSLog(@"search result is: %@",x);
//    } error:^(NSError *error) {
//        NSLog(@"obtain an error");
//    }];
    
[[[[[searchbar.rac_textSignal filter:^BOOL(NSString *value) {
    return [self validValue:value];
}] throttle:0.5]
flattenMap:^RACStream *(id value) {
    return [self searchValue:value];
}]
deliverOn:[RACScheduler mainThreadScheduler]]
subscribeNext:^(id x) {
    NSLog(@"search result is: %@",x);
} error:^(NSError *error) {
    NSLog(@"obtain an error");
    
}];
    
}

- (RACSignal *)requestAuthority {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"alert" message:@"request for search authority" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction: [UIAlertAction actionWithTitle:@"sure" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
        }] ];
        [alert addAction: [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [subscriber sendError:[[NSError alloc] init]];
        }]];
        [self.navigationController presentViewController:alert animated:YES completion:nil];
        return nil;
    }];
    
    
}

- (RACSignal *)signSignal {
     return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
         [self signWithName:@"123" AndPassword:@"123456" completed:^(BOOL success){
             [subscriber sendNext:@(success)];
             [subscriber sendCompleted];
         }];
         return nil;
     }];
}

- (void)signWithName:(NSString*)name AndPassword: (NSString *)password completed:(void(^)(BOOL))block {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        BOOL success = [name isEqualToString:@"user"] && [password isEqualToString:@"password"];
        if (block) {
            block(success);
        }
    });
}

- (BOOL)validValue: (NSString *)value {
    return value.length >= 2;
}

- (RACSignal *)searchValue:(NSString *)value {
    NSLog(@"call searchValue");
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        double delayInSeconds = 2;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            if ([value containsString:@"a"]) {
                [subscriber sendNext:[NSString stringWithFormat:@"%@ success", value]];
                [subscriber sendCompleted];
            } else {
                [subscriber sendError:[NSError errorWithDomain:NSOSStatusErrorDomain code:400 userInfo:nil]];
            }
        });
        return nil;
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
