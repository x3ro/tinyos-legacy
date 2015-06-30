/**
 * Sends commands to the serial port to control a wireless sensor network.
 *
 * @file      xcommand.c
 * @author    Martin Turon
 * @version   2004/10/3    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: xcommand.c,v 1.4 2004/11/11 01:00:51 mturon Exp $
 */

#include "xcommand.h"

static const char *g_version = 
    "$Id: xcommand.c,v 1.4 2004/11/11 01:00:51 mturon Exp $";

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
static int        g_ostream;   //!< Handle of output stream  
static char *     g_command;

unsigned char       g_am_type = AMTYPE_XCOMMAND;   //!< TOS AM type of command to send

char *     g_argument;

int        g_seq_no  = 100;     //!< Broadcast sequence number
unsigned   g_frame   = 0x26;    //!< Packetizer sequence number
unsigned   g_group   = 0xff;
unsigned   g_dest    = 0xFFFF;  //!< Destination nodeid (0xFFFF = all)

void xcommand_print_help() {
    printf(
	"\nUsage: xcommand <-?|v|q> command argument"
	"\n               <-s=device> <-b=baud> <-i=server:port>"
	"\n               <-n=nodeid> <-g=group> <-#=seq_no>"
	"\n   -? = display help [help]"
	"\n   -q = quiet mode (suppress headers)"
	"\n   -v = show version of all modules"
	"\n   -b = set the baudrate [baud=#|mica2|mica2dot]"
	"\n   -s = set serial port device [device=com1]"
	"\n   -i = internet serial forwarder [inet=host:port]"
	"\n   -n = nodeid to send command to [node=nodeid]"
	"\n   -g = group to send command over [group=groupid]"
	"\n   -# = sequence number of command [#=seq_no]"
	"\n"
	"\n   XCommand list:"
	"\n      wake, sleep, reset"
	"\n      set_rate  <interval in millisec>"
	"\n      set_leds  <number from 0-7>"
	"\n      set_sound <0=off|1=on>"
	"\n      red_on,   red_off,   red_toggle"
	"\n      green_on, green_off, green_toggle"
	"\n      yellow_on, yellow_off, yellow_toggle"
	"\n\n"
        );
}

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

                case 'c':
                    g_params.bits.display_cooked = 1;
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

                case 'a':
                    if (argv[argc][2] == '=') {
                        g_am_type = atol(argv[argc]+3);
                    }
                    break;

                case 'g':
                    if (argv[argc][2] == '=') {
                        g_group = atoi(argv[argc]+3);
                    }
                    break;

                case 'n':
                    if (argv[argc][2] == '=') {
                        g_dest = atoi(argv[argc]+3);
                    }
                    break;

                case '#':
                    if (argv[argc][2] == '=') {
                        g_seq_no = atoi(argv[argc]+3);
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
        } else {
	    if (argv[argc]) {
		// processing arguments backwards, so always update command.
		if (g_command) {
		    g_argument = g_command;
		}
		g_command = argv[argc];					
	    }
	}
        argc--;
    } 

    if (!g_params.bits.mode_quiet) {
        // Summarize parameter settings
        printf("xcommand Ver:%s\n", g_version);
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
	xcommand_print_help();
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
        g_ostream = xsocket_port_open();
    } else {
        g_ostream = xserial_port_open();
    }
}

int xmain_get_verbose() {
    return !g_params.bits.mode_quiet;
}

/**
 * The main entry point for the sensor commander console application.
 * 
 * @param     argc            Argument count
 * @param     argv            Argument vector
 *
 * @author    Martin Turon
 * @version   2004/10/3       mturon      Intial version
 */
int main(int argc, char **argv) 
{
    int len = 0;
    unsigned char buffer[255];

    parse_args(argc, argv); 

    if (!g_command) {
	xcommand_print_help();
	exit(2);
    }

    if (!xpacket_get_app(g_am_type)) {
	printf("error: No command table for AM type: %d", g_am_type);
	exit(2);
    }
    XCmdBuilder cmd_bldr = xpacket_get_builder(g_am_type, g_command);
    if (!cmd_bldr) {
	printf("error: Command not found for AM type %d: %s", 
	       g_am_type, g_command);
	exit(2);
    }

    printf("Sending (#%d) %s %s : ", g_seq_no, g_command, g_argument);
    len = xpacket_build_cmd(buffer, cmd_bldr, g_params.bits.mode_socket);

    xpacket_print_raw(buffer, len);
    xserial_port_write_packet(g_ostream, buffer, len);
    
    return 1;
}


//####################### User Manual Follows ##############################

/** 
@mainpage XCommand Documentation

@section version Version 
$Id: xcommand.c,v 1.4 2004/11/11 01:00:51 mturon Exp $

@section usage Usage 
Usage: xcommand <-?|v|q> command argument
@n               <-s=device> <-b=baud> <-i=server:port>
@n               <-n=nodeid> <-g=group> <-#=seq_no> <-a=app AM type>
@n   -? = display help [help]
@n   -q = quiet mode (suppress headers)
@n   -v = show version of all modules
@n   -b = set the baudrate [baud=#|mica2|mica2dot]
@n   -s = set serial port device [device=com1]
@n   -i = internet serial forwarder [inet=host:port]
@n   -n = nodeid to send command to [node=nodeid]
@n   -g = group to send command over [group=groupid]
@n   -a = application or AM type of command message [app=type]
@n   -# = sequence number of command [#=seq_no]
@n
@n   XCommand list:
@n      wake, sleep, reset
@n      set_rate  <interval in millisec>
@n      set_leds  <number from 0-7>
@n      set_sound <0=off|1=on>
@n      red_on,   red_off,   red_toggle
@n      green_on, green_off, green_toggle
@n      yellow_on, yellow_off, yellow_toggle
@n

@section params Parameters

@subsection help -? [help]

XCommand has many modes of operation that can be controlled by passing command line parameters.  The current list of these command line options and a brief usage explanation is always available by passing the -? flag.
@n
@n A detail explanation of each command line option as of version 1.1 follows.


@subsection versions	-v [versions]
     Displays complete version information for all sensorboard decoding modules within xcommand. 

@n $ xcmd -v
@n xcommand Ver: Id: xcommand.c,v 1.1 2004/10/07 19:33:13 mturon Exp 
@n    f8:  Id: cmd_XMesh.c,v 1.4 2004/10/08 00:33:20 mturon Exp 
@n    30:  Id: cmd_XSensor.c,v 1.2 2004/10/07 23:14:25 mturon Exp 
@n    12:  Id: cmd_Surge.c,v 1.1 2004/10/07 19:33:13 mturon Exp 
@n    08:  Id: cmd_SimpleCmd.c,v 1.1 2004/10/07 19:33:13 mturon Exp 

@subsection quiet	-q [quiet]
     This flag suppresses the standard xcommand header which displays the version string and parameter selections. 


@subsection baud -b=baudrate [baud]
     This flag allows the user to set the baud rate of the serial line connection.  The default baud rate is 57600 bits per second which is compatible with the Mica2.  The desired baudrate must be passed as a  number directly after the equals sign with no spaces inbetween, i.e. -b=19200.  Optionally, a product name can be passed in lieu of an actual number and the proper baud will be set, i.e. -b=mica2dot.  Valid product names are:
	mica2          	(57600 baud)
	mica2dot	(19200 baud)


@subsection serial -s=port [serial]
     This flag gives the user the ability to specify which COM port or device xcommand should use.  The default port is /dev/ttyS0 or the UNIX equivalent to COM1.  The given port must be passed directly after the equals sign with no spaces, i.e. -s=com3.  

@subsection internet -i=hostname:port [inet]
     This flag tells xcmd to connect via a serial forwarder over a TCP/IP internet socket.  Specify the hostname and port to connect in the argument.  The default hostname is localhost, and the default port 9001.  The keyword 'mib600' can be passed as an alias to port 10002 when connecting to that hardware device.  The hostname and port must be passed directly after the equals sign with no spaces with a optional colon inbetween, i.e. -i=remote, -i=10.1.1.1:9000, -i=mymib:mib600, -i=:9002, -i=localhost:9003, or -i=stargate.xbow.com.  

@subsection node	-n=nodeid [node]
     This flag specifies which node to send the message to.  When not passed, the broadcast address is used (0xFFFF).

@subsection group	-g=group [group]
     This flag specifies which AM group id to send the message on.  Nodes typically ignore messages for a group which they have not been programmed for, so it is important to pass the correct group here.

@subsection sequence	-#=seq_no [sequence]
     This flag defines the sequence number that will be used for sending the command packet.  The TinyOS Bcast component uses the sequence number to insure that the same command doesn't cycle through the network forever.  Try and increment this number systematically everytime a command message is sent.

@subsection application	-a=am_type [app]
     This flag specifies which AM TOS type to send the message on.  The AM type can be passed as an integer, or as an application name.  For example, Surge sends commands on AM_TYPE=18.  To set the rate of a Surge node, one would use `xcmd -a=18 set_rate`.  The default am_type will work for any application that uses the TinyOS XCommand component, such as XSensor.

@section params Commands

@subsection sleep [XCommand]
     Will tell the mote to stop collecting data and go to sleep.

@subsection wake [XCommand]
     Will wake up a mote and restart data aquisition from the sleep state.

@subsection set_rate [XCommand]
     The set_rate command will change the data aquisition duty cycle of the mote.  The first argument is the new timer interval in milliseconds.

@subsection set_leds [XCommand]
     The set_leds command will actuate all three LEDs of a mote using the following encoding of the first argument: bit 1 = red, bit 2 = green, bit 3 = yellow.  Passing a 7 for instance will turn all the LEDs on, while passing a 0 will turn them all off.

@section building Build Process
     The source code for the xcommand tool is located at: /opt/tinyos-1.x/contrib/xbow/tools/src/xcmd.  
@n@n
    To build the tool, change to the xcmd source directory and run `make`. 
@n@n
    To get the latest version of the source, change to the xcmd source directory and run `cvs update`.  


@section setup Setup

    Xcommand is a command line tool that can be run from a cygwin shell by simply typing `xcmd`.  The executable needs to be in your working path to use it.  A simple way to add Xcommand to your working path is to create a soft link to it by running the following command: 
@n$ ln -s /opt/tinyos-1.x/contrib/xbow/tools/src/xcmd /usr/local/bin/xcmd
@n@n
  You can use Xcommand to actuate subdevices on a mote such as the LEDs, sounder, or relays.  The commands can be sent to either one mote over a serial link, or a wireless network of motes.  In both configurations, you need to have a MIB510 board connected via a serial cable to your PC.
@n@n
    For a single mote configuration, the mote must be programmed with a XSensorMXX### application and plugged into the MIB510.  The mote will listen for command packets over the UART and radio whenever it has power.
@n@n
   For the network of motes configuration, a base station mote needs to be programmed with TOSBase and plugged into the MIB510.  All other motes need to be installed with an XSensorMXX## application and put within range of the base station or a valid multi-hop peer.  Take care to program all the motes to the same frequency and group id.

*/

