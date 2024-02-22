//
//  DOHeaderView.h
//  Dopamine
//
//  Created by tomt000 on 04/01/2024.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DOHeaderView : UIView

@property (nonatomic, strong) NSMutableArray<NSAttributedString *> *subtitles;

-(instancetype)initWithImage:(UIImage *)image subtitles:(NSArray<NSAttributedString *> *)subtitles;

@end

NS_ASSUME_NONNULL_END
