//
//  LibraryViewController.m
//  epub
//
//  Created by 전자책 on 2015. 12. 2..
//  Copyright (c) 2015년 Baidu. All rights reserved.
//

#import "LibraryViewController.h"
#import "ResourceHelper.h"
#import "BookViewController.h"

@interface LibraryViewController ()

@end

@implementation LibraryViewController  //시작과 동시에 나옴 

- (void)viewDidLoad {
    [super viewDidLoad];
    
   // UIView *view = [[UIView alloc] initWithFrame:CGRectMake(58, 50, 160, 160)];
    //view.backgroundColor = [UIColor colorWithPatternImage:[ResourceHelper loadImageByTheme:NSLocalizedString(@"store_bg", nil)]];
    //[self.view addSubview:view];
    UIAlertView *alertView;
    alertView = [[UIAlertView alloc] initWithTitle:@"MemoPad" message:nil delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes",nil];
    [alertView setMessage:@"Do you want to delete the memo?"];
    [alertView show];
    [alertView release];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
