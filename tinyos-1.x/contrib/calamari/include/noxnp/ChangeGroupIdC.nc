
configuration ChangeGroupIdC
{
}
implementation
{
  components ChangeGroupIdM
           , SystemGenericCommC as Comm
    //	   , XnpC
	   ;
  
  ChangeGroupIdM.ReceiveMsg -> Comm.ReceiveMsg[ AM_CHANGE_GROUP_ID ];
  //  ChangeGroupIdM.XnpConfig -> XnpC;
}

