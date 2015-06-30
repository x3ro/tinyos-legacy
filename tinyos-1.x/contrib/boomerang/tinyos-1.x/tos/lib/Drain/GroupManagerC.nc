//$Id: GroupManagerC.nc,v 1.1.1.1 2007/11/05 19:09:10 jpolastre Exp $

/**
 * This component holds a list of groups that have been joined, and
 * provides functions to look up, join, and leave groups.
 *
 * @author Gilman Tolle <get@cs.berkeley.edu>
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
