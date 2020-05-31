#import <objc/runtime.h>
#import <substrate.h>


@interface YTIRange : NSObject
@property (assign) int start;
@property (assign) int end;
@end

@interface YTIFormatStream : NSObject
@property (strong) NSString* URL;
@property (strong) NSString* mimeType;
@property (assign) int itag;
@property (assign) int height;
@property (assign) int width;
@property (strong) NSString* quality;
@property (strong) NSString* qualityLabel;
@property (assign) int approxDurationMs;
@property (assign) int contentLength;
@property (assign) int bitrate;
//@property (strong) YTIRange* initRange;
@property (strong) YTIRange* indexRange;
- (void)setInitRange:(id)arg1;
@end

@interface YTIStreamingData : NSObject
@property (strong) NSMutableArray* adaptiveFormatsArray;
@end

@interface YTIVideoDetails : NSObject
@property (strong) NSString* videoId;
@end

@interface YTIPlayerResponse : NSObject
@property (strong) YTIStreamingData* streamingData;
@property (strong) YTIVideoDetails* videoDetails;
@end

@interface YTPlayerResponse : NSObject
@property (strong) YTIPlayerResponse* playerData;
@end

@interface YTPlayerViewController : NSObject
@property (strong) NSString* currentVideoID;
@property (strong) YTPlayerResponse* playerResponse;
@end


%hook YTPlayerResponse
+ (id)playerResponseFromProtoResponse:(id)arg1 cacheContext:(id)arg2 mutableState:(id)arg3
{
	YTPlayerResponse* ret = %orig(arg1, arg2, arg3);
	
	@try {
		NSString* videoId = ret.playerData.videoDetails.videoId;
		
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@&pbj=1", videoId]];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60.0];
		[request setHTTPMethod:@"GET"];
		[request setValue:@"1" forHTTPHeaderField:@"x-youtube-client-name"];
		[request setValue:@"2.20200516.07.00" forHTTPHeaderField:@"x-youtube-client-version"];
		[request setValue:@"1" forHTTPHeaderField:@"dnt"];
		NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil]?:[NSData data];
		NSDictionary *jsonResp = [NSJSONSerialization JSONObjectWithData:receivedData options:0 error:nil]?:@{};
		
		NSMutableArray* formats = [ret.playerData.streamingData.adaptiveFormatsArray?:@[] mutableCopy];
		NSString* playRespSt = ((NSArray*)jsonResp)[2][@"player"][@"args"][@"player_response"];
		NSDictionary *jsonPlayResp = [NSJSONSerialization JSONObjectWithData:[playRespSt dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil]?:@{};
		NSArray* adaptiveFormats = jsonPlayResp[@"streamingData"][@"adaptiveFormats"];
		
		for(NSDictionary* formatNow in adaptiveFormats) {
			@try {
				NSString* url = formatNow[@"url"];
				
				if(!url) {
					continue;
				}
				
				int itag = [formatNow[@"itag"]?:@(0) intValue];
				BOOL hasFormat = NO;
				for(YTIFormatStream* forma in formats) {
					if(forma.itag == itag) {
						hasFormat = YES;
						break;
					}
				}
				if(hasFormat) {
					continue;
				}
				
				YTIFormatStream* newFormat = [[%c(YTIFormatStream) alloc] init];
				newFormat.URL = url;
				
				if(formatNow[@"itag"]!=nil) {
					newFormat.itag = [formatNow[@"itag"] intValue];
				}			
				if(formatNow[@"width"]!=nil) {
					newFormat.width = [formatNow[@"width"] intValue];
				}
				if(formatNow[@"height"]!=nil) {
					newFormat.height = [formatNow[@"height"] intValue];
				}
				if(formatNow[@"mimeType"]!=nil) {
					newFormat.mimeType = formatNow[@"mimeType"];
				}
				if(formatNow[@"qualityLabel"]!=nil) {
					newFormat.qualityLabel = formatNow[@"qualityLabel"];
				}
				if(formatNow[@"quality"]!=nil) {
					newFormat.quality = formatNow[@"quality"];
				}
				if(formatNow[@"approxDurationMs"]!=nil) {
					newFormat.approxDurationMs = [formatNow[@"approxDurationMs"] intValue];
				}
				if(formatNow[@"contentLength"]!=nil) {
					newFormat.contentLength = [formatNow[@"contentLength"] intValue];
				}
				if(formatNow[@"bitrate"]!=nil) {
					newFormat.bitrate = [formatNow[@"bitrate"] intValue];
				}
				
				if(formatNow[@"initRange"]!=nil) {
					YTIRange* range = [[%c(YTIRange) alloc] init];
					range.start = [formatNow[@"initRange"][@"start"] intValue];
					range.end = [formatNow[@"initRange"][@"end"] intValue];
					[newFormat setInitRange:range];
				}
				if(formatNow[@"indexRange"]!=nil) {
					YTIRange* range = [[%c(YTIRange) alloc] init];
					range.start = [formatNow[@"indexRange"][@"start"] intValue];
					range.end = [formatNow[@"indexRange"][@"end"] intValue];
					newFormat.indexRange = range;
				}
				
				[formats addObject:newFormat];
			} @catch(NSException*e) {
			}
		}
		ret.playerData.streamingData.adaptiveFormatsArray = formats;
	}@catch(NSException*e) {
	}
	return ret;
}
%end
