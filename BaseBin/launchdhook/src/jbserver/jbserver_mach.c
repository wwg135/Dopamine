#include <libjailbreak/jbserver.h>
#include <mach/mach.h>
#include <bsm/audit.h>

int systemwide_process_checkin(audit_token_t *processToken, char **rootPathOut, char **bootUUIDOut, char **sandboxExtensionsOut, bool *fullyDebuggedOut);
bool systemwide_domain_allowed(audit_token_t clientToken);

static int mach_msg_handler(audit_token_t *auditToken, struct jbserver_mach_msg *jbsMachMsg)
{
	// Anything implemented by the mach server is provided systemwide
	// So we also need to honor the allowed handler of the systemwide domain
	if (!systemwide_domain_allowed(*auditToken)) return -1;

	if (jbsMachMsg->action == JBSERVER_MACH_CHECKIN) {
		struct jbserver_mach_msg_stage1 *checkinStage1Msg = (struct jbserver_mach_msg_stage1 *)jbsMachMsg;

		struct jbserver_mach_msg_checkin_reply reply;
		memset(&reply, 0, sizeof(reply));
		
		char *jbRootPath = NULL, *bootUUID = NULL, *sandboxExtensions = NULL;
		bool fullyDebugged = false;
		int result = systemwide_process_checkin(auditToken, &jbRootPath, &bootUUID, &sandboxExtensions, &reply.fullyDebugged);

		reply.base.msg.magic = jbsMachMsg->magic;
		reply.base.msg.action = jbsMachMsg->action;
		reply.base.msg.hdr.msgh_size = sizeof(reply);

		if (jbRootPath) {
			strlcpy(reply.jbRootPath, jbRootPath, sizeof(reply.jbRootPath));
			free(jbRootPath);
		}
		if (bootUUID) {
			strlcpy(reply.bootUUID, bootUUID, sizeof(reply.bootUUID));
			free(bootUUID);
		}
		if (sandboxExtensions) {
			strlcpy(reply.sandboxExtensions, sandboxExtensions, sizeof(reply.sandboxExtensions));
			free(sandboxExtensions);
		}

		reply.base.status = result;

		if (MACH_PORT_VALID(jbsMachMsg->hdr.msgh_remote_port) && MACH_MSGH_BITS_REMOTE(jbsMachMsg->hdr.msgh_bits) != 0) {
			// Send reply
			uint32_t bits = MACH_MSGH_BITS_REMOTE(jbsMachMsg->hdr.msgh_bits);
			if (bits == MACH_MSG_TYPE_COPY_SEND)
				bits = MACH_MSG_TYPE_MOVE_SEND;
			
			reply.base.msg.hdr.msgh_bits = MACH_MSGH_BITS(bits, 0);
			// size already set
			reply.base.msg.hdr.msgh_remote_port  = jbsMachMsg->hdr.msgh_remote_port;
			reply.base.msg.hdr.msgh_local_port   = 0;
			reply.base.msg.hdr.msgh_voucher_port = 0;
			reply.base.msg.hdr.msgh_id           = jbsMachMsg->hdr.msgh_id + 100;
			
			kern_return_t kr = mach_msg_send(&reply.base.msg.hdr);
			if (kr == KERN_SUCCESS /*|| kr == MACH_SEND_INVALID_MEMORY || kr == MACH_SEND_INVALID_RIGHT || kr == MACH_SEND_INVALID_TYPE || kr == MACH_SEND_MSG_TOO_SMALL*/) {
				// All of these imply the message was either sent or destroyed
				// -> Kill the reply port in the original message as we certainly got rid of the associated right
				jbsMachMsg->hdr.msgh_remote_port = 0;
				jbsMachMsg->hdr.msgh_bits = jbsMachMsg->hdr.msgh_bits & ~MACH_MSGH_BITS_REMOTE_MASK;
			}
		}
		return 0;
	}

	return -1;
}

void jbserver_mach_init(void)
{
	jbserver_mach_msg_handler = mach_msg_handler;
}