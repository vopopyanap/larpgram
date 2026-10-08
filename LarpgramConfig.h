#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LarpgramGift : NSObject <NSSecureCoding>
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *price;
@property (nonatomic, strong) NSString *modelName;
@property (nonatomic, assign) NSInteger number;
@property (nonatomic, strong) NSString *senderName;
@property (nonatomic, assign) BOOL isNFT;
@end

@interface LarpgramConfig : NSObject

+ (instancetype)shared;

@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, assign) BOOL showFloatingButton;

// Fake Phone Number
@property (nonatomic, assign) BOOL spoofPhone;
@property (nonatomic, strong) NSString *fakePhone;

// Fake Usernames
@property (nonatomic, assign) BOOL spoofUsernames;
@property (nonatomic, strong) NSArray<NSString *> *fakeUsernames;

// Fake Gifts
@property (nonatomic, assign) BOOL spoofGifts;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *fakeGifts;

- (void)save;
- (void)load;

@end

NS_ASSUME_NONNULL_END
