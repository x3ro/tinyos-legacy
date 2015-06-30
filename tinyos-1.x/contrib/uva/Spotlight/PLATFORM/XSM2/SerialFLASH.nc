/*	
 * 
 */

interface SerialFLASH
{
  command result_t check_flash();
  command result_t write_flash_block(char *buf);
  command result_t read_flash_block(char *buf);
}

