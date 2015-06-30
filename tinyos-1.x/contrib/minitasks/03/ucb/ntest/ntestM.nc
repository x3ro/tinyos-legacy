

//!! MagHood = CreateNeighborhood ( 4, ntestM, GenericCommBackend, 10);
//!! MagReadingAttr = CreateAttribute (uint8_t = 0xff);
//!! MagDataRefl = CreateReflection (MagHood, MagReadingAttr, TRUE, 11, 12);
module ntestM
{
  provides {
    interface NeighborhoodManager;
    interface StdControl;
  }
  
  uses {
    interface Neighborhood;
    interface MagHood_private;

    interface MagReadingAttr;
    interface MagReadingAttrReflection;
    interface MagReadingAttrReflectionSnoop;
  }
}
implementation {
  
  command result_t StdControl.init()
    {
      dbg(DBG_USR2, "Hooyea: my tos-local-addr %d!\n", TOS_LOCAL_ADDRESS); 
      return SUCCESS;
    }

  task void go()
    {
      int i = 0;
      nodeID_t id;
      uint8_t val;
      
      call MagReadingAttr.set (TOS_LOCAL_ADDRESS);
      //      call MagReadingAttrReflection.push();

      for (; i < 4; i++) {
        id = call Neighborhood.getNeighbor(i);
        val = call MagReadingAttrReflection.pull (id);
        dbg(DBG_USR2, "Got a value: %d with value %d\n", i, id);
      }
    }
  
  
  command result_t StdControl.start()
    {
      post go();
      return SUCCESS;
      
    }


  command result_t StdControl.stop()
    {
      return SUCCESS;
    }

  command void NeighborhoodManager.prune()
  {
  }

  command void NeighborhoodManager.pushManagementInfo()
  {
    call MagReadingAttrReflection.push();
  }

  command void NeighborhoodManager.pullManagementInfo()
  {
    //call MagDataRefl.pull( POTENTIAL_NEIGHBORS );
  }

  event void MagReadingAttr.updated(  )
    {
    }

  
  event void MagReadingAttrReflection.updated( nodeID_t id, uint8_t value )
    {
      
    }

  event void Neighborhood.removingNeighbor( nodeID_t id )
    {
    }
  event void Neighborhood.addedNeighbor( nodeID_t id )
    {
    }

  event void MagReadingAttrReflectionSnoop.updatedNAN(
                                     RoutingDestination_t src, uint8_t value )
    {
      dbg(DBG_USR2, "Got a value: %d\n", value);
    }

}
