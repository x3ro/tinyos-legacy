/* This file is for dumping definitions of types, etc. that are in
 * tos.h but are not in regular C libraries, so that we can test C
 * functions before putting them on motes.

 * This file is meant to be included in the Testing file.  Ex. if you
 * run Test_A.c to test the functionality of A.h, you need a #include
 * C_Test_hacks.h in the file Test_A.c
 */


/* Copied from tos.h */
typedef unsigned char bool;
#ifdef FALSE //if FALSE is defined, undefine it, for the enum below
#undef FALSE
#endif
#ifdef TRUE //if TRUE is defined, undefine it, for the enum below
#undef TRUE
#endif
enum {
  FALSE = 0,
  TRUE = 1
};
