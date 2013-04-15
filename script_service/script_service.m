//
//  main.m
//  script_service
//
//  Created by Vitalii Parovishnyk on 3/6/13.
//
//

#import <Cocoa/Cocoa.h>
#include <xpc/xpc.h>
#include <asl.h>
#include "LockMeNowAppDelegate.h"

static NSString* doShell(NSString* file)
{
	NSString *scriptPath = [[NSBundle mainBundle] pathForResource:file ofType:@"sh"];
	
	NSTask *scriptTask = [NSTask new];
	NSPipe *outputPipe = [NSPipe pipe];
	
	if ([[NSFileManager defaultManager] isExecutableFileAtPath:scriptPath] == NO) {
		NSArray *chmodArguments = [NSArray arrayWithObjects:@"+x", scriptPath, nil];
		
		NSTask *chmod = [NSTask launchedTaskWithLaunchPath:@"/bin/chmod" arguments:chmodArguments];
		
		[chmod waitUntilExit];
	}
	
	[scriptTask setStandardOutput:outputPipe];
	[scriptTask setLaunchPath:scriptPath];
	
	NSFileHandle *filehandle = [outputPipe fileHandleForReading];
	
	[scriptTask launch];
	[scriptTask waitUntilExit];
	
	NSData *outputData    = [filehandle readDataToEndOfFile];
	
	NSString *outputString  = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
	
	return outputString;
}

static bool checkEncription()
{
	bool encription = false;
	
	NSString *outputString = doShell(@"filevault_2_encryption_check_extension_attribute");
	
	NSRange textRange;
	textRange =[outputString rangeOfString:@"FileVault 2 Encryption Complete"];
	if(textRange.location != NSNotFound)
	{
		encription = true;
	}
	
	return encription;
}

static void makeLoginWindowLock()
{
	NSTask *task;
	NSMutableArray *arguments = [NSArray arrayWithObject:@"-suspend"];
	
	task = [[NSTask alloc] init];
	[task setArguments: arguments];
	[task setLaunchPath: @"/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"];
	[task launch];
}

static void makeJustLock()
{
	io_registry_entry_t r =	IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
	if(!r) return;
	IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanTrue);
	IOObjectRelease(r);
}

static void
fetch_process_request(xpc_object_t request, xpc_object_t reply)
{
    // Get the URL and XPC connection from the XPC request
	if (xpc_dictionary_get_value(request, "locktype") != NULL)
    {
		uint64_t locktype = xpc_dictionary_get_uint64(request, "locktype");
		
		switch (locktype) {
			case LOCK_LOGIN_WINDOW:
				makeLoginWindowLock();
				break;
				
			case LOCK_SCREEN:
				makeJustLock();
				break;
				
			default:
				break;
		}
	}
	else if (xpc_dictionary_get_value(request, "encription") != NULL)
    {
		bool encription = checkEncription();
		xpc_dictionary_set_bool(reply, "encription", encription);
	}
}

static void
fetch_peer_event_handler(xpc_connection_t peer, xpc_object_t event)
{
    // Get the object type.
    xpc_type_t type = xpc_get_type(event);
    if (XPC_TYPE_ERROR == type) {
        // Handle an error.
        if (XPC_ERROR_CONNECTION_INVALID == event) {
            // The client process on the other end of the connection
            // has either crashed or cancelled the connection.
            asl_log(NULL, NULL, ASL_LEVEL_NOTICE, "peer(%d) received "
					"XPC_ERROR_CONNECTION_INVALID",
					xpc_connection_get_pid(peer));
            xpc_connection_cancel(peer);
        } else if (XPC_ERROR_TERMINATION_IMMINENT == event) {
            // Handle per-connection termination cleanup. This
            // service is about to exit.
            asl_log(NULL, NULL, ASL_LEVEL_NOTICE, "peer(%d) received "
					"XPC_ERROR_TERMINATION_IMMINENT",
					xpc_connection_get_pid(peer));
        }
    } else if (XPC_TYPE_DICTIONARY == type) {
        xpc_object_t requestMessage = event;
        char *messageDescription = xpc_copy_description(requestMessage);
		
        asl_log(NULL, NULL, ASL_LEVEL_NOTICE, "received message from "
				"peer(%d)\n:%s",xpc_connection_get_pid(peer), messageDescription);
        free(messageDescription);
		
        xpc_object_t replyMessage = xpc_dictionary_create_reply(requestMessage);
        assert(replyMessage != NULL);
		
        // Process request and build a reply message.
        fetch_process_request(requestMessage, replyMessage);
		
        messageDescription = xpc_copy_description(replyMessage);
        asl_log(NULL, NULL, ASL_LEVEL_NOTICE, "reply message to peer(%d)\n: %s",
                xpc_connection_get_pid(peer), messageDescription);
        free(messageDescription);
		
        xpc_connection_send_message(peer, replyMessage);
        xpc_release(replyMessage);
    }
}

static void script_event_handler(xpc_connection_t peer)
{
    // Generate an unique name for the queue to handle messages from
    // this peer and create a new dispatch queue for it.
    char *queue_name = NULL;
    asprintf(&queue_name, "%s-peer-%d", "com.bymaster.lockmenow.script",
             xpc_connection_get_pid(peer));
    dispatch_queue_t peer_event_queue =
	dispatch_queue_create(queue_name, DISPATCH_QUEUE_SERIAL);
    assert(peer_event_queue != NULL);
    free(queue_name);
	
    // Set the target queue for connection.
    xpc_connection_set_target_queue(peer, peer_event_queue);
	
    // Set the handler block for connection.
    xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
        fetch_peer_event_handler(peer, event);
    });
	
    // Enable the peer connection to receive messages.
    xpc_connection_resume(peer);
}

int main(int argc, char *argv[])
{
	xpc_main(script_event_handler);
    exit(EXIT_FAILURE);
}
