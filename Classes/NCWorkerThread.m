//
// NCWorkerThread.m
// Newton Commander
//

#import "NCWorkerThread.h"
#import "NCLog.h"
#import "NSSocketPort+ObtainPortNumber.h"


@interface NSMutableArray (ShiftExtension)
// returns the first element of self and removes it
-(id)shift;
@end

@implementation NSMutableArray (ShiftExtension)
-(id)shift {
	if([self count] < 1) return nil;
	id obj = [self objectAtIndex:0];
	[self removeObjectAtIndex:0];
	return obj;
}
@end



@implementation NCWorkerCallback

-(id)initWithWorkerThread:(NCWorkerThread*)workerThread {
    self = [super init];
    if(self != nil) {
		m_worker_thread = workerThread;
    }
    return self;
}

-(oneway void)weAreRunningOnPort:(in bycopy NSNumber*)childPort {
	[m_worker_thread callbackWeAreRunningOnPort:childPort];
}

-(oneway void)responseData:(in bycopy NSData*)data {
	[m_worker_thread callbackResponseData:data];
}

@end /* end of class NCWorkerCallback */


@interface NCWorkerThread () {
	NCWorker* m_worker;
	id<NCWorkerController> m_controller;
	NCWorkerCallback* m_callback;
	NSConnection* m_connection;
	NSDistantObject* m_distant_object;
	NSString* m_path;
	NSString* m_uid;
	NSString* m_identifier;
	NSString* m_cwd;
	BOOL m_connection_established;
	NSMutableArray* m_request_queue;
	NSTask* m_task;
}

@property (nonatomic, strong) NSConnection* connection;
@property (nonatomic, assign) int connectionPort;
@property (nonatomic, strong) NSTask* task;
@property (nonatomic, strong) NSString* uid;

@end

@implementation NCWorkerThread

@synthesize connection = m_connection;
@synthesize task = m_task;
@synthesize uid = m_uid;

-(id)initWithWorker:(NCWorker*)worker
		 controller:(id<NCWorkerController>)controller
			   path:(NSString*)path
				uid:(NSString*)uid
		 identifier:(NSString*)identifier
{
    self = [super init];
    if(self != nil) {
		m_worker = worker;
		m_controller = controller;
		m_path = [path copy];
		m_cwd = [m_path stringByDeletingLastPathComponent];
		m_uid = [uid copy];
		m_identifier = [identifier copy];
		m_callback = [[NCWorkerCallback alloc] initWithWorkerThread:self];
		m_connection = nil;
		m_distant_object = nil;
		m_connection_established = NO;
		m_request_queue = [[NSMutableArray alloc] init];
		m_task = nil;
		
		NSAssert(m_worker, @"must be initialized");
		NSAssert(m_controller, @"must be initialized");
		NSAssert(m_path, @"must be initialized");
		NSAssert(m_uid, @"must be initialized");
		NSAssert(m_identifier, @"must be initialized");
		NSAssert(m_request_queue, @"must be initialized");
		NSAssert(m_callback, @"must be initialized");
    }
    return self;
}

-(void)main {
	@autoreleasepool {
		
		[self performSelector:@selector(threadDidStart) withObject:nil afterDelay:0.f];
		[[NSRunLoop currentRunLoop] run];
		
		LOG_DEBUG(@"NSRunLoop exited, terminating thread for identifier: %@", m_identifier);
	}
}

-(void)threadDidStart {
	[self createConnection];
	
	NSAssert((m_task == nil), @"task must not already be running");
	[self startTask];
	NSAssert((m_task != nil), @"at this point the task must be running");
	// LOG_DEBUG(@"thread started");
}

-(void)createConnection {
	NSAssert(m_connection == nil, @"m_connection must not already be initialized");
	
	id root_object = m_callback;
	
	// IPC between different user accounts is not possible with mach ports, thus we use sockets
	NSSocketPort* port = [[NSSocketPort alloc] init];
	NSConnection* con = [NSConnection connectionWithReceivePort:port sendPort:nil];
	[con setRootObject:root_object];
	
	[con addRequestMode:NSEventTrackingRunLoopMode];
	[con addRequestMode:NSConnectionReplyMode];
	[con addRequestMode:NSModalPanelRunLoopMode];
	
	[con setRequestTimeout:1.0];
	[con setReplyTimeout:1.0];
	
	self.connection = con;
	self.connectionPort = [port nc_portNumber];
	
	LOG_DEBUG(@"parent - port number %d", self.connectionPort);
}

-(void)startTask {
	NSAssert(m_task == nil, @"task must not already be running");
	
	NSString* path = m_path;
	NSString* uid = m_uid;
	NSString* identifier = m_identifier;
	NSString* parentPortNumber = [NSString stringWithFormat:@"%d", self.connectionPort];
	NSString* cwd = m_cwd;
	
	NSAssert(path, @"path must be initialized");
	NSAssert(uid, @"uid must be initialized");
	NSAssert(identifier, @"identifier must be initialized");
	NSAssert(cwd, @"cwd must be initialized");
	
	NSArray* args = [NSArray arrayWithObjects:
					 identifier,
					 parentPortNumber,
					 uid,
					 nil
					 ];
	LOG_DEBUG(@"arguments for worker: %@", args);
	
	NSTask* task = [[NSTask alloc] init];
	[task setEnvironment:[NSDictionary dictionary]];
	[task setCurrentDirectoryPath:cwd];
	[task setLaunchPath:path];
	[task setArguments:args];
	[task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
	[task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
	[task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
	
	@try {
		/*
		 "launch" throws an exception if the path is invalid
		 */
		[task launch];
		
	} @catch(NSException* e) {
		LOG_ERROR(@"NCWorkerThread "
				  "failed to launch task!\n"
				  "name: %@\n"
				  "reason: %@\n"
				  "launch_path: %@\n"
				  "arguments: %@",
				  [e name],
				  [e reason],
				  path,
				  args
				  );
		exit(-1);
		return;
	}
	
	self.task = task;
}

-(void)callbackWeAreRunningOnPort:(NSNumber*)childPort {
	// LOG_DEBUG(@"will connect to child %@", name);
	if (childPort == nil) {
		LOG_ERROR(@"child did not announce its port");
		exit(-1);
		return;
	}
	
	/*
	 we are halfway through the handshake procedure:
	 connection from child to parent is now up running.
	 connection from parent to child is not yet established.
	 */
	
	[self connectToChildWithPort:[childPort integerValue]];
	
    /*
	 at this point we now have a estabilished a two-way connection using sockets
	 */
	// LOG_DEBUG(@"bidirectional connection OK");
	
	[self performSelector: @selector(dispatchQueue)
	           withObject: nil
	           afterDelay: 0.f];
}

-(void)connectToChildWithPort:(NSInteger)childPort {
	// IPC between different user accounts is not possible with mach ports, thus we use sockets
	NSSocketPort *port = [[NSSocketPort alloc] initRemoteWithTCPPort:childPort host:nil];
	NSConnection* connection = [NSConnection connectionWithReceivePort:nil sendPort:port];
	
	NSDistantObject* obj = [connection rootProxy];
	if(obj == nil) {
		LOG_ERROR(@"ERROR: could not connect to child with port %d\nTERMINATE: %@", childPort, self);
		exit(-1);
		return;
	}
	[obj setProtocolForProxy:@protocol(NCWorkerChildCallbackProtocol)];
	id <NCWorkerChildCallbackProtocol> proxy = (id <NCWorkerChildCallbackProtocol>)obj;
	LOG_INFO(@"Will handshake with child");
	double t0 = CFAbsoluteTimeGetCurrent();
	int rc = [proxy handshakeAcknowledge:42];
	double t1 = CFAbsoluteTimeGetCurrent();
	double elapsed = t1 - t0;
	if(rc != 43) {
		LOG_ERROR(@"ERROR: failed creating two-way connection. child with port: %d  elapsed: %.6f", childPort, elapsed);
		return;
	}
	LOG_INFO(@"Did handshake with child. elapsed: %.6f", elapsed);
	
	m_connection_established = YES;
	m_distant_object = obj;
}

-(void)dispatchQueue {
	// LOG_DEBUG(@"dispatchQueue... ENTER");
	if(!m_connection_established) return;
	if(!m_distant_object) return;
	
	// IDEA: autoreleasepool
	
	id <NCWorkerChildCallbackProtocol> proxy = (id <NCWorkerChildCallbackProtocol>)m_distant_object;
	
    for(;;) {
        NSData* data = [m_request_queue shift];
        if (!data) {
            break;
        }
		// LOG_DEBUG(@"dispatch");
		[proxy requestData:data];
	}
	
	// LOG_DEBUG(@"dispatchQueue... DONE");
}

-(void)addRequestToQueue:(NSData*)data {
	[m_request_queue addObject:data];
	[self dispatchQueue];
}

-(void)callbackResponseData:(NSData*)data {
	// TODO: type check that it's a dictionary
	// TODO: discard pending invokations in lister mode
	NSDictionary* dict = (NSDictionary*)[NSUnarchiver unarchiveObjectWithData:data];
	
	SEL sel = @selector(worker:response:);
	id obj = m_controller;
	id arg2 = m_worker;
	id arg3 = dict;
	
	
	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&arg2 atIndex:2];
	[inv setArgument:&arg3 atIndex:3];
	[inv retainArguments];
	[inv performSelectorOnMainThread:@selector(invoke)
						  withObject:nil waitUntilDone:NO];
}

/*-(void)changeUid:(NSString*)uid {
 
 } */

-(void)restartTask {
	// m_uid = @"0";
	
	LOG_DEBUG(@"thread.%s will shutdown connection to worker", _cmd);
	[self shutdownConnection];
	
	LOG_DEBUG(@"thread.%s will stop current task", _cmd);
	[self stopTask];
	
	LOG_DEBUG(@"thread.%s will create a new connection", _cmd);
	[self createConnection];
	
	LOG_DEBUG(@"thread.%s will start new task", _cmd);
	[self startTask];
	
	LOG_DEBUG(@"thread.%s restart completed", _cmd);
}

-(void)shutdownConnection {
	/*
	 TODO: figure out what objects to invalidate
	 */
	[[m_connection receivePort] invalidate];
	[[m_connection sendPort] invalidate];
	[m_connection invalidate];
	
	NSConnection* con = [m_distant_object connectionForProxy];
	[[con receivePort] invalidate];
	[[con sendPort] invalidate];
	[con invalidate];
	
	self.connection = nil;
	
	m_distant_object = nil;
}

-(void)stopTask {
	[m_task terminate];
	self.task = nil;
}

@end
