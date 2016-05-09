//
//  StoreViewController.m
//  epub
//
//  Created by zhiyu on 13-6-8.
//  Copyright (c) 2013年 Baidu. All rights reserved.
//
// 뭔가 구입 가능하게
// 수정가능하게


#import "StoreViewController.h"
#import "ResourceHelper.h"
#import <CoreText/CoreText.h>  //pdf 문서 처리 

@interface StoreViewController ()

@end

@implementation StoreViewController

@synthesize uploadButton;
@synthesize contactButton;

@synthesize httpServerViewController;  //앱 스토어와 연결-->이펍가져오기.


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
       

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
	// Do any additional setup after loading the view.
    //웹뷰 불러올것
     //www.insubstoy.com 책을 구매할수 있도록 할것
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(58, 50, 160, 160)];
    view.backgroundColor = [UIColor colorWithPatternImage:[ResourceHelper loadImageByTheme:NSLocalizedString(@"store_bg", nil)]];
    [self.view addSubview:view];
    
    self.uploadButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 300, 88, 44)];
    [uploadButton release];
    [uploadButton setImage:[ResourceHelper loadImageByTheme:NSLocalizedString(@"upload_btn", nil)] forState:UIControlStateNormal];
    [uploadButton addTarget:self action:@selector(startUpload:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:uploadButton];
 
    self.contactButton = [[UIButton alloc] initWithFrame:CGRectMake(160, 200, 88, 44)];  //제작사 홈페이지 바로가기 
 //   NSString* newBtnTitle = NSLocalizedString(@"LOCALIZED_KEY", nil);
    [contactButton release];
    [contactButton setImage:[ResourceHelper loadImageByTheme:NSLocalizedString(@"upload_btn", nil)] forState:UIControlStateNormal];
    [contactButton addTarget:self action:@selector(contact:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:contactButton];
    
    
    //HTTP SERVER
    self.httpServerViewController = [[HttpServerViewController alloc] init];  //http 서버 컨트롤러
    [httpServerViewController release];
    [self.view addSubview:httpServerViewController.view];
    httpServerViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
 
    
}

- (void) startUpload:(id)sender{
    [httpServerViewController startServer];//서버 고를수 있게 할것..
}

- (void) contact:(id)sender{
         NSURL *url = [NSURL URLWithString:@"http://www.nexple.net"];
        [[UIApplication sharedApplication] openURL:url];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
