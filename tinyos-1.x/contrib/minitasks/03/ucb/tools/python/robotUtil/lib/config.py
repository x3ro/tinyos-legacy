#System wide configuration parameters

ORIGIN_ADDR = 0x1000

#GROUP_ID = 0x34
GROUP_ID = 0xDD
UART_ADDR = 126
BROADCAST_ADDR = 65535

MAG_AM_TYPE = 101
MAG_PAYLOAD_LENGTH = 18

C_ROUTE_AM_TYPE = 102
C_ROUTE_PAYLOAD_LENGTH = 22
C_ROUTE_PROTOCOL = 54
C_ROUTE_TYPE = 5
C_ROUTE_LEN = 13

#orange grid -- but with screwy measurements
#MOTE_TO_GPS_M1 = [ 0.493120 , -0.035791 , 45.480000 ]
#MOTE_TO_GPS_M2 = [ 0.005965 ,  1.000656 , 50.490000 ]
#GPS_TO_MOTE_M1 = [  2.027026 , 0.072502 , -95.849761 ]
#GPS_TO_MOTE_M2 = [ -0.012084 , 0.998912 , -49.885507 ]

#blue grid
MOTE_TO_GPS_M1 = [  0.954426 , 0.316154 , 22.260000 ]
MOTE_TO_GPS_M2 = [ -0.298755 , 0.945478 , 28.970000 ]
GPS_TO_MOTE_M1 = [ 0.948474 , -0.317155 , -11.925038 ]
GPS_TO_MOTE_M2 = [ 0.299702 ,  0.957450 , -34.408684 ]



SOCKET_PACKET_LENGTH = 36

PURSUE_LOG_FILENAME = "/home/guest/work/robotUtil/pursue/log.txt"
PURSUE_GPS_TIME_OUT = 0.5  #in seconds
PURSUE_INIT_DIST = 2 #in meters
PURSUE_INIT_DIST_TOL = 0.5  #in m; goal tolerance for *initial* robot move

PURSUE_XY_NUM_AVE = 1  #3,number of samples to average x,y over for estimates

PURSUE_MAX_SPEED = 0.8 # in m/s
PURSUE_MIN_SPEED = 0.1 # in m/s
PURSUE_TURN_SPEED = 200  #50 - degrees/sec?
PURSUE_TURN_ADJ = 10 #7  degrees?
PURSUE_GOAL_TOL = 1 # in meters

PURSUE_SENSOR_BUFFER_SIZE = 10 #how long should the state trace be
PURSUE_NUM_GPS_TICKS_UPDATE = 20  #how many gps readings should we have before doing state estimation

PURSUE_CRASH_RADIUS = 1.3 #in meters

PURSUE_GRID_X_MIN = -1
PURSUE_GRID_Y_MIN = -1
PURSUE_GRID_X_MAX = 21
PURSUE_GRID_Y_MAX = 21

PURSUE_SELF_MAG_RADIUS = 2.5
PURSUE_GPS_DEV_MIN = 0.05
PURSUE_GPS_DEV_MAX = 1
