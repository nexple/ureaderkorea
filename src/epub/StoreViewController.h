//
//  StoreViewController.h
//  epub
//
//  Created by zhiyu on 13-6-8.
//  Copyright (c) 2013年 Baidu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HttpServerViewController.h"


@interface StoreViewController : UIViewController
@property (nonatomic,retain) HttpServerViewController *httpServerViewController;

@property (nonatomic, retain) UIButton *uploadButton;
@property (nonatomic, retain) UIButton *contactButton;


@end
