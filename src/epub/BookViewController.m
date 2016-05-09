#import "BookViewController.h"
#import <QuartzCore/QuartzCore.h> //간단한 에니메이션 구현때 사용  pdf 문서 처리 
#import "UIWebView+SearchWebView.h"  //? 어디에서 검색하는건지 모르겠음.업로드용인듯 하다
#import "Chapter.h"
#import "EPubBookLoader.h"
#import "MessageHelper.h"
#import "Constants.h"
#import "GADBannerView.h"
#import <CoreText/CoreText.h>

//#import "LibraryViewController.h"
//ux 나 ui 개량해서
//조절할수 있을것.

@interface BookViewController()
 //책 넘기기 페이지 카운트 넘버 등
- (void) gotoNextSpine; //spine=척추 톱니바퀴를 말하는듯.
- (void) gotoPrevSpine;
- (void) gotoNextPage;
- (void) gotoPrevPage;
- (int)  getGlobalPageCount;
- (void) gotoPageInCurrentSpine: (int)pageIndex;
- (void) updatePagination;
- (void) toLastReadPage;
- (void) recordLastReadPage;

@end

@implementation BookViewController

@synthesize historyListViewController; //한글화 필요
@synthesize httpServerViewController;  //앱 스토어와 연결-->이펍가져오기.
@synthesize libraryViewController; //도서관 찾기 뷰 컨트롤러 추가 2015.12.5

@synthesize bookLoader;
@synthesize headerbar;
@synthesize toolbar;
@synthesize webView;
@synthesize settingsButton;

@synthesize searchlibraryButton;  //도서관 찾기 버튼 추가 2015.12.5

@synthesize chapterListButton;
//@synthesize decTextSizeButton;
@synthesize incTextSizeButton;
//@synthesize uploadButton;
@synthesize pageSlider;
@synthesize currentPageLabel;
@synthesize currentPageLabel2;
@synthesize epubLoaded;
@synthesize paginating;
@synthesize enablePaging;
@synthesize searching;
@synthesize currentSpineIndex;
@synthesize currentPageInSpineIndex;
@synthesize pagesInCurrentSpineCount;
@synthesize currentTextSize;
@synthesize totalPagesCount;
@synthesize hud;
@synthesize isClearWebViewContent;

#pragma mark -
-(id)init{
    self = [super init];
    if(self!=nil){
        self.enablePaging = NO;
        self.isClearWebViewContent = NO;
    }
    //처음 시작할때 책과 챕터 불러오는듯.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadBook:) name:@"loadBook" object:nil];  //푸시 알람
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadChapter:) name:@"loadChapter" object:nil];  //노티를 날린다고 함(은어)

    return self;
}

- (void) loadChapter:(NSNotification *)notification{
    [self hideToolbar];
    
    NSString *chapter = (NSString *)[notification object];
    [self loadSpine:[chapter intValue] atPageIndex:0];
}

- (void) loadBook:(NSNotification *)notification{
    
    [historyListViewController.view setHidden:YES];
    [currentPageLabel setText:@"0/0"];
    
    NSString *path = [notification object];
    currentSpineIndex = 0;
    currentPageInSpineIndex = 0;
    pagesInCurrentSpineCount = 0;
    totalPagesCount = 0;
	searching = NO;
    epubLoaded = NO;
    
    self.isClearWebViewContent = YES;
    [webView loadHTMLString:NSLocalizedString(@"loading data", nil) baseURL:nil];
    
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.delegate = self;
    hud.labelText = NSLocalizedString(@"loading page", nil);
    [hud show:NO];
    
    [self hideToolbar];
    [NSThread detachNewThreadSelector:@selector(start:) toTarget:self withObject:path];
}

-(void)start:(NSString *)path{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [hud hide:NO];
    
    self.bookLoader = [[EPubBookLoader alloc] initWithPath:path];
    [bookLoader release];
    
    if(bookLoader.error == 1){
        [webView loadHTMLString:NSLocalizedString(@"parse_error", nil) baseURL:nil];
    }else{
        epubLoaded = YES;
        
        //record history
        NSMutableArray *items = [FileHelper getDataFromFile:@"history"];
        if(items.count < 100){
            NSArray *array = [path componentsSeparatedByString:@"/"];
            
            for(NSDictionary *item in items){
                if([[item objectForKey:@"name"] isEqualToString:[array objectAtIndex:(array.count-1)]]){
                    [FileHelper deleteData:item ofFile:@"history"];
                }
            }
            NSMutableDictionary *book = [[NSMutableDictionary alloc] init];
            [book setObject:[array objectAtIndex:(array.count-1)] forKey:@"name"];
            [book setObject:path forKey:@"path"];
            
            [FileHelper prependData:book toFile:@"history"];
            [book release];
        }
        
        //set last read page parameters
        [self toLastReadPage];
        if(currentSpineIndex > bookLoader.spineArray.count-1){
            currentSpineIndex = 0;
        }
        [self performSelectorOnMainThread:@selector(updatePagination) withObject:nil waitUntilDone:NO];
        [pool release];
    }
}

- (void) chapterDidFinishLoad:(Chapter *)chapter{
    totalPagesCount+=chapter.pageCount;
    
	if(chapter.chapterIndex + 1 < [bookLoader.spineArray count]){
		[[bookLoader.spineArray objectAtIndex:chapter.chapterIndex+1] setDelegate:self];
		[[bookLoader.spineArray objectAtIndex:chapter.chapterIndex+1] loadChapterWithWindowSize:webView.bounds fontPercentSize:currentTextSize];
		[currentPageLabel setText:[NSString stringWithFormat:@"0/%d", totalPagesCount]];
	} else {
		[currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], totalPagesCount]];
		[pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)totalPagesCount animated:YES];
		paginating = NO;
		NSLog(@"Pagination Ended!");
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"bookDidLoaded" object:nil];
	}
}

- (int) getGlobalPageCount{
	int pageCount = 0;
	for(int i=0; i<currentSpineIndex; i++){
		pageCount+= [[bookLoader.spineArray objectAtIndex:i] pageCount]; 
	}
	pageCount+=currentPageInSpineIndex+1;
	return pageCount;
}

- (void) loadSpine:(int)spineIndex atPageIndex:(int)pageIndex {
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.delegate = self;
    hud.labelText = NSLocalizedString(@"loading page", nil);
    [hud show:NO];
    
	webView.hidden = YES;
	
	NSURL* url = [NSURL fileURLWithPath:[[bookLoader.spineArray objectAtIndex:spineIndex] spinePath]];
	self.isClearWebViewContent = NO;
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
	currentPageInSpineIndex = pageIndex;
	currentSpineIndex = spineIndex;
}

- (void) gotoPageInCurrentSpine:(int)pageIndex{
    //不分页条件下，上一个章节最后一页 비 정렬 상태 의마지막 페이지다음
    if(pageIndex == -1){
        pageIndex = pagesInCurrentSpineCount-1;
        currentPageInSpineIndex = pageIndex;
    }
    
	if(pageIndex>=pagesInCurrentSpineCount){
		pageIndex = pagesInCurrentSpineCount - 1;
		currentPageInSpineIndex = pagesInCurrentSpineCount - 1;	
	}
	
	float pageOffset = pageIndex*webView.bounds.size.width;
    
	NSString* goToOffsetFunc = [NSString stringWithFormat:@" function pageScroll(xOffset){ window.scroll(xOffset,0); } "];
	NSString* goTo =[NSString stringWithFormat:@"pageScroll(%f)", pageOffset];
	
	[webView stringByEvaluatingJavaScriptFromString:goToOffsetFunc];
	[webView stringByEvaluatingJavaScriptFromString:goTo];
    
    if(!enablePaging){
            [currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",currentPageInSpineIndex+1, pagesInCurrentSpineCount]];
            [pageSlider setValue:(float)100*(float)(currentPageInSpineIndex+1)/(float)pagesInCurrentSpineCount animated:YES];	
    }else{
        if(!paginating){
            [currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], totalPagesCount]];
            [pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)totalPagesCount animated:YES];	
        }
    }
	
	webView.hidden = NO;
    
    [self recordLastReadPage];
}

- (void) gotoNextSpine {
	if(!paginating){
		if(currentSpineIndex+1<[bookLoader.spineArray count]){
			[self loadSpine:++currentSpineIndex atPageIndex:0];
		}	
	}
}

- (void) gotoPrevSpine {
	if(!paginating){
		if(currentSpineIndex-1>=0){
			[self loadSpine:--currentSpineIndex atPageIndex:0];
		}	
	}
}

- (void) gotoNextPage {
    if(!paginating){
        if(currentPageInSpineIndex+1<pagesInCurrentSpineCount){
            [self gotoPageInCurrentSpine:++currentPageInSpineIndex];
        } else {
            [self gotoNextSpine];
        }		
    }
}

- (void) gotoPrevPage {
	if (!paginating) {
		if(currentPageInSpineIndex-1>=0){
			[self gotoPageInCurrentSpine:--currentPageInSpineIndex];
		} else {
            if(enablePaging){
                if(currentSpineIndex!=0){
                    int targetPage = [[bookLoader.spineArray objectAtIndex:(currentSpineIndex-1)] pageCount];
                    [self loadSpine:--currentSpineIndex atPageIndex:targetPage-1];
                }
            }else{
                //不分页条件下，上一个章节最后一页，-1标示 비 정렬 상태 , 챕터 의 마지막 페이지 에 -1 마크
                if(currentSpineIndex-1>=0)
                [self loadSpine:--currentSpineIndex atPageIndex:-1];
            }
		}
	}
}


- (void) increaseTextSizeClicked:(id)sender{
    
  
            self.pageSlider.hidden = YES; //슬라이드바 보이기 YES 보이기 NO 숨기기
   
    
	//if(!paginating){
//		if(currentTextSize+25<=200){
//			currentTextSize+=25;
//			[self updatePagination];
//			if(currentTextSize == 200){
//				[incTextSizeButton setEnabled:NO];
//			}
//			[decTextSizeButton setEnabled:YES];   //텍스트 크기 키우기 이걸 좀 자동으로 하고 싶다.
//		}
//	}
}
 

- (void) searchlibraryClicked:(id)sender{  //도서관 찾기 버튼 추가 2015.12.5
    
  // self.libraryViewController = [[LibraryViewController alloc] init];
  //  [libraryViewController release];
  //  [self.view addSubview:libraryViewController];
    
     [[NSNotificationCenter defaultCenter] postNotificationName:@"searchlibraryClicked" object:nil];  //글로벌 변수 같은 역활을 한다.appdelegate.m의 함수를 호출
    // LibraryViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
 ///  LibraryViewController = [[LibraryViewController alloc] initWithView:self.view];
 ///   [self.view addSubview: LibraryViewController];
   // hud.delegate = self;
//hud.labelText = NSLocalizedString(@"loading page", nil);
  //  [hud show:NO];
   // self.libraryViewController = [[LibraryViewController alloc] init];  //히스토리 뷰 컨트롤러
   // [LibraryViewController release];
    //[self.view addSubview:historyListViewController.view];
   // [self.view addSubview:libraryViewController];
    

    
}

- (void) decreaseTextSizeClicked:(id)sender{
	if(!paginating){
		if(currentTextSize-25>=50){
			currentTextSize-=25;
			[self updatePagination];
			if(currentTextSize==50){
				//[decTextSizeButton setEnabled:NO];
			}
		//	[incTextSizeButton setEnabled:YES];
		}
	}
}

- (void) doneClicked:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
}


- (void) slidingStarted:(id)sender{  //에니메이션 바꿔도 될듯
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionMoveIn;
    transition.subtype = kCATransitionFade;
    [currentPageLabel2.layer addAnimation:transition forKey:nil];
    currentPageLabel2.frame = CGRectMake((self.view.frame.size.width-currentPageLabel2.frame.size.width)/2, currentPageLabel2.frame.origin.y, currentPageLabel2.frame.size.width, currentPageLabel2.frame.size.height);
    
    
    int targetPage = 0;
    NSString *text;
    
    if(enablePaging){
        targetPage = ((pageSlider.value/(float)100)*(float)totalPagesCount);
        if (targetPage==0) {
            targetPage++;
        }
        text = [NSString stringWithFormat:@"%d/%d", targetPage, totalPagesCount];
        
    }else{
        targetPage = ((pageSlider.value/(float)100)*(float)pagesInCurrentSpineCount);
        if (targetPage==0) {
            targetPage++;
        }
        text = [NSString stringWithFormat:@"%d/%d", targetPage, pagesInCurrentSpineCount];
    }
	
    [currentPageLabel setText:text];
}

- (void) slidingChanged:(id)sender{  //슬라이더..
    int targetPage = 0;
	int chapterIndex = 0;
	int pageIndex = 0;
    NSString *text;
    
    if(enablePaging){
        targetPage = ((pageSlider.value/(float)100)*(float)totalPagesCount);
        if (targetPage==0) {
            targetPage++;
        }
        
        text = [NSString stringWithFormat:@"%d/%d", targetPage, totalPagesCount];
        
        int pageSum = 0;
        for(chapterIndex=0; chapterIndex<[bookLoader.spineArray count]; chapterIndex++){
            pageSum+=[[bookLoader.spineArray objectAtIndex:chapterIndex] pageCount];
            if(pageSum>=targetPage){
                pageIndex = [[bookLoader.spineArray objectAtIndex:chapterIndex] pageCount] - 1 - pageSum + targetPage;
                break;
            }
        }
        
    }else{
        targetPage = ((pageSlider.value/(float)100)*(float)pagesInCurrentSpineCount);
        if (targetPage==0) {
            targetPage++;
        }
        text = [NSString stringWithFormat:@"%d/%d", targetPage, pagesInCurrentSpineCount];
        
        pageIndex = targetPage-1;
    }
    
    currentPageInSpineIndex = pageIndex;
    currentPageLabel.text = text;
    currentPageLabel2.text = text;
}

- (void) slidingEnded:(id)sender{
    int targetPage = 0;
	int chapterIndex = 0;
	int pageIndex = 0;
    NSString *text;
    
    if(enablePaging){
        targetPage = ((pageSlider.value/(float)100)*(float)totalPagesCount);
        if (targetPage==0) {
            targetPage++;
        }
        
        text = [NSString stringWithFormat:@"%d/%d", targetPage, totalPagesCount];
        
        int pageSum = 0;
        for(chapterIndex=0; chapterIndex<[bookLoader.spineArray count]; chapterIndex++){
            pageSum+=[[bookLoader.spineArray objectAtIndex:chapterIndex] pageCount];
            if(pageSum>=targetPage){
                pageIndex = [[bookLoader.spineArray objectAtIndex:chapterIndex] pageCount] - 1 - pageSum + targetPage;
                break;
            }
        }
        
    }else{
        targetPage = ((pageSlider.value/(float)100)*(float)pagesInCurrentSpineCount);
        if (targetPage==0) {
            targetPage++;
        }
        text = [NSString stringWithFormat:@"%d/%d", targetPage, pagesInCurrentSpineCount];
        
        pageIndex = targetPage-1;
    }
    
    currentPageInSpineIndex = pageIndex;
    currentPageLabel.text = text;
    currentPageLabel2.text = text;
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal;
    transition.subtype = kCATransitionFade;
    [currentPageLabel2.layer addAnimation:transition forKey:nil];
    currentPageLabel2.frame = CGRectMake(self.view.frame.size.width, currentPageLabel2.frame.origin.y, currentPageLabel2.frame.size.width, currentPageLabel2.frame.size.height);
    
	[self loadSpine:currentSpineIndex atPageIndex:currentPageInSpineIndex];
    [self hideToolbar];
}

- (void) startUpload:(id)sender{
    [httpServerViewController startServer];//서버 고를수 있게 할것..
}

- (void) showChapterIndex:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showChapters" object:nil];  
}

- (void) showSettings:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showSettings" object:nil];  
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView{
    if(self.isClearWebViewContent)
        return;
    
    [hud hide:NO];
    
	NSString *insertRule1 = [NSString stringWithFormat:@"addCSSRule('html', 'font-size:14px;margin:0px;padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", webView.frame.size.height, webView.frame.size.width];
	NSString *insertRule2 = @"addCSSRule('p', 'text-align: justify;')";
    NSString *insertRule3 = @"addCSSRule('img', 'max-width:100%; max-height:100%;border:none;')";
    
    NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', 'background:#fff;font-weight:normal;-webkit-text-size-adjust: %d%%;')", currentTextSize];
	NSString *setHighlightColorRule = @"addCSSRule('highlight', 'background-color: yellow;')";
    
	[webView stringByEvaluatingJavaScriptFromString:SHEET];
	[webView stringByEvaluatingJavaScriptFromString:ADDCSSRULE];
	[webView stringByEvaluatingJavaScriptFromString:insertRule1];
	[webView stringByEvaluatingJavaScriptFromString:insertRule2];
	[webView stringByEvaluatingJavaScriptFromString:insertRule3];
    [webView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
    [webView stringByEvaluatingJavaScriptFromString:setHighlightColorRule];
	int totalWidth = [[webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"] intValue];
	pagesInCurrentSpineCount = (int)((float)totalWidth/webView.bounds.size.width);
    
    if(currentPageInSpineIndex > pagesInCurrentSpineCount-1)
        currentPageInSpineIndex = pagesInCurrentSpineCount -1;
	[self gotoPageInCurrentSpine:currentPageInSpineIndex];
}

- (void) updatePagination{    
	if(epubLoaded){
        if(!paginating){
            NSLog(@"Pagination Started!");
            [currentPageLabel setText:@"0/0"];
            
            if(enablePaging){
                 totalPagesCount=0;
                paginating = YES;
                hud = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:hud];
                hud.delegate = self;
                hud.labelText = NSLocalizedString(@"loading page", nil);
                [hud show:YES];
                [[bookLoader.spineArray objectAtIndex:0] setDelegate:self];
                [[bookLoader.spineArray objectAtIndex:0] loadChapterWithWindowSize:webView.bounds fontPercentSize:currentTextSize];
            }
            [webView loadHTMLString:@"" baseURL:nil];
            
            [self loadSpine:currentSpineIndex atPageIndex:currentPageInSpineIndex]; 
            
            NSLog(@"pages:%d",currentSpineIndex);
        }
	}
}

-(void)toLastReadPage{
    NSMutableDictionary *last = (NSMutableDictionary *)[ResourceHelper getUserDefaults:self.bookLoader.filePath];
    if(last!=nil){
        currentSpineIndex       = [[last objectForKey:@"currentSpineIndex"] intValue];
        currentTextSize         = [[last objectForKey:@"currentTextSize"] intValue];
        currentPageInSpineIndex = [[last objectForKey:@"currentPageInSpineIndex"] intValue];
    }
}

-(void)recordLastReadPage{
    NSMutableDictionary *last = [[NSMutableDictionary alloc] init];
    NSString *rCurrentSpineIndex = [[NSString alloc] initWithFormat:@"%d",currentSpineIndex];
    NSString *rCurrentPageInSpineIndex = [[NSString alloc] initWithFormat:@"%d",currentPageInSpineIndex];
    NSString *rCurrentTextSize = [[NSString alloc] initWithFormat:@"%d",currentTextSize];
    
    [last setObject:rCurrentSpineIndex forKey:@"currentSpineIndex"];
    [last setObject:rCurrentPageInSpineIndex forKey:@"currentPageInSpineIndex"];
    [last setObject:rCurrentTextSize forKey:@"currentTextSize"];
     
    [rCurrentSpineIndex release];
    [rCurrentPageInSpineIndex release];
    [rCurrentTextSize release];
    
    [ResourceHelper setUserDefaults:last forKey:self.bookLoader.filePath];
    
    [last release];
}

#pragma mark -
#pragma mark Rotation support

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    [self updatePagination];
	return YES;
}

#pragma mark -
#pragma mark View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad { //뷰 로드
    [super viewDidLoad];
    
    self.view.frame = [[UIScreen mainScreen] bounds];
	self.view.backgroundColor = [UIColor whiteColor];
    
    self.view.layer.cornerRadius = 3;
    self.view.clipsToBounds = YES;
    
    UIImageView *logoView=[[UIImageView alloc] initWithImage:[ResourceHelper loadImageByTheme:NSLocalizedString(@"logo", nil)]]; //이미지 로고
    
    logoView.frame = CGRectMake(17, 15, 56,16);
    [self.view addSubview:logoView];
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(5, 30, self.view.frame.size.width-10, self.view.frame.size.height - 35)];
    [webView release];
    
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    [webView setDelegate:self];
    [self.view addSubview:webView];
    
    UITapGestureRecognizer *singleFingerOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleFingerEvent)];  //탭 제스쳐 
    singleFingerOne.numberOfTouchesRequired = 1; //手指数
    singleFingerOne.numberOfTapsRequired = 1; //tap次数
    singleFingerOne.delegate = self;
    [self.webView addGestureRecognizer:singleFingerOne];
    [singleFingerOne release];
    
    UIScrollView* sv = nil;
	for (UIView* v in  webView.subviews) {
		if([v isKindOfClass:[UIScrollView class]]){
			sv = (UIScrollView*) v;
			sv.scrollEnabled = NO;
			sv.bounces = NO;
		}
	}
    
	currentTextSize = 100;	 
	
	UISwipeGestureRecognizer* rightSwipeRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gotoNextPage)] autorelease];
	[rightSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];  //오른쪽을 쓸어내기
	
	UISwipeGestureRecognizer* leftSwipeRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gotoPrevPage)] autorelease];
	[leftSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight]; //왼쪽으로 쓸어내기 
	
	[webView addGestureRecognizer:rightSwipeRecognizer];
	[webView addGestureRecognizer:leftSwipeRecognizer];
    
    
    self.currentPageLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width-258, 7, 250, 10)];
    [currentPageLabel release];
    currentPageLabel.backgroundColor = [UIColor clearColor];
    currentPageLabel.font = [UIFont systemFontOfSize:10];
    currentPageLabel.textAlignment = UITextAlignmentRight;
    currentPageLabel.textColor = [UIColor colorWithRed:37/255.f green:37/255.f blue:37/255.f alpha:1];
    [self.view addSubview:currentPageLabel];
    
    
    self.historyListViewController = [[HistoryListViewController alloc] init];  //히스토리 뷰 컨트롤러
    [historyListViewController release];
    [self.view addSubview:historyListViewController.view];
    historyListViewController.view.frame = CGRectMake(0, 50, self.view.frame.size.width, self.view.frame.size.height-100);
    
    self.headerbar = [[UIView alloc] initWithFrame:CGRectMake(0, -44, self.view.frame.size.width, 44)];
    [headerbar release];
    
    self.headerbar.backgroundColor = [UIColor whiteColor];
    
    //阴影
    UIView *shadow =[[UIView alloc] initWithFrame:CGRectMake(0, headerbar.frame.size.height - 10, headerbar.frame.size.width, 10)];
    shadow.backgroundColor = [UIColor colorWithPatternImage:[ResourceHelper loadImageByTheme:@"listheaderbg"]];
    [headerbar addSubview:shadow];
    [shadow release];
   
    
   // UIView *sliderbg =[[UIView alloc] initWithFrame:CGRectMake(0, 0, headerbar.frame.size.width, 40)];  //슬라이더 뒤의 눈금 배경
   // sliderbg.backgroundColor = [UIColor colorWithPatternImage:[ResourceHelper loadImageByTheme:@"sliderbg"]];
   // [headerbar addSubview:sliderbg];
   // [sliderbg release];
    
    self.pageSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 550.5, self.view.frame.size.width, 10)];  //슬라이더 위치 조정(화면 꼭대기에 붙어 있음) 밑으로 내림 2015/12/8
    [pageSlider release];
    
    [pageSlider setThumbImage:[ResourceHelper loadImageByTheme:@"slider_ball"] forState:UIControlStateNormal];
    [pageSlider setThumbImage:[ResourceHelper loadImageByTheme:@"slider_ball"] forState:UIControlStateHighlighted];
	[pageSlider setMinimumTrackImage:[ResourceHelper loadImageByTheme:@"orangeslide"] forState:UIControlStateNormal];
	[pageSlider setMaximumTrackImage:[ResourceHelper loadImageByTheme:@"yellowslide"] forState:UIControlStateNormal];
    
    [pageSlider setMinimumValue:0];
    [pageSlider setMaximumValue:100];
    [pageSlider addTarget:self action:@selector(slidingEnded:) forControlEvents:UIControlEventTouchUpInside];
    [pageSlider addTarget:self action:@selector(slidingEnded:) forControlEvents:UIControlEventTouchUpOutside];
    [pageSlider addTarget:self action:@selector(slidingChanged:) forControlEvents:UIControlEventValueChanged];
    [pageSlider addTarget:self action:@selector(slidingStarted:) forControlEvents:UIControlEventTouchDown];
    //아무 반응 없으면 자동으로 슬라이더 사라지는 기능 추가
    [self.headerbar addSubview:pageSlider];
    [self.view addSubview:headerbar];
    
    //Toolbar
    self.toolbar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-44, self.view.frame.size.width, 44)];
    [toolbar release];
    
    self.toolbar.backgroundColor = [UIColor whiteColor];
    
    //阴影
    shadow =[[UIView alloc] initWithFrame:CGRectMake(0, 0, toolbar.frame.size.width, 10)];
    shadow.backgroundColor = [UIColor colorWithPatternImage:[ResourceHelper loadImageByTheme:@"listfooterbg"]];
    [toolbar addSubview:shadow];
    [shadow release];
    
    self.chapterListButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [chapterListButton release];
    [chapterListButton setImage:[ResourceHelper loadImageByTheme:@"books"] forState:UIControlStateNormal];
    [chapterListButton addTarget:self action:@selector(showChapterIndex:) forControlEvents:UIControlEventTouchUpInside];
    
 /*   self.uploadButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 0, 88, 44)];
    [uploadButton release];
    [uploadButton setImage:[ResourceHelper loadImageByTheme:NSLocalizedString(@"upload_btn", nil)] forState:UIControlStateNormal];
    [uploadButton addTarget:self action:@selector(startUpload:) forControlEvents:UIControlEventTouchUpInside];
   */
    
    self.settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(toolbar.frame.size.width - 44, 0, 44, 44)];
    [settingsButton release];
    [settingsButton setImage:[ResourceHelper loadImageByTheme:@"settings"] forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
    
   /* self.decTextSizeButton = [[UIButton alloc] initWithFrame:CGRectMake(toolbar.frame.size.width/2, 0, 44, 44)];
    [decTextSizeButton release];
    [decTextSizeButton setImage:[ResourceHelper loadImageByTheme:@"dec"] forState:UIControlStateNormal];
    [decTextSizeButton setImage:[ResourceHelper loadImageByTheme:@"dec"] forState:UIControlStateHighlighted];
    [decTextSizeButton addTarget:self action:@selector(decreaseTextSizeClicked:) forControlEvents:UIControlEventTouchUpInside];
    */
    self.incTextSizeButton = [[UIButton alloc] initWithFrame:CGRectMake(toolbar.frame.size.width/2+56, 0, 44, 44)];
   // [incTextSizeButton release];
    [incTextSizeButton setImage:[ResourceHelper loadImageByTheme:@"inc"] forState:UIControlStateNormal];
    [incTextSizeButton setImage:[ResourceHelper loadImageByTheme:@"inc"] forState:UIControlStateHighlighted];
    [incTextSizeButton addTarget:self action:@selector(increaseTextSizeClicked:) forControlEvents:UIControlEventTouchUpInside];
  
    
  /*  self.searchlibraryButton = [[UIButton alloc] initWithFrame:CGRectMake(150, 0, 88, 44)];  //도서관 찾기 버튼 추가
    [searchlibraryButton release];
    [searchlibraryButton setImage:[ResourceHelper loadImageByTheme:@"settings"] forState:UIControlStateNormal];
    [searchlibraryButton setImage:[ResourceHelper loadImageByTheme:@"settings"] forState:UIControlStateHighlighted];
    [searchlibraryButton addTarget:self action:@selector( searchlibraryClicked:) forControlEvents:UIControlEventTouchUpInside];
    */
    
    
    [self.toolbar addSubview:chapterListButton];  //툴바에 버튼 부탁 
  //  [self.toolbar addSubview:uploadButton];
   // [self.toolbar addSubview:decTextSizeButton];
    [self.toolbar addSubview:incTextSizeButton];
   // [self.toolbar addSubview:settingsButton];
    
    [self.toolbar addSubview:searchlibraryButton]; //도서관 찾기 버튼 추가
    
    [self.view addSubview:toolbar];
    
    UILabel *_pageText = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width, (self.view.frame.size.height+80)/2, 100, 30)];
    _pageText.layer.cornerRadius = 5;
    _pageText.backgroundColor = [UIColor colorWithRed:68/255.f green:68/255.f blue:68/255.f alpha:1];
    _pageText.textColor = [UIColor colorWithRed:172/255.f green:134/255.f blue:98/255.f alpha:1];
    _pageText.font = [UIFont systemFontOfSize:24];
    _pageText.textAlignment = NSTextAlignmentCenter;
    self.currentPageLabel2 = _pageText;
    [_pageText release];
    
    [self.view addSubview:currentPageLabel2];
    
    //HTTP SERVER
    self.httpServerViewController = [[HttpServerViewController alloc] init];  //http 서버 컨트롤러
    [httpServerViewController release];
    [self.view addSubview:httpServerViewController.view];
    httpServerViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    
//    // Create a view of the standard size at the top of the screen.
//    // Available AdSize constants are explained in GADAdSize.h.
//    GADBannerView *bannerView_ = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
//    
//    // Specify the ad's "unit identifier". This is your AdMob Publisher ID.
//    bannerView_.adUnitID = @"a151af3dfc0be11";
//    
//    // Let the runtime know which UIViewController to restore after taking
//    // the user wherever the ad goes and add it to the view hierarchy.
//    bannerView_.rootViewController = self;
//    [self.view addSubview:bannerView_];
//    
//    // Initiate a generic request to load it with an ad.
//    [bannerView_ loadRequest:[self createRequest]];
//    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bookDidLoaded:) name:@"bookDidLoaded" object:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

-(void)handleSingleFingerEvent{
    if(self.toolbar.frame.origin.y == self.view.frame.size.height){
        [self showToolbar];
    }else{
        [self hideToolbar];
    }
}

-(void)showToolbar{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.5];
    self.toolbar.frame = CGRectMake(0, self.view.frame.size.height-44, self.view.frame.size.width, 44);
    self.headerbar.frame = CGRectMake(0, 0, self.view.frame.size.width, 44);
    [UIView commitAnimations];
     //self.pageSlider.hidden = YES; //슬라이드바 숨기기
     self.pageSlider.hidden = NO;
}

-(void)hideToolbar{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.5];
    self.toolbar.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 44);
    self.headerbar.frame = CGRectMake(0, -44, self.view.frame.size.width, 44);
    [UIView commitAnimations];
   // self.pageSlider = nil;
      
}

- (GADRequest *)createRequest {
   // GADRequest *request = [GADRequest request];
    
    // Make the request for a test ad. Put in an identifier for the simulator as
    // well as any devices you want to receive test ads.
   // request.testDevices =
   // [NSArray arrayWithObjects:@"b335f74b5f5d26982168ab68b06b6053316157a7",nil];
   // return request;
}

-(void)bookDidLoaded:(NSNotification *)notification{
    [hud hide:YES];
}

- (void)viewDidUnload {
	self.toolbar = nil;
	self.webView = nil;
	self.chapterListButton = nil;
	//self.decTextSizeButton = nil;
	self.incTextSizeButton = nil;
	self.pageSlider = nil;
	self.currentPageLabel = nil;
    self.searchlibraryButton=nil;  //도서관 찾기 버튼 추가
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    self.toolbar = nil;
	self.webView = nil;
	self.chapterListButton = nil;
	//self.decTextSizeButton = nil;
	self.incTextSizeButton = nil;
    self.searchlibraryButton=nil; //도서관 찾기 버튼 추가
	self.pageSlider = nil;
	self.currentPageLabel = nil;
	[bookLoader release];
    [super dealloc];
}

@end
