//
//  ASLHelper.c
//  ASLHelper
//
//  Created by Vitalii Parovishnyk on 2/20/15.
//
//

#include <syslog.h>
#include <xpc/xpc.h>
#include <mach-o/dyld.h>
#include <CoreFoundation/CoreFoundation.h>

static const char *str = "\n\
# Facility loginwindow gets saved in lockmenow.log\n\
> lockmenow.log mode=0755 format=bsd rotate=seq compress file_max=1M all_max=5M\n\
? [= Sender loginwindow] file lockmenow.log\n";

#define ASL_PATH "/private/etc/asl.conf"

static bool checkASLPatch()
{
    bool result = false;
    
    FILE *fp = fopen(ASL_PATH,"r");
    char tmp[256] = {0x0};
    
    while(fp != NULL && fgets(tmp, sizeof(tmp),fp) != NULL)
    {
        if (strstr(tmp, "lockmenow.log"))
        {
            result = true;
        }
    }
    
    if (fp != NULL)
    {
        fclose(fp);
    }
            
    return result;
}

static bool applyASLPatch(const char *reactivationScript)
{
    bool result = false;
    
    FILE *fp = fopen (ASL_PATH, "at");
    
    if (fp != NULL)
    {
        fprintf(fp,"%s",str);
        
        fclose(fp);
        
        result = true;
        
        if (reactivationScript != NULL)
        {
            int status = system(reactivationScript);
            syslog(LOG_NOTICE, "Script status: %d", status);
        }
        else
        {
            syslog(LOG_NOTICE, "Cant find script");
        }
    }
    
    return result;
}

static void __XPC_Fetch_Process_Request(xpc_object_t request, xpc_object_t reply)
{
    // Get the URL and XPC connection from the XPC request
    if (xpc_dictionary_get_value(request, "check_asl_patch") != NULL)
    {
        bool result = checkASLPatch();
        xpc_dictionary_set_bool(reply, "check_asl_patch", result);
    }
    else if (xpc_dictionary_get_value(request, "patch_asl") != NULL)
    {
        const char *reactivationScript = xpc_dictionary_get_string(request, "script_path");
        bool result = applyASLPatch(reactivationScript);
        xpc_dictionary_set_bool(reply, "patch_asl", result);
    }
}

static void __XPC_Peer_Event_Handler(xpc_connection_t connection, xpc_object_t event) {
    syslog(LOG_NOTICE, "Received event in helper.");
    
    xpc_type_t type = xpc_get_type(event);
    
    if (type == XPC_TYPE_ERROR) {
        if (event == XPC_ERROR_CONNECTION_INVALID) {
            // The client process on the other end of the connection has either
            // crashed or cancelled the connection. After receiving this error,
            // the connection is in an invalid state, and you do not need to
            // call xpc_connection_cancel(). Just tear down any associated state
            // here.
            
        } else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
            // Handle per-connection termination cleanup.
        }
        
    } else {
        xpc_object_t requestMessage = event;
        
        xpc_object_t replyMessage = xpc_dictionary_create_reply(requestMessage);
        
        // Process request and build a reply message.
        __XPC_Fetch_Process_Request(requestMessage, replyMessage);
        
        xpc_connection_send_message(connection, replyMessage);
        xpc_release(replyMessage);
    }
}

static void __XPC_Connection_Handler(xpc_connection_t connection)  {
    syslog(LOG_NOTICE, "Configuring message event handler for helper.");
    
    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        __XPC_Peer_Event_Handler(connection, event);
    });
    
    xpc_connection_resume(connection);
}

int main(int argc, const char *argv[]) {
    xpc_connection_t service = xpc_connection_create_mach_service("com.igrsoft.ASLHelper",
                                                                  dispatch_get_main_queue(),
                                                                  XPC_CONNECTION_MACH_SERVICE_LISTENER);
    
    if (!service) {
        syslog(LOG_NOTICE, "Failed to create service.");
        exit(EXIT_FAILURE);
    }
    
    syslog(LOG_NOTICE, "Configuring connection event handler for helper");
    xpc_connection_set_event_handler(service, ^(xpc_object_t connection) {
        __XPC_Connection_Handler(connection);
    });
    
    xpc_connection_resume(service);
    
    dispatch_main();
    
    return EXIT_SUCCESS;
}

