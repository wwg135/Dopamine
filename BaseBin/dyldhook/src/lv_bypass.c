#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sandbox.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <sys/mman.h>

#include "machomerger_hook.h"
#include "dyld_jbinfo.h"
#include "dyld.h"

#include <libjailbreak/jbclient_mach.h>

int HOOK(__fcntl)(int fd, int cmd, void *arg1, void *arg2, void *arg3, void *arg4, void *arg5, void *arg6, void *arg7, void *arg8)
{
	if (jbinfo_is_checked_in()) {
		switch (cmd) {
			case F_ADDSIGS:
			case F_ADDFILESIGS:
			case F_ADDFILESIGS_RETURN: {
				jbclient_mach_trust_file(fd);
				break;
			}
		}
	}
	return (int)msyscall_errno(0x5C, fd, cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
}