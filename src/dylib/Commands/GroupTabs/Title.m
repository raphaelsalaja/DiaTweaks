// Names for groups Group Tabs by Domain creates. The host stays the grouping key; this is only the title.
#import "GroupTabs.h"

// Spellings a capitalised first label gets wrong. Hosts that aren't listed, and aren't "name.tld", keep the host.
static NSString *DPBrand(NSString *host) {
    static NSDictionary<NSString *, NSString *> *brands;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        brands = @{
            @"askubuntu.com": @"Ask Ubuntu",
            @"bbc.co.uk": @"BBC",
            @"bbc.com": @"BBC",
            @"calendar.google.com": @"Google Calendar",
            @"chatgpt.com": @"ChatGPT",
            @"cnn.com": @"CNN",
            @"docs.google.com": @"Google Docs",
            @"drive.google.com": @"Google Drive",
            @"ebay.com": @"eBay",
            @"en.wikipedia.org": @"Wikipedia",
            @"github.com": @"GitHub",
            @"gitlab.com": @"GitLab",
            @"googlemail.com": @"Gmail",
            @"ibm.com": @"IBM",
            @"icloud.com": @"iCloud",
            @"imdb.com": @"IMDb",
            @"linkedin.com": @"LinkedIn",
            @"mail.google.com": @"Gmail",
            @"maps.google.com": @"Google Maps",
            @"meet.google.com": @"Google Meet",
            @"mit.edu": @"MIT",
            @"music.youtube.com": @"YouTube Music",
            @"nasa.gov": @"NASA",
            @"nba.com": @"NBA",
            @"news.ycombinator.com": @"Hacker News",
            @"nfl.com": @"NFL",
            @"npmjs.com": @"npm",
            @"npr.org": @"NPR",
            @"nytimes.com": @"New York Times",
            @"openai.com": @"OpenAI",
            @"outlook.live.com": @"Outlook",
            @"outlook.office.com": @"Outlook",
            @"paypal.com": @"PayPal",
            @"pbs.org": @"PBS",
            @"photos.google.com": @"Google Photos",
            @"playstation.com": @"PlayStation",
            @"producthunt.com": @"Product Hunt",
            @"serverfault.com": @"Server Fault",
            @"sheets.google.com": @"Google Sheets",
            @"slides.google.com": @"Google Slides",
            @"soundcloud.com": @"SoundCloud",
            @"sourceforge.net": @"SourceForge",
            @"stackexchange.com": @"Stack Exchange",
            @"stackoverflow.com": @"Stack Overflow",
            @"superuser.com": @"Super User",
            @"teams.microsoft.com": @"Teams",
            @"tiktok.com": @"TikTok",
            @"washingtonpost.com": @"Washington Post",
            @"wordpress.com": @"WordPress",
            @"wordpress.org": @"WordPress",
            @"youtu.be": @"YouTube",
            @"youtube.com": @"YouTube",
        };
    });
    return brands[host];
}

// "reddit.com" → "Reddit". Longer hosts stay put, so docs.github.com is not folded into GitHub.
static NSString *DPCapitalizedLabel(NSString *host) {
    NSArray<NSString *> *labels = [host componentsSeparatedByString:@"."];
    if (labels.count != 2 || ![labels[0] length]) return host;
    static NSLocale *locale;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]; });
    NSString *name = [labels[0] capitalizedStringWithLocale:locale];
    return name.length ? name : host;
}

static NSString *DPFriendlyTitle(NSString *host) {
    if (!host.length) return host ?: @"";
    return DPBrand(host) ?: DPCapitalizedLabel(host);
}

// One brand per group. Two hosts that would share a name (youtube.com and youtu.be, both YouTube) keep their hosts
// while both are in the window, and so does a name that is some other host.
NSDictionary<NSString *, NSString *> *DPGroupTitles(NSArray<NSString *> *domains) {
    NSMutableDictionary<NSString *, NSString *> *titles = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSNumber *> *uses = [NSMutableDictionary dictionary];
    for (NSString *domain in domains) {
        if (![domain isKindOfClass:NSString.class] || !domain.length || titles[domain]) continue;
        NSString *title = DPFriendlyTitle(domain);
        titles[domain] = title.length ? title : domain;
        uses[titles[domain]] = @(uses[titles[domain]].integerValue + 1);
    }
    NSSet<NSString *> *hosts = [NSSet setWithArray:titles.allKeys];
    for (NSString *domain in titles.allKeys) {
        NSString *title = titles[domain];
        BOOL shared = uses[title].integerValue > 1;
        BOOL usedHost = [hosts containsObject:title] && ![title isEqualToString:domain];
        if (shared || usedHost) titles[domain] = domain;
    }
    return titles;
}
