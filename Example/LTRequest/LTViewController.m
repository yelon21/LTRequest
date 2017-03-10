//
//  LTViewController.m
//  LTRequest
//
//  Created by yelon21 on 07/11/2016.
//  Copyright (c) 2016 yelon21. All rights reserved.
//

#import "LTViewController.h"
#import "LTRequest.h"

@interface LTViewController ()

@end

@implementation LTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    LTRequest *request = [[LTRequest alloc]init];
//    [request lt_requestUrl:@"http://img.ivsky.com/img/bizhi/pre/201606/06/maikailun_paoche.jpg"
//                httpMethod:@"GET"
//                  response:^(NSURLResponse * _Nullable response, NSString * _Nullable errorString) {
//                      
//                      NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
//                      NSLog(@"urlResponse.statusCode=%@",@(urlResponse.statusCode));
//                      NSLog(@"localizedStringForStatusCode=%@",[NSHTTPURLResponse localizedStringForStatusCode:urlResponse.statusCode]);
//                      NSLog(@"allHeaderFields=%@",urlResponse.allHeaderFields);
//                      NSLog(@"urlResponse.statusCode=%@",@(urlResponse.statusCode));
//                  } progress:^(double currentLength, double totleLength, NSData * _Nonnull receiveData, NSData * _Nonnull appendData) {
//                      
//                      NSLog(@"progress=%@",@(currentLength/totleLength));
//                      
//                  } complete:^(NSData * _Nullable responseData, NSString * _Nullable errorString) {
//                      
//                      NSLog(@"errorString=%@",errorString);
//                  }];
 
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    LTRequest *request = [[LTRequest alloc]init];
    
    request.supportSSL = YES;
    
    [request lt_setValue:@"WEQWE" forHTTPHeaderField:@"UserAgent"];
    [request lt_addPostValue:@"VALUE" forKey:@"KEYYY"];
    
    [request lt_requestUrl:@"https://app.yjpal.com:5556/unifiedAction.do"
                httpMethod:@"POST"
                  response:^(NSURLResponse * _Nullable response, NSString * _Nullable errorString) {
   
                      NSLog(@"errorString=%@",errorString);
                      
                  } progress:^(double currentLength, double totleLength, NSData * _Nonnull receiveData, NSData * _Nonnull appendData) {
                      
                      
                  } complete:^(NSData * _Nullable responseData, NSString * _Nullable errorString) {
                      
                      NSLog(@"string=%@",[[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding]);
                      NSLog(@"errorString=%@",errorString);
                      
                  }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
