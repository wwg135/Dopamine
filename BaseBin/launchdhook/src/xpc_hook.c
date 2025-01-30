#include <libjailbreak/libjailbreak.h>
#include <mach-o/dyld.h>
#include <xpc/xpc.h>
#include <bsm/libbsm.h>
#include <libproc.h>
#include <sandbox.h>
#include <substrate.h>
#include <libjailbreak/jbserver.h>

mach_msg_header_t* dispatch_mach_msg_get_msg(void *message, size_t *_Nullable size_ptr);

int xpc_receive_mach_msg(void *msg, void *a2, void *a3, void *a4, xpc_object_t *xOut);
int (*xpc_receive_mach_msg_orig)(void *msg, void *a2, void *a3, void *a4, xpc_object_t *xOut);
int xpc_receive_mach_msg_hook(void *msg, void *a2, void *a3, void *a4, xpc_object_t *xOut)
{
	size_t msgBufSize = 0;
    struct jbserver_mach_msg *jbsMachMsg = (struct jbserver_mach_msg *)dispatch_mach_msg_get_msg(msg, &msgBufSize);
    if (jbsMachMsg != NULL && msgBufSize >= sizeof(mach_msg_header_t)) {
        size_t msgSize = jbsMachMsg->hdr.msgh_size;
        if (msgSize <= msgBufSize && msgSize >= sizeof(struct jbserver_mach_msg) && jbsMachMsg->magic == JBSERVER_MACH_MAGIC) {
			mach_msg_context_trailer_t *trailer = (mach_msg_context_trailer_t *)((uint8_t *)jbsMachMsg + round_msg(jbsMachMsg->hdr.msgh_size));
            jbserver_received_mach_message(&trailer->msgh_audit, jbsMachMsg);
            // Pass the message to xpc_receive_mach_msg anyway, it will get rid of it for us
        }
    }

	int r = xpc_receive_mach_msg_orig(msg, a2, a3, a4, xOut);
	if (r == 0 && xOut && *xOut) {
		if (jbserver_received_xpc_message(&gGlobalServer, *xOut) == 0) {
			// Returning non null here makes launchd disregard this message
			// For jailbreak messages we have the logic to handle them
			xpc_release(*xOut);
			return 22;
		}
	}
	return r;
}

void initXPCHooks(void)
{
	MSHookFunction(xpc_receive_mach_msg, (void *)xpc_receive_mach_msg_hook, (void **)&xpc_receive_mach_msg_orig);
}
