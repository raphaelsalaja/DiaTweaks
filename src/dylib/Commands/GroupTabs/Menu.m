#import "GroupTabs.h"

static const NSInteger DPGroupMenuTag = 0xD1A7001;
static const NSInteger DPGroupSelectedMenuTag = 0xD1A7002;
static NSString *const DPGroupMenuTitle = @"Group Tabs by Domain";
static NSString *const DPGroupSelectedMenuTitle = @"Group Selected Tabs by Domain";
static BOOL DPInserting;

static BOOL DPIsNewGroupTitle(NSString *title) {
    if ([title isEqualToString:@"New Group with Tab"] || [title isEqualToString:@"New Group with Tabs"]) return YES;
    return [title hasPrefix:@"New Group with "] && ([title hasSuffix:@" Tab"] || [title hasSuffix:@" Tabs"]);
}

extern DPPatch DPGroupTabs;

static BOOL DPIsGroupTag(NSInteger tag) { return tag == DPGroupMenuTag || tag == DPGroupSelectedMenuTag; }

static NSMenuItem *DPGroupMenuItem(NSString *title, NSInteger tag, void (^action)(void)) {
    NSMenuItem *item = DPMenuItem(title, action);
    item.tag = tag;
    item.image = [NSImage imageWithSystemSymbolName:@"rectangle.3.group" accessibilityDescription:nil];
    item.hidden = !DPGroupTabs.on;
    return item;
}

static NSMenuItem *DPFullItem(void) { return DPGroupMenuItem(DPGroupMenuTitle, DPGroupMenuTag, ^{ DPGroupTabsOnce(); }); }

static NSMenuItem *DPSelectedItem(void) {
    return DPGroupMenuItem(DPGroupSelectedMenuTitle, DPGroupSelectedMenuTag, ^{ DPGroupSelectedTabsOnce(); });
}

static void DPPlaceGroupItem(NSMenu *menu) {
    if (DPInserting || !menu) return;
    NSInteger anchor = NSNotFound, visible = NSNotFound;
    for (NSInteger i = 0; i < menu.numberOfItems; i++) {
        NSMenuItem *item = [menu itemAtIndex:i];
        if (!DPIsNewGroupTitle(item.title)) continue;
        if (!item.hidden && visible == NSNotFound) visible = i;
        if (anchor == NSNotFound) anchor = i;
    }
    if (visible != NSNotFound) anchor = visible;
    if (anchor == NSNotFound) return;
    NSInteger end = menu.numberOfItems;
    for (NSInteger i = anchor + 1; i < menu.numberOfItems; i++)
        if ([menu itemAtIndex:i].isSeparatorItem) { end = i; break; }
    if (end >= 2 && [menu itemAtIndex:end - 2].tag == DPGroupMenuTag && [menu itemAtIndex:end - 1].tag == DPGroupSelectedMenuTag) return;
    DPInserting = YES;
    NSMenuItem *full = nil, *selected = nil;
    for (NSInteger i = menu.numberOfItems - 1; i >= 0; i--) {
        NSMenuItem *item = [menu itemAtIndex:i];
        if (!DPIsGroupTag(item.tag)) continue;
        if (item.tag == DPGroupMenuTag && !full) full = item;
        if (item.tag == DPGroupSelectedMenuTag && !selected) selected = item;
        [menu removeItemAtIndex:i];
        if (i < end) end--;
    }
    [menu insertItem:full ?: DPFullItem() atIndex:MIN(end, menu.numberOfItems)];
    [menu insertItem:selected ?: DPSelectedItem() atIndex:MIN(end + 1, menu.numberOfItems)];
    DPInserting = NO;
}

static void DPInstallMenuBarItem(void) {
    NSMenu *tabMenu = nil, *commandMenu = nil, *windowMenu = nil, *fileMenu = nil;
    for (NSMenuItem *top in NSApp.mainMenu.itemArray) {
        NSString *title = top.title ?: @"";
        if ([title isEqualToString:@"Tab"] || [title isEqualToString:@"Tabs"]) tabMenu = top.submenu;
        if ([title isEqualToString:@"Window"]) windowMenu = top.submenu;
        if ([title isEqualToString:@"File"]) fileMenu = top.submenu;
        for (NSMenuItem *item in top.submenu.itemArray)
            if (DPIsNewGroupTitle(item.title) || [item.title isEqualToString:@"New Tab"] || [item.title isEqualToString:@"Close Tab"]
                || [item.title isEqualToString:@"Select Next Tab"] || [item.title isEqualToString:@"Reopen Closed Tab"])
                commandMenu = top.submenu;
    }
    NSMenu *menu = tabMenu ?: commandMenu ?: windowMenu ?: fileMenu;
    if (!menu || ([menu itemWithTag:DPGroupMenuTag] && [menu itemWithTag:DPGroupSelectedMenuTag])) return;
    for (NSMenuItem *item in menu.itemArray)
        if (DPIsNewGroupTitle(item.title)) return DPPlaceGroupItem(menu);
    NSInteger index = menu.numberOfItems;
    for (NSInteger i = 0; i < menu.numberOfItems; i++) {
        NSString *title = [menu itemAtIndex:i].title;
        if (DPIsNewGroupTitle(title) || [title isEqualToString:@"New Tab"]) index = i + 1;
    }
    DPInserting = YES;
    for (NSInteger i = menu.numberOfItems - 1; i >= 0; i--)
        if (DPIsGroupTag([menu itemAtIndex:i].tag)) {
            [menu removeItemAtIndex:i];
            if (i < index) index--;
        }
    [menu insertItem:DPFullItem() atIndex:MIN(index, menu.numberOfItems)];
    [menu insertItem:DPSelectedItem() atIndex:MIN(index + 1, menu.numberOfItems)];
    DPInserting = NO;
}

static void DPMenu_addItem(NSMenu *self, SEL _cmd, NSMenuItem *item) {
    DPCallOriginal(DPMenu_addItem, self, item);
    if (!DPInserting && (DPIsNewGroupTitle(item.title) || DPIsGroupTag(item.tag) || [self itemWithTag:DPGroupMenuTag])) DPPlaceGroupItem(self);
}

static void DPMenu_insertItem(NSMenu *self, SEL _cmd, NSMenuItem *item, NSInteger index) {
    DPCallOriginal(DPMenu_insertItem, self, item, index);
    if (!DPInserting && (DPIsNewGroupTitle(item.title) || DPIsGroupTag(item.tag) || [self itemWithTag:DPGroupMenuTag])) DPPlaceGroupItem(self);
}

void DPInstallGroupMenus(void) {
    DPHookClass(NSMenu.class, @selector(addItem:), (IMP)DPMenu_addItem);
    DPHookClass(NSMenu.class, @selector(insertItem:atIndex:), (IMP)DPMenu_insertItem);
    DPOnLaunch(^{ DPInstallMenuBarItem(); });
}

// Tab context menus are built each time they open, so only the Tabs menu keeps an item to hide.
static void DPApplyGroupTabs(DPPatch *patch) {
    for (NSMenuItem *top in NSApp.mainMenu.itemArray) {
        [top.submenu itemWithTag:DPGroupMenuTag].hidden = !patch->on;
        [top.submenu itemWithTag:DPGroupSelectedMenuTag].hidden = !patch->on;
    }
}

DP_PATCH(DPGroupTabs) {
    .key = @"groupTabsByDomain",
    .order = 86,
    .defaultOn = YES,
    .title = @"Group Tabs by Domain",
    .detail = @"Adds Group Tabs by Domain and Group Selected Tabs by Domain to the tab right-click menu and the Tabs menu. One groups the window’s tabs by site, the other only the tabs you have selected.",
    .symbol = @"rectangle.3.group.fill",
    .tint = @"systemPinkColor",
    .section = @"Tabs",
    .install = DPInstallGroupTabs,
    .apply = DPApplyGroupTabs,
};
