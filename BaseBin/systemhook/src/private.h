int necp_match_policy(uint8_t *parameters, size_t parameters_size, void *returned_result);
int necp_open(int flags);
int necp_client_action(int necp_fd, uint32_t action, uuid_t client_id, size_t client_id_len, uint8_t *buffer, size_t buffer_size);
int necp_session_open(int flags);
int necp_session_action(int necp_fd, uint32_t action, uint8_t *in_buffer, size_t in_buffer_length, uint8_t *out_buffer, size_t out_buffer_length);

int ptrace(int request, pid_t pid, caddr_t addr, int data);
#define PT_ATTACH       10      /* trace some running process */
#define PT_ATTACHEXC    14      /* attach to running process with signal exception */

#define POSIX_SPAWN_PROC_TYPE_DRIVER 0x700
int posix_spawnattr_getprocesstype_np(const posix_spawnattr_t * __restrict, int * __restrict) __API_AVAILABLE(macos(10.8), ios(6.0));

#define POSIX_SPAWNATTR_OFF_MEMLIMIT_ACTIVE 0x48
#define POSIX_SPAWNATTR_OFF_MEMLIMIT_INACTIVE 0x4C
#define POSIX_SPAWNATTR_OFF_LAUNCH_TYPE 0xA8

extern char **environ;