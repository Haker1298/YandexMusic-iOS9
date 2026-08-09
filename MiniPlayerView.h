#import <UIKit/UIKit.h>

@interface MiniPlayerView : UIView
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *artistLabel;
@property (strong, nonatomic) UIButton *playPauseBtn;
+ (instancetype)sharedPlayer;
- (void)updatePlayState:(BOOL)playing;
- (void)setTrackInfo:(NSString *)title artist:(NSString *)artist;
@end
