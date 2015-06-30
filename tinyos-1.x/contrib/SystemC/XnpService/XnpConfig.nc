
// XnpConfig interface: allow querying of the current Xnp state without
// requiring a client module to respond to NPX_DOWNLOAD_REQ.

interface XnpConfig
{
  command uint16_t getProgramID();
  command void saveGroupID();
}

