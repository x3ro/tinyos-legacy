includes NCS;


/**
 * Blocking (NCSLib) version of contour finding.
 */
configuration Contour {
} implementation {
  components Main, ContourM, FiberC, NCSLibC, LedsC;

  Main.StdControl -> ContourM;

  ContourM.Fiber -> FiberC;
  ContourM.NCSLib -> NCSLibC;
  ContourM.NCSSensor -> NCSLibC.NCSSensor[NCS_SENSOR_PHOTO];
  ContourM.NCSNeighborhood -> NCSLibC.NCSRadioNeighborhood;
  ContourM.NCSLocation -> NCSLibC;
  ContourM.SV_location -> NCSLibC.NCSSharedVar[0];
  ContourM.SV_belowset -> NCSLibC.NCSSharedVar[1];
  ContourM.Leds -> LedsC;
}

