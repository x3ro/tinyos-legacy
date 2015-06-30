/* A trivial set of fixed point macros */
#ifndef FP_H
#define FP_H

/* + and - can be used directly */
#define FPMUL(fp1, fp2) (fp_type)(((fp_bigger)(fp1) * (fp2)) >> FP_BITS)

#define FPDIV(fp1, fp2) (fp_type)(((fp_bigger)(fp1) << FP_BITS) / (fp2))

#define FP_ROUND_TO_ZERO(fp) ((fp) >> FP_BITS)
#define FP_ROUND_AWAY_ZERO(fp) (((fp) + (1 << FP_BITS) - 1) >> FP_BITS)

#define INT_TO_FP(i) ((i) << FP_BITS)

#endif
