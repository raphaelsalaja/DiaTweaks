// Group Tabs by Domain and Group Selected Tabs by Domain are one-shot commands in the tab context menu and the Tabs menu, shown while the
// patch is on. The hooks only remember live browsers and web contents so a command can read each tab's session ID; nothing is grouped until
// it's chosen. Selected tabs use the same domain rules on that selection. None, or only one, does nothing.
#import "StdPatch/StdPatch.h"

void DPInstallGroupTabs(void);

// Tracking.m: what the hooks remembered.
id DPCommandBrowser(void);  // The front window's browser, or the only one.
NSWindow *DPBrowserWindow(id browser);
id DPGroupingDelegate(id browser);
NSArray *DPTrackedContents(id browser);
long long DPSessionOf(id contents);

// Messages.m
long long DPLongID(id value);
id DPMsg(id object, SEL sel);
BOOL DPMsgBool(id object, SEL sel);
NSString *DPText(id value);

// Plan.m: which groups to create and which tabs to add to existing ones.
NSString *DPDomainKey(NSString *urlString);
NSArray<NSDictionary *> *DPOps(NSArray<NSDictionary *> *tabs, NSArray *groups);

// Order.m: where tabs sit, so undo can put them back.
NSDictionary *DPTabPlaces(NSDictionary<NSNumber *, NSString *> *urls);
void DPRestorePlaces(id delegate, id browser, NSDictionary *places);

void DPGroupTabsOnce(void);           // Grouping.m. Every loose tab in the front window.
void DPGroupSelectedTabsOnce(void);   // Grouping.m. Only the front window's selected tabs.
NSSet<NSNumber *> *DPSelectedSessions(id browser);  // Selection.m. Nil when fewer than two selected tabs can be grouped.
// Grouping.m, also used by Tidy Tabs. An op is {op: create, title, ids} or {op: add, group, ids}; a create without a
// title leaves the group for Dia's AI to name. Undo is Command-Z
// right after, and ungroups `ids` and puts them back at `places`.
void DPRunOps(id delegate, id browser, NSArray<NSDictionary *> *ops, NSUInteger index, void (^done)(void));
void DPOfferUndo(id delegate, id browser, NSArray *ids, NSDictionary *places);
void DPInstallGroupMenus(void);  // Menu.m
