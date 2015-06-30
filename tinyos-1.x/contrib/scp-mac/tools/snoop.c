/*
 * Copyright (C) 2003-2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Author: Wei Ye, Eric Osterweil
 *
 * This program captures all packets sent by snooper, and display them
 * To be used with the snooper at apps/snooper/SNOOPER.c
 * The first byte is packet length
 *
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <strings.h>
#include <errno.h>
#include <inttypes.h>

#define MAX_LENGTH 250
#define BAUDRATE_MICA B19200 // baudrate for Mica
#define BAUDRATE_MICA2 B57600 // baudrate for Mica2
#define BAUDRATE_MICAZ B115200 // baudrate for MicaZ
//#define SERIAL_DEVICE "/dev/ttyS%c" //the port to use.
#define DEFAULT_DEVICE "/dev/ttyS0" // default serial device

int input_stream;
char input_buffer[MAX_LENGTH];
long startTime;
struct timeval timeStamp;

unsigned char pktLen = 0; // packet length

void print_usage(void);
void print_packet( int p_iLineLen,
                   int p_iEnableCrc,
                   uint16_t p_uiCrc );
uint16_t read_packet(void);
int setSerial( char *p_szPlatform,
               struct termios *p_pNewtio );
int16_t update_crc(char data, int16_t crc);

#define NUM_PLATFORMS 3
// don't change the order of platforms
static char *g_szPlatforms[NUM_PLATFORMS] = { "mica", "mica2", "micaz" };
int platformId = NUM_PLATFORMS;

int iEnableCrc = 1;  // CRC is enabled by default

int main( int argc, char *argv[ ] )
{
  int iRet = 0;
  int iLineLen = 80;
  int iError = 0;
  int iTimeout = 1;
  fd_set tFdSet;
  struct timeval tTimeVal;
  int iArg = 0;
  char szOpts[ ] = { "p:d:t:l:c:h" };
//  char *szDev = "0";
  char *szPlatform = NULL;
//  char *szSerial = ( char * ) malloc( sizeof( char ) * strlen( SERIAL_DEVICE ) );
  char *szSerial = NULL;
  char *crcCheck = NULL;
  struct termios newtio;
  uint16_t uiCrc = 0x00;
  char *crcOptions[2] = { "crc", "nocrc" };  // don't change order

  while ( EOF != ( iArg = getopt( argc, argv, szOpts ) ) )
  {
    switch ( iArg )
    {
      case 'p':
        szPlatform = optarg;
        break;
      case 'd':
        szSerial = optarg;
        break;
      case 't':
        iTimeout = atoi( optarg );
        break;
      case 'l':
        iLineLen = atoi( optarg );
        break;
      case 'c':
        crcCheck = optarg;
        break;
      case 'h':
        print_usage();
        return 1;
      default:
        print_usage();
        return 1;
    }
  }

  // check platform
  if ( NULL == szPlatform ) {
    printf("No platform specified!\n");
    print_usage();
    return 1;
  } else {
    // validate specified platform
    int i;
    for (i = 0; i < NUM_PLATFORMS; i++) {
      if (strcmp(szPlatform, g_szPlatforms[i]) == 0 ) { // found platform
        platformId = i;
        break;
      }
    }
    if (platformId < NUM_PLATFORMS) { // valid platform
      printf("Platform: %s\n", szPlatform);
    } else {
      printf("Invalid platform!\n");
      print_usage();
      return 1;
    }
  }

  // check serial device
  if ( szSerial == NULL ) {
    // will use default device
    szSerial = DEFAULT_DEVICE;
    printf("Serial device: default %s\n", szSerial);
    printf("  To change device, see 'snoop -h'.\n");
  } else {
    printf("Serial device: %s\n", szSerial);
  }
  
  // check if CRC check is required
  if (crcCheck != NULL) {  // user specified CRC option
    if (strcmp(crcCheck, crcOptions[0]) == 0) {  // CRC enabled
      iEnableCrc = 1;
    } else if (strcmp(crcCheck, crcOptions[1]) == 0) { // CRC disabled
      iEnableCrc = 0;
    } else {
      printf("Invalid CRC option!\n");
      print_usage();
      return 1;
    }
  }
    
  if (iEnableCrc == 1) {
    if (platformId == 2) {  // micaz
      iEnableCrc = 0;
      printf("CRC: disabled\n");
      printf("  Can't check CRC for micaz, as its radio changes CRC bytes.\n");
    } else {
      printf("CRC: enabled\n");
    }
  } else {
    printf("CRC: disabled\n");
  }
    
  bzero( &newtio, sizeof( newtio ) );
  
  /* open input_stream for read/write */ 
  if ( -1 == ( input_stream = open( szSerial, O_RDWR|O_NOCTTY ) ) ) {
    printf( "Input_stream open %s failed!\n",
            szSerial );
    printf("  Possible reasons: \n");
    printf("    1. The device name is wrong.\n");
    printf("    2. The device does not exist.\n");
    printf("    2. You have no permission to open the device.\n" );
    return 1;
  }
  
  if ( 0 != setSerial( szPlatform, &newtio ) ) {
    fprintf( stderr, "Unable to initialize device.\n" );
    return 1;
  }
  else
  {
    struct timeval sTime;
    time_t timep;
    tcflush(input_stream, TCIFLUSH);
    tcsetattr(input_stream, TCSANOW, &newtio);
    //printf("input_stream opens ok\n");
    // record starting time
    timep = time(NULL);
    printf("Snooper starts at %s\n", ctime(&timep));
    gettimeofday(&sTime, NULL);  // starting time for time stamping
    startTime = sTime.tv_sec;

    while( 1 )
    {
      FD_ZERO( &tFdSet );
      FD_SET( input_stream, &tFdSet );

      tTimeVal.tv_sec = iTimeout;
      tTimeVal.tv_usec = 0;

      iError = select( input_stream + 1,
                       &tFdSet,
                       NULL,
                       NULL,
                       &tTimeVal );
      if ( iError > 0
           && FD_ISSET( input_stream, &tFdSet ) )
      {
        uiCrc = 0x00;
        uiCrc = read_packet( );
        print_packet( iLineLen,
                      iEnableCrc,
                      uiCrc );
      }
    }
  }

  return 0;
}

void print_usage( )
{
  //usage...
  printf( "Usage: snoop -p < mica | mica2 | micaz > \n" );
  printf( "             [ -d <serial_device_name> ]\n" );
  printf( "             [ -t <select_timeout> ]\n" );
  printf( "             [ -l <wrap-arround_line_length> ]\n" );
  printf( "             [ -c < crc | nocrc > ]\n" );
  printf( "             [ -h ]\n" );
}


uint16_t read_packet()
{
	int i, count = 0;
  int j = 0;
  int16_t uiCrc = 0;
	bzero(input_buffer, MAX_LENGTH);
	//search through to find 0x7e signifing the start of a packet
	while(input_buffer[0] != (char)0x7e){
		while(1 != read(input_stream, input_buffer, 1)){};
	} 
	// have start symbol now, get time stamp
    gettimeofday(&timeStamp, NULL);

    // read in rest of packet
    input_buffer[0] = 0;
	while(1 != read(input_stream, input_buffer, 1)){
	}
	pktLen = input_buffer[0];
	if (pktLen == 0 || pktLen > MAX_LENGTH)	return;
	count = 1;
	while(count < pktLen) {
		count += read(input_stream, input_buffer + count, pktLen - count); 	
	}

  for ( j = 0; j < count - 2; j++ )
  {
    uiCrc = update_crc( input_buffer[ j ],
                        uiCrc );
  }

  return uiCrc;
}

void print_packet( int p_iLineLen,
                   int p_iEnableCrc,
                   uint16_t p_uiCrc )
{
  //now print out the packet
  int i;
  char *szFormat = " %02X";
  int iLen = 3;
  uint16_t uiCrc = 0;
  long totalTime;
  uint8_t hours, minutes, seconds;
  uint16_t milisec;

  // show time stamp relative to when the snooper starts
  totalTime = timeStamp.tv_sec - startTime; // total seconds
  seconds = (uint8_t)(totalTime % 60);
  totalTime = (totalTime - seconds) / 60;   // total minutes
  minutes = (uint8_t)(totalTime % 60);
  totalTime = (totalTime - minutes) / 60;   // total hours
  hours = (uint8_t)(totalTime);
  milisec = (uint16_t)(timeStamp.tv_usec/1000);
  printf("At %02d:%02d:%02d.%03d", 
     hours, minutes, seconds, milisec);

  if ( pktLen == 0
       || pktLen > MAX_LENGTH )
  {
    printf(" LENGTH ERROR\n");
  }
  else
  {
    if ( 1 == p_iEnableCrc )
    {
      memcpy( &uiCrc,
              &input_buffer[ pktLen - 2 ],
              sizeof( uint16_t ) );
      if ( p_uiCrc != uiCrc )
      {
        printf( " CRC ERROR");
      }
    }
    for(i = 0; i < pktLen; i ++){
      if ( 0 == ( i  % ( p_iLineLen / iLen ) ) )
      {
        printf("\n");
      }
      printf( szFormat,
              input_buffer[i] & 0xFF );
    }
    printf( "\n" );
  }

  fflush( stdout );
} 

int setSerial( char *p_szPlatform,
               struct termios *p_pNewtio )
{
  int iRet = 0;
  

   
  if ( NULL == p_szPlatform )
  {
    fprintf( stderr,
             "Unable to use NULL platform.\n" );
    iRet = -1;
  }
  else if ( 0 == strcmp( p_szPlatform,
                         g_szPlatforms[ 0 ] ) )  // mica
  {
    p_pNewtio->c_cflag = CS8 | CLOCAL | CREAD;
    	cfsetispeed(p_pNewtio, BAUDRATE_MICA);
	cfsetospeed(p_pNewtio, BAUDRATE_MICA);

  }
  else if ( 0 == strcmp( p_szPlatform,
                         g_szPlatforms[ 1 ] ) )  // mica2
  {
    p_pNewtio->c_cflag = CS8 | CLOCAL | CREAD;
    	cfsetispeed(p_pNewtio, BAUDRATE_MICA2);
	cfsetospeed(p_pNewtio, BAUDRATE_MICA2);

  }
  else if ( 0 == strcmp( p_szPlatform,
                         g_szPlatforms[ 2 ] ) )  // micaz
  {
    p_pNewtio->c_cflag = CS8 | CLOCAL | CREAD;
    	cfsetispeed(p_pNewtio, BAUDRATE_MICAZ);
	cfsetospeed(p_pNewtio, BAUDRATE_MICAZ);

    iEnableCrc = 0;  // disable CRC check, as CC2420 changes the CRC bytes
  }
  else
  {
    perror("Unknown platform!\n");
    iRet = -1;
  }

printf("Input baud rate changed to %d\n", (int) cfgetispeed(p_pNewtio));
printf("Output baud rate changed to %d\n", (int) cfgetispeed(p_pNewtio));
  if ( 0 == iRet )
  {
    p_pNewtio->c_iflag = IGNPAR;

    /* Raw output_file */
    p_pNewtio->c_oflag = 0;
  }

  return iRet;
}

int16_t update_crc(char data, int16_t crc)
{
  char i;
  int16_t tmp;
  tmp = (int16_t)(data);
  crc = crc ^ (tmp << 8);
  for (i = 0; i < 8; i++) {
    if (crc & 0x8000)
       crc = crc << 1 ^ 0x1021;  // << is done before ^
    else
       crc = crc << 1;
    }
  return crc;
}

