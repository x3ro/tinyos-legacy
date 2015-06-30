#ifdef PLATFORM_PC

#include <stdio.h>
#define FATAL(...) (printf("Fatal Error: "), printf(__VA_ARGS__), printf("\n"))
#define ASSERT(FLAG, ...) ({if((FLAG) == 0) FATAL(__VA_ARGS__);})
#define PRINT(...) (printf(__VA_ARGS__))

#else

#define FATAL(...) { }
#define ASSERT(FLAG, ...) { }
#define PRINT(...) { }

#endif


