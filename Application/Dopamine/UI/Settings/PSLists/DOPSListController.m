//
//  DOPSListController.m
//  Dopamine
//
//  Created by tomt000 on 26/01/2024.
//

#import "DOPSListController.h"
#import "DOThemeManager.h"

@interface DOPSListController ()

@end

@implementation DOPSListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_table setSeparatorColor:[UIColor clearColor]];
    [_table setBackgroundColor:[UIColor clearColor]];
    [DOPSListController setupViewControllerStyle:self];

    // 添加拖动手势识别器
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.view addGestureRecognizer:panGesture];
    
    // 添加拖动大小标志视图
    UIView *resizeHandle = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 20, self.view.bounds.size.height - 20, 20, 20)];
    resizeHandle.backgroundColor = [UIColor blueColor]; // 可根据需要设置颜色
    [self.view addSubview:resizeHandle];
}

+ (void)setupViewControllerStyle:(UIViewController*)vc
{
    DOTheme *theme = [[DOThemeManager sharedInstance] enabledTheme];
    
    vc.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    vc.view.backgroundColor = theme.windowColor;
    vc.view.layer.cornerRadius = 16;
    vc.view.layer.masksToBounds = YES;
    vc.view.layer.cornerCurve = kCACornerCurveContinuous;
    [UISwitch appearanceWhenContainedInInstancesOfClasses:@[[vc class]]].onTintColor = [UIColor colorWithRed: 71.0/255.0 green: 169.0/255.0 blue: 135.0/255.0 alpha: 1.0];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _table.frame = CGRectMake(12, 5, self.view.bounds.size.width - 24, self.view.bounds.size.height - 10);
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.view];
    
    CGRect frame = self.view.frame;
    frame.size.width += translation.x;
    frame.size.height += translation.y;
    
    self.view.frame = frame;
    [gesture setTranslation:CGPointZero inView:self.view];
}

@end
