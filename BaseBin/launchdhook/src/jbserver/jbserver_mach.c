#include <libjailbreak/jbserver.h>
#include <mach/mach.h>
#include <bsm/audit.h>

int systemwide_process_checkin(audit_token_t *processToken, char **rootPathOut, char **bootUUIDOut, char **sandboxExtensionsOut, bool *fullyDebuggedOut);
int systemwide_fork_fix(audit_token_t *parentToken, uint64_t childPid);
bool systemwide_domain_allowed(audit_token_t clientToken);

static int mach_msg_handler(audit_token_t *auditToken, struct jbserver_mach_msg *jbsMachMsg)
{
	int r = -1;

	// Anything implemented by the mach server is provided systemwide
	// So we also need to honor the allowed handler of the systemwide domain
	if (!systemwide_domain_allowed(*auditToken)) return -1;

	void *replyData = NULL;

	if (jbsMachMsg->action == JBSERVER_MACH_CHECKIN) {
		struct jbserver_mach_msg_checkin *checkinMsg = (struct jbserver_mach_msg_checkin *)jbsMachMsg;

		size_t replySize = sizeof(struct jbserver_mach_msg_checkin_reply);
		replyData = malloc(replySize);
		struct jbserver_mach_msg_checkin_reply *reply = (struct jbserver_mach_msg_checkin_reply *)replyData;
		memset(reply, 0, replySize);
		
		char *jbRootPath = NULL, *bootUUID = NULL, *sandboxExtensions = NULL;
		bool fullyDebugged = false;
		int result = systemwide_process_checkin(auditToken, &jbRootPath, &bootUUID, &sandboxExtensions, &reply->fullyDebugged);

		reply->base.msg.magic         = jbsMachMsg->magic;
		reply->base.msg.action        = jbsMachMsg->action;
		reply->base.msg.hdr.msgh_size = replySize;

		if (jbRootPath) {
			strlcpy(reply->jbRootPath, jbRootPath, sizeof(reply->jbRootPath));
			free(jbRootPath);
		}
		if (bootUUID) {
			strlcpy(reply->bootUUID, bootUUID, sizeof(reply->bootUUID));
			free(bootUUID);
		}
		if (sandboxExtensions) {
			strlcpy(reply->sandboxExtensions, sandboxExtensions, sizeof(reply->sandboxExtensions));
			free(sandboxExtensions);
		}

		reply->base.status = result;
		r = 0;
	}
	else if (jbsMachMsg->action == JBSERVER_MACH_FORK_FIX) {
		struct jbserver_mach_msg_forkfix *forkfixMsg = (struct jbserver_mach_msg_forkfix *)jbsMachMsg;

		size_t replySize = sizeof(struct jbserver_mach_msg_forkfix_reply);
		replyData = malloc(replySize);
		struct jbserver_mach_msg_forkfix_reply *reply = (struct jbserver_mach_msg_forkfix_reply *)replyData;
		memset(reply, 0, replySize);
		
		int result = systemwide_fork_fix(auditToken, forkfixMsg->childPid);

		reply->base.msg.magic         = jbsMachMsg->magic;
		reply->base.msg.action        = jbsMachMsg->action;
		reply->base.msg.hdr.msgh_size = replySize;

		reply->base.status = result;
		r = 0;
	}

	if (MACH_PORT_VALID(jbsMachMsg->hdr.msgh_remote_port) && MACH_MSGH_BITS_REMOTE(jbsMachMsg->hdr.msgh_bits) != 0) {
		struct jbserver_mach_msg_reply *reply = (struct jbserver_mach_msg_reply *)replyData;

		// Send reply
		uint32_t bits = MACH_MSGH_BITS_REMOTE(jbsMachMsg->hdr.msgh_bits);
		if (bits == MACH_MSG_TYPE_COPY_SEND)
			bits = MACH_MSG_TYPE_MOVE_SEND;
		
		reply->msg.hdr.msgh_bits = MACH_MSGH_BITS(bits, 0);
		// size already set
		reply->msg.hdr.msgh_remote_port  = jbsMachMsg->hdr.msgh_remote_port;
		reply->msg.hdr.msgh_local_port   = 0;
		reply->msg.hdr.msgh_voucher_port = 0;
		reply->msg.hdr.msgh_id           = jbsMachMsg->hdr.msgh_id + 100;
		
		kern_return_t kr = mach_msg_send(&reply->msg.hdr);
		if (kr == KERN_SUCCESS /*|| kr == MACH_SEND_INVALID_MEMORY || kr == MACH_SEND_INVALID_RIGHT || kr == MACH_SEND_INVALID_TYPE || kr == MACH_SEND_MSG_TOO_SMALL*/) {
			// All of these imply the message was either sent or destroyed
			// -> Kill the reply port in the original message as we certainly got rid of the associated right
			jbsMachMsg->hdr.msgh_remote_port = 0;
			jbsMachMsg->hdr.msgh_bits = jbsMachMsg->hdr.msgh_bits & ~MACH_MSGH_BITS_REMOTE_MASK;
		}
	}

	if (replyData) free(replyData);

	return r;
}

void jbserver_mach_init(void)
{
	jbserver_mach_msg_handler = mach_msg_handler;
}