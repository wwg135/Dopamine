#include "jbclient_mach.h"
#include <dispatch/dispatch.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <pthread.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

mach_port_t jbclient_mach_get_launchd_port(void)
{
	mach_port_t launchdPort = MACH_PORT_NULL;
	task_get_bootstrap_port(task_self_trap(), &launchdPort);
	return launchdPort;
}

kern_return_t jbclient_mach_send_msg(struct jbserver_mach_msg *msg, struct jbserver_mach_msg_reply *reply)
{
	static mach_port_t launchdPort = MACH_PORT_NULL;
	mach_port_t replyPort = mig_get_reply_port();
	
	if (!replyPort)
		return KERN_FAILURE;
	
	if (!launchdPort)
		launchdPort = jbclient_mach_get_launchd_port();
	
	if (!launchdPort)
		return KERN_FAILURE;

	msg->magic = JBSERVER_MACH_MAGIC;
	
	msg->hdr.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, MACH_MSG_TYPE_MAKE_SEND_ONCE);
	// size already set
	msg->hdr.msgh_remote_port  = launchdPort;
	msg->hdr.msgh_local_port   = replyPort;
	msg->hdr.msgh_voucher_port = 0;
	msg->hdr.msgh_id           = 0x40000000;
	
	kern_return_t kr = mach_msg(&msg->hdr, MACH_SEND_MSG, msg->hdr.msgh_size, 0, 0, 0, 0);
	if (kr != KERN_SUCCESS)
		return kr;
	
	kr = mach_msg(&reply->msg.hdr, MACH_RCV_MSG, 0, reply->msg.hdr.msgh_size, replyPort, 0, 0);
	if (kr != KERN_SUCCESS)
		return kr;
	
	// Get rid of any rights we might have received
	mach_msg_destroy(&reply->msg.hdr);
	return KERN_SUCCESS;
}

int jbclient_mach_process_checkin(char *jbRootPathOut, char *bootUUIDOut, char *sandboxExtensionsOut, bool *fullyDebuggedOut)
{
	struct jbserver_mach_msg_checkin msg;
	msg.base.hdr.msgh_size = sizeof(msg);
	msg.base.action = JBSERVER_MACH_CHECKIN;

	size_t replySize = sizeof(struct jbserver_mach_msg_checkin_reply) + MAX_TRAILER_SIZE;
	uint8_t replyU[replySize];
	bzero(replyU, replySize);
	struct jbserver_mach_msg_checkin_reply *reply = (struct jbserver_mach_msg_checkin_reply *)&replyU;
	reply->base.msg.hdr.msgh_size = replySize;

	kern_return_t kr = jbclient_mach_send_msg((struct jbserver_mach_msg *)&msg, (struct jbserver_mach_msg_reply *)reply);
	if (kr != KERN_SUCCESS) return kr;

	reply->jbRootPath[sizeof(reply->jbRootPath)-1] = '\0';
	if (jbRootPathOut) strcpy(jbRootPathOut, reply->jbRootPath);

	reply->bootUUID[sizeof(reply->bootUUID)-1] = '\0';
	if (bootUUIDOut) strcpy(bootUUIDOut, reply->bootUUID);

	reply->sandboxExtensions[sizeof(reply->sandboxExtensions)-1] = '\0';
	if(sandboxExtensionsOut) strcpy(sandboxExtensionsOut, reply->sandboxExtensions);

	if (fullyDebuggedOut) *fullyDebuggedOut = reply->fullyDebugged;

	return (int)reply->base.status;
}

int jbclient_mach_fork_fix(pid_t childPid)
{
	struct jbserver_mach_msg_forkfix msg;
	msg.base.hdr.msgh_size = sizeof(msg);
	msg.base.action = JBSERVER_MACH_FORK_FIX;

	msg.childPid = childPid;

	size_t replySize = sizeof(struct jbserver_mach_msg_forkfix_reply) + MAX_TRAILER_SIZE;
	uint8_t replyU[replySize];
	bzero(replyU, replySize);
	struct jbserver_mach_msg_forkfix_reply *reply = (struct jbserver_mach_msg_forkfix_reply *)&replyU;
	reply->base.msg.hdr.msgh_size = replySize;

	kern_return_t kr = jbclient_mach_send_msg((struct jbserver_mach_msg *)&msg, (struct jbserver_mach_msg_reply *)reply);
	if (kr != KERN_SUCCESS) return kr;

	return (int)reply->base.status;
}