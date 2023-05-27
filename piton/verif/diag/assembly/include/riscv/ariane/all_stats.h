/* -----------------------------------------------
 * File           : all_stats.h
 * Organization   : Barcelona Supercomputing Center
 * Author(s)      : Noelia Oliete Escuin
 * Email(s)       : noelia.oliete@bsc.es
 * -----------------------------------------------*/
#ifndef __ALL_STATS_H
#define __ALL_STATS_H
#include "cache_metrics.h"
#include "util.h"

#define all_stats(code, iter) do { \
    volatile static uint32_t _amo_cnt = 0; \
    reset_L2_metrics(cid); \
    unsigned long _c = -read_csr(mcycle), _i = -read_csr(minstret); init_L2_metrics(cid); \
    code; \
    stop_L2_metrics(cid); \
    _c += read_csr(mcycle), _i += read_csr(minstret); \
    while(argv[0][0] != _amo_cnt); \
    printf("\n%s: %d cid, %ld cycles, %ld.%ld cycles/iter, %ld.%ld CPI, %ld L2_access, %ld L2_misses\n", \
             stringify(code), cid, _c, _c/iter, 10*_c/iter%10, _c/_i, 10*_c/_i%10, read_L2_access(cid), read_L2_misses(cid)); \
    ATOMIC_OP(_amo_cnt, 1, add, w); \
  } while(0)

#endif   //__ALL_STATS_H