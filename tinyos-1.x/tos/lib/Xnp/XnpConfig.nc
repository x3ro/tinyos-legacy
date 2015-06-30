// $Id: XnpConfig.nc,v 1.3 2003/10/07 21:46:27 idgay Exp $


// XnpConfig interface: allow querying of the current Xnp state without
// requiring a client module to respond to NPX_DOWNLOAD_REQ.

interface XnpConfig
{
  command uint16_t getProgramID();
  command void saveGroupID();
}

