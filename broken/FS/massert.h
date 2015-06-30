#ifdef NDEBUG
#undef assert
#define assert(x) 
#else
#ifdef PC
#include <assert.h>
#else 
// Mica
#undef assert
#define assert(x) \
  if (!(x)) { call Debug.dbg16(0xffff); call Debug.dbgString(__FILE__); call Debug.dbg16(__LINE__); }
#endif
#endif

uses interface Debug;
