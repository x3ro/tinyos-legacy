/**
 * Listens to the serial port, and outputs sensor data in human readable form.
 *
 * @file      xlisten.c
 * @author    Martin Turon
 * @version   2004/3/10    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: xlisten.c,v 1.10 2004/09/30 02:53:57 mturon Exp $
 */

#include "xsensors.h"

static const char *g_version = 
    "$Id: xlisten.c,v 1.10 2004/09/30 02:53:57 mturon Exp $";

/** A structure to store parsed parameter flags. */
typedef union {
    unsigned flat;
    
    struct {
        // output display options
        unsigned  display_raw    : 1;  //!< raw TOS packets
        unsigned  display_parsed : 1;  //!< pull out sensor readings
        unsigned  display_cooked : 1;  //!< convert to engineering units
        unsigned  export_parsed  : 1;  //!< output comma delimited fields
        unsigned  export_cooked  : 1;  //!< output comma delimited fields
        unsigned  log_parsed     : 1;  //!< log output to database
        unsigned  log_cooked     : 1;  //!< log output to database
        unsigned  display_time   : 1;  //!< display timestamp of packet
        unsigned  display_ascii  : 1;  //!< display packet as ASCII characters
        unsigned  display_rsvd   : 7;  //!< pad first word for output options
        
        // modes of operation
        unsigned  display_help   : 1;
        unsigned  display_baud   : 1;  //!< baud was set by user
        unsigned  mode_debug     : 1;  //!< debug serial port
        unsigned  mode_quiet     : 1;  //!< suppress headers
        unsigned  mode_version   : 1;  //!< print versions of all modules
        unsigned  mode_header    : 1;  //!< user using custom packet header
        unsigned  mode_socket    : 1;  //!< connect to a serial forwarder
        unsigned  mode_framing   : 2;  //!< auto=0, framed=1, unframed=2
    } bits; 
    
    struct {
        unsigned short output;         //!< one output option required
        unsigned short mode;
    } options;
} s_params;

/** A variable to store parsed parameter flags. */
static s_params   g_params;
static int        g_istream;   //!< Handle of input stream  

/**
 * Extracts command line options and sets flags internally.
 * 
 * @param     argc            Argument count
 * @param     argv            Argument vector
 *
 * @author    Martin Turon
 *
 * @version   2004/3/10       mturon      Intial version
 * @n         2004/3/12       mturon      Added -b,-s,-q,-x
 * @n         2004/8/04       mturon      Added -l [ver. 1.11]
 * @n         2004/8/22       mturon      Added -i [ver. 1.13]
 * @n         2004/9/27       mturon      Added -t [ver. 1.15]
 * @n         2004/9/29       mturon      Added -f,-a [v 1.16]
 */
void parse_args(int argc, char **argv) 
{
    // This value is set if/when the bitflag is set.
    unsigned baudrate = 0;
    char *server, *port;

    g_params.flat = 0;   /* default to no params set */

    xpacket_initialize();

    while (argc) {
        if ((argv[argc]) && (*argv[argc] == '-')) {
            switch(argv[argc][1]) {
                case '?':
                    g_params.bits.display_help = 1;
                    break;

                case 'q':
                    g_params.bits.mode_quiet = 1;
                    break;

                case 'p':
                    g_params.bits.display_parsed = 1;
                    break;

                case 'r':
                    g_params.bits.display_raw = 1;
                    break;

                case 'a':
                    g_params.bits.display_ascii = 1;
                    break;

                case 'c':
                    g_params.bits.display_cooked = 1;
                    break;

                case 'x':
                    switch (argv[argc][2]) {
                        case 'r':  g_params.bits.export_parsed = 1;  break;
                        default:   g_params.bits.export_cooked = 1;  break;
                    }
					break;

                case 'f': {
                    switch (argv[argc][2]) {
                        case '=':    // specify arbitrary offset
                            g_params.bits.mode_framing = atoi(argv[argc]+3)&3;
                            break;

                        case 'a':    // automatic deframing
                            g_params.bits.mode_framing = 0;
							break;

                        case '0':    
                        case 'n':    // assume no framing
                            g_params.bits.mode_framing = 2;
							break;

                        case '1':    // force framing
						default:
                            g_params.bits.mode_framing = 1;
                            break;
                    }
                    break;
	            }

                case 'w':
                case 'h': {
                    int offset = XPACKET_DATASTART_MULTIHOP;
                    g_params.bits.mode_header = 1;
                    switch (argv[argc][2]) {
                        case '=':    // specify arbitrary offset
                            offset = atoi(argv[argc]+3);
                            break;
                        case '0':    // direct uart (no wireless)
                        case '1':    // single hop offset
                            offset = XPACKET_DATASTART_STANDARD;
                            break;
                    }
                    xpacket_set_start(offset);
                    break;
	            }

                case 'l':
                    g_params.bits.log_cooked = 1;
                    if (argv[argc][2] == '=') {
                        xdb_set_table(argv[argc]+3);
//                        xdb_create_table(argv[argc]+3);
    	        }

                case 'b':
                    if (argv[argc][2] == '=') {
                        baudrate = xserial_set_baud(argv[argc]+3);
                        g_params.bits.display_baud = 1;
                    }
                    break;

                case 's':
                    if (argv[argc][2] == '=') {
                        xserial_set_device(argv[argc]+3);
                    }
                    break;

		case 't':
		    g_params.bits.display_time = 1;
		    break;

                case 'i':
		    g_params.bits.mode_socket = 1;
                    if (argv[argc][2] == '=') {
			server = argv[argc]+3;
			port = strchr(server, ':');
			if (port) {
			    *port++ = '\0';
			    xsocket_set_port(port);
			}
                        xsocket_set_server(server);
                    }
                    break;

                case 'v':
                    g_params.bits.mode_version = 1;
                    break;

                case 'd':
                    g_params.bits.mode_debug = 1;
                    break;
            }
        }
        argc--;
    }

    if (!g_params.bits.mode_quiet) {
        // Summarize parameter settings
        printf("xlisten Ver:%s\n", g_version);
        if (g_params.bits.mode_version)   xpacket_print_versions();
        printf("Using params: ");
        if (g_params.bits.display_help)   printf("[help] ");
        if (g_params.bits.display_baud)   printf("[baud=0x%04x] ", baudrate);
        if (g_params.bits.display_raw)    printf("[raw] ");
        if (g_params.bits.display_ascii)  printf("[ascii] ");
        if (g_params.bits.display_parsed) printf("[parsed] ");
        if (g_params.bits.display_cooked) printf("[cooked] ");
        if (g_params.bits.export_parsed)  printf("[export] ");
        if (g_params.bits.display_time)   printf("[timed] ");
        if (g_params.bits.export_cooked)  printf("[convert] ");
        if (g_params.bits.log_cooked)     printf("[logging] ");
        if (g_params.bits.mode_framing==1)printf("[framed] ");
        if (g_params.bits.mode_framing==2)printf("[unframed] ");
        if (g_params.bits.mode_header)    printf("[header=%i] ", 
						 xpacket_get_start());
        if (g_params.bits.mode_socket)    printf("[inet=%s:%u] ", 
						 xsocket_get_server(), 
						 xsocket_get_port());
        if (g_params.bits.mode_debug) {
            printf("[debug - serial dump!] \n");
            xserial_port_dump();
        }
        printf("\n");
    }

    if (g_params.bits.display_help) {
        printf(
            "\nUsage: xlisten <-?|r|p|c|x|l|d|v|q> <-l=table>"
	    "\n               <-s=device> <-b=baud> <-i=server:port>"
            "\n   -? = display help [help]"
            "\n   -r = raw display of tos packets [raw]"
            "\n   -a = ascii display of tos packets [ascii]"
            "\n   -p = parse packet into raw sensor readings [parsed]"
            "\n   -x = export readings in csv spreadsheet format [export]"
            "\n   -c = convert data to engineering units [cooked]"
            "\n   -l = log data to database or file [logged]"
            "\n   -d = debug serial port by dumping bytes [debug]"
            "\n   -b = set the baudrate [baud=#|mica2|mica2dot]"
            "\n   -s = set serial port device [device=com1]"
            "\n   -i = use serial forwarder input [inet=host:port]"
            "\n   -o = output (forward serial) to port [onet=port] -!TBA!-"
            "\n   -h = specify header size [header=offset]"
            "\n   -t = display time packet was received [timed]"
            "\n   -q = quiet mode (suppress headers)"
            "\n   -v = show version of all modules"
            "\n"
        );
        exit(0);
    }

    /* Default to displaying packets as raw, parsed, and cooked. */
    if (g_params.options.output == 0) {
        g_params.bits.display_raw = 1;
        g_params.bits.display_parsed = 1;
        g_params.bits.display_cooked = 1;
    }

    /* Stream initialization */

    // Set STDOUT and STDERR to be line buffered, so output is not delayed.
    setlinebuf(stdout);
    setlinebuf(stderr);

    if (g_params.bits.mode_socket) {
        g_istream = xsocket_port_open();
    } else {
        g_istream = xserial_port_open();
    }
}

int xmain_get_verbose() {
    return !g_params.bits.mode_quiet;
}

/**
 * The main entry point for the sensor listener console application.
 * 
 * @param     argc            Argument count
 * @param     argv            Argument vector
 *
 * @author    Martin Turon
 * @version   2004/3/10       mturon      Intial version
 */
int main(int argc, char **argv) 
{
    int length;
    unsigned char buffer[255];

    parse_args(argc, argv); 

    while (1) {
	length = xserial_port_read_packet(g_istream, buffer);

        if (length < XPACKET_MIN_SIZE)
	    continue;     // ignore patial packets and packetizer frame end

        if (g_params.bits.display_time)   xpacket_print_time();

        if (g_params.bits.display_raw)    xpacket_print_raw(buffer, length);

        if (g_params.bits.display_ascii)  xpacket_print_ascii(buffer, length);

        xpacket_decode(buffer, length, g_params.bits.mode_framing);

        if (g_params.bits.display_parsed) xpacket_print_parsed(buffer);

        if (g_params.bits.export_parsed)  xpacket_export_parsed(buffer);

        if (g_params.bits.export_cooked)  xpacket_export_cooked(buffer);

        if (g_params.bits.log_cooked)     xpacket_log_cooked(buffer);

        if (g_params.bits.display_cooked) xpacket_print_cooked(buffer);
    }
}


//####################### User Manual Follows ##############################

/** 
@mainpage XListen Documentation

@section version Version 
$Id: xlisten.c,v 1.10 2004/09/30 02:53:57 mturon Exp $

@section usage Usage 
Usage: xlisten <-?|r|p|c|x|l|d|v|q> <-b=baud> <-s=device> <-h=size>
@n
@n      -? = display help [help]
@n      -r = raw display of tos packets [raw]
@n      -p = parse packet into raw sensor readings [parsed]
@n      -x = export readings in csv spreadsheet format [export]
@n      -c = convert data to engineering units [cooked]
@n      -t = display time packet was received [timed]"
@n      -a = ascii display of tos packets [ascii]"
@n      -l = log data to database [logged]
@n      -d = debug serial port by dumping bytes [debug]
@n      -b = set the baudrate [baud=#|mica2|mica2dot]
@n      -s = set serial port device [device=com1]
@n      -i = use serial forwarder input [inet=host:port]"
@n      -h = specify size of TOS_msg header [header=size]
@n      -v = display complete version information for all modules [version]
@n      -q = quiet mode (suppress headers)
@n
@section params Parameters

@subsection help -? [help]

XListen has many modes of operation that can be controlled by passing command line parameters.  The current list of these command line options and a brief usage explanation is always available by passing the -? flag.
@n
@n A detail explanation of each command line option as of version 1.7 follows.

@subsection baud -b=baudrate [baud]
     This flag allows the user to set the baud rate of the serial line connection.  The default baud rate is 57600 bits per second which is compatible with the Mica2.  The desired baudrate must be passed as a  number directly after the equals sign with no spaces inbetween, i.e. -b=19200.  Optionally, a product name can be passed in lieu of an actual number and the proper baud will be set, i.e. -b=mica2dot.  Valid product names are:
	mica2           	(57600 baud)
	mica2dot	(19200 baud)


@subsection serial -s=port [serial]
     This flag gives the user the ability to specify which COM port or device xlisten should use.  The default port is /dev/ttyS0 or the UNIX equivalent to COM1.  The given port must be passed directly after the equals sign with no spaces, i.e. -s=com3.  

@subsection raw	-r [raw]
     Raw mode displays the actual TOS packets as a sequence of bytes as seen coming over the serial line.  Sample output follows:

@n $ xlisten -r
@n xlisten Ver: Id: xlisten.c,v 1.7 2004/03/23 00:52:28 mturon Exp
@n Using params: [raw]
@n /dev/ttyS0 input stream opened
@n 7e7e000033000000c8035f61d383036100000000e4510d610000000080070000d4b5f577
@n 7e00007d1d8101060029091e09ef082209e7080b09b40800000000000000000000000100
@n 7e00007d1d81020600f007de07da07d507c3064706540500000000000000000000000100

@subsection parsed	-p [parsed]
     Parsed mode attempts to interpret the results of the incoming TOS packets and display information accordingly.  The first stage of the parsing is to look for a valid sensorboard_id field, and display the part number.  The node_id of the packet sender is also pulled out and displayed.  Finally, raw sensor readings are extracted and displayed with some designation as to their meaning:

@n $ xlisten -p -b=mica2dot
@n xlisten Ver: Id: xlisten.c,v 1.7 2004/03/23 00:52:28 mturon Exp
@n Using params: [baud=0x000e] [parsed]
@n /dev/ttyS0 input stream opened
@n mda500 id=06 bat=00c1 thrm=0203 a2=019c a3=0149 a4=011d a5=012b a6=011b a7=0147
@n mda500 id=06 bat=00c2 thrm=0203 a2=019d a3=014d a4=011e a5=0131 a6=011b a7=0140
@n mda500 id=06 bat=00c2 thrm=0204 a2=0199 a3=014c a4=0125 a5=012a a6=011f a7=0147
@n mda500 id=06 bat=00c2 thrm=0204 a2=0198 a3=0148 a4=0122 a5=0131 a6=012d a7=0143
@n mda500 id=06 bat=00c2 thrm=0203 a2=019e a3=014e a4=0124 a5=012b a6=011c a7=0143
@n mda500 id=06 bat=00c2 thrm=0204 a2=019d a3=014c a4=011f a5=0135 a6=0133 a7=011d
@n mda500 id=06 bat=00c2 thrm=0205 a2=019a a3=014c a4=011e a5=0131 a6=012d a7=011c

@subsection cooked	-c [cooked]
     Cooked mode actually converts the raw sensor readings within a given packet into engineering units.  Sample output follows:

@n $ xlisten -c -b=mica2dot
@n xlisten Ver: Id: xlisten.c,v 1.7 2004/03/23 00:52:28 mturon Exp
@n Using params: [baud=0x000e] [cooked]
@n /dev/ttyS0 input stream opened
@n MDA500 [sensor data converted to engineering units]:
@n    health:     node id=6
@n    battery:    volts=3163 mv
@n    thermistor: resistance=10177 ohms, tempurature=24.61 C
@n    adc chan 2: voltage=1258 mv
@n    adc chan 3: voltage=1001 mv
@n    adc chan 4: voltage=893 mv
@n    adc chan 5: voltage=939 mv
@n    adc chan 6: voltage=875 mv
@n    adc chan 7: voltage=850 mv

@subsection quiet	-q [quiet]
     This flag suppresses the standard xlisten header which displays the version string and parameter selections. 

@subsection export	-x [export]
    Export mode displays raw adc values as comma delimited text for use in spreadsheet and data manipulation programs.  The user can pipe the output of xlisten in export mode to a file and load that file into Microsoft Excel to build charts of the information.  Sample output follows:

@n $ xlisten -b=mica2dot -q -x
@n 51200,24323,54113,899,97,0,58368,3409
@n 6,193,518,409,328,283,296,298
@n 6,194,517,410,330,292,310,300
@n 6,194,518,409,329,286,309,288
@n 6,194,517,411,331,287,297,300
@n 6,194,516,413,335,288,301,287

@subsection timed	-t [timed]
    Displays the time at which the packet was received.

@n $ xlisten -t
@n [2004/09/29 10:24:29]
@n [2004/09/29 10:36:57]

@subsection ascii	-a [ascii]
    Displays the raw packet contents as ASCII characters.

@subsection logging	-l [logged]
    Logs incoming readings to a Postgres database.  Default connection settings are: server=localhost, port=5432, user=tele, pass=tiny.

@subsection header	-h=size [header]
     Passing the header flag tells xlisten to use a different offset when parsing packets that are being forwarded by TOSBase.  Generally this flag is not required as xlisten autodetects the header size from the AM type.  When this flag is passed all xlisten will assume all incoming packets have a data payload begining after the header size offset.

@subsection versions	-v [versions]
     Displays complete version information for all sensorboard decoding modules within xlisten. 

@n $  xlisten -v
@n xlisten Ver: Id: xlisten.c,v 1.11 2004/08/04 21:06:41 mturon Exp 
@n   87: Id: mep401.c,v 1.10 2004/08/04 21:06:41 mturon Exp 
@n   86: Id: mts400.c,v 1.15 2004/08/04 21:06:41 husq Exp 
@n   85: Id: mts400.c,v 1.15 2004/08/04 21:06:41 mturon Exp 
@n   84: Id: mts300.c,v 1.14 2004/08/04 21:06:41 husq Exp 
@n   83: Id: mts300.c,v 1.14 2004/08/04 21:06:41 mturon Exp 
@n   82: Id: mts101.c,v 1.5 2004/08/04 21:06:41 husq Exp 
@n   81: Id: mda300.c,v 1.4 2004/08/04 17:15:22 jdprabhu Exp 
@n   80: Id: mda500.c,v 1.11 2004/08/04 21:06:41 husq Exp 
@n   03: Id: mep500.c,v 1.3 2004/08/04 21:06:41 mturon Exp 
@n   02: Id: mts510.c,v 1.6 2004/08/04 21:06:41 husq Exp 
@n   01: Id: mda500.c,v 1.11 2004/08/04 21:06:41 abroad Exp 

@subsection debug	-d [debug]
     This flag puts xlisten in a mode so that it behaves exactly like the TinyOS raw listen tool (tinyos-1.x/tools/src/raw_listen.c.)  All other command line options except -b [baud] and -s[serial] will be ignored.  This mode is mainly used for compatibility and debugging serial port issues.  Individual bytes will be displayed as soon as they are read from the serial port with no post-processing.  In most cases -r [raw] is equivalent and preferred to using debug mode.

@subsection display	Display Options
     The -r, -p, and -c flags are considered display options.  These can be passed in various combinations to display multiple views of the same packet at once.  The default display mode when xlisten is invoked with no arguments is -r.  What follows is sample output for all three display options turned on at once:

@n $ xlisten -b=mica2dot -r -p -c
@n xlisten Ver: Id: xlisten.c,v 1.7 2004/03/23 00:52:28 mturon Exp
@n Using params: [baud=0x000e] [raw] [parsed] [cooked]
@n /dev/ttyS0 input stream opened
@n 7e7e000033000000c8035f61d383036100000000e4510d610000000080070000d4b5f577
@n 7e00007d1d01010600c200050293014401210135012f0122010000000000000000000100
@n mda500 id=06 bat=00c2 thrm=0205 a2=0193 a3=0144 a4=0121 a5=0135 a6=012f a7=0122
@n MDA500 [sensor data converted to engineering units]:
@n    health:     node id=6
@n    battery:    volts=3163 mv
@n    thermistor: resistance=10217 ohms, tempurature=24.53 C
@n    adc chan 2: voltage=1246 mv
@n    adc chan 3: voltage=1001 mv
@n    adc chan 4: voltage=893 mv
@n    adc chan 5: voltage=955 mv
@n    adc chan 6: voltage=936 mv
@n    adc chan 7: voltage=896 mv

@section building Build Process
     The source code for the xlisten tool is located at: /opt/tinyos-1.x/contrib/xbow/tools/src/xlisten.  
@n@n
    To build the tool, change to the xlisten source directory and run `make`. 
@n@n
    To get the latest version of the source, change to the xlisten source directory and run `cvs update`.  


@section setup Setup

    XListen is a command line tool that can be run from a cygwin shell by simply typing `xlisten`.  The executable needs to be in your working path to use it.  A simple way to add xlisten to your working path is to create a soft link to it by running the following command: 
@n$ ln -s /opt/tinyos-1.x/contrib/xbow/tools/src/xlisten /usr/local/bin/xlisten
@n@n
  You can use xlisten to read sensor data from either one mote over a serial link, or a wireless network of motes.  In both configurations, you need to have a MIB510 board connected via a serial cable to your PC.
@n@n
    For a single mote configuration, the mote must be programmed with a XSensorMXX### application and plugged into the MIB510.  The mote will stream packets over the UART whenever it has power.
@n@n
   For the network of motes configuration, a base station mote needs to be programmed with TOSBase and plugged into the MIB510.  All other motes need to be installed with an XSensorMXX## application and put within range of the base station or a valid multi-hop peer.  Xlisten must then be run with the -w flag to properly parse the wireless packets.  Take care to program all the motes to the same frequency and group id.

*/

