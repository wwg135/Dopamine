//
//  DOHeaderView.m
//  Dopamine
//
//  Created by tomt000 on 04/01/2024.
//

#import "DOHeaderView.h"
#import "DOThemeManager.h"
#import "DOUIManager.h"

@interface DOHeaderView ()

@property (nonatomic) UIImageView *logoView;
@property (nonatomic) UILabel *timerLabel;
@property (nonatomic) UILabel *developLabel;
@property (nonatomic) UIStackView *stackView;
@property (nonatomic) NSMutableArray<UILabel *> *subtitleLabels;

@end

@implementation DOHeaderView

-(id)initWithImage:(UIImage *)image subtitles:(NSArray<NSAttributedString *> *)subtitles {
    if (self = [super init]) {
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.spacing = 2;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.alignment = UIStackViewAlignmentLeading;

        [self addSubview:stackView];

        [NSLayoutConstraint activateConstraints:@[
            [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        ]];

        //1 - Add the logo to our stack
        self.logoView = [[UIImageView alloc] init];
        self.logoView.translatesAutoresizingMaskIntoConstraints = NO;
        self.logoView.image = [image imageWithAlignmentRectInsets:UIEdgeInsetsMake(7, 0, -7, 0)];
        [stackView addArrangedSubview:self.logoView];

        [NSLayoutConstraint activateConstraints:@[
            [self.logoView.heightAnchor constraintEqualToConstant:40],
            [self.logoView.widthAnchor constraintEqualToAnchor:self.logoView.heightAnchor multiplier:image.size.width / image.size.height],
        ]];

        //3 - Add our subtitles to our stack
        [subtitles enumerateObjectsUsingBlock:^(NSAttributedString *formatedText, NSUInteger idx, BOOL *stop) {
            UILabel *label = [[UILabel alloc] init];
            label.attributedText = formatedText;
            label.translatesAutoresizingMaskIntoConstraints = NO;
            [stackView addArrangedSubview:label];
	    if ([[DOUIManager sharedInstance] isextrafeatures] && idx == 2) {
  		self.developLabel = label;
            }
    	    if ([[DOUIManager sharedInstance] isextrafeatures] && idx == 3) {
		self.timerLabel = label;
            }
        }];

        self.translatesAutoresizingMaskIntoConstraints = NO;

        DOTheme *theme = [[DOThemeManager sharedInstance] enabledTheme];
        if (theme.titleShadow)
        {
            self.layer.shadowColor = [UIColor blackColor].CGColor;
            self.layer.shadowOffset = CGSizeZero;
            self.layer.shadowRadius = 30;
            self.layer.shadowOpacity = 0.3;
        }

	[self.developLabel setText:@"AAA"];
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateLabel) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)updateLabel {
    self.timerLabel.text = [self formatUptime];
}

- (NSString *)formatUptime {
    NSString *formatted;
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
    int uptimeInt = ts.tv_sec;
    int seconds = uptimeInt % 60;
    int minutes = (uptimeInt / 60) % 60;
    int hours = (uptimeInt / 3600) % 24;
    int days = uptimeInt / 86400;
    if (days > 0) {
        formatted = [NSString stringWithFormat:@"系统已运行：%d 天 %d 时 %d 分 %d 秒", days, hours, minutes, seconds];
    } else if (hours > 0) {
        formatted = [NSString stringWithFormat:@"系统已运行：%d 时 %d 分 %d 秒", hours, minutes, seconds];
    } else if (minutes > 0) {
        formatted = [NSString stringWithFormat:@"系统已运行：%d 分 %d 秒", minutes, seconds];
    } else {
        formatted = [NSString stringWithFormat:@"系统已运行：%d 秒", seconds];
    }
    return formatted;
}

- (void)addSubTitle:(NSString *)subtitle {
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = subtitle;
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.stackView addArrangedSubview:subtitleLabel];
    [self.subtitleLabels addObject:subtitleLabel];
}

@end
