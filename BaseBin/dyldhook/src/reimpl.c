#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <sandbox.h>
#include <limits.h>

#include "dyld.h"
#include "private_api.h"

int64_t sandbox_extension_consume(const char *extension_token)
{
	int64_t r = 0xAAAAAAAAAAAAAAAA;
	if (!strcmp(extension_token, "invalid")) return 0;

	struct sandbox_policy_layout data = {
		.profile = (void *)extension_token,
		.len = strlen(extension_token),
		.container = &r,
	};

	if (__sandbox_ms("Sandbox", 6, &data) != 0) {
		return -1;
	}
	else {
		return r;
	}
}

extern mach_port_t mach_reply_port(void);
mach_port_t gReplyPort = 0;
mach_port_t mig_get_reply_port(void) {
    if (!gReplyPort) {
        gReplyPort = mach_reply_port();
    }

    return gReplyPort;
}