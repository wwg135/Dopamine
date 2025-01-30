#include <libjailbreak/jbserver.h>
#include <mach/mach.h>
#include <bsm/audit.h>

int systemwide_process_checkin_stage1(audit_token_t *processToken, char **sandboxExtensionsOut);

static int mach_msg_handler(audit_token_t *auditToken, struct jbserver_mach_msg *jbsMachMsg)
{
	uint64_t callerPid = audit_token_to_pid(*auditToken);

	if (jbsMachMsg->action == JBSERVER_MACH_CHECKIN_STAGE1) {
		FILE *f = fopen("/var/mobile/launchd_mach.txt", "a");
		fprintf(f, "Received stage1 checkin from %d\n", callerPid);
		fclose(f);

		struct jbserver_mach_msg_checkin_stage1 *checkinStage1Msg = (struct jbserver_mach_msg_checkin_stage1 *)jbsMachMsg;
		
		char *sandboxExtensions = NULL;
		int result = systemwide_process_checkin_stage1(auditToken, &sandboxExtensions);

		struct jbserver_mach_msg_checkin_stage1_reply reply;
		reply.base.msg.magic = jbsMachMsg->magic;
		reply.base.msg.action = jbsMachMsg->action;
		reply.base.msg.hdr.msgh_size = sizeof(reply);

		if (sandboxExtensions) {
			strlcpy(reply.sbx_tokens, sandboxExtensions, sizeof(reply.sbx_tokens));
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