configuration AMOrControllerImpl {
  provides interface ServiceControl[uint8_t id];
}
implementation {
  components ServiceOrController("ActiveMessageServiceOrController$Control");
  components ActiveMessagesImpl;
  
  ServiceControl = ServiceOrController;
  ServiceOrController.SubControl -> ActiveMessagesImpl;
}



