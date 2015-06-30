//$Id: GroupManagerC.nc,v 1.4 2005/07/16 01:27:15 gtolle Exp $

includes Attrs;

/**
 * This component holds a list of groups that have been joined, and
 * provides functions to look up, join, and leave groups.
 *
 * @author Gilman Tolle
 */
configuration GroupManagerC {
  provides {
    interface StdControl;
    interface GroupManager;
  }
}
implementation {
  components GroupManagerM;
  components TimerC;

  StdControl = GroupManagerM;
  GroupManager = GroupManagerM;

  GroupManagerM.Timer -> TimerC.Timer[unique("Timer")];
}
