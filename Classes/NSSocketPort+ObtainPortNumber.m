//
// NSSocketPort+ObtainPortNumber.m
// Newton Commander
//
#import "NSSocketPort+ObtainPortNumber.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

@implementation NSSocketPort (ObtainPortNumber)

-(int)nc_portNumber {
	NSSocketNativeHandle sock = [self socket];
	NSData *address = self.address;
	if ([address length] != sizeof(struct sockaddr_in)) {
		NSLog(@"NSSocketPort (ObtainPortNumber) - Mismatch size of address vs size of sockaddr_in.");
		return -1;
	}
	
	struct sockaddr_in addr = *((struct sockaddr_in*)[address bytes]);
	
	socklen_t len = sizeof(addr);
	if (getsockname(sock, (struct sockaddr *)&addr, &len) == -1) {
		NSLog(@"NSSocketPort (ObtainPortNumber) - getsockname failed.");
		return -1;
	}
	
	int portNumber = ntohs(addr.sin_port);
	return portNumber;
}

@end
