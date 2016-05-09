//
//  BookLoader.m
//  epub
//
//  Created by zhiyu zheng on 12-6-6.
//  Copyright (c) 2012年 Baidu. All rights reserved.
//
//게시판하고 비슷하면서도 약간 다름.
//인터넷 게시판 db 백업된걸 열어본다고 할까..그런거랑 비슷함..
//다른점은 프린터로 출력하기 쉽게 되어 있음.(포털은 귀찮은 변환과정을 거쳐야 프린트 가능)
//대신 포털의 이메일이나 다른기능들은 없음.
//메모기능이나 에버노트랑 연동이나 구글의 검색기능이 없음(아이북스에는 있음)
//갈무리 기능이나 이런게 없음
//인앱 구입기능은 구글 서재나 아이튠즈 같은게 있어야 되는데
//없는게 문제.
//국내 전자책 서점과 연결하면 될듯한데 폐쇄적인 전자책 서점의 문제도 있음.
//사실상 db 판매랑 똑같음

//파일 패스를 보는건데 아이폰은 패스가 딱히 없음.

#import "BookLoader.h"

@interface BookLoader()

- (void) parse;

@end

@implementation BookLoader

@synthesize spineArray,filePath,error; //spineArray는 뭔가?

- (id) initWithPath:(NSString*)path{
    if((self=[super init])){
        error = 0;
		self.filePath = path;
		self.spineArray = [[NSMutableArray alloc] init];
        [self.spineArray release];
		[self parse];
	}
	return self;
}

- (void) parse{

}
@end
