#ifndef _OPP_MACROS_H_
#define _OPP_MACROS_H_

#define MAX(a,b) ((a) > (b) ? (a) : (b))
#define MIN(a,b) ((a) < (b) ? (a) : (b))

#define SEQ_GT16(a,b)     ((int16_t)((a) - (b)) > 0)
#define SEQ_GT32(a,b)     ((int32_t)((a) - (b)) > 0)

// Operator Definitions        0 - 200 


#ifndef NULL
#define NULL (void *)0
#endif

#endif
