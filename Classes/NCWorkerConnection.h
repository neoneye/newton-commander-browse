//
// NCWorkerConnection.h
// Newton Commander
//

#import <Foundation/Foundation.h>

typedef void (^NCWorkerConnectionDidReceiveDataBlock)(NSData* data);

@interface NCWorkerConnection : NSThread

-(id)initWithDidReceiveDataBlock:(NCWorkerConnectionDidReceiveDataBlock)didReceiveDataBlock;

-(void)killSocket;

@end
