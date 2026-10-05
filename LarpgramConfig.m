#import "LarpgramConfig.h"

@implementation LarpgramConfig

+ (instancetype)shared {
    static LarpgramConfig *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        [sharedInstance load];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isEnabled = YES;
        _spoofPhone = YES;
        _fakePhone = @"+888 0777 9999";
        _spoofUsernames = YES;
        _fakeUsernames = @[@"owner", @"rich", @"ceo"];
        _spoofGifts = YES;
        _fakeGifts = [NSMutableArray arrayWithArray:@[
            @{
                @"id": @(1001),
                @"title": @"Plush Pepe",
                @"number": @(1),
                @"model": @"pepe",
                @"isNFT": @(YES),
                @"sender": @"Anonymous"
            },
            @{
                @"id": @(1002),
                @"title": @"Diamond Heart",
                @"number": @(7),
                @"model": @"diamond",
                @"isNFT": @(YES),
                @"sender": @"Durov"
            }
        ]];
    }
    return self;
}

- (void)load {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"larpgram_enabled"] != nil) {
        self.isEnabled = [defaults boolForKey:@"larpgram_enabled"];
    }
    if ([defaults objectForKey:@"larpgram_spoof_phone"] != nil) {
        self.spoofPhone = [defaults boolForKey:@"larpgram_spoof_phone"];
    }
    if ([defaults stringForKey:@"larpgram_fake_phone"] != nil) {
        self.fakePhone = [defaults stringForKey:@"larpgram_fake_phone"];
    }
    if ([defaults objectForKey:@"larpgram_spoof_usernames"] != nil) {
        self.spoofUsernames = [defaults boolForKey:@"larpgram_spoof_usernames"];
    }
    if ([defaults arrayForKey:@"larpgram_fake_usernames"] != nil) {
        self.fakeUsernames = [defaults arrayForKey:@"larpgram_fake_usernames"];
    }
    if ([defaults objectForKey:@"larpgram_spoof_gifts"] != nil) {
        self.spoofGifts = [defaults boolForKey:@"larpgram_spoof_gifts"];
    }
    NSArray *gifts = [defaults arrayForKey:@"larpgram_fake_gifts"];
    if (gifts != nil) {
        self.fakeGifts = [gifts mutableCopy];
    }
}

- (void)save {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.isEnabled forKey:@"larpgram_enabled"];
    [defaults setBool:self.spoofPhone forKey:@"larpgram_spoof_phone"];
    [defaults setObject:self.fakePhone forKey:@"larpgram_fake_phone"];
    [defaults setBool:self.spoofUsernames forKey:@"larpgram_spoof_usernames"];
    [defaults setObject:self.fakeUsernames forKey:@"larpgram_fake_usernames"];
    [defaults setBool:self.spoofGifts forKey:@"larpgram_spoof_gifts"];
    [defaults setObject:self.fakeGifts forKey:@"larpgram_fake_gifts"];
    [defaults synchronize];
}

@end
