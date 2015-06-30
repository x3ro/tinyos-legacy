#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "sfsource.h"

int saferead(int fd, void *buffer, int count)
{
  int actual = 0;

  while (count > 0)
    {
      printf("\n>>> socket reading ");
      int n = read(fd, buffer, count);
      printf(" ... %i read\n ", count);

      if (n == -1 && errno == EINTR)
	continue;
      if (n == -1)
	return -1;
      if (n == 0)
	return actual;

      count -= n;
      actual += n;
      buffer += n;
    }
  return actual;
}

int safewrite(int fd, const void *buffer, int count)
{
  int actual = 0;

  while (count > 0)
    {
      int n = write(fd, buffer, count);

      if (n == -1 && errno == EINTR)
	continue;
      if (n == -1)
	return -1;

      count -= n;
      actual += n;
      buffer += n;
    }
  return actual;
}

int open_sf_source(const char *host, int port)
/* Returns: file descriptor for serial forwarder at host:port
 */
{
  int fd = socket(AF_INET, SOCK_STREAM, 0);
  struct hostent *entry;
  struct sockaddr_in addr;

  if (fd < 0)
    return fd;

  entry = gethostbyname(host);
  if (!entry)
    {
      close(fd);
      return -1;
    }      

  addr.sin_family = entry->h_addrtype;
  memcpy(&addr.sin_addr, entry->h_addr, entry->h_length);
  addr.sin_port = htons(port);
  if (connect(fd, (struct sockaddr *)&addr, sizeof addr) < 0)
    {
      close(fd);
      return -1;
    }

  if (init_sf_source(fd) < 0)
    {
      close(fd);
      return -1;
    }

  return fd;
}

extern int platform; 

int init_sf_source(int fd)
/* Effects: Checks that fd is following the serial forwarder protocol
   Returns: 0 if it is, -1 otherwise
 */
{
  char check[2];
  char nonce[6];
  /* Indicate version and check if serial forwarder on the other end
     (life is easy as we're the earliest protocol version) */
  nonce[0] = 'T'; nonce[1] = ' ';
  nonce[2] = (char)  (platform        & 0xff);
  nonce[3] = (char) ((platform >>  8) & 0xff);
  nonce[4] = (char) ((platform >> 16) & 0xff);
  nonce[5] = (char) ((platform >> 24) & 0xff);
  printf("initializing SF source...\n");
  if (safewrite(fd, nonce, 6) != 6) {
     return -1;
  }
  printf("wrote identifier...\n");
  if (saferead(fd, check, 6) != 6) {
    return -1;
  }
  printf("read reply...\n");
  if (check[0] != 'T' || check[1] < ' ') {
    return -1;
  }
  printf("reply passed.\n");

  return 0;
}

void *read_sf_packet(int fd, int *len)
/* Effects: reads packet from serial forwarder on file descriptor fd
   Returns: the packet read (in newly allocated memory), and *len is
     set to the packet length, or NULL for failure
*/
{
  unsigned char l;
  void *packet;

  if (saferead(fd, &l, 1) != 1)
    return NULL;
  
  printf("read header: packet will be %i bytes long.\n", (int)l);
  packet = malloc(l);
  if (!packet)
    return NULL;

  if (saferead(fd, packet, l) != l)
    {
      printf("packet read SHORT\n");
      free(packet);
      return NULL;
    }
  printf("read packet of %i bytes.\n", (int)l);
  *len = l;
  
  return packet;
}

int write_sf_packet(int fd, const void *packet, int len)
/* Effects: writes len byte packet to serial forwarder on file descriptor
     fd
   Returns: 0 if packet successfully written, -1 otherwise
*/
{
  unsigned char l = len;

  if (safewrite(fd, &l, 1) != 1 ||
      safewrite(fd, packet, l) != l)
    return -1;

  return 0;
}
