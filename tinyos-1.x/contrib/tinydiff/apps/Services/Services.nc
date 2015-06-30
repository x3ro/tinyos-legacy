////////////////////////////////////////////////////////////////////////////
//
// CENS
//
// Contents: 
//
// Purpose: 
//
////////////////////////////////////////////////////////////////////////////
//
// $Id: Services.nc,v 1.2 2003/06/23 23:19:36 mmysore Exp $
//
// $Log: Services.nc,v $
// Revision 1.2  2003/06/23 23:19:36  mmysore
// Fix to make tinydiff work with latest TinyOS cvs.  The new sensorIB stuff is
// (somehow :-> ) compatible with the latest mica2 stack code on cvs.
//
// Revision 1.2  2003/05/09 00:28:22  mmysore
// Small changes to Services and diffsink
//
// Revision 1.1  2003/05/08 21:00:48  eoster
// Initial checkin.
//
////////////////////////////////////////////////////////////////////////////

configuration Services
{

}
implementation
{
  components Main,
             ServicesM,
             SamplerC,
             EssM,
             EssFilterM,
             NeighborStoreM,
             TimerC,
//             CC1000ControlM,
             ExtGenericComm as GenericComm,
             RandomLFSR,
             TxManC,
             OnePhasePullNlist as OPP;

  Main.StdControl -> ServicesM.StdControl;
  Main.StdControl -> EssM.StdControl;
  Main.StdControl -> EssFilterM.StdControl;
  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> GenericComm.Control;
  Main.StdControl -> TxManC.Control;
  Main.StdControl -> OPP.StdControl;
//  Main.StdControl -> CC1000ControlM.StdControl;

  ServicesM.SamplerControl -> SamplerC.SamplerControl;
  ServicesM.Sample -> SamplerC.Sample;

  ServicesM.EssState -> EssM.EssState;
  ServicesM.EssComm -> EssM.EssComm;

  EssM.Timer -> TimerC.Timer[ unique( "Timer" ) ];
  EssM.ReadNeighborStore -> NeighborStoreM.ReadNeighborStore;
  EssM.Publish -> OPP.Publish;

  EssFilterM.Filter -> OPP.Filter[ 0 ];
  EssFilterM.EssState -> EssM.EssState;
}
