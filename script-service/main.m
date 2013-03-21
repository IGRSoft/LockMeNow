//
//  main.m
//  script-service
//
//  Created by Vitalii Parovishnyk on 2/13/13.
//
//

#include <Foundation/Foundation.h>

#import "ScriptServer.h"

int main(int argc, const char *argv[])
{
    // Get the singleton service listener object.
    NSXPCListener *serviceListener = [NSXPCListener serviceListener];
    
    // Configure the service listener with a delegate.
    ScriptServer *sharedScriptServer = [ScriptServer sharedScriptServer];
    serviceListener.delegate = sharedScriptServer;
    
    // Resume the listener. At this point, NSXPCListener will take over the execution of this service, managing its lifetime as needed.
    [serviceListener resume];
    
	return 0;
}
