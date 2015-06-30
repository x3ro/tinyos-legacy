includes endianconv;
module PanDescriptorM
{
	provides 
	{
		interface IeeePanDescriptor;
	}
}
implementation
{	
	command void IeeePanDescriptor.getCoordAddr( Ieee_PanDescriptor panDescriptor,
	                                             Ieee_Address coordAddr )
	{
		panDescriptor_t* pd = panDescriptor;
		coordAddr->mode = pd->coordAddrMode;
		NTOUHCPY16(pd->coordPanId, (uint8_t*)(&coordAddr->panId));
		if (coordAddr->mode == 2) {
			NTOUHCPY16(pd->coordAddress, coordAddr->address);
		} else {
			NTOUHCPY64(pd->coordAddress, coordAddr->address);
		}
	}
	
	command uint8_t IeeePanDescriptor.getLogicalChannel( Ieee_PanDescriptor panDescriptor )
	{
		panDescriptor_t* pd = panDescriptor;
		return pd->logicalChannel;
	}
	
	command uint16_t IeeePanDescriptor.getSuperframeSpec( Ieee_PanDescriptor panDescriptor )
	{
		panDescriptor_t* pd = panDescriptor;
		return NTOUH16(((uint16_t*)pd->superFrameSpec)[0]);
	}
	
	command bool IeeePanDescriptor.getGtsPermit( Ieee_PanDescriptor panDescriptor )
	{
		panDescriptor_t* pd = panDescriptor;
		return pd->gtsPermit;
	}
	
	command uint8_t IeeePanDescriptor.getLinkQuality( Ieee_PanDescriptor panDescriptor )
	{
		panDescriptor_t* pd = panDescriptor;
		return pd->linkQuality;
	}
	
	command uint32_t IeeePanDescriptor.getTimeStamp( Ieee_PanDescriptor panDescriptor )
	{
		uint32_t timestamp = 0;		
		panDescriptor_t* pd = panDescriptor;
		// Stupid freescale 24 bit timestamp :(
		timestamp = pd->timeStamp[0];
		timestamp = timestamp << 8;
		timestamp |= pd->timeStamp[1];
		timestamp = timestamp << 8;
		timestamp |= pd->timeStamp[2];
		return timestamp;
	}
	
	command bool IeeePanDescriptor.getSecurityUse( Ieee_PanDescriptor panDescriptor )
	{
		panDescriptor_t* pd = panDescriptor;
		return pd->securityUse;
	}
	
	command uint8_t IeeePanDescriptor.getAclEntry( Ieee_PanDescriptor panDescriptor )
	{
		panDescriptor_t* pd = panDescriptor;
		return pd->aclEntry;
	}
	
	command bool IeeePanDescriptor.getSecurityFailure( Ieee_PanDescriptor panDescriptor )
	{
		panDescriptor_t* pd = panDescriptor;
		return pd->securityFailure;
	}
}
