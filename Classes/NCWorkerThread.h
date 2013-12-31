//
// NCWorkerThread.h
// Newton Commander
//

#import "NCWorker.h"
#import "NCWorkerProtocol.h"

@class NCWorkerThread;


@interface NCWorkerCallback : NSObject <NCWorkerParentCallbackProtocol> {
	NCWorkerThread* m_worker_thread;
}

-(id)initWithWorkerThread:(NCWorkerThread*)workerThread;

-(void)weAreRunningOnPort:(NSNumber*)childPort;
-(void)responseData:(NSData*)data;

@end


@interface NCWorkerThread : NSThread

/*
 worker:      the class that owns us
 path:        path to the executable that this thread should run as sub-task
 label:       purpose of this worker
 uid:         the user-id that the task should run as (switch user ala sudo)
 */
-(id)initWithWorker:(NCWorker*)worker
		 controller:(id<NCWorkerController>)controller
			   path:(NSString*)path
				uid:(NSString*)uid
			  label:(NSString*)label;

-(void)callbackWeAreRunningOnPort:(NSNumber*)childPort;
-(void)callbackResponseData:(NSData*)data;

-(void)addRequestToQueue:(NSData*)data;

-(void)restartTask;
-(void)startTask;

-(void)createConnection;

-(void)shutdownConnection;
-(void)stopTask;

@end
