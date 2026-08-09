#import "MiniPlayerView.h"
#import "AudioPlayer.h"
#import "AppDelegate.h"

@implementation MiniPlayerView

+ (instancetype)sharedPlayer {
    static MiniPlayerView *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MiniPlayerView alloc] initWithFrame:CGRectZero];
    });
    return instance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.14 alpha:0.97];

        // Progress bar at top
        UIView *progressBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 2)];
        progressBg.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1.0];
        progressBg.tag = 1001;
        progressBg.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:progressBg];

        UIView *progressFill = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 2)];
        progressFill.backgroundColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
        progressFill.tag = 1002;
        [progressBg addSubview:progressFill];

        // Track info (left side)
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, frame.size.width - 80, 17)];
        self.titleLabel.text = @"";
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.titleLabel];

        self.artistLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 29, frame.size.width - 80, 15)];
        self.artistLabel.text = @"";
        self.artistLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        self.artistLabel.font = [UIFont systemFontOfSize:12];
        self.artistLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.artistLabel];

        // Play/Pause button (right)
        UIImage *playImg = [UIImage imageNamed:@"player_play"];
        self.playPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.playPauseBtn.frame = CGRectMake(frame.size.width - 48, 10, 36, 36);
        if (playImg) {
            [self.playPauseBtn setImage:playImg forState:UIControlStateNormal];
            [self.playPauseBtn setImage:[UIImage imageNamed:@"player_pause"] forState:UIControlStateSelected];
        } else {
            [self.playPauseBtn setTitle:@">▶" forState:UIControlStateNormal];
            [self.playPauseBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        self.playPauseBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        self.playPauseBtn.tintColor = [UIColor whiteColor];
        [self.playPauseBtn addTarget:self action:@selector(playPauseTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.playPauseBtn];

        // Tap gesture to expand (future: open full player)
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)playPauseTapped {
    AudioPlayer *player = [AudioPlayer sharedPlayer];
    if (player.isPlaying) {
        [player pause];
    } else {
        [player resume];
    }
}

- (void)updatePlayState:(BOOL)playing {
    self.playPauseBtn.selected = playing;
}

- (void)setTrackInfo:(NSString *)title artist:(NSString *)artist {
    self.titleLabel.text = title;
    self.artistLabel.text = artist;
}

- (void)tapped {
    // Future: expand to full player view
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIView *progressBg = [self viewWithTag:1001];
    UIView *progressFill = [self viewWithTag:1002];
    progressBg.frame = CGRectMake(0, 0, self.bounds.size.width, 2);

    // Update progress
    AudioPlayer *player = [AudioPlayer sharedPlayer];
    if (player.currentDuration > 0) {
        float pct = (float)(player.currentTime / player.currentDuration);
        progressFill.frame = CGRectMake(0, 0, self.bounds.size.width * pct, 2);
    }
}

@end