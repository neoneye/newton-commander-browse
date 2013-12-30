//
// NCWorker.h
// Newton Commander
//
#import <Cocoa/Cocoa.h>


@class NCWorker;
@class NCWorkerThread;


@protocol NCWorkerController

-(void)worker:(NCWorker*)worker response:(NSDictionary*)dict;

@end

@interface NCWorker : NSObject

-(id)initWithController:(id<NCWorkerController>)controller label:(NSString*)label;

-(id)initWithController:(id<NCWorkerController>)controller label:(NSString*)label pathToWorker:(NSString*)pathToWorker;

+(NSString*)defaultPathToWorker;

-(void)setUid:(int)uid;
-(void)resetUid;

-(void)start;   
-(void)restart;

-(void)request:(NSDictionary*)dict;

/*
TODO: transaction id.. how?
TODO: kill task
*/
@end
