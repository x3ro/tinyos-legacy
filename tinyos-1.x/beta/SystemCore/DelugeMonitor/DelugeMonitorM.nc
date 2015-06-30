module DelugeMonitorM {
  provides interface StdControl;
  uses {
    interface DelugeMetadata;
    interface NetProg;

    interface MgmtAttr as MA_DownloadingImg;
    interface MgmtAttr as MA_DownloadingImgPageNum;
    interface MgmtAttr as MA_DownloadingImgTotalPages;
    interface MgmtAttr as MA_ImgSummary;
  } 
}
implementation {

  uint8_t runningImgNum;
  uint8_t currentSeqno;
  uint8_t simpleReboot = FALSE;

  command result_t StdControl.init() {
    call MA_DownloadingImg.init(sizeof(uint8_t), MA_TYPE_UINT);
    call MA_DownloadingImgPageNum.init(sizeof(uint8_t), MA_TYPE_UINT);
    call MA_DownloadingImgTotalPages.init(sizeof(uint8_t), MA_TYPE_UINT);
    call MA_ImgSummary.init(8, MA_TYPE_OCTETSTRING);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t MA_DownloadingImg.getAttr(uint8_t *buf) {
    uint8_t imgNum = call DelugeMetadata.getNextIncompleteImage();

    if (imgNum == DELUGE_INVALID_IMGNUM)
      memset(buf, 0, sizeof(imgNum));
    else
      memcpy(buf, &imgNum, sizeof(imgNum));
    return SUCCESS;
  }

  event result_t MA_DownloadingImgPageNum.getAttr(uint8_t *buf) {
    pgnum_t pgNum = call DelugeMetadata.getNextIncompletePage();

    if (pgNum == DELUGE_NO_PAGE)
      memset(buf, 0, sizeof(pgNum));
    else      
      memcpy(buf, &pgNum, sizeof(pgNum));
    return SUCCESS;
  }

  event result_t MA_DownloadingImgTotalPages.getAttr(uint8_t *buf) {
    uint8_t imgNum = call DelugeMetadata.getNextIncompleteImage();
    pgnum_t pgNum;

    if (imgNum == DELUGE_INVALID_IMGNUM)
      memset(buf, 0, sizeof(pgNum));
    else {
      pgNum = call DelugeMetadata.getNumPgs(imgNum);
      memcpy(buf, &pgNum, sizeof(pgNum));
    }
    return SUCCESS;
  }

  event result_t MA_ImgSummary.getAttr(uint8_t *buf) {
    call DelugeMetadata.getImgSummaries((DelugeImgSummary*) buf);
    return SUCCESS;
  }

  event result_t DelugeMetadata.applyPageDiffDone(result_t result) {
    return SUCCESS;
  }

  event result_t DelugeMetadata.ready(result_t result) {
    return SUCCESS;
  }
}
