
/*
 * The serialization interface used to save / recover objects
 */
includes app_header;

interface Serialize 
{
	command result_t checkpoint(uint8_t *buffer, datalen_t *len);

	command result_t restore(uint8_t *buffer, datalen_t *len);
}
