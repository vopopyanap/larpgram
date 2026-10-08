#import <UIKit/UIKit.h>
#import "LarpgramConfig.h"

@interface LarpgramSettingsViewController : UITableViewController <UITextFieldDelegate>
@end

@implementation LarpgramSettingsViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        self.title = @"Larpgram Settings";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
}

- (void)donePressed {
    [[LarpgramConfig shared] save];
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"Master Switch";
        case 1: return @"Phone Number Spoofing";
        case 2: return @"Fragment NFT Usernames";
        case 3: return @"Telegram NFT Gifts";
        default: return @"";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"Toggle Larpgram and HUD overlay button.";
        case 1: return @"Change your profile phone number to any custom or +888 anonymous number.";
        case 2: return @"Inject custom collectible/NFT usernames into your Telegram profile list.";
        case 3: return @"Inject custom limited/NFT gifts directly into your gifts tab.";
        default: return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 2; // Master Toggle, Floating Button Toggle
        case 1: return 2; // Toggle, Input
        case 2: return 2; // Toggle, List/Input
        case 3: return 2; // Toggle, Count info
        default: return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LarpCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"LarpCell"];
    }
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    LarpgramConfig *config = [LarpgramConfig shared];

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Enable Larpgram";
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = config.isEnabled;
            [sw addTarget:self action:@selector(masterSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
        } else {
            cell.textLabel.text = @"Floating ⚡ Button";
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = config.showFloatingButton;
            [sw addTarget:self action:@selector(floatingBtnSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Spoof Phone Number";
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = config.spoofPhone;
            [sw addTarget:self action:@selector(phoneSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
        } else {
            cell.textLabel.text = @"Fake Number";
            cell.detailTextLabel.text = config.fakePhone;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Spoof NFT Usernames";
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = config.spoofUsernames;
            [sw addTarget:self action:@selector(usernamesSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
        } else {
            cell.textLabel.text = @"Usernames";
            cell.detailTextLabel.text = [config.fakeUsernames componentsJoinedByString:@", "];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    } else if (indexPath.section == 3) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Spoof Profile Gifts";
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = config.spoofGifts;
            [sw addTarget:self action:@selector(giftsSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
        } else {
            cell.textLabel.text = @"Active Gifts";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu injected", (unsigned long)config.fakeGifts.count];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LarpgramConfig *config = [LarpgramConfig shared];

    if (indexPath.section == 1 && indexPath.row == 1) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Spoof Phone" message:@"Enter visual phone number (e.g. +888 0777 9999):" preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = config.fakePhone;
            textField.placeholder = @"+888 ...";
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *newPhone = alert.textFields.firstObject.text;
            if (newPhone.length > 0) {
                config.fakePhone = newPhone;
                [config save];
                [self.tableView reloadData];
            }
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    } else if (indexPath.section == 2 && indexPath.row == 1) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"NFT Usernames" message:@"Enter comma-separated usernames (without @):" preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = [config.fakeUsernames componentsJoinedByString:@", "];
            textField.placeholder = @"owner, rich, alpha";
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *raw = alert.textFields.firstObject.text;
            NSArray *parts = [raw componentsSeparatedByString:@","];
            NSMutableArray *cleaned = [NSMutableArray array];
            for (NSString *p in parts) {
                NSString *trimmed = [[p stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"@" withString:@""];
                if (trimmed.length > 0) {
                    [cleaned addObject:trimmed];
                }
            }
            config.fakeUsernames = cleaned;
            [config save];
            [self.tableView reloadData];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)masterSwitchChanged:(UISwitch *)sender {
    [LarpgramConfig shared].isEnabled = sender.on;
    [[LarpgramConfig shared] save];
}

- (void)floatingBtnSwitchChanged:(UISwitch *)sender {
    [LarpgramConfig shared].showFloatingButton = sender.on;
    [[LarpgramConfig shared] save];
}

- (void)phoneSwitchChanged:(UISwitch *)sender {
    [LarpgramConfig shared].spoofPhone = sender.on;
    [[LarpgramConfig shared] save];
}

- (void)usernamesSwitchChanged:(UISwitch *)sender {
    [LarpgramConfig shared].spoofUsernames = sender.on;
    [[LarpgramConfig shared] save];
}

- (void)giftsSwitchChanged:(UISwitch *)sender {
    [LarpgramConfig shared].spoofGifts = sender.on;
    [[LarpgramConfig shared] save];
}

@end
