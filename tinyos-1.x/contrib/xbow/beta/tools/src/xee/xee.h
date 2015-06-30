#ifndef xeeHedit
#define xeeHedit 1


#include <stdio.h>
#include <ctype.h>
#include "config.h"

// Debug control
extern int debugLevel;

#define bool int

enum boolean{false,true};

void xcrc_set(char *packet, int length);


/* Sensorboard data packet definitions */
void xpacket_print_raw     (unsigned char *tos_packet, int len);
void xpacket_print_parsed  (unsigned char *tos_packet, int len);
void xpacket_print_cooked  (unsigned char *tos_packet, int len);

/* Serial port routines. */
int xserial_port_open ();
int xserial_port_close(int serline); 
int xserial_port_dump ();
int xserial_port_sync_packet (int serline);
int xserial_port_read_packet (int serline, unsigned char *buffer);

unsigned xserial_set_baudrate (unsigned baudrate);
unsigned xserial_set_baud     (const char *baud);
void     xserial_set_device   (const char *device);
void     xserial_set_verbose  (int verbose);


#endif
