module AddressM
{
	provides 
	{
		interface IeeeAddress;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{
	command result_t IeeeAddress.create( Ieee_Address *primitive )
	{
		result_t res = call BufferMng.claim(sizeof(ieeeAddress_t), (uint8_t**)primitive);
		if (res == SUCCESS) {
			// Initialize primitive to contain no address.
			(*primitive)->mode = 0;
		}
		return res;
	}
	
	command result_t IeeeAddress.destroy( Ieee_Address primitive )
	{
		return call BufferMng.release(sizeof(ieeeAddress_t), (uint8_t*)primitive);
	}

	command result_t IeeeAddress.setAddrMode( Ieee_Address addr, uint8_t mode )
	{
		addr->mode = mode;
		return SUCCESS;
	}
	
	command result_t IeeeAddress.setPanId( Ieee_Address addr, uint16_t panId )
	{
		if (addr->mode) {
			addr->panId = panId;
			return SUCCESS;
		}
		return FAIL;
	}
	
	command result_t IeeeAddress.setAddress( Ieee_Address addr, uint8_t *address )
	{
		if (addr->mode) {
			memcpy(addr->address, address, 8);
			return SUCCESS;
		}
		return FAIL;
	}

	command uint8_t IeeeAddress.getAddrMode( Ieee_Address addr )
	{
		return addr->mode;
	}
	
	command uint16_t IeeeAddress.getPanId( Ieee_Address addr )
	{
		return addr->panId;
	}
	
	command void IeeeAddress.getAddress( Ieee_Address addr, uint8_t *myAddress )
	{
		memcpy(myAddress, addr->address, 8);
	}
}
