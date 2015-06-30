generic configuration AMController {
  provides interface ServiceControl;
}
implementation {
  components AMOrControllerImpl;

  ServiceControl -> AMOrControllerImpl.ServiceControl[unique("ActiveMessageServiceOrController$Control")];
  
}


