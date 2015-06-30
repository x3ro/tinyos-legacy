#define SAMPLING_PERIOD_MILLIS  50
#define MOVING_WINDOW_SIZE      8
#define COUNTDOWN_TIME          1*(1000/SAMPLING_PERIOD_MILLIS)
#define NOISE                   0
#define AC                      1
#define DC                      2
#define LPF_WINDOW_SIZE         8
#define VARIANCE_WINDOW_SIZE    24
#define VARIANCE_THRESHOLD      27
#define MAX_HIST_SIZE		6

typedef struct
{
  uint32_t x;
  uint32_t y;
} Pair_uint32_t;

typedef struct
{
  int32_t x;
  int32_t y;
} Pair_int32_t;


typedef struct
{
    bool target_1;
    bool target_2;
    bool target_3;
    int8_t probability_1;
    int8_t probability_2;
    int8_t probability_3;
} TargetInfo_t;
