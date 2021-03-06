//
// NCWorkerProtocol.h
// Newton Commander
//
// Communication between NewtonCommander.app and NCWorker.app
//

@protocol NCWorkerChildCallbackProtocol <NSObject>

-(int)handshakeAcknowledge:(int)value;

-(oneway void)requestData:(in bycopy NSData*)data;

@end


@protocol NCWorkerParentCallbackProtocol <NSObject>


-(oneway void)weAreRunningOnPort:(in bycopy NSNumber*)childPort;


-(oneway void)responseData:(in bycopy NSData*)data;

@end
