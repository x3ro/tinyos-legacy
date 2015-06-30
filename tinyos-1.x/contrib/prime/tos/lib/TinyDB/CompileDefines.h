#ifndef __COMPILE_DEFINES__
#define __COMPILE_DEFINES__

//defines indicating which features are in use
#undef kUSE_MAGNETOMETER //include magnetometer attribute? 1596 bytes code, 55 bytes ram
#define kQUERY_SHARING //allow query sharing
#undef kFANCY_AGGS //use fancy aggregates
#undef kEEPROM_ATTR //enable the EEPROM attribute -- uses about 3 kb of code
#undef kCONTENT_ATTR //enable the contention attribute
#undef kRAW_MIC_ATTRS // enable raw microphone or tone detector attributes
#undef kLIFE_CMD
#undef kSUPPORTS_EVENTS //about 3k of code, 100 bytes of ram for event based queries
#define kSTATUS //200 bytes of code -- allow lists of running queries to be fetched over the UART
#undef kUSE_BOMBILLA //

#if !defined(PLATFORM_PC)
#undef kMATCHBOX //enabled logging to EEPROM, 20k code, 489 bytes RAM
#undef kUART_DEBUGGER //allow output to a UART debugger, 556 bytes code, 20 bytes ram
//#undef kUSE_BOMBILLA
#endif

#ifndef NETWORK_MODULE
#define NETWORK_MODULE	NetworkC
#endif

/*            RAM     CODE
   MAG        55      1596
   SHARING
   AGGS
   EEPROM              ~3k
   UART       20       556
   EVENTS     100      ~3k
   STATUS              ~200
   BOMBILLA   1555     ~18k
 */

//other things we should support
// o disabling of EEPROM file system
// o disabling of some commands?
// o disabling of logging ?

#endif
