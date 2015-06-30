  inline uint16_t htons( uint16_t val )
  {
    // The MSB is little-endian; network order is big
    return ((val & 0xff) << 8) | ((val & 0xff00) >> 8);
  }

  inline uint16_t ntohs( uint16_t val )
  {
    // The MSB is little-endian; network order is big
    return ((val & 0xff) << 8) | ((val & 0xff00) >> 8);
  }

  inline void htonl( uint32_t val, uint8_t *dest )
  {
    dest[0] = (val & 0xff000000) >> 24;
    dest[1] = (val & 0x00ff0000) >> 16;
    dest[2] = (val & 0x0000ff00) >> 8;
    dest[3] = (val & 0x000000ff);
  }

  inline uint32_t ntohl( uint8_t *src )
  {
    return (((uint32_t) src[0]) << 24) | (((uint32_t) src[1]) << 16) |
      (((uint32_t) src[2]) << 8) | (((uint32_t) src[3]));
  }
