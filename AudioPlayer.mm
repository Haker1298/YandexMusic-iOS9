#import "AudioPlayer.h"
#import "AppDelegate.h"
#import "MiniPlayerView.h"

static NSString *const kApiBase = @"https://api.music.yandex.net";

@interface AudioPlayer ()
@property (strong, nonatomic) id timeObserver;
@property (strong, nonatomic) id itemEndObserver;
@end

@implementation AudioPlayer

+ (instancetype)sharedPlayer {
    static AudioPlayer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AudioPlayer alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _player = [[AVPlayer alloc] init];
        _queue = @[];
        _currentQueueIndex = 0;
        _isPlaying = NO;
        _currentDuration = 0;
        _currentTime = 0;

        // Observe item end to auto-play next
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(itemDidPlayToEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
    }
    return self;
}

- (void)playTrack:(NSString *)trackId albumId:(NSString *)albumId {
    if (!trackId) return;

    AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *token = del.accessToken;
    if (!token) return;

    self.isPlaying = YES;
    [[MiniPlayerView sharedPlayer] updatePlayState:YES];

    // Build API path
    NSString *path;
    if (albumId) {
        path = [NSString stringWithFormat:@"/tracks/%@?albumId=%@", trackId, albumId];
    } else {
        path = [NSString stringWithFormat:@"/tracks/%@", trackId];
    }

    NSString *urlStr = [NSString stringWithFormat:@"%@%@", kApiBase, path];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[NSString stringWithFormat:@"OAuth %@", token] forHTTPHeaderField:@"Authorization"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self notifyPlayerError:error.localizedDescription ?: @"Failed to get track info"];
            });
            return;
        }

        NSError *jsonErr;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonErr];
        if (!json || ![json isKindOfClass:[NSDictionary class]]) return;

        // Navigate to downloadInfo URL
        NSArray *tracks = json[@"result"];
        if (!tracks || tracks.count == 0) return;
        NSDictionary *track = tracks[0];

        NSString *downloadInfoUrl = nil;
        if (albumId) {
            id albums = track[@"albums"];
            if ([albums isKindOfClass:[NSDictionary class]]) {
                downloadInfoUrl = ((NSDictionary *)albums)[albumId][@"downloadInfoUrl"];
            } else if ([albums isKindOfClass:[NSArray class]]) {
                for (NSDictionary *a in (NSArray *)albums) {
                    if ([a[@"id"] isEqualToString:albumId]) {
                        downloadInfoUrl = a[@"downloadInfoUrl"];
                        break;
                    }
                }
            }
        }
        if (!downloadInfoUrl) {
            // Try to get from first album (dict or array)
            id albums = track[@"albums"];
            if ([albums isKindOfClass:[NSDictionary class]]) {
                NSDictionary *albumDict = (NSDictionary *)albums;
                for (NSString *key in albumDict) {
                    NSDictionary *album = albumDict[key];
                    if (album[@"downloadInfoUrl"]) {
                        downloadInfoUrl = album[@"downloadInfoUrl"];
                        break;
                    }
                }
            } else if ([albums isKindOfClass:[NSArray class]]) {
                NSArray *albumArr = (NSArray *)albums;
                if (albumArr.count > 0 && albumArr[0][@"downloadInfoUrl"]) {
                    downloadInfoUrl = albumArr[0][@"downloadInfoUrl"];
                }
            }
        }

        // Fallback: use direct downloadInfo from track
        if (!downloadInfoUrl && track[@"downloadInfoUrl"]) {
            downloadInfoUrl = track[@"downloadInfoUrl"];
        }

        if (!downloadInfoUrl) {
            // Construct download-info URL directly
            downloadInfoUrl = [NSString stringWithFormat:@"/tracks/%@/download-info", trackId];
        }

        [self fetchStreamUrl:downloadInfoUrl token:token];
    }];
    [task resume];
}

- (void)fetchStreamUrl:(NSString *)infoUrl token:(NSString *)token {
    // If it's a relative URL, prepend API base
    if ([infoUrl hasPrefix:@"/"]) {
        infoUrl = [NSString stringWithFormat:@"%@%@", kApiBase, infoUrl];
    }

    NSURL *url = [NSURL URLWithString:infoUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[NSString stringWithFormat:@"OAuth %@", token] forHTTPHeaderField:@"Authorization"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self notifyPlayerError:@"Failed to get stream URL"];
            });
            return;
        }

        NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *streamUrl = nil;

        // Try parsing as JSON array (most common: [{codec, bitrateInKbps, href, ...}])
        NSError *jsonErr = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonErr];

        if ([jsonObj isKindOfClass:[NSArray class]]) {
            // Direct array response: pick highest quality
            NSArray *arr = (NSArray *)jsonObj;
            if (arr.count > 0) {
                // Prefer 320 > 256 > 128 kbps mp3, then aac
                int bestIdx = -1;
                int bestBitrate = -1;
                for (int i = 0; i < (int)arr.count; i++) {
                    NSDictionary *info = arr[i];
                    int br = [info[@"bitrateInKbps"] intValue];
                    NSString *codec = info[@"codec"];
                    // Prefer mp3 over aac at same bitrate
                    int score = br;
                    if ([codec isEqualToString:@"aac"]) score -= 1;
                    if (score > bestBitrate) {
                        bestBitrate = score;
                        bestIdx = i;
                    }
                }
                if (bestIdx >= 0) {
                    streamUrl = arr[bestIdx][@"href"];
                } else {
                    streamUrl = arr[0][@"href"];
                }
            }
        } else if ([jsonObj isKindOfClass:[NSDictionary class]]) {
            // Wrapped response: {"result": [...]} or {"href": "..."}
            NSDictionary *dict = (NSDictionary *)jsonObj;
            
            // Check for direct href
            if (dict[@"href"]) {
                streamUrl = dict[@"href"];
            }
            
            // Check for result array
            if (!streamUrl) {
                NSArray *results = dict[@"result"];
                if ([results isKindOfClass:[NSArray class]] && results.count > 0) {
                    // Pick highest quality
                    int bestIdx = 0;
                    int bestBitrate = -1;
                    for (int i = 0; i < (int)results.count; i++) {
                        int br = [results[i][@"bitrateInKbps"] intValue];
                        if (br > bestBitrate) {
                            bestBitrate = br;
                            bestIdx = i;
                        }
                    }
                    streamUrl = results[bestIdx][@"href"];
                }
            }
        }

        // Last resort: parse as key-value text (old format)
        if (!streamUrl && responseStr) {
            NSArray *parts = [responseStr componentsSeparatedByString:@"&"];
            NSMutableDictionary *kv = [NSMutableDictionary dictionary];
            for (NSString *part in parts) {
                NSArray *pair = [part componentsSeparatedByString:@"="];
                if (pair.count == 2) {
                    kv[pair[0]] = pair[1];
                }
            }
            if (kv[@"hostname"] && kv[@"path"]) {
                // Build direct URL
                streamUrl = [NSString stringWithFormat:@"https://%@%@", kv[@"hostname"], kv[@"path"]];
            }
        }

        if (streamUrl) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self playStreamUrl:streamUrl];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self notifyPlayerError:@"Could not parse stream URL"];
            });
        }
    }];
    [task resume];
}

- (void)playStreamUrl:(NSString *)streamUrl {
    // Remove old observer
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }

    NSURL *url = [NSURL URLWithString:streamUrl];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    self.currentItem = item;
    self.currentTrackId = self.currentTrackId; // keep

    [self.player replaceCurrentItemWithPlayerItem:item];
    [self.player play];
    self.isPlaying = YES;

    [[MiniPlayerView sharedPlayer] updatePlayState:YES];

    // Observe duration via KVO (works on all iOS versions)
    [item addObserver:self forKeyPath:@"duration" options:0 context:nil];

    // Time observer for progress updates (every 0.5s)
    __weak typeof(self) wself = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 2)
                                                                  queue:dispatch_get_main_queue()
                                                             usingBlock:^(CMTime time) {
        typeof(self) s = wself;
        if (!s) return;
        double current = CMTimeGetSeconds(time);
        double dur = CMTimeGetSeconds(s.player.currentItem.duration);
        if (dur > 0 && isfinite(dur)) {
            s.currentTime = current;
            s.currentDuration = dur;
            [s notifyPlayerUpdate];
        }
    }];

    // Update mini player
    [[MiniPlayerView sharedPlayer] setHidden:NO];
    [[MiniPlayerView sharedPlayer] setTrackInfo:self.currentTitle artist:self.currentArtist];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"duration"]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        double dur = CMTimeGetSeconds(item.duration);
        if (dur > 0 && isfinite(dur)) {
            self.currentDuration = dur;
            [self notifyPlayerUpdate];
        }
    }
}

- (void)pause {
    [self.player pause];
    self.isPlaying = NO;
    [[MiniPlayerView sharedPlayer] updatePlayState:NO];
    [self notifyPlayerUpdate];
}

- (void)resume {
    [self.player play];
    self.isPlaying = YES;
    [[MiniPlayerView sharedPlayer] updatePlayState:YES];
    [self notifyPlayerUpdate];
}

- (void)stop {
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.isPlaying = NO;
    self.currentTime = 0;
    [[MiniPlayerView sharedPlayer] setHidden:YES];
}

- (void)playNext {
    if (self.queue.count == 0) return;
    int nextIdx = self.currentQueueIndex + 1;
    if (nextIdx >= (int)self.queue.count) nextIdx = 0;
    self.currentQueueIndex = nextIdx;
    NSDictionary *track = self.queue[nextIdx];
    if (track) {
        NSString *tid = [NSString stringWithFormat:@"%@", track[@"id"]];
        self.currentTrackId = tid;
        self.currentTitle = track[@"title"] ?: @"";
        self.currentArtist = @"";
        if (track[@"artists"] && [track[@"artists"] isKindOfClass:[NSArray class]]) {
            NSArray *artists = track[@"artists"];
            if (artists.count > 0) {
                self.currentArtist = artists[0][@"name"] ?: @"";
            }
        }
        [self playTrack:tid albumId:nil];
    }
}

- (void)playPrev {
    if (self.queue.count == 0) return;
    int prevIdx = self.currentQueueIndex - 1;
    if (prevIdx < 0) prevIdx = (int)self.queue.count - 1;
    self.currentQueueIndex = prevIdx;
    NSDictionary *track = self.queue[prevIdx];
    if (track) {
        NSString *tid = [NSString stringWithFormat:@"%@", track[@"id"]];
        self.currentTrackId = tid;
        self.currentTitle = track[@"title"] ?: @"";
        self.currentArtist = @"";
        if (track[@"artists"] && [track[@"artists"] isKindOfClass:[NSArray class]]) {
            NSArray *artists = track[@"artists"];
            if (artists.count > 0) {
                self.currentArtist = artists[0][@"name"] ?: @"";
            }
        }
        [self playTrack:tid albumId:nil];
    }
}

- (void)seekTo:(double)seconds {
    if (self.player.currentItem) {
        CMTime time = CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC);
        [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}

- (void)itemDidPlayToEnd:(NSNotification *)notif {
    if (notif.object == self.currentItem) {
        [self playNext];
    }
}

#pragma mark - Notifications to JS

- (void)notifyPlayerUpdate {
    NSDictionary *state = @{
        @"playing": @(self.isPlaying),
        @"trackId": self.currentTrackId ?: @"",
        @"title": self.currentTitle ?: @"",
        @"artist": self.currentArtist ?: @"",
        @"cover": self.currentCoverUrl ?: @"",
        @"currentTime": @(self.currentTime),
        @"duration": @(self.currentDuration)
    };

    // Notify via the web VC that started playback
    if (self.webVC) {
        [self.webVC updatePlayerState:state];
    }
}

- (void)notifyPlayerError:(NSString *)errorMsg {
    NSLog(@"[AudioPlayer] Error: %@", errorMsg);
    // Could show an alert or send to JS
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
    }
}

@end