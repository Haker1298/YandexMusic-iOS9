#import <AVFoundation/AVFoundation.h>
#import "WebViewController.h"

@interface AudioPlayer : NSObject
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *currentItem;
@property (strong, nonatomic) NSString *currentTrackId;
@property (copy, nonatomic) NSString *currentTitle;
@property (copy, nonatomic) NSString *currentArtist;
@property (copy, nonatomic) NSString *currentCoverUrl;
@property (assign, nonatomic) double currentDuration;
@property (assign, nonatomic) double currentTime;
@property (assign, nonatomic) BOOL isPlaying;
@property (strong, nonatomic) NSArray *queue;
@property (assign, nonatomic) int currentQueueIndex;
@property (weak, nonatomic) WebViewController *webVC;

+ (instancetype)sharedPlayer;
- (void)playTrack:(NSString *)trackId albumId:(NSString *)albumId;
- (void)pause;
- (void)resume;
- (void)stop;
- (void)playNext;
- (void)playPrev;
- (void)seekTo:(double)seconds;
@end