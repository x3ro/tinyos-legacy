struct MagMsg
{
    uint16_t readingNumber;
    uint16_t X;
    uint16_t Y;
    uint8_t  biasX;
    uint8_t  biasY;
};

struct CalMsg
{
    uint16_t bias_center;
    uint16_t bias_scale;
};

struct GainMsg
{
    uint8_t gain;
};

enum {
  AM_COMPASSMSG = 17,
  AM_CALIBRATEMSG = 18
};
