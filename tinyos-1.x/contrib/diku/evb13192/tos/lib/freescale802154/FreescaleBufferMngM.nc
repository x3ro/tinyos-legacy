module FreescaleBufferMngM
{
	provides
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{
	command result_t BufferMng.claim( uint8_t size, uint8_t **buffer )
	{
		*buffer = MM_Alloc(size);
		if (!(*buffer)) {
			return FAIL;
		}
		return SUCCESS;
	}
	
	command result_t BufferMng.release( uint8_t size, uint8_t *buffer )
	{
		MM_Free(buffer);
		return SUCCESS;
	}
}
