//$Id: DelugeStatsM.nc,v 1.2 2005/06/14 18:22:21 gtolle Exp $

includes Deluge;
includes DelugeMetadata;

module DelugeStatsM {
  provides interface AttrList<pgnum_t> as DelugeTotalPages
    @nucleusAttr("DelugeTotalPages");
  provides interface AttrList<pgnum_t> as DelugeCompletedPages
    @nucleusAttr("DelugeCompletedPages");
  provides interface AttrList<imgvnum_t> as DelugeImageVersion
    @nucleusAttr("DelugeImageVersion");

  uses interface DelugeStats;
}
implementation {
  
  command result_t DelugeTotalPages.get(pgnum_t* buf, uint8_t pos) {
    pgnum_t numPgs;

    if (pos >= DELUGE_NUM_IMAGES)
      return FAIL;

    numPgs = call DelugeStats.getNumPgs(pos);
    memcpy(buf, &numPgs, sizeof(pgnum_t));
    signal DelugeTotalPages.getDone(buf);
    return SUCCESS;
  }
  command result_t DelugeCompletedPages.get(pgnum_t* buf, uint8_t pos) {
    pgnum_t numPgs;

    if (pos >= DELUGE_NUM_IMAGES)
      return FAIL;

    numPgs = call DelugeStats.getNumPgsComplete(pos);
    memcpy(buf, &numPgs, sizeof(pgnum_t));
    signal DelugeCompletedPages.getDone(buf);
    return SUCCESS;
  }
  command result_t DelugeImageVersion.get(imgvnum_t* buf, uint8_t pos) {
    imgvnum_t vNum;

    if (pos >= DELUGE_NUM_IMAGES)
      return FAIL;

    vNum = call DelugeStats.getVNum(pos);
    memcpy(buf, &vNum, sizeof(imgvnum_t));
    signal DelugeImageVersion.getDone(buf);
    return SUCCESS;
  }
}
