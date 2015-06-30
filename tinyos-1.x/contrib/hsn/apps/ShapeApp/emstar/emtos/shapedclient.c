
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "libdev/status_client.h"
#include "libmisc/misc_buf.h"


#define SHAPED_DEVICE "/dev/shaped/shape"
#define MAX_NET_SIZE 16



status_client_context_t* shaped_status = NULL;


uint16_t shapedclient_write(uint16_t data, uint16_t ids) {
  int fd = open(SHAPED_DEVICE, O_WRONLY);
  int writeme = 0;
  elog(LOG_INFO, "SHAPED CLIENT -> writing data %x, ids %x, combined %x", data, ids, data | ids << 16);
  if (fd < 0) {
    elog(LOG_WARNING, "Unable to open shaped status device for writing!");
    return 0;
  }
  if (g_status_client_set_binary_mode(fd, 1) < 0) {
    elog(LOG_WARNING, "Unable to set binary mode for shaped status device trying write anyways!");
  }
  
  writeme = data | (ids << 16);
  if (write(fd, &writeme, sizeof(int)) != sizeof(int)) {
    elog(LOG_WARNING, "Unable to write bytes to shaped status device!");
    close(fd);
    return 0;
  }

  close(fd);
  return 1;
} 

void shapedclient_read(uint8_t *shape, uint8_t *guess) {
  buf_t *buf = g_status_client_read_once(SHAPED_DEVICE, 1, sizeof(uint8_t) *2);
  uint8_t res[2];
  memcpy(&res, buf->buf, sizeof(uint8_t) *2);
  elog(LOG_INFO, "SHAPED CLIENT -> reading %d, %d", res[0], res[1]);
  *shape = res[0];
  *guess = res[1];
  buf_free(buf);
}


int shapedclient_init() {


  elog(LOG_INFO, "SHAPE CLIENT -> initing");

  /*
  status_client_opts_t opts = {
    devname: SHAPED_DEVICE,
    read_as_ascii: 0
  }

  if (g_status_client_full(&opts, &shaped_status) < 0) {
    elog(LOG_CRIT, "Unable to connect to shaped status device!");
    return 0;
  }
  */

  return 1;

}
