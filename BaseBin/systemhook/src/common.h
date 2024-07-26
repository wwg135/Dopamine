#include <CoreFoundation/CoreFoundation.h>
#include <spawn.h>
#include <xpc/xpc.h>

#define HOOK_DYLIB_PATH "/usr/lib/systemhook.dylib"

#define SYS_execve 0x3B
#define SYS_posix_spawn 0xF4
#define SYS_csops 0xA9
#define SYS_csops_audittoken 0xAA
#define SYS_necp_match_policy 0x1CC
#define SYS_necp_open 0x1F5
#define SYS_necp_client_action 0x1F6
#define SYS_necp_session_open 0x20A
#define SYS_necp_session_action 0x20B

typedef enum 
{
	kSpawnConfigDontInject = 1 << 0,
	kSpawnConfigDontTrust = 1 << 1
} kSpawnConfig;

struct _posix_spawn_args_desc {
	size_t attr_size;
	posix_spawnattr_t attrp;
	
	size_t file_actions_size;
	void *file_actions;

	size_t port_actions_size;
	void *port_actions;

	size_t mac_extensions_size;
	void *mac_extensions;

	size_t coal_info_size;
	struct _posix_spawn_coalition_info *coal_info;

	size_t persona_info_size;
	void *persona_info;

	size_t posix_cred_info_size;
	void *posix_cred_info;

	size_t subsystem_root_path_size;
	char *subsystem_root_path;

	size_t conclave_id_size;
	char *conclave_id;
};

int __posix_spawn(pid_t *restrict pid, const char *restrict path, struct _posix_spawn_args_desc *desc, char *const argv[restrict], char *const envp[restrict]);
int __execve(const char *path, char *const argv[], char *const envp[]);

bool string_has_prefix(const char *str, const char* prefix);
bool string_has_suffix(const char* str, const char* suffix);

int __posix_spawn_orig(pid_t *restrict pid, const char *restrict path, struct _posix_spawn_args_desc *desc, char *const argv[restrict], char * const envp[restrict]);

int resolvePath(const char *file, const char *searchPath, int (^attemptHandler)(char *path));
int spawn_hook_common(pid_t *restrict pid, const char *restrict path,
					   struct _posix_spawn_args_desc *desc,
					   char *const argv[restrict],
					   char *const envp[restrict],
					   void *orig,
					   int (*trust_binary)(const char *path, xpc_object_t preferredArchsArray),
					   int (*set_process_debugged)(uint64_t pid, bool fullyDebugged));