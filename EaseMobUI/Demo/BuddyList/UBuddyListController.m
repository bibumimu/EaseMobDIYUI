//
//  UBuddyListController.m
//  EaseMobUI
//
//  Created by 周玉震 on 15/8/25.
//  Copyright (c) 2015年 周玉震. All rights reserved.
//

#import "UBuddyListController.h"
#import "UChatController.h"

#import "EM+ChatOppositeTag.h"
#import "EM+ChatBuddy.h"

#import "EM+ChatResourcesUtils.h"

#import <EaseMobSDKFull/EaseMob.h>

#define GroupName           (@"groupName")
#define GroupExpand         (@"groupExpand")
#define GroupBuddys         (@"groupBuddys")

@interface UBuddyListController ()<EM_ChatBuddyListControllerDataSource,EM_ChatBuddyListControllerDelegate,EMChatManagerDelegate>

@property (nonatomic, assign) BOOL needReload;

@end

@implementation UBuddyListController{
    NSArray *tags;
    NSArray *icons;
    NSMutableArray *buddyArray;
    NSMutableArray *searchArray;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.tabBarItem.image = [UIImage imageNamed:@"buddy"];
        
        
        tags = @[@"新朋友",@"群组",@"讨论组",@"黑名单"];
        icons = @[kEMChatIconBuddyNew,kEMChatIconBuddyGroup,kEMChatIconBuddyRoom,kEMChatIconBuddyBlacklist];
        
        buddyArray = [[NSMutableArray alloc]init];
        for (int i = 0; i < 2; i++) {
            [buddyArray addObject:[[NSMutableDictionary alloc]initWithDictionary:@{
                                                                                   GroupName : [NSString stringWithFormat:@"我的好友%d",i+1],
                                                                                   GroupExpand : @(NO),
                                                                                   GroupBuddys : [[NSMutableArray alloc]init]
                                                                                   }]];
        }
        
        searchArray = [[NSMutableArray alloc]init];
        self.dataSource = self;
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
    [[EaseMob sharedInstance].chatManager asyncFetchBuddyList];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.needReload) {
        [self reloadOppositeList];
        self.needReload = NO;
    }
}

#pragma mark - EM_ChatBuddyListControllerDataSource
- (BOOL)shouldShowSearchBar{
    return YES;
}

- (BOOL)shouldShowTagBar{
    return YES;
}

//search
- (NSInteger)numberOfRowsForSearch{
    return searchArray.count;
}

- (EM_ChatOpposite *)dataForSearchRowAtIndex:(NSInteger)index{
    return searchArray[index];
}


//tags
- (NSInteger)numberOfTags{
    return tags.count;
}

- (UIFont *)fontForTagAtIndex:(NSInteger)index{
    return [EM_ChatResourcesUtils iconFontWithSize:30];
}

- (NSString *)titleForTagAtIndex:(NSInteger)index{
    return tags[index];
}

- (NSString *)iconForTagAtIndex:(NSInteger)index{
    return icons[index];
}

//group
- (NSInteger)numberOfGroups{
    return buddyArray.count;
}

- (BOOL)shouldExpandForGroupAtIndex:(NSInteger)index{
    NSDictionary *info = buddyArray[index];
    return [info[GroupExpand] boolValue];
}

- (NSString *)titleForGroupAtIndex:(NSInteger)index{
    NSDictionary *info = buddyArray[index];
    return info[GroupName];
}

//opposite
- (NSInteger)numberOfRowsAtGroupIndex:(NSInteger)groupIndex{
    NSDictionary *info = buddyArray[groupIndex];
    return [info[GroupBuddys] count];
}

- (EM_ChatOpposite *)dataForRow:(NSInteger)rowIndex groupIndex:(NSInteger)groupIndex{
    NSMutableDictionary *info = buddyArray[groupIndex];
    NSArray *buddys = info[GroupBuddys];
    return buddys[rowIndex];
}

#pragma mark - EM_ChatBuddyListControllerDelegate
//search
- (BOOL)shouldReloadSearchForSearchString:(NSString *)searchString{
    if (searchString) {
        [searchArray removeAllObjects];
        
        for (int i = 0; i < buddyArray.count; i++) {
            NSDictionary *info = buddyArray[i];
            NSArray *buddys = info[GroupBuddys];
            for (EM_ChatBuddy *buddy in buddys) {
                if ([buddy.displayName containsString:searchString]) {
                    [searchArray addObject:buddy];
                    continue;
                }
                if ([buddy.remarkName containsString:searchString]){
                    [searchArray addObject:buddy];
                    continue;
                }
                if ([buddy.uid containsString:searchString]){
                    [searchArray addObject:buddy];
                    continue;
                }
            }
        }
    }
    return YES;
}

- (void)didSelectedForSearchRowAtIndex:(NSInteger)index{
    EM_ChatBuddy *buddy = searchArray[index];
    UChatController *chatController = [[UChatController alloc]initWithOpposite:buddy];
    [self.navigationController pushViewController:chatController animated:YES];
}

//group
- (void)didSelectedForGroupManageAtIndex:(NSInteger)groupIndex{
    NSLog(@"分组管理%ld",groupIndex);
}

- (void)didSelectedForGroupAtIndex:(NSInteger)groupIndex{
    NSDictionary *info = buddyArray[groupIndex];
    BOOL expand = [info[GroupExpand] boolValue];
    [info setValue:@(!expand) forKey:GroupExpand];
    [self reloadOppositeList];
}

//opposite
- (void)didSelectedForRowAtIndex:(NSInteger)rowIndex groupIndex:(NSInteger)groupIndex{
    NSMutableDictionary *info = buddyArray[groupIndex];
    NSArray *buddys = info[GroupBuddys];
    EM_ChatBuddy *buddy = buddys[rowIndex];
    UChatController *chatController = [[UChatController alloc]initWithOpposite:buddy];
    [self.navigationController pushViewController:chatController animated:YES];
}

#pragma mark - EMChatManagerBuddyDelegate
- (void)didFetchedBuddyList:(NSArray *)buddyList error:(EMError *)error{
    for (int i = 0;i < buddyList.count;i++) {
        EMBuddy *emBuddy = buddyList[i];
        EM_ChatBuddy *buddy = [[EM_ChatBuddy alloc]init];
        buddy.uid = emBuddy.username;
        buddy.nickName = emBuddy.username;
        buddy.remarkName = emBuddy.username;
        buddy.displayName = buddy.remarkName;

        NSDictionary *info = buddyArray[i % 2];
        NSMutableArray *buddys = info[GroupBuddys];
        
        if (![buddys containsObject:buddy]) {
            [buddys addObject:buddy];
        }
    }
    
    if (self.isShow) {
        [self reloadOppositeList];
    }else{
        self.needReload = YES;
    }
}

- (void)didUpdateBuddyList:(NSArray *)buddyList changedBuddies:(NSArray *)changedBuddies isAdd:(BOOL)isAdd{
    
}

- (void)didRemovedByBuddy:(NSString *)username{
    
}

@end