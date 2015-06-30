#ifndef _SHAPED_CLIENT_H
#define _SHAPED_CLIENT_H

uint16_t shapedclient_write(uint16_t data, uint16_t ids);
void shapedclient_read(uint8_t *shape, uint8_t* guess);
int shapedclient_init();

#endif
