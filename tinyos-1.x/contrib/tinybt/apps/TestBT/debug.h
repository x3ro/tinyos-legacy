/* Defines to make fail and debug methods work on symbolics 
   - shared between components that use the assembly component - mostly to 
   allow ./decode_status.pl to work... */

/* **********************************************************************
 * DEBUG flags
 * *********************************************************************/

#define DEBUG_CHILDSTATE_READBDADDRPENDING         0
#define DEBUG_CHILDEVENT_READY                     0
#define DEBUG_PARENTEVENT_READY                    0
#define DEBUG_CHILDEVENT_READBDADDRCOMPLETE        0
#define DEBUG_CHILDSTATE_SCANENABLEPENDING         1
#define DEBUG_CHILDSTATE_SCANDISABLEPENDING        1
#define DEBUG_PARENTSTATE_SCANENABLEPENDING        1
#define DEBUG_PARENTSTATE_SCANDISABLEPENDING       1
#define DEBUG_CHILDEVENT_SCANENABLECOMPLETE        1
#define DEBUG_PARENTEVENT_SCANENABLECOMPLETE       1
#define DEBUG_PARENTEVENT_SCANDISABLECOMPLETE      1
#define DEBUG_CHILDSTATE_IDLE                      1
#define DEBUG_CHILDSTATE_INQPENDING                2
#define DEBUG_CHILDEVENT_INQRESULT                 3
#define DEBUG_CHILDSTATE_INQCANCELPENDING          4
#define DEBUG_CHILDEVENT_INQCANCELCOMPLETE         4
#define DEBUG_CHILDEVENT_CONNREQUEST               5
#define DEBUG_PARENTEVENT_CONNREQUEST              5
#define DEBUG_CHILDSTATE_CONNCOMPLETEPENDING       5
#define DEBUG_CHILDEVENT_CONNCOMPLETE              6
#define DEBUG_PARENTEVENT_CONNCOMPLETE             6
#define DEBUG_CHILDEVENT_CONNFAILED                7
#define DEBUG_CHILDEVENT_CONNDISCONNECT            7
#define DEBUG_PARENTEVENT_CONNFAILED               7       
#define DEBUG_PARENTSTATE_CLOSED                   7
#define DEBUG_PARENTTASK_DISCONNECTCHILDREN        8
#define DEBUG_CHILDSTATE_HAVEPARENT                8
#define DEBUG_PARENTSTATE_OPEN                     9
#define DEBUG_CHILDSTATE_WAITFORPARENTINQDISABLE   9
#define DEBUG_CHILDEVENT_PARENTINQDISABLE         10
#define DEBUG_PARENTEVENT_PARENTDISCONNECT        10
#define DEBUG_PARENTSTATE_CLOSING                 10
#define DEBUG_PARENTEVENT_WRITELINKPOLICYCOMPLETE 11
#define DEBUG_PARENTEVENT_ROLECHANGE              12
#define DEBUG_CHILDSTATE_WRITELINKPOLICYPENDING   12
#define DEBUG_CHILDEVENT_WRITELINKPOLICYCOMPLETE  13

#define DEBUG_APPLICATION_1                        2
#define DEBUG_APPLICATION_2                        3
#define DEBUG_APPLICATION_CHECKCOMMAND             4
#define DEBUG_APPLICATION_CHECKCHILDPACKET         5
#define DEBUG_APPLICATION_NOQUERYCONNECTION        6
#define DEBUG_APPLICATION_NORESPONSEPACKET         7

#define DEBUG_BT0_ACL_DATA                        14
#define DEBUG_BT1_ACL_DATA                        15

// #define DEBUG_SENDINGCHAR                      13
#define DEBUG_NOCOMPLETE                          14
#define DEBUG_TMP                                 15
// #define DEBUG_BT_INIT                          15
// #define DEBUG_TOS_INIT                         15

/* **********************************************************************
 * FAIL FLAGS 
 * *********************************************************************/

/* Flags used for first parameter of FAIL calls
   Remember to update decode_status, if these are moved around
   (Especially wrt. bt interface decoding)
*/
#define FAIL_CONNECTION                       1 
#define FAIL_BUFFER                           2
#define FAIL_APPLICATION                      3  /* Used by the application */
#define FAIL_DELAY_BUFFER                     4  /* Uses bit 1 == bt dev */
#define FAIL_POST                             6  /* Uses bit 1 == bt dev */
#define FAIL_COMPLETE                         8  /* Uses bit 1 == bt dev */ 
#define FAIL_STATEFAIL                       10  /* Uses bit 1 == bt dev */
#define FAIL_BT                              12  /* Uses bit 1 == bt dev */
#define FAIL_ASSEMBLY                        14
#define FAIL_GENERAL                         15

/* To be able to distinguesh, it is a good idea to not use the values
   for the first argument (written in ()). For the stuff we can not
   control this way, say the statefail and failbt, they are last to
   increase the change that there are no conflicts. */

/*Flags for FAIL_CONNECTION (1) */
/* DECODE:FAIL_CONNECTION */
#define FAIL_CONNECTION_TOOMANY                 2
#define FAIL_CONNECTION_CONNREQUEST             3
#define FAIL_CONNECTION_CONNCOMPLETE            4
#define FAIL_CONNECTION_CONNNOTFOUND            5
#define FAIL_CONNECTION_LINKPOLICY              6
#define FAIL_CONNECTION_ROLECHANGE              7
#define FAIL_PARENT_NOT_CONNECTED               8
#define FAIL_CONNECTION_RECVACL                 9
#define FAIL_CONNECTION_DISCONNCOMPLETE        10

/* Flags for FAIL_BUFFER (2) */
/* DECODE:FAIL_BUFFER */
#define FAIL_BUFFER_PUT                         3
#define FAIL_BUFFER_GET                         4
#define FAIL_BUFFER_PUTDUPLICATE                5
  
/* Flags for FAIL_APPLICATION (3) */
/* DECODE:FAIL_APPLICATION */
#define FAIL_APPLICATION_OVERRUN              4
#define FAIL_APPLICATION_CHECKCOMMAND         5
#define FAIL_APPLICATION_CHECKCHILDPACKET     6
#define FAIL_APPLICATION_NULLCONNECTION       7

/* Flags for FAIL_DELAY_BUFFER (4+5) */
/* DECODE:FAIL_DELAY_BUFFER */
#define FAIL_DELAY_PUT                        2
#define FAIL_DELAY_PUTFRONT                   3
#define FAIL_DELAY_GET                        6
#define FAIL_DELAY_ERROR                      7
#define FAIL_DELAY_A                          8
#define FAIL_DELAY_B                          9
#define FAIL_DELAY_NULLBUF                   10
#define FAIL_DELAY_BUSYSLOT                  11
#define FAIL_DELAY_OUTOFSLOTS                12
#define FAIL_DELAY_NO_PENDING                13

/* Flags for FAIL_POST (6+7) */
/* DECODE:FAIL_POST */
#define FAIL_POST_SCANCHANGE                  2
#define FAIL_POST_INQ                         3
#define FAIL_POST_CREATECONN                  4
#define FAIL_POST_CONNACCEPT                  5
#define FAIL_POST_WRITELINKPOLICY             6
#define FAIL_POST_INQCANCEL                   7
#define FAIL_POST_SWITCHROLE                  8

/* Flags for FAIL_COMPLETE (8+9) */
/* DECODE:FAIL_COMPLETE */
#define FAIL_COMPLETE_SCANENABLE              2
#define FAIL_COMPLETE_DISCONNECT              3
#define FAIL_COMPLETE_INQCANCEL               4

/* Flags for FAIL_STATEFAIL (10+11) */
/* DECODE:FAIL_STATEFAIL */

/* The state of the interface in question, followed
   by the event that caused it (DEBUG_), followed
   by any other information */

/* Flags for FAIL_BT (12+13) */
/* DECODE:FAIL_BT */

/* The code as send by the hardware layer, with
   param as bits */

/* Flags for FAIL_ASSEMBLY (14) */
/* DECODE:FAIL_ASSEMBLY */
#define FAIL_NOTIMPLEMENTED                   2


/* Flags for FAIL_GENERAL (15) */
/* DECODE:FAIL_GENERAL */
#define FAIL_SENDCHARACL                      3
#define FAIL_BT_INIT                          4
#define FAIL_BT_READBDADDR                    5
#define FAIL_BT0_SENDERROR                    6
#define FAIL_BT1_SENDERROR                    7 
#define FAIL_BT_RECVERROR                     8
#define FAIL_CHILD_WRONGSTATE_SCCA           10 
#define FAIL_TMP                             14 

/* Do not use 15 for FAIL, as it is hard to distinguesh */

/* **********************************************************************
 * Debug and fail functions
 * *********************************************************************/

/* Fail macros and helper function */
#define FAIL() FAIL2(FAIL_GENERAL, FAIL_TMP)

#define FAIL2(a,b) call Debug.fail2(a, b)
#define FAIL3(a,b,c) call Debug.fail3(a, b, c)
#define FAIL4(a,b,c,d) call Debug.fail4(a, b, c, d)
#define FAIL5(a,b,c,d,e) call Debug.fail5(a, b, c, d, e)

