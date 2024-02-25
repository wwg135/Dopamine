#ifndef JBCLIENT_XPC_H
#define JBCLIENT_XPC_H

#include <xpc/xpc.h>
#include <stdint.h>

void jbclient_xpc_set_custom_port(mach_port_t serverPort);

xpc_object_t jbserver_xpc_send_dict(xpc_object_t xdict);
xpc_object_t jbserver_xpc_send(uint64_t domain, uint64_t action, xpc_object_t xargs);

char *jbclient_get_jbroot(void);
char *jbclient_get_boot_uuid(void);
int jbclient_trust_binary(const char *binaryPath);
int jbclient_trust_library(const char *libraryPath, void *addressInCaller);
int jbclient_process_checkin(char **rootPathOut, char **bootUUIDOut, char **sandboxExtensionsOut);
int jbclient_fork_fix(uint64_t childPid);
int jbclient_cs_revalidate(void);
int jbclient_platform_set_process_debugged(uint64_t pid);
int jbclient_platform_stage_jailbreak_update(const char *updateTar);
int jbclient_watchdog_intercept_userspace_panic(const char *panicMessage);
int jbclient_watchdog_get_last_userspace_panic(char **panicMessage);
int jbclient_root_get_physrw(bool singlePTE);
int jbclient_root_sign_thread(mach_port_t threadPort);
int jbclient_root_get_sysinfo(xpc_object_t *sysInfoOut);
int jbclient_root_add_cdhash(uint8_t *cdhashData, size_t cdhashLen);
int jbclient_root_steal_ucred(uint64_t ucredToSteal, uint64_t *orgUcred);
int jbclient_root_set_mac_label(uint64_t slot, uint64_t label, uint64_t *orgLabel);
int jbclient_boomerang_done(void);

#endif
