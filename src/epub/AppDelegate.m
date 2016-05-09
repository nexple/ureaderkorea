#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "BookViewController.h"
#import "LibraryViewController.h"

#import "ResourceHelper.h"
#import "MessageHelper.h"
#import "ResourceHelper.h"
#import "iRate.h"
#import "ASIHTTPRequest.h"
#import "JSONKit.h"
//#import "InAppPurchaseManager.h"
//하단의 메뉴 스토어 없애기
//테마 플러그인 추가할수 있게 하기
//deployment 7부터 스위프트 가능
//번역기 추가할수 있으면 추가할것.
//제스처 추가
//3d 터치 제스쳐 추가(
//아이 클라우드 추가.
//다른 에니메이션 없나..
//아이콘 더 원색으로 찐하게..구글 메티리얼 디자인 가이드 참조할것.애플 디자인 가이드 라인 참조할것..
//웹서버 버튼 스토아로 옮기기

// 알람기능 추가
// https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_pdf/dq_pdf.html 에서 pdf 처리 
@implementation AppDelegate

@synthesize window, detailViewController,leftViewController,rightViewController,mainView,path,slideWidth,selectedChapter;
@synthesize chaptersListViewController,booksListViewController,storeViewController;
@synthesize bookViewController,libraryViewController;


//@synthesize httpServerViewController;  //앱 스토어와 연결-->이펍가져오기.

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.slideWidth = 500;
    } else {
        self.slideWidth = 276;
    }
    
    self.selectedChapter = -1;
    
    [ResourceHelper setUserDefaults:@"default" forKey:@"theme"];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    if([ResourceHelper getUserDefaults:@"installed"] == nil){
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *fileDefaultPath = [[NSBundle mainBundle] pathForResource:NSLocalizedString(@"init_file", nil) ofType:@"epub"];
        if ([fileManager copyItemAtPath:fileDefaultPath toPath:[NSString stringWithFormat:@"%@/%@",documentsDirectory, [NSString stringWithFormat:@"%@.epub",NSLocalizedString(@"init_file", nil)]] error:nil] == NO)
        {
        }
        
		NSFileManager *filemanager=[[NSFileManager alloc] init];
		if ([filemanager fileExistsAtPath:fileDefaultPath]) {
			NSError *error;
			[filemanager removeItemAtPath:fileDefaultPath error:&error];
		}
		[filemanager release];

        [ResourceHelper setUserDefaults:@"1" forKey:@"installed"];
    }
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];
    
    self.mainView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.mainView.backgroundColor = [UIColor blackColor];
    
    [self.window addSubview:mainView];
    [self.window makeKeyAndVisible];
    
    BookViewController *_bookViewController = [[BookViewController alloc] init];
    self.bookViewController = _bookViewController;
    [_bookViewController release];
    //PluginViewController *test=[[testcontroller alloc] init];
    
    UINavigationController *_detailViewController = [[UINavigationController alloc] initWithRootViewController:bookViewController];  //북뷰 컨트롤러 올림
    self.detailViewController = _detailViewController;
    [_detailViewController release];
    
    detailViewController.navigationBar.hidden = YES;
    
    [detailViewController.view.layer setShadowColor:[[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6] CGColor]];
    [detailViewController.view.layer setShadowOffset:CGSizeMake(0, 0)];
    [detailViewController.view.layer setShadowOpacity:1.0];
    [detailViewController.view.layer setShadowRadius:3.0];
    detailViewController.view.layer.shadowPath = [[UIBezierPath bezierPathWithRect:detailViewController.view.bounds] CGPath];
    
    NSMutableArray *controllers = [NSMutableArray array];
    NSMutableArray *items = [NSMutableArray array];
    
    self.booksListViewController = [[BooksListViewController alloc] init];
    self.chaptersListViewController = [[ChaptersListViewController alloc] init];
    self.storeViewController = [[StoreViewController alloc] init];
    //self.libraryViewController = [[LibraryViewController alloc] init]; // 주속 풀면 라이브러리 뷰 컨트롤러가 자동으로 첫화면으로 나옴
    
    chaptersListViewController.bookViewController = bookViewController;
    [controllers addObject:chaptersListViewController];
    [controllers addObject:booksListViewController];
    [controllers addObject:storeViewController];
    //[controllers addObject:libraryViewController]; // 주속 풀면 라이브러리 뷰 컨트롤러가 자동으로 첫화면으로 나옴
    
    [chaptersListViewController release];
    [booksListViewController release];
    //[libraryViewController release];  // 주속 풀면 라이브러리 뷰 컨트롤러가 자동으로 첫화면으로 나옴
    
    NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
    [item setObject:@"Chapters" forKey:@"text"];
    [item setObject:NSLocalizedString(@"tab1", nil) forKey:@"imageNormal"];
    [item setObject:NSLocalizedString(@"tab1_selected", nil) forKey:@"imageSelected"];
    [items addObject:item];
    [item release];
    
    item = [[NSMutableDictionary alloc] init];
    [item setObject:@"Shelf" forKey:@"text"];
    [item setObject:NSLocalizedString(@"tab2", nil) forKey:@"imageNormal"];
    [item setObject:NSLocalizedString(@"tab2_selected", nil) forKey:@"imageSelected"];
    [items addObject:item];
    [item release];

    item = [[NSMutableDictionary alloc] init];
    [item setObject:@"Books" forKey:@"text"];
    [item setObject:NSLocalizedString(@"tab3", nil) forKey:@"imageNormal"];
    [item setObject:NSLocalizedString(@"tab3_selected", nil) forKey:@"imageSelected"];
    [items addObject:item];
    [item release];
/*
    item = [[NSMutableDictionary alloc] init];  //한개 더 추가됨 settings 불러옴
    [item setObject:@"searchlibrary" forKey:@"text"];
    [item setObject:NSLocalizedString(@"tab3", nil) forKey:@"imageNormal"];
    [item setObject:NSLocalizedString(@"tab3_selected", nil) forKey:@"imageSelected"];
    [items addObject:item];
    [item release];
  */
    
 
    
    
    
    self.leftViewController = [[ZYTabViewController alloc] initWithControllers:controllers tabItems:items bg:nil];
    [leftViewController release];
    
    CGRect f = leftViewController.view.frame;
    leftViewController.view.frame = CGRectMake(f.origin.x, f.origin.y, slideWidth, f.size.height);
    [leftViewController build];    
    [leftViewController selectTab:1];
    
    //阴影 그림자
    UIView *shadow =[[UIView alloc] initWithFrame:CGRectMake(0, leftViewController.view.bounds.size.height-44, leftViewController.view.bounds.size.width, 10)];
    shadow.backgroundColor = [UIColor colorWithPatternImage:[ResourceHelper loadImageByTheme:@"menuheaderbg"]];
    [leftViewController.view addSubview:shadow];
    [shadow release];

    self.rightViewController = [[SettingsViewController alloc] init];
    [rightViewController release];
    f = rightViewController.view.frame;
    rightViewController.view.frame = CGRectMake(f.size.width-slideWidth, f.origin.y, slideWidth, f.size.height);
    
    [mainView addSubview:leftViewController.view];
    [mainView addSubview:rightViewController.view];
    [mainView addSubview:detailViewController.view];
    
    self.leftViewController.view.layer.cornerRadius = 3;
    self.leftViewController.view.layer.masksToBounds = YES;
    self.rightViewController.view.layer.cornerRadius = 3;
    self.rightViewController.view.layer.masksToBounds = YES;
    self.detailViewController.view.layer.cornerRadius = 3;
    
    [leftViewController.view.layer setShadowPath:[UIBezierPath bezierPathWithRect:leftViewController.view.bounds].CGPath];
    [rightViewController.view.layer setShadowPath:[UIBezierPath bezierPathWithRect:rightViewController.view.bounds].CGPath];
    [detailViewController.view.layer setShadowPath:[UIBezierPath bezierPathWithRect:detailViewController.view.bounds].CGPath];
    
    CGAffineTransform newTransform =  CGAffineTransformScale(leftViewController.view.transform, 0.8, 0.8);  //에니메이션 적용 
    [leftViewController.view setTransform:newTransform];
    
    CGAffineTransform newTransform1 =  CGAffineTransformScale(rightViewController.view.transform, 0.8, 0.8);
    [rightViewController.view setTransform:newTransform1];
    
    [iRate sharedInstance].appStoreID = APP_ID;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showChapters:) name:@"showChapters" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showBooks:) name:@"showBooks" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSettings:) name:@"showSettings" object:nil]; //스토아임
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchlibraryClicked:) name:@"searchlibrary" object:nil];
    return YES;
}

- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSString *filePath = [url relativePath];
    if([[filePath pathExtension] isEqualToString:@"epub"]){
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *toPath = [NSString stringWithFormat:@"%@/%@",documentsDirectory, [filePath lastPathComponent]];
        
        if ([fileManager copyItemAtPath:filePath toPath:toPath error:nil] == NO){
            NSLog(@"no");
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadBook" object:toPath];
    }
    
    return YES;
}

-(void)loadBook{
    if(self.path!=nil){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadBook" object:self.path];
    }
}

-(void)loadChapter{
    if(self.selectedChapter!=-1){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadChapter" object:[NSString stringWithFormat:@"%d",selectedChapter]];
    }
}

-(void)showChapters:(NSNotification *)notification{
    NSLog(@"show chapters");
    id chapter = [notification object];
    if(chapter!=nil){
        self.selectedChapter = ((NSIndexPath *)chapter).row;
    }else{
        self.selectedChapter = -1;
    }
    
    if([[[mainView subviews] objectAtIndex:0] isEqual:self.leftViewController.view]){
        [mainView exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
    }
    
    CGRect f = detailViewController.view.frame;
        
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(loadChapter)];
    [UIView setAnimationDuration:0.5];
    if(f.origin.x == 0){
        detailViewController.view.frame = CGRectMake(f.origin.x+slideWidth, f.origin.y, f.size.width, f.size.height);
        CGAffineTransform newTransform =  CGAffineTransformScale(leftViewController.view.transform, 1.25, 1.25);
        [leftViewController.view setTransform:newTransform];
    }else{
        detailViewController.view.frame = CGRectMake(f.origin.x-slideWidth, f.origin.y, f.size.width, f.size.height);
        CGAffineTransform newTransform =  CGAffineTransformScale(leftViewController.view.transform, 0.8, 0.8);
        [leftViewController.view setTransform:newTransform];
    }
    [UIView commitAnimations];
    
    [chaptersListViewController loadChapters];
    [booksListViewController loadBooks];
}

-(void)showBooks:(NSNotification *)notification{  //책 제목들 불러오기 
    NSString *book = (NSString *)[notification object];
    if(book!=nil){
        self.path = book;
    }else{
        self.path = nil;
    }
    
    if([[[mainView subviews] objectAtIndex:0] isEqual:self.leftViewController.view]){
        [mainView exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
    }
    
    CGRect f = detailViewController.view.frame;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(loadBook)];  //loadbook 실행
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.5];
    if(f.origin.x == 0){
        detailViewController.view.frame = CGRectMake(f.origin.x+slideWidth, f.origin.y, f.size.width, f.size.height);
        CGAffineTransform newTransform =  CGAffineTransformScale(leftViewController.view.transform, 1.25, 1.25);
        [leftViewController.view setTransform:newTransform];
    }else{
        detailViewController.view.frame = CGRectMake(f.origin.x-slideWidth, f.origin.y, f.size.width, f.size.height);
        CGAffineTransform newTransform =  CGAffineTransformScale(leftViewController.view.transform, 0.8, 0.8);
        [leftViewController.view setTransform:newTransform];
    }
    [UIView commitAnimations];
    
}

-(void)showSettings:(NSNotification *)notification{  //스토어 임 변수명 변경할것 헛갈림
    if([[[mainView subviews] objectAtIndex:0] isEqual:self.rightViewController.view]){
        [mainView exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
    }
    
    CGRect f = detailViewController.view.frame;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.5];
    if(f.origin.x == 0){
        detailViewController.view.frame = CGRectMake(f.origin.x-slideWidth, f.origin.y, f.size.width, f.size.height);
        CGAffineTransform newTransform =  CGAffineTransformScale(rightViewController.view.transform, 1.25, 1.25);
        [rightViewController.view setTransform:newTransform];
        
    }else{
        detailViewController.view.frame = CGRectMake(f.origin.x+slideWidth, f.origin.y, f.size.width, f.size.height);
        CGAffineTransform newTransform =  CGAffineTransformScale(rightViewController.view.transform, 0.8, 0.8);
        [rightViewController.view setTransform:newTransform];
        
    }
    [UIView commitAnimations];
    
}


-(void)searchlibraryClicked:(NSNotification *)notification{  //synthersize 선언 없음
    if([[[mainView subviews] objectAtIndex:0] isEqual:self.rightViewController.view]){
        [mainView exchangeSubviewAtIndex:2 withSubviewAtIndex:0];
    }
    
       NSLog(@"searchlibraryclicked");
    
    
    /*UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"도서관 찾기 된거냐"
                                                        message:nil delegate:self,
                                              cancelButtonTitle:@"go",
                                              otherButtonTitles:@"cancel", nil];
  
    [alertView show];
    [alertView release];
    */
    /*  if([[[mainView subviews] objectAtIndex:0] isEqual:self.rightViewController.view]){
        [mainView exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
    }
    
    CGRect f = detailViewController.view.frame;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.5];
    if(f.origin.x == 0){
        detailViewController.view.frame = CGRectMake(f.origin.x-slideWidth, f.origin.y, f.size.width, f.size.height);
        CGAffineTransform newTransform =  CGAffineTransformScale(rightViewController.view.transform, 1.25, 1.25);
        [rightViewController.view setTransform:newTransform];
        
    }else{
        detailViewController.view.frame = CGRectMake(f.origin.x+slideWidth, f.origin.y, f.size.width, f.size.height);
        CGAffineTransform newTransform =  CGAffineTransformScale(rightViewController.view.transform, 0.8, 0.8);
        [rightViewController.view setTransform:newTransform];
        
    }
    [UIView commitAnimations];
    */
    //self.leftViewController = [[ZYTabViewController alloc] initWithControllers:controllers tabItems:items bg:nil];
    //[leftViewController release];
    
      //detailViewController.view = [[LibraryViewController alloc] init];
     // [libraryViewController release];
     // [rightViewController.view addSubview:libraryViewController];
    
}

- (void) checkEdition {  //버전 체크 
    NSString *url = [NSString stringWithFormat:@"%@%@", HOST, URI_VERSION];
    NSURL *reqUrl = [[NSURL alloc] initWithString:url];
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:reqUrl];
    [reqUrl release];
    [request setDelegate:self];
    [request setValidatesSecureCertificate:NO];
    [request setTimeOutSeconds:10];
    [request setDidFinishSelector:@selector(versionSuccess:)];
    [request setDidFailSelector:@selector(versionFailed:)];
    [request startAsynchronous];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 2 && buttonIndex == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:DOWNLOAD_URL]];
    }
}

- (void)versionSuccess:(ASIHTTPRequest *)request
{
    NSDictionary *res = [[request responseString] objectFromJSONString];
    
    NSString *currentVersion = (NSString *)[[[NSBundle mainBundle] infoDictionary] valueForKey:kCFBundleVersionKey];
    if(res!=nil && [res objectForKey:@"v"]!=nil){
        NSString *force = [res objectForKey:@"f"];
        NSString *version = [res objectForKey:@"v"];
        if ([version floatValue] > [currentVersion floatValue]) {
           UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"new_version", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"go", nil) otherButtonTitles:NSLocalizedString(@"cancel", nil), nil];
           alertView.tag = 2;
           [alertView show];
           [alertView release];
       }
    }
    
    [request release];
}

- (void)versionFailed:(ASIHTTPRequest *)request
{
    NSLog(@"check version err:%@",request.error);
    [request cancel];
    [request release];
}

- (void)applicationWillEnterForeground:(UIApplication *)application{
    NSLog(@"check version");
    
    //[[[InAppPurchaseManager alloc] init] loadStore];
    [self checkEdition];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [window release];
    [detailViewController release];
    
    [super dealloc];
}


@end

