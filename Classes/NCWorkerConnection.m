//
// NCWorkerConnection.m
// Newton Commander
//

#import "NCWorkerConnection.h"
#import "NCLog.h"
#import "ZMQObjC.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

@interface NCWorkerConnection ()

@property (nonatomic, copy) NCWorkerConnectionDidReceiveDataBlock didReceiveDataBlock;
@property (nonatomic, strong) ZMQContext *context;
@property (nonatomic, strong) ZMQSocket *socket;

@end

@implementation NCWorkerConnection

-(id)initWithDidReceiveDataBlock:(NCWorkerConnectionDidReceiveDataBlock)didReceiveDataBlock
{
    self = [super init];
    if(self != nil) {
		self.didReceiveDataBlock = didReceiveDataBlock;
		NSAssert(self.didReceiveDataBlock, @"must be initialized");
		
		//[self findEndpoint];
    }
    return self;
}

#if 0
-(void)findEndpoint {
	NSLog(@"finding an available endpoint");
	
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if(sock < 0) {
        printf("socket error\n");
        return;
    }
    printf("Opened %d\n", sock);
	
	struct sockaddr_in serv_addr;
	bzero((char *) &serv_addr, sizeof(serv_addr));
	serv_addr.sin_family = AF_INET;
	serv_addr.sin_addr.s_addr = INADDR_ANY;
	serv_addr.sin_port = 0;
	if (bind(sock, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0) {
        if(errno == EADDRINUSE) {
            printf("the port is not available. already to other process\n");
			return;
        } else {
            printf("could not bind to process (%d) %s\n", errno, strerror(errno));
			return;
        }
    }
	
	socklen_t len = sizeof(serv_addr);
	if (getsockname(sock, (struct sockaddr *)&serv_addr, &len) == -1) {
		perror("getsockname");
		return;
	}

	printf("port number %d\n", ntohs(serv_addr.sin_port));
	
	
    if (close (sock) < 0 ) {
        printf("did not close: %s\n", strerror(errno));
        return;
    }

	
	NSLog(@"done finding an available endpoint");
	exit(-1);
}
#endif

-(void)main {
	@autoreleasepool {
		LOG_DEBUG(@"IPCManager thread start");
		BOOL ok = [self setup];
		if (ok) [self outerLoop];
		[self teardown];
		LOG_DEBUG(@"IPCManager thread stop");
	}
}

-(BOOL)setup {
	ZMQContext *context = [[ZMQContext alloc] initWithIOThreads:1];
	
    NSString *endpoint = @"tcp://*:5555";
    ZMQSocket *socket = [context socketWithType:ZMQ_REP];
    BOOL didBind = [socket bindToEndpoint:endpoint];
    if (!didBind) {
		NSLog(@"*** Failed to bind to endpoint [%@].", endpoint);
		return NO;
    }
	
	self.context = context;
	self.socket = socket;
	
	return YES;
}

-(void)outerLoop {
	while (1) {
		@autoreleasepool {
			BOOL ok = [self innerLoop];
			if (!ok) break;
		}
	}
}

-(BOOL)innerLoop {
	
	// Wait for next request from client
	NSData *data = [self.socket receiveDataWithFlags:0];
	if (!data) {
		NSLog(@"receiveDataWithFlags returned nil. Let stop this thread.");
		return NO;
	}
	
	NSLog(@"receiveDataWithFlags returned %d bytes", (int)[data length]);
	self.didReceiveDataBlock(data);
	
	// Send a reply
	NSString *message = @"ok";
	NSData *reply = [message dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	BOOL ok = [self.socket sendData:reply withFlags:0];
	if (!ok) {
		NSLog(@"failed to reply");
		return NO;
	}
	
	return YES;
}

-(void)teardown {
	self.socket = nil;
	[self.context closeSockets];
	[self.context terminate];
	self.context = nil;
}

-(void)killSocket {
	[self.socket close];
}

@end
