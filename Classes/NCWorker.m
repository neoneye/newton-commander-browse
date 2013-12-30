//
//  NCWorkerParent.m
//  NCWorker
//
//  Created by Simon Strandgaard on 08/06/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCLog.h"
#import "NCWorker.h"
#import "NCWorkerThread.h"
#import "NCWorkerProtocol.h"
#include <unistd.h>


@interface NCWorker () {
	id m_controller;
	NSString* m_label;
	NSString* m_path_to_worker;
	NCWorkerThread* m_thread;
	NSString* m_identifier;
	int m_uid;
}

+(NSString*)createIdentifier;
-(void)restartTask;
@end

@implementation NCWorker

-(id)initWithController:(id<NCWorkerController>)controller label:(NSString*)label pathToWorker:(NSString*)pathToWorker {
    self = [super init];
    if(self != nil) {
		m_controller = controller;
		m_label = [label copy];
		m_path_to_worker = [pathToWorker copy];
		m_thread = nil;
		m_identifier = [NCWorker createIdentifier];
		[self resetUid];
		
		NSAssert(m_controller, @"must be initialized");
		NSAssert(m_label, @"must be initialized");
		NSAssert(m_path_to_worker, @"must be initialized");
		NSAssert(m_identifier, @"must be initialized");
    }
    return self;
}


-(id)initWithController:(id<NCWorkerController>)controller label:(NSString*)label {
	return [self initWithController:controller label:label pathToWorker:[NCWorker defaultPathToWorker]];
}

+(NSString*)defaultPathToWorker {
	NSString *bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"NewtonCommanderBrowse.bundle"];
	NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
	NSAssert(bundle, @"cannot find our bundle");
	NSString *path = [bundle.resourcePath stringByAppendingPathComponent:@"NewtonCommanderHelper"];
	NSAssert(path, @"bundle does not contain the worker");
	return path;
}

+(NSString*)createIdentifier {
	static NSUInteger tag_counter = 0;                          
	NSUInteger pid = getpid();
	NSUInteger tag = tag_counter++; // autoincrement it
	return [NSString stringWithFormat:@"%lu_%lu", 
		(unsigned long)pid, (unsigned long)tag]; 
}

-(void)setUid:(int)uid {
	m_uid = uid;
}

-(void)resetUid {
	m_uid = getuid();
}

-(void)start {
	if(m_thread) return;
	
	NSString* uid_str = [NSString stringWithFormat:@"%i", m_uid];
	// uid_str = @"501"; // user: neoneye
	// uid_str = @"503"; // user: johndoe
	// uid_str = @"-2";  // user: nobody
	// uid_str = @"0";   // user: root
	// uid_str = @"";    // ignore user

	NSString* path = m_path_to_worker;
	// TODO: use worker label in cname and pname's to distinguish between workers
	NSString* cname = [NSString stringWithFormat:@"child_%@", m_identifier];
	NSString* pname = [NSString stringWithFormat:@"parent_%@", m_identifier];

	
	m_thread = [[NCWorkerThread alloc] 
		initWithWorker:self 
		controller:m_controller
		path:path
		uid:uid_str
		label:m_label
		childName:cname
		parentName:pname
	];
	[m_thread setName:@"WorkerThread"];
	[m_thread start];
}

-(void)restart {
	LOG_DEBUG(@"ncworker.%s", _cmd);

	NCWorkerThread* t = m_thread; 
	if(!t) {
		[self start];
		t = m_thread;
		NSAssert(t, @"start is always supposed to initialize m_thread");
	}
	
	NSString* uid_str = [NSString stringWithFormat:@"%i", m_uid];
	
	NSThread* thread = t;
	id obj = t;
	SEL sel = @selector(setUid:);

	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&uid_str atIndex:2]; 
	[inv retainArguments];

	[inv performSelector:@selector(invoke) 
    	onThread:thread 
		withObject:nil 
		waitUntilDone:NO];

	
	[self restartTask];
}

-(void)restartTask {
	NCWorkerThread* t = m_thread; 
	if(!t) return;
	NSAssert(t, @"start is always supposed to initialize m_thread");
	
	//NSThread* thread = t;
	id obj = t;
	SEL sel = @selector(restartTask);

	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	[inv performSelector:@selector(invoke) 
    	onThread:m_thread 
		withObject:nil 
		waitUntilDone:NO];
}

-(void)request:(NSDictionary*)dict {
	
	// start thread if not already started
	NCWorkerThread* t = m_thread; 
	if(!t) {
		[self start];
		t = m_thread;
		NSAssert(t, @"start is always supposed to initialize m_thread");
	}
	
	NSData* data = [NSArchiver archivedDataWithRootObject:dict];
	
	
	NSThread* thread = t;
	id obj = t;
	SEL sel = @selector(addRequestToQueue:);

	NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[obj methodSignatureForSelector:sel]];
	[inv setTarget:obj];
	[inv setSelector:sel];
	// arguments starts at 2, since 0 is the target and 1 is the selector
	[inv setArgument:&data atIndex:2]; 
	[inv retainArguments];

	[inv performSelector:@selector(invoke) 
    	onThread:thread 
		withObject:nil 
		waitUntilDone:NO];
}

@end /* end of class NCWorker */
