/* 
 * 8 bit CRC
 */
interface Crc8
{
    command uint8_t crc8(uint8_t *ptr, uint16_t len, uint8_t crc_);
}
