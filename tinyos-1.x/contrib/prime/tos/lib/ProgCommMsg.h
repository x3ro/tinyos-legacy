/* @(#)ProgCommMsg.h
 */


typedef struct ProgFragmentMsg{
    int prog_id;
    int addr;
    char code[16];
} ProgFragment;

typedef struct FragmentRequestMsg{
    int prog_id;
    int addr;
    short dest;
    char check;
} FragmentRequest;

typedef struct NewProgramAnnounceMsg{
    int prog_id;
    unsigned short prog_length;
    char rename_flag;
    short new_id;
} NewProgAnnounce;

typedef struct StartProgramMsg{
    int prog_id;
} StartProgram;    

enum {
    AM_READFRAG = 50,
    AM_WRITEFRAG = 49,
    AM_NEWPROG = 47,
    AM_STARTPROG = 48,
    AM_FRAGMENTREQUESTMSG = 50,
    AM_PROGFRAGMENTMSG = 49,
    AM_NEWPROGRAMANNOUNCEMSG = 47, 
    AM_STARTPROGRAMMSG = 48
};

