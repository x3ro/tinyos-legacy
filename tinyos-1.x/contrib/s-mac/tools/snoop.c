/* snoop.c                                         tab:4
 *
 * To be used with apps/snooper/SNOOPER.c
 * Similar to listen.c but support different length of packet.
 * The first byte is packet length
 *
 * Author: Wei Ye, Eric Osterweil
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
#define SERIAL_DEVICE "/dev/ttyS%c" //the port to use.

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

static char *g_szPlatforms[ 2 ] = { "mica", "mica2" };

int main( int argc, char *argv[ ] )
{
  int iRet = 0;
  int iLineLen = 80;
  int iError = 0;
  int iTimeout = 1;
  int iEnableCrc = 1;
  fd_set tFdSet;
  struct timeval tTimeVal;
  int iArg = 0;
  char szOpts[ ] = { "t:d:l:p:c" };
  char *szDev = "0";
  char *szPlatform = NULL;
  char *szSerial = ( char * ) malloc( sizeof( char ) * strlen( SERIAL_DEVICE ) );
  struct termios newtio;
  uint16_t uiCrc = 0x00;

  while ( EOF != ( iArg = getopt( argc, argv, szOpts ) ) )
  {
    switch ( iArg )
    {
      case 't':
        iTimeout = atoi( optarg );
        break;
      case 'd':
        if ( NULL != optarg )
        {
          szDev = optarg;
        }
        break;
      case 'l':
        iLineLen = atoi( optarg );
        break;
      case 'p':
        szPlatform = optarg;
        break;
      case 'c':
        iEnableCrc = 0;
        break;
      default:
        print_usage();
        break;
    }
  }

  bzero( &newtio,
         sizeof( newtio ) );
  bzero( szSerial,
         strlen( SERIAL_DEVICE ) );
  sprintf( szSerial,
           SERIAL_DEVICE,
           szDev[ 0 ] );
  if ( NULL == szPlatform )
  {
    print_usage();
    iRet = 1;
  }
  /* open input_stream for read/write */ 
  else if ( -1 == ( input_stream = open( szSerial, O_RDWR|O_NOCTTY ) ) )
  {
    printf( "Input_stream open %s failed!\n",
            szSerial );
    printf( "Make sure the user has permission to open device.\n" );
    iRet = 1;
  }
  else if ( 0 != setSerial( szPlatform, &newtio ) )
  {
    fprintf( stderr,
             "Unable to init serial.\n" );
    iRet = 1;
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

  return iRet;
}

void print_usage( )
{
  //usage...
  printf( "Usage: snoop -p < mica | mica2 > [ -t <select_timeout> ]\n" );
  printf( "             [ -d <serial_device_number> ]\n" );
  printf( "             [ -l <wrap-arround_line_length> ]\n" );
  printf( "             [ -c ]\n" );
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
  else if ( NULL == p_pNewtio )
  {
    fprintf( stderr,
             "Unable to use NULL termios structure.\n" );
    iRet = -1;
  }
  else if ( 0 == strcmp( p_szPlatform,
                         g_szPlatforms[ 0 ] ) )
  {
    p_pNewtio->c_cflag = BAUDRATE_MICA | CS8 | CLOCAL | CREAD;
  }
  else if ( 0 == strcmp( p_szPlatform,
                         g_szPlatforms[ 1 ] ) )
  {
    p_pNewtio->c_cflag = BAUDRATE_MICA2 | CS8 | CLOCAL | CREAD;
  }
  else
  {
    perror("Unknown platform!\n");
    iRet = -1;
  }

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

