#ifndef SP_DEBUG_INC
#define SP_DEBUG_INC

#include "tos.h"

#ifndef SP_DEBUG
# define ud_init(x)
# define ud_byte(x)
#else

void ud_byte(unsigned char data);
void ud_init(unsigned char bandwidth);


#endif // SP_DEBUG


#endif // SP_DEBUG_INC

