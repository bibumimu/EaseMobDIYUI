//
//  EM+BuddyListController.m
//  EaseMobUI 好友列表
//
//  Created by 周玉震 on 15/8/21.
//  Copyright (c) 2015年 周玉震. All rights reserved.
//

#import "EM+BuddyListController.h"
#import "EM+ChatController.h"

#import "EM+ChatOppositeTagBar.h"
#import "EM+ChatOppositeTag.h"
#import "EM+ChatTableView.h"
#import "EM+ChatOppositeHeader.h"
#import "EM+ChatOppositeCell.h"

#import "EaseMobUIClient.h"
#import "EM+Common.h"
#import "EM+ChatResourcesUtils.h"

#import <MJRefresh/MJRefresh.h>

@interface EM_BuddyListController ()
<UITableViewDataSource,
UITableViewDelegate,
UISearchDisplayDelegate,
EM_ChatTableViewTapDelegate,
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout>

@end

@implementation EM_BuddyListController{
    UISearchDisplayController *_searchController;
    
    EM_ChatTableView *_tableView;
    EM_ChatOppositeTagBar *_tableHeader;
    
    NSMutableDictionary *_expandSign;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.title = [EM_ChatResourcesUtils stringWithName:@"common.contact"];
        _expandSign = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableView = [[EM_ChatTableView alloc]initWithFrame:self.view.frame];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 60;
    _tableView.contentInset = UIEdgeInsetsMake(self.offestY > 0 ? self.offestY : 0, 0, 0, 0);
    _tableView.tapDelegate = self;
    
    MJRefreshGifHeader *header = [MJRefreshGifHeader headerWithRefreshingTarget:self refreshingAction:@selector(didBeginRefresh)];
    _tableView.header = header;
    
    [self.view addSubview:_tableView];
    
    _tableHeader = [[EM_ChatOppositeTagBar alloc]init];
    [self reloadTagBar];
    _tableView.tableHeaderView = _tableHeader;
    
    _searchController = [[UISearchDisplayController alloc]initWithSearchBar:_tableHeader.searchBar contentsController:self];
    _searchController.delegate = self;
    _searchController.searchResultsDataSource = self;
    _searchController.searchResultsDelegate = self;
    _searchController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_searchController setActive:NO];
}

- (void)reloadTagBar{
    CGFloat height =0;
    BOOL showSearchBar = NO;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(shouldShowSearchBar)]) {
        showSearchBar = [self.dataSource shouldShowSearchBar];
    }
    
    if (showSearchBar) {
        height += HEIGH_FOR_SEARCH_BAR;
    }
    
    BOOL showTagBar = NO;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(shouldShowTagBar)]) {
        showTagBar = [self.dataSource shouldShowTagBar];
    }
    
    if (showTagBar) {
        height += self.view.frame.size.width / 4;
        _tableHeader.collectionView.dataSource = self;
        _tableHeader.collectionView.delegate = self;
    }else{
        _tableHeader.collectionView.dataSource = nil;
        _tableHeader.collectionView.delegate = nil;
    }
    
    _tableHeader.searchBar.hidden = !showSearchBar;
    _tableHeader.collectionView.hidden = !showTagBar;
    _tableHeader.frame = CGRectMake(0, 0, self.view.frame.size.width, height);
    [_tableHeader.collectionView reloadData];
    [_tableView reloadData];
}

- (void)reloadOppositeList{
    [_tableView reloadData];
}

- (void)startRefresh{
    [_tableView.header beginRefreshing];
}

- (void)endRefresh{
    [_tableView.header endRefreshing];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didEndRefresh)]) {
        [self.delegate didEndRefresh];
    }
}

- (void)didBeginRefresh{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStartRefresh)]) {
        [self.delegate didStartRefresh];
    }else{
        //刷新数据
        [self endRefresh];
        [self reloadOppositeList];
    }
}

#pragma mark - UISearchDisplayDelegate
- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller{
    [controller.searchBar removeFromSuperview];
    controller.searchBar.frame = CGRectMake(0, 0, _tableHeader.frame.size.width, IS_PAD ? 60 : 44);
    [_tableHeader addSubview:controller.searchBar];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    BOOL reload = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(shouldReloadSearchForSearchString:)]) {
        reload = [self.delegate shouldReloadSearchForSearchString:searchString];
    }
    return reload;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger count = 0;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfTags)]) {
        count = [self.dataSource numberOfTags];
    }
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    EM_ChatOppositeTag *cell = [collectionView dequeueReusableCellWithReuseIdentifier:TAG_IDENTIFIER forIndexPath:indexPath];
    
    NSString *title = nil;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(titleForTagAtIndex:)]) {
        title = [self.dataSource titleForTagAtIndex:indexPath.row];
    }
    
    cell.title = title;
    
    UIFont *font = nil;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(fontForTagAtIndex:)]) {
        font = [self.dataSource fontForTagAtIndex:indexPath.row];
    }
    
    NSString *icon = nil;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(iconForTagAtIndex:)]) {
        icon = [self.dataSource iconForTagAtIndex:indexPath.row];
    }
    
    if (font && icon) {
        cell.font = font;
        cell.icon = icon;
    }
    
    NSString *badge = nil;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(badgeForTagAtIndex:)]) {
        badge = [self.dataSource badgeForTagAtIndex:indexPath.row];
    }
    cell.badge = badge;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BOOL shouldSelected = NO;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(shouldSelectedForTagAtIndex:)]) {
        shouldSelected = [self.dataSource shouldSelectedForTagAtIndex:indexPath.row];
    }
    
    if (shouldSelected) {
        for (int i = 0; i < [collectionView numberOfItemsInSection:indexPath.section]; i++) {
            NSIndexPath *index = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
            EM_ChatOppositeTag *cell = (EM_ChatOppositeTag *)[collectionView cellForItemAtIndexPath:index];
            cell.tagSelected = index.row == indexPath.row;
        }
    }

    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedForTagAtIndex:)]) {
        [self.delegate didSelectedForTagAtIndex:indexPath.row];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger count = 0;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfTags)]) {
        count = [self.dataSource numberOfTags];
    }
    
    CGSize size = CGSizeZero;
    if (count <= 0) {
        size =  CGSizeZero;
    }else if(count > 0 && count < 4){
        size = CGSizeMake(self.view.frame.size.width / count, collectionView.frame.size.height);
    }else{
        size = CGSizeMake(self.view.frame.size.width / 4, collectionView.frame.size.height);
    }
    return size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

#pragma mark - EM_ChatTableViewTapDelegate
- (void)chatTableView:(EM_ChatTableView *)table didTapEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (_tableHeader.searchBar.isFirstResponder) {[_tableHeader.searchBar resignFirstResponder];}
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (tableView == _tableView) {
        NSInteger groupCount = 1;
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfGroups)]) {
            groupCount = [self.dataSource numberOfGroups];
            if (groupCount < 1) {
                groupCount = 1;
            }
        }
        return  groupCount;
    }else if(tableView == _searchController.searchResultsTableView){
        return 1;
    }else{
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == _tableView) {
        
        NSInteger rowCount = 0;
        BOOL expand = YES;
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(shouldExpandForGroupAtIndex:)]) {
            expand = [self.dataSource shouldExpandForGroupAtIndex:section];
        }
        if (expand) {
            if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfRowsAtGroupIndex:)]) {
                rowCount = [self.dataSource numberOfRowsAtGroupIndex:section];
            }
        }
        return rowCount;
    }else if(tableView == _searchController.searchResultsTableView){
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfRowsForSearch)]) {
            return [self.dataSource numberOfRowsForSearch];
        }
        return 0;
    }else{
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *oppositeIdentifier = @"oppositeIdentifier";
    EM_ChatOppositeCell *cell = [tableView dequeueReusableCellWithIdentifier:oppositeIdentifier];
    if (!cell) {
        cell = [[EM_ChatOppositeCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:oppositeIdentifier];
    }
    cell.indexPath = indexPath;
    cell.hiddenTopLine = indexPath.row == 0;
    cell.hiddenBottomLine = YES;
    EM_ChatOpposite *opposite = nil;
    if (tableView == _tableView) {
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(dataForRow:groupIndex:)]) {
            opposite = [self.dataSource dataForRow:indexPath.row groupIndex:indexPath.section];
        }
    }else if(tableView == _searchController.searchResultsTableView){
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(dataForSearchRowAtIndex:)]) {
            opposite = [self.dataSource dataForSearchRowAtIndex:indexPath.row];
        }
    }
    if (opposite) {
        cell.name = opposite.displayName;
        cell.details = opposite.intro;
        cell.avatarImage = [EM_ChatResourcesUtils defaultAvatarImage];
        if (opposite.avatar) {
            cell.avatarURL = opposite.avatar;
        }
    }
    return cell;
    
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if ([tableView numberOfSections] > 1 && tableView == _tableView) {
        return 40;
    }
    return 0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    NSInteger groupCount = [tableView numberOfSections];
    if (groupCount > 1) {
        if (tableView == _tableView) {
            static NSString *headerIdentifier = @"headerIdentifier";
            EM_ChatOppositeHeader *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerIdentifier];
            if (!header) {
                header = [[EM_ChatOppositeHeader alloc]initWithReuseIdentifier:headerIdentifier];
                
                BOOL expand = YES;
                if (self.dataSource && [self.dataSource respondsToSelector:@selector(shouldExpandForGroupAtIndex:)]) {
                    expand = [self.dataSource shouldExpandForGroupAtIndex:section];
                }
                
                header.arrow = KEMChatIconMorePlay;
                if (expand) {
                    header.angle = 90 * M_PI / 180.0;
                }else{
                    header.angle = 0;
                }
                
                NSInteger rowCount = 0;
                if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfRowsAtGroupIndex:)]) {
                    rowCount = [self.dataSource numberOfRowsAtGroupIndex:section];
                }
                header.buddyCount = rowCount;
                
                [header setChatOppositeHeaderClickedBlock:^(NSInteger s) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedForGroupAtIndex:)]) {
                        [self.delegate didSelectedForGroupAtIndex:s];
                    }
                }];
                
                [header setChatOppositeHeaderManageBlock:^(NSInteger section) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedForGroupManageAtIndex:)]) {
                        [self.delegate didSelectedForGroupManageAtIndex:section];
                    }
                }];
                
                if (self.dataSource && [self.dataSource respondsToSelector:@selector(shouldShowGroupManage)]) {
                    header.needManage = [self.dataSource shouldShowGroupManage];
                }
            }
            NSString *title;
            if (self.dataSource && [self.dataSource respondsToSelector:@selector(titleForGroupAtIndex:)]) {
                title = [self.dataSource titleForGroupAtIndex:section];
            }else{
                title = [NSString stringWithFormat:@"%@%ld",[EM_ChatResourcesUtils stringWithName:@"common.group_name"],section + 1];
            }
            header.title = title;
            header.section = section;
            return header;
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == _tableView) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedForRowAtIndex:groupIndex:)]) {
            [self.delegate didSelectedForRowAtIndex:indexPath.row groupIndex:indexPath.section];
        }
    }else if(tableView == _searchController.searchResultsTableView){
        if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectedForSearchRowAtIndex:)]) {
            [self.delegate didSelectedForSearchRowAtIndex:indexPath.row];
        }
    }
}

@end