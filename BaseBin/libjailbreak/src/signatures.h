#ifndef SIGNATURES_H
#define SIGNATURES_H

#include <choma/CodeDirectory.h>

typedef uint8_t cdhash_t[CS_CDHASH_LEN];
void file_collect_untrusted_cdhashes(int fd, cdhash_t **cdhashesOut, uint32_t *cdhashCountOut);
void file_collect_untrusted_cdhashes_by_path(const char *path, cdhash_t **cdhashesOut, uint32_t *cdhashCountOut);
#endif