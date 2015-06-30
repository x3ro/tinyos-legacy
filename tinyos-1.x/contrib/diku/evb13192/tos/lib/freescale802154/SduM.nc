module SduM
{
	provides
	{
		interface IeeeMacSdu as IeeeSdu;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{
	command result_t IeeeSdu.create( Ieee_Msdu *msdu )
	{
		return call BufferMng.claim(sizeof(fsSdu_t), (uint8_t**)msdu);
	}
	
	command result_t IeeeSdu.destroy( Ieee_Msdu msdu )
	{
		if (msdu->bufferDestroyable) {
			call BufferMng.release(msdu->bufferLen, msdu->buffer);
		}
		return call BufferMng.release(sizeof(fsSdu_t), (uint8_t*)msdu);
	}
	
	/** Get a pointer for the beginning of the sdu payload **/
	command uint8_t* IeeeSdu.getPayload(Ieee_Msdu msdu)
	{
		return msdu->payload;
	}
	/** Get the length of the sdu payload **/
	command uint8_t IeeeSdu.getPayloadLen(Ieee_Msdu msdu)
	{
		return msdu->payloadLen;
	}
	
	/** Set a pointer for the beginning of the sdu payload **/
	command void IeeeSdu.setPayload(Ieee_Msdu msdu, uint8_t *payload, uint8_t length)
	{
		msdu->payload = payload;
		msdu->buffer = payload;
		msdu->bufferLen = length;
		msdu->payloadLen = length;
		msdu->bufferDestroyable = TRUE;
	}
}
