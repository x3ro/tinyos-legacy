configuration DelugeMonitorC {
  provides interface StdControl;
  
}
implementation {
  components DelugeMonitorM, MgmtAttrsC, DelugeMetadataC;

  StdControl = DelugeMonitorM;

  DelugeMonitorM.DelugeMetadata -> DelugeMetadataC.Metadata;

  DelugeMonitorM.MA_DownloadingImg -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  DelugeMonitorM.MA_DownloadingImgPageNum -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  DelugeMonitorM.MA_DownloadingImgTotalPages -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];  
  DelugeMonitorM.MA_ImgSummary -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];  
}
