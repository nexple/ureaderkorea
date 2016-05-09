#import "ChaptersListViewController.h"
#import <QuartzCore/QuartzCore.h>

//글들만 보이는데 썸내일 사진 필요

@implementation ChaptersListViewController

@synthesize bookViewController,selectedIndexPath;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

-(void)loadChapters{
    [self.tableView reloadData];
}

- (void)viewDidLayoutSubviews{
    if(self.selectedIndexPath!=nil)
        [self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];  //색상변경
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;  //테이블 뷰 스타일
}

- (void)viewDidUnload{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [bookViewController.bookLoader.spineArray count];  //북뷰 컨트롤러
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.contentView.backgroundColor = [UIColor colorWithPatternImage:[ResourceHelper loadImageByTheme:@"item_bg"]];
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.textColor = [UIColor colorWithRed:102/255.f green:102/255.f blue:102/255.f alpha:1];
        cell.textLabel.highlightedTextColor=[UIColor colorWithRed:255/255.f green:255/255.f blue:255/255.f alpha:1];
        
//        [cell.textLabel setShadowColor:[UIColor whiteColor]];
//        [cell.textLabel setShadowOffset:CGSizeMake(0, 1)];
//        
        UIView *backView = [[UIView alloc] initWithFrame:cell.frame];
        cell.selectedBackgroundView = backView;
        cell.selectedBackgroundView.backgroundColor = [UIColor colorWithPatternImage:[ResourceHelper loadImageByTheme:@"item_bg_selected"]];
        [backView release];
    }
    
    cell.textLabel.text = [[bookViewController.bookLoader.spineArray objectAtIndex:[indexPath row]] title];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section //헤더 
{
    UIView* myView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 44)] autorelease];
    [myView setClipsToBounds:NO];
    myView.backgroundColor = [UIColor colorWithPatternImage:[ResourceHelper loadImageByTheme:@"head_bg"]];
    
//    [myView.layer setShadowColor:[UIColor blackColor].CGColor];
//    [myView.layer setShadowOpacity:1];
//    [myView.layer setShadowRadius:2];
//    [myView.layer setShadowOffset:CGSizeMake(0, 0)];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, tableView.frame.size.width, 44)];
    //CGRectMake(10, 10으로 내림(y 값임), tableView.frame.size.width, 44) 위에 와피파이 아이콘하고 겹쳐서 내림.
    titleLabel.textColor=[UIColor blackColor];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = NSLocalizedString(@"챕터들 ",nil);
    [myView addSubview:titleLabel];
    [titleLabel release];
    return myView;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  //선택되면
{
    self.selectedIndexPath = indexPath; //항목 선택되면 
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showChapters" object:indexPath];  //에니메이션 실행뒤에 다른 뷰에서 실행됨
}

@end
