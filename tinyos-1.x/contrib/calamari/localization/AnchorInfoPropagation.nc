interface AnchorInfoPropagation
{
  event void overheardManagementMsg();
  command void sendAllAnchors();
  command void stop();
  command void reset();
}
