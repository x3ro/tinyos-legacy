# 37 "/usr/include/stdint.h"
typedef signed char int8_t;
typedef short int int16_t;
typedef int int32_t;



__extension__ 
typedef long long int int64_t;




typedef unsigned char uint8_t;
typedef unsigned short int uint16_t;

typedef unsigned int uint32_t;





__extension__ 
typedef unsigned long long int uint64_t;






typedef signed char int_least8_t;
typedef short int int_least16_t;
typedef int int_least32_t;



__extension__ 
typedef long long int int_least64_t;



typedef unsigned char uint_least8_t;
typedef unsigned short int uint_least16_t;
typedef unsigned int uint_least32_t;



__extension__ 
typedef unsigned long long int uint_least64_t;






typedef signed char int_fast8_t;





typedef int int_fast16_t;
typedef int int_fast32_t;
__extension__ 
typedef long long int int_fast64_t;



typedef unsigned char uint_fast8_t;





typedef unsigned int uint_fast16_t;
typedef unsigned int uint_fast32_t;
__extension__ 
typedef unsigned long long int uint_fast64_t;
# 126 "/usr/include/stdint.h" 3
typedef int intptr_t;


typedef unsigned int uintptr_t;








__extension__ 
typedef long long int intmax_t;
__extension__ 
typedef unsigned long long int uintmax_t;
# 35 "/usr/include/inttypes.h"
typedef long int __gwchar_t;
# 288 "/usr/include/inttypes.h" 3
typedef struct __nesc_unnamed4242 {

  long long int quot;
  long long int rem;
} imaxdiv_t;
# 213 "/usr/lib/gcc-lib/i386-redhat-linux/3.3.2/include/stddef.h" 3
typedef unsigned int size_t;
# 38 "/usr/include/string.h"
extern void *memcpy(void *__restrict __dest, 
const void *__restrict __src, size_t __n);
#line 58
extern void *memset(void *__s, int __c, size_t __n);
# 85 "/usr/include/string.h" 3
extern char *strncpy(char *__restrict __dest, 
const char *__restrict __src, size_t __n);









extern int 
__attribute((__pure__)) 
#line 96
strcmp(const char *__s1, const char *__s2);


extern int 
__attribute((__pure__)) 
#line 99
strncmp(const char *__s1, const char *__s2, size_t __n);
#line 191
extern char *strtok(char *__restrict __s, const char *__restrict __delim);
#line 243
extern char *strerror(int __errnum);
#line 260
extern void bzero(void *__s, size_t __n);
# 325 "/usr/lib/gcc-lib/i386-redhat-linux/3.3.2/include/stddef.h" 3
typedef long int wchar_t;
# 95 "/usr/include/stdlib.h" 3
typedef struct __nesc_unnamed4243 {

  int quot;
  int rem;
} div_t;



typedef struct __nesc_unnamed4244 {

  long int quot;
  long int rem;
} ldiv_t;
#line 142
extern double __attribute((__pure__)) atof(const char *__nptr);

extern int __attribute((__pure__)) atoi(const char *__nptr);







__extension__ 
#line 186
__extension__ 



__extension__ 








__extension__ 



__extension__ 
#line 287
__extension__ 






__extension__ 
# 34 "/usr/include/bits/types.h"
typedef unsigned char __u_char;
typedef unsigned short int __u_short;
typedef unsigned int __u_int;
typedef unsigned long int __u_long;


typedef signed char __int8_t;
typedef unsigned char __uint8_t;
typedef signed short int __int16_t;
typedef unsigned short int __uint16_t;
typedef signed int __int32_t;
typedef unsigned int __uint32_t;




__extension__ 
#line 50
typedef signed long long int __int64_t;
__extension__ 
#line 51
typedef unsigned long long int __uint64_t;







__extension__ 
#line 59
typedef long long int __quad_t;
__extension__ 
#line 60
typedef unsigned long long int __u_quad_t;
#line 136
__extension__ 
#line 136
typedef unsigned long long int __dev_t;
__extension__ 
#line 137
typedef unsigned int __uid_t;
__extension__ 
#line 138
typedef unsigned int __gid_t;
__extension__ 
#line 139
typedef unsigned long int __ino_t;
__extension__ 
#line 140
typedef unsigned long long int __ino64_t;
__extension__ 
#line 141
typedef unsigned int __mode_t;
__extension__ 
#line 142
typedef unsigned int __nlink_t;
__extension__ 
#line 143
typedef long int __off_t;
__extension__ 
#line 144
typedef long long int __off64_t;
__extension__ 
#line 145
typedef int __pid_t;
__extension__ 
#line 146
typedef struct __nesc_unnamed4245 {
#line 146
  int __val[2];
} 
#line 146
__fsid_t;
__extension__ 
#line 147
typedef long int __clock_t;
__extension__ 
#line 148
typedef unsigned long int __rlim_t;
__extension__ 
#line 149
typedef unsigned long long int __rlim64_t;
__extension__ 
#line 150
typedef unsigned int __id_t;
__extension__ 
#line 151
typedef long int __time_t;
__extension__ 
#line 152
typedef unsigned int __useconds_t;
__extension__ 
#line 153
typedef long int __suseconds_t;

__extension__ 
#line 155
typedef int __daddr_t;
__extension__ 
#line 156
typedef long int __swblk_t;
__extension__ 
#line 157
typedef int __key_t;


__extension__ 
#line 160
typedef int __clockid_t;


__extension__ 
#line 163
typedef int __timer_t;


__extension__ 
#line 166
typedef long int __blksize_t;




__extension__ 
#line 171
typedef long int __blkcnt_t;
__extension__ 
#line 172
typedef long long int __blkcnt64_t;


__extension__ 
#line 175
typedef unsigned long int __fsblkcnt_t;
__extension__ 
#line 176
typedef unsigned long long int __fsblkcnt64_t;


__extension__ 
#line 179
typedef unsigned long int __fsfilcnt_t;
__extension__ 
#line 180
typedef unsigned long long int __fsfilcnt64_t;

__extension__ 
#line 182
typedef int __ssize_t;



typedef __off64_t __loff_t;
typedef __quad_t *__qaddr_t;
typedef char *__caddr_t;


__extension__ 
#line 191
typedef int __intptr_t;


__extension__ 
#line 194
typedef unsigned int __socklen_t;
# 35 "/usr/include/sys/types.h"
typedef __u_char u_char;
typedef __u_short u_short;
typedef __u_int u_int;
typedef __u_long u_long;
typedef __quad_t quad_t;
typedef __u_quad_t u_quad_t;
typedef __fsid_t fsid_t;




typedef __loff_t loff_t;



typedef __ino_t ino_t;
#line 62
typedef __dev_t dev_t;




typedef __gid_t gid_t;




typedef __mode_t mode_t;




typedef __nlink_t nlink_t;




typedef __uid_t uid_t;





typedef __off_t off_t;
#line 100
typedef __pid_t pid_t;




typedef __id_t id_t;




typedef __ssize_t ssize_t;





typedef __daddr_t daddr_t;
typedef __caddr_t caddr_t;





typedef __key_t key_t;
# 76 "/usr/include/time.h"
typedef __time_t time_t;
#line 92
typedef __clockid_t clockid_t;
#line 104
typedef __timer_t timer_t;
# 151 "/usr/include/sys/types.h"
typedef unsigned long int ulong;
typedef unsigned short int ushort;
typedef unsigned int uint;
# 197 "/usr/include/sys/types.h" 3
typedef unsigned int __attribute((__mode__(__QI__))) u_int8_t;
typedef unsigned int __attribute((__mode__(__HI__))) u_int16_t;
typedef unsigned int __attribute((__mode__(__SI__))) u_int32_t;
typedef unsigned int __attribute((__mode__(__DI__))) u_int64_t;

typedef int __attribute((__mode__(__word__))) register_t;
# 23 "/usr/include/bits/sigset.h"
typedef int __sig_atomic_t;




typedef struct __nesc_unnamed4246 {

  unsigned long int __val[1024 / (8 * sizeof(unsigned long int ))];
} __sigset_t;
# 38 "/usr/include/sys/select.h"
typedef __sigset_t sigset_t;
# 118 "/usr/include/time.h" 3
struct timespec {

  __time_t tv_sec;
  long int tv_nsec;
};
# 69 "/usr/include/bits/time.h"
struct timeval {

  __time_t tv_sec;
  __suseconds_t tv_usec;
};
# 49 "/usr/include/sys/select.h"
typedef __suseconds_t suseconds_t;





typedef long int __fd_mask;
#line 67
typedef struct __nesc_unnamed4247 {







  __fd_mask __fds_bits[1024 / (8 * sizeof(__fd_mask ))];
} 

fd_set;






typedef __fd_mask fd_mask;
#line 109
extern int select(int __nfds, fd_set *__restrict __readfds, 
fd_set *__restrict __writefds, 
fd_set *__restrict __exceptfds, 
struct timeval *__restrict __timeout);
# 29 "/usr/include/sys/sysmacros.h"
__extension__ 


__extension__ 


__extension__ 





__extension__ 





__extension__ 





__extension__ 
# 231 "/usr/include/sys/types.h" 3
typedef __blkcnt_t blkcnt_t;



typedef __fsblkcnt_t fsblkcnt_t;



typedef __fsfilcnt_t fsfilcnt_t;
# 83 "/usr/include/bits/sched.h" 3
struct __sched_param {

  int __sched_priority;
};
# 26 "/usr/include/bits/pthreadtypes.h"
struct _pthread_fastlock {

  long int __status;
  int __spinlock;
};




typedef struct _pthread_descr_struct *_pthread_descr;





typedef struct __pthread_attr_s {

  int __detachstate;
  int __schedpolicy;
  struct __sched_param __schedparam;
  int __inheritsched;
  int __scope;
  size_t __guardsize;
  int __stackaddr_set;
  void *__stackaddr;
  size_t __stacksize;
} pthread_attr_t;





__extension__ 
#line 58
typedef long long __pthread_cond_align_t;




typedef struct __nesc_unnamed4248 {

  struct _pthread_fastlock __c_lock;
  _pthread_descr __c_waiting;
  char __padding
  [
#line 67
  48 - sizeof(struct _pthread_fastlock )
   - sizeof(_pthread_descr ) - sizeof(__pthread_cond_align_t )];
  __pthread_cond_align_t __align;
} pthread_cond_t;



typedef struct __nesc_unnamed4249 {

  int __dummy;
} pthread_condattr_t;


typedef unsigned int pthread_key_t;





typedef struct __nesc_unnamed4250 {

  int __m_reserved;
  int __m_count;
  _pthread_descr __m_owner;
  int __m_kind;
  struct _pthread_fastlock __m_lock;
} pthread_mutex_t;



typedef struct __nesc_unnamed4251 {

  int __mutexkind;
} pthread_mutexattr_t;



typedef int pthread_once_t;
# 150 "/usr/include/bits/pthreadtypes.h" 3
typedef unsigned long int pthread_t;
# 445 "/usr/include/stdlib.h"
struct random_data {

  int32_t *fptr;
  int32_t *rptr;
  int32_t *state;
  int rand_type;
  int rand_deg;
  int rand_sep;
  int32_t *end_ptr;
};
#line 473
extern int rand(void );
#line 508
struct drand48_data {

  unsigned short int __x[3];
  unsigned short int __old_x[3];
  unsigned short int __c;
  unsigned short int __init;
  unsigned long long int __a;
};
#line 556
extern void __attribute((__malloc__)) *malloc(size_t __size);
#line 569
extern void free(void *__ptr);
# 612 "/usr/include/stdlib.h" 3
extern void __attribute((__noreturn__)) exit(int __status);
#line 626
extern char *getenv(const char *__name);
#line 728
typedef int (*__compar_fn_t)(const void *, const void *);
# 154 "/usr/include/bits/mathcalls.h" 3
extern double pow(double __x, double __y);
# 252 "/usr/include/math.h" 3
typedef enum __nesc_unnamed4252 {

  _IEEE_ = -1, 
  _SVID_, 
  _XOPEN_, 
  _POSIX_, 
  _ISOC_
} _LIB_VERSION_TYPE;
#line 277
struct exception {


  int type;
  char *name;
  double arg1;
  double arg2;
  double retval;
};
# 151 "/usr/lib/gcc-lib/i386-redhat-linux/3.3.2/include/stddef.h" 3
typedef int ptrdiff_t;
# 48 "/usr/include/ctype.h"
enum __nesc_unnamed4253 {

  _ISupper = 0 < 8 ? (1 << 0) << 8 : (1 << 0) >> 8, 
  _ISlower = 1 < 8 ? (1 << 1) << 8 : (1 << 1) >> 8, 
  _ISalpha = 2 < 8 ? (1 << 2) << 8 : (1 << 2) >> 8, 
  _ISdigit = 3 < 8 ? (1 << 3) << 8 : (1 << 3) >> 8, 
  _ISxdigit = 4 < 8 ? (1 << 4) << 8 : (1 << 4) >> 8, 
  _ISspace = 5 < 8 ? (1 << 5) << 8 : (1 << 5) >> 8, 
  _ISprint = 6 < 8 ? (1 << 6) << 8 : (1 << 6) >> 8, 
  _ISgraph = 7 < 8 ? (1 << 7) << 8 : (1 << 7) >> 8, 
  _ISblank = 8 < 8 ? (1 << 8) << 8 : (1 << 8) >> 8, 
  _IScntrl = 9 < 8 ? (1 << 9) << 8 : (1 << 9) >> 8, 
  _ISpunct = 10 < 8 ? (1 << 10) << 8 : (1 << 10) >> 8, 
  _ISalnum = 11 < 8 ? (1 << 11) << 8 : (1 << 11) >> 8
};
# 87 "/root/src/tinyos-1.x/tos/system/tos.h"
typedef unsigned char bool;






enum __nesc_unnamed4254 {
  FALSE = 0, 
  TRUE = 1
};

uint16_t TOS_LOCAL_ADDRESS = 1;

enum __nesc_unnamed4255 {
  FAIL = 0, 
  SUCCESS = 1
};
static inline 

uint8_t rcombine(uint8_t r1, uint8_t r2);
typedef uint8_t  result_t;
static inline 






result_t rcombine(result_t r1, result_t r2);
static inline 






result_t rcombine3(result_t r1, result_t r2, result_t r3);
static inline 



result_t rcombine4(result_t r1, result_t r2, result_t r3, 
result_t r4);





enum __nesc_unnamed4256 {
  NULL = 0x0
};
# 46 "/usr/include/stdio.h"
typedef struct _IO_FILE FILE;
#line 62
typedef struct _IO_FILE __FILE;
# 354 "/usr/lib/gcc-lib/i386-redhat-linux/3.3.2/include/stddef.h" 3
typedef unsigned int wint_t;
# 76 "/usr/include/wchar.h" 3
typedef struct __nesc_unnamed4257 {

  int __count;
  union __nesc_unnamed4258 {

    wint_t __wch;
    char __wchb[4];
  } __value;
} __mbstate_t;
# 26 "/usr/include/_G_config.h"
typedef struct __nesc_unnamed4259 {

  __off_t __pos;
  __mbstate_t __state;
} _G_fpos_t;
typedef struct __nesc_unnamed4260 {

  __off64_t __pos;
  __mbstate_t __state;
} _G_fpos64_t;
# 37 "/usr/include/gconv.h"
enum __nesc_unnamed4261 {

  __GCONV_OK = 0, 
  __GCONV_NOCONV, 
  __GCONV_NODB, 
  __GCONV_NOMEM, 

  __GCONV_EMPTY_INPUT, 
  __GCONV_FULL_OUTPUT, 
  __GCONV_ILLEGAL_INPUT, 
  __GCONV_INCOMPLETE_INPUT, 

  __GCONV_ILLEGAL_DESCRIPTOR, 
  __GCONV_INTERNAL_ERROR
};



enum __nesc_unnamed4262 {

  __GCONV_IS_LAST = 0x0001, 
  __GCONV_IGNORE_ERRORS = 0x0002
};



struct __gconv_step;
struct __gconv_step_data;
struct __gconv_loaded_object;
struct __gconv_trans_data;



typedef int (*__gconv_fct)(struct __gconv_step *, struct __gconv_step_data *, 
const unsigned char **, const unsigned char *, 
unsigned char **, size_t *, int , int );


typedef wint_t (*__gconv_btowc_fct)(struct __gconv_step *, unsigned char );


typedef int (*__gconv_init_fct)(struct __gconv_step *);
typedef void (*__gconv_end_fct)(struct __gconv_step *);



typedef int (*__gconv_trans_fct)(struct __gconv_step *, 
struct __gconv_step_data *, void *, 
const unsigned char *, 
const unsigned char **, 
const unsigned char *, unsigned char **, 
size_t *);


typedef int (*__gconv_trans_context_fct)(void *, const unsigned char *, 
const unsigned char *, 
unsigned char *, unsigned char *);


typedef int (*__gconv_trans_query_fct)(const char *, const char ***, 
size_t *);


typedef int (*__gconv_trans_init_fct)(void **, const char *);
typedef void (*__gconv_trans_end_fct)(void *);

struct __gconv_trans_data {


  __gconv_trans_fct __trans_fct;
  __gconv_trans_context_fct __trans_context_fct;
  __gconv_trans_end_fct __trans_end_fct;
  void *__data;
  struct __gconv_trans_data *__next;
};



struct __gconv_step {

  struct __gconv_loaded_object *__shlib_handle;
  const char *__modname;

  int __counter;

  char *__from_name;
  char *__to_name;

  __gconv_fct __fct;
  __gconv_btowc_fct __btowc_fct;
  __gconv_init_fct __init_fct;
  __gconv_end_fct __end_fct;



  int __min_needed_from;
  int __max_needed_from;
  int __min_needed_to;
  int __max_needed_to;


  int __stateful;

  void *__data;
};



struct __gconv_step_data {

  unsigned char *__outbuf;
  unsigned char *__outbufend;



  int __flags;



  int __invocation_counter;



  int __internal_use;

  __mbstate_t *__statep;
  __mbstate_t __state;



  struct __gconv_trans_data *__trans;
};



typedef struct __gconv_info {

  size_t __nsteps;
  struct __gconv_step *__steps;
  __extension__ struct __gconv_step_data __data[];
} *__gconv_t;
# 45 "/usr/include/_G_config.h"
typedef union __nesc_unnamed4263 {

  struct __gconv_info __cd;
  struct __nesc_unnamed4264 {

    struct __gconv_info __cd;
    struct __gconv_step_data __data;
  } __combined;
} _G_iconv_t;

typedef int __attribute((__mode__(__HI__))) _G_int16_t;
typedef int __attribute((__mode__(__SI__))) _G_int32_t;
typedef unsigned int __attribute((__mode__(__HI__))) _G_uint16_t;
typedef unsigned int __attribute((__mode__(__SI__))) _G_uint32_t;
# 43 "/usr/lib/gcc-lib/i386-redhat-linux/3.3.2/include/stdarg.h"
typedef __builtin_va_list __gnuc_va_list;
# 163 "/usr/include/libio.h" 3
struct _IO_jump_t;
#line 163
struct _IO_FILE;









typedef void _IO_lock_t;





struct _IO_marker {
  struct _IO_marker *_next;
  struct _IO_FILE *_sbuf;



  int _pos;
};
#line 199
enum __codecvt_result {

  __codecvt_ok, 
  __codecvt_partial, 
  __codecvt_error, 
  __codecvt_noconv
};
#line 264
struct _IO_FILE {
  int _flags;




  char *_IO_read_ptr;
  char *_IO_read_end;
  char *_IO_read_base;
  char *_IO_write_base;
  char *_IO_write_ptr;
  char *_IO_write_end;
  char *_IO_buf_base;
  char *_IO_buf_end;

  char *_IO_save_base;
  char *_IO_backup_base;
  char *_IO_save_end;

  struct _IO_marker *_markers;

  struct _IO_FILE *_chain;

  int _fileno;



  int _flags2;

  __off_t _old_offset;



  unsigned short _cur_column;
  signed char _vtable_offset;
  char _shortbuf[1];



  _IO_lock_t *_lock;








  __off64_t _offset;





  void *__pad1;
  void *__pad2;

  int _mode;

  char _unused2[15 * sizeof(int ) - 2 * sizeof(void *)];
};



typedef struct _IO_FILE _IO_FILE;


struct _IO_FILE_plus;

struct _IO_FILE_plus;
struct _IO_FILE_plus;
struct _IO_FILE_plus;
#line 351
typedef __ssize_t __io_read_fn(void *__cookie, char *__buf, size_t __nbytes);







typedef __ssize_t __io_write_fn(void *__cookie, const char *__buf, 
size_t __n);







typedef int __io_seek_fn(void *__cookie, __off64_t *__pos, int __w);


typedef int __io_close_fn(void *__cookie);
#line 433
extern int _IO_getc(_IO_FILE *__fp);
# 88 "/usr/include/stdio.h" 3
typedef _G_fpos_t fpos_t;
# 142 "/usr/include/stdio.h"
struct _IO_FILE;
extern struct _IO_FILE *stdout;
extern struct _IO_FILE *stderr;
# 243 "/usr/include/stdio.h" 3
extern FILE *fopen(const char *__restrict __filename, 
const char *__restrict __modes);
#line 275
extern FILE *fdopen(int __fd, const char *__modes);
#line 323
extern int fprintf(FILE *__restrict __stream, 
const char *__restrict __format, ...);




extern int printf(const char *__restrict __format, ...);








extern int vfprintf(FILE *__restrict __s, const char *__restrict __format, 
__gnuc_va_list __arg);
#line 353
extern int 

__attribute((__format__(__printf__, 3, 4))) 
#line 353
snprintf(char *__restrict __s, size_t __maxlen, 
const char *__restrict __format, ...);


extern int 

__attribute((__format__(__printf__, 3, 0))) 
#line 357
vsnprintf(char *__restrict __s, size_t __maxlen, 
const char *__restrict __format, __gnuc_va_list __arg);
# 41 "/usr/include/signal.h"
typedef __sig_atomic_t sig_atomic_t;
# 73 "/usr/include/signal.h" 3
typedef void (*__sighandler_t)(int );
#line 90
extern __sighandler_t signal(int __sig, __sighandler_t __handler);
#line 197
typedef __sighandler_t sig_t;
# 33 "/usr/include/bits/siginfo.h"
typedef union sigval {

  int sival_int;
  void *sival_ptr;
} sigval_t;
#line 51
typedef struct siginfo {

  int si_signo;
  int si_errno;

  int si_code;

  union __nesc_unnamed4265 {

    int _pad[128 / sizeof(int ) - 3];


    struct __nesc_unnamed4266 {

      __pid_t si_pid;
      __uid_t si_uid;
    } _kill;


    struct __nesc_unnamed4267 {

      int si_tid;
      int si_overrun;
      sigval_t si_sigval;
    } _timer;


    struct __nesc_unnamed4268 {

      __pid_t si_pid;
      __uid_t si_uid;
      sigval_t si_sigval;
    } _rt;


    struct __nesc_unnamed4269 {

      __pid_t si_pid;
      __uid_t si_uid;
      int si_status;
      __clock_t si_utime;
      __clock_t si_stime;
    } _sigchld;


    struct __nesc_unnamed4270 {

      void *si_addr;
    } _sigfault;


    struct __nesc_unnamed4271 {

      long int si_band;
      int si_fd;
    } _sigpoll;
  } _sifields;
} siginfo_t;
#line 129
enum __nesc_unnamed4272 {

  SI_ASYNCNL = -60, 

  SI_TKILL = -6, 

  SI_SIGIO, 

  SI_ASYNCIO, 

  SI_MESGQ, 

  SI_TIMER, 

  SI_QUEUE, 

  SI_USER, 

  SI_KERNEL = 0x80
};




enum __nesc_unnamed4273 {

  ILL_ILLOPC = 1, 

  ILL_ILLOPN, 

  ILL_ILLADR, 

  ILL_ILLTRP, 

  ILL_PRVOPC, 

  ILL_PRVREG, 

  ILL_COPROC, 

  ILL_BADSTK
};



enum __nesc_unnamed4274 {

  FPE_INTDIV = 1, 

  FPE_INTOVF, 

  FPE_FLTDIV, 

  FPE_FLTOVF, 

  FPE_FLTUND, 

  FPE_FLTRES, 

  FPE_FLTINV, 

  FPE_FLTSUB
};



enum __nesc_unnamed4275 {

  SEGV_MAPERR = 1, 

  SEGV_ACCERR
};



enum __nesc_unnamed4276 {

  BUS_ADRALN = 1, 

  BUS_ADRERR, 

  BUS_OBJERR
};



enum __nesc_unnamed4277 {

  TRAP_BRKPT = 1, 

  TRAP_TRACE
};



enum __nesc_unnamed4278 {

  CLD_EXITED = 1, 

  CLD_KILLED, 

  CLD_DUMPED, 

  CLD_TRAPPED, 

  CLD_STOPPED, 

  CLD_CONTINUED
};



enum __nesc_unnamed4279 {

  POLL_IN = 1, 

  POLL_OUT, 

  POLL_MSG, 

  POLL_ERR, 

  POLL_PRI, 

  POLL_HUP
};
#line 273
typedef struct sigevent {

  sigval_t sigev_value;
  int sigev_signo;
  int sigev_notify;

  union __nesc_unnamed4280 {

    int _pad[64 / sizeof(int ) - 3];



    __pid_t _tid;

    struct __nesc_unnamed4281 {

      void (*_function)(sigval_t );
      void *_attribute;
    } _sigev_thread;
  } _sigev_un;
} sigevent_t;






enum __nesc_unnamed4282 {

  SIGEV_SIGNAL = 0, 

  SIGEV_NONE, 

  SIGEV_THREAD, 


  SIGEV_THREAD_ID = 4
};
# 212 "/usr/include/signal.h"
extern int sigemptyset(sigset_t *__set);
# 25 "/usr/include/bits/sigaction.h"
struct sigaction {



  union __nesc_unnamed4283 {


    __sighandler_t sa_handler;

    void (*sa_sigaction)(int , siginfo_t *, void *);
  } 
  __sigaction_handler;







  __sigset_t sa_mask;


  int sa_flags;


  void (*sa_restorer)(void );
};
# 255 "/usr/include/signal.h"
extern int sigaction(int __sig, const struct sigaction *__restrict __act, 
struct sigaction *__restrict __oact);
#line 301
struct sigvec {

  __sighandler_t sv_handler;
  int sv_mask;

  int sv_flags;
};
# 18 "/usr/include/asm/sigcontext.h"
struct _fpreg {
  unsigned short significand[4];
  unsigned short exponent;
};

struct _fpxreg {
  unsigned short significand[4];
  unsigned short exponent;
  unsigned short padding[3];
};

struct _xmmreg {
  unsigned long element[4];
};

struct _fpstate {

  unsigned long cw;
  unsigned long sw;
  unsigned long tag;
  unsigned long ipoff;
  unsigned long cssel;
  unsigned long dataoff;
  unsigned long datasel;
  struct _fpreg _st[8];
  unsigned short status;
  unsigned short magic;


  unsigned long _fxsr_env[6];
  unsigned long mxcsr;
  unsigned long reserved;
  struct _fpxreg _fxsr_st[8];
  struct _xmmreg _xmm[8];
  unsigned long padding[56];
};



struct sigcontext {
  unsigned short gs, __gsh;
  unsigned short fs, __fsh;
  unsigned short es, __esh;
  unsigned short ds, __dsh;
  unsigned long edi;
  unsigned long esi;
  unsigned long ebp;
  unsigned long esp;
  unsigned long ebx;
  unsigned long edx;
  unsigned long ecx;
  unsigned long eax;
  unsigned long trapno;
  unsigned long err;
  unsigned long eip;
  unsigned short cs, __csh;
  unsigned long eflags;
  unsigned long esp_at_signal;
  unsigned short ss, __ssh;
  struct _fpstate *fpstate;
  unsigned long oldmask;
  unsigned long cr2;
};
# 26 "/usr/include/bits/sigstack.h"
struct sigstack {

  void *ss_sp;
  int ss_onstack;
};



enum __nesc_unnamed4284 {

  SS_ONSTACK = 1, 

  SS_DISABLE
};










typedef struct sigaltstack {

  void *ss_sp;
  int ss_flags;
  size_t ss_size;
} stack_t;
# 62 "/root/src/tinyos-1.x/beta/TOSSIM-packet/nido.h"
enum __nesc_unnamed4285 {
  TOSNODES = 1000, 
  DEFAULT_EEPROM_SIZE = 512 * 1024
};

enum __nesc_unnamed4286 {
  TOSSIM_RADIO_MODEL_SIMPLE = 0, 
  TOSSIM_RADIO_MODEL_LOSSY = 1, 
  TOSSIM_RADIO_MODEL_PACKET = 2
};
# 51 "/root/src/tinyos-1.x/tos/platform/pc/heap_array.h"
typedef struct __nesc_unnamed4287 {
  int size;
  void *data;
  int private_size;
} heap_t;
static inline 
void init_heap(heap_t *heap);
static inline 
int heap_is_empty(heap_t *heap);
static inline 
long long heap_get_min_key(heap_t *heap);
static 
void *heap_pop_min_data(heap_t *heap, long long *key);
static inline void heap_insert(heap_t *heap, void *data, long long key);
# 62 "/usr/include/bits/sched.h" 3
struct sched_param {

  int __sched_priority;
};
#line 98
typedef unsigned long int __cpu_mask;






typedef struct __nesc_unnamed4288 {

  __cpu_mask __bits[1024 / (8 * sizeof(__cpu_mask ))];
} cpu_set_t;
# 60 "/usr/include/time.h"
typedef __clock_t clock_t;
# 131 "/usr/include/time.h" 3
struct tm {

  int tm_sec;
  int tm_min;
  int tm_hour;
  int tm_mday;
  int tm_mon;
  int tm_year;
  int tm_wday;
  int tm_yday;
  int tm_isdst;


  long int tm_gmtoff;
  const char *tm_zone;
};
#line 159
struct itimerspec {

  struct timespec it_interval;
  struct timespec it_value;
};


struct sigevent;
#line 229
struct tm;



struct tm;





struct tm;




struct tm;
# 59 "/usr/include/pthread.h" 3
enum __nesc_unnamed4289 {

  PTHREAD_CREATE_JOINABLE, 

  PTHREAD_CREATE_DETACHED
};


enum __nesc_unnamed4290 {

  PTHREAD_INHERIT_SCHED, 

  PTHREAD_EXPLICIT_SCHED
};


enum __nesc_unnamed4291 {

  PTHREAD_SCOPE_SYSTEM, 

  PTHREAD_SCOPE_PROCESS
};


enum __nesc_unnamed4292 {

  PTHREAD_MUTEX_TIMED_NP, 
  PTHREAD_MUTEX_RECURSIVE_NP, 
  PTHREAD_MUTEX_ERRORCHECK_NP, 
  PTHREAD_MUTEX_ADAPTIVE_NP
};
#line 102
enum __nesc_unnamed4293 {

  PTHREAD_PROCESS_PRIVATE, 

  PTHREAD_PROCESS_SHARED
};
#line 131
struct _pthread_cleanup_buffer {

  void (*__routine)(void *);
  void *__arg;
  int __canceltype;
  struct _pthread_cleanup_buffer *__prev;
};



enum __nesc_unnamed4294 {

  PTHREAD_CANCEL_ENABLE, 

  PTHREAD_CANCEL_DISABLE
};

enum __nesc_unnamed4295 {

  PTHREAD_CANCEL_DEFERRED, 

  PTHREAD_CANCEL_ASYNCHRONOUS
};









extern int pthread_create(pthread_t *__restrict __threadp, 
const pthread_attr_t *__restrict __attr, 
void *(*__start_routine)(void *), 
void *__restrict __arg);
#line 332
extern int pthread_mutex_init(pthread_mutex_t *__restrict __mutex, 
const pthread_mutexattr_t *__restrict 
__mutex_attr);








extern int pthread_mutex_lock(pthread_mutex_t *__mutex);









extern int pthread_mutex_unlock(pthread_mutex_t *__mutex);
#line 391
extern int pthread_cond_init(pthread_cond_t *__restrict __cond, 
const pthread_condattr_t *__restrict 
__cond_attr);





extern int pthread_cond_signal(pthread_cond_t *__cond);


extern int pthread_cond_broadcast(pthread_cond_t *__cond);



extern int pthread_cond_wait(pthread_cond_t *__restrict __cond, 
pthread_mutex_t *__restrict __mutex);
# 63 "/root/src/tinyos-1.x/tos/platform/pc/event_queue.h"
struct TOS_state;

typedef struct event_queue {
  int pause;
  heap_t heap;
  pthread_mutex_t lock;
} event_queue_t;

typedef struct event {
  long long time;
  int mote;
  int pause;
  int force;

  void *data;

  void (*handle)(struct event *, struct TOS_state *);
  void (*cleanup)(struct event *);
} event_t;
static inline 

void queue_init(event_queue_t *queue, int fpause);
static void queue_insert_event(event_queue_t *queue, event_t *event);
static inline event_t *queue_pop_event(event_queue_t *queue);
static inline void queue_handle_next_event(event_queue_t *queue);
static inline int queue_is_empty(event_queue_t *queue);
static inline long long queue_peek_event_time(event_queue_t *queue);
# 62 "/root/src/tinyos-1.x/beta/TOSSIM-packet/adjacency_list.h"
enum __nesc_unnamed4296 {
  NUM_NODES_ALLOC = 200
};


typedef struct link {
  int mote;
  double data;
  double neg;
  double pos;
  char bit;
  struct link *next_link;
} link_t;


link_t *free_list;
int num_free_links;
static 
link_t *allocate_link(int mote);
static 
int adjacency_list_init(void);
# 62 "/root/src/tinyos-1.x/tos/platform/pc/rfm_model.h"
typedef struct __nesc_unnamed4297 {
  void (*init)(void);
  void (*transmit)(int , char );
  void (*stop_transmit)(int );
  char (*hears)(int );
  bool (*connected)(int , int );
  link_t *(*neighbors)(int );
} rfm_model;
static inline 

rfm_model *create_simple_model(void);
static inline 




rfm_model *create_lossy_model(char *file);
static 
void static_one_cell_init(void);
static inline 


void set_link_prob_value(uint16_t moteID1, uint16_t moteID2, double prob);



extern link_t *radio_connectivity[TOSNODES];
# 59 "/root/src/tinyos-1.x/tos/platform/pc/adc_model.h"
typedef struct __nesc_unnamed4298 {
  void (*init)(void);

  uint16_t (*read)(int , uint8_t , long long );
} adc_model;
static inline 
adc_model *create_random_adc_model(void);
static inline adc_model *create_generic_adc_model(void);
static inline void set_adc_value(int moteID, uint8_t port, uint16_t value);
# 58 "/root/src/tinyos-1.x/tos/platform/pc/spatial_model.h"
typedef struct __nesc_unnamed4299 {
  double xCoordinate;
  double yCoordinate;
  double zCoordinate;
} point3D;

typedef struct __nesc_unnamed4300 {
  void (*init)(void);
  void (*get_position)(int , long long , point3D *);
} 

spatial_model;
static inline 


spatial_model *create_simple_spatial_model(void);
static inline 
# 64 "/root/src/tinyos-1.x/tos/platform/pc/nido_eeprom.h"
int anonymousEEPROM(int numMotes, int eepromSize);
static inline int namedEEPROM(char *name, int numMotes, int eepromSize);
# 55 "/root/src/tinyos-1.x/tos/platform/pc/events.h"
typedef struct __nesc_unnamed4301 {
  int interval;
  int mote;
  int valid;
  int disabled;
} clock_tick_data_t;

typedef struct __nesc_unnamed4302 {
  int valid;
  char port;
} adc_tick_data_t;

typedef struct __nesc_unnamed4303 {
  int interval;
  int mote;
  int valid;
} radio_tick_data_t;

typedef struct __nesc_unnamed4304 {
  int interval;
  int mote;
  int valid;
} channel_mon_data_t;

typedef struct __nesc_unnamed4305 {
  int interval;
  int mote;
  int valid;
  int count;
  int ending;
} spi_byte_data_t;

typedef struct __nesc_unnamed4306 {
  int interval;
  int mote;
  int valid;
} radio_timing_data_t;
static inline 




void event_default_cleanup(event_t *event);
static 
void event_total_cleanup(event_t *event);
static inline 
void event_clocktick_create(event_t *event, 
int mote, 
long long eventTime, 
int interval);
static inline 
void event_clocktick_handle(event_t *event, 
struct TOS_state *state);
static inline 
void event_clocktick_invalidate(event_t *event);
#line 134
void event_spi_byte_create(event_t *event, int mote, long long ftime, int interval, int count);
static inline 
#line 146
void event_cleanup(event_t *fevent);
# 49 "/root/src/tinyos-1.x/tos/types/AM.h"
enum __nesc_unnamed4307 {
  TOS_BCAST_ADDR = 0xffff, 
  TOS_UART_ADDR = 0x007e
};





enum __nesc_unnamed4308 {
  TOS_DEFAULT_AM_GROUP = 0x7d
};

uint8_t TOS_AM_GROUP = TOS_DEFAULT_AM_GROUP;
#line 84
typedef struct TOS_Msg {


  uint16_t addr;
  uint8_t type;
  uint8_t group;
  uint8_t length;
  int8_t data[36];
  uint16_t crc;







  uint16_t strength;
  uint8_t ack;
  uint16_t time;
  uint8_t sendSecurityMode;
  uint8_t receiveSecurityMode;
} TOS_Msg;

typedef struct TOS_Msg_TinySecCompat {


  uint16_t addr;
  uint8_t type;

  uint8_t length;
  uint8_t group;
  int8_t data[36];
  uint16_t crc;







  uint16_t strength;
  uint8_t ack;
  uint16_t time;
  uint8_t sendSecurityMode;
  uint8_t receiveSecurityMode;
} TOS_Msg_TinySecCompat;

typedef struct TinySec_Msg {

  uint16_t addr;
  uint8_t type;
  uint8_t length;

  uint8_t iv[4];

  uint8_t enc[36];

  uint8_t mac[4];


  uint8_t calc_mac[4];
  uint8_t ack_byte;
  bool cryptoDone;
  bool receiveDone;

  bool MACcomputed;
} __attribute((packed))  TinySec_Msg;



enum __nesc_unnamed4309 {
  MSG_DATA_SIZE = (size_t )& ((struct TOS_Msg *)0)->crc + sizeof(uint16_t ), 
  TINYSEC_MSG_DATA_SIZE = (size_t )& ((struct TinySec_Msg *)0)->mac + 4, 
  DATA_LENGTH = 36, 
  LENGTH_BYTE_NUMBER = (size_t )& ((struct TOS_Msg *)0)->length + 1, 
  TINYSEC_NODE_ID_SIZE = sizeof(uint16_t )
};

enum __nesc_unnamed4310 {
  TINYSEC_AUTH_ONLY = 1, 
  TINYSEC_ENCRYPT_AND_AUTH = 2, 
  TINYSEC_DISABLED = 3, 
  TINYSEC_RECEIVE_AUTHENTICATED = 4, 
  TINYSEC_RECEIVE_CRC = 5, 
  TINYSEC_RECEIVE_ANY = 6, 
  TINYSEC_ENABLED_BIT = 128, 
  TINYSEC_ENCRYPT_ENABLED_BIT = 64
} __attribute((packed)) ;


typedef TOS_Msg *TOS_MsgPtr;
static inline 
# 57 "/root/src/tinyos-1.x/beta/TOSSIM-packet/packet_sim.h"
void packet_sim_init(char *cFile);
static inline result_t packet_sim_transmit(TOS_MsgPtr msg);
void   packet_sim_transmit_done(TOS_MsgPtr msg);
TOS_MsgPtr   packet_sim_receive_msg(TOS_MsgPtr msg);
# 56 "/usr/include/sys/time.h" 3
struct timezone {

  int tz_minuteswest;
  int tz_dsttime;
};

typedef struct timezone *__restrict __timezone_ptr_t;









extern int gettimeofday(struct timeval *__restrict __tv, 
__timezone_ptr_t __tz);
#line 91
enum __itimer_which {


  ITIMER_REAL = 0, 


  ITIMER_VIRTUAL = 1, 



  ITIMER_PROF = 2
};




struct itimerval {


  struct timeval it_interval;

  struct timeval it_value;
};






typedef int __itimer_which_t;
# 84 "/root/src/tinyos-1.x/beta/TOSSIM-packet/nido.h"
typedef struct TOS_node_state {
  long long time;
  int pot_setting;
} TOS_node_state_t;

typedef struct TOS_state {
  long long tos_time;
  int radio_kb_rate;
  short num_nodes;
  short current_node;
  TOS_node_state_t node_state[TOSNODES];
  event_queue_t queue;
  uint8_t radioModel;
  rfm_model *rfm;
  adc_model *adc;
  spatial_model *space;
  bool moteOn[TOSNODES];
  bool cancelBoot[TOSNODES];


  bool paused;
  pthread_mutex_t pause_lock;
  pthread_cond_t pause_cond;
  pthread_cond_t pause_ack_cond;
} TOS_state_t;






extern TOS_state_t tos_state;




void set_sim_rate(uint32_t );
uint32_t get_sim_rate(void);
static void __nesc_nido_initialise(int mote);
# 54 "/root/src/tinyos-1.x/tos/types/dbg_modes.h"
typedef long long TOS_dbg_mode;



enum __nesc_unnamed4311 {
  DBG_ALL = ~0ULL, 


  DBG_BOOT = 1ULL << 0, 
  DBG_CLOCK = 1ULL << 1, 
  DBG_TASK = 1ULL << 2, 
  DBG_SCHED = 1ULL << 3, 
  DBG_SENSOR = 1ULL << 4, 
  DBG_LED = 1ULL << 5, 
  DBG_CRYPTO = 1ULL << 6, 


  DBG_ROUTE = 1ULL << 7, 
  DBG_AM = 1ULL << 8, 
  DBG_CRC = 1ULL << 9, 
  DBG_PACKET = 1ULL << 10, 
  DBG_ENCODE = 1ULL << 11, 
  DBG_RADIO = 1ULL << 12, 


  DBG_LOG = 1ULL << 13, 
  DBG_ADC = 1ULL << 14, 
  DBG_I2C = 1ULL << 15, 
  DBG_UART = 1ULL << 16, 
  DBG_PROG = 1ULL << 17, 
  DBG_SOUNDER = 1ULL << 18, 
  DBG_TIME = 1ULL << 19, 




  DBG_SIM = 1ULL << 21, 
  DBG_QUEUE = 1ULL << 22, 
  DBG_SIMRADIO = 1ULL << 23, 
  DBG_HARD = 1ULL << 24, 
  DBG_MEM = 1ULL << 25, 



  DBG_USR1 = 1ULL << 27, 
  DBG_USR2 = 1ULL << 28, 
  DBG_USR3 = 1ULL << 29, 
  DBG_TEMP = 1ULL << 30, 

  DBG_ERROR = 1ULL << 31, 
  DBG_NONE = 0, 

  DBG_DEFAULT = DBG_ALL
};
static inline 
# 129 "/root/src/tinyos-1.x/beta/TOSSIM-packet/nido.h"
void tos_state_model_init(void );
static inline 
# 48 "/root/src/tinyos-1.x/tos/platform/pc/hardware.nido.h"
void init_hardware(void);
#line 199
enum __nesc_unnamed4312 {
  TOSH_period16 = 0x00, 
  TOSH_period32 = 0x01, 
  TOSH_period64 = 0x02, 
  TOSH_period128 = 0x03, 
  TOSH_period256 = 0x04, 
  TOSH_period512 = 0x05, 
  TOSH_period1024 = 0x06, 
  TOSH_period2048 = 0x07
};
# 42 "/usr/include/bits/uio.h"
struct iovec {

  void *iov_base;
  size_t iov_len;
};
# 36 "/usr/include/bits/socket.h"
typedef __socklen_t socklen_t;




enum __socket_type {

  SOCK_STREAM = 1, 


  SOCK_DGRAM = 2, 


  SOCK_RAW = 3, 

  SOCK_RDM = 4, 

  SOCK_SEQPACKET = 5, 


  SOCK_PACKET = 10
};
# 29 "/usr/include/bits/sockaddr.h"
typedef unsigned short int sa_family_t;
# 145 "/usr/include/bits/socket.h"
struct sockaddr {

  sa_family_t sa_family;
  char sa_data[14];
};
#line 162
struct sockaddr_storage {

  sa_family_t ss_family;
  __uint32_t __ss_align;
  char __ss_padding[128 - 2 * sizeof(__uint32_t )];
};



enum __nesc_unnamed4313 {

  MSG_OOB = 0x01, 

  MSG_PEEK = 0x02, 

  MSG_DONTROUTE = 0x04, 






  MSG_CTRUNC = 0x08, 

  MSG_PROXY = 0x10, 

  MSG_TRUNC = 0x20, 

  MSG_DONTWAIT = 0x40, 

  MSG_EOR = 0x80, 

  MSG_WAITALL = 0x100, 

  MSG_FIN = 0x200, 

  MSG_SYN = 0x400, 

  MSG_CONFIRM = 0x800, 

  MSG_RST = 0x1000, 

  MSG_ERRQUEUE = 0x2000, 

  MSG_NOSIGNAL = 0x4000, 

  MSG_MORE = 0x8000
};





struct msghdr {

  void *msg_name;
  socklen_t msg_namelen;

  struct iovec *msg_iov;
  size_t msg_iovlen;

  void *msg_control;
  size_t msg_controllen;

  int msg_flags;
};


struct cmsghdr {

  size_t cmsg_len;

  int cmsg_level;
  int cmsg_type;

  __extension__ unsigned char __cmsg_data[];
};
#line 257
struct cmsghdr;
# 284 "/usr/include/bits/socket.h" 3
enum __nesc_unnamed4314 {

  SCM_RIGHTS = 0x01, 


  SCM_CREDENTIALS = 0x02, 


  __SCM_CONNECT = 0x03
};



struct ucred {

  pid_t pid;
  uid_t uid;
  gid_t gid;
};
# 309 "/usr/include/bits/socket.h"
struct linger {

  int l_onoff;
  int l_linger;
};
# 40 "/usr/include/sys/socket.h"
struct osockaddr {

  unsigned short int sa_family;
  unsigned char sa_data[14];
};




enum __nesc_unnamed4315 {

  SHUT_RD = 0, 

  SHUT_WR, 

  SHUT_RDWR
};
# 100 "/usr/include/sys/socket.h" 3
extern int socket(int __domain, int __type, int __protocol);









extern int bind(int __fd, const struct sockaddr *__addr, socklen_t __len);
#line 136
extern ssize_t send(int __fd, const void *__buf, size_t __n, int __flags);
#line 192
extern int setsockopt(int __fd, int __level, int __optname, 
const void *__optval, socklen_t __optlen);





extern int listen(int __fd, int __n);









extern int accept(int __fd, struct sockaddr *__restrict __addr, 
socklen_t *__restrict __addr_len);
# 31 "/usr/include/netinet/in.h"
enum __nesc_unnamed4316 {

  IPPROTO_IP = 0, 

  IPPROTO_HOPOPTS = 0, 

  IPPROTO_ICMP = 1, 

  IPPROTO_IGMP = 2, 

  IPPROTO_IPIP = 4, 

  IPPROTO_TCP = 6, 

  IPPROTO_EGP = 8, 

  IPPROTO_PUP = 12, 

  IPPROTO_UDP = 17, 

  IPPROTO_IDP = 22, 

  IPPROTO_TP = 29, 

  IPPROTO_IPV6 = 41, 

  IPPROTO_ROUTING = 43, 

  IPPROTO_FRAGMENT = 44, 

  IPPROTO_RSVP = 46, 

  IPPROTO_GRE = 47, 

  IPPROTO_ESP = 50, 

  IPPROTO_AH = 51, 

  IPPROTO_ICMPV6 = 58, 

  IPPROTO_NONE = 59, 

  IPPROTO_DSTOPTS = 60, 

  IPPROTO_MTP = 92, 

  IPPROTO_ENCAP = 98, 

  IPPROTO_PIM = 103, 

  IPPROTO_COMP = 108, 

  IPPROTO_SCTP = 132, 

  IPPROTO_RAW = 255, 

  IPPROTO_MAX
};



typedef uint16_t in_port_t;


enum __nesc_unnamed4317 {

  IPPORT_ECHO = 7, 
  IPPORT_DISCARD = 9, 
  IPPORT_SYSTAT = 11, 
  IPPORT_DAYTIME = 13, 
  IPPORT_NETSTAT = 15, 
  IPPORT_FTP = 21, 
  IPPORT_TELNET = 23, 
  IPPORT_SMTP = 25, 
  IPPORT_TIMESERVER = 37, 
  IPPORT_NAMESERVER = 42, 
  IPPORT_WHOIS = 43, 
  IPPORT_MTP = 57, 

  IPPORT_TFTP = 69, 
  IPPORT_RJE = 77, 
  IPPORT_FINGER = 79, 
  IPPORT_TTYLINK = 87, 
  IPPORT_SUPDUP = 95, 


  IPPORT_EXECSERVER = 512, 
  IPPORT_LOGINSERVER = 513, 
  IPPORT_CMDSERVER = 514, 
  IPPORT_EFSSERVER = 520, 


  IPPORT_BIFFUDP = 512, 
  IPPORT_WHOSERVER = 513, 
  IPPORT_ROUTESERVER = 520, 


  IPPORT_RESERVED = 1024, 


  IPPORT_USERRESERVED = 5000
};



typedef uint32_t in_addr_t;
struct in_addr {

  in_addr_t s_addr;
};
#line 193
struct in6_addr {

  union __nesc_unnamed4318 {

    uint8_t u6_addr8[16];
    uint16_t u6_addr16[8];
    uint32_t u6_addr32[4];
  } in6_u;
};




struct in6_addr;
struct in6_addr;
#line 219
struct sockaddr_in {

  sa_family_t sin_family;
  in_port_t sin_port;
  struct in_addr sin_addr;


  unsigned char sin_zero

  [
#line 226
  sizeof(struct sockaddr ) - 
  sizeof(unsigned short int ) - 
  sizeof(in_port_t ) - 
  sizeof(struct in_addr )];
};


struct sockaddr_in6 {

  sa_family_t sin6_family;
  in_port_t sin6_port;
  uint32_t sin6_flowinfo;
  struct in6_addr sin6_addr;
  uint32_t sin6_scope_id;
};


struct ipv6_mreq {


  struct in6_addr ipv6mr_multiaddr;


  unsigned int ipv6mr_interface;
};
# 66 "/usr/include/bits/in.h"
struct ip_opts {

  struct in_addr ip_dst;
  char ip_opts[40];
};


struct ip_mreq {

  struct in_addr imr_multiaddr;
  struct in_addr imr_interface;
};


struct ip_mreqn {

  struct in_addr imr_multiaddr;
  struct in_addr imr_address;
  int imr_ifindex;
};


struct in_pktinfo {

  int ipi_ifindex;
  struct in_addr ipi_spec_dst;
  struct in_addr ipi_addr;
};
# 263 "/usr/include/netinet/in.h"
extern uint16_t 
__attribute((const)) 
#line 263
ntohs(uint16_t __netshort);

extern uint32_t 
__attribute((const)) 
#line 265
htonl(uint32_t __hostlong);

extern uint16_t 
__attribute((const)) 
#line 267
htons(uint16_t __hostshort);
# 364 "/usr/include/netinet/in.h" 3
struct in6_pktinfo {

  struct in6_addr ipi6_addr;
  unsigned int ipi6_ifindex;
};
# 286 "/usr/include/unistd.h" 3
extern __off_t lseek(int __fd, __off_t __offset, int __whence);
#line 305
extern int close(int __fd);






extern ssize_t read(int __fd, void *__buf, size_t __nbytes);





extern ssize_t write(int __fd, const void *__buf, size_t __n);
#line 390
extern unsigned int sleep(unsigned int __seconds);
#line 405
extern int usleep(__useconds_t __useconds);
# 25 "/usr/include/bits/confname.h"
enum __nesc_unnamed4319 {

  _PC_LINK_MAX, 

  _PC_MAX_CANON, 

  _PC_MAX_INPUT, 

  _PC_NAME_MAX, 

  _PC_PATH_MAX, 

  _PC_PIPE_BUF, 

  _PC_CHOWN_RESTRICTED, 

  _PC_NO_TRUNC, 

  _PC_VDISABLE, 

  _PC_SYNC_IO, 

  _PC_ASYNC_IO, 

  _PC_PRIO_IO, 

  _PC_SOCK_MAXBUF, 

  _PC_FILESIZEBITS, 

  _PC_REC_INCR_XFER_SIZE, 

  _PC_REC_MAX_XFER_SIZE, 

  _PC_REC_MIN_XFER_SIZE, 

  _PC_REC_XFER_ALIGN, 

  _PC_ALLOC_SIZE_MIN, 

  _PC_SYMLINK_MAX, 

  _PC_2_SYMLINKS
};



enum __nesc_unnamed4320 {

  _SC_ARG_MAX, 

  _SC_CHILD_MAX, 

  _SC_CLK_TCK, 

  _SC_NGROUPS_MAX, 

  _SC_OPEN_MAX, 

  _SC_STREAM_MAX, 

  _SC_TZNAME_MAX, 

  _SC_JOB_CONTROL, 

  _SC_SAVED_IDS, 

  _SC_REALTIME_SIGNALS, 

  _SC_PRIORITY_SCHEDULING, 

  _SC_TIMERS, 

  _SC_ASYNCHRONOUS_IO, 

  _SC_PRIORITIZED_IO, 

  _SC_SYNCHRONIZED_IO, 

  _SC_FSYNC, 

  _SC_MAPPED_FILES, 

  _SC_MEMLOCK, 

  _SC_MEMLOCK_RANGE, 

  _SC_MEMORY_PROTECTION, 

  _SC_MESSAGE_PASSING, 

  _SC_SEMAPHORES, 

  _SC_SHARED_MEMORY_OBJECTS, 

  _SC_AIO_LISTIO_MAX, 

  _SC_AIO_MAX, 

  _SC_AIO_PRIO_DELTA_MAX, 

  _SC_DELAYTIMER_MAX, 

  _SC_MQ_OPEN_MAX, 

  _SC_MQ_PRIO_MAX, 

  _SC_VERSION, 

  _SC_PAGESIZE, 


  _SC_RTSIG_MAX, 

  _SC_SEM_NSEMS_MAX, 

  _SC_SEM_VALUE_MAX, 

  _SC_SIGQUEUE_MAX, 

  _SC_TIMER_MAX, 




  _SC_BC_BASE_MAX, 

  _SC_BC_DIM_MAX, 

  _SC_BC_SCALE_MAX, 

  _SC_BC_STRING_MAX, 

  _SC_COLL_WEIGHTS_MAX, 

  _SC_EQUIV_CLASS_MAX, 

  _SC_EXPR_NEST_MAX, 

  _SC_LINE_MAX, 

  _SC_RE_DUP_MAX, 

  _SC_CHARCLASS_NAME_MAX, 


  _SC_2_VERSION, 

  _SC_2_C_BIND, 

  _SC_2_C_DEV, 

  _SC_2_FORT_DEV, 

  _SC_2_FORT_RUN, 

  _SC_2_SW_DEV, 

  _SC_2_LOCALEDEF, 


  _SC_PII, 

  _SC_PII_XTI, 

  _SC_PII_SOCKET, 

  _SC_PII_INTERNET, 

  _SC_PII_OSI, 

  _SC_POLL, 

  _SC_SELECT, 

  _SC_UIO_MAXIOV, 

  _SC_IOV_MAX = _SC_UIO_MAXIOV, 

  _SC_PII_INTERNET_STREAM, 

  _SC_PII_INTERNET_DGRAM, 

  _SC_PII_OSI_COTS, 

  _SC_PII_OSI_CLTS, 

  _SC_PII_OSI_M, 

  _SC_T_IOV_MAX, 



  _SC_THREADS, 

  _SC_THREAD_SAFE_FUNCTIONS, 

  _SC_GETGR_R_SIZE_MAX, 

  _SC_GETPW_R_SIZE_MAX, 

  _SC_LOGIN_NAME_MAX, 

  _SC_TTY_NAME_MAX, 

  _SC_THREAD_DESTRUCTOR_ITERATIONS, 

  _SC_THREAD_KEYS_MAX, 

  _SC_THREAD_STACK_MIN, 

  _SC_THREAD_THREADS_MAX, 

  _SC_THREAD_ATTR_STACKADDR, 

  _SC_THREAD_ATTR_STACKSIZE, 

  _SC_THREAD_PRIORITY_SCHEDULING, 

  _SC_THREAD_PRIO_INHERIT, 

  _SC_THREAD_PRIO_PROTECT, 

  _SC_THREAD_PROCESS_SHARED, 


  _SC_NPROCESSORS_CONF, 

  _SC_NPROCESSORS_ONLN, 

  _SC_PHYS_PAGES, 

  _SC_AVPHYS_PAGES, 

  _SC_ATEXIT_MAX, 

  _SC_PASS_MAX, 


  _SC_XOPEN_VERSION, 

  _SC_XOPEN_XCU_VERSION, 

  _SC_XOPEN_UNIX, 

  _SC_XOPEN_CRYPT, 

  _SC_XOPEN_ENH_I18N, 

  _SC_XOPEN_SHM, 


  _SC_2_CHAR_TERM, 

  _SC_2_C_VERSION, 

  _SC_2_UPE, 


  _SC_XOPEN_XPG2, 

  _SC_XOPEN_XPG3, 

  _SC_XOPEN_XPG4, 


  _SC_CHAR_BIT, 

  _SC_CHAR_MAX, 

  _SC_CHAR_MIN, 

  _SC_INT_MAX, 

  _SC_INT_MIN, 

  _SC_LONG_BIT, 

  _SC_WORD_BIT, 

  _SC_MB_LEN_MAX, 

  _SC_NZERO, 

  _SC_SSIZE_MAX, 

  _SC_SCHAR_MAX, 

  _SC_SCHAR_MIN, 

  _SC_SHRT_MAX, 

  _SC_SHRT_MIN, 

  _SC_UCHAR_MAX, 

  _SC_UINT_MAX, 

  _SC_ULONG_MAX, 

  _SC_USHRT_MAX, 


  _SC_NL_ARGMAX, 

  _SC_NL_LANGMAX, 

  _SC_NL_MSGMAX, 

  _SC_NL_NMAX, 

  _SC_NL_SETMAX, 

  _SC_NL_TEXTMAX, 


  _SC_XBS5_ILP32_OFF32, 

  _SC_XBS5_ILP32_OFFBIG, 

  _SC_XBS5_LP64_OFF64, 

  _SC_XBS5_LPBIG_OFFBIG, 


  _SC_XOPEN_LEGACY, 

  _SC_XOPEN_REALTIME, 

  _SC_XOPEN_REALTIME_THREADS, 


  _SC_ADVISORY_INFO, 

  _SC_BARRIERS, 

  _SC_BASE, 

  _SC_C_LANG_SUPPORT, 

  _SC_C_LANG_SUPPORT_R, 

  _SC_CLOCK_SELECTION, 

  _SC_CPUTIME, 

  _SC_THREAD_CPUTIME, 

  _SC_DEVICE_IO, 

  _SC_DEVICE_SPECIFIC, 

  _SC_DEVICE_SPECIFIC_R, 

  _SC_FD_MGMT, 

  _SC_FIFO, 

  _SC_PIPE, 

  _SC_FILE_ATTRIBUTES, 

  _SC_FILE_LOCKING, 

  _SC_FILE_SYSTEM, 

  _SC_MONOTONIC_CLOCK, 

  _SC_MULTI_PROCESS, 

  _SC_SINGLE_PROCESS, 

  _SC_NETWORKING, 

  _SC_READER_WRITER_LOCKS, 

  _SC_SPIN_LOCKS, 

  _SC_REGEXP, 

  _SC_REGEX_VERSION, 

  _SC_SHELL, 

  _SC_SIGNALS, 

  _SC_SPAWN, 

  _SC_SPORADIC_SERVER, 

  _SC_THREAD_SPORADIC_SERVER, 

  _SC_SYSTEM_DATABASE, 

  _SC_SYSTEM_DATABASE_R, 

  _SC_TIMEOUTS, 

  _SC_TYPED_MEMORY_OBJECTS, 

  _SC_USER_GROUPS, 

  _SC_USER_GROUPS_R, 

  _SC_2_PBS, 

  _SC_2_PBS_ACCOUNTING, 

  _SC_2_PBS_LOCATE, 

  _SC_2_PBS_MESSAGE, 

  _SC_2_PBS_TRACK, 

  _SC_SYMLOOP_MAX, 

  _SC_STREAMS, 

  _SC_2_PBS_CHECKPOINT, 


  _SC_V6_ILP32_OFF32, 

  _SC_V6_ILP32_OFFBIG, 

  _SC_V6_LP64_OFF64, 

  _SC_V6_LPBIG_OFFBIG, 


  _SC_HOST_NAME_MAX, 

  _SC_TRACE, 

  _SC_TRACE_EVENT_FILTER, 

  _SC_TRACE_INHERIT, 

  _SC_TRACE_LOG
};



enum __nesc_unnamed4321 {

  _CS_PATH, 


  _CS_V6_WIDTH_RESTRICTED_ENVS, 


  _CS_GNU_LIBC_VERSION, 

  _CS_GNU_LIBPTHREAD_VERSION, 


  _CS_LFS_CFLAGS = 1000, 

  _CS_LFS_LDFLAGS, 

  _CS_LFS_LIBS, 

  _CS_LFS_LINTFLAGS, 

  _CS_LFS64_CFLAGS, 

  _CS_LFS64_LDFLAGS, 

  _CS_LFS64_LIBS, 

  _CS_LFS64_LINTFLAGS, 


  _CS_XBS5_ILP32_OFF32_CFLAGS = 1100, 

  _CS_XBS5_ILP32_OFF32_LDFLAGS, 

  _CS_XBS5_ILP32_OFF32_LIBS, 

  _CS_XBS5_ILP32_OFF32_LINTFLAGS, 

  _CS_XBS5_ILP32_OFFBIG_CFLAGS, 

  _CS_XBS5_ILP32_OFFBIG_LDFLAGS, 

  _CS_XBS5_ILP32_OFFBIG_LIBS, 

  _CS_XBS5_ILP32_OFFBIG_LINTFLAGS, 

  _CS_XBS5_LP64_OFF64_CFLAGS, 

  _CS_XBS5_LP64_OFF64_LDFLAGS, 

  _CS_XBS5_LP64_OFF64_LIBS, 

  _CS_XBS5_LP64_OFF64_LINTFLAGS, 

  _CS_XBS5_LPBIG_OFFBIG_CFLAGS, 

  _CS_XBS5_LPBIG_OFFBIG_LDFLAGS, 

  _CS_XBS5_LPBIG_OFFBIG_LIBS, 

  _CS_XBS5_LPBIG_OFFBIG_LINTFLAGS, 


  _CS_POSIX_V6_ILP32_OFF32_CFLAGS, 

  _CS_POSIX_V6_ILP32_OFF32_LDFLAGS, 

  _CS_POSIX_V6_ILP32_OFF32_LIBS, 

  _CS_POSIX_V6_ILP32_OFF32_LINTFLAGS, 

  _CS_POSIX_V6_ILP32_OFFBIG_CFLAGS, 

  _CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS, 

  _CS_POSIX_V6_ILP32_OFFBIG_LIBS, 

  _CS_POSIX_V6_ILP32_OFFBIG_LINTFLAGS, 

  _CS_POSIX_V6_LP64_OFF64_CFLAGS, 

  _CS_POSIX_V6_LP64_OFF64_LDFLAGS, 

  _CS_POSIX_V6_LP64_OFF64_LIBS, 

  _CS_POSIX_V6_LP64_OFF64_LINTFLAGS, 

  _CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS, 

  _CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS, 

  _CS_POSIX_V6_LPBIG_OFFBIG_LIBS, 

  _CS_POSIX_V6_LPBIG_OFFBIG_LINTFLAGS
};
# 736 "/usr/include/unistd.h" 3
extern int unlink(const char *__name);
# 38 "/usr/include/bits/errno.h"
extern int __attribute((const)) *__errno_location(void );
 
# 46 "/root/src/tinyos-1.x/tos/platform/pc/external_comm.h"
static int socketsInitialized = 0;
static inline void initializeSockets(void);
static inline int readTossimCommand(int clifd);
static void buildTossimEvent(uint16_t moteID, uint16_t type, long long ftime, void *data, 
unsigned char **msgp, int *lenp);
static void sendTossimEvent(uint16_t moteID, uint16_t type, long long ftime, void *data);
static int writeTossimEvent(void *data, int datalen, int clifd);
static inline 



int printTime(char *buf, int len);
static int printOtherTime(char *buf, int len, long long int ftime);
# 105 "/usr/lib/gcc-lib/i386-redhat-linux/3.3.2/include/stdarg.h" 3
typedef __gnuc_va_list va_list;
# 58 "/root/src/tinyos-1.x/tos/platform/pc/GuiMsg.h"
enum __nesc_unnamed4322 {

  AM_DEBUGMSGEVENT = 1, 
  AM_RADIOMSGSENTEVENT = 1 << 1, 
  AM_UARTMSGSENTEVENT = 1 << 2, 
  AM_ADCDATAREADYEVENT = 1 << 3, 
  AM_TOSSIMINITEVENT = 1 << 4, 
  AM_INTERRUPTEVENT = 1 << 5, 
  AM_LEDEVENT = 1 << 6, 






  AM_TURNONMOTECOMMAND = 1 << 12, 
  AM_TURNOFFMOTECOMMAND, 
  AM_RADIOMSGSENDCOMMAND, 
  AM_UARTMSGSENDCOMMAND, 
  AM_SETLINKPROBCOMMAND, 
  AM_SETADCPORTVALUECOMMAND, 
  AM_INTERRUPTCOMMAND, 
  AM_SETRATECOMMAND, 
  AM_SETDBGCOMMAND, 
  AM_VARIABLERESOLVECOMMAND, 
  AM_VARIABLERESOLVERESPONSE, 
  AM_VARIABLEREQUESTCOMMAND, 
  AM_VARIABLEREQUESTRESPONSE, 
  AM_GETMOTECOUNTCOMMAND, 
  AM_GETMOTECOUNTRESPONSE
};




typedef struct GuiMsg {
  uint16_t msgType;
  uint16_t moteID;
  long long time;
  uint16_t payLoadLen;
} GuiMsg;






typedef struct DebugMsgEvent {
  char debugMessage[512];
} DebugMsgEvent;


typedef struct RadioMsgSentEvent {
  TOS_Msg message;
} RadioMsgSentEvent;


typedef struct UARTMsgSentEvent {
  TOS_Msg message;
} UARTMsgSentEvent;


typedef struct ADCDataReadyEvent {
  uint8_t port;
  uint16_t data;
} ADCDataReadyEvent;


typedef struct VariableResolveResponse {
  uint32_t addr;
  uint8_t length;
} VariableResolveResponse;


typedef struct VariableRequestResponse {
  uint8_t length;
  char value[256];
} VariableRequestResponse;


typedef struct TossimInitEvent {
  int numMotes;
  uint8_t radioModel;
  uint32_t rate;
} __attribute((packed))  TossimInitEvent;


typedef struct InterruptEvent {
  uint32_t id;
} InterruptEvent;


typedef struct TurnOnMoteCommand {
} TurnOnMoteCommand;


typedef struct TurnOffMoteCommand {
} TurnOffMoteCommand;


typedef struct RadioMsgSendCommand {
  TOS_Msg message;
} RadioMsgSendCommand;


typedef struct UARTMsgSendCommand {
  TOS_Msg message;
} UARTMsgSendCommand;


typedef struct SetLinkProbCommand {
  uint16_t moteReceiver;
  uint32_t scaledProb;
} SetLinkProbCommand;


typedef struct SetADCPortValueCommand {
  uint8_t port;
  uint16_t value;
} SetADCPortValueCommand;


typedef struct VariableResolveCommand {
  char name[256];
} VariableResolveCommand;


typedef struct VariableRequestCommand {
  uint32_t addr;
  uint8_t length;
} VariableRequestCommand;

typedef struct InterruptCommand {
  uint32_t id;
} InterruptCommand;

typedef struct SetRateCommand {
  uint32_t rate;
} SetRateCommand;

typedef struct LedEvent {
  uint8_t red : 1;
  uint8_t green : 1;
  uint8_t yellow : 1;
} LedEvent;

typedef struct SetDBGCommand {
  long long dbg;
} SetDBGCommand;

typedef struct GetMoteCountCommand {
  uint8_t placeholder;
} GetMoteCountCommand;

typedef struct GetMoteCountResponse {
  uint16_t totalMotes;
  uint8_t bitmask[(TOSNODES + 7) / 8];
} GetMoteCountResponse;
# 72 "/root/src/tinyos-1.x/tos/types/dbg.h"
typedef struct dbg_mode {
  char *d_name;
  unsigned long long d_mode;
} TOS_dbg_mode_names;

TOS_dbg_mode dbg_modes = 0;

static bool dbg_active(TOS_dbg_mode mode);




static void dbg_add_mode(const char *mode);
static void dbg_add_modes(const char *modes);
static void dbg_init(void );
static void dbg_help(void );

static void dbg_set(TOS_dbg_mode );

static void dbg(TOS_dbg_mode mode, const char *format, ...);
#line 109
static void dbg_clear(TOS_dbg_mode mode, const char *format, ...);
# 66 "/root/src/tinyos-1.x/tos/platform/pc/hardware.h"
extern  TOS_dbg_mode dbg_modes;
 

TOS_state_t tos_state;
#line 86
typedef uint8_t __nesc_atomic_t;

__inline __nesc_atomic_t  __nesc_atomic_start(void );




__inline void  __nesc_atomic_end(__nesc_atomic_t oldSreg);







enum __nesc_unnamed4323 {
  TOSH_ADC_PORTMAPSIZE = 255
};
# 48 "/root/src/tinyos-1.x/tos/platform/pc/heap_array.c"
const int STARTING_SIZE = 511;



typedef struct node {
  void *data;
  long long key;
} node_t;
static 
void down_heap(heap_t *heap, int findex);
static void up_heap(heap_t *heap, int findex);
static void swap(node_t *first, node_t *second);
static inline 







void init_heap(heap_t *heap);
static inline 








int is_empty(heap_t *heap);
static inline 


int heap_is_empty(heap_t *heap);
static inline 


long long heap_get_min_key(heap_t *heap);
static 
#line 104
void *heap_pop_min_data(heap_t *heap, long long *key);
static inline 
#line 120
void expand_heap(heap_t *heap);
static inline 
#line 134
void heap_insert(heap_t *heap, void *data, long long key);
static 
#line 148
void swap(node_t *first, node_t *second);
static 
#line 161
void down_heap(heap_t *heap, int findex);
static 
#line 187
void up_heap(heap_t *heap, int findex);
 
# 41 "/root/src/tinyos-1.x/tos/platform/pc/hardware.c"
struct __nesc_unnamed4324 {
  char status_register;
  char register_A;
  char register_B;
  char register_C;
  char register_D;
  char register_E;
  char register_default;
} TOSH_pc_hardware;
static inline 
void init_hardware(void);
# 47 "/root/src/tinyos-1.x/tos/platform/pc/event_queue.c"
struct timespec;
static inline 


void queue_init(event_queue_t *queue, int fpause);
static 




void queue_insert_event(event_queue_t *queue, event_t *event);
static inline 




event_t *queue_pop_event(event_queue_t *queue);
static inline 
#line 86
int queue_is_empty(event_queue_t *queue);
static inline 






long long queue_peek_event_time(event_queue_t *queue);
static inline 
#line 109
void queue_handle_next_event(event_queue_t *queue);
static inline 
# 43 "/root/src/tinyos-1.x/tos/platform/pc/events.c"
void event_default_cleanup(event_t *event);
static 



void event_total_cleanup(event_t *event);
static inline 






void event_cleanup(event_t *fevent);
# 36 "/root/src/tinyos-1.x/tos/platform/pc/hpl.c"
static int clockScales[8] = { -1, 122, 976, 3906, 7812, 15625, 31250, 125000 };
 
static event_t *clockEvents[TOSNODES];
 static uint8_t intervals[TOSNODES];
 static uint8_t scales[TOSNODES];
 static long long setTime[TOSNODES];
 static uint8_t interruptPending[TOSNODES];
static inline 
void  SIG_OUTPUT_COMPARE2_interrupt(void );
static 





void TOSH_clock_set_rate(char interval, char scale);
static inline 
#line 86
uint8_t TOSH_get_clock0_counter(void);
#line 116
struct timeval;
static inline 
void event_clocktick_handle(event_t *event, 
struct TOS_state *state);
static inline 
#line 152
void event_clocktick_create(event_t *event, int mote, long long eventTime, int interval);
static inline 
#line 172
void event_clocktick_invalidate(event_t *event);










enum __nesc_unnamed4325 {
  ADC_LATENCY = 200
};
#line 306
enum __nesc_unnamed4326 {
  NOT_WAITING = 0, 
  WAITING_FOR_ONE_TO_PASS = 1, 
  WAITING_FOR_ONE_TO_CAPTURE = 2
};
#line 431
void   event_spi_byte_create(event_t *fevent, int mote, long long ftime, int interval, int count);
# 46 "/root/src/tinyos-1.x/tos/platform/pc/dbg.c"
static TOS_dbg_mode_names dbg_nametab[33] = { 
{ "all", DBG_ALL }, { "boot", DBG_BOOT | DBG_ERROR }, { "clock", DBG_CLOCK | DBG_ERROR }, { "task", DBG_TASK | DBG_ERROR }, { "sched", DBG_SCHED | DBG_ERROR }, { "sensor", DBG_SENSOR | DBG_ERROR }, { "led", DBG_LED | DBG_ERROR }, { "crypto", DBG_CRYPTO | DBG_ERROR }, { "route", DBG_ROUTE | DBG_ERROR }, { "am", DBG_AM | DBG_ERROR }, { "crc", DBG_CRC | DBG_ERROR }, { "packet", DBG_PACKET | DBG_ERROR }, { "encode", DBG_ENCODE | DBG_ERROR }, { "radio", DBG_RADIO | DBG_ERROR }, { "logger", DBG_LOG | DBG_ERROR }, { "adc", DBG_ADC | DBG_ERROR }, { "i2c", DBG_I2C | DBG_ERROR }, { "uart", DBG_UART | DBG_ERROR }, { "prog", DBG_PROG | DBG_ERROR }, { "sounder", DBG_SOUNDER | DBG_ERROR }, { "time", DBG_TIME | DBG_ERROR }, { "sim", DBG_SIM | DBG_ERROR }, { "queue", DBG_QUEUE | DBG_ERROR }, { "simradio", DBG_SIMRADIO | DBG_ERROR }, { "hardware", DBG_HARD | DBG_ERROR }, { "simmem", DBG_MEM | DBG_ERROR }, { "usr1", DBG_USR1 | DBG_ERROR }, { "usr2", DBG_USR2 | DBG_ERROR }, { "usr3", DBG_USR3 | DBG_ERROR }, { "temp", DBG_TEMP | DBG_ERROR }, { "error", DBG_ERROR }, { "none", DBG_NONE }, { (void *)0, DBG_ERROR } };






void dbg_set(TOS_dbg_mode modes);



void dbg_add_mode(const char *name);
#line 84
void dbg_add_modes(const char *modes);








void dbg_init(void );
#line 107
void dbg_help(void );
# 65 "/root/src/tinyos-1.x/tos/platform/pc/external_comm.c"
int commandServerSocket = -1;
int eventServerSocket = -1;
int commandClients[4];
 int eventClients[4];

pthread_t clientAcceptThread;
pthread_t commandReadThread;
pthread_mutex_t commandClientsLock;
pthread_cond_t commandClientsCond;
pthread_mutex_t eventClientsLock;
pthread_cond_t eventClientsCond;


TOS_Msg external_comm_msgs_[TOSNODES];
TOS_MsgPtr external_comm_buffers_[TOSNODES];
 static int GUI_enabled;
static 
int createServerSocket(short port);
static inline void *clientAcceptThreadFunc(void *arg);
static inline void *commandReadThreadFunc(void *arg);



static int __nesc_nido_resolve(int __nesc_mote, 
char *varname, 
uint32_t *addr, uint8_t *size);
static inline 
#line 107
void initializeSockets(void);
static 
#line 134
int acceptConnection(int servfd);
static 
#line 150
int createServerSocket(short port);
static inline 
#line 207
void waitForGuiConnection(void);
static 
#line 227
int printOtherTime(char *buf, int len, long long int ftime);
static inline 
#line 244
int printTime(char *buf, int len);
static 


void addClient(int *clientSockets, int clifd);
static inline 
#line 262
void sendInitEvent(int clifd);
static inline 
#line 281
void *clientAcceptThreadFunc(void *arg);
#line 329
typedef struct __nesc_unnamed4327 {
  GuiMsg *msg;
  char *payLoad;
} incoming_command_data_t;



void nido_start_mote(uint16_t moteID);
void nido_stop_mote(uint16_t moteID);
TOS_MsgPtr NIDO_received_radio(TOS_MsgPtr packet);
TOS_MsgPtr NIDO_received_uart(TOS_MsgPtr packet);
static inline void set_link_prob_value(uint16_t moteID1, uint16_t moteID2, double prob);
static inline 
void event_command_cleanup(event_t *event);
static inline 




void event_command_in_handle(event_t *event, 
struct TOS_state *state);
static inline void event_command_in_create(event_t *event, 
GuiMsg *msg, 
char *payLoad);
static inline 
#line 372
int processCommand(int clifd, GuiMsg *msg, char *payLoad, 
unsigned char **replyMsg, int *replyLen);
static inline 
#line 467
void event_command_in_handle(event_t *event, 
struct TOS_state *state);
static inline 
#line 538
int readTossimCommand(int clifd);
static inline 
#line 626
void *commandReadThreadFunc(void *arg);
static 
#line 702
int writeTossimEvent(void *data, int datalen, int clifd);
static 
#line 733
void buildTossimEvent(uint16_t moteID, uint16_t type, long long ftime, void *data, 
unsigned char **msgp, int *lenp);
static 
#line 793
void sendTossimEvent(uint16_t moteID, uint16_t type, long long ftime, void *data);
# 32 "/root/src/tinyos-1.x/tos/platform/pc/tos.c"
int signaled = 0;

long long rate_checkpoint_time;
double rate_value;

struct timeval startTime;
struct timeval thisTime;
static inline 
void handle_signal(int sig);
static inline 
#line 52
void init_signals(void );
static inline 
#line 72
double get_rate_value(void);
static inline 


void set_rate_value(double rate);
static inline 


void rate_checkpoint(void);
static inline 




void rate_based_wait(void);
static inline 
# 48 "/root/src/tinyos-1.x/tos/platform/pc/adc_model.c"
void random_adc_init(void);
static inline 
uint16_t random_adc_read(int moteID, uint8_t port, long long ftime);
static inline 


adc_model *create_random_adc_model(void);










enum __nesc_unnamed4328 {
  ADC_NUM_PORTS_PER_NODE = 256
};

uint16_t adcValues[TOSNODES][ADC_NUM_PORTS_PER_NODE];
pthread_mutex_t adcValuesLock;
static inline 
void generic_adc_init(void);
static inline 









uint16_t generic_adc_read(int moteID, uint8_t port, long long ftime);
static inline 
#line 99
adc_model *create_generic_adc_model(void);
static inline 





void set_adc_value(int moteID, uint8_t port, uint16_t value);
# 49 "/root/src/tinyos-1.x/tos/platform/pc/spatial_model.c"
point3D *points;
static inline 
void simple_spatial_init(void);
static inline 
#line 63
void simple_spatial_get_position(int moteID, long long ftime, point3D *point);
static inline 





spatial_model *create_simple_spatial_model(void);
# 36 "/usr/include/bits/stat.h"
struct stat {

  __dev_t st_dev;
  unsigned short int __pad1;

  __ino_t st_ino;



  __mode_t st_mode;
  __nlink_t st_nlink;
  __uid_t st_uid;
  __gid_t st_gid;
  __dev_t st_rdev;
  unsigned short int __pad2;

  __off_t st_size;



  __blksize_t st_blksize;


  __blkcnt_t st_blocks;










  struct timespec st_atim;
  struct timespec st_mtim;
  struct timespec st_ctim;
# 85 "/usr/include/bits/stat.h" 3
  unsigned long int __unused4;
  unsigned long int __unused5;
};
# 136 "/usr/include/bits/fcntl.h" 3
struct flock {

  short int l_type;
  short int l_whence;

  __off_t l_start;
  __off_t l_len;




  __pid_t l_pid;
};
# 72 "/usr/include/fcntl.h" 3
extern int open(const char *__file, int __oflag, ...);
# 51 "/root/src/tinyos-1.x/tos/platform/pc/eeprom.c"
static char *filename;
static int numMotes = 0;
static int moteSize = 0;
static int initialized = 0;
static int fd = -1;
static 
int createEEPROM(char *file, int motes, int eempromBytes);
static inline 
#line 90
int anonymousEEPROM(int fnumMotes, int eepromSize);
static inline 
#line 103
int namedEEPROM(char *name, int fnumMotes, int eepromSize);
# 59 "/root/src/tinyos-1.x/tos/system/sched.c"
typedef struct __nesc_unnamed4329 {
  void (*tp)(void);
} TOSH_sched_entry_T;

enum __nesc_unnamed4330 {
  TOSH_MAX_TASKS = 8, 
  TOSH_TASK_BITMASK = TOSH_MAX_TASKS - 1
};

TOSH_sched_entry_T TOSH_queue[TOSH_MAX_TASKS];
volatile uint8_t TOSH_sched_full;
volatile uint8_t TOSH_sched_free;
#line 98
bool  TOS_post(void (*tp)(void));
static 
#line 139
bool TOSH_run_next_task(void);
static 
# 145 "/root/src/tinyos-1.x/tos/system/tos.h"
void *nmemcpy(void *to, const void *from, size_t n);
# 87 "/root/src/tinyos-1.x/tos/types/list.h"
typedef struct list {
  struct list *l_next;
  struct list *l_prev;
} list_t;
#line 87
typedef struct list 


list_link_t;
# 4 "AbstractConstants.h"
typedef enum __nesc_unnamed4331 {
  BOMB_OPTION_FORWARD = 0x80, 
  BOMB_OPTION_FORCE = 0x40, 
  BOMB_OPTION_MASK = 0x3f
} BombillaCapsuleOption;

typedef enum __nesc_unnamed4332 {
  BOMB_CONTEXT_TIMER1 = 0, 
  BOMB_CONTEXT_ONCE = 1, 
  BOMB_CONTEXT_NUM = 2, 
  BOMB_CONTEXT_INVALID = 255
} BombillaContextType;
typedef enum __nesc_unnamed4333 {
  BOMB_CAPSULE_TIMER1 = 0, 
  BOMB_CAPSULE_ONCE = 1, 
  BOMB_CAPSULE_NUM = 2, 
  BOMB_CAPSULE_INVALID = 255
} BombillaCapsuleType;

enum __nesc_unnamed4334 {
  BOMB_CALLDEPTH = 8, 
  BOMB_OPDEPTH = 16, 
  BOMB_HEAPSIZE = 18, 
  BOMB_MAX_PARALLEL = 4, 
  BOMB_NUM_YIELDS = 4, 
  BOMB_HEADERSIZES = 3, 
  BOMB_HEADERSIZE = 6, 
  BOMB_BUF_LEN = 10, 
  BOMB_PGMSIZE = 24, 
  BOMB_BUF_NUM = 2
};

typedef enum __nesc_unnamed4335 {
  BOMB_DATA_NONE = 0, 
  BOMB_DATA_VALUE = 1, 
  BOMB_DATA_PHOTO = 2, 
  BOMB_DATA_TEMP = 3, 
  BOMB_DATA_MIC = 4, 
  BOMB_DATA_MAGX = 5, 
  BOMB_DATA_MAGY = 6, 
  BOMB_DATA_ACCELX = 7, 
  BOMB_DATA_ACCELY = 8, 
  BOMB_DATA_END = 9
} BombillaSensorType;

typedef enum __nesc_unnamed4336 {
  BOMB_TYPE_INVALID = 0, 
  BOMB_TYPE_VALUE = 1 << 0, 
  BOMB_TYPE_BUFFER = 1 << 1, 
  BOMB_TYPE_SENSE = 1 << 2
} BombillaDataType;

typedef enum __nesc_unnamed4337 {
  BOMB_VAR_V = BOMB_TYPE_VALUE, 
  BOMB_VAR_B = BOMB_TYPE_BUFFER, 
  BOMB_VAR_S = BOMB_TYPE_SENSE, 
  BOMB_VAR_VB = BOMB_VAR_V | BOMB_VAR_B, 
  BOMB_VAR_VS = BOMB_VAR_V | BOMB_VAR_S, 
  BOMB_VAR_SB = BOMB_VAR_B | BOMB_VAR_S, 
  BOMB_VAR_VSB = (BOMB_VAR_B | BOMB_VAR_S) | BOMB_VAR_V, 
  BOMB_VAR_ALL = (BOMB_VAR_B | BOMB_VAR_S) | BOMB_VAR_V
} BombillaDataCondensed;

typedef enum __nesc_unnamed4338 {
  BOMB_STATE_HALT = 0, 
  BOMB_STATE_SENDING = 1, 
  BOMB_STATE_LOG = 2, 
  BOMB_STATE_SENSE = 3, 
  BOMB_STATE_SEND_WAIT = 4, 
  BOMB_STATE_LOG_WAIT = 5, 
  BOMB_STATE_SENSE_WAIT = 6, 
  BOMB_STATE_LOCK_WAIT = 7, 
  BOMB_STATE_RESUMING = 8, 
  BOMB_STATE_RUN = 9
} BombillaContextState;

typedef enum __nesc_unnamed4339 {
  BOMB_ERROR_TRIGGERED = 0, 
  BOMB_ERROR_INVALID_RUNNABLE = 1, 
  BOMB_ERROR_STACK_OVERFLOW = 2, 
  BOMB_ERROR_STACK_UNDERFLOW = 3, 
  BOMB_ERROR_BUFFER_OVERFLOW = 4, 
  BOMB_ERROR_BUFFER_UNDERFLOW = 5, 
  BOMB_ERROR_INDEX_OUT_OF_BOUNDS = 6, 
  BOMB_ERROR_INSTRUCTION_RUNOFF = 7, 
  BOMB_ERROR_LOCK_INVALID = 8, 
  BOMB_ERROR_LOCK_STEAL = 9, 
  BOMB_ERROR_UNLOCK_INVALID = 10, 
  BOMB_ERROR_QUEUE_ENQUEUE = 11, 
  BOMB_ERROR_QUEUE_DEQUEUE = 12, 
  BOMB_ERROR_QUEUE_REMOVE = 13, 
  BOMB_ERROR_QUEUE_INVALID = 14, 
  BOMB_ERROR_RSTACK_OVERFLOW = 15, 
  BOMB_ERROR_RSTACK_UNDERFLOW = 16, 
  BOMB_ERROR_INVALID_ACCESS = 17, 
  BOMB_ERROR_TYPE_CHECK = 18, 
  BOMB_ERROR_INVALID_TYPE = 19, 
  BOMB_ERROR_INVALID_LOCK = 20, 
  BOMB_ERROR_INVALID_INSTRUCTION = 21, 
  BOMB_ERROR_INVALID_SENSOR = 22
} BombillaErrorCode;

typedef enum __nesc_unnamed4340 {
  BOMB_MAX_NET_ACTIVITY = 64, 
  BOMB_PROPAGATE_TIMER = 737, 
  BOMB_PROPAGATE_FACTOR = 0x7f
} BombillaCapsulePropagateConstants;

typedef enum __nesc_unnamed4341 {
  MOP_MASK = 0xe0, 
  MCLASS_OP = 0x40, 
  MARG_MASK = 0x07, 
  MINSTR_MASK = 0xf8, 
  VOP_MASK = 0xe0, 
  VCLASS_OP = 0x60, 
  VARG_MASK = 0x0f, 
  VINSTR_MASK = 0xf0, 
  JOP_MASK = 0xc0, 
  JCLASS_OP = 0x80, 
  JARG_MASK = 0x1f, 
  JINSTR_MASK = 0xe0, 
  XOP_MASK = 0xc0, 
  XCLASS_OP = 0xc0, 
  XARG_MASK = 0x3f, 
  XINSTR_MASK = 0xc0
} BombillaInstructionMasks;

enum __nesc_unnamed4342 {
  AM_BOMBILLAROUTEMSG = 0x1b, 
  AM_BOMBILLAVERSIONMSG = 0x1c, 
  AM_BOMBILLAERRORMSG = 0x1d, 
  AM_BOMBILLACAPSULEMSG = 0x1e, 
  AM_BOMBILLAPACKETMSG = 0x1f
};

typedef enum __nesc_unnamed4343 {

  OPadd = 0x0, 
  OPsub = 0x1, 
  OPhalt = 0x2, 
  OPland = 0x3, 
  OPlor = 0x4, 
  OPor = 0x5, 
  OPand = 0x6, 
  OPnot = 0x7, 
  OPlnot = 0x8, 
  OPdiv = 0x9, 
  OPbtail = 0xa, 
  OPeqv = 0xb, 
  OPexp = 0xc, 
  OPimp = 0xd, 
  OPlxor = 0xe, 
  OPmod = 0xf, 
  OPmul = 0x10, 
  OPbread = 0x11, 
  OPbwrite = 0x12, 
  OPpop = 0x13, 
  OPeq = 0x14, 
  OPgte = 0x15, 
  OPgt = 0x16, 
  OPlt = 0x17, 
  OPlte = 0x18, 
  OPneq = 0x19, 
  OPcopy = 0x1a, 
  OPinv = 0x1b, 
  OPputled = 0x1c, 
  OPbclear = 0x1d, 
  OPcast = 0x1e, 
  OPid = 0x1f, 
  OPuart = 0x20, 
  OPrand = 0x21, 
  OProute = 0x22, 
  OPbpush1 = 0x24, 
  OPsettimer1 = 0x26, 
  OP2pushc10 = 0x28, 
  OP2jumps10 = 0x2c, 
  OPgetlocal3 = 0x30, 
  OPsetlocal3 = 0x38, 
  OPgetvar4 = 0x40, 
  OPsetvar4 = 0x50, 
  OPpushc6 = 0x80
} BombillaInstruction;
# 79 "/root/src/tinyos-1.x/tos/lib/VM/types/Bombilla.h"
typedef struct __nesc_unnamed4344 {
  list_t queue;
} BombillaQueue;

typedef struct __nesc_unnamed4345 {
  uint8_t type;
  uint16_t var;
} BombillaSensorVariable;

typedef struct __nesc_unnamed4346 {
  uint8_t padding;
  int16_t var;
} BombillaValueVariable;

typedef struct __nesc_unnamed4347 {
  uint8_t type;
  uint8_t size;
  int16_t entries[BOMB_BUF_LEN];
} BombillaDataBuffer;

typedef struct __nesc_unnamed4348 {
  uint8_t padding;
  BombillaDataBuffer *var;
} BombillaBufferVariable;

typedef struct __nesc_unnamed4349 {
  uint8_t type;
  union  {
    BombillaSensorVariable sense;
    BombillaValueVariable value;
    BombillaBufferVariable buffer;
  } ;
} BombillaStackVariable;

typedef struct __nesc_unnamed4350 {
  uint8_t sp;
  BombillaStackVariable stack[BOMB_OPDEPTH];
} BombillaOperandStack;

typedef struct __nesc_unnamed4351 {
} 

BombillaBiBaSignature;

typedef uint32_t b_capsule_version;

typedef struct __nesc_unnamed4352 {
  b_capsule_version version;
  uint8_t type;
  uint8_t options;
  int8_t code[BOMB_PGMSIZE];
  BombillaBiBaSignature signature;
} BombillaCapsule;

typedef struct __nesc_unnamed4353 {
  bool haveSeen;
  uint8_t usedVars[(BOMB_HEAPSIZE + 7) / 8];
  BombillaCapsule capsule;
} BombillaCapsuleBuffer;

typedef struct __nesc_unnamed4354 {
  BombillaCapsuleBuffer *capsule;
  uint8_t pc;
} BombillaReturnVariable;

typedef struct __nesc_unnamed4355 {
  uint8_t sp;
  BombillaReturnVariable stack[BOMB_CALLDEPTH];
} BombillaReturnStack;

typedef struct __nesc_unnamed4356 {
  uint16_t pc;
  uint8_t state;
  BombillaCapsuleBuffer rootCapsule;
  BombillaCapsuleBuffer *currentCapsule;
  uint8_t which;
  uint8_t heldSet[(BOMB_HEAPSIZE + 7) / 8];
  uint8_t releaseSet[(BOMB_HEAPSIZE + 7) / 8];
  uint8_t acquireSet[(BOMB_HEAPSIZE + 7) / 8];
  BombillaOperandStack opStack;
  list_link_t link;
  BombillaQueue *queue;
} BombillaContext;

typedef struct __nesc_unnamed4357 {
  BombillaContext *holder;
} BombillaLock;

typedef struct BombillaErrorMsg {
  uint8_t context;
  uint8_t reason;
  uint8_t capsule;
  uint8_t instruction;
} BombillaErrorMsg;

typedef struct BombillaCapsuleMsg {
  BombillaCapsule capsule;
} BombillaCapsuleMsg;

typedef struct BombillaPacketMsg {
  int8_t header[BOMB_HEADERSIZE];
  BombillaDataBuffer payload;
} BombillaPacket;

typedef enum __nesc_unnamed4358 {
  BOMB_VERSION_VECTOR = 0, 
  BOMB_VERSION_PROGRAM = 1
} BombillaVersionMsgType;

typedef struct BombillaVersionMsg {
  uint8_t type;
  b_capsule_version versions[BOMB_CAPSULE_NUM];
  BombillaBiBaSignature signature;
} BombillaVersionMsg;
# 39 "/root/src/tinyos-1.x/tos/interfaces/Timer.h"
enum __nesc_unnamed4359 {
  TIMER_REPEAT = 0, 
  TIMER_ONE_SHOT = 1, 
  NUM_TIMERS = 9
};
# 34 "/root/src/tinyos-1.x/tos/interfaces/Clock.h"
enum __nesc_unnamed4360 {
  TOS_I1024PS = 0, TOS_S1024PS = 3, 
  TOS_I512PS = 1, TOS_S512PS = 3, 
  TOS_I256PS = 3, TOS_S256PS = 3, 
  TOS_I128PS = 7, TOS_S128PS = 3, 
  TOS_I64PS = 15, TOS_S64PS = 3, 
  TOS_I32PS = 31, TOS_S32PS = 3, 
  TOS_I16PS = 63, TOS_S16PS = 3, 
  TOS_I8PS = 127, TOS_S8PS = 3, 
  TOS_I4PS = 255, TOS_S4PS = 3, 
  TOS_I2PS = 15, TOS_S2PS = 7, 
  TOS_I1PS = 31, TOS_S1PS = 7, 
  TOS_I0PS = 0, TOS_S0PS = 0
};
enum __nesc_unnamed4361 {
  DEFAULT_SCALE = 3, DEFAULT_INTERVAL = 255
};
# 33 "/root/src/tinyos-1.x/tos/platform/pc/PCRadio.h"
typedef struct __nesc_unnamed4362 {
  TOS_MsgPtr msg;
  int success;
} uart_send_done_data_t;

enum __nesc_unnamed4363 {
  UART_SEND_DELAY = 1600
};



void NIDO_uart_send_done(TOS_MsgPtr fmsg, result_t fsuccess);
static inline 
void event_uart_write_create(event_t *uevent, int mote, long long utime, TOS_MsgPtr msg, result_t success);
static inline 
void event_uart_write_handle(event_t *uevent, 
struct TOS_state *state);
static inline 
#line 61
void event_uart_write_create(event_t *uevent, int mote, long long utime, TOS_MsgPtr msg, result_t success);
static inline 
#line 77
void TOSH_uart_send(TOS_MsgPtr msg);
static 
# 47 "/root/src/tinyos-1.x/tos/platform/pc/adjacency_list.c"
link_t *allocate_link(int mote);
static 
#line 78
int adjacency_list_init(void);
# 61 "/root/src/tinyos-1.x/tos/platform/pc/rfm_model.c"
char transmitting[TOSNODES];
int radio_active[TOSNODES];
link_t *radio_connectivity[TOSNODES];
pthread_mutex_t radioConnectivityLock;





short radio_heard[TOSNODES];

bool radio_idle_state[TOSNODES];
double noise_prob = 0;

short IDLE_STATE_MASK = 0xffff;
char *lossyFileName = "lossy.nss";
static inline 
bool simple_connected(int moteID1, int moteID2);
static inline 


void simple_init(void);
static inline 








void simple_transmit(int moteID, char bit);
static inline 







void simple_stops_transmit(int moteID);
static inline 









char simple_hears(int moteID);
static inline 
#line 124
link_t *simple_neighbors(int moteID);
static inline 






rfm_model *create_simple_model(void);
static 
#line 194
void static_one_cell_init(void);
static inline 
#line 313
bool lossy_connected(int moteID1, int moteID2);
static inline 
#line 336
void lossy_transmit(int moteID, char bit);
static inline 
#line 357
void lossy_stop_transmit(int moteID);
static inline 
#line 371
char lossy_hears(int moteID);
static inline 
#line 392
int read_lossy_entry(FILE *file, int *mote_one, int *mote_two, double *loss);
static inline 
#line 471
void lossy_init(void);
static inline 
#line 512
link_t *lossy_neighbors(int moteID);
static inline 






rfm_model *create_lossy_model(char *file);
static inline 
#line 550
void set_link_prob_value(uint16_t moteID1, uint16_t moteID2, double prob);
# 58 "/root/src/tinyos-1.x/beta/TOSSIM-packet/packet_sim.c"
int byteTransmitTime = 8 * 104 * 2;
int initBackoffLow = 10 * (8 * 104);
int initBackoffHigh = 20 * (8 * 104);
int backoffLow = 10 * (8 * 104);
int backoffHigh = 20 * (8 * 104);
int txChangeLatency = 30 * (8 * 104);
int preambleLength = 20;
int headerLength = 7;


struct IncomingMsg;

typedef struct IncomingMsg {
  TOS_MsgPtr msg;
  int fromID;
} IncomingMsg;

typedef enum __nesc_unnamed4364 {
  RADIO_TX_IDLE, 
  RADIO_TX_BACK, 
  RADIO_TX_TRANS, 
  RADIO_RX_IDLE, 
  RADIO_RX_RECV
} PacketRadioState;

TOS_MsgPtr packet_transmitting[TOSNODES];

IncomingMsg *incoming[TOSNODES];
TOS_Msg packet_sim_bufs[TOSNODES];
TOS_MsgPtr current_ptr[TOSNODES];

uint8_t rxState[TOSNODES];
uint8_t txState[TOSNODES];

link_t *packet_connectivity[TOSNODES];
static inline 
void connectivity_init(char *cFile);
static inline void initialBackoff(void);
static void event_backoff_create(event_t *event, int node, long long eventTime);
void   event_backoff_handle(event_t *event, struct TOS_state *state);

void   event_start_transmit_handle(event_t *event, struct TOS_state *state);
static inline void event_start_transmit_create(event_t *event, int node, long long eventTime);

void   event_receive_packet_create(event_t *event, int node, long long eventTime, IncomingMsg *msg);
void   event_receive_packet_handle(event_t *event, struct TOS_state *state);

void   event_send_packet_done_create(event_t *event, int node, long long eventTime);
void   event_send_packet_done_handle(event_t *event, struct TOS_state *state);
static inline 
void packet_sim_init(char *cFile);
static inline 
#line 121
result_t packet_sim_transmit(TOS_MsgPtr msg);
static inline 








void initialBackoff(void);
static 
#line 146
void event_backoff_create(event_t *event, int node, long long eventTime);










void   event_backoff_handle(event_t *event, struct TOS_state *state);
static inline 
#line 172
void event_start_transmit_create(event_t *event, int node, long long eventTime);
static 








void corruptPacket(IncomingMsg *msg, int src, int dest);









void   event_start_transmit_handle(event_t *event, struct TOS_state *state);
#line 257
void   event_receive_packet_create(event_t *event, int node, long long eventTime, IncomingMsg *msg);










void   event_receive_packet_handle(event_t *event, struct TOS_state *state);
#line 280
void   event_send_packet_done_create(event_t *event, int node, long long eventTime);










void   event_send_packet_done_handle(event_t *event, struct TOS_state *state);
static 
#line 311
int read_int(FILE *file);
static 
#line 341
double read_double(FILE *file);
static inline 
#line 372
int read_packet_entry(FILE *file, int *mote_one, int *mote_two, double *packet_loss, double *falsePos, double *falseNeg);
static inline 
#line 385
void connectivity_init(char *cFile);
# 44 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHop.h"
enum __nesc_unnamed4365 {
  AM_MULTIHOPMSG = 250, 
  AM_DEBUGPACKET = 3
};


typedef struct TOS_MHopNeighbor {
  uint16_t addr;
  uint16_t recv_count;
  uint16_t fail_count;
  int16_t last_seqno;
  uint8_t goodness;
  uint8_t hopcount;
  uint8_t timeouts;
} TOS_MHopNeighbor;

typedef struct MultihopMsg {
  uint16_t sourceaddr;
  uint16_t originaddr;
  int16_t seqno;
  uint8_t hopcount;
  uint8_t data[36 - 7];
} __attribute((packed))  TOS_MHopMsg;

typedef struct DBGEstEntry {
  uint16_t id;
  uint8_t hopcount;
  uint8_t sendEst;
} __attribute((packed))  DBGEstEntry;


typedef struct DebugPacket {
  uint8_t estEntries;
  DBGEstEntry estList[5];
} __attribute((packed))  DebugPacket;
static  result_t BombillaEngineM$Error$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static  void BombillaEngineM$Comm$reboot(uint8_t arg_0x9ddbd00);
static  void BombillaEngineM$Comm$registerCapsule(uint8_t arg_0x9ddbd00, BombillaCapsuleBuffer *arg_0x9dd4a30);
static  result_t BombillaEngineM$Comm$default$analyzeLockSets(uint8_t arg_0x9ddbd00, BombillaCapsuleBuffer *arg_0x9dd4ec8[]);
static  result_t BombillaEngineM$ErrorTimer$fired(void);
static  result_t BombillaEngineM$SendError$sendDone(TOS_MsgPtr arg_0x9de8e10, result_t arg_0x9de8f60);
static  result_t BombillaEngineM$Bytecode$default$execute(uint8_t arg_0x9dd05b0, uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t BombillaEngineM$StdControl$init(void);
static  result_t BombillaEngineM$StdControl$start(void);
static  result_t BombillaEngineM$StdControl$stop(void);
static  result_t BombillaEngineM$Synch$makeRunnable(BombillaContext *arg_0x9dee198);
static   result_t LedsC$Leds$yellowOff(void);
static   result_t LedsC$Leds$yellowOn(void);
static   result_t LedsC$Leds$init(void);
static   result_t LedsC$Leds$greenOff(void);
static   result_t LedsC$Leds$redOff(void);
static   result_t LedsC$Leds$greenToggle(void);
static   result_t LedsC$Leds$yellowToggle(void);
static   result_t LedsC$Leds$redToggle(void);
static   result_t LedsC$Leds$redOn(void);
static   result_t LedsC$Leds$greenOn(void);
static   result_t TimerM$Clock$fire(void);
static  result_t TimerM$StdControl$init(void);
static  result_t TimerM$StdControl$start(void);
static  result_t TimerM$StdControl$stop(void);
static  result_t TimerM$Timer$default$fired(uint8_t arg_0x97e2b40);
static  result_t TimerM$Timer$start(uint8_t arg_0x97e2b40, char arg_0x9de4698, uint32_t arg_0x9de47f0);
static  result_t TimerM$Timer$stop(uint8_t arg_0x97e2b40);
static   void HPLClock$Clock$setInterval(uint8_t arg_0x9e308c8);
static   uint8_t HPLClock$Clock$readCounter(void);
static   result_t HPLClock$Clock$setRate(char arg_0x9e0dad0, char arg_0x9e0dc10);
static   result_t NoLeds$Leds$greenToggle(void);
static   result_t NoLeds$Leds$yellowToggle(void);
static   result_t NoLeds$Leds$redToggle(void);
static   uint8_t HPLPowerManagementM$PowerManagement$adjustPower(void);
static  TOS_MsgPtr AMPromiscuous$ReceiveMsg$default$receive(uint8_t arg_0x9e705c8, TOS_MsgPtr arg_0x9e55570);
static  result_t AMPromiscuous$ActivityTimer$fired(void);
static  result_t AMPromiscuous$UARTSend$sendDone(TOS_MsgPtr arg_0x9e6ac78, result_t arg_0x9e6adc8);
static  TOS_MsgPtr AMPromiscuous$RadioReceive$receive(TOS_MsgPtr arg_0x9e55570);
static  result_t AMPromiscuous$Control$init(void);
static  result_t AMPromiscuous$Control$start(void);
static  result_t AMPromiscuous$Control$stop(void);
static  result_t AMPromiscuous$RadioSend$sendDone(TOS_MsgPtr arg_0x9e6ac78, result_t arg_0x9e6adc8);
static  result_t AMPromiscuous$SendMsg$send(uint8_t arg_0x9e70010, uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0);
static  TOS_MsgPtr AMPromiscuous$UARTReceive$receive(TOS_MsgPtr arg_0x9e55570);
static  result_t TossimPacketM$Control$init(void);
static  result_t TossimPacketM$Control$start(void);
static  result_t TossimPacketM$Control$stop(void);
static  TOS_MsgPtr TossimPacketM$ReceiveMain$receive(TOS_MsgPtr arg_0x9e55570);
static  result_t Nido$RadioSendMsg$send(TOS_MsgPtr arg_0x9e6a760);
static  result_t UARTNoCRCPacketM$Send$send(TOS_MsgPtr arg_0x9e6a760);
static  result_t UARTNoCRCPacketM$Control$init(void);
static  result_t UARTNoCRCPacketM$Control$start(void);
static  result_t UARTNoCRCPacketM$Control$stop(void);
static  TOS_MsgPtr AMFilter$LowerReceive$receive(uint8_t arg_0x9f5d408, TOS_MsgPtr arg_0x9e55570);
static  TOS_MsgPtr AMFilter$UpperReceive$default$receive(uint8_t arg_0x9f5ceb0, TOS_MsgPtr arg_0x9e55570);
static  void BContextSynch$Analysis$analyzeCapsuleCalls(BombillaCapsuleBuffer *arg_0x9dea098[]);
static  void BContextSynch$Analysis$analyzeCapsuleVars(BombillaCapsuleBuffer *arg_0x9dd1c28);
static  int16_t BContextSynch$CodeLocks$default$lockNum(uint8_t arg_0x9fb4bd8, uint8_t arg_0x9f97678);
static  result_t BContextSynch$StdControl$init(void);
static  result_t BContextSynch$StdControl$start(void);
static  result_t BContextSynch$StdControl$stop(void);
static  void BContextSynch$Synch$yieldContext(BombillaContext *arg_0x9df13a0);
static  void BContextSynch$Synch$initializeContext(BombillaContext *arg_0x9df0f88);
static  void BContextSynch$Synch$haltContext(BombillaContext *arg_0x9df1d58);
static  result_t BContextSynch$Synch$obtainLocks(BombillaContext *arg_0x9dd3888, BombillaContext *arg_0x9dd3a08);
static  bool BContextSynch$Synch$isRunnable(BombillaContext *arg_0x9dd32b8);
static  void BContextSynch$Synch$reboot(void);
static  result_t BContextSynch$Synch$releaseLocks(BombillaContext *arg_0x9df0010, BombillaContext *arg_0x9df0190);
static  result_t BContextSynch$Synch$releaseAllLocks(BombillaContext *arg_0x9df07c0, BombillaContext *arg_0x9df0940);
static  bool BContextSynch$Synch$resumeContext(BombillaContext *arg_0x9df17c0, BombillaContext *arg_0x9df1938);
static  result_t BLocks$Locks$unlock(BombillaContext *arg_0x9fbe5d8, uint8_t arg_0x9fbe720);
static  result_t BLocks$Locks$lock(BombillaContext *arg_0x9f93f00, uint8_t arg_0x9fbe060);
static  bool BLocks$Locks$isLocked(uint8_t arg_0x9fbecc8);
static  bool BLocks$Locks$isHeldBy(uint8_t arg_0x9fbf1b8, BombillaContext *arg_0x9fbf320);
static  void BLocks$Locks$reboot(void);
static  result_t BQueue$Queue$enqueue(BombillaContext *arg_0x9dcc7c8, BombillaQueue *arg_0x9dcc940, BombillaContext *arg_0x9dccab8);
static  result_t BQueue$Queue$init(BombillaQueue *arg_0x9defdb8);
static  BombillaContext *BQueue$Queue$dequeue(BombillaContext *arg_0x9dcd0a0, BombillaQueue *arg_0x9dcd218);
static  bool BQueue$Queue$empty(BombillaQueue *arg_0x9dcc300);
static  result_t BStacks$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500);
static  result_t BStacks$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  result_t BStacks$Stacks$resetStacks(BombillaContext *arg_0x9f8f860);
static  result_t BStacks$Stacks$pushBuffer(BombillaContext *arg_0x9fb6cc8, BombillaDataBuffer *arg_0x9fb6e38);
static  BombillaStackVariable *BStacks$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  result_t BStacks$default$resetStack(BombillaContext *arg_0xa010010);
static  uint8_t BStacks$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438);
static  result_t OPaddM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t BBuffer$Buffer$clear(BombillaContext *arg_0xa024b98, BombillaDataBuffer *arg_0xa024d08);
static  uint8_t BBuffer$Buffer$concatenate(BombillaContext *arg_0xa020bb8, BombillaDataBuffer *arg_0xa020d28, BombillaDataBuffer *arg_0xa020e98);
static  result_t BBuffer$Buffer$prepend(BombillaContext *arg_0xa020360, BombillaDataBuffer *arg_0xa0204d0, BombillaStackVariable *arg_0xa020640);
static  result_t BBuffer$Buffer$get(BombillaContext *arg_0xa0214a8, BombillaDataBuffer *arg_0xa021618, uint8_t arg_0xa021768, BombillaStackVariable *arg_0xa0218d8);
static  result_t BBuffer$Buffer$yank(BombillaContext *arg_0xa021ec0, BombillaDataBuffer *arg_0xa01e060, uint8_t arg_0xa01e1b0, BombillaStackVariable *arg_0xa01e320);
static  result_t BBuffer$Buffer$checkAndSetTypes(BombillaContext *arg_0xa025250, BombillaDataBuffer *arg_0xa0253c0, BombillaStackVariable *arg_0xa025530);
static  result_t BBuffer$Buffer$append(BombillaContext *arg_0xa025af0, BombillaDataBuffer *arg_0xa025c60, BombillaStackVariable *arg_0xa025dd0);
static  result_t BBuffer$Buffer$set(BombillaContext *arg_0xa01e900, BombillaDataBuffer *arg_0xa01ea70, uint8_t arg_0xa01ebc0, BombillaStackVariable *arg_0xa01ed30);
static  result_t OPsubM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPhaltM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPhaltM$Synch$makeRunnable(BombillaContext *arg_0x9dee198);
static  result_t OPlandM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPlorM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPorM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPandM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPnotM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPlnotM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPdivM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPbtailM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPeqvM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPexpM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPimpM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPlxorM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPmodM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPmulM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPbreadM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPbwriteM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPpopM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPeqM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPgteM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPgtM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPltM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPlteM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPneqM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPcopyM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPinvM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPputledM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPbclearM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPcastM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPidM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPuartM$Synch$makeRunnable(BombillaContext *arg_0x9dee198);
static  result_t OPuartM$SendPacket$sendDone(TOS_MsgPtr arg_0x9de8e10, result_t arg_0x9de8f60);
static  result_t OPuartM$Virus$capsuleHeard(uint8_t arg_0xbf51fc90);
static  result_t OPuartM$Virus$capsuleInstalled(BombillaCapsule *arg_0xbf51f888);
static  void OPuartM$Virus$capsuleForce(uint8_t arg_0xbf5100a0);
static  result_t OPuartM$sendDone(void);
static  result_t OPuartM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPuartM$StdControl$init(void);
static  result_t OPuartM$StdControl$start(void);
static  result_t OPuartM$StdControl$stop(void);
static  result_t BVirusExtended$BCastTimer$fired(void);
static  result_t BVirusExtended$VersionTimer$fired(void);
static  result_t BVirusExtended$CapsuleSend$sendDone(TOS_MsgPtr arg_0x9de8e10, result_t arg_0x9de8f60);
static  TOS_MsgPtr BVirusExtended$BCastReceive$receive(TOS_MsgPtr arg_0x9e55570);
static  result_t BVirusExtended$Virus$registerCapsule(uint8_t arg_0xbf51f2e8, BombillaCapsule *arg_0xbf51f450);
static  result_t BVirusExtended$BCastSend$sendDone(TOS_MsgPtr arg_0x9de8e10, result_t arg_0x9de8f60);
static  TOS_MsgPtr BVirusExtended$CapsuleReceive$receive(TOS_MsgPtr arg_0x9e55570);
static  TOS_MsgPtr BVirusExtended$ReceiveRouted$receive(TOS_MsgPtr arg_0xbf4fa3b0, void *arg_0xbf4fa508, uint16_t arg_0xbf4fa660);
static  result_t BVirusExtended$VersionSend$sendDone(TOS_MsgPtr arg_0x9de8e10, result_t arg_0x9de8f60);
static  TOS_MsgPtr BVirusExtended$VersionReceive$receive(TOS_MsgPtr arg_0x9e55570);
static  result_t BVirusExtended$CapsuleTimer$fired(void);
static  result_t BVirusExtended$StdControl$init(void);
static  result_t BVirusExtended$StdControl$start(void);
static  result_t BVirusExtended$StdControl$stop(void);
static  result_t BVirusExtended$InterceptRouted$intercept(TOS_MsgPtr arg_0xbf4fbb80, void *arg_0xbf4fbcd8, uint16_t arg_0xbf4fbe30);
static  result_t QueuedSendM$QueueSendMsg$send(uint8_t arg_0xbf4aa9e0, uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0);
static  result_t QueuedSendM$StdControl$init(void);
static  result_t QueuedSendM$StdControl$start(void);
static  result_t QueuedSendM$StdControl$stop(void);
static  result_t QueuedSendM$SerialSendMsg$sendDone(uint8_t arg_0xbf4ab368, TOS_MsgPtr arg_0x9de8e10, result_t arg_0x9de8f60);
static   uint16_t RandomLFSR$Random$rand(void);
static   result_t RandomLFSR$Random$init(void);
static  TOS_MsgPtr MultiHopEngineGridM$ReceiveMsg$receive(uint8_t arg_0xbf484240, TOS_MsgPtr arg_0x9e55570);
static  result_t MultiHopEngineGridM$Intercept$default$intercept(uint8_t arg_0xbf486cc0, TOS_MsgPtr arg_0xbf4fbb80, void *arg_0xbf4fbcd8, uint16_t arg_0xbf4fbe30);
static  result_t MultiHopEngineGridM$Send$send(uint8_t arg_0xbf486658, TOS_MsgPtr arg_0xbf48aae0, uint16_t arg_0xbf48ac30);
static  void *MultiHopEngineGridM$Send$getBuffer(uint8_t arg_0xbf486658, TOS_MsgPtr arg_0xbf48b268, uint16_t *arg_0xbf48b3d0);
static  result_t MultiHopEngineGridM$Send$default$sendDone(uint8_t arg_0xbf486658, TOS_MsgPtr arg_0xbf48bbf8, result_t arg_0xbf48bd48);
static  TOS_MsgPtr MultiHopEngineGridM$Receive$default$receive(uint8_t arg_0xbf486158, TOS_MsgPtr arg_0xbf4fa3b0, void *arg_0xbf4fa508, uint16_t arg_0xbf4fa660);
static  result_t MultiHopEngineGridM$SendMsg$sendDone(uint8_t arg_0xbf484740, TOS_MsgPtr arg_0x9de8e10, result_t arg_0x9de8f60);
static  result_t MultiHopGrid$RouteSelect$selectRoute(TOS_MsgPtr arg_0xbf47e7f8, uint8_t arg_0xbf47e940);
static  result_t MultiHopGrid$RouteSelect$initializeFields(TOS_MsgPtr arg_0xbf47eeb8, uint8_t arg_0xbf47f000);
static  TOS_MsgPtr MultiHopGrid$ReceiveMsg$receive(TOS_MsgPtr arg_0x9e55570);
static  result_t MultiHopGrid$fillInAddr(uint16_t arg_0xbf45c2d8, TOS_MsgPtr arg_0xbf45c428);
static  result_t MultiHopGrid$Snoop$intercept(uint8_t arg_0xbf45a080, TOS_MsgPtr arg_0xbf4fbb80, void *arg_0xbf4fbcd8, uint16_t arg_0xbf4fbe30);
static  result_t MultiHopGrid$DebugSendMsg$sendDone(TOS_MsgPtr arg_0xbf48bbf8, result_t arg_0xbf48bd48);
static  result_t MultiHopGrid$ATimer$fired(void);
static  result_t MultiHopGrid$SendMsg$sendDone(TOS_MsgPtr arg_0x9de8e10, result_t arg_0x9de8f60);
static  result_t MultiHopGrid$Timer$fired(void);
static  result_t OPrandM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPrandM$StdControl$init(void);
static  result_t OPrandM$StdControl$start(void);
static  result_t OPrandM$StdControl$stop(void);
static  result_t OProuteM$Send$sendDone(TOS_MsgPtr arg_0xbf48bbf8, result_t arg_0xbf48bd48);
static  void OProuteM$Comm$reboot(void);
static  void OProuteM$Comm$registerCapsule(BombillaCapsuleBuffer *arg_0x9dd4a30);
static  result_t OProuteM$sendDone(void);
static  result_t OProuteM$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OProuteM$Synch$makeRunnable(BombillaContext *arg_0x9dee198);
static  result_t OnceContextM$Timer$fired(void);
static  result_t OnceContextM$Comm$analyzeLockSets(BombillaCapsuleBuffer *arg_0x9dd4ec8[]);
static  result_t OnceContextM$Virus$capsuleHeard(uint8_t arg_0xbf51fc90);
static  result_t OnceContextM$Virus$capsuleInstalled(BombillaCapsule *arg_0xbf51f888);
static  void OnceContextM$Virus$capsuleForce(uint8_t arg_0xbf5100a0);
static  result_t OnceContextM$StdControl$init(void);
static  result_t OnceContextM$StdControl$start(void);
static  result_t OnceContextM$StdControl$stop(void);
static  result_t OnceContextM$Synch$makeRunnable(BombillaContext *arg_0x9dee198);
static  result_t OPbpush1M$Virus$capsuleHeard(uint8_t arg_0xbf51fc90);
static  result_t OPbpush1M$Virus$capsuleInstalled(BombillaCapsule *arg_0xbf51f888);
static  void OPbpush1M$Virus$capsuleForce(uint8_t arg_0xbf5100a0);
static  int16_t OPbpush1M$BombillaBytecodeLock$lockNum(uint8_t arg_0x9f97678);
static  result_t OPbpush1M$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPsettimer1M$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t Timer1ContextM$Synch$makeRunnable(BombillaContext *arg_0x9dee198);
static  result_t Timer1ContextM$Comm$analyzeLockSets(BombillaCapsuleBuffer *arg_0x9dd4ec8[]);
static  result_t Timer1ContextM$ClockTimer$fired(void);
static  result_t Timer1ContextM$Virus$capsuleHeard(uint8_t arg_0xbf51fc90);
static  result_t Timer1ContextM$Virus$capsuleInstalled(BombillaCapsule *arg_0xbf51f888);
static  void Timer1ContextM$Virus$capsuleForce(uint8_t arg_0xbf5100a0);
static  result_t Timer1ContextM$StdControl$init(void);
static  result_t Timer1ContextM$StdControl$start(void);
static  result_t Timer1ContextM$StdControl$stop(void);
static  result_t Timer1ContextM$Timer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0);
static  result_t Timer1ContextM$Timer$stop(void);
static  result_t OP2pushc10M$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OP2jumps10M$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPgetsetlocal3M$Virus$capsuleHeard(uint8_t arg_0xbf51fc90);
static  result_t OPgetsetlocal3M$Virus$capsuleInstalled(BombillaCapsule *arg_0xbf51f888);
static  void OPgetsetlocal3M$Virus$capsuleForce(uint8_t arg_0xbf5100a0);
static  result_t OPgetsetlocal3M$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPgetsetlocal3M$StdControl$init(void);
static  result_t OPgetsetlocal3M$StdControl$start(void);
static  result_t OPgetsetlocal3M$StdControl$stop(void);
static  result_t OPgetsetvar4M$Virus$capsuleHeard(uint8_t arg_0xbf51fc90);
static  result_t OPgetsetvar4M$Virus$capsuleInstalled(BombillaCapsule *arg_0xbf51f888);
static  void OPgetsetvar4M$Virus$capsuleForce(uint8_t arg_0xbf5100a0);
static  int16_t OPgetsetvar4M$BombillaBytecodeLock$lockNum(uint8_t arg_0x9f97678);
static  result_t OPgetsetvar4M$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  result_t OPgetsetvar4M$StdControl$init(void);
static  result_t OPgetsetvar4M$StdControl$start(void);
static  result_t OPgetsetvar4M$StdControl$stop(void);
static  result_t OPpushc6M$BombillaBytecode$execute(uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260);
static  
# 115 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaQueue.nc"
result_t BombillaEngineM$Queue$enqueue(BombillaContext *arg_0x9dcc7c8, 
BombillaQueue *arg_0x9dcc940, 
BombillaContext *arg_0x9dccab8);
static  
#line 89
result_t BombillaEngineM$Queue$init(BombillaQueue *arg_0x9defdb8);
static  
#line 129
BombillaContext *BombillaEngineM$Queue$dequeue(BombillaContext *arg_0x9dcd0a0, 
BombillaQueue *arg_0x9dcd218);
static  
# 96 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextComm.nc"
result_t BombillaEngineM$Comm$analyzeLockSets(
# 85 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
uint8_t arg_0x9ddbd00, 
# 96 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextComm.nc"
BombillaCapsuleBuffer *arg_0x9dd4ec8[]);
static  
# 63 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
result_t BombillaEngineM$SubControl$init(void);
static  





result_t BombillaEngineM$SubControl$start(void);
static  






result_t BombillaEngineM$SubControl$stop(void);
static  
# 81 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaAnalysis.nc"
void BombillaEngineM$Analysis$analyzeCapsuleCalls(BombillaCapsuleBuffer *arg_0x9dea098[]);
static  
#line 80
void BombillaEngineM$Analysis$analyzeCapsuleVars(BombillaCapsuleBuffer *arg_0x9dd1c28);
static   
# 114 "/root/src/tinyos-1.x/tos/interfaces/Leds.nc"
result_t BombillaEngineM$Leds$yellowOn(void);
static   
#line 56
result_t BombillaEngineM$Leds$init(void);
static   
#line 106
result_t BombillaEngineM$Leds$greenToggle(void);
static   
#line 131
result_t BombillaEngineM$Leds$yellowToggle(void);
static   
#line 81
result_t BombillaEngineM$Leds$redToggle(void);
static   
#line 64
result_t BombillaEngineM$Leds$redOn(void);
static   
#line 89
result_t BombillaEngineM$Leds$greenOn(void);
static  
# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
result_t BombillaEngineM$ErrorTimer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0);
static  







result_t BombillaEngineM$ErrorTimer$stop(void);
static  
# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
result_t BombillaEngineM$SendError$send(uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0);
static  
# 97 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBytecode.nc"
result_t BombillaEngineM$Bytecode$execute(
# 93 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
uint8_t arg_0x9dd05b0, 
# 97 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBytecode.nc"
uint8_t arg_0x9dd60e8, 
BombillaContext *arg_0x9dd6260);
static  
# 161 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
void BombillaEngineM$Synch$reboot(void);
# 103 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
BombillaQueue BombillaEngineM$runQueue[1000];
BombillaCapsuleBuffer *BombillaEngineM$capsules[1000][3];

BombillaContext *BombillaEngineM$errorContext[1000];
BombillaErrorMsg BombillaEngineM$errorMsg[1000];
bool BombillaEngineM$inErrorState[1000];
bool BombillaEngineM$errorFlipFlop[1000];
TOS_Msg BombillaEngineM$msg[1000];
static inline  
result_t BombillaEngineM$StdControl$init(void);
static inline  
#line 128
result_t BombillaEngineM$StdControl$start(void);
static inline  




result_t BombillaEngineM$StdControl$stop(void);
static inline 




result_t BombillaEngineM$computeInstruction(BombillaContext *context);
static  
#line 152
void BombillaEngineM$RunTask(void);
static inline 
#line 170
result_t BombillaEngineM$executeContext(BombillaContext *context);
static inline   





result_t BombillaEngineM$Bytecode$default$execute(uint8_t opcode, uint8_t instr, 
BombillaContext *context);
static inline  





void BombillaEngineM$Comm$registerCapsule(uint8_t type, BombillaCapsuleBuffer *capsule);
static  


void BombillaEngineM$Comm$reboot(uint8_t type);
static inline   
#line 212
result_t BombillaEngineM$Comm$default$analyzeLockSets(uint8_t type, BombillaCapsuleBuffer *caps[]);
static inline  


result_t BombillaEngineM$Synch$makeRunnable(BombillaContext *context);
static  



result_t BombillaEngineM$Error$error(BombillaContext *context, uint8_t cause);
static inline  
#line 246
result_t BombillaEngineM$ErrorTimer$fired(void);
static inline  
#line 273
result_t BombillaEngineM$SendError$sendDone(TOS_MsgPtr mesg, result_t success);
# 50 "/root/src/tinyos-1.x/tos/platform/pc/LedsC.nc"
uint8_t LedsC$ledsOn[1000];

enum LedsC$__nesc_unnamed4366 {
  LedsC$RED_BIT = 1, 
  LedsC$GREEN_BIT = 2, 
  LedsC$YELLOW_BIT = 4
};
static 
void LedsC$updateLeds(void);
static inline   







result_t LedsC$Leds$init(void);
static   







result_t LedsC$Leds$redOn(void);
static   
#line 88
result_t LedsC$Leds$redOff(void);
static   









result_t LedsC$Leds$redToggle(void);
static   









result_t LedsC$Leds$greenOn(void);
static   









result_t LedsC$Leds$greenOff(void);
static   









result_t LedsC$Leds$greenToggle(void);
static   









result_t LedsC$Leds$yellowOn(void);
static   









result_t LedsC$Leds$yellowOff(void);
static   









result_t LedsC$Leds$yellowToggle(void);
static   
# 41 "/root/src/tinyos-1.x/tos/interfaces/PowerManagement.nc"
uint8_t TimerM$PowerManagement$adjustPower(void);
static   
# 105 "/root/src/tinyos-1.x/tos/interfaces/Clock.nc"
void TimerM$Clock$setInterval(uint8_t arg_0x9e308c8);
static   
#line 153
uint8_t TimerM$Clock$readCounter(void);
static   
#line 96
result_t TimerM$Clock$setRate(char arg_0x9e0dad0, char arg_0x9e0dc10);
static  
# 73 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
result_t TimerM$Timer$fired(
# 45 "/root/src/tinyos-1.x/tos/system/TimerM.nc"
uint8_t arg_0x97e2b40);









uint32_t TimerM$mState[1000];
uint8_t TimerM$setIntervalFlag[1000];
uint8_t TimerM$mScale[1000];
#line 57
uint8_t TimerM$mInterval[1000];
int8_t TimerM$queue_head[1000];
int8_t TimerM$queue_tail[1000];
uint8_t TimerM$queue_size[1000];
uint8_t TimerM$queue[1000][NUM_TIMERS];

struct TimerM$timer_s {
  uint8_t type;
  int32_t ticks;
  int32_t ticksLeft;
} TimerM$mTimerList[1000][NUM_TIMERS];

enum TimerM$__nesc_unnamed4367 {
  TimerM$maxTimerInterval = 230
};
static  result_t TimerM$StdControl$init(void);
static inline  








result_t TimerM$StdControl$start(void);
static inline  


result_t TimerM$StdControl$stop(void);
static  





result_t TimerM$Timer$start(uint8_t id, char type, 
uint32_t interval);
#line 116
static void TimerM$adjustInterval(void);
static  
#line 142
result_t TimerM$Timer$stop(uint8_t id);
static inline   
#line 156
result_t TimerM$Timer$default$fired(uint8_t id);
static inline 


void TimerM$enqueue(uint8_t value);
static inline 






uint8_t TimerM$dequeue(void);
static inline  








void TimerM$signalOneTimer(void);
static inline  




void TimerM$HandleFire(void);
static inline   
#line 206
result_t TimerM$Clock$fire(void);
static   
# 180 "/root/src/tinyos-1.x/tos/interfaces/Clock.nc"
result_t HPLClock$Clock$fire(void);
# 60 "/root/src/tinyos-1.x/tos/platform/pc/HPLClock.nc"
char HPLClock$set_flag[1000];
 unsigned char HPLClock$mscale[1000];
 
#line 61
unsigned char HPLClock$nextScale[1000];
 
#line 61
unsigned char HPLClock$minterval[1000];
static inline   
#line 82
void HPLClock$Clock$setInterval(uint8_t value);
static inline   
#line 113
uint8_t HPLClock$Clock$readCounter(void);
static inline   
#line 128
result_t HPLClock$Clock$setRate(char interval, char scale);
static inline 






void  SIG_OUTPUT_COMPARE2_interrupt(void);
static inline   
# 63 "/root/src/tinyos-1.x/tos/system/NoLeds.nc"
result_t NoLeds$Leds$redToggle(void);
static inline   
#line 75
result_t NoLeds$Leds$greenToggle(void);
static inline   
#line 87
result_t NoLeds$Leds$yellowToggle(void);
# 46 "/root/src/tinyos-1.x/tos/platform/pc/HPLPowerManagementM.nc"
enum HPLPowerManagementM$__nesc_unnamed4368 {
  HPLPowerManagementM$IDLE = 0
};
static inline   
uint8_t HPLPowerManagementM$PowerManagement$adjustPower(void);
static  
# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
TOS_MsgPtr AMPromiscuous$ReceiveMsg$receive(
# 56 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
uint8_t arg_0x9e705c8, 
# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
TOS_MsgPtr arg_0x9e55570);
static  
# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
result_t AMPromiscuous$ActivityTimer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0);
static  







result_t AMPromiscuous$ActivityTimer$stop(void);
static  
# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
TOS_MsgPtr AMPromiscuous$NonPromiscuous$receive(
# 57 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
uint8_t arg_0x9e70b00, 
# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
TOS_MsgPtr arg_0x9e55570);
static  
# 58 "/root/src/tinyos-1.x/tos/interfaces/BareSendMsg.nc"
result_t AMPromiscuous$UARTSend$send(TOS_MsgPtr arg_0x9e6a760);
static   
# 41 "/root/src/tinyos-1.x/tos/interfaces/PowerManagement.nc"
uint8_t AMPromiscuous$PowerManagement$adjustPower(void);
static  
# 63 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
result_t AMPromiscuous$RadioControl$init(void);
static  





result_t AMPromiscuous$RadioControl$start(void);
static  






result_t AMPromiscuous$RadioControl$stop(void);
static  
#line 63
result_t AMPromiscuous$TimerControl$init(void);
static  





result_t AMPromiscuous$TimerControl$start(void);
static  
#line 63
result_t AMPromiscuous$UARTControl$init(void);
static  





result_t AMPromiscuous$UARTControl$start(void);
static  






result_t AMPromiscuous$UARTControl$stop(void);
static  
# 65 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
result_t AMPromiscuous$sendDone(void);
static  
# 58 "/root/src/tinyos-1.x/tos/interfaces/BareSendMsg.nc"
result_t AMPromiscuous$RadioSend$send(TOS_MsgPtr arg_0x9e6a760);
static  
# 49 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
result_t AMPromiscuous$SendMsg$sendDone(
# 55 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
uint8_t arg_0x9e70010, 
# 49 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
TOS_MsgPtr arg_0x9de8e10, result_t arg_0x9de8f60);
# 82 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
bool AMPromiscuous$state[1000];
TOS_MsgPtr AMPromiscuous$buffer[1000];
uint16_t AMPromiscuous$lastCount[1000];
uint16_t AMPromiscuous$counter[1000];
bool AMPromiscuous$promiscuous_mode[1000];
bool AMPromiscuous$crc_check[1000];
static  

result_t AMPromiscuous$Control$init(void);
static  
#line 106
result_t AMPromiscuous$Control$start(void);
static  
#line 123
result_t AMPromiscuous$Control$stop(void);
static 
#line 156
void AMPromiscuous$dbgPacket(TOS_MsgPtr data);
static 









result_t AMPromiscuous$reportSendDone(TOS_MsgPtr msg, result_t success);
static inline  







result_t AMPromiscuous$ActivityTimer$fired(void);
static inline  
#line 190
void AMPromiscuous$sendTask(void);
static inline 
#line 202
void AMPromiscuous$am_test_func(void);
static  


result_t AMPromiscuous$SendMsg$send(uint8_t id, uint16_t addr, uint8_t length, TOS_MsgPtr data);
static inline  
#line 238
result_t AMPromiscuous$UARTSend$sendDone(TOS_MsgPtr msg, result_t success);
static inline  

result_t AMPromiscuous$RadioSend$sendDone(TOS_MsgPtr msg, result_t success);




TOS_MsgPtr   prom_received(TOS_MsgPtr packet);
static inline   
#line 274
TOS_MsgPtr AMPromiscuous$ReceiveMsg$default$receive(uint8_t id, TOS_MsgPtr msg);
static inline  


TOS_MsgPtr AMPromiscuous$UARTReceive$receive(TOS_MsgPtr packet);
static inline  

TOS_MsgPtr AMPromiscuous$RadioReceive$receive(TOS_MsgPtr packet);
static  
# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
TOS_MsgPtr TossimPacketM$Receive$receive(TOS_MsgPtr arg_0x9e55570);
# 61 "/root/src/tinyos-1.x/beta/TOSSIM-packet/TossimPacketM.nc"
TOS_Msg TossimPacketM$buffer[1000];
TOS_MsgPtr TossimPacketM$bufferPtr[1000];
static inline  
result_t TossimPacketM$Control$init(void);
static inline  




result_t TossimPacketM$Control$start(void);
static inline  


result_t TossimPacketM$Control$stop(void);
static inline  



TOS_MsgPtr TossimPacketM$ReceiveMain$receive(TOS_MsgPtr msg);
static  
# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
TOS_MsgPtr Nido$UARTReceiveMsg$receive(TOS_MsgPtr arg_0x9e55570);
static  
# 67 "/root/src/tinyos-1.x/tos/interfaces/BareSendMsg.nc"
result_t Nido$RadioSendMsg$sendDone(TOS_MsgPtr arg_0x9e6ac78, result_t arg_0x9e6adc8);
static  
# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
TOS_MsgPtr Nido$RadioReceiveMsg$receive(TOS_MsgPtr arg_0x9e55570);
static  
# 63 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
result_t Nido$StdControl$init(void);
static  





result_t Nido$StdControl$start(void);
static  






result_t Nido$StdControl$stop(void);
static inline 
# 73 "/root/src/tinyos-1.x/beta/TOSSIM-packet/Nido.nc"
void Nido$usage(char *progname);
static 



void Nido$help(char *progname);
#line 103
void   event_boot_handle(event_t *fevent, 
struct TOS_state *fstate);
#line 118
int   main(int argc, char **argv);
#line 334
void   nido_start_mote(uint16_t moteID);
#line 349
void   nido_stop_mote(uint16_t moteID);
#line 363
TOS_MsgPtr   NIDO_received_radio(TOS_MsgPtr packet);









TOS_MsgPtr   NIDO_received_uart(TOS_MsgPtr packet);
static inline  









result_t Nido$RadioSendMsg$send(TOS_MsgPtr msg);








void   packet_sim_transmit_done(TOS_MsgPtr msg);




TOS_MsgPtr   packet_sim_receive_msg(TOS_MsgPtr msg);








void   set_sim_rate(uint32_t rate);







uint32_t   get_sim_rate(void);
static  
# 67 "/root/src/tinyos-1.x/tos/interfaces/BareSendMsg.nc"
result_t UARTNoCRCPacketM$Send$sendDone(TOS_MsgPtr arg_0x9e6ac78, result_t arg_0x9e6adc8);
static inline  
# 55 "/root/src/tinyos-1.x/tos/platform/pc/UARTNoCRCPacketM.nc"
result_t UARTNoCRCPacketM$Control$init(void);
static inline  


result_t UARTNoCRCPacketM$Control$start(void);
static inline  


result_t UARTNoCRCPacketM$Control$stop(void);
static inline  


result_t UARTNoCRCPacketM$Send$send(TOS_MsgPtr msg);
#line 79
void   NIDO_uart_send_done(TOS_MsgPtr fmsg, result_t fsuccess);
# 74 "/root/src/tinyos-1.x/tos/system/NoCRCPacket.nc"
enum NoCRCPacket$__nesc_unnamed4369 {
  NoCRCPacket$IDLE, 
  NoCRCPacket$PACKET, 
  NoCRCPacket$BYTES
};
static  
# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
TOS_MsgPtr AMFilter$UpperReceive$receive(
# 49 "/root/src/tinyos-1.x/tos/lib/VM/components/AMFilter.nc"
uint8_t arg_0x9f5ceb0, 
# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
TOS_MsgPtr arg_0x9e55570);
static inline  
# 56 "/root/src/tinyos-1.x/tos/lib/VM/components/AMFilter.nc"
TOS_MsgPtr AMFilter$LowerReceive$receive(uint8_t id, TOS_MsgPtr msg);
static inline   
#line 69
TOS_MsgPtr AMFilter$UpperReceive$default$receive(uint8_t id, TOS_MsgPtr msg);
static  
# 111 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaLocks.nc"
result_t BContextSynch$Locks$unlock(BombillaContext *arg_0x9fbe5d8, uint8_t arg_0x9fbe720);
static  
#line 95
result_t BContextSynch$Locks$lock(BombillaContext *arg_0x9f93f00, uint8_t arg_0x9fbe060);
static  
#line 123
bool BContextSynch$Locks$isLocked(uint8_t arg_0x9fbecc8);
static  
#line 139
void BContextSynch$Locks$reboot(void);
static  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t BContextSynch$Stacks$resetStacks(BombillaContext *arg_0x9f8f860);
static  
# 115 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaQueue.nc"
result_t BContextSynch$Queue$enqueue(BombillaContext *arg_0x9dcc7c8, 
BombillaQueue *arg_0x9dcc940, 
BombillaContext *arg_0x9dccab8);
static  
#line 89
result_t BContextSynch$Queue$init(BombillaQueue *arg_0x9defdb8);
static  
#line 129
BombillaContext *BContextSynch$Queue$dequeue(BombillaContext *arg_0x9dcd0a0, 
BombillaQueue *arg_0x9dcd218);
static  
#line 100
bool BContextSynch$Queue$empty(BombillaQueue *arg_0x9dcc300);
static  
# 87 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBytecodeLock.nc"
int16_t BContextSynch$CodeLocks$lockNum(
# 87 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
uint8_t arg_0x9fb4bd8, 
# 87 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBytecodeLock.nc"
uint8_t arg_0x9f97678);
static  
# 159 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
result_t BContextSynch$Synch$makeRunnable(BombillaContext *arg_0x9dee198);
# 93 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
BombillaQueue BContextSynch$readyQueue[1000];
static inline  
result_t BContextSynch$StdControl$init(void);
static inline  



result_t BContextSynch$StdControl$start(void);
static inline  


result_t BContextSynch$StdControl$stop(void);
static inline  


void BContextSynch$Synch$reboot(void);
static inline  



bool BContextSynch$Synch$isRunnable(BombillaContext *context);
static inline  
#line 131
result_t BContextSynch$Synch$obtainLocks(BombillaContext *caller, 
BombillaContext *obtainer);
static  
#line 151
result_t BContextSynch$Synch$releaseLocks(BombillaContext *caller, 
BombillaContext *releaser);
static inline  
#line 167
result_t BContextSynch$Synch$releaseAllLocks(BombillaContext *caller, 
BombillaContext *releaser);
static  
#line 183
void BContextSynch$Analysis$analyzeCapsuleVars(BombillaCapsuleBuffer *buf);
static inline 
#line 202
void BContextSynch$capsuleCallsDeep(BombillaCapsuleBuffer *capsules[], int which);
static inline  
#line 218
void BContextSynch$Analysis$analyzeCapsuleCalls(BombillaCapsuleBuffer *capsules[]);
static  









void BContextSynch$Synch$initializeContext(BombillaContext *context);
static  
#line 243
void BContextSynch$Synch$yieldContext(BombillaContext *context);
static  
#line 268
bool BContextSynch$Synch$resumeContext(BombillaContext *caller, 
BombillaContext *context);
static inline  
#line 284
void BContextSynch$Synch$haltContext(BombillaContext *context);
static inline   
#line 298
int16_t BContextSynch$CodeLocks$default$lockNum(uint8_t ival, uint8_t instr);
# 82 "/root/src/tinyos-1.x/tos/lib/VM/components/BLocks.nc"
BombillaLock BLocks$locks[1000][BOMB_HEAPSIZE];
static inline  
void BLocks$Locks$reboot(void);
static inline  





result_t BLocks$Locks$lock(BombillaContext *context, uint8_t lockNum);
static  





result_t BLocks$Locks$unlock(BombillaContext *context, uint8_t lockNum);
static inline  





bool BLocks$Locks$isLocked(uint8_t lockNum);
static inline  


bool BLocks$Locks$isHeldBy(uint8_t lockNum, 
BombillaContext *context);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
result_t BQueue$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static inline 
# 83 "/root/src/tinyos-1.x/tos/lib/VM/components/BQueue.nc"
void BQueue$list_insert_before(list_link_t *before, list_link_t *new);
static inline 





void BQueue$list_insert_head(list_t *list, list_link_t *element);
static inline 






void BQueue$list_remove(list_link_t *ll);
static inline 
#line 115
void BQueue$list_init(list_t *list);
static inline 



bool BQueue$list_empty(list_t *list);
static inline  


result_t BQueue$Queue$init(BombillaQueue *queue);
static  



bool BQueue$Queue$empty(BombillaQueue *queue);
static  




result_t BQueue$Queue$enqueue(BombillaContext *context, 
BombillaQueue *queue, 
BombillaContext *element);
static  









BombillaContext *BQueue$Queue$dequeue(BombillaContext *context, 
BombillaQueue *queue);
static  
# 79 "/root/src/tinyos-1.x/tos/lib/VM/components/BStacks.nc"
result_t BStacks$resetStack(BombillaContext *arg_0xa010010);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
result_t BStacks$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static inline  
# 85 "/root/src/tinyos-1.x/tos/lib/VM/components/BStacks.nc"
result_t BStacks$Stacks$resetStacks(BombillaContext *context);
static inline   



result_t BStacks$default$resetStack(BombillaContext *context);
static  


result_t BStacks$Stacks$pushValue(BombillaContext *context, 
int16_t val);
static  
#line 129
result_t BStacks$Stacks$pushBuffer(BombillaContext *context, 
BombillaDataBuffer *buffer);
static  
#line 147
result_t BStacks$Stacks$pushOperand(BombillaContext *context, 
BombillaStackVariable *var);
static  
#line 164
BombillaStackVariable *BStacks$Stacks$popOperand(BombillaContext *context);
static  
#line 226
uint8_t BStacks$Types$checkTypes(BombillaContext *context, 
BombillaStackVariable *var, 
uint8_t types);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPaddM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 131
result_t OPaddM$Stacks$pushBuffer(BombillaContext *arg_0x9fb6cc8, BombillaDataBuffer *arg_0x9fb6e38);
static  
#line 158
BombillaStackVariable *OPaddM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
result_t OPaddM$Error$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static  
# 154 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBuffer.nc"
uint8_t OPaddM$Buffer$concatenate(BombillaContext *arg_0xa020bb8, BombillaDataBuffer *arg_0xa020d28, BombillaDataBuffer *arg_0xa020e98);
static  
#line 137
result_t OPaddM$Buffer$prepend(BombillaContext *arg_0xa020360, BombillaDataBuffer *arg_0xa0204d0, BombillaStackVariable *arg_0xa020640);
static  
#line 122
result_t OPaddM$Buffer$append(BombillaContext *arg_0xa025af0, BombillaDataBuffer *arg_0xa025c60, BombillaStackVariable *arg_0xa025dd0);
static inline  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPaddM.nc"
result_t OPaddM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
result_t BBuffer$Error$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static inline  
# 83 "/root/src/tinyos-1.x/tos/lib/VM/components/BBuffer.nc"
result_t BBuffer$Buffer$clear(BombillaContext *context, 
BombillaDataBuffer *buffer);
static  








result_t BBuffer$Buffer$checkAndSetTypes(BombillaContext *context, 
BombillaDataBuffer *buffer, 
BombillaStackVariable *var);
static  
#line 118
result_t BBuffer$Buffer$append(BombillaContext *context, 
BombillaDataBuffer *buffer, 
BombillaStackVariable *var);
static inline  
#line 146
uint8_t BBuffer$Buffer$concatenate(BombillaContext *context, 
BombillaDataBuffer *dest, 
BombillaDataBuffer *src);
static inline  
#line 169
result_t BBuffer$Buffer$prepend(BombillaContext *context, 
BombillaDataBuffer *buffer, 
BombillaStackVariable *var);
static  
#line 204
result_t BBuffer$Buffer$get(BombillaContext *context, 
BombillaDataBuffer *buffer, 
uint8_t bufferIndex, 
BombillaStackVariable *dest);
static inline  
#line 233
result_t BBuffer$Buffer$yank(BombillaContext *context, 
BombillaDataBuffer *buffer, 
uint8_t bufferIndex, 
BombillaStackVariable *dest);
static inline  
#line 271
result_t BBuffer$Buffer$set(BombillaContext *context, 
BombillaDataBuffer *buffer, 
uint8_t bufferIndex, 
BombillaStackVariable *src);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPsubM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPsubM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPsubM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPsubM.nc"
result_t OPsubM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 157 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
void OPhaltM$Synch$haltContext(BombillaContext *arg_0x9df1d58);
static inline  
# 88 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPhaltM.nc"
result_t OPhaltM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static inline  






result_t OPhaltM$Synch$makeRunnable(BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPlandM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPlandM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPlandM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPlandM.nc"
result_t OPlandM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPlorM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPlorM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPlorM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPlorM.nc"
result_t OPlorM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPorM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPorM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPorM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPorM.nc"
result_t OPorM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPandM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPandM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPandM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPandM.nc"
result_t OPandM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPnotM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500);
static  









BombillaStackVariable *OPnotM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPnotM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPnotM.nc"
result_t OPnotM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPlnotM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500);
static  









BombillaStackVariable *OPlnotM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPlnotM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPlnotM.nc"
result_t OPlnotM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPdivM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPdivM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPdivM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPdivM.nc"
result_t OPdivM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPbtailM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500);
static  









BombillaStackVariable *OPbtailM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPbtailM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static  
# 191 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBuffer.nc"
result_t OPbtailM$Buffer$yank(BombillaContext *arg_0xa021ec0, BombillaDataBuffer *arg_0xa01e060, uint8_t arg_0xa01e1b0, BombillaStackVariable *arg_0xa01e320);
static inline  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbtailM.nc"
result_t OPbtailM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPeqvM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPeqvM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPeqvM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPeqvM.nc"
result_t OPeqvM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPexpM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPexpM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPexpM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPexpM.nc"
result_t OPexpM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPimpM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPimpM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPimpM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPimpM.nc"
result_t OPimpM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPlxorM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPlxorM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPlxorM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPlxorM.nc"
result_t OPlxorM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPmodM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPmodM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPmodM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPmodM.nc"
result_t OPmodM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPmulM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPmulM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPmulM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPmulM.nc"
result_t OPmulM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPbreadM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500);
static  









BombillaStackVariable *OPbreadM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPbreadM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static  
# 172 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBuffer.nc"
result_t OPbreadM$Buffer$get(BombillaContext *arg_0xa0214a8, BombillaDataBuffer *arg_0xa021618, uint8_t arg_0xa021768, BombillaStackVariable *arg_0xa0218d8);
static inline  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbreadM.nc"
result_t OPbreadM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
BombillaStackVariable *OPbwriteM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPbwriteM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static  
# 211 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBuffer.nc"
result_t OPbwriteM$Buffer$set(BombillaContext *arg_0xa01e900, BombillaDataBuffer *arg_0xa01ea70, uint8_t arg_0xa01ebc0, BombillaStackVariable *arg_0xa01ed30);
static inline  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbwriteM.nc"
result_t OPbwriteM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
BombillaStackVariable *OPpopM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static inline  
# 88 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPpopM.nc"
result_t OPpopM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPeqM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPeqM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static inline 
# 88 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPeqM.nc"
bool OPeqM$areEqual(BombillaStackVariable *arg1, BombillaStackVariable *arg2);
static inline  
#line 105
result_t OPeqM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPgteM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPgteM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
result_t OPgteM$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgteM.nc"
result_t OPgteM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPgtM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPgtM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
result_t OPgtM$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgtM.nc"
result_t OPgtM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPltM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPltM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
result_t OPltM$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPltM.nc"
result_t OPltM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPlteM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPlteM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
result_t OPlteM$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPlteM.nc"
result_t OPlteM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPneqM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPneqM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static inline 
# 87 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPneqM.nc"
bool OPneqM$areEqual(BombillaStackVariable *arg1, BombillaStackVariable *arg2);
static inline  
#line 104
result_t OPneqM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPcopyM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500);
static  









BombillaStackVariable *OPcopyM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static inline  
# 88 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPcopyM.nc"
result_t OPcopyM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPinvM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500);
static  









BombillaStackVariable *OPinvM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPinvM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPinvM.nc"
result_t OPinvM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
BombillaStackVariable *OPputledM$BombillaStacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static   
# 122 "/root/src/tinyos-1.x/tos/interfaces/Leds.nc"
result_t OPputledM$Leds$yellowOff(void);
static   
#line 114
result_t OPputledM$Leds$yellowOn(void);
static   
#line 97
result_t OPputledM$Leds$greenOff(void);
static   
#line 72
result_t OPputledM$Leds$redOff(void);
static   
#line 106
result_t OPputledM$Leds$greenToggle(void);
static   
#line 131
result_t OPputledM$Leds$yellowToggle(void);
static   
#line 81
result_t OPputledM$Leds$redToggle(void);
static   
#line 64
result_t OPputledM$Leds$redOn(void);
static   
#line 89
result_t OPputledM$Leds$greenOn(void);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPputledM$BombillaTypes$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPputledM.nc"
result_t OPputledM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPbclearM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500);
static  









BombillaStackVariable *OPbclearM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPbclearM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static  
# 91 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBuffer.nc"
result_t OPbclearM$Buffer$clear(BombillaContext *arg_0xa024b98, BombillaDataBuffer *arg_0xa024d08);
static inline  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbclearM.nc"
result_t OPbclearM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPcastM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
#line 158
BombillaStackVariable *OPcastM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPcastM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPcastM.nc"
result_t OPcastM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPidM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPidM.nc"
result_t OPidM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 152 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
void OPuartM$Synch$yieldContext(BombillaContext *arg_0x9df13a0);
static  
#line 129
result_t OPuartM$Synch$releaseLocks(BombillaContext *arg_0x9df0010, 
BombillaContext *arg_0x9df0190);
static  
#line 154
bool OPuartM$Synch$resumeContext(BombillaContext *arg_0x9df17c0, 
BombillaContext *arg_0x9df1938);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
result_t OPuartM$Error$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static  
# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPuartM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500);
static  









BombillaStackVariable *OPuartM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 115 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaQueue.nc"
result_t OPuartM$Queue$enqueue(BombillaContext *arg_0x9dcc7c8, 
BombillaQueue *arg_0x9dcc940, 
BombillaContext *arg_0x9dccab8);
static  
#line 89
result_t OPuartM$Queue$init(BombillaQueue *arg_0x9defdb8);
static  
#line 129
BombillaContext *OPuartM$Queue$dequeue(BombillaContext *arg_0x9dcd0a0, 
BombillaQueue *arg_0x9dcd218);
static  
#line 100
bool OPuartM$Queue$empty(BombillaQueue *arg_0x9dcc300);
static  
# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
result_t OPuartM$SendPacket$send(uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPuartM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
# 102 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPuartM.nc"
BombillaQueue OPuartM$sendWaitQueue[1000];
BombillaContext *OPuartM$sendingContext[1000];
TOS_Msg OPuartM$msg[1000];
static inline  
result_t OPuartM$StdControl$init(void);
static inline  



result_t OPuartM$StdControl$start(void);
static inline  


result_t OPuartM$StdControl$stop(void);
static inline  


result_t OPuartM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static inline  
#line 154
result_t OPuartM$SendPacket$sendDone(TOS_MsgPtr mesg, result_t success);
static inline  
#line 173
result_t OPuartM$sendDone(void);
static inline  
#line 185
result_t OPuartM$Synch$makeRunnable(BombillaContext *context);
static  


result_t OPuartM$Virus$capsuleInstalled(BombillaCapsule *capsule);
static inline  
#line 203
result_t OPuartM$Virus$capsuleHeard(uint8_t type);
static inline  


void OPuartM$Virus$capsuleForce(uint8_t type);
static  
# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
result_t BVirusExtended$BCastTimer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0);
static  







result_t BVirusExtended$BCastTimer$stop(void);
static  
#line 59
result_t BVirusExtended$VersionTimer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0);
static  







result_t BVirusExtended$VersionTimer$stop(void);
static  
# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
result_t BVirusExtended$CapsuleSend$send(uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0);
static   
# 63 "/root/src/tinyos-1.x/tos/interfaces/Random.nc"
uint16_t BVirusExtended$Random$rand(void);
static   
#line 57
result_t BVirusExtended$Random$init(void);
static  
# 63 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
result_t BVirusExtended$SubControl$init(void);
static  





result_t BVirusExtended$SubControl$start(void);
static  






result_t BVirusExtended$SubControl$stop(void);
static  
# 85 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaVirus.nc"
result_t BVirusExtended$Virus$capsuleHeard(uint8_t arg_0xbf51fc90);
static  
#line 84
result_t BVirusExtended$Virus$capsuleInstalled(BombillaCapsule *arg_0xbf51f888);
static  
void BVirusExtended$Virus$capsuleForce(uint8_t arg_0xbf5100a0);
static  
# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
result_t BVirusExtended$BCastSend$send(uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0);
static  
#line 48
result_t BVirusExtended$VersionSend$send(uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0);
static  
# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
result_t BVirusExtended$CapsuleTimer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0);
static  







result_t BVirusExtended$CapsuleTimer$stop(void);
# 107 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
typedef enum BVirusExtended$__nesc_unnamed4370 {
  BVirusExtended$BVIRUS_TIMER_VERSION = 100, 
  BVirusExtended$BVIRUS_TIMER_CAPSULE = 1000, 
  BVirusExtended$BVIRUS_CAPSULE_INIT = 1, 
  BVirusExtended$BVIRUS_CAPSULE_MAX = 16, 
  BVirusExtended$BVIRUS_VERSION_THRESHOLD_INIT = 1, 
  BVirusExtended$BVIRUS_VERSION_THRESHOLD_MAX = 300, 
  BVirusExtended$TAU_INIT = 10, 
  BVirusExtended$TAU_MAX = 600, 
  BVirusExtended$BVIRUS_VERSION_HEARD_THRESHOLD = 1
} BVirusExtended$BVirusConstants;

typedef enum BVirusExtended$__nesc_unnamed4371 {
  BVirusExtended$BVIRUS_IDLE, 
  BVirusExtended$BVIRUS_PULLING, 
  BVirusExtended$BVIRUS_PUSHING
} BVirusExtended$BVirusState;

BombillaCapsule *BVirusExtended$capsules[1000][BOMB_CAPSULE_NUM];
uint8_t BVirusExtended$capsuleTimerThresholds[1000][BOMB_CAPSULE_NUM];

uint8_t BVirusExtended$capsuleTimerCounters[1000][BOMB_CAPSULE_NUM];
uint8_t BVirusExtended$bCastIdx[1000];

uint16_t BVirusExtended$versionCounter[1000];
uint16_t BVirusExtended$versionThreshold[1000];
uint16_t BVirusExtended$versionCancelled[1000];
uint16_t BVirusExtended$tau[1000];
uint16_t BVirusExtended$versionHeard[1000];


BVirusExtended$BVirusState BVirusExtended$state[1000];
bool BVirusExtended$sendBusy[1000];
bool BVirusExtended$capsuleBusy[1000];
bool BVirusExtended$amBCasting[1000];

TOS_Msg BVirusExtended$sendMessage[1000];
TOS_MsgPtr BVirusExtended$sendPtr[1000];
TOS_Msg BVirusExtended$receiveMsg[1000];
TOS_MsgPtr BVirusExtended$receivePtr[1000];
static inline 
void BVirusExtended$cancelVersionCounter(void);
static 


void BVirusExtended$newVersionCounter(void);
static inline 






uint8_t BVirusExtended$typeToIndex(uint8_t type);
static inline  








result_t BVirusExtended$StdControl$init(void);
static inline  
#line 193
result_t BVirusExtended$StdControl$start(void);
static inline  







result_t BVirusExtended$StdControl$stop(void);
static  






result_t BVirusExtended$Virus$registerCapsule(uint8_t type, BombillaCapsule *capsule);
static 








result_t BVirusExtended$receiveCapsule(BombillaCapsule *capsule, uint16_t payloadLen, char *type);
static inline 
#line 260
result_t BVirusExtended$sendCapsule(uint8_t idx);
static inline 
#line 285
result_t BVirusExtended$sendBCastCapsule(uint8_t idx);
static inline 
#line 312
result_t BVirusExtended$sendVersionPacket(void);
static inline  
#line 341
void BVirusExtended$versionTimerTask(void);
static inline  
#line 367
result_t BVirusExtended$VersionTimer$fired(void);
static inline 





TOS_MsgPtr BVirusExtended$receiveProgram(TOS_MsgPtr msg);
static inline 



TOS_MsgPtr BVirusExtended$receiveVector(TOS_MsgPtr msg);
static inline  
#line 421
TOS_MsgPtr BVirusExtended$VersionReceive$receive(TOS_MsgPtr msg);
static inline  
#line 438
void BVirusExtended$capsuleTimerTask(void);
static inline  
#line 464
result_t BVirusExtended$CapsuleTimer$fired(void);
static  



result_t BVirusExtended$InterceptRouted$intercept(TOS_MsgPtr msg, 
void *payload, 
uint16_t payloadLen);
static inline  







TOS_MsgPtr BVirusExtended$ReceiveRouted$receive(TOS_MsgPtr msg, 
void *payload, 
uint16_t payloadLen);
static inline  






TOS_MsgPtr BVirusExtended$CapsuleReceive$receive(TOS_MsgPtr msg);
static inline  






TOS_MsgPtr BVirusExtended$BCastReceive$receive(TOS_MsgPtr msg);
static inline  
#line 514
result_t BVirusExtended$BCastTimer$fired(void);
static inline  




result_t BVirusExtended$CapsuleSend$sendDone(TOS_MsgPtr msg, result_t success);
static inline  






result_t BVirusExtended$VersionSend$sendDone(TOS_MsgPtr msg, result_t success);
static inline  






result_t BVirusExtended$BCastSend$sendDone(TOS_MsgPtr msg, result_t success);
static  
# 49 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
result_t QueuedSendM$QueueSendMsg$sendDone(
# 60 "/root/src/tinyos-1.x/tos/lib/Queue/QueuedSendM.nc"
uint8_t arg_0xbf4aa9e0, 
# 49 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
TOS_MsgPtr arg_0x9de8e10, result_t arg_0x9de8f60);
static   
# 106 "/root/src/tinyos-1.x/tos/interfaces/Leds.nc"
result_t QueuedSendM$Leds$greenToggle(void);
static   
#line 81
result_t QueuedSendM$Leds$redToggle(void);
static  
# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
result_t QueuedSendM$SerialSendMsg$send(
# 65 "/root/src/tinyos-1.x/tos/lib/Queue/QueuedSendM.nc"
uint8_t arg_0xbf4ab368, 
# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0);
# 74 "/root/src/tinyos-1.x/tos/lib/Queue/QueuedSendM.nc"
enum QueuedSendM$__nesc_unnamed4372 {
  QueuedSendM$MESSAGE_QUEUE_SIZE = 32, 
  QueuedSendM$MAX_RETRANSMIT_COUNT = 5
};

struct QueuedSendM$_msgq_entry {
  uint16_t address;
  uint8_t length;
  uint8_t id;
  uint8_t xmit_count;
  TOS_MsgPtr pMsg;
} QueuedSendM$msgqueue[1000][QueuedSendM$MESSAGE_QUEUE_SIZE];

uint16_t QueuedSendM$enqueue_next[1000];
#line 87
uint16_t QueuedSendM$dequeue_next[1000];
bool QueuedSendM$retransmit[1000];
bool QueuedSendM$fQueueIdle[1000];
static inline  
result_t QueuedSendM$StdControl$init(void);
static inline  
#line 107
result_t QueuedSendM$StdControl$start(void);
static inline  

result_t QueuedSendM$StdControl$stop(void);
static  
#line 122
void QueuedSendM$QueueServiceTask(void);
static inline 
#line 141
void QueuedSendM$queue_test_func(void);
static  



result_t QueuedSendM$QueueSendMsg$send(uint8_t id, uint16_t address, uint8_t length, TOS_MsgPtr msg);
static inline  
#line 182
result_t QueuedSendM$SerialSendMsg$sendDone(uint8_t id, TOS_MsgPtr msg, result_t success);
# 54 "/root/src/tinyos-1.x/tos/system/RandomLFSR.nc"
uint16_t RandomLFSR$shiftReg[1000];
uint16_t RandomLFSR$initSeed[1000];
uint16_t RandomLFSR$mask[1000];
static   

result_t RandomLFSR$Random$init(void);
static   









uint16_t RandomLFSR$Random$rand(void);
static  
# 71 "/root/src/tinyos-1.x/tos/interfaces/RouteSelect.nc"
result_t MultiHopEngineGridM$RouteSelect$selectRoute(TOS_MsgPtr arg_0xbf47e7f8, uint8_t arg_0xbf47e940);
static  
#line 86
result_t MultiHopEngineGridM$RouteSelect$initializeFields(TOS_MsgPtr arg_0xbf47eeb8, uint8_t arg_0xbf47f000);
static  
# 86 "/root/src/tinyos-1.x/tos/interfaces/Intercept.nc"
result_t MultiHopEngineGridM$Intercept$intercept(
# 52 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopEngineGridM.nc"
uint8_t arg_0xbf486cc0, 
# 86 "/root/src/tinyos-1.x/tos/interfaces/Intercept.nc"
TOS_MsgPtr arg_0xbf4fbb80, void *arg_0xbf4fbcd8, uint16_t arg_0xbf4fbe30);
static  
#line 86
result_t MultiHopEngineGridM$Snoop$intercept(
# 53 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopEngineGridM.nc"
uint8_t arg_0xbf4871f0, 
# 86 "/root/src/tinyos-1.x/tos/interfaces/Intercept.nc"
TOS_MsgPtr arg_0xbf4fbb80, void *arg_0xbf4fbcd8, uint16_t arg_0xbf4fbe30);
static  
# 119 "/root/src/tinyos-1.x/tos/interfaces/Send.nc"
result_t MultiHopEngineGridM$Send$sendDone(
# 51 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopEngineGridM.nc"
uint8_t arg_0xbf486658, 
# 119 "/root/src/tinyos-1.x/tos/interfaces/Send.nc"
TOS_MsgPtr arg_0xbf48bbf8, result_t arg_0xbf48bd48);
static  
# 81 "/root/src/tinyos-1.x/tos/interfaces/Receive.nc"
TOS_MsgPtr MultiHopEngineGridM$Receive$receive(
# 50 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopEngineGridM.nc"
uint8_t arg_0xbf486158, 
# 81 "/root/src/tinyos-1.x/tos/interfaces/Receive.nc"
TOS_MsgPtr arg_0xbf4fa3b0, void *arg_0xbf4fa508, uint16_t arg_0xbf4fa660);
static  
# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
result_t MultiHopEngineGridM$SendMsg$send(
# 59 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopEngineGridM.nc"
uint8_t arg_0xbf484740, 
# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0);
# 71 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopEngineGridM.nc"
enum MultiHopEngineGridM$__nesc_unnamed4373 {
  MultiHopEngineGridM$FWD_QUEUE_SIZE = 16, 
  MultiHopEngineGridM$EMPTY = 0xff
};






struct TOS_Msg;
struct TOS_Msg *MultiHopEngineGridM$FwdBufList[1000][MultiHopEngineGridM$FWD_QUEUE_SIZE];

uint8_t MultiHopEngineGridM$iFwdBufHead[1000];
#line 84
uint8_t MultiHopEngineGridM$iFwdBufTail[1000];
static  
#line 126
result_t MultiHopEngineGridM$Send$send(uint8_t id, TOS_MsgPtr pMsg, uint16_t PayloadLen);
static  
#line 153
void *MultiHopEngineGridM$Send$getBuffer(uint8_t id, TOS_MsgPtr pMsg, uint16_t *length);










static TOS_MsgPtr MultiHopEngineGridM$mForward(TOS_MsgPtr pMsg, uint8_t id);
static  
#line 186
TOS_MsgPtr MultiHopEngineGridM$ReceiveMsg$receive(uint8_t id, TOS_MsgPtr pMsg);
static inline   
#line 213
TOS_MsgPtr MultiHopEngineGridM$Receive$default$receive(uint8_t id, TOS_MsgPtr msg, void *payload, uint16_t payloadLen);
static  



result_t MultiHopEngineGridM$SendMsg$sendDone(uint8_t id, TOS_MsgPtr pMsg, result_t success);
static inline   
#line 288
result_t MultiHopEngineGridM$Send$default$sendDone(uint8_t id, TOS_MsgPtr pMsg, result_t success);
static inline   


result_t MultiHopEngineGridM$Intercept$default$intercept(uint8_t id, TOS_MsgPtr pMsg, void *payload, 
uint16_t payloadLen);
static   
# 63 "/root/src/tinyos-1.x/tos/interfaces/Random.nc"
uint16_t MultiHopGrid$Random$rand(void);
static   
# 106 "/root/src/tinyos-1.x/tos/interfaces/Leds.nc"
result_t MultiHopGrid$Leds$greenToggle(void);
static   
#line 131
result_t MultiHopGrid$Leds$yellowToggle(void);
static   
#line 81
result_t MultiHopGrid$Leds$redToggle(void);
static  
# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
result_t MultiHopGrid$SendMsg$send(uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0);
# 71 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopGrid.nc"
enum MultiHopGrid$__nesc_unnamed4374 {
  MultiHopGrid$NBRFLAG_VALID = 0x01, 
  MultiHopGrid$NBRFLAG_NEW = 0x02, 
  MultiHopGrid$NBRFLAG_EST_INIT = 0x04
};

enum MultiHopGrid$__nesc_unnamed4375 {
  MultiHopGrid$BASE_STATION_ADDRESS = 0, 
  MultiHopGrid$ROUTE_TABLE_SIZE = 16, 
  MultiHopGrid$ESTIMATE_TO_ROUTE_RATIO = 10, 
  MultiHopGrid$ACCEPTABLE_MISSED = -20, 
  MultiHopGrid$DATA_TO_ROUTE_RATIO = 2, 
  MultiHopGrid$DATA_FREQ = 1000, 
  MultiHopGrid$SWITCH_THRESHOLD = 192, 
  MultiHopGrid$MAX_ALLOWABLE_LINK_COST = 256 * 6, 
  MultiHopGrid$LIVELINESS = 2, 
  MultiHopGrid$MAX_DESCENDANT_LIVE = 5
};






enum MultiHopGrid$__nesc_unnamed4376 {
  MultiHopGrid$ROUTE_INVALID = 0xff
};

struct MultiHopGrid$SortEntry {
  uint16_t id;
  uint8_t receiveEst;
};

struct MultiHopGrid$SortDbgEntry {
  uint16_t id;
  uint8_t sendEst;
  uint8_t hopcount;
};

typedef struct MultiHopGrid$RPEstEntry {
  uint16_t id;
  uint8_t receiveEst;
} __attribute((packed))  MultiHopGrid$RPEstEntry;

typedef struct MultiHopGrid$RoutePacket {
  uint16_t parent;
  uint16_t cost;
  uint8_t estEntries;
  MultiHopGrid$RPEstEntry estList[1];
} __attribute((packed))  MultiHopGrid$RoutePacket;

typedef struct MultiHopGrid$TableEntry {
  uint16_t id;
  uint16_t parent;
  uint16_t cost;
  uint8_t childLiveliness;
  uint16_t missed;
  uint16_t received;
  int16_t lastSeqno;
  uint8_t flags;
  uint8_t liveliness;
  uint8_t hop;
  uint8_t receiveEst;
  uint8_t sendEst;
} MultiHopGrid$TableEntry;


TOS_Msg MultiHopGrid$routeMsg[1000];
bool MultiHopGrid$gfSendRouteBusy[1000];



MultiHopGrid$TableEntry MultiHopGrid$NeighborTbl[1000][MultiHopGrid$ROUTE_TABLE_SIZE];
MultiHopGrid$TableEntry *MultiHopGrid$gpCurrentParent[1000];
uint8_t MultiHopGrid$gbCurrentHopCount[1000];
uint16_t MultiHopGrid$gbCurrentCost[1000];
int16_t MultiHopGrid$gCurrentSeqNo[1000];
uint16_t MultiHopGrid$gwEstTicks[1000];
static 
#line 160
uint8_t MultiHopGrid$findEntry(uint8_t id);
static inline 
#line 178
uint8_t MultiHopGrid$findEntryToBeReplaced(void);
static 
#line 202
void MultiHopGrid$newEntry(uint8_t indes, uint16_t id);
static inline 
#line 230
uint8_t MultiHopGrid$findPreparedIndex(uint16_t id);
static 
#line 260
uint32_t MultiHopGrid$evaluateCost(uint16_t cost, uint8_t sendEst, uint8_t receiveEst);
static inline 
#line 272
void MultiHopGrid$updateEst(MultiHopGrid$TableEntry *Nbr);
static inline 
#line 320
void MultiHopGrid$updateTable(void);
static 
#line 336
bool MultiHopGrid$updateNbrCounters(uint16_t saddr, int16_t seqno, uint8_t *NbrIndex);
static inline 
#line 373
void MultiHopGrid$chooseParent(void);
#line 449
uint8_t MultiHopGrid$last_entry_sent[1000];
static inline  
void MultiHopGrid$SendRouteTask(void);
static inline  
#line 544
void MultiHopGrid$TimerTask(void);
static inline  
#line 590
result_t MultiHopGrid$ATimer$fired(void);
static inline 
#line 655
void MultiHopGrid$updateDescendant(uint16_t id);
static  






result_t MultiHopGrid$RouteSelect$selectRoute(TOS_MsgPtr Msg, uint8_t id);
static  
#line 748
result_t MultiHopGrid$RouteSelect$initializeFields(TOS_MsgPtr Msg, uint8_t id);
static inline  
#line 814
result_t MultiHopGrid$Timer$fired(void);
static inline  



TOS_MsgPtr MultiHopGrid$ReceiveMsg$receive(TOS_MsgPtr Msg);
static inline  
#line 851
result_t MultiHopGrid$Snoop$intercept(uint8_t id, TOS_MsgPtr Msg, void *Payload, uint16_t Len);
static inline  
#line 864
result_t MultiHopGrid$SendMsg$sendDone(TOS_MsgPtr pMsg, result_t success);
static inline  



result_t MultiHopGrid$DebugSendMsg$sendDone(TOS_MsgPtr pMsg, result_t success);
static inline  
#line 914
result_t MultiHopGrid$fillInAddr(uint16_t addr, TOS_MsgPtr msg);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPrandM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static   
# 63 "/root/src/tinyos-1.x/tos/interfaces/Random.nc"
uint16_t OPrandM$Random$rand(void);
static   
#line 57
result_t OPrandM$Random$init(void);
static inline  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPrandM.nc"
result_t OPrandM$StdControl$init(void);
static inline  



result_t OPrandM$StdControl$start(void);
static inline  


result_t OPrandM$StdControl$stop(void);
static inline  


result_t OPrandM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
BombillaStackVariable *OProuteM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
result_t OProuteM$Error$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OProuteM.nc"
result_t OProuteM$fillInAddr(uint16_t arg_0xbf3e6df0, TOS_MsgPtr arg_0xbf3e6f40);
static  
# 83 "/root/src/tinyos-1.x/tos/interfaces/Send.nc"
result_t OProuteM$Send$send(TOS_MsgPtr arg_0xbf48aae0, uint16_t arg_0xbf48ac30);
static  
#line 106
void *OProuteM$Send$getBuffer(TOS_MsgPtr arg_0xbf48b268, uint16_t *arg_0xbf48b3d0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OProuteM$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static  
# 152 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
void OProuteM$Synch$yieldContext(BombillaContext *arg_0x9df13a0);
static  
#line 129
result_t OProuteM$Synch$releaseLocks(BombillaContext *arg_0x9df0010, 
BombillaContext *arg_0x9df0190);
static  
#line 154
bool OProuteM$Synch$resumeContext(BombillaContext *arg_0x9df17c0, 
BombillaContext *arg_0x9df1938);
# 100 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OProuteM.nc"
BombillaCapsuleBuffer *OProuteM$onceCapsule[1000];
BombillaContext *OProuteM$sendingContext[1000];
TOS_Msg OProuteM$msg[1000];
static inline  
result_t OProuteM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
#line 138
result_t OProuteM$Send$sendDone(TOS_MsgPtr mesg, result_t success);
static inline  
#line 155
result_t OProuteM$sendDone(void);
static inline  
#line 174
void OProuteM$Comm$registerCapsule(BombillaCapsuleBuffer *capsule);
static inline  

void OProuteM$Comm$reboot(void);
static inline  result_t OProuteM$Synch$makeRunnable(BombillaContext *context);
static  
# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
result_t OnceContextM$Timer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0);
static  
# 101 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextComm.nc"
void OnceContextM$Comm$reboot(void);
static  
#line 90
void OnceContextM$Comm$registerCapsule(BombillaCapsuleBuffer *arg_0x9dd4a30);
static  
# 82 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaVirus.nc"
result_t OnceContextM$Virus$registerCapsule(uint8_t arg_0xbf51f2e8, BombillaCapsule *arg_0xbf51f450);
static  
# 80 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaAnalysis.nc"
void OnceContextM$Analysis$analyzeCapsuleVars(BombillaCapsuleBuffer *arg_0x9dd1c28);
static  
# 150 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
void OnceContextM$Synch$initializeContext(BombillaContext *arg_0x9df0f88);
static  


bool OnceContextM$Synch$resumeContext(BombillaContext *arg_0x9df17c0, 
BombillaContext *arg_0x9df1938);
# 92 "/root/src/tinyos-1.x/tos/lib/VM/contexts/OnceContextM.nc"
BombillaContext OnceContextM$onceContext[1000];
static inline  
result_t OnceContextM$StdControl$init(void);
static inline  
#line 139
result_t OnceContextM$Timer$fired(void);
static inline  


result_t OnceContextM$StdControl$start(void);
static inline  





result_t OnceContextM$StdControl$stop(void);
static inline  


result_t OnceContextM$Comm$analyzeLockSets(BombillaCapsuleBuffer *capsules[]);
static inline  


result_t OnceContextM$Synch$makeRunnable(BombillaContext *context);
static  


result_t OnceContextM$Virus$capsuleInstalled(BombillaCapsule *capsule);
static inline  
#line 184
result_t OnceContextM$Virus$capsuleHeard(uint8_t type);
static inline  


void OnceContextM$Virus$capsuleForce(uint8_t type);
static  
# 131 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPbpush1M$Stacks$pushBuffer(BombillaContext *arg_0x9fb6cc8, BombillaDataBuffer *arg_0x9fb6e38);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
result_t OPbpush1M$Error$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static  
# 137 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaLocks.nc"
bool OPbpush1M$Locks$isHeldBy(uint8_t arg_0x9fbf1b8, BombillaContext *arg_0x9fbf320);
# 93 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbpush1M.nc"
typedef enum OPbpush1M$__nesc_unnamed4377 {
  OPbpush1M$BOMB_BUF_LOCK_1_0 = 0, 
  OPbpush1M$BOMB_BUF_LOCK_1_1 = 1
} OPbpush1M$BufLockNames;

BombillaDataBuffer OPbpush1M$buffers[1000][BOMB_BUF_NUM];
static inline 
uint8_t OPbpush1M$varToLock(uint8_t arg);
static  
#line 112
result_t OPbpush1M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static inline  
#line 125
int16_t OPbpush1M$BombillaBytecodeLock$lockNum(uint8_t instr);
static  







result_t OPbpush1M$Virus$capsuleInstalled(BombillaCapsule *capsule);
static inline  
#line 151
result_t OPbpush1M$Virus$capsuleHeard(uint8_t type);
static inline  


void OPbpush1M$Virus$capsuleForce(uint8_t type);
static  
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
BombillaStackVariable *OPsettimer1M$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPsettimer1M$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static  
# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
result_t OPsettimer1M$Timer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0);
static  







result_t OPsettimer1M$Timer$stop(void);
static  
# 96 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPsettimer1M.nc"
result_t OPsettimer1M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 63 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
result_t Timer1ContextM$SubControlTimer$init(void);
static  





result_t Timer1ContextM$SubControlTimer$start(void);
static  






result_t Timer1ContextM$SubControlTimer$stop(void);
static  
# 150 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
void Timer1ContextM$Synch$initializeContext(BombillaContext *arg_0x9df0f88);
static  


bool Timer1ContextM$Synch$resumeContext(BombillaContext *arg_0x9df17c0, 
BombillaContext *arg_0x9df1938);
static  
# 101 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextComm.nc"
void Timer1ContextM$Comm$reboot(void);
static  
#line 90
void Timer1ContextM$Comm$registerCapsule(BombillaCapsuleBuffer *arg_0x9dd4a30);
static  
# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
result_t Timer1ContextM$ClockTimer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0);
static  







result_t Timer1ContextM$ClockTimer$stop(void);
static  
# 82 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaVirus.nc"
result_t Timer1ContextM$Virus$registerCapsule(uint8_t arg_0xbf51f2e8, BombillaCapsule *arg_0xbf51f450);
static  
# 80 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaAnalysis.nc"
void Timer1ContextM$Analysis$analyzeCapsuleVars(BombillaCapsuleBuffer *arg_0x9dd1c28);
# 98 "/root/src/tinyos-1.x/tos/lib/VM/contexts/Timer1ContextM.nc"
BombillaContext Timer1ContextM$clockContext[1000];
static inline  
result_t Timer1ContextM$StdControl$init(void);
static inline  
#line 121
result_t Timer1ContextM$StdControl$start(void);
static inline  



result_t Timer1ContextM$StdControl$stop(void);
static inline  




result_t Timer1ContextM$Comm$analyzeLockSets(BombillaCapsuleBuffer *capsules[]);
static inline  


void Timer1ContextM$ClockEventTask(void);
static inline  
#line 148
result_t Timer1ContextM$ClockTimer$fired(void);
static inline  




result_t Timer1ContextM$Synch$makeRunnable(BombillaContext *context);
static  


result_t Timer1ContextM$Virus$capsuleInstalled(BombillaCapsule *capsule);
static inline  
#line 177
result_t Timer1ContextM$Virus$capsuleHeard(uint8_t type);
static inline  


void Timer1ContextM$Virus$capsuleForce(uint8_t type);
static inline  


result_t Timer1ContextM$Timer$start(char type, uint32_t interval);
static inline  


result_t Timer1ContextM$Timer$stop(void);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OP2pushc10M$BombillaStacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
static  
# 87 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OP2pushc10M.nc"
result_t OP2pushc10M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
BombillaStackVariable *OP2jumps10M$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OP2jumps10M$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
result_t OP2jumps10M$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OP2jumps10M.nc"
result_t OP2jumps10M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPgetsetlocal3M$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500);
static  









BombillaStackVariable *OPgetsetlocal3M$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPgetsetlocal3M$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
# 96 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetlocal3M.nc"
BombillaStackVariable OPgetsetlocal3M$vars[1000][BOMB_CONTEXT_NUM][1 << 3];
static inline  
result_t OPgetsetlocal3M$StdControl$init(void);
static inline  









result_t OPgetsetlocal3M$StdControl$start(void);
static inline  


result_t OPgetsetlocal3M$StdControl$stop(void);
static  


result_t OPgetsetlocal3M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
#line 138
result_t OPgetsetlocal3M$Virus$capsuleInstalled(BombillaCapsule *capsule);
static inline  
#line 157
result_t OPgetsetlocal3M$Virus$capsuleHeard(uint8_t type);
static inline  


void OPgetsetlocal3M$Virus$capsuleForce(uint8_t type);
static  
# 137 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaLocks.nc"
bool OPgetsetvar4M$Locks$isHeldBy(uint8_t arg_0x9fbf1b8, BombillaContext *arg_0x9fbf320);
static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
result_t OPgetsetvar4M$Error$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840);
static  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
uint8_t OPgetsetvar4M$Types$checkTypes(BombillaContext *arg_0x9fdf160, 
BombillaStackVariable *arg_0x9fdf2e0, 
uint8_t arg_0x9fdf438);
static  
# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPgetsetvar4M$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500);
static  









BombillaStackVariable *OPgetsetvar4M$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0);
# 96 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetvar4M.nc"
typedef enum OPgetsetvar4M$__nesc_unnamed4378 {
  OPgetsetvar4M$BOMB_LOCK_4_0 = 2, 
  OPgetsetvar4M$BOMB_LOCK_4_1 = 3, 
  OPgetsetvar4M$BOMB_LOCK_4_2 = 4, 
  OPgetsetvar4M$BOMB_LOCK_4_3 = 5, 

  OPgetsetvar4M$BOMB_LOCK_4_4 = 6, 
  OPgetsetvar4M$BOMB_LOCK_4_5 = 7, 
  OPgetsetvar4M$BOMB_LOCK_4_6 = 8, 
  OPgetsetvar4M$BOMB_LOCK_4_7 = 9, 

  OPgetsetvar4M$BOMB_LOCK_4_8 = 10, 
  OPgetsetvar4M$BOMB_LOCK_4_9 = 11, 
  OPgetsetvar4M$BOMB_LOCK_4_10 = 12, 
  OPgetsetvar4M$BOMB_LOCK_4_11 = 13, 

  OPgetsetvar4M$BOMB_LOCK_4_12 = 14, 
  OPgetsetvar4M$BOMB_LOCK_4_13 = 15, 
  OPgetsetvar4M$BOMB_LOCK_4_14 = 16, 
  OPgetsetvar4M$BOMB_LOCK_4_15 = 17, 
  OPgetsetvar4M$BOMB_LOCK_4_COUNT = 16
} OPgetsetvar4M$LockNames;


BombillaStackVariable OPgetsetvar4M$heap[1000][OPgetsetvar4M$BOMB_LOCK_4_COUNT];
static inline  
result_t OPgetsetvar4M$StdControl$init(void);
static inline  







result_t OPgetsetvar4M$StdControl$start(void);
static inline  


result_t OPgetsetvar4M$StdControl$stop(void);
static 


uint8_t OPgetsetvar4M$varToLock(uint8_t num);
static inline  
#line 178
int16_t OPgetsetvar4M$BombillaBytecodeLock$lockNum(uint8_t instr);
static  




result_t OPgetsetvar4M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static  
#line 210
result_t OPgetsetvar4M$Virus$capsuleInstalled(BombillaCapsule *capsule);
static inline  
#line 227
result_t OPgetsetvar4M$Virus$capsuleHeard(uint8_t type);
static inline  


void OPgetsetvar4M$Virus$capsuleForce(uint8_t type);
static  
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
result_t OPpushc6M$BombillaStacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08);
# 87 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPpushc6M.nc"
typedef enum OPpushc6M$__nesc_unnamed4379 {
  OPpushc6M$OP_PUSHC_ARG_MASKM = 0x3f
} OPpushc6M$OPpushcConstantsM;
static  
result_t OPpushc6M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context);
static inline 
# 116 "/root/src/tinyos-1.x/tos/system/tos.h"
result_t rcombine(result_t r1, result_t r2)



{
  return r1 == FAIL ? FAIL : r2;
}

static inline  
# 273 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
result_t BombillaEngineM$SendError$sendDone(TOS_MsgPtr mesg, result_t success)
#line 273
{
  return SUCCESS;
}

# 154 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
inline static  bool OPuartM$Synch$resumeContext(BombillaContext *arg_0x9df17c0, BombillaContext *arg_0x9df1938){
#line 154
  unsigned char result;
#line 154

#line 154
  result = BContextSynch$Synch$resumeContext(arg_0x9df17c0, arg_0x9df1938);
#line 154

#line 154
  return result;
#line 154
}
#line 154
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
inline static  result_t OPuartM$Error$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840){
#line 94
  unsigned char result;
#line 94

#line 94
  result = BombillaEngineM$Error$error(arg_0x9db46f8, arg_0x9db4840);
#line 94

#line 94
  return result;
#line 94
}
#line 94
static inline  
# 154 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPuartM.nc"
result_t OPuartM$SendPacket$sendDone(TOS_MsgPtr mesg, result_t success)
#line 154
{
  BombillaContext *sender = OPuartM$sendingContext[tos_state.current_node];

  if (sender == (void *)0) {
      return SUCCESS;
    }
  dbg(DBG_USR1, "VM: UART send completed with code. %i\n", (int )success);

  if (sender->state != BOMB_STATE_SENDING) {
      OPuartM$Error$error(sender, BOMB_ERROR_QUEUE_INVALID);
      return FAIL;
    }

  OPuartM$sendingContext[tos_state.current_node] = (void *)0;
  OPuartM$Synch$resumeContext(sender, sender);

  return SUCCESS;
}

static inline  
# 536 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
result_t BVirusExtended$BCastSend$sendDone(TOS_MsgPtr msg, result_t success)
#line 536
{
  if (msg == BVirusExtended$sendPtr[tos_state.current_node]) {
      BVirusExtended$sendBusy[tos_state.current_node] = FALSE;
    }
  return SUCCESS;
}

static inline  
#line 520
result_t BVirusExtended$CapsuleSend$sendDone(TOS_MsgPtr msg, result_t success)
#line 520
{
  if (msg == BVirusExtended$sendPtr[tos_state.current_node]) {
      BVirusExtended$sendBusy[tos_state.current_node] = FALSE;
    }

  return SUCCESS;
}

static inline  result_t BVirusExtended$VersionSend$sendDone(TOS_MsgPtr msg, result_t success)
#line 528
{
  if (msg == BVirusExtended$sendPtr[tos_state.current_node]) {
      BVirusExtended$sendBusy[tos_state.current_node] = FALSE;
    }

  return SUCCESS;
}

static inline  
# 864 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopGrid.nc"
result_t MultiHopGrid$SendMsg$sendDone(TOS_MsgPtr pMsg, result_t success)
#line 864
{
  MultiHopGrid$gfSendRouteBusy[tos_state.current_node] = FALSE;

  return SUCCESS;
}

# 49 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
inline static  result_t QueuedSendM$QueueSendMsg$sendDone(uint8_t arg_0xbf4aa9e0, TOS_MsgPtr arg_0x9de8e10, result_t arg_0x9de8f60){
#line 49
  unsigned char result;
#line 49

#line 49
  result = MultiHopEngineGridM$SendMsg$sendDone(arg_0xbf4aa9e0, arg_0x9de8e10, arg_0x9de8f60);
#line 49
  switch (arg_0xbf4aa9e0) {
#line 49
    case AM_BOMBILLAVERSIONMSG:
#line 49
      result = rcombine(result, BVirusExtended$VersionSend$sendDone(arg_0x9de8e10, arg_0x9de8f60));
#line 49
      break;
#line 49
    case AM_BOMBILLACAPSULEMSG:
#line 49
      result = rcombine(result, BVirusExtended$CapsuleSend$sendDone(arg_0x9de8e10, arg_0x9de8f60));
#line 49
      break;
#line 49
    case 67:
#line 49
      result = rcombine(result, BVirusExtended$BCastSend$sendDone(arg_0x9de8e10, arg_0x9de8f60));
#line 49
      break;
#line 49
    case AM_MULTIHOPMSG:
#line 49
      result = rcombine(result, MultiHopGrid$SendMsg$sendDone(arg_0x9de8e10, arg_0x9de8f60));
#line 49
      break;
#line 49
  }
#line 49

#line 49
  return result;
#line 49
}
#line 49
static inline   
# 63 "/root/src/tinyos-1.x/tos/system/NoLeds.nc"
result_t NoLeds$Leds$redToggle(void)
#line 63
{
  return SUCCESS;
}

# 81 "/root/src/tinyos-1.x/tos/interfaces/Leds.nc"
inline static   result_t QueuedSendM$Leds$redToggle(void){
#line 81
  unsigned char result;
#line 81

#line 81
  result = NoLeds$Leds$redToggle();
#line 81

#line 81
  return result;
#line 81
}
#line 81
static inline  
# 182 "/root/src/tinyos-1.x/tos/lib/Queue/QueuedSendM.nc"
result_t QueuedSendM$SerialSendMsg$sendDone(uint8_t id, TOS_MsgPtr msg, result_t success)
#line 182
{
  if (msg != QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$dequeue_next[tos_state.current_node]].pMsg) {
      return FAIL;
    }

  dbg(DBG_ROUTE, "qent %d dequeued rt=%i, ack=%i, addr=%i.\n", QueuedSendM$dequeue_next[tos_state.current_node], (int )QueuedSendM$retransmit[tos_state.current_node], (int )msg->ack, (int )QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$dequeue_next[tos_state.current_node]].address);
  if ((!QueuedSendM$retransmit[tos_state.current_node] || msg->ack != 0) || QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$dequeue_next[tos_state.current_node]].address == TOS_UART_ADDR) {

      QueuedSendM$QueueSendMsg$sendDone(id, msg, success);
      QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$dequeue_next[tos_state.current_node]].length = 0;

      QueuedSendM$dequeue_next[tos_state.current_node]++;
#line 193
      QueuedSendM$dequeue_next[tos_state.current_node] %= QueuedSendM$MESSAGE_QUEUE_SIZE;
    }
  else 







    {
      QueuedSendM$Leds$redToggle();
      if (++ QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$dequeue_next[tos_state.current_node]].xmit_count > QueuedSendM$MAX_RETRANSMIT_COUNT) {


          dbg(DBG_ROUTE, "Queued send Retransmit timeout.\n");
          QueuedSendM$QueueSendMsg$sendDone(id, msg, FAIL);
          QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$dequeue_next[tos_state.current_node]].length = 0;
          QueuedSendM$dequeue_next[tos_state.current_node]++;
#line 211
          QueuedSendM$dequeue_next[tos_state.current_node] %= QueuedSendM$MESSAGE_QUEUE_SIZE;
        }
    }


  TOS_post(QueuedSendM$QueueServiceTask);

  return SUCCESS;
}

# 49 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
inline static  result_t AMPromiscuous$SendMsg$sendDone(uint8_t arg_0x9e70010, TOS_MsgPtr arg_0x9de8e10, result_t arg_0x9de8f60){
#line 49
  unsigned char result;
#line 49

#line 49
  result = QueuedSendM$SerialSendMsg$sendDone(arg_0x9e70010, arg_0x9de8e10, arg_0x9de8f60);
#line 49
  switch (arg_0x9e70010) {
#line 49
    case AM_BOMBILLAERRORMSG:
#line 49
      result = rcombine(result, BombillaEngineM$SendError$sendDone(arg_0x9de8e10, arg_0x9de8f60));
#line 49
      break;
#line 49
    case AM_BOMBILLAPACKETMSG:
#line 49
      result = rcombine(result, OPuartM$SendPacket$sendDone(arg_0x9de8e10, arg_0x9de8f60));
#line 49
      break;
#line 49
  }
#line 49

#line 49
  return result;
#line 49
}
#line 49
# 86 "/root/src/tinyos-1.x/tos/interfaces/RouteSelect.nc"
inline static  result_t MultiHopEngineGridM$RouteSelect$initializeFields(TOS_MsgPtr arg_0xbf47eeb8, uint8_t arg_0xbf47f000){
#line 86
  unsigned char result;
#line 86

#line 86
  result = MultiHopGrid$RouteSelect$initializeFields(arg_0xbf47eeb8, arg_0xbf47f000);
#line 86

#line 86
  return result;
#line 86
}
#line 86
static inline 
# 178 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopGrid.nc"
uint8_t MultiHopGrid$findEntryToBeReplaced(void)
#line 178
{
  uint8_t i = 0;
  uint8_t minSendEst = -1;
  uint8_t minSendEstIndex = MultiHopGrid$ROUTE_INVALID;

#line 182
  for (i = 0; i < MultiHopGrid$ROUTE_TABLE_SIZE; i++) {
      if ((MultiHopGrid$NeighborTbl[tos_state.current_node][i].flags & MultiHopGrid$NBRFLAG_VALID) == 0) {
          return i;
        }
      if (minSendEst >= MultiHopGrid$NeighborTbl[tos_state.current_node][i].sendEst) {
          minSendEst = MultiHopGrid$NeighborTbl[tos_state.current_node][i].sendEst;
          minSendEstIndex = i;
        }
    }
  return minSendEstIndex;
}

static inline 
#line 230
uint8_t MultiHopGrid$findPreparedIndex(uint16_t id)
#line 230
{
  uint8_t indes = MultiHopGrid$findEntry(id);

#line 232
  if (indes == (uint8_t )MultiHopGrid$ROUTE_INVALID) {
      indes = MultiHopGrid$findEntryToBeReplaced();
      MultiHopGrid$newEntry(indes, id);
    }
  return indes;
}

# 63 "/root/src/tinyos-1.x/tos/interfaces/Random.nc"
inline static   uint16_t MultiHopGrid$Random$rand(void){
#line 63
  unsigned short result;
#line 63

#line 63
  result = RandomLFSR$Random$rand();
#line 63

#line 63
  return result;
#line 63
}
#line 63
static inline 
# 655 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopGrid.nc"
void MultiHopGrid$updateDescendant(uint16_t id)
#line 655
{
  uint8_t indes = MultiHopGrid$findEntry(id);

#line 657
  if (indes == (uint8_t )MultiHopGrid$ROUTE_INVALID) {
#line 657
      return;
    }
  else 
#line 658
    {
      MultiHopGrid$NeighborTbl[tos_state.current_node][indes].childLiveliness = MultiHopGrid$MAX_DESCENDANT_LIVE;
    }
}

static inline  
#line 869
result_t MultiHopGrid$DebugSendMsg$sendDone(TOS_MsgPtr pMsg, result_t success)
#line 869
{
  return SUCCESS;
}

static inline   
# 288 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopEngineGridM.nc"
result_t MultiHopEngineGridM$Send$default$sendDone(uint8_t id, TOS_MsgPtr pMsg, result_t success)
#line 288
{
  return SUCCESS;
}

# 119 "/root/src/tinyos-1.x/tos/interfaces/Send.nc"
inline static  result_t MultiHopEngineGridM$Send$sendDone(uint8_t arg_0xbf486658, TOS_MsgPtr arg_0xbf48bbf8, result_t arg_0xbf48bd48){
#line 119
  unsigned char result;
#line 119

#line 119
  switch (arg_0xbf486658) {
#line 119
    case 3:
#line 119
      result = MultiHopGrid$DebugSendMsg$sendDone(arg_0xbf48bbf8, arg_0xbf48bd48);
#line 119
      break;
#line 119
    case 66:
#line 119
      result = OProuteM$Send$sendDone(arg_0xbf48bbf8, arg_0xbf48bd48);
#line 119
      break;
#line 119
    default:
#line 119
      result = MultiHopEngineGridM$Send$default$sendDone(arg_0xbf486658, arg_0xbf48bbf8, arg_0xbf48bd48);
#line 119
    }
#line 119

#line 119
  return result;
#line 119
}
#line 119
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
inline static  result_t OProuteM$Error$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840){
#line 94
  unsigned char result;
#line 94

#line 94
  result = BombillaEngineM$Error$error(arg_0x9db46f8, arg_0x9db4840);
#line 94

#line 94
  return result;
#line 94
}
#line 94
# 64 "/root/src/tinyos-1.x/tos/interfaces/Leds.nc"
inline static   result_t BombillaEngineM$Leds$redOn(void){
#line 64
  unsigned char result;
#line 64

#line 64
  result = LedsC$Leds$redOn();
#line 64

#line 64
  return result;
#line 64
}
#line 64
#line 89
inline static   result_t BombillaEngineM$Leds$greenOn(void){
#line 89
  unsigned char result;
#line 89

#line 89
  result = LedsC$Leds$greenOn();
#line 89

#line 89
  return result;
#line 89
}
#line 89
#line 114
inline static   result_t BombillaEngineM$Leds$yellowOn(void){
#line 114
  unsigned char result;
#line 114

#line 114
  result = LedsC$Leds$yellowOn();
#line 114

#line 114
  return result;
#line 114
}
#line 114
# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t BombillaEngineM$ErrorTimer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0){
#line 59
  unsigned char result;
#line 59

#line 59
  result = TimerM$Timer$start(0, arg_0x9de4698, arg_0x9de47f0);
#line 59

#line 59
  return result;
#line 59
}
#line 59
static inline 
# 86 "/root/src/tinyos-1.x/tos/platform/pc/hpl.c"
uint8_t TOSH_get_clock0_counter(void)
#line 86
{

  if (scales[tos_state.current_node] == 0 || 
  intervals[tos_state.current_node] == 0) {
#line 89
      return 0;
    }
  else 
#line 90
    {
      long long timeDiff = tos_state.tos_time - setTime[tos_state.current_node];

#line 92
      timeDiff /= (long long )clockScales[scales[tos_state.current_node]];
      timeDiff %= (long long )intervals[tos_state.current_node];
      return (uint8_t )timeDiff;
    }
}

static inline   
# 113 "/root/src/tinyos-1.x/tos/platform/pc/HPLClock.nc"
uint8_t HPLClock$Clock$readCounter(void)
#line 113
{
  return TOSH_get_clock0_counter();
}

# 153 "/root/src/tinyos-1.x/tos/interfaces/Clock.nc"
inline static   uint8_t TimerM$Clock$readCounter(void){
#line 153
  unsigned char result;
#line 153

#line 153
  result = HPLClock$Clock$readCounter();
#line 153

#line 153
  return result;
#line 153
}
#line 153
static inline 
# 172 "/root/src/tinyos-1.x/tos/platform/pc/hpl.c"
void event_clocktick_invalidate(event_t *event)
#line 172
{
  clock_tick_data_t *data = event->data;

#line 174
  data->valid = 0;
}

static inline 
# 56 "/root/src/tinyos-1.x/tos/platform/pc/events.c"
void event_cleanup(event_t *fevent)
{
  dbg(DBG_MEM, "event_cleanup: freeing event: 0x%x\n", (unsigned int )fevent);
  fevent->cleanup(fevent);
}

static inline   
# 50 "/root/src/tinyos-1.x/tos/platform/pc/HPLPowerManagementM.nc"
uint8_t HPLPowerManagementM$PowerManagement$adjustPower(void)
#line 50
{
  return HPLPowerManagementM$IDLE;
}

# 41 "/root/src/tinyos-1.x/tos/interfaces/PowerManagement.nc"
inline static   uint8_t TimerM$PowerManagement$adjustPower(void){
#line 41
  unsigned char result;
#line 41

#line 41
  result = HPLPowerManagementM$PowerManagement$adjustPower();
#line 41

#line 41
  return result;
#line 41
}
#line 41
static inline   
# 82 "/root/src/tinyos-1.x/tos/platform/pc/HPLClock.nc"
void HPLClock$Clock$setInterval(uint8_t value)
#line 82
{
  TOSH_clock_set_rate(value, HPLClock$mscale[tos_state.current_node]);
}

# 105 "/root/src/tinyos-1.x/tos/interfaces/Clock.nc"
inline static   void TimerM$Clock$setInterval(uint8_t arg_0x9e308c8){
#line 105
  HPLClock$Clock$setInterval(arg_0x9e308c8);
#line 105
}
#line 105
# 116 "/root/src/tinyos-1.x/tos/system/TimerM.nc"
static void TimerM$adjustInterval(void)
#line 116
{
  uint8_t i;
#line 117
  uint8_t val = TimerM$maxTimerInterval;
  uint8_t which;

#line 119
  if (TimerM$mState[tos_state.current_node]) {
      for (i = 0; i < NUM_TIMERS; i++) {
          if (TimerM$mState[tos_state.current_node] & (0x1 << i) && TimerM$mTimerList[tos_state.current_node][i].ticksLeft < val) {
              val = TimerM$mTimerList[tos_state.current_node][i].ticksLeft;
              which = i;
            }
        }
      { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 126
        {
          TimerM$mInterval[tos_state.current_node] = val;
          TimerM$Clock$setInterval(TimerM$mInterval[tos_state.current_node]);
          TimerM$setIntervalFlag[tos_state.current_node] = 0;
        }
#line 130
        __nesc_atomic_end(__nesc_atomic); }
    }
  else {
      { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 133
        {
          TimerM$mInterval[tos_state.current_node] = TimerM$maxTimerInterval;
          TimerM$Clock$setInterval(TimerM$mInterval[tos_state.current_node]);
          TimerM$setIntervalFlag[tos_state.current_node] = 0;
        }
#line 137
        __nesc_atomic_end(__nesc_atomic); }
    }
  TimerM$PowerManagement$adjustPower();
}

# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
inline static  result_t BombillaEngineM$SendError$send(uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0){
#line 48
  unsigned char result;
#line 48

#line 48
  result = AMPromiscuous$SendMsg$send(AM_BOMBILLAERRORMSG, arg_0x9de8758, arg_0x9de88a0, arg_0x9de89f0);
#line 48

#line 48
  return result;
#line 48
}
#line 48
# 131 "/root/src/tinyos-1.x/tos/interfaces/Leds.nc"
inline static   result_t BombillaEngineM$Leds$yellowToggle(void){
#line 131
  unsigned char result;
#line 131

#line 131
  result = LedsC$Leds$yellowToggle();
#line 131

#line 131
  return result;
#line 131
}
#line 131
#line 106
inline static   result_t BombillaEngineM$Leds$greenToggle(void){
#line 106
  unsigned char result;
#line 106

#line 106
  result = LedsC$Leds$greenToggle();
#line 106

#line 106
  return result;
#line 106
}
#line 106
#line 81
inline static   result_t BombillaEngineM$Leds$redToggle(void){
#line 81
  unsigned char result;
#line 81

#line 81
  result = LedsC$Leds$redToggle();
#line 81

#line 81
  return result;
#line 81
}
#line 81
# 68 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t BombillaEngineM$ErrorTimer$stop(void){
#line 68
  unsigned char result;
#line 68

#line 68
  result = TimerM$Timer$stop(0);
#line 68

#line 68
  return result;
#line 68
}
#line 68
static inline  
# 246 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
result_t BombillaEngineM$ErrorTimer$fired(void)
#line 246
{
  dbg(DBG_USR1 | DBG_ERROR, "VM: ERROR\n");
  if (!BombillaEngineM$inErrorState[tos_state.current_node]) {
      BombillaEngineM$ErrorTimer$stop();
      return FAIL;
    }
  BombillaEngineM$Leds$redToggle();
  BombillaEngineM$Leds$greenToggle();
  BombillaEngineM$Leds$yellowToggle();
  nmemcpy(BombillaEngineM$msg[tos_state.current_node].data, 
  &BombillaEngineM$errorMsg[tos_state.current_node], 
  sizeof(BombillaErrorMsg ));

  if (BombillaEngineM$errorFlipFlop[tos_state.current_node]) {
      BombillaEngineM$SendError$send(TOS_UART_ADDR, 
      sizeof(BombillaErrorMsg ), 
      (TOS_MsgPtr )&BombillaEngineM$msg[tos_state.current_node]);
    }
  else {
      BombillaEngineM$SendError$send(TOS_BCAST_ADDR, 
      sizeof(BombillaErrorMsg ), 
      (TOS_MsgPtr )&BombillaEngineM$msg[tos_state.current_node]);
    }
  BombillaEngineM$errorFlipFlop[tos_state.current_node] = !BombillaEngineM$errorFlipFlop[tos_state.current_node];
  return SUCCESS;
}

static inline  
# 176 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
result_t AMPromiscuous$ActivityTimer$fired(void)
#line 176
{
  AMPromiscuous$lastCount[tos_state.current_node] = AMPromiscuous$counter[tos_state.current_node];
  AMPromiscuous$counter[tos_state.current_node] = 0;
  return SUCCESS;
}

static inline 
# 244 "/root/src/tinyos-1.x/tos/platform/pc/external_comm.c"
int printTime(char *buf, int len)
#line 244
{
  return printOtherTime(buf, len, tos_state.tos_time);
}

# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
inline static  result_t BVirusExtended$BCastSend$send(uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0){
#line 48
  unsigned char result;
#line 48

#line 48
  result = QueuedSendM$QueueSendMsg$send(67, arg_0x9de8758, arg_0x9de88a0, arg_0x9de89f0);
#line 48

#line 48
  return result;
#line 48
}
#line 48
static inline 
# 285 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
result_t BVirusExtended$sendBCastCapsule(uint8_t idx)
#line 285
{
  BombillaCapsule *capsule = BVirusExtended$capsules[tos_state.current_node][idx];
  BombillaCapsuleMsg *msg = (BombillaCapsuleMsg *)BVirusExtended$sendPtr[tos_state.current_node]->data;

#line 288
  if (BVirusExtended$sendBusy[tos_state.current_node]) {
#line 288
      return FAIL;
    }
  else 
#line 289
    {

      BVirusExtended$sendBusy[tos_state.current_node] = TRUE;

      nmemcpy(& msg->capsule, capsule, sizeof(BombillaCapsule ));

      if (!BVirusExtended$BCastSend$send(TOS_BCAST_ADDR, sizeof(BombillaCapsuleMsg ), BVirusExtended$sendPtr[tos_state.current_node])) {
          BVirusExtended$sendBusy[tos_state.current_node] = FALSE;
          return FAIL;
        }
      else {

          char timeVal[128];

#line 302
          printTime(timeVal, 128);
          printf("%i: Broadcasting capsule %i @ %s\n", (int )TOS_LOCAL_ADDRESS, (int )idx, timeVal);



          return SUCCESS;
        }
    }
}

static inline  
#line 514
result_t BVirusExtended$BCastTimer$fired(void)
#line 514
{
  BVirusExtended$sendBCastCapsule(BVirusExtended$bCastIdx[tos_state.current_node]);
  BVirusExtended$amBCasting[tos_state.current_node] = FALSE;
  return SUCCESS;
}

# 68 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t BVirusExtended$CapsuleTimer$stop(void){
#line 68
  unsigned char result;
#line 68

#line 68
  result = TimerM$Timer$stop(3);
#line 68

#line 68
  return result;
#line 68
}
#line 68
# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
inline static  result_t BVirusExtended$CapsuleSend$send(uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0){
#line 48
  unsigned char result;
#line 48

#line 48
  result = QueuedSendM$QueueSendMsg$send(AM_BOMBILLACAPSULEMSG, arg_0x9de8758, arg_0x9de88a0, arg_0x9de89f0);
#line 48

#line 48
  return result;
#line 48
}
#line 48
static inline 
# 260 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
result_t BVirusExtended$sendCapsule(uint8_t idx)
#line 260
{
  BombillaCapsule *capsule = BVirusExtended$capsules[tos_state.current_node][idx];
  BombillaCapsuleMsg *msg = (BombillaCapsuleMsg *)BVirusExtended$sendPtr[tos_state.current_node]->data;

#line 263
  if (BVirusExtended$sendBusy[tos_state.current_node]) {
#line 263
      return FAIL;
    }
  else 
#line 264
    {

      BVirusExtended$sendBusy[tos_state.current_node] = TRUE;

      nmemcpy(& msg->capsule, capsule, sizeof(BombillaCapsule ));

      if (!BVirusExtended$CapsuleSend$send(TOS_BCAST_ADDR, sizeof(BombillaCapsuleMsg ), BVirusExtended$sendPtr[tos_state.current_node])) {
          BVirusExtended$sendBusy[tos_state.current_node] = FALSE;
          return FAIL;
        }
      else {

          char timeVal[128];

#line 277
          printTime(timeVal, 128);
          dbg(DBG_USR3, "Sending capsule %i @ %s\n", (int )idx, timeVal);

          return SUCCESS;
        }
    }
}

static inline  
#line 438
void BVirusExtended$capsuleTimerTask(void)
#line 438
{
  uint8_t i;
  bool halt = TRUE;

#line 441
  dbg(DBG_USR3, "BVirus: Capsule task running.\n");
  for (i = 0; i < BOMB_CAPSULE_NUM; i++) {
      BVirusExtended$capsuleTimerCounters[tos_state.current_node][i]++;
    }
  for (i = 0; i < BOMB_CAPSULE_NUM; i++) {
      if (BVirusExtended$capsuleTimerThresholds[tos_state.current_node][i] <= BVirusExtended$BVIRUS_CAPSULE_MAX) {
          halt = FALSE;
          if (BVirusExtended$capsuleTimerCounters[tos_state.current_node][i] >= BVirusExtended$capsuleTimerThresholds[tos_state.current_node][i]) {
              if (BVirusExtended$sendCapsule(i)) {
                  BVirusExtended$capsuleTimerThresholds[tos_state.current_node][i] <<= 2;
                  BVirusExtended$capsuleTimerCounters[tos_state.current_node][i] = 0;
                }
              break;
            }
        }
    }
  if (halt) {
      BVirusExtended$CapsuleTimer$stop();
      BVirusExtended$state[tos_state.current_node] = BVirusExtended$BVIRUS_PULLING;
    }
  return;
}

static inline  result_t BVirusExtended$CapsuleTimer$fired(void)
#line 464
{
  TOS_post(BVirusExtended$capsuleTimerTask);
  return SUCCESS;
}

# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
inline static  result_t BVirusExtended$VersionSend$send(uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0){
#line 48
  unsigned char result;
#line 48

#line 48
  result = QueuedSendM$QueueSendMsg$send(AM_BOMBILLAVERSIONMSG, arg_0x9de8758, arg_0x9de88a0, arg_0x9de89f0);
#line 48

#line 48
  return result;
#line 48
}
#line 48
static inline 
# 312 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
result_t BVirusExtended$sendVersionPacket(void)
#line 312
{
  int i;
  BombillaVersionMsg *msg = (BombillaVersionMsg *)BVirusExtended$sendPtr[tos_state.current_node]->data;

#line 315
  dbg(DBG_USR3, "Sending version vector packet:\n  ");
  if (BVirusExtended$sendBusy[tos_state.current_node]) {
#line 316
      return FAIL;
    }
#line 317
  BVirusExtended$sendBusy[tos_state.current_node] = TRUE;

  msg->type = BOMB_VERSION_VECTOR;
  for (i = 0; i < BOMB_CAPSULE_NUM; i++) {
      if (BVirusExtended$capsules[tos_state.current_node][i] != (void *)0 && 
      BVirusExtended$capsules[tos_state.current_node][i]->type & BOMB_OPTION_FORWARD) {
          msg->versions[i] = BVirusExtended$capsules[tos_state.current_node][i]->version;
        }
      else {
          msg->versions[i] = 0;
        }
      dbg_clear(DBG_USR3, "%08x ", msg->versions[i]);
    }
  dbg_clear(DBG_USR3, "\n");
  if (!BVirusExtended$VersionSend$send(TOS_BCAST_ADDR, sizeof(BombillaVersionMsg ), BVirusExtended$sendPtr[tos_state.current_node])) {
      dbg(DBG_USR3 | DBG_ERROR, "BVirus: Version vector send failed\n");
      BVirusExtended$sendBusy[tos_state.current_node] = FALSE;
      return FAIL;
    }
  else {
      return SUCCESS;
    }
}

static inline  void BVirusExtended$versionTimerTask(void)
#line 341
{
  BVirusExtended$versionCounter[tos_state.current_node]++;
  if (BVirusExtended$versionCounter[tos_state.current_node] >= BVirusExtended$tau[tos_state.current_node]) {
      BVirusExtended$tau[tos_state.current_node] *= 2;
      if (BVirusExtended$tau[tos_state.current_node] > BVirusExtended$TAU_MAX) {
          BVirusExtended$tau[tos_state.current_node] = BVirusExtended$TAU_MAX;
        }
      BVirusExtended$newVersionCounter();
    }
  else {
#line 350
    if (BVirusExtended$versionCounter[tos_state.current_node] == BVirusExtended$versionThreshold[tos_state.current_node]) {

        char timeBuf[128];

#line 353
        printTime(timeBuf, 128);
        dbg(DBG_USR3, "BVirus: Version timer counter expired (hrd: %i, thr: %i, cancel: %i): %s\n", (int )BVirusExtended$versionHeard[tos_state.current_node], (int )BVirusExtended$versionThreshold[tos_state.current_node], (int )BVirusExtended$versionCancelled[tos_state.current_node], timeBuf);

        if (!BVirusExtended$versionCancelled[tos_state.current_node]) {
            dbg(DBG_USR3, "BVirus: Sending version packet\n");
            BVirusExtended$sendVersionPacket();
            BVirusExtended$versionCancelled[tos_state.current_node] = 1;
          }
      }
    else {
      }
    }
}

static inline  result_t BVirusExtended$VersionTimer$fired(void)
#line 367
{
  if (BVirusExtended$state[tos_state.current_node] == BVirusExtended$BVIRUS_PULLING) {
      TOS_post(BVirusExtended$versionTimerTask);
    }
  return SUCCESS;
}

# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
inline static  result_t MultiHopGrid$SendMsg$send(uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0){
#line 48
  unsigned char result;
#line 48

#line 48
  result = QueuedSendM$QueueSendMsg$send(AM_MULTIHOPMSG, arg_0x9de8758, arg_0x9de88a0, arg_0x9de89f0);
#line 48

#line 48
  return result;
#line 48
}
#line 48
static inline  
# 451 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopGrid.nc"
void MultiHopGrid$SendRouteTask(void)
#line 451
{
  TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&MultiHopGrid$routeMsg[tos_state.current_node].data[0];
  MultiHopGrid$RoutePacket *pRP = (MultiHopGrid$RoutePacket *)&pMHMsg->data[0];
  uint8_t length = (size_t )& ((TOS_MHopMsg *)0)->data + (size_t )& ((MultiHopGrid$RoutePacket *)0)->estList;
  uint8_t maxEstEntries;
  uint8_t i;
#line 456
  uint8_t j;
  uint8_t last_index_added = 0;

  if (MultiHopGrid$gfSendRouteBusy[tos_state.current_node]) {
      return;
    }

  dbg(DBG_ROUTE, "MultiHopWMEWMA Sending route update msg.\n");
  dbg(DBG_ROUTE, "Current cost: %d.\n", MultiHopGrid$gbCurrentCost[tos_state.current_node]);

  maxEstEntries = 36 - length;
  maxEstEntries = maxEstEntries / sizeof(MultiHopGrid$RPEstEntry );

  pRP->parent = MultiHopGrid$gpCurrentParent[tos_state.current_node] ? MultiHopGrid$gpCurrentParent[tos_state.current_node]->id : MultiHopGrid$ROUTE_INVALID;
  pRP->cost = MultiHopGrid$gbCurrentCost[tos_state.current_node];

  for (i = 0, j = 0; i < MultiHopGrid$ROUTE_TABLE_SIZE && j < maxEstEntries; i++) {
      uint8_t table_index = i + MultiHopGrid$last_entry_sent[tos_state.current_node] + 1;

#line 474
      if (table_index >= MultiHopGrid$ROUTE_TABLE_SIZE) {
#line 474
        table_index -= MultiHopGrid$ROUTE_TABLE_SIZE;
        }
#line 475
      if (MultiHopGrid$NeighborTbl[tos_state.current_node][table_index].flags & MultiHopGrid$NBRFLAG_VALID && MultiHopGrid$NeighborTbl[tos_state.current_node][table_index].receiveEst > 100) {
          pRP->estList[j].id = MultiHopGrid$NeighborTbl[tos_state.current_node][table_index].id;
          pRP->estList[j].receiveEst = MultiHopGrid$NeighborTbl[tos_state.current_node][table_index].receiveEst;
          j++;
          length += sizeof(MultiHopGrid$RPEstEntry );
          last_index_added = table_index;
          dbg(DBG_ROUTE, "Adding %d to route msg.\n", pRP->estList[j].id);
        }
    }
  MultiHopGrid$last_entry_sent[tos_state.current_node] = last_index_added;
  dbg(DBG_ROUTE, "Added total of %d entries to route msg.\n", j);
  pRP->estEntries = j;
  pMHMsg->sourceaddr = pMHMsg->originaddr = TOS_LOCAL_ADDRESS;
  pMHMsg->hopcount = MultiHopGrid$gbCurrentHopCount[tos_state.current_node];
  pMHMsg->seqno = MultiHopGrid$gCurrentSeqNo[tos_state.current_node]++;

  if (MultiHopGrid$SendMsg$send(TOS_BCAST_ADDR, length, &MultiHopGrid$routeMsg[tos_state.current_node]) == SUCCESS) {
      MultiHopGrid$gfSendRouteBusy[tos_state.current_node] = TRUE;
    }
}

static inline  
#line 590
result_t MultiHopGrid$ATimer$fired(void)
#line 590
{
  TOS_post(MultiHopGrid$SendRouteTask);
  return SUCCESS;
}

static inline   
# 75 "/root/src/tinyos-1.x/tos/system/NoLeds.nc"
result_t NoLeds$Leds$greenToggle(void)
#line 75
{
  return SUCCESS;
}

# 106 "/root/src/tinyos-1.x/tos/interfaces/Leds.nc"
inline static   result_t MultiHopGrid$Leds$greenToggle(void){
#line 106
  unsigned char result;
#line 106

#line 106
  result = NoLeds$Leds$greenToggle();
#line 106

#line 106
  return result;
#line 106
}
#line 106
static inline 
# 373 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopGrid.nc"
void MultiHopGrid$chooseParent(void)
#line 373
{
  MultiHopGrid$TableEntry *pNbr;
  uint32_t ulNbrLinkCost = (uint32_t )-1;
  uint32_t ulNbrTotalCost = (uint32_t )-1;
  uint32_t oldParentCost = (uint32_t )-1;
  uint32_t oldParentLinkCost = (uint32_t )-1;
  uint32_t ulMinTotalCost = (uint32_t )-1;
  MultiHopGrid$TableEntry *pNewParent = (void *)0;
  MultiHopGrid$TableEntry *pOldParent = (void *)0;
  uint8_t i;

  if (TOS_LOCAL_ADDRESS == MultiHopGrid$BASE_STATION_ADDRESS) {
#line 384
    return;
    }




  for (i = 0; i < MultiHopGrid$ROUTE_TABLE_SIZE; i++) {
      pNbr = &MultiHopGrid$NeighborTbl[tos_state.current_node][i];

      if (!(pNbr->flags & MultiHopGrid$NBRFLAG_VALID)) {
#line 393
        continue;
        }
#line 394
      if (pNbr->parent == TOS_LOCAL_ADDRESS) {
#line 394
        continue;
        }
#line 395
      if (pNbr->parent == MultiHopGrid$ROUTE_INVALID) {
#line 395
        continue;
        }
#line 396
      if (pNbr->hop == MultiHopGrid$ROUTE_INVALID) {
#line 396
        continue;
        }
#line 397
      if (pNbr->cost == (uint16_t )MultiHopGrid$ROUTE_INVALID) {
#line 397
        continue;
        }
#line 398
      if (pNbr->sendEst < 25 || pNbr->receiveEst < 25) {
#line 398
        continue;
        }
#line 399
      if (pNbr->childLiveliness > 0) {
#line 399
        continue;
        }
      ulNbrLinkCost = MultiHopGrid$evaluateCost(0, pNbr->sendEst, pNbr->receiveEst);
      ulNbrTotalCost = MultiHopGrid$evaluateCost(pNbr->cost, pNbr->sendEst, pNbr->receiveEst);

      MultiHopGrid$Leds$greenToggle();
      if (ulNbrLinkCost > MultiHopGrid$MAX_ALLOWABLE_LINK_COST) {
#line 405
        continue;
        }
#line 406
      dbg(DBG_ROUTE, "MultiHopWMEWMA node: %d, Cost %d, link Cost, %d\n", pNbr->id, ulNbrTotalCost, ulNbrLinkCost);
      if (pNbr == MultiHopGrid$gpCurrentParent[tos_state.current_node]) {
          pOldParent = pNbr;
          oldParentCost = ulNbrTotalCost;
          oldParentLinkCost = ulNbrLinkCost;
          continue;
        }

      if (ulMinTotalCost > ulNbrTotalCost) {
          ulMinTotalCost = ulNbrTotalCost;
          pNewParent = pNbr;
        }
    }



  if (pNewParent == (void *)0) {

      pNewParent = pOldParent;
      ulMinTotalCost = oldParentCost;
    }
  else {
#line 426
    if (pOldParent != (void *)0 && 
    oldParentCost < MultiHopGrid$SWITCH_THRESHOLD + ulMinTotalCost) {

        pNewParent = pOldParent;
        ulMinTotalCost = oldParentCost;
      }
    }
  if (pNewParent) {
      { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 434
        {
          MultiHopGrid$gpCurrentParent[tos_state.current_node] = pNewParent;
          MultiHopGrid$gbCurrentHopCount[tos_state.current_node] = pNewParent->hop + 1;
          MultiHopGrid$gbCurrentCost[tos_state.current_node] = ulMinTotalCost >> 6;
        }
#line 438
        __nesc_atomic_end(__nesc_atomic); }
    }
  else 
#line 439
    {
      { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 440
        {
          MultiHopGrid$gpCurrentParent[tos_state.current_node] = (void *)0;
          MultiHopGrid$gbCurrentHopCount[tos_state.current_node] = MultiHopGrid$ROUTE_INVALID;
          MultiHopGrid$gbCurrentCost[tos_state.current_node] = MultiHopGrid$ROUTE_INVALID;
        }
#line 444
        __nesc_atomic_end(__nesc_atomic); }
    }
}

static inline 
#line 272
void MultiHopGrid$updateEst(MultiHopGrid$TableEntry *Nbr)
#line 272
{
  uint16_t usExpTotal;
#line 273
  uint16_t usActTotal;
#line 273
  uint16_t newAve;

  if (Nbr->flags & MultiHopGrid$NBRFLAG_NEW) {
    return;
    }
  usExpTotal = MultiHopGrid$ESTIMATE_TO_ROUTE_RATIO;



  dbg(DBG_ROUTE, "MultiHopWMEWMA: Updating Nbr %d. ExpTotl = %d, rcvd= %d, missed = %d\n", 
  Nbr->id, usExpTotal, Nbr->received, Nbr->missed);

  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 285
    {
      usActTotal = Nbr->received + Nbr->missed;

      if (usActTotal < usExpTotal) {
          usActTotal = usExpTotal;
        }

      newAve = (uint16_t )255 * (uint16_t )Nbr->received / (uint16_t )usActTotal;
      Nbr->missed = 0;
      Nbr->received = 0;



      if (Nbr->liveliness == 0) {
          Nbr->sendEst >>= 1;
        }
      else 
#line 300
        {
          Nbr->liveliness--;
        }
    }
#line 303
    __nesc_atomic_end(__nesc_atomic); }



  if (Nbr->flags & MultiHopGrid$NBRFLAG_EST_INIT) {
      uint16_t tmp;

#line 309
      tmp = (2 * (uint16_t )Nbr->receiveEst + (uint16_t )newAve * 6) / 8;
      Nbr->receiveEst = (uint8_t )tmp;
    }
  else {
      Nbr->receiveEst = (uint8_t )newAve;
      Nbr->flags ^= MultiHopGrid$NBRFLAG_EST_INIT;
    }

  if (Nbr->childLiveliness > 0) {
#line 317
    Nbr->childLiveliness--;
    }
}

static inline 
#line 320
void MultiHopGrid$updateTable(void)
#line 320
{
  MultiHopGrid$TableEntry *pNbr;
  uint8_t i = 0;

  MultiHopGrid$gwEstTicks[tos_state.current_node]++;
  MultiHopGrid$gwEstTicks[tos_state.current_node] %= MultiHopGrid$ESTIMATE_TO_ROUTE_RATIO;

  for (i = 0; i < MultiHopGrid$ROUTE_TABLE_SIZE; i++) {
      pNbr = &MultiHopGrid$NeighborTbl[tos_state.current_node][i];
      if (pNbr->flags & MultiHopGrid$NBRFLAG_VALID) {
          if (MultiHopGrid$gwEstTicks[tos_state.current_node] == 0) {
            MultiHopGrid$updateEst(pNbr);
            }
        }
    }
}

# 81 "/root/src/tinyos-1.x/tos/interfaces/Leds.nc"
inline static   result_t MultiHopGrid$Leds$redToggle(void){
#line 81
  unsigned char result;
#line 81

#line 81
  result = NoLeds$Leds$redToggle();
#line 81

#line 81
  return result;
#line 81
}
#line 81
static inline  
# 544 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopGrid.nc"
void MultiHopGrid$TimerTask(void)
#line 544
{

  MultiHopGrid$Leds$redToggle();
  dbg(DBG_ROUTE, "MultiHopWMEWMA timer task.\n");
  MultiHopGrid$updateTable();


  {
    int i;

#line 553
    dbg(DBG_ROUTE, "\taddr\tprnt\tcost\tmisd\trcvd\tlstS\thop\trEst\tsEst\tDesc\n");
    for (i = 0; i < MultiHopGrid$ROUTE_TABLE_SIZE; i++) {
        if (MultiHopGrid$NeighborTbl[tos_state.current_node][i].flags) {
            dbg(DBG_ROUTE, "\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", 
            MultiHopGrid$NeighborTbl[tos_state.current_node][i].id, 
            MultiHopGrid$NeighborTbl[tos_state.current_node][i].parent, 
            MultiHopGrid$NeighborTbl[tos_state.current_node][i].cost, 
            MultiHopGrid$NeighborTbl[tos_state.current_node][i].missed, 
            MultiHopGrid$NeighborTbl[tos_state.current_node][i].received, 
            MultiHopGrid$NeighborTbl[tos_state.current_node][i].lastSeqno, 
            MultiHopGrid$NeighborTbl[tos_state.current_node][i].hop, 
            MultiHopGrid$NeighborTbl[tos_state.current_node][i].receiveEst, 
            MultiHopGrid$NeighborTbl[tos_state.current_node][i].sendEst, 
            MultiHopGrid$NeighborTbl[tos_state.current_node][i].childLiveliness);
          }
      }
    if (MultiHopGrid$gpCurrentParent[tos_state.current_node]) {
        dbg(DBG_ROUTE, "MultiHopWMEWMA: Parent = %d\n", MultiHopGrid$gpCurrentParent[tos_state.current_node]->id);
      }
  }

  MultiHopGrid$chooseParent();
}

static inline  
#line 814
result_t MultiHopGrid$Timer$fired(void)
#line 814
{
  TOS_post(MultiHopGrid$TimerTask);
  return SUCCESS;
}

# 154 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
inline static  bool Timer1ContextM$Synch$resumeContext(BombillaContext *arg_0x9df17c0, BombillaContext *arg_0x9df1938){
#line 154
  unsigned char result;
#line 154

#line 154
  result = BContextSynch$Synch$resumeContext(arg_0x9df17c0, arg_0x9df1938);
#line 154

#line 154
  return result;
#line 154
}
#line 154
#line 150
inline static  void Timer1ContextM$Synch$initializeContext(BombillaContext *arg_0x9df0f88){
#line 150
  BContextSynch$Synch$initializeContext(arg_0x9df0f88);
#line 150
}
#line 150
static inline  
# 136 "/root/src/tinyos-1.x/tos/lib/VM/contexts/Timer1ContextM.nc"
void Timer1ContextM$ClockEventTask(void)
#line 136
{
  if (Timer1ContextM$clockContext[tos_state.current_node].state == BOMB_STATE_HALT) {
      Timer1ContextM$Synch$initializeContext(&Timer1ContextM$clockContext[tos_state.current_node]);
      Timer1ContextM$Synch$resumeContext(&Timer1ContextM$clockContext[tos_state.current_node], &Timer1ContextM$clockContext[tos_state.current_node]);
    }
  else {
      dbg(DBG_USR1, "VM: Timer 1 context not halted. Currently in state %i.\n", Timer1ContextM$clockContext[tos_state.current_node].state);
    }
}

static inline  

result_t Timer1ContextM$ClockTimer$fired(void)
#line 148
{
  dbg(DBG_USR1, "VM: Timer 1 timer fired, posting ClockEventTask.\n");
  TOS_post(Timer1ContextM$ClockEventTask);
  return SUCCESS;
}

static inline  
# 139 "/root/src/tinyos-1.x/tos/lib/VM/contexts/OnceContextM.nc"
result_t OnceContextM$Timer$fired(void)
#line 139
{
  return OnceContextM$Virus$capsuleInstalled(& OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule);
}

static inline   
# 156 "/root/src/tinyos-1.x/tos/system/TimerM.nc"
result_t TimerM$Timer$default$fired(uint8_t id)
#line 156
{
  return SUCCESS;
}

# 73 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t TimerM$Timer$fired(uint8_t arg_0x97e2b40){
#line 73
  unsigned char result;
#line 73

#line 73
  switch (arg_0x97e2b40) {
#line 73
    case 0:
#line 73
      result = BombillaEngineM$ErrorTimer$fired();
#line 73
      break;
#line 73
    case 1:
#line 73
      result = AMPromiscuous$ActivityTimer$fired();
#line 73
      break;
#line 73
    case 2:
#line 73
      result = BVirusExtended$VersionTimer$fired();
#line 73
      break;
#line 73
    case 3:
#line 73
      result = BVirusExtended$CapsuleTimer$fired();
#line 73
      break;
#line 73
    case 4:
#line 73
      result = BVirusExtended$BCastTimer$fired();
#line 73
      break;
#line 73
    case 5:
#line 73
      result = MultiHopGrid$Timer$fired();
#line 73
      break;
#line 73
    case 6:
#line 73
      result = MultiHopGrid$ATimer$fired();
#line 73
      break;
#line 73
    case 7:
#line 73
      result = Timer1ContextM$ClockTimer$fired();
#line 73
      break;
#line 73
    case 8:
#line 73
      result = OnceContextM$Timer$fired();
#line 73
      break;
#line 73
    default:
#line 73
      result = TimerM$Timer$default$fired(arg_0x97e2b40);
#line 73
    }
#line 73

#line 73
  return result;
#line 73
}
#line 73
static inline 
# 168 "/root/src/tinyos-1.x/tos/system/TimerM.nc"
uint8_t TimerM$dequeue(void)
#line 168
{
  if (TimerM$queue_size[tos_state.current_node] == 0) {
    return NUM_TIMERS;
    }
#line 171
  if (TimerM$queue_head[tos_state.current_node] == NUM_TIMERS - 1) {
    TimerM$queue_head[tos_state.current_node] = -1;
    }
#line 173
  TimerM$queue_head[tos_state.current_node]++;
  TimerM$queue_size[tos_state.current_node]--;
  return TimerM$queue[tos_state.current_node][(uint8_t )TimerM$queue_head[tos_state.current_node]];
}

static inline  void TimerM$signalOneTimer(void)
#line 178
{
  uint8_t itimer = TimerM$dequeue();

#line 180
  if (itimer < NUM_TIMERS) {
    TimerM$Timer$fired(itimer);
    }
}

static inline 
#line 160
void TimerM$enqueue(uint8_t value)
#line 160
{
  if (TimerM$queue_tail[tos_state.current_node] == NUM_TIMERS - 1) {
    TimerM$queue_tail[tos_state.current_node] = -1;
    }
#line 163
  TimerM$queue_tail[tos_state.current_node]++;
  TimerM$queue_size[tos_state.current_node]++;
  TimerM$queue[tos_state.current_node][(uint8_t )TimerM$queue_tail[tos_state.current_node]] = value;
}

static inline  
#line 184
void TimerM$HandleFire(void)
#line 184
{
  uint8_t i;

#line 186
  TimerM$setIntervalFlag[tos_state.current_node] = 1;
  if (TimerM$mState[tos_state.current_node]) {
      for (i = 0; i < NUM_TIMERS; i++) {
          if (TimerM$mState[tos_state.current_node] & (0x1 << i)) {
              TimerM$mTimerList[tos_state.current_node][i].ticksLeft -= TimerM$mInterval[tos_state.current_node] + 1;
              if (TimerM$mTimerList[tos_state.current_node][i].ticksLeft <= 2) {
                  if (TimerM$mTimerList[tos_state.current_node][i].type == TIMER_REPEAT) {
                      TimerM$mTimerList[tos_state.current_node][i].ticksLeft += TimerM$mTimerList[tos_state.current_node][i].ticks;
                    }
                  else 
#line 194
                    {
                      TimerM$mState[tos_state.current_node] &= ~(0x1 << i);
                    }
                  TimerM$enqueue(i);
                  TOS_post(TimerM$signalOneTimer);
                }
            }
        }
    }
  TimerM$adjustInterval();
}

static inline   result_t TimerM$Clock$fire(void)
#line 206
{
  TOS_post(TimerM$HandleFire);
  return SUCCESS;
}

# 180 "/root/src/tinyos-1.x/tos/interfaces/Clock.nc"
inline static   result_t HPLClock$Clock$fire(void){
#line 180
  unsigned char result;
#line 180

#line 180
  result = TimerM$Clock$fire();
#line 180

#line 180
  return result;
#line 180
}
#line 180
static inline 
# 136 "/root/src/tinyos-1.x/tos/platform/pc/HPLClock.nc"
void  SIG_OUTPUT_COMPARE2_interrupt(void)
#line 136
{
  if (HPLClock$set_flag[tos_state.current_node]) {
      HPLClock$mscale[tos_state.current_node] = HPLClock$nextScale[tos_state.current_node];
      HPLClock$nextScale[tos_state.current_node] |= 0x8;
      TOSH_clock_set_rate(HPLClock$minterval[tos_state.current_node], HPLClock$nextScale[tos_state.current_node]);
      HPLClock$set_flag[tos_state.current_node] = 0;
    }
  HPLClock$Clock$fire();
}

# 79 "/root/src/tinyos-1.x/tos/types/dbg.h"
static bool dbg_active(TOS_dbg_mode mode)
{
  return (dbg_modes & mode) != 0;
}

static inline 
# 118 "/root/src/tinyos-1.x/tos/platform/pc/hpl.c"
void event_clocktick_handle(event_t *event, 
struct TOS_state *state)
#line 119
{

  event_queue_t *queue = & state->queue;
  clock_tick_data_t *data = (clock_tick_data_t *)event->data;

#line 123
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 123
    TOS_LOCAL_ADDRESS = (short )(event->mote & 0xffff);
#line 123
    __nesc_atomic_end(__nesc_atomic); }

  if (TOS_LOCAL_ADDRESS != event->mote) {
      dbg(DBG_ERROR, "ERROR in clock tick event handler! Things are probably ver bad....\n");
    }

  if (data->valid) {
      if (dbg_active(DBG_CLOCK)) {
          char buf[1024];

#line 132
          printTime(buf, 1024);
          dbg(DBG_CLOCK, "CLOCK: event handled for mote %i at %s with interval of %i.\n", event->mote, buf, data->interval);
        }

      event->time = event->time + data->interval;
      queue_insert_event(queue, event);
      if (! data->disabled) {
          SIG_OUTPUT_COMPARE2_interrupt();
        }
      else {
          interruptPending[tos_state.current_node] = 1;
        }
    }
  else {
      dbg(DBG_CLOCK, "CLOCK: invalid event discarded.\n");

      event_cleanup(event);
    }
}

static inline void event_clocktick_create(event_t *event, int mote, long long eventTime, int interval)
#line 152
{


  clock_tick_data_t *data = malloc(sizeof(clock_tick_data_t ));

#line 156
  dbg(DBG_MEM, "malloc data entry for clock event: 0x%x\n", (int )data);
  data->interval = interval;
  data->mote = mote;
  data->valid = 1;
  data->disabled = 0;

  event->mote = mote;
  event->force = 0;
  event->pause = 1;
  event->data = data;
  event->time = eventTime + interval;
  event->handle = event_clocktick_handle;
  event->cleanup = event_total_cleanup;
}

static inline 
# 120 "/root/src/tinyos-1.x/tos/platform/pc/heap_array.c"
void expand_heap(heap_t *heap)
#line 120
{
  int new_size = heap->private_size * 2 + 1;
  void *new_data = malloc(sizeof(node_t ) * new_size);

  dbg(DBG_SIM, "Resized heap from %i to %i.\n", heap->private_size, new_size);

  memcpy(new_data, heap->data, sizeof(node_t ) * heap->private_size);
  free(heap->data);

  heap->data = new_data;
  heap->private_size = new_size;
}

static inline 
void heap_insert(heap_t *heap, void *data, long long key)
#line 134
{
  int findex = heap->size;

#line 136
  if (findex == heap->private_size) {
      expand_heap(heap);
    }

  findex = heap->size;
  ((node_t *)heap->data)[findex].key = key;
  ((node_t *)heap->data)[findex].data = data;
  up_heap(heap, findex);

  heap->size++;
}

# 150 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
inline static  void OnceContextM$Synch$initializeContext(BombillaContext *arg_0x9df0f88){
#line 150
  BContextSynch$Synch$initializeContext(arg_0x9df0f88);
#line 150
}
#line 150
static inline   
# 90 "/root/src/tinyos-1.x/tos/lib/VM/components/BStacks.nc"
result_t BStacks$default$resetStack(BombillaContext *context)
#line 90
{
  return SUCCESS;
}

#line 79
inline static  result_t BStacks$resetStack(BombillaContext *arg_0xa010010){
#line 79
  unsigned char result;
#line 79

#line 79
  result = BStacks$default$resetStack(arg_0xa010010);
#line 79

#line 79
  return result;
#line 79
}
#line 79
static inline  





result_t BStacks$Stacks$resetStacks(BombillaContext *context)
#line 85
{
  context->opStack.sp = 0;
  return BStacks$resetStack(context);
}

# 90 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t BContextSynch$Stacks$resetStacks(BombillaContext *arg_0x9f8f860){
#line 90
  unsigned char result;
#line 90

#line 90
  result = BStacks$Stacks$resetStacks(arg_0x9f8f860);
#line 90

#line 90
  return result;
#line 90
}
#line 90
static inline  
# 178 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetvar4M.nc"
int16_t OPgetsetvar4M$BombillaBytecodeLock$lockNum(uint8_t instr)
#line 178
{
  uint8_t arg = instr & 0xf;

#line 180
  dbg(DBG_USR2, "OPgetsetvar4M: lockNum called with rval of %i\n", (int )arg);
  return OPgetsetvar4M$varToLock(arg);
}

static inline  
# 125 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbpush1M.nc"
int16_t OPbpush1M$BombillaBytecodeLock$lockNum(uint8_t instr)
#line 125
{
  if (instr & 1) {
      return OPbpush1M$BOMB_BUF_LOCK_1_1;
    }
  else {
      return OPbpush1M$BOMB_BUF_LOCK_1_0;
    }
}

static inline   
# 298 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
int16_t BContextSynch$CodeLocks$default$lockNum(uint8_t ival, uint8_t instr)
#line 298
{
  return -1;
}

# 87 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBytecodeLock.nc"
inline static  int16_t BContextSynch$CodeLocks$lockNum(uint8_t arg_0x9fb4bd8, uint8_t arg_0x9f97678){
#line 87
  short result;
#line 87

#line 87
  switch (arg_0x9fb4bd8) {
#line 87
    case OPbpush1 + 0:
#line 87
      result = OPbpush1M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPbpush1 + 1:
#line 87
      result = OPbpush1M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 0:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 1:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 2:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 3:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 4:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 5:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 6:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 7:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 8:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 9:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 10:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 11:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 12:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 13:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 14:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPgetvar4 + 15:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 0:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 1:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 2:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 3:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 4:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 5:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 6:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 7:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 8:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 9:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 10:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 11:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 12:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 13:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 14:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    case OPsetvar4 + 15:
#line 87
      result = OPgetsetvar4M$BombillaBytecodeLock$lockNum(arg_0x9f97678);
#line 87
      break;
#line 87
    default:
#line 87
      result = BContextSynch$CodeLocks$default$lockNum(arg_0x9fb4bd8, arg_0x9f97678);
#line 87
    }
#line 87

#line 87
  return result;
#line 87
}
#line 87
static inline  
# 177 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OProuteM.nc"
void OProuteM$Comm$reboot(void)
#line 177
{
}

# 101 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextComm.nc"
inline static  void OnceContextM$Comm$reboot(void){
#line 101
  BombillaEngineM$Comm$reboot(1);
#line 101
  OProuteM$Comm$reboot();
#line 101
}
#line 101
static inline  
# 84 "/root/src/tinyos-1.x/tos/lib/VM/components/BLocks.nc"
void BLocks$Locks$reboot(void)
#line 84
{
  int i;

#line 86
  for (i = 0; i < BOMB_HEAPSIZE; i++) {
      BLocks$locks[tos_state.current_node][i].holder = (void *)0;
    }
}

# 139 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaLocks.nc"
inline static  void BContextSynch$Locks$reboot(void){
#line 139
  BLocks$Locks$reboot();
#line 139
}
#line 139
static inline 
# 115 "/root/src/tinyos-1.x/tos/lib/VM/components/BQueue.nc"
void BQueue$list_init(list_t *list)
#line 115
{
  dbg(DBG_BOOT, "QUEUE: Initializing queue at 0x%x.\n", list);
  list->l_next = list->l_prev = list;
}

static inline  



result_t BQueue$Queue$init(BombillaQueue *queue)
#line 124
{
  BQueue$list_init(& queue->queue);
  return SUCCESS;
}

# 89 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaQueue.nc"
inline static  result_t BContextSynch$Queue$init(BombillaQueue *arg_0x9defdb8){
#line 89
  unsigned char result;
#line 89

#line 89
  result = BQueue$Queue$init(arg_0x9defdb8);
#line 89

#line 89
  return result;
#line 89
}
#line 89
static inline  
# 108 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
void BContextSynch$Synch$reboot(void)
#line 108
{
  BContextSynch$Queue$init(&BContextSynch$readyQueue[tos_state.current_node]);
  BContextSynch$Locks$reboot();
}

# 161 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
inline static  void BombillaEngineM$Synch$reboot(void){
#line 161
  BContextSynch$Synch$reboot();
#line 161
}
#line 161
# 80 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaAnalysis.nc"
inline static  void BombillaEngineM$Analysis$analyzeCapsuleVars(BombillaCapsuleBuffer *arg_0x9dd1c28){
#line 80
  BContextSynch$Analysis$analyzeCapsuleVars(arg_0x9dd1c28);
#line 80
}
#line 80
static inline 
# 202 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
void BContextSynch$capsuleCallsDeep(BombillaCapsuleBuffer *capsules[], int which)
#line 202
{
  int i;
  BombillaCapsuleBuffer *buf = capsules[which];

#line 205
  if (buf->haveSeen) {
      return;
    }
  buf->haveSeen = 1;
  for (i = 0; i < BOMB_PGMSIZE; i++) {
    }




  return;
}

static inline  void BContextSynch$Analysis$analyzeCapsuleCalls(BombillaCapsuleBuffer *capsules[])
#line 218
{
  int i;
  int numCapsules = 3;

  for (i = 0; i < numCapsules; i++) {
      if (capsules[i] != (void *)0) {
          BContextSynch$capsuleCallsDeep(capsules, i);
        }
    }
}

# 81 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaAnalysis.nc"
inline static  void BombillaEngineM$Analysis$analyzeCapsuleCalls(BombillaCapsuleBuffer *arg_0x9dea098[]){
#line 81
  BContextSynch$Analysis$analyzeCapsuleCalls(arg_0x9dea098);
#line 81
}
#line 81
# 154 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
inline static  bool OnceContextM$Synch$resumeContext(BombillaContext *arg_0x9df17c0, BombillaContext *arg_0x9df1938){
#line 154
  unsigned char result;
#line 154

#line 154
  result = BContextSynch$Synch$resumeContext(arg_0x9df17c0, arg_0x9df1938);
#line 154

#line 154
  return result;
#line 154
}
#line 154
static inline  
# 105 "/root/src/tinyos-1.x/tos/lib/VM/components/BLocks.nc"
bool BLocks$Locks$isLocked(uint8_t lockNum)
#line 105
{
  return BLocks$locks[tos_state.current_node][lockNum].holder != 0;
}

# 123 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaLocks.nc"
inline static  bool BContextSynch$Locks$isLocked(uint8_t arg_0x9fbecc8){
#line 123
  unsigned char result;
#line 123

#line 123
  result = BLocks$Locks$isLocked(arg_0x9fbecc8);
#line 123

#line 123
  return result;
#line 123
}
#line 123
static inline  
# 113 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
bool BContextSynch$Synch$isRunnable(BombillaContext *context)
#line 113
{
  int8_t i;
  uint8_t *neededLocks = context->acquireSet;

#line 116
  dbg(DBG_USR2, "VM: Checking whether context %i runnable: ", (int )context->which);

  for (i = 0; i < BOMB_HEAPSIZE; i++) {
      dbg_clear(DBG_USR2, "%i,", (int )i);
      if (neededLocks[i / 8] & (1 << i % 8)) {
          if (BContextSynch$Locks$isLocked(i)) {
              dbg_clear(DBG_USR2, " - no\n");
              return FALSE;
            }
        }
    }
  dbg_clear(DBG_USR2, " - yes\n");
  return TRUE;
}

static inline  
# 91 "/root/src/tinyos-1.x/tos/lib/VM/components/BLocks.nc"
result_t BLocks$Locks$lock(BombillaContext *context, uint8_t lockNum)
#line 91
{
  BLocks$locks[tos_state.current_node][lockNum].holder = context;
  context->heldSet[lockNum / 8] |= 1 << lockNum % 8;
  dbg(DBG_USR2, "VM: Context %i locking lock %i\n", (int )context->which, (int )lockNum);
  return SUCCESS;
}

# 95 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaLocks.nc"
inline static  result_t BContextSynch$Locks$lock(BombillaContext *arg_0x9f93f00, uint8_t arg_0x9fbe060){
#line 95
  unsigned char result;
#line 95

#line 95
  result = BLocks$Locks$lock(arg_0x9f93f00, arg_0x9fbe060);
#line 95

#line 95
  return result;
#line 95
}
#line 95
static inline  
# 131 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
result_t BContextSynch$Synch$obtainLocks(BombillaContext *caller, 
BombillaContext *obtainer)
#line 132
{
  int8_t i;
  uint8_t *neededLocks = obtainer->acquireSet;

#line 135
  dbg(DBG_USR2, "VM: Attempting to obtain necessary locks for context %i: ", obtainer->which);
  for (i = 0; i < BOMB_HEAPSIZE; i++) {
      dbg_clear(DBG_USR2, "%i", (int )i);
      if (neededLocks[i / 8] & (1 << i % 8)) {
          dbg_clear(DBG_USR2, "+");
          BContextSynch$Locks$lock(obtainer, i);
        }
      dbg_clear(DBG_USR2, ",");
    }
  for (i = 0; i < (BOMB_HEAPSIZE + 7) / 8; i++) {
      obtainer->acquireSet[i] = 0;
    }
  dbg_clear(DBG_USR2, "\n");
  return SUCCESS;
}

# 115 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaQueue.nc"
inline static  result_t BombillaEngineM$Queue$enqueue(BombillaContext *arg_0x9dcc7c8, BombillaQueue *arg_0x9dcc940, BombillaContext *arg_0x9dccab8){
#line 115
  unsigned char result;
#line 115

#line 115
  result = BQueue$Queue$enqueue(arg_0x9dcc7c8, arg_0x9dcc940, arg_0x9dccab8);
#line 115

#line 115
  return result;
#line 115
}
#line 115
static inline 
# 170 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
result_t BombillaEngineM$executeContext(BombillaContext *context)
#line 170
{
  if (context->state != BOMB_STATE_RUN) {
#line 171
      return FAIL;
    }
#line 172
  BombillaEngineM$Queue$enqueue(context, &BombillaEngineM$runQueue[tos_state.current_node], context);
  TOS_post(BombillaEngineM$RunTask);
  return SUCCESS;
}

static inline  
#line 216
result_t BombillaEngineM$Synch$makeRunnable(BombillaContext *context)
#line 216
{
  context->state = BOMB_STATE_RUN;
  return BombillaEngineM$executeContext(context);
}

static inline  
# 97 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPhaltM.nc"
result_t OPhaltM$Synch$makeRunnable(BombillaContext *context)
#line 97
{
  return SUCCESS;
}

static inline  
# 185 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPuartM.nc"
result_t OPuartM$Synch$makeRunnable(BombillaContext *context)
#line 185
{
  return SUCCESS;
}

static inline  
# 178 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OProuteM.nc"
result_t OProuteM$Synch$makeRunnable(BombillaContext *context)
#line 178
{
  return SUCCESS;
}

static inline  
# 154 "/root/src/tinyos-1.x/tos/lib/VM/contexts/Timer1ContextM.nc"
result_t Timer1ContextM$Synch$makeRunnable(BombillaContext *context)
#line 154
{
  return SUCCESS;
}

static inline  
# 158 "/root/src/tinyos-1.x/tos/lib/VM/contexts/OnceContextM.nc"
result_t OnceContextM$Synch$makeRunnable(BombillaContext *context)
#line 158
{
  return SUCCESS;
}

# 159 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
inline static  result_t BContextSynch$Synch$makeRunnable(BombillaContext *arg_0x9dee198){
#line 159
  unsigned char result;
#line 159

#line 159
  result = OnceContextM$Synch$makeRunnable(arg_0x9dee198);
#line 159
  result = rcombine(result, Timer1ContextM$Synch$makeRunnable(arg_0x9dee198));
#line 159
  result = rcombine(result, OProuteM$Synch$makeRunnable(arg_0x9dee198));
#line 159
  result = rcombine(result, OPuartM$Synch$makeRunnable(arg_0x9dee198));
#line 159
  result = rcombine(result, OPhaltM$Synch$makeRunnable(arg_0x9dee198));
#line 159
  result = rcombine(result, BombillaEngineM$Synch$makeRunnable(arg_0x9dee198));
#line 159

#line 159
  return result;
#line 159
}
#line 159
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
inline static  result_t BQueue$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840){
#line 94
  unsigned char result;
#line 94

#line 94
  result = BombillaEngineM$Error$error(arg_0x9db46f8, arg_0x9db4840);
#line 94

#line 94
  return result;
#line 94
}
#line 94
static inline 
# 83 "/root/src/tinyos-1.x/tos/lib/VM/components/BQueue.nc"
void BQueue$list_insert_before(list_link_t *before, list_link_t *new)
#line 83
{
  new->l_next = before;
  new->l_prev = before->l_prev;
  before->l_prev->l_next = new;
  before->l_prev = new;
}

static inline void BQueue$list_insert_head(list_t *list, list_link_t *element)
#line 90
{
  BQueue$list_insert_before(list->l_next, element);
}

# 129 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaQueue.nc"
inline static  BombillaContext *BombillaEngineM$Queue$dequeue(BombillaContext *arg_0x9dcd0a0, BombillaQueue *arg_0x9dcd218){
#line 129
  struct __nesc_unnamed4356 *result;
#line 129

#line 129
  result = BQueue$Queue$dequeue(arg_0x9dcd0a0, arg_0x9dcd218);
#line 129

#line 129
  return result;
#line 129
}
#line 129
static inline 
# 120 "/root/src/tinyos-1.x/tos/lib/VM/components/BQueue.nc"
bool BQueue$list_empty(list_t *list)
#line 120
{
  return list->l_next == list ? TRUE : FALSE;
}

static inline 
#line 98
void BQueue$list_remove(list_link_t *ll)
#line 98
{
  list_link_t *before = ll->l_prev;
  list_link_t *after = ll->l_next;

#line 101
  before->l_next = after;
  after->l_prev = before;
  ll->l_next = 0;
  ll->l_prev = 0;
}

# 152 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
inline static  void OProuteM$Synch$yieldContext(BombillaContext *arg_0x9df13a0){
#line 152
  BContextSynch$Synch$yieldContext(arg_0x9df13a0);
#line 152
}
#line 152
#line 129
inline static  result_t OProuteM$Synch$releaseLocks(BombillaContext *arg_0x9df0010, BombillaContext *arg_0x9df0190){
#line 129
  unsigned char result;
#line 129

#line 129
  result = BContextSynch$Synch$releaseLocks(arg_0x9df0010, arg_0x9df0190);
#line 129

#line 129
  return result;
#line 129
}
#line 129
# 83 "/root/src/tinyos-1.x/tos/interfaces/Send.nc"
inline static  result_t OProuteM$Send$send(TOS_MsgPtr arg_0xbf48aae0, uint16_t arg_0xbf48ac30){
#line 83
  unsigned char result;
#line 83

#line 83
  result = MultiHopEngineGridM$Send$send(66, arg_0xbf48aae0, arg_0xbf48ac30);
#line 83

#line 83
  return result;
#line 83
}
#line 83
# 106 "/root/src/tinyos-1.x/tos/interfaces/Send.nc"
inline static  void *OProuteM$Send$getBuffer(TOS_MsgPtr arg_0xbf48b268, uint16_t *arg_0xbf48b3d0){
#line 106
  void *result;
#line 106

#line 106
  result = MultiHopEngineGridM$Send$getBuffer(66, arg_0xbf48b268, arg_0xbf48b3d0);
#line 106

#line 106
  return result;
#line 106
}
#line 106
static inline  
# 914 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopGrid.nc"
result_t MultiHopGrid$fillInAddr(uint16_t addr, TOS_MsgPtr msg)
#line 914
{
  TOS_MHopMsg *mhmsg = (TOS_MHopMsg *)msg->data;

#line 916
  dbg(DBG_ROUTE, "MultiHopGrid: Filling in addr of 0x%x to 0x%hx\n", msg, addr);
  mhmsg->originaddr = addr;
  return SUCCESS;
}

# 94 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OProuteM.nc"
inline static  result_t OProuteM$fillInAddr(uint16_t arg_0xbf3e6df0, TOS_MsgPtr arg_0xbf3e6f40){
#line 94
  unsigned char result;
#line 94

#line 94
  result = MultiHopGrid$fillInAddr(arg_0xbf3e6df0, arg_0xbf3e6f40);
#line 94

#line 94
  return result;
#line 94
}
#line 94
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OProuteM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OProuteM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 104 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OProuteM.nc"
result_t OProuteM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 105
{
  uint16_t len;
  BombillaCapsule *msgCapsule;
  BombillaStackVariable *arg = OProuteM$Stacks$popOperand(context);

  {
    char timeVal[128];

#line 112
    printTime(timeVal, 128);
    dbg(DBG_USR1 | DBG_USR3, "VM (%i): Routing capsule @%s.\n", (int )context->which, timeVal);
  }

  if (!OProuteM$Types$checkTypes(context, arg, BOMB_VAR_V)) {
#line 116
      return FAIL;
    }
#line 117
  if (arg->value.var == TOS_LOCAL_ADDRESS) {
#line 117
      return SUCCESS;
    }
#line 118
  OProuteM$fillInAddr(arg->value.var, &OProuteM$msg[tos_state.current_node]);
  msgCapsule = (BombillaCapsule *)OProuteM$Send$getBuffer(&OProuteM$msg[tos_state.current_node], &len);
  nmemcpy(msgCapsule, & OProuteM$onceCapsule[tos_state.current_node]->capsule, len);

  if (OProuteM$Send$send(&OProuteM$msg[tos_state.current_node], len)) {
      dbg(DBG_USR1 | DBG_TEMP, "VM (%i): Routing capsule to %i succeeded.\n", (int )context->which, (int )arg->value.var);
      context->state = BOMB_STATE_SENDING;
      OProuteM$sendingContext[tos_state.current_node] = context;
      OProuteM$Synch$releaseLocks(context, context);
      OProuteM$Synch$yieldContext(context);
    }
  else {
      context->state = BOMB_STATE_SEND_WAIT;
      OProuteM$sendingContext[tos_state.current_node] = context;
      OProuteM$Synch$releaseLocks(context, context);
      OProuteM$Synch$yieldContext(context);
    }
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPrandM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 63 "/root/src/tinyos-1.x/tos/interfaces/Random.nc"
inline static   uint16_t OPrandM$Random$rand(void){
#line 63
  unsigned short result;
#line 63

#line 63
  result = RandomLFSR$Random$rand();
#line 63

#line 63
  return result;
#line 63
}
#line 63
static inline  
# 105 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPrandM.nc"
result_t OPrandM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 106
{
  uint16_t rval = OPrandM$Random$rand();

#line 108
  dbg(DBG_USR1, "VM (%i): Pushing random number: %hu.\n", (int )context->which, rval);
  OPrandM$Stacks$pushValue(context, rval);
  return SUCCESS;
}

# 152 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
inline static  void OPuartM$Synch$yieldContext(BombillaContext *arg_0x9df13a0){
#line 152
  BContextSynch$Synch$yieldContext(arg_0x9df13a0);
#line 152
}
#line 152
#line 129
inline static  result_t OPuartM$Synch$releaseLocks(BombillaContext *arg_0x9df0010, BombillaContext *arg_0x9df0190){
#line 129
  unsigned char result;
#line 129

#line 129
  result = BContextSynch$Synch$releaseLocks(arg_0x9df0010, arg_0x9df0190);
#line 129

#line 129
  return result;
#line 129
}
#line 129
# 115 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaQueue.nc"
inline static  result_t OPuartM$Queue$enqueue(BombillaContext *arg_0x9dcc7c8, BombillaQueue *arg_0x9dcc940, BombillaContext *arg_0x9dccab8){
#line 115
  unsigned char result;
#line 115

#line 115
  result = BQueue$Queue$enqueue(arg_0x9dcc7c8, arg_0x9dcc940, arg_0x9dccab8);
#line 115

#line 115
  return result;
#line 115
}
#line 115
# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPuartM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500){
#line 147
  unsigned char result;
#line 147

#line 147
  result = BStacks$Stacks$pushOperand(arg_0x9fb7390, arg_0x9fb7500);
#line 147

#line 147
  return result;
#line 147
}
#line 147
# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
inline static  result_t OPuartM$SendPacket$send(uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0){
#line 48
  unsigned char result;
#line 48

#line 48
  result = AMPromiscuous$SendMsg$send(AM_BOMBILLAPACKETMSG, arg_0x9de8758, arg_0x9de88a0, arg_0x9de89f0);
#line 48

#line 48
  return result;
#line 48
}
#line 48
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPuartM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPuartM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 119 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPuartM.nc"
result_t OPuartM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 120
{
  BombillaStackVariable *arg = OPuartM$Stacks$popOperand(context);

#line 122
  if (!OPuartM$Types$checkTypes(context, arg, BOMB_VAR_B)) {
#line 122
      return FAIL;
    }
  else 
#line 123
    {
      int i;
      BombillaDataBuffer *buffer = arg->buffer.var;
      uint8_t len = buffer->size * sizeof buffer->entries[0];

#line 127
      len += sizeof  buffer->type + sizeof  buffer->size;

      for (i = 0; i < len; i++) {
          OPuartM$msg[tos_state.current_node].data[i] = ((uint8_t *)buffer)[i];
        }

      if (OPuartM$SendPacket$send(TOS_UART_ADDR, len, &OPuartM$msg[tos_state.current_node])) {
          dbg(DBG_USR1, "VM (%i): Sending packet to UART.\n", (int )context->which);
          context->state = BOMB_STATE_SENDING;
          OPuartM$sendingContext[tos_state.current_node] = context;
        }
      else 
        {
          dbg(DBG_USR1, "VM (%i): UART send request refused. Enqueue and wait.\n", (int )context->which);


          context->pc--;
          OPuartM$Stacks$pushOperand(context, arg);
          OPuartM$Queue$enqueue(context, &OPuartM$sendWaitQueue[tos_state.current_node], context);
          context->state = BOMB_STATE_SEND_WAIT;
        }
      OPuartM$Synch$releaseLocks(context, context);
      OPuartM$Synch$yieldContext(context);
    }
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPidM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPidM.nc"
result_t OPidM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  dbg(DBG_USR1, "VM (%i): Pushing local address: %i.\n", (int )context->which, (int )TOS_LOCAL_ADDRESS);
  OPidM$Stacks$pushValue(context, TOS_LOCAL_ADDRESS);
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPcastM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPcastM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPcastM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPcastM.nc"
result_t OPcastM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg = OPcastM$Stacks$popOperand(context);

#line 92
  dbg(DBG_USR1, "VM (%i): Casting.\n", (int )context->which);
  if (!OPcastM$Types$checkTypes(context, arg, BOMB_VAR_S)) {
#line 93
      return FAIL;
    }
#line 94
  OPcastM$Stacks$pushValue(context, arg->sense.var);
  return SUCCESS;
}

# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPbclearM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500){
#line 147
  unsigned char result;
#line 147

#line 147
  result = BStacks$Stacks$pushOperand(arg_0x9fb7390, arg_0x9fb7500);
#line 147

#line 147
  return result;
#line 147
}
#line 147
static inline  
# 83 "/root/src/tinyos-1.x/tos/lib/VM/components/BBuffer.nc"
result_t BBuffer$Buffer$clear(BombillaContext *context, 
BombillaDataBuffer *buffer)
#line 84
{
  int i;

#line 86
  buffer->size = 0;
  buffer->type = BOMB_DATA_NONE;
  for (i = 0; i < BOMB_BUF_LEN; i++) {
      buffer->entries[i] = 0;
    }
  return SUCCESS;
}

# 91 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBuffer.nc"
inline static  result_t OPbclearM$Buffer$clear(BombillaContext *arg_0xa024b98, BombillaDataBuffer *arg_0xa024d08){
#line 91
  unsigned char result;
#line 91

#line 91
  result = BBuffer$Buffer$clear(arg_0xa024b98, arg_0xa024d08);
#line 91

#line 91
  return result;
#line 91
}
#line 91
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPbclearM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPbclearM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbclearM.nc"
result_t OPbclearM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 91
{
  BombillaStackVariable *arg = OPbclearM$Stacks$popOperand(context);

#line 93
  dbg(DBG_USR1, "VM (%i): Clearing buffer. \n", context->which);

  if (!OPbclearM$Types$checkTypes(context, arg, BOMB_VAR_B)) {
#line 95
      return FAIL;
    }
  else 
#line 96
    {
      OPbclearM$Buffer$clear(context, arg->buffer.var);
      OPbclearM$Stacks$pushOperand(context, arg);
      return SUCCESS;
    }
}

# 131 "/root/src/tinyos-1.x/tos/interfaces/Leds.nc"
inline static   result_t OPputledM$Leds$yellowToggle(void){
#line 131
  unsigned char result;
#line 131

#line 131
  result = LedsC$Leds$yellowToggle();
#line 131

#line 131
  return result;
#line 131
}
#line 131
#line 106
inline static   result_t OPputledM$Leds$greenToggle(void){
#line 106
  unsigned char result;
#line 106

#line 106
  result = LedsC$Leds$greenToggle();
#line 106

#line 106
  return result;
#line 106
}
#line 106
#line 81
inline static   result_t OPputledM$Leds$redToggle(void){
#line 81
  unsigned char result;
#line 81

#line 81
  result = LedsC$Leds$redToggle();
#line 81

#line 81
  return result;
#line 81
}
#line 81
#line 114
inline static   result_t OPputledM$Leds$yellowOn(void){
#line 114
  unsigned char result;
#line 114

#line 114
  result = LedsC$Leds$yellowOn();
#line 114

#line 114
  return result;
#line 114
}
#line 114
#line 89
inline static   result_t OPputledM$Leds$greenOn(void){
#line 89
  unsigned char result;
#line 89

#line 89
  result = LedsC$Leds$greenOn();
#line 89

#line 89
  return result;
#line 89
}
#line 89
#line 64
inline static   result_t OPputledM$Leds$redOn(void){
#line 64
  unsigned char result;
#line 64

#line 64
  result = LedsC$Leds$redOn();
#line 64

#line 64
  return result;
#line 64
}
#line 64
#line 122
inline static   result_t OPputledM$Leds$yellowOff(void){
#line 122
  unsigned char result;
#line 122

#line 122
  result = LedsC$Leds$yellowOff();
#line 122

#line 122
  return result;
#line 122
}
#line 122
#line 97
inline static   result_t OPputledM$Leds$greenOff(void){
#line 97
  unsigned char result;
#line 97

#line 97
  result = LedsC$Leds$greenOff();
#line 97

#line 97
  return result;
#line 97
}
#line 97
#line 72
inline static   result_t OPputledM$Leds$redOff(void){
#line 72
  unsigned char result;
#line 72

#line 72
  result = LedsC$Leds$redOff();
#line 72

#line 72
  return result;
#line 72
}
#line 72
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPputledM$BombillaTypes$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPputledM$BombillaStacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPputledM.nc"
result_t OPputledM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 91
{
  uint16_t val;
  BombillaStackVariable *arg = OPputledM$BombillaStacks$popOperand(context);

#line 94
  if (!OPputledM$BombillaTypes$checkTypes(context, arg, BOMB_VAR_V)) {
      return FAIL;
    }
  else {
      uint8_t op;
      uint8_t led;

      val = arg->value.var;
      op = (val >> 3) & 3;
      led = val & 7;
      dbg(DBG_USR1, "VM (%i): Executing OPputledM with op %i and led %i.\n", (int )context->which, (int )op, (int )led);

      switch (op) {
          case 0: 
            if (led & 1) {
#line 108
              OPputledM$Leds$redOn();
              }
            else {
#line 109
              OPputledM$Leds$redOff();
              }
#line 110
          if (led & 2) {
#line 110
            OPputledM$Leds$greenOn();
            }
          else {
#line 111
            OPputledM$Leds$greenOff();
            }
#line 112
          if (led & 4) {
#line 112
            OPputledM$Leds$yellowOn();
            }
          else {
#line 113
            OPputledM$Leds$yellowOff();
            }
#line 114
          break;
          case 1: 
            if (!(led & 1)) {
#line 116
              OPputledM$Leds$redOff();
              }
#line 117
          if (!(led & 2)) {
#line 117
            OPputledM$Leds$greenOff();
            }
#line 118
          if (!(led & 4)) {
#line 118
            OPputledM$Leds$yellowOff();
            }
#line 119
          break;
          case 2: 
            if (led & 1) {
#line 121
              OPputledM$Leds$redOn();
              }
#line 122
          if (led & 2) {
#line 122
            OPputledM$Leds$greenOn();
            }
#line 123
          if (led & 4) {
#line 123
            OPputledM$Leds$yellowOn();
            }
#line 124
          break;
          case 3: 
            if (led & 1) {
#line 126
              OPputledM$Leds$redToggle();
              }
#line 127
          if (led & 2) {
#line 127
            OPputledM$Leds$greenToggle();
            }
#line 128
          if (led & 4) {
#line 128
            OPputledM$Leds$yellowToggle();
            }
#line 129
          break;
          default: 
            dbg(DBG_ERROR, "VM: LED command had unknown operations.\n");
          return FAIL;
        }
    }
  return SUCCESS;
}

# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPinvM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500){
#line 147
  unsigned char result;
#line 147

#line 147
  result = BStacks$Stacks$pushOperand(arg_0x9fb7390, arg_0x9fb7500);
#line 147

#line 147
  return result;
#line 147
}
#line 147
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPinvM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPinvM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPinvM.nc"
result_t OPinvM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg = OPinvM$Stacks$popOperand(context);

#line 92
  dbg(DBG_USR1, "VM (%i): Inverting top of stack.\n", (int )context->which);
  if (!OPinvM$Types$checkTypes(context, arg, BOMB_VAR_V)) {
#line 93
      return FAIL;
    }
#line 94
  arg->value.var = - arg->value.var;
  OPinvM$Stacks$pushOperand(context, arg);
  return SUCCESS;
}

# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPcopyM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500){
#line 147
  unsigned char result;
#line 147

#line 147
  result = BStacks$Stacks$pushOperand(arg_0x9fb7390, arg_0x9fb7500);
#line 147

#line 147
  return result;
#line 147
}
#line 147
#line 158
inline static  BombillaStackVariable *OPcopyM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 88 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPcopyM.nc"
result_t OPcopyM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 89
{
  BombillaStackVariable *arg = OPcopyM$Stacks$popOperand(context);

#line 91
  dbg(DBG_USR1, "VM (%i): Copying top of stack.\n", (int )context->which);
  OPcopyM$Stacks$pushOperand(context, arg);
  OPcopyM$Stacks$pushOperand(context, arg);
  return SUCCESS;
}

static inline 
# 87 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPneqM.nc"
bool OPneqM$areEqual(BombillaStackVariable *arg1, BombillaStackVariable *arg2)
#line 87
{
  if (arg1->type != arg2->type) {
#line 88
      return FALSE;
    }
#line 89
  if (arg1->type == BOMB_TYPE_SENSE) {
      return arg1->sense.type == arg2->sense.type && 
      arg1->sense.var == arg2->sense.var;
    }
  else {
#line 93
    if (arg1->type == BOMB_TYPE_VALUE) {
        return arg1->value.var == arg2->value.var;
      }
    else {
#line 96
      if (arg1->type == BOMB_TYPE_BUFFER) {
          return arg1->buffer.var == arg2->buffer.var;
        }
      else {
          return FALSE;
        }
      }
    }
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPneqM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
#line 158
inline static  BombillaStackVariable *OPneqM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 104 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPneqM.nc"
result_t OPneqM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 105
{
  BombillaStackVariable *arg1 = OPneqM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPneqM$Stacks$popOperand(context);

#line 108
  dbg(DBG_USR1, "VM (%i): Executing neq.\n", (int )context->which);
  OPneqM$Stacks$pushValue(context, !OPneqM$areEqual(arg1, arg2));
  return SUCCESS;
}

# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
inline static  result_t OPlteM$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840){
#line 94
  unsigned char result;
#line 94

#line 94
  result = BombillaEngineM$Error$error(arg_0x9db46f8, arg_0x9db4840);
#line 94

#line 94
  return result;
#line 94
}
#line 94
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPlteM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
#line 158
inline static  BombillaStackVariable *OPlteM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPlteM.nc"
result_t OPlteM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg1 = OPlteM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPlteM$Stacks$popOperand(context);

  if (arg1->type == BOMB_VAR_V && 
  arg2->type == BOMB_VAR_V) {
      OPlteM$Stacks$pushValue(context, arg2->value.var <= arg1->value.var);
    }
  else {
    if (
#line 98
    arg1->type == BOMB_VAR_S && 
    arg2->type == BOMB_VAR_S && 
    arg1->sense.type == arg2->sense.type) {
        OPlteM$Stacks$pushValue(context, arg2->sense.var <= arg1->sense.var);
      }
    else {
        OPlteM$BombillaError$error(context, BOMB_ERROR_INVALID_TYPE);
        return FAIL;
      }
    }
#line 107
  return SUCCESS;
}

# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
inline static  result_t OPltM$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840){
#line 94
  unsigned char result;
#line 94

#line 94
  result = BombillaEngineM$Error$error(arg_0x9db46f8, arg_0x9db4840);
#line 94

#line 94
  return result;
#line 94
}
#line 94
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPltM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
#line 158
inline static  BombillaStackVariable *OPltM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPltM.nc"
result_t OPltM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg1 = OPltM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPltM$Stacks$popOperand(context);

  if (arg1->type == BOMB_VAR_V && 
  arg2->type == BOMB_VAR_V) {
      OPltM$Stacks$pushValue(context, arg2->value.var < arg1->value.var);
    }
  else {
    if (
#line 98
    arg1->type == BOMB_VAR_S && 
    arg2->type == BOMB_VAR_S && 
    arg1->sense.type == arg2->sense.type) {
        OPltM$Stacks$pushValue(context, arg2->sense.var < arg1->sense.var);
      }
    else {
        OPltM$BombillaError$error(context, BOMB_ERROR_INVALID_TYPE);
      }
    }
#line 106
  return SUCCESS;
}

# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
inline static  result_t OPgtM$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840){
#line 94
  unsigned char result;
#line 94

#line 94
  result = BombillaEngineM$Error$error(arg_0x9db46f8, arg_0x9db4840);
#line 94

#line 94
  return result;
#line 94
}
#line 94
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPgtM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
#line 158
inline static  BombillaStackVariable *OPgtM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgtM.nc"
result_t OPgtM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg1 = OPgtM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPgtM$Stacks$popOperand(context);

  if (arg1->type == BOMB_VAR_V && 
  arg2->type == BOMB_VAR_V) {
      OPgtM$Stacks$pushValue(context, arg2->value.var > arg1->value.var);
    }
  else {
    if (
#line 98
    arg1->type == BOMB_VAR_S && 
    arg2->type == BOMB_VAR_S && 
    arg1->sense.type == arg2->sense.type) {
        OPgtM$Stacks$pushValue(context, arg2->sense.var > arg1->sense.var);
      }
    else {
        OPgtM$BombillaError$error(context, BOMB_ERROR_INVALID_TYPE);
        return FAIL;
      }
    }
#line 107
  return SUCCESS;
}

# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
inline static  result_t OPgteM$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840){
#line 94
  unsigned char result;
#line 94

#line 94
  result = BombillaEngineM$Error$error(arg_0x9db46f8, arg_0x9db4840);
#line 94

#line 94
  return result;
#line 94
}
#line 94
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPgteM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
#line 158
inline static  BombillaStackVariable *OPgteM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgteM.nc"
result_t OPgteM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg1 = OPgteM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPgteM$Stacks$popOperand(context);

  if (arg1->type == BOMB_VAR_V && 
  arg2->type == BOMB_VAR_V) {
      OPgteM$Stacks$pushValue(context, arg2->value.var > arg1->value.var);
    }
  else {
    if (
#line 98
    arg1->type == BOMB_VAR_S && 
    arg2->type == BOMB_VAR_S && 
    arg1->sense.type == arg2->sense.type) {
        OPgteM$Stacks$pushValue(context, arg2->sense.var > arg1->sense.var);
      }
    else {
        OPgteM$BombillaError$error(context, BOMB_ERROR_INVALID_TYPE);
        return FAIL;
      }
    }
#line 107
  return SUCCESS;
}

static inline 
# 88 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPeqM.nc"
bool OPeqM$areEqual(BombillaStackVariable *arg1, BombillaStackVariable *arg2)
#line 88
{
  if (arg1->type != arg2->type) {
#line 89
      return FALSE;
    }
#line 90
  if (arg1->type == BOMB_TYPE_SENSE) {
      return arg1->sense.type == arg2->sense.type && 
      arg1->sense.var == arg2->sense.var;
    }
  else {
#line 94
    if (arg1->type == BOMB_TYPE_VALUE) {
        return arg1->value.var == arg2->value.var;
      }
    else {
#line 97
      if (arg1->type == BOMB_TYPE_BUFFER) {
          return arg1->buffer.var == arg2->buffer.var;
        }
      else {
          return FALSE;
        }
      }
    }
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPeqM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
#line 158
inline static  BombillaStackVariable *OPeqM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 105 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPeqM.nc"
result_t OPeqM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 106
{
  BombillaStackVariable *arg1 = OPeqM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPeqM$Stacks$popOperand(context);

#line 109
  dbg(DBG_USR1, "VM (%i): Executing eq.\n", (int )context->which);
  OPeqM$Stacks$pushValue(context, OPeqM$areEqual(arg1, arg2));
  return SUCCESS;
}

# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPpopM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 88 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPpopM.nc"
result_t OPpopM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 89
{
  dbg(DBG_USR1, "VM (%i): Popping top operand off of stack. \n", context->which);
  OPpopM$Stacks$popOperand(context);
  return SUCCESS;
}

# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
inline static  result_t BBuffer$Error$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840){
#line 94
  unsigned char result;
#line 94

#line 94
  result = BombillaEngineM$Error$error(arg_0x9db46f8, arg_0x9db4840);
#line 94

#line 94
  return result;
#line 94
}
#line 94
static inline  
# 271 "/root/src/tinyos-1.x/tos/lib/VM/components/BBuffer.nc"
result_t BBuffer$Buffer$set(BombillaContext *context, 
BombillaDataBuffer *buffer, 
uint8_t bufferIndex, 
BombillaStackVariable *src)
#line 274
{

  if (bufferIndex >= BOMB_BUF_LEN) {
      BBuffer$Error$error(context, BOMB_ERROR_INDEX_OUT_OF_BOUNDS);
    }
  if (src->type == BOMB_VAR_V) {
      if (buffer->type != BOMB_DATA_VALUE) {
          BBuffer$Error$error(context, BOMB_ERROR_INVALID_TYPE);
          return FAIL;
        }
      buffer->entries[bufferIndex] = src->value.var;
    }
  else {
#line 286
    if (src->type == BOMB_VAR_S) {
        if (buffer->type != src->sense.type) {
            BBuffer$Error$error(context, BOMB_ERROR_INVALID_TYPE);
            return FAIL;
          }
        buffer->entries[bufferIndex] = src->sense.var;
      }
    else {
        BBuffer$Error$error(context, BOMB_ERROR_INVALID_TYPE);
        return FAIL;
      }
    }
  if (buffer->size < bufferIndex) {
      buffer->size = bufferIndex + 1;
    }
  return SUCCESS;
}

# 211 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBuffer.nc"
inline static  result_t OPbwriteM$Buffer$set(BombillaContext *arg_0xa01e900, BombillaDataBuffer *arg_0xa01ea70, uint8_t arg_0xa01ebc0, BombillaStackVariable *arg_0xa01ed30){
#line 211
  unsigned char result;
#line 211

#line 211
  result = BBuffer$Buffer$set(arg_0xa01e900, arg_0xa01ea70, arg_0xa01ebc0, arg_0xa01ed30);
#line 211

#line 211
  return result;
#line 211
}
#line 211
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPbwriteM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPbwriteM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbwriteM.nc"
result_t OPbwriteM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 91
{
  BombillaStackVariable *bidx = OPbwriteM$Stacks$popOperand(context);
  BombillaStackVariable *buf = OPbwriteM$Stacks$popOperand(context);
  BombillaStackVariable *val = OPbwriteM$Stacks$popOperand(context);

#line 95
  dbg(DBG_USR1, "Writing element to buffer\n");
  if (!OPbwriteM$Types$checkTypes(context, bidx, BOMB_VAR_V) || 
  !OPbwriteM$Types$checkTypes(context, buf, BOMB_VAR_B)) {
#line 97
      return FAIL;
    }
#line 98
  OPbwriteM$Buffer$set(context, buf->buffer.var, bidx->value.var, val);
  return SUCCESS;
}

# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPbreadM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500){
#line 147
  unsigned char result;
#line 147

#line 147
  result = BStacks$Stacks$pushOperand(arg_0x9fb7390, arg_0x9fb7500);
#line 147

#line 147
  return result;
#line 147
}
#line 147
# 172 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBuffer.nc"
inline static  result_t OPbreadM$Buffer$get(BombillaContext *arg_0xa0214a8, BombillaDataBuffer *arg_0xa021618, uint8_t arg_0xa021768, BombillaStackVariable *arg_0xa0218d8){
#line 172
  unsigned char result;
#line 172

#line 172
  result = BBuffer$Buffer$get(arg_0xa0214a8, arg_0xa021618, arg_0xa021768, arg_0xa0218d8);
#line 172

#line 172
  return result;
#line 172
}
#line 172
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPbreadM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPbreadM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbreadM.nc"
result_t OPbreadM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 91
{
  BombillaStackVariable *bindex = OPbreadM$Stacks$popOperand(context);
  BombillaStackVariable *buf = OPbreadM$Stacks$popOperand(context);
  BombillaStackVariable element;

#line 95
  dbg(DBG_USR1, "Reading element from buffer\n");
  if (!OPbreadM$Types$checkTypes(context, bindex, BOMB_VAR_V) || 
  !OPbreadM$Types$checkTypes(context, buf, BOMB_VAR_B)) {
#line 97
      return FAIL;
    }
#line 98
  OPbreadM$Buffer$get(context, buf->buffer.var, bindex->value.var, &element);
  OPbreadM$Stacks$pushOperand(context, &element);
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPmulM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPmulM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPmulM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPmulM.nc"
result_t OPmulM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg1 = OPmulM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPmulM$Stacks$popOperand(context);

  dbg(DBG_USR1, "VM (%i): Executing multiply.\n", (int )context->which);
  if (!OPmulM$Types$checkTypes(context, arg1, BOMB_VAR_V) || 
  !OPmulM$Types$checkTypes(context, arg2, BOMB_VAR_V)) {
#line 96
      return FAIL;
    }
#line 97
  OPmulM$Stacks$pushValue(context, arg2->value.var * arg1->value.var);
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPmodM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPmodM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPmodM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPmodM.nc"
result_t OPmodM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg1 = OPmodM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPmodM$Stacks$popOperand(context);

  dbg(DBG_USR1, "VM (%i): Executing mod.\n", (int )context->which);
  if (!OPmodM$Types$checkTypes(context, arg1, BOMB_VAR_V) || 
  !OPmodM$Types$checkTypes(context, arg2, BOMB_VAR_V)) {
#line 96
      return FAIL;
    }
#line 97
  OPmodM$Stacks$pushValue(context, arg2->value.var % arg1->value.var);
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPlxorM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPlxorM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPlxorM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPlxorM.nc"
result_t OPlxorM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg1 = OPlxorM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPlxorM$Stacks$popOperand(context);

#line 93
  dbg(DBG_USR1, "VM (%i): Taking logical xor.\n", (int )context->which);

  if (!OPlxorM$Types$checkTypes(context, arg1, BOMB_VAR_V) || 
  !OPlxorM$Types$checkTypes(context, arg2, BOMB_VAR_V)) {
#line 96
      return FAIL;
    }
  OPlxorM$Stacks$pushValue(context, arg1->value.var ^ arg2->value.var);
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPimpM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPimpM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPimpM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPimpM.nc"
result_t OPimpM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  uint16_t result;
  BombillaStackVariable *arg1 = OPimpM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPimpM$Stacks$popOperand(context);

  if (!OPimpM$Types$checkTypes(context, arg1, BOMB_VAR_V) || 
  !OPimpM$Types$checkTypes(context, arg2, BOMB_VAR_V)) {
#line 96
      return FAIL;
    }
  result = ! arg1->value.var || (arg1->value.var && arg2->value.var);

  OPimpM$Stacks$pushValue(context, result);
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPexpM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPexpM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPexpM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPexpM.nc"
result_t OPexpM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  uint16_t rval;
  BombillaStackVariable *arg1 = OPexpM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPexpM$Stacks$popOperand(context);

  if (!OPexpM$Types$checkTypes(context, arg1, BOMB_VAR_V) || 
  !OPexpM$Types$checkTypes(context, arg2, BOMB_VAR_V)) {
#line 96
      return FAIL;
    }
  rval = (uint16_t )pow((double )arg1->value.var, (double )arg2->value.var);
  OPexpM$Stacks$pushValue(context, rval);
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPeqvM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPeqvM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPeqvM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPeqvM.nc"
result_t OPeqvM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  uint16_t rval;
  BombillaStackVariable *arg1 = OPeqvM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPeqvM$Stacks$popOperand(context);

#line 94
  if (!OPeqvM$Types$checkTypes(context, arg1, BOMB_VAR_V) || 
  !OPeqvM$Types$checkTypes(context, arg2, BOMB_VAR_V)) {
#line 95
      return FAIL;
    }
#line 96
  rval = (arg1->value.var && arg2->value.var) || !(arg1->value.var || arg2->value.var);

  OPeqvM$Stacks$pushValue(context, rval);
  return SUCCESS;
}

# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPbtailM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500){
#line 147
  unsigned char result;
#line 147

#line 147
  result = BStacks$Stacks$pushOperand(arg_0x9fb7390, arg_0x9fb7500);
#line 147

#line 147
  return result;
#line 147
}
#line 147
static inline  
# 233 "/root/src/tinyos-1.x/tos/lib/VM/components/BBuffer.nc"
result_t BBuffer$Buffer$yank(BombillaContext *context, 
BombillaDataBuffer *buffer, 
uint8_t bufferIndex, 
BombillaStackVariable *dest)
#line 236
{
  if (bufferIndex >= buffer->size) {
      dbg(DBG_ERROR, "VM: Index %i out of bounds on buffer of size %i.\n", (int )buffer->size, (int )bufferIndex);
      BBuffer$Error$error(context, BOMB_ERROR_INDEX_OUT_OF_BOUNDS);
      return FAIL;
    }
  else {
#line 242
    if (buffer->type == BOMB_DATA_VALUE) {
        uint8_t i;

#line 244
        dest->type = BOMB_TYPE_VALUE;
        dest->value.var = buffer->entries[bufferIndex];
        for (i = bufferIndex; i < buffer->size - 1; i++) {
            buffer->entries[i] = buffer->entries[i + 1];
          }
        buffer->size--;
        return SUCCESS;
      }
    else {
#line 252
      if (buffer->type > BOMB_DATA_VALUE && 
      buffer->type < BOMB_DATA_END) {
          uint8_t i;

#line 255
          dest->type = BOMB_TYPE_SENSE;
          dest->sense.type = buffer->type;
          dest->sense.var = buffer->entries[bufferIndex];
          for (i = bufferIndex; i < buffer->size - 1; i++) {
              buffer->entries[i] = buffer->entries[i + 1];
            }
          buffer->size--;
          return SUCCESS;
        }
      else {
          dbg(DBG_ERROR, "VM: Tried to get entry from buffer of unknown type!\n");
          return FAIL;
        }
      }
    }
#line 268
  return FAIL;
}

# 191 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBuffer.nc"
inline static  result_t OPbtailM$Buffer$yank(BombillaContext *arg_0xa021ec0, BombillaDataBuffer *arg_0xa01e060, uint8_t arg_0xa01e1b0, BombillaStackVariable *arg_0xa01e320){
#line 191
  unsigned char result;
#line 191

#line 191
  result = BBuffer$Buffer$yank(arg_0xa021ec0, arg_0xa01e060, arg_0xa01e1b0, arg_0xa01e320);
#line 191

#line 191
  return result;
#line 191
}
#line 191
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPbtailM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPbtailM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbtailM.nc"
result_t OPbtailM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 91
{
  BombillaStackVariable *arg = OPbtailM$Stacks$popOperand(context);

#line 93
  dbg(DBG_USR1, "VM (%i): yanking tail of buffer. \n", context->which);

  if (!OPbtailM$Types$checkTypes(context, arg, BOMB_VAR_B)) {
#line 95
      return FAIL;
    }
  else 
#line 96
    {
      BombillaStackVariable var;

#line 98
      OPbtailM$Buffer$yank(context, arg->buffer.var, arg->buffer.var->size - 1, &var);
      OPbtailM$Stacks$pushOperand(context, arg);
      OPbtailM$Stacks$pushOperand(context, &var);
      return SUCCESS;
    }
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPdivM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPdivM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPdivM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPdivM.nc"
result_t OPdivM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg1 = OPdivM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPdivM$Stacks$popOperand(context);

  dbg(DBG_USR1, "VM (%i): Executing div.\n", (int )context->which);
  if (!OPdivM$Types$checkTypes(context, arg1, BOMB_VAR_V) || 
  !OPdivM$Types$checkTypes(context, arg2, BOMB_VAR_V)) {
#line 96
      return FAIL;
    }
#line 97
  OPdivM$Stacks$pushValue(context, arg2->value.var / arg1->value.var);
  return SUCCESS;
}

# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPlnotM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500){
#line 147
  unsigned char result;
#line 147

#line 147
  result = BStacks$Stacks$pushOperand(arg_0x9fb7390, arg_0x9fb7500);
#line 147

#line 147
  return result;
#line 147
}
#line 147
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPlnotM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPlnotM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPlnotM.nc"
result_t OPlnotM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg = OPlnotM$Stacks$popOperand(context);

#line 92
  dbg(DBG_USR1, "VM (%i): Logical not of top of stack.\n", (int )context->which);
  if (!OPlnotM$Types$checkTypes(context, arg, BOMB_VAR_V)) {
#line 93
      return FAIL;
    }
#line 94
  arg->value.var = ~ arg->value.var;
  OPlnotM$Stacks$pushOperand(context, arg);
  return SUCCESS;
}

# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPnotM$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500){
#line 147
  unsigned char result;
#line 147

#line 147
  result = BStacks$Stacks$pushOperand(arg_0x9fb7390, arg_0x9fb7500);
#line 147

#line 147
  return result;
#line 147
}
#line 147
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPnotM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPnotM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPnotM.nc"
result_t OPnotM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg = OPnotM$Stacks$popOperand(context);

#line 92
  dbg(DBG_USR1, "VM (%i): Not top of stack.\n", (int )context->which);
  if (!OPnotM$Types$checkTypes(context, arg, BOMB_VAR_V)) {
#line 93
      return FAIL;
    }
#line 94
  arg->value.var = arg->value.var ? 0 : 1;
  OPnotM$Stacks$pushOperand(context, arg);
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPandM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPandM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPandM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPandM.nc"
result_t OPandM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg1 = OPandM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPandM$Stacks$popOperand(context);

#line 93
  dbg(DBG_USR1, "VM (%i): Taking logical and.\n", (int )context->which);

  if (!OPandM$Types$checkTypes(context, arg1, BOMB_VAR_V) || 
  !OPandM$Types$checkTypes(context, arg2, BOMB_VAR_V)) {
#line 96
      return FAIL;
    }
  OPandM$Stacks$pushValue(context, arg1->value.var && arg2->value.var ? 1 : 0);
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPorM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPorM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPorM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPorM.nc"
result_t OPorM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg1 = OPorM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPorM$Stacks$popOperand(context);

#line 93
  dbg(DBG_USR1, "VM (%i): Taking logical and.\n", (int )context->which);

  if (!OPorM$Types$checkTypes(context, arg1, BOMB_VAR_V) || 
  !OPorM$Types$checkTypes(context, arg2, BOMB_VAR_V)) {
#line 96
      return FAIL;
    }
  OPorM$Stacks$pushValue(context, arg1->value.var || arg2->value.var ? 1 : 0);
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPlorM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPlorM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPlorM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPlorM.nc"
result_t OPlorM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg1 = OPlorM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPlorM$Stacks$popOperand(context);

#line 93
  dbg(DBG_USR1, "VM (%i): Taking logical or.\n", (int )context->which);

  if (!OPlorM$Types$checkTypes(context, arg1, BOMB_VAR_V) || 
  !OPlorM$Types$checkTypes(context, arg2, BOMB_VAR_V)) {
#line 96
      return FAIL;
    }
  OPlorM$Stacks$pushValue(context, arg1->value.var | arg2->value.var);
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPlandM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPlandM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPlandM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPlandM.nc"
result_t OPlandM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg1 = OPlandM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPlandM$Stacks$popOperand(context);

#line 93
  dbg(DBG_USR1, "VM (%i): Taking logical and.\n", (int )context->which);

  if (!OPlandM$Types$checkTypes(context, arg1, BOMB_VAR_V) || 
  !OPlandM$Types$checkTypes(context, arg2, BOMB_VAR_V)) {
#line 96
      return FAIL;
    }
  OPlandM$Stacks$pushValue(context, arg1->value.var & arg2->value.var);
  return SUCCESS;
}

# 111 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaLocks.nc"
inline static  result_t BContextSynch$Locks$unlock(BombillaContext *arg_0x9fbe5d8, uint8_t arg_0x9fbe720){
#line 111
  unsigned char result;
#line 111

#line 111
  result = BLocks$Locks$unlock(arg_0x9fbe5d8, arg_0x9fbe720);
#line 111

#line 111
  return result;
#line 111
}
#line 111
static inline  
# 167 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
result_t BContextSynch$Synch$releaseAllLocks(BombillaContext *caller, 
BombillaContext *releaser)
#line 168
{
  int8_t i;
  uint8_t *lockSet = releaser->heldSet;

#line 171
  dbg(DBG_USR2, "VM: Attempting to release all locks for context %i.\n", releaser->which);
  for (i = 0; i < BOMB_HEAPSIZE; i++) {
      if (lockSet[i / 8] & (1 << i % 8)) {
          BContextSynch$Locks$unlock(releaser, i);
        }
    }
  for (i = 0; i < (BOMB_HEAPSIZE + 7) / 8; i++) {
      releaser->releaseSet[i] = 0;
    }
  return SUCCESS;
}

static inline  
#line 284
void BContextSynch$Synch$haltContext(BombillaContext *context)
#line 284
{
  BContextSynch$Synch$releaseAllLocks(context, context);
  BContextSynch$Synch$yieldContext(context);
  context->state = BOMB_STATE_HALT;
}

# 157 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
inline static  void OPhaltM$Synch$haltContext(BombillaContext *arg_0x9df1d58){
#line 157
  BContextSynch$Synch$haltContext(arg_0x9df1d58);
#line 157
}
#line 157
static inline  
# 88 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPhaltM.nc"
result_t OPhaltM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 89
{
  dbg(DBG_USR1, "VM (%i): OPhaltM executed.\n", (int )context->which);
  context->state = BOMB_STATE_HALT;
  context->pc = 0;
  OPhaltM$Synch$haltContext(context);
  return SUCCESS;
}

# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPsubM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPsubM$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPsubM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 89 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPsubM.nc"
result_t OPsubM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 90
{
  BombillaStackVariable *arg1 = OPsubM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPsubM$Stacks$popOperand(context);

  dbg(DBG_USR1, "VM (%i): Executing subtract.\n", (int )context->which);
  if (!OPsubM$Types$checkTypes(context, arg1, BOMB_VAR_V) || 
  !OPsubM$Types$checkTypes(context, arg2, BOMB_VAR_V)) {
#line 96
      return FAIL;
    }
#line 97
  OPsubM$Stacks$pushValue(context, arg2->value.var - arg1->value.var);
  return SUCCESS;
}

# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
inline static  result_t OPaddM$Error$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840){
#line 94
  unsigned char result;
#line 94

#line 94
  result = BombillaEngineM$Error$error(arg_0x9db46f8, arg_0x9db4840);
#line 94

#line 94
  return result;
#line 94
}
#line 94
# 131 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPaddM$Stacks$pushBuffer(BombillaContext *arg_0x9fb6cc8, BombillaDataBuffer *arg_0x9fb6e38){
#line 131
  unsigned char result;
#line 131

#line 131
  result = BStacks$Stacks$pushBuffer(arg_0x9fb6cc8, arg_0x9fb6e38);
#line 131

#line 131
  return result;
#line 131
}
#line 131
# 122 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBuffer.nc"
inline static  result_t OPaddM$Buffer$append(BombillaContext *arg_0xa025af0, BombillaDataBuffer *arg_0xa025c60, BombillaStackVariable *arg_0xa025dd0){
#line 122
  unsigned char result;
#line 122

#line 122
  result = BBuffer$Buffer$append(arg_0xa025af0, arg_0xa025c60, arg_0xa025dd0);
#line 122

#line 122
  return result;
#line 122
}
#line 122
static inline  
# 146 "/root/src/tinyos-1.x/tos/lib/VM/components/BBuffer.nc"
uint8_t BBuffer$Buffer$concatenate(BombillaContext *context, 
BombillaDataBuffer *dest, 
BombillaDataBuffer *src)
#line 148
{
  if (dest->type != src->type) {
      BBuffer$Error$error(context, BOMB_ERROR_INVALID_TYPE);
      return FAIL;
    }
  else {
      uint8_t i;
      uint8_t start;
      uint8_t end;
      BombillaStackVariable var;

      start = dest->size;
      end = start + src->size;
      end = end > BOMB_BUF_LEN ? BOMB_BUF_LEN : end;
      for (i = start; i < end; i++) {
          BBuffer$Buffer$get(context, src, i - start, &var);
          BBuffer$Buffer$append(context, dest, &var);
        }
      return start + src->size - end;
    }
}

# 154 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBuffer.nc"
inline static  uint8_t OPaddM$Buffer$concatenate(BombillaContext *arg_0xa020bb8, BombillaDataBuffer *arg_0xa020d28, BombillaDataBuffer *arg_0xa020e98){
#line 154
  unsigned char result;
#line 154

#line 154
  result = BBuffer$Buffer$concatenate(arg_0xa020bb8, arg_0xa020d28, arg_0xa020e98);
#line 154

#line 154
  return result;
#line 154
}
#line 154
static inline  
# 169 "/root/src/tinyos-1.x/tos/lib/VM/components/BBuffer.nc"
result_t BBuffer$Buffer$prepend(BombillaContext *context, 
BombillaDataBuffer *buffer, 
BombillaStackVariable *var)
#line 171
{
  if (buffer->size >= BOMB_BUF_LEN) {
      dbg(DBG_ERROR, "VM: Data buffer overrun.\n");
      BBuffer$Error$error(context, BOMB_ERROR_BUFFER_OVERFLOW);
      return FAIL;
    }
  if (BBuffer$Buffer$checkAndSetTypes(context, buffer, var) == FAIL) {
      return FAIL;
    }
  if (var->type == BOMB_TYPE_VALUE) {
      uint8_t i;

#line 182
      for (i = buffer->size; i > 0; i--) {
          buffer->entries[(int )i] = buffer->entries[(int )i - 1];
        }
      buffer->entries[0] = var->value.var;
      buffer->size++;
      return SUCCESS;
    }
  else {
#line 189
    if (var->type == BOMB_TYPE_SENSE) {
        uint8_t i;

#line 191
        for (i = buffer->size; i > 0; i--) {
            buffer->entries[(int )i] = buffer->entries[(int )i - 1];
          }
        buffer->entries[0] = var->sense.var;
        buffer->size++;
        return SUCCESS;
      }
    else {
        dbg(DBG_USR1, "VM: Buffers only contain values or readings.\n");
        return FAIL;
      }
    }
}

# 137 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBuffer.nc"
inline static  result_t OPaddM$Buffer$prepend(BombillaContext *arg_0xa020360, BombillaDataBuffer *arg_0xa0204d0, BombillaStackVariable *arg_0xa020640){
#line 137
  unsigned char result;
#line 137

#line 137
  result = BBuffer$Buffer$prepend(arg_0xa020360, arg_0xa0204d0, arg_0xa020640);
#line 137

#line 137
  return result;
#line 137
}
#line 137
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPaddM$Stacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
#line 158
inline static  BombillaStackVariable *OPaddM$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
static inline  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPaddM.nc"
result_t OPaddM$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 91
{
  BombillaStackVariable *arg1 = OPaddM$Stacks$popOperand(context);
  BombillaStackVariable *arg2 = OPaddM$Stacks$popOperand(context);

  if (arg1->type == BOMB_TYPE_VALUE && arg2->type == BOMB_TYPE_VALUE) {
      dbg(DBG_USR1, "VM (%i): Executing add of two values: %i + %i == %i\n", (int )context->which, (int )arg1->value.var, (int )arg2->value.var, (int )arg1->value.var + arg2->value.var);
      OPaddM$Stacks$pushValue(context, arg1->value.var + arg2->value.var);
    }
  else {
    if (arg1->type == BOMB_TYPE_BUFFER) {
        if (arg2->type != BOMB_TYPE_BUFFER) {
            dbg(DBG_USR1, "VM (%i): Prepend value onto buffer.\n", (int )context->which);
            OPaddM$Buffer$prepend(context, arg1->buffer.var, arg2);
          }
        else {
            dbg(DBG_USR1, "VM (%i): Concatenating buffers.\n", (int )context->which);
            OPaddM$Buffer$concatenate(context, arg2->buffer.var, arg1->buffer.var);
          }
        OPaddM$Stacks$pushBuffer(context, arg1->buffer.var);
      }
    else {
#line 111
      if (arg2->type == BOMB_TYPE_BUFFER) {
          OPaddM$Buffer$append(context, arg2->buffer.var, arg1);
          OPaddM$Stacks$pushBuffer(context, arg2->buffer.var);
        }
      else {
          OPaddM$Error$error(context, BOMB_ERROR_TYPE_CHECK);
          dbg(DBG_USR1, "VM (%i): Invalid add.\n", (int )context->which);
        }
      }
    }
#line 120
  return SUCCESS;
}

static inline   
# 177 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
result_t BombillaEngineM$Bytecode$default$execute(uint8_t opcode, uint8_t instr, 
BombillaContext *context)
#line 178
{
  dbg(DBG_ERROR | DBG_USR1, "VM: Executing default instruction: halt!\n");
  context->state = BOMB_STATE_HALT;
  context->pc = 0;
  return FAIL;
}

# 97 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaBytecode.nc"
inline static  result_t BombillaEngineM$Bytecode$execute(uint8_t arg_0x9dd05b0, uint8_t arg_0x9dd60e8, BombillaContext *arg_0x9dd6260){
#line 97
  unsigned char result;
#line 97

#line 97
  switch (arg_0x9dd05b0) {
#line 97
    case OPadd + 0:
#line 97
      result = OPaddM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsub + 0:
#line 97
      result = OPsubM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPhalt + 0:
#line 97
      result = OPhaltM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPland + 0:
#line 97
      result = OPlandM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPlor + 0:
#line 97
      result = OPlorM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPor + 0:
#line 97
      result = OPorM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPand + 0:
#line 97
      result = OPandM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPnot + 0:
#line 97
      result = OPnotM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPlnot + 0:
#line 97
      result = OPlnotM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPdiv + 0:
#line 97
      result = OPdivM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPbtail + 0:
#line 97
      result = OPbtailM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPeqv + 0:
#line 97
      result = OPeqvM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPexp + 0:
#line 97
      result = OPexpM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPimp + 0:
#line 97
      result = OPimpM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPlxor + 0:
#line 97
      result = OPlxorM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPmod + 0:
#line 97
      result = OPmodM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPmul + 0:
#line 97
      result = OPmulM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPbread + 0:
#line 97
      result = OPbreadM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPbwrite + 0:
#line 97
      result = OPbwriteM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpop + 0:
#line 97
      result = OPpopM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPeq + 0:
#line 97
      result = OPeqM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgte + 0:
#line 97
      result = OPgteM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgt + 0:
#line 97
      result = OPgtM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPlt + 0:
#line 97
      result = OPltM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPlte + 0:
#line 97
      result = OPlteM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPneq + 0:
#line 97
      result = OPneqM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPcopy + 0:
#line 97
      result = OPcopyM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPinv + 0:
#line 97
      result = OPinvM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPputled + 0:
#line 97
      result = OPputledM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPbclear + 0:
#line 97
      result = OPbclearM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPcast + 0:
#line 97
      result = OPcastM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPid + 0:
#line 97
      result = OPidM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPuart + 0:
#line 97
      result = OPuartM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPrand + 0:
#line 97
      result = OPrandM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OProute + 0:
#line 97
      result = OProuteM$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPbpush1 + 0:
#line 97
      result = OPbpush1M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPbpush1 + 1:
#line 97
      result = OPbpush1M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsettimer1 + 0:
#line 97
      result = OPsettimer1M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsettimer1 + 1:
#line 97
      result = OPsettimer1M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OP2pushc10 + 0:
#line 97
      result = OP2pushc10M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OP2pushc10 + 1:
#line 97
      result = OP2pushc10M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OP2pushc10 + 2:
#line 97
      result = OP2pushc10M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OP2pushc10 + 3:
#line 97
      result = OP2pushc10M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OP2jumps10 + 0:
#line 97
      result = OP2jumps10M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OP2jumps10 + 1:
#line 97
      result = OP2jumps10M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OP2jumps10 + 2:
#line 97
      result = OP2jumps10M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OP2jumps10 + 3:
#line 97
      result = OP2jumps10M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetlocal3 + 0:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetlocal3 + 1:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetlocal3 + 2:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetlocal3 + 3:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetlocal3 + 4:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetlocal3 + 5:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetlocal3 + 6:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetlocal3 + 7:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetlocal3 + 0:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetlocal3 + 1:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetlocal3 + 2:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetlocal3 + 3:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetlocal3 + 4:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetlocal3 + 5:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetlocal3 + 6:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetlocal3 + 7:
#line 97
      result = OPgetsetlocal3M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 0:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 1:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 2:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 3:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 4:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 5:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 6:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 7:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 8:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 9:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 10:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 11:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 12:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 13:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 14:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPgetvar4 + 15:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 0:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 1:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 2:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 3:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 4:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 5:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 6:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 7:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 8:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 9:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 10:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 11:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 12:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 13:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 14:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPsetvar4 + 15:
#line 97
      result = OPgetsetvar4M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 0:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 1:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 2:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 3:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 4:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 5:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 6:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 7:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 8:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 9:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 10:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 11:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 12:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 13:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 14:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 15:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 16:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 17:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 18:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 19:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 20:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 21:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 22:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 23:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 24:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 25:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 26:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 27:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 28:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 29:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 30:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 31:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 32:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 33:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 34:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 35:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 36:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 37:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 38:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 39:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 40:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 41:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 42:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 43:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 44:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 45:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 46:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 47:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 48:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 49:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 50:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 51:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 52:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 53:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 54:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 55:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 56:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 57:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 58:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 59:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 60:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 61:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 62:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    case OPpushc6 + 63:
#line 97
      result = OPpushc6M$BombillaBytecode$execute(arg_0x9dd60e8, arg_0x9dd6260);
#line 97
      break;
#line 97
    default:
#line 97
      result = BombillaEngineM$Bytecode$default$execute(arg_0x9dd05b0, arg_0x9dd60e8, arg_0x9dd6260);
#line 97
    }
#line 97

#line 97
  return result;
#line 97
}
#line 97
static inline 
# 140 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
result_t BombillaEngineM$computeInstruction(BombillaContext *context)
#line 140
{
  uint8_t instr = context->currentCapsule->capsule.code[(int )context->pc];

  if (context->state != BOMB_STATE_RUN) {
      dbg(DBG_ERROR, "VM: (%hhi) Tried to execute instruction in non-run state: %hhi\n", context->which, context->state);
      return FAIL;
    }
  context->pc++;
  BombillaEngineM$Bytecode$execute(instr, instr, context);
  return SUCCESS;
}

# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
inline static  result_t BStacks$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840){
#line 94
  unsigned char result;
#line 94

#line 94
  result = BombillaEngineM$Error$error(arg_0x9db46f8, arg_0x9db4840);
#line 94

#line 94
  return result;
#line 94
}
#line 94
# 100 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaQueue.nc"
inline static  bool BContextSynch$Queue$empty(BombillaQueue *arg_0x9dcc300){
#line 100
  unsigned char result;
#line 100

#line 100
  result = BQueue$Queue$empty(arg_0x9dcc300);
#line 100

#line 100
  return result;
#line 100
}
#line 100
#line 129
inline static  BombillaContext *BContextSynch$Queue$dequeue(BombillaContext *arg_0x9dcd0a0, BombillaQueue *arg_0x9dcd218){
#line 129
  struct __nesc_unnamed4356 *result;
#line 129

#line 129
  result = BQueue$Queue$dequeue(arg_0x9dcd0a0, arg_0x9dcd218);
#line 129

#line 129
  return result;
#line 129
}
#line 129
static inline 
# 131 "/root/src/tinyos-1.x/beta/TOSSIM-packet/packet_sim.c"
void initialBackoff(void)
#line 131
{
  event_t *event = (event_t *)malloc(sizeof(event_t ));
  int backoffAmount = initBackoffLow;

#line 134
  backoffAmount += rand() % (initBackoffHigh - initBackoffLow);
  event_backoff_create(event, tos_state.current_node, tos_state.tos_time + backoffAmount);
  if (dbg_active(DBG_PACKET)) {
      char timeBuf[128];

#line 138
      printTime(timeBuf, 128);
      dbg(DBG_PACKET, "SIM_PACKET: Initial backoff @%s is %i.\n", timeBuf, backoffAmount);
    }
  dbg(DBG_MEM, "SIM_PACKET: Allocated event 0x%x\n", (unsigned int )event);
  queue_insert_event(& tos_state.queue, event);
#line 142
  ;
}

static inline 
#line 121
result_t packet_sim_transmit(TOS_MsgPtr msg)
#line 121
{
  if (packet_transmitting[tos_state.current_node] != (void *)0) {
      return FAIL;
    }
  packet_transmitting[tos_state.current_node] = msg;
  txState[tos_state.current_node] = RADIO_TX_BACK;
  initialBackoff();
  return SUCCESS;
}

static inline  
# 384 "/root/src/tinyos-1.x/beta/TOSSIM-packet/Nido.nc"
result_t Nido$RadioSendMsg$send(TOS_MsgPtr msg)
#line 384
{
  dbg(DBG_AM, "TossimPacketM: Send.send() called\n");
  return packet_sim_transmit(msg);
}

# 58 "/root/src/tinyos-1.x/tos/interfaces/BareSendMsg.nc"
inline static  result_t AMPromiscuous$RadioSend$send(TOS_MsgPtr arg_0x9e6a760){
#line 58
  unsigned char result;
#line 58

#line 58
  result = Nido$RadioSendMsg$send(arg_0x9e6a760);
#line 58

#line 58
  return result;
#line 58
}
#line 58
static inline  
# 238 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
result_t AMPromiscuous$UARTSend$sendDone(TOS_MsgPtr msg, result_t success)
#line 238
{
  return AMPromiscuous$reportSendDone(msg, success);
}

# 67 "/root/src/tinyos-1.x/tos/interfaces/BareSendMsg.nc"
inline static  result_t UARTNoCRCPacketM$Send$sendDone(TOS_MsgPtr arg_0x9e6ac78, result_t arg_0x9e6adc8){
#line 67
  unsigned char result;
#line 67

#line 67
  result = AMPromiscuous$UARTSend$sendDone(arg_0x9e6ac78, arg_0x9e6adc8);
#line 67

#line 67
  return result;
#line 67
}
#line 67
# 79 "/root/src/tinyos-1.x/tos/platform/pc/UARTNoCRCPacketM.nc"
void   NIDO_uart_send_done(TOS_MsgPtr fmsg, result_t fsuccess)
#line 79
{
  UARTNoCRCPacketM$Send$sendDone(fmsg, fsuccess);
}

static inline 
# 48 "/root/src/tinyos-1.x/tos/platform/pc/PCRadio.h"
void event_uart_write_handle(event_t *uevent, 
struct TOS_state *state)
#line 49
{


  NIDO_uart_send_done((TOS_MsgPtr )((uart_send_done_data_t *)uevent->data)->msg, (
  (uart_send_done_data_t *)uevent->data)->success);
  (

  (uart_send_done_data_t *)uevent->data)->msg = (void *)0;
  event_cleanup(uevent);
  dbg(DBG_UART, "UART: packet transfer complete.\n");
}

static inline void event_uart_write_create(event_t *uevent, int mote, long long utime, TOS_MsgPtr msg, result_t success)
#line 61
{
  uart_send_done_data_t *data = (uart_send_done_data_t *)malloc(sizeof(uart_send_done_data_t ));

#line 63
  dbg(DBG_MEM, "malloc uart send done data event.\n");
  (
  (uart_send_done_data_t *)data)->msg = msg;
  ((uart_send_done_data_t *)data)->success = success;

  uevent->mote = mote;
  uevent->data = data;
  uevent->time = utime;
  uevent->handle = event_uart_write_handle;
  uevent->cleanup = event_total_cleanup;
  uevent->pause = 0;
  uevent->force = 0;
}

static inline void TOSH_uart_send(TOS_MsgPtr msg)
{
  result_t success;
  event_t *uevent;
  UARTMsgSentEvent ev;
  char buf[1024];

#line 83
  success = SUCCESS;

  nmemcpy(& ev.message, msg, sizeof  ev.message);
  sendTossimEvent(tos_state.current_node, AM_UARTMSGSENTEVENT, tos_state.tos_time, &ev);


  uevent = (event_t *)malloc(sizeof(event_t ));
  event_uart_write_create(uevent, tos_state.current_node, tos_state.tos_time + UART_SEND_DELAY, msg, success);
  queue_insert_event(& tos_state.queue, uevent);
#line 91
  ;
  printTime(buf, 1024);
  dbg(DBG_UART, "Enqueueing uart_send_event at %s for mote %i", buf, tos_state.current_node);
}

static inline  
# 67 "/root/src/tinyos-1.x/tos/platform/pc/UARTNoCRCPacketM.nc"
result_t UARTNoCRCPacketM$Send$send(TOS_MsgPtr msg)
#line 67
{
  msg->crc = 1;

  TOSH_uart_send(msg);

  return SUCCESS;
}

# 58 "/root/src/tinyos-1.x/tos/interfaces/BareSendMsg.nc"
inline static  result_t AMPromiscuous$UARTSend$send(TOS_MsgPtr arg_0x9e6a760){
#line 58
  unsigned char result;
#line 58

#line 58
  result = UARTNoCRCPacketM$Send$send(arg_0x9e6a760);
#line 58

#line 58
  return result;
#line 58
}
#line 58
static inline  
# 190 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
void AMPromiscuous$sendTask(void)
#line 190
{
  result_t ok;

  if (AMPromiscuous$buffer[tos_state.current_node]->addr == TOS_UART_ADDR) {
    ok = AMPromiscuous$UARTSend$send(AMPromiscuous$buffer[tos_state.current_node]);
    }
  else {
#line 196
    ok = AMPromiscuous$RadioSend$send(AMPromiscuous$buffer[tos_state.current_node]);
    }
  if (ok == FAIL) {
    AMPromiscuous$reportSendDone(AMPromiscuous$buffer[tos_state.current_node], FAIL);
    }
}

static inline  
#line 241
result_t AMPromiscuous$RadioSend$sendDone(TOS_MsgPtr msg, result_t success)
#line 241
{
  return AMPromiscuous$reportSendDone(msg, success);
}

# 67 "/root/src/tinyos-1.x/tos/interfaces/BareSendMsg.nc"
inline static  result_t Nido$RadioSendMsg$sendDone(TOS_MsgPtr arg_0x9e6ac78, result_t arg_0x9e6adc8){
#line 67
  unsigned char result;
#line 67

#line 67
  result = AMPromiscuous$RadioSend$sendDone(arg_0x9e6ac78, arg_0x9e6adc8);
#line 67

#line 67
  return result;
#line 67
}
#line 67
# 393 "/root/src/tinyos-1.x/beta/TOSSIM-packet/Nido.nc"
void   packet_sim_transmit_done(TOS_MsgPtr msg)
#line 393
{
  dbg(DBG_PACKET, "TossimPacketMica2M: Send done.\n");
  Nido$RadioSendMsg$sendDone(msg, SUCCESS);
}

# 291 "/root/src/tinyos-1.x/beta/TOSSIM-packet/packet_sim.c"
void   event_send_packet_done_handle(event_t *event, struct TOS_state *state)
#line 291
{
  RadioMsgSentEvent ev;
  TOS_MsgPtr bufferPtr = packet_transmitting[tos_state.current_node];

#line 294
  if (dbg_active(DBG_PACKET)) {
      char timeBuf[128];

#line 296
      printTime(timeBuf, 128);
      dbg(DBG_PACKET, "SIM_PACKET: Send done @%s\n", timeBuf);
    }

  nmemcpy(& ev.message, bufferPtr, sizeof  ev.message);
  ev.message.crc = 1;
  sendTossimEvent(tos_state.current_node, AM_RADIOMSGSENTEVENT, tos_state.tos_time, &ev);

  packet_transmitting[tos_state.current_node] = (void *)0;
  packet_sim_transmit_done(bufferPtr);
  txState[tos_state.current_node] = RADIO_TX_IDLE;
  event_cleanup(event);
}

#line 280
void   event_send_packet_done_create(event_t *event, int node, long long eventTime)
#line 280
{
  event->mote = node;
  event->force = 0;
  event->pause = 0;
  event->time = eventTime;
  event->handle = event_send_packet_done_handle;
  event->cleanup = event_total_cleanup;
  event->data = (void *)0;
}

static inline  
# 281 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
TOS_MsgPtr AMPromiscuous$RadioReceive$receive(TOS_MsgPtr packet)
#line 281
{
  return prom_received(packet);
}

# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
inline static  TOS_MsgPtr TossimPacketM$Receive$receive(TOS_MsgPtr arg_0x9e55570){
#line 75
  struct TOS_Msg *result;
#line 75

#line 75
  result = AMPromiscuous$RadioReceive$receive(arg_0x9e55570);
#line 75

#line 75
  return result;
#line 75
}
#line 75
static inline  
# 79 "/root/src/tinyos-1.x/beta/TOSSIM-packet/TossimPacketM.nc"
TOS_MsgPtr TossimPacketM$ReceiveMain$receive(TOS_MsgPtr msg)
#line 79
{
  nmemcpy(TossimPacketM$bufferPtr[tos_state.current_node], msg, sizeof(TOS_Msg ));
  TossimPacketM$bufferPtr[tos_state.current_node] = TossimPacketM$Receive$receive(TossimPacketM$bufferPtr[tos_state.current_node]);
  return msg;
}

# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
inline static  TOS_MsgPtr Nido$RadioReceiveMsg$receive(TOS_MsgPtr arg_0x9e55570){
#line 75
  struct TOS_Msg *result;
#line 75

#line 75
  result = TossimPacketM$ReceiveMain$receive(arg_0x9e55570);
#line 75

#line 75
  return result;
#line 75
}
#line 75
# 398 "/root/src/tinyos-1.x/beta/TOSSIM-packet/Nido.nc"
TOS_MsgPtr   packet_sim_receive_msg(TOS_MsgPtr msg)
#line 398
{
  if (msg->crc) {
      return Nido$RadioReceiveMsg$receive(msg);
    }
  else {
      return msg;
    }
}

# 268 "/root/src/tinyos-1.x/beta/TOSSIM-packet/packet_sim.c"
void   event_receive_packet_handle(event_t *event, struct TOS_state *state)
#line 268
{
  IncomingMsg *receivedPacket;

  receivedPacket = (IncomingMsg *)event->data;

  incoming[tos_state.current_node] = 0;
  dbg(DBG_PACKET, "SIM_PACKET: Receiving\n");
  current_ptr[tos_state.current_node] = packet_sim_receive_msg(receivedPacket->msg);
  rxState[tos_state.current_node] = RADIO_RX_IDLE;
  event_cleanup(event);
}

#line 257
void   event_receive_packet_create(event_t *event, int node, long long eventTime, IncomingMsg *msg)
#line 257
{
  event->mote = node;
  event->force = 0;
  event->pause = 0;
  event->time = eventTime;
  event->handle = event_receive_packet_handle;
  event->cleanup = event_total_cleanup;
  event->data = msg;
}

#line 192
void   event_start_transmit_handle(event_t *event, struct TOS_state *state)
#line 192
{
  link_t *connectLink;
  TOS_MsgPtr msg = packet_transmitting[tos_state.current_node];
  int transmitTime = preambleLength + msg->length + headerLength;
  bool ack = FALSE;

#line 197
  transmitTime *= byteTransmitTime;
  connectLink = packet_connectivity[tos_state.current_node];
  msg->crc = 1;

  dbg(DBG_PACKET, "SIM_PACKET: Transmitting, transmit time is %i.\n", transmitTime);

  while (connectLink != (void *)0) {
      int mote = connectLink->mote;

#line 205
      if (mote >= tos_state.num_nodes || 
      !tos_state.moteOn[mote]) {
          connectLink = connectLink->next_link;
          continue;
        }

      if (incoming[mote] == (void *)0) {
          if (txState[mote] != RADIO_TX_TRANS) {
              int r;
              double prob;
              event_t *recvEvent = (event_t *)malloc(sizeof(event_t ));
              IncomingMsg *msgEvent = (IncomingMsg *)malloc(sizeof(IncomingMsg ));

              msgEvent->fromID = tos_state.current_node;
              msgEvent->msg = current_ptr[mote];
              nmemcpy(current_ptr[mote], msg, sizeof(TOS_Msg ));

              r = rand() % 100000;
              prob = (double )r / 100000.0;
              if (prob < connectLink->data) {
                  corruptPacket(msgEvent, tos_state.current_node, mote);
                  incoming[mote] = msgEvent;
                  rxState[mote] = RADIO_RX_RECV;
                }
              else {
                  ack = TRUE;
                  incoming[mote] = msgEvent;
                  rxState[mote] = RADIO_RX_RECV;
                  current_ptr[mote]->crc = 1;
                }
              dbg(DBG_PACKET, "SIM_PACKET: Enqueueing receive for %i.\n", mote);
              event_receive_packet_create(recvEvent, mote, tos_state.tos_time + transmitTime, msgEvent);
              queue_insert_event(& tos_state.queue, recvEvent);
#line 237
              ;
            }
        }
      else {
          corruptPacket(incoming[mote], tos_state.current_node, mote);
          if (packet_transmitting[incoming[mote]->fromID] != (void *)0) {
              packet_transmitting[incoming[mote]->fromID]->ack = 0;
            }
        }
      connectLink = connectLink->next_link;
    }
  packet_transmitting[tos_state.current_node] = msg;
  msg->ack = ack;
  dbg(DBG_PACKET, "SIM_PACKET: Enqueueing send done.\n");
  event_send_packet_done_create(event, tos_state.current_node, tos_state.tos_time + transmitTime - 1);
  queue_insert_event(& tos_state.queue, event);
#line 252
  ;
}

static inline 
#line 172
void event_start_transmit_create(event_t *event, int node, long long eventTime)
#line 172
{
  event->mote = node;
  event->force = 0;
  event->pause = 0;
  event->data = (void *)0;
  event->time = eventTime;
  event->handle = event_start_transmit_handle;
  event->cleanup = event_total_cleanup;
}

#line 157
void   event_backoff_handle(event_t *event, struct TOS_state *state)
#line 157
{
  if (incoming[tos_state.current_node] != (void *)0 && rxState[tos_state.current_node] == RADIO_RX_IDLE) {
      int backoffAmount = backoffLow;

#line 160
      backoffAmount += rand() % (backoffHigh - backoffLow);
      event_backoff_create(event, tos_state.current_node, tos_state.tos_time + backoffAmount);
      dbg(DBG_PACKET, "SIM_PACKET: Backoff more: %i.\n", backoffAmount);
      queue_insert_event(& tos_state.queue, event);
#line 163
      ;
    }
  else {
      txState[tos_state.current_node] = RADIO_TX_TRANS;
      event_start_transmit_create(event, tos_state.current_node, tos_state.tos_time + txChangeLatency);
      queue_insert_event(& tos_state.queue, event);
#line 168
      ;
    }
}

# 63 "/root/src/tinyos-1.x/tos/interfaces/Random.nc"
inline static   uint16_t BVirusExtended$Random$rand(void){
#line 63
  unsigned short result;
#line 63

#line 63
  result = RandomLFSR$Random$rand();
#line 63

#line 63
  return result;
#line 63
}
#line 63
# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t BVirusExtended$BCastTimer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0){
#line 59
  unsigned char result;
#line 59

#line 59
  result = TimerM$Timer$start(4, arg_0x9de4698, arg_0x9de47f0);
#line 59

#line 59
  return result;
#line 59
}
#line 59
# 68 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t BVirusExtended$BCastTimer$stop(void){
#line 68
  unsigned char result;
#line 68

#line 68
  result = TimerM$Timer$stop(4);
#line 68

#line 68
  return result;
#line 68
}
#line 68
static inline 
# 160 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
uint8_t BVirusExtended$typeToIndex(uint8_t type)
#line 160
{
  type &= BOMB_OPTION_MASK;
  if (type <= BOMB_CAPSULE_NUM) {
      return type;
    }
  else {
      return BOMB_CAPSULE_INVALID;
    }
}

static inline  
#line 498
TOS_MsgPtr BVirusExtended$BCastReceive$receive(TOS_MsgPtr msg)
#line 498
{
  BombillaCapsuleMsg *cMsg = (BombillaCapsuleMsg *)msg->data;
  BombillaCapsule *capsule = & cMsg->capsule;

  if (BVirusExtended$receiveCapsule(capsule, sizeof(BombillaCapsule ), "bcast") == SUCCESS) {
      BVirusExtended$amBCasting[tos_state.current_node] = TRUE;
      BVirusExtended$bCastIdx[tos_state.current_node] = BVirusExtended$typeToIndex(capsule->type);
      BVirusExtended$BCastTimer$start(TIMER_ONE_SHOT, 10 + BVirusExtended$Random$rand() % 90);
    }
  else {
#line 507
    if (BVirusExtended$amBCasting[tos_state.current_node]) {
        BVirusExtended$BCastTimer$stop();
        BVirusExtended$BCastTimer$start(TIMER_ONE_SHOT, 10 + BVirusExtended$Random$rand() % 90);
      }
    }
#line 511
  return msg;
}

static inline  
#line 490
TOS_MsgPtr BVirusExtended$CapsuleReceive$receive(TOS_MsgPtr msg)
#line 490
{
  BombillaCapsuleMsg *cMsg = (BombillaCapsuleMsg *)msg->data;
  BombillaCapsule *capsule = & cMsg->capsule;

  BVirusExtended$receiveCapsule(capsule, sizeof(BombillaCapsule ), "trickle");
  return msg;
}

static inline 
#line 374
TOS_MsgPtr BVirusExtended$receiveProgram(TOS_MsgPtr msg)
#line 374
{
  dbg(DBG_USR3, "BVirus: Received program vector.\n");
  return msg;
}

static inline 
#line 148
void BVirusExtended$cancelVersionCounter(void)
#line 148
{
  BVirusExtended$versionCancelled[tos_state.current_node] = 1;
}

# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t BVirusExtended$CapsuleTimer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0){
#line 59
  unsigned char result;
#line 59

#line 59
  result = TimerM$Timer$start(3, arg_0x9de4698, arg_0x9de47f0);
#line 59

#line 59
  return result;
#line 59
}
#line 59
static inline 
# 379 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
TOS_MsgPtr BVirusExtended$receiveVector(TOS_MsgPtr msg)
#line 379
{
  uint8_t i;
  bool same = TRUE;
  BombillaVersionMsg *versions = (BombillaVersionMsg *)msg->data;


  for (i = 0; i < BOMB_CAPSULE_NUM; i++) {
      if (BVirusExtended$capsules[tos_state.current_node][i] != (void *)0) {
          if (versions->versions[i] > BVirusExtended$capsules[tos_state.current_node][i]->version) {


              dbg(DBG_USR3, "BVirus: heard newer version vector\n");
              BVirusExtended$tau[tos_state.current_node] = BVirusExtended$TAU_INIT;
              BVirusExtended$newVersionCounter();
              same = FALSE;
              break;
            }
          else {
#line 396
            if (versions->versions[i] < BVirusExtended$capsules[tos_state.current_node][i]->version) {


                dbg(DBG_USR3, "BVirus: heard older version vector, send out capsule.\n");
                BVirusExtended$capsuleTimerThresholds[tos_state.current_node][i] = BVirusExtended$BVIRUS_CAPSULE_INIT;
                BVirusExtended$capsuleTimerCounters[tos_state.current_node][i] = 0;
                if (BVirusExtended$state[tos_state.current_node] != BVirusExtended$BVIRUS_PUSHING) {
                    BVirusExtended$CapsuleTimer$start(TIMER_REPEAT, BVirusExtended$BVIRUS_TIMER_CAPSULE);
                    BVirusExtended$state[tos_state.current_node] = BVirusExtended$BVIRUS_PUSHING;
                  }
                same = FALSE;
                break;
              }
            }
        }
    }
#line 411
  if (same == TRUE) {
      dbg(DBG_USR3, "BVirus: Heard same version vector as mine.\n");
      BVirusExtended$versionHeard[tos_state.current_node]++;
      if (BVirusExtended$versionHeard[tos_state.current_node] >= BVirusExtended$BVIRUS_VERSION_HEARD_THRESHOLD) {
          BVirusExtended$cancelVersionCounter();
        }
    }
  return msg;
}

static inline  TOS_MsgPtr BVirusExtended$VersionReceive$receive(TOS_MsgPtr msg)
#line 421
{
  BombillaVersionMsg *versions = (BombillaVersionMsg *)msg->data;

#line 423
  dbg(DBG_USR3, "Received version packet, type %i\n", versions->type);
  if (versions->type == BOMB_VERSION_VECTOR) {
      return BVirusExtended$receiveVector(msg);
    }
  else {
#line 427
    if (versions->type == BOMB_VERSION_PROGRAM) {
        return BVirusExtended$receiveProgram(msg);
      }
    else {
        return msg;
      }
    }
}

static inline   
# 69 "/root/src/tinyos-1.x/tos/lib/VM/components/AMFilter.nc"
TOS_MsgPtr AMFilter$UpperReceive$default$receive(uint8_t id, TOS_MsgPtr msg)
#line 69
{
  return msg;
}

# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
inline static  TOS_MsgPtr AMFilter$UpperReceive$receive(uint8_t arg_0x9f5ceb0, TOS_MsgPtr arg_0x9e55570){
#line 75
  struct TOS_Msg *result;
#line 75

#line 75
  switch (arg_0x9f5ceb0) {
#line 75
    case AM_BOMBILLAVERSIONMSG:
#line 75
      result = BVirusExtended$VersionReceive$receive(arg_0x9e55570);
#line 75
      break;
#line 75
    case AM_BOMBILLACAPSULEMSG:
#line 75
      result = BVirusExtended$CapsuleReceive$receive(arg_0x9e55570);
#line 75
      break;
#line 75
    case 67:
#line 75
      result = BVirusExtended$BCastReceive$receive(arg_0x9e55570);
#line 75
      break;
#line 75
    default:
#line 75
      result = AMFilter$UpperReceive$default$receive(arg_0x9f5ceb0, arg_0x9e55570);
#line 75
    }
#line 75

#line 75
  return result;
#line 75
}
#line 75
static inline  
# 56 "/root/src/tinyos-1.x/tos/lib/VM/components/AMFilter.nc"
TOS_MsgPtr AMFilter$LowerReceive$receive(uint8_t id, TOS_MsgPtr msg)
#line 56
{

  if ((
#line 57
  msg->addr == TOS_LOCAL_ADDRESS || 
  msg->addr == TOS_BCAST_ADDR) && 
  msg->group == TOS_AM_GROUP) {
      dbg(DBG_AM, "AMFilter: Packet passed AM, signaling.\n");
      return AMFilter$UpperReceive$receive(id, msg);
    }
  else {
      dbg(DBG_AM, "AMFilter: Packet failed AM requirements.\n");
      return msg;
    }
}

# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
inline static  TOS_MsgPtr AMPromiscuous$NonPromiscuous$receive(uint8_t arg_0x9e70b00, TOS_MsgPtr arg_0x9e55570){
#line 75
  struct TOS_Msg *result;
#line 75

#line 75
  result = AMFilter$LowerReceive$receive(arg_0x9e70b00, arg_0x9e55570);
#line 75

#line 75
  return result;
#line 75
}
#line 75
static inline   
# 87 "/root/src/tinyos-1.x/tos/system/NoLeds.nc"
result_t NoLeds$Leds$yellowToggle(void)
#line 87
{
  return SUCCESS;
}

# 131 "/root/src/tinyos-1.x/tos/interfaces/Leds.nc"
inline static   result_t MultiHopGrid$Leds$yellowToggle(void){
#line 131
  unsigned char result;
#line 131

#line 131
  result = NoLeds$Leds$yellowToggle();
#line 131

#line 131
  return result;
#line 131
}
#line 131
static inline  
# 819 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopGrid.nc"
TOS_MsgPtr MultiHopGrid$ReceiveMsg$receive(TOS_MsgPtr Msg)
#line 819
{
  TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];
  MultiHopGrid$RoutePacket *pRP = (MultiHopGrid$RoutePacket *)&pMHMsg->data[0];
  uint16_t saddr;
  uint8_t i;
#line 823
  uint8_t iNbr;

  MultiHopGrid$Leds$yellowToggle();

  saddr = pMHMsg->sourceaddr;

  MultiHopGrid$updateNbrCounters(saddr, pMHMsg->seqno, &iNbr);


  MultiHopGrid$NeighborTbl[tos_state.current_node][iNbr].parent = pRP->parent;
  MultiHopGrid$NeighborTbl[tos_state.current_node][iNbr].hop = pMHMsg->hopcount;
  MultiHopGrid$NeighborTbl[tos_state.current_node][iNbr].cost = pRP->cost;


  if (MultiHopGrid$NeighborTbl[tos_state.current_node][iNbr].childLiveliness > 0 && pRP->parent != TOS_LOCAL_ADDRESS) {
    MultiHopGrid$NeighborTbl[tos_state.current_node][iNbr].childLiveliness = 0;
    }

  for (i = 0; i < pRP->estEntries; i++) {
      if (pRP->estList[i].id == TOS_LOCAL_ADDRESS) {
          MultiHopGrid$NeighborTbl[tos_state.current_node][iNbr].sendEst = pRP->estList[i].receiveEst;
          MultiHopGrid$NeighborTbl[tos_state.current_node][iNbr].liveliness = MultiHopGrid$LIVELINESS;
        }
    }

  return Msg;
}

static inline   
# 274 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
TOS_MsgPtr AMPromiscuous$ReceiveMsg$default$receive(uint8_t id, TOS_MsgPtr msg)
#line 274
{
  return AMPromiscuous$NonPromiscuous$receive(id, msg);
}

# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
inline static  TOS_MsgPtr AMPromiscuous$ReceiveMsg$receive(uint8_t arg_0x9e705c8, TOS_MsgPtr arg_0x9e55570){
#line 75
  struct TOS_Msg *result;
#line 75

#line 75
  switch (arg_0x9e705c8) {
#line 75
    case 3:
#line 75
      result = MultiHopEngineGridM$ReceiveMsg$receive(3, arg_0x9e55570);
#line 75
      break;
#line 75
    case 66:
#line 75
      result = MultiHopEngineGridM$ReceiveMsg$receive(66, arg_0x9e55570);
#line 75
      break;
#line 75
    case AM_MULTIHOPMSG:
#line 75
      result = MultiHopGrid$ReceiveMsg$receive(arg_0x9e55570);
#line 75
      break;
#line 75
    default:
#line 75
      result = AMPromiscuous$ReceiveMsg$default$receive(arg_0x9e705c8, arg_0x9e55570);
#line 75
    }
#line 75

#line 75
  return result;
#line 75
}
#line 75
static inline   
# 292 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopEngineGridM.nc"
result_t MultiHopEngineGridM$Intercept$default$intercept(uint8_t id, TOS_MsgPtr pMsg, void *payload, 
uint16_t payloadLen)
#line 293
{
  return SUCCESS;
}

# 86 "/root/src/tinyos-1.x/tos/interfaces/Intercept.nc"
inline static  result_t MultiHopEngineGridM$Intercept$intercept(uint8_t arg_0xbf486cc0, TOS_MsgPtr arg_0xbf4fbb80, void *arg_0xbf4fbcd8, uint16_t arg_0xbf4fbe30){
#line 86
  unsigned char result;
#line 86

#line 86
  switch (arg_0xbf486cc0) {
#line 86
    case 66:
#line 86
      result = BVirusExtended$InterceptRouted$intercept(arg_0xbf4fbb80, arg_0xbf4fbcd8, arg_0xbf4fbe30);
#line 86
      break;
#line 86
    default:
#line 86
      result = MultiHopEngineGridM$Intercept$default$intercept(arg_0xbf486cc0, arg_0xbf4fbb80, arg_0xbf4fbcd8, arg_0xbf4fbe30);
#line 86
    }
#line 86

#line 86
  return result;
#line 86
}
#line 86
static inline  
# 207 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPuartM.nc"
void OPuartM$Virus$capsuleForce(uint8_t type)
#line 207
{
  return;
}

static inline  
# 155 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbpush1M.nc"
void OPbpush1M$Virus$capsuleForce(uint8_t type)
#line 155
{
  return;
}

static inline  
# 181 "/root/src/tinyos-1.x/tos/lib/VM/contexts/Timer1ContextM.nc"
void Timer1ContextM$Virus$capsuleForce(uint8_t type)
#line 181
{
  return;
}

static inline  
# 161 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetlocal3M.nc"
void OPgetsetlocal3M$Virus$capsuleForce(uint8_t type)
#line 161
{
  return;
}

static inline  
# 231 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetvar4M.nc"
void OPgetsetvar4M$Virus$capsuleForce(uint8_t type)
#line 231
{
  return;
}

static inline  
# 188 "/root/src/tinyos-1.x/tos/lib/VM/contexts/OnceContextM.nc"
void OnceContextM$Virus$capsuleForce(uint8_t type)
#line 188
{
  return;
}

# 86 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaVirus.nc"
inline static  void BVirusExtended$Virus$capsuleForce(uint8_t arg_0xbf5100a0){
#line 86
  OnceContextM$Virus$capsuleForce(arg_0xbf5100a0);
#line 86
  OPgetsetvar4M$Virus$capsuleForce(arg_0xbf5100a0);
#line 86
  OPgetsetlocal3M$Virus$capsuleForce(arg_0xbf5100a0);
#line 86
  Timer1ContextM$Virus$capsuleForce(arg_0xbf5100a0);
#line 86
  OPbpush1M$Virus$capsuleForce(arg_0xbf5100a0);
#line 86
  OPuartM$Virus$capsuleForce(arg_0xbf5100a0);
#line 86
}
#line 86
#line 84
inline static  result_t BVirusExtended$Virus$capsuleInstalled(BombillaCapsule *arg_0xbf51f888){
#line 84
  unsigned char result;
#line 84

#line 84
  result = OnceContextM$Virus$capsuleInstalled(arg_0xbf51f888);
#line 84
  result = rcombine(result, OPgetsetvar4M$Virus$capsuleInstalled(arg_0xbf51f888));
#line 84
  result = rcombine(result, OPgetsetlocal3M$Virus$capsuleInstalled(arg_0xbf51f888));
#line 84
  result = rcombine(result, Timer1ContextM$Virus$capsuleInstalled(arg_0xbf51f888));
#line 84
  result = rcombine(result, OPbpush1M$Virus$capsuleInstalled(arg_0xbf51f888));
#line 84
  result = rcombine(result, OPuartM$Virus$capsuleInstalled(arg_0xbf51f888));
#line 84

#line 84
  return result;
#line 84
}
#line 84
# 101 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextComm.nc"
inline static  void Timer1ContextM$Comm$reboot(void){
#line 101
  BombillaEngineM$Comm$reboot(0);
#line 101
}
#line 101
static inline  
# 203 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPuartM.nc"
result_t OPuartM$Virus$capsuleHeard(uint8_t type)
#line 203
{
  return SUCCESS;
}

static inline  
# 151 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbpush1M.nc"
result_t OPbpush1M$Virus$capsuleHeard(uint8_t type)
#line 151
{
  return SUCCESS;
}

static inline  
# 177 "/root/src/tinyos-1.x/tos/lib/VM/contexts/Timer1ContextM.nc"
result_t Timer1ContextM$Virus$capsuleHeard(uint8_t type)
#line 177
{
  return SUCCESS;
}

static inline  
# 157 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetlocal3M.nc"
result_t OPgetsetlocal3M$Virus$capsuleHeard(uint8_t type)
#line 157
{
  return SUCCESS;
}

static inline  
# 227 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetvar4M.nc"
result_t OPgetsetvar4M$Virus$capsuleHeard(uint8_t type)
#line 227
{
  return SUCCESS;
}

static inline  
# 184 "/root/src/tinyos-1.x/tos/lib/VM/contexts/OnceContextM.nc"
result_t OnceContextM$Virus$capsuleHeard(uint8_t type)
#line 184
{
  return SUCCESS;
}

# 85 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaVirus.nc"
inline static  result_t BVirusExtended$Virus$capsuleHeard(uint8_t arg_0xbf51fc90){
#line 85
  unsigned char result;
#line 85

#line 85
  result = OnceContextM$Virus$capsuleHeard(arg_0xbf51fc90);
#line 85
  result = rcombine(result, OPgetsetvar4M$Virus$capsuleHeard(arg_0xbf51fc90));
#line 85
  result = rcombine(result, OPgetsetlocal3M$Virus$capsuleHeard(arg_0xbf51fc90));
#line 85
  result = rcombine(result, Timer1ContextM$Virus$capsuleHeard(arg_0xbf51fc90));
#line 85
  result = rcombine(result, OPbpush1M$Virus$capsuleHeard(arg_0xbf51fc90));
#line 85
  result = rcombine(result, OPuartM$Virus$capsuleHeard(arg_0xbf51fc90));
#line 85

#line 85
  return result;
#line 85
}
#line 85
# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
inline static  result_t MultiHopEngineGridM$SendMsg$send(uint8_t arg_0xbf484740, uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0){
#line 48
  unsigned char result;
#line 48

#line 48
  result = QueuedSendM$QueueSendMsg$send(arg_0xbf484740, arg_0x9de8758, arg_0x9de88a0, arg_0x9de89f0);
#line 48

#line 48
  return result;
#line 48
}
#line 48
# 71 "/root/src/tinyos-1.x/tos/interfaces/RouteSelect.nc"
inline static  result_t MultiHopEngineGridM$RouteSelect$selectRoute(TOS_MsgPtr arg_0xbf47e7f8, uint8_t arg_0xbf47e940){
#line 71
  unsigned char result;
#line 71

#line 71
  result = MultiHopGrid$RouteSelect$selectRoute(arg_0xbf47e7f8, arg_0xbf47e940);
#line 71

#line 71
  return result;
#line 71
}
#line 71
# 164 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopEngineGridM.nc"
static TOS_MsgPtr MultiHopEngineGridM$mForward(TOS_MsgPtr pMsg, uint8_t id)
#line 164
{
  TOS_MsgPtr pNewBuf = pMsg;

  if ((MultiHopEngineGridM$iFwdBufHead[tos_state.current_node] + 1) % MultiHopEngineGridM$FWD_QUEUE_SIZE == MultiHopEngineGridM$iFwdBufTail[tos_state.current_node]) {
    return pNewBuf;
    }
  if (MultiHopEngineGridM$RouteSelect$selectRoute(pMsg, id) != SUCCESS) {
    return pNewBuf;
    }


  dbg(DBG_ROUTE, "Forwarding packet.\n");
  if (MultiHopEngineGridM$SendMsg$send(id, pMsg->addr, pMsg->length, pMsg) == SUCCESS) {
      pNewBuf = MultiHopEngineGridM$FwdBufList[tos_state.current_node][MultiHopEngineGridM$iFwdBufHead[tos_state.current_node]];
      MultiHopEngineGridM$FwdBufList[tos_state.current_node][MultiHopEngineGridM$iFwdBufHead[tos_state.current_node]] = pMsg;
      MultiHopEngineGridM$iFwdBufHead[tos_state.current_node]++;
#line 179
      MultiHopEngineGridM$iFwdBufHead[tos_state.current_node] %= MultiHopEngineGridM$FWD_QUEUE_SIZE;
    }

  return pNewBuf;
}

static inline 
# 141 "/root/src/tinyos-1.x/tos/lib/Queue/QueuedSendM.nc"
void QueuedSendM$queue_test_func(void)
#line 141
{
  int i = 3;

#line 143
  i += 2;
}

# 106 "/root/src/tinyos-1.x/tos/interfaces/Leds.nc"
inline static   result_t QueuedSendM$Leds$greenToggle(void){
#line 106
  unsigned char result;
#line 106

#line 106
  result = NoLeds$Leds$greenToggle();
#line 106

#line 106
  return result;
#line 106
}
#line 106
# 48 "/root/src/tinyos-1.x/tos/interfaces/SendMsg.nc"
inline static  result_t QueuedSendM$SerialSendMsg$send(uint8_t arg_0xbf4ab368, uint16_t arg_0x9de8758, uint8_t arg_0x9de88a0, TOS_MsgPtr arg_0x9de89f0){
#line 48
  unsigned char result;
#line 48

#line 48
  result = AMPromiscuous$SendMsg$send(arg_0xbf4ab368, arg_0x9de8758, arg_0x9de88a0, arg_0x9de89f0);
#line 48

#line 48
  return result;
#line 48
}
#line 48
static inline  
# 480 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
TOS_MsgPtr BVirusExtended$ReceiveRouted$receive(TOS_MsgPtr msg, 
void *payload, 
uint16_t payloadLen)
#line 482
{
  BombillaCapsuleMsg *cMsg = (BombillaCapsuleMsg *)payload;
  BombillaCapsule *capsule = & cMsg->capsule;

  BVirusExtended$receiveCapsule(capsule, payloadLen, "routed");
  return msg;
}

static inline   
# 213 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopEngineGridM.nc"
TOS_MsgPtr MultiHopEngineGridM$Receive$default$receive(uint8_t id, TOS_MsgPtr msg, void *payload, uint16_t payloadLen)
#line 213
{
  return msg;
}

# 81 "/root/src/tinyos-1.x/tos/interfaces/Receive.nc"
inline static  TOS_MsgPtr MultiHopEngineGridM$Receive$receive(uint8_t arg_0xbf486158, TOS_MsgPtr arg_0xbf4fa3b0, void *arg_0xbf4fa508, uint16_t arg_0xbf4fa660){
#line 81
  struct TOS_Msg *result;
#line 81

#line 81
  switch (arg_0xbf486158) {
#line 81
    case 66:
#line 81
      result = BVirusExtended$ReceiveRouted$receive(arg_0xbf4fa3b0, arg_0xbf4fa508, arg_0xbf4fa660);
#line 81
      result = BVirusExtended$ReceiveRouted$receive(arg_0xbf4fa3b0, arg_0xbf4fa508, arg_0xbf4fa660);
#line 81
      break;
#line 81
    default:
#line 81
      result = MultiHopEngineGridM$Receive$default$receive(arg_0xbf486158, arg_0xbf4fa3b0, arg_0xbf4fa508, arg_0xbf4fa660);
#line 81
    }
#line 81

#line 81
  return result;
#line 81
}
#line 81
static inline  
# 851 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopGrid.nc"
result_t MultiHopGrid$Snoop$intercept(uint8_t id, TOS_MsgPtr Msg, void *Payload, uint16_t Len)
#line 851
{
  TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];
  uint8_t iNbr;

  MultiHopGrid$updateNbrCounters(pMHMsg->sourceaddr, pMHMsg->seqno, &iNbr);




  return SUCCESS;
}

# 86 "/root/src/tinyos-1.x/tos/interfaces/Intercept.nc"
inline static  result_t MultiHopEngineGridM$Snoop$intercept(uint8_t arg_0xbf4871f0, TOS_MsgPtr arg_0xbf4fbb80, void *arg_0xbf4fbcd8, uint16_t arg_0xbf4fbe30){
#line 86
  unsigned char result;
#line 86

#line 86
  result = MultiHopGrid$Snoop$intercept(arg_0xbf4871f0, arg_0xbf4fbb80, arg_0xbf4fbcd8, arg_0xbf4fbe30);
#line 86
  switch (arg_0xbf4871f0) {
#line 86
    case 66:
#line 86
      result = rcombine(result, BVirusExtended$InterceptRouted$intercept(arg_0xbf4fbb80, arg_0xbf4fbcd8, arg_0xbf4fbe30));
#line 86
      break;
#line 86
  }
#line 86

#line 86
  return result;
#line 86
}
#line 86
static inline 
# 202 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
void AMPromiscuous$am_test_func(void)
#line 202
{
  int i = 5;

}

static inline 
# 100 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbpush1M.nc"
uint8_t OPbpush1M$varToLock(uint8_t arg)
#line 100
{
  if (arg == 0) {
      return OPbpush1M$BOMB_BUF_LOCK_1_0;
    }
  else {
#line 104
    if (arg == 1) {
        return OPbpush1M$BOMB_BUF_LOCK_1_1;
      }
    else {
        return 255;
      }
    }
}

static inline  
# 109 "/root/src/tinyos-1.x/tos/lib/VM/components/BLocks.nc"
bool BLocks$Locks$isHeldBy(uint8_t lockNum, 
BombillaContext *context)
#line 110
{
  return BLocks$locks[tos_state.current_node][lockNum].holder == context;
}

# 137 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaLocks.nc"
inline static  bool OPbpush1M$Locks$isHeldBy(uint8_t arg_0x9fbf1b8, BombillaContext *arg_0x9fbf320){
#line 137
  unsigned char result;
#line 137

#line 137
  result = BLocks$Locks$isHeldBy(arg_0x9fbf1b8, arg_0x9fbf320);
#line 137

#line 137
  return result;
#line 137
}
#line 137
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
inline static  result_t OPbpush1M$Error$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840){
#line 94
  unsigned char result;
#line 94

#line 94
  result = BombillaEngineM$Error$error(arg_0x9db46f8, arg_0x9db4840);
#line 94

#line 94
  return result;
#line 94
}
#line 94
# 131 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPbpush1M$Stacks$pushBuffer(BombillaContext *arg_0x9fb6cc8, BombillaDataBuffer *arg_0x9fb6e38){
#line 131
  unsigned char result;
#line 131

#line 131
  result = BStacks$Stacks$pushBuffer(arg_0x9fb6cc8, arg_0x9fb6e38);
#line 131

#line 131
  return result;
#line 131
}
#line 131
#line 158
inline static  BombillaStackVariable *OPsettimer1M$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPsettimer1M$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 68 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t Timer1ContextM$ClockTimer$stop(void){
#line 68
  unsigned char result;
#line 68

#line 68
  result = TimerM$Timer$stop(7);
#line 68

#line 68
  return result;
#line 68
}
#line 68
static inline  
# 189 "/root/src/tinyos-1.x/tos/lib/VM/contexts/Timer1ContextM.nc"
result_t Timer1ContextM$Timer$stop(void)
#line 189
{
  return Timer1ContextM$ClockTimer$stop();
}

# 68 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t OPsettimer1M$Timer$stop(void){
#line 68
  unsigned char result;
#line 68

#line 68
  result = Timer1ContextM$Timer$stop();
#line 68

#line 68
  return result;
#line 68
}
#line 68
#line 59
inline static  result_t Timer1ContextM$ClockTimer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0){
#line 59
  unsigned char result;
#line 59

#line 59
  result = TimerM$Timer$start(7, arg_0x9de4698, arg_0x9de47f0);
#line 59

#line 59
  return result;
#line 59
}
#line 59
static inline  
# 185 "/root/src/tinyos-1.x/tos/lib/VM/contexts/Timer1ContextM.nc"
result_t Timer1ContextM$Timer$start(char type, uint32_t interval)
#line 185
{
  return Timer1ContextM$ClockTimer$start(type, interval);
}

# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t OPsettimer1M$Timer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0){
#line 59
  unsigned char result;
#line 59

#line 59
  result = Timer1ContextM$Timer$start(arg_0x9de4698, arg_0x9de47f0);
#line 59

#line 59
  return result;
#line 59
}
#line 59
# 103 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OP2pushc10M$BombillaStacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
#line 158
inline static  BombillaStackVariable *OP2jumps10M$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OP2jumps10M$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
inline static  result_t OP2jumps10M$BombillaError$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840){
#line 94
  unsigned char result;
#line 94

#line 94
  result = BombillaEngineM$Error$error(arg_0x9db46f8, arg_0x9db4840);
#line 94

#line 94
  return result;
#line 94
}
#line 94
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPgetsetlocal3M$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPgetsetlocal3M$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPgetsetlocal3M$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500){
#line 147
  unsigned char result;
#line 147

#line 147
  result = BStacks$Stacks$pushOperand(arg_0x9fb7390, arg_0x9fb7500);
#line 147

#line 147
  return result;
#line 147
}
#line 147
# 137 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaLocks.nc"
inline static  bool OPgetsetvar4M$Locks$isHeldBy(uint8_t arg_0x9fbf1b8, BombillaContext *arg_0x9fbf320){
#line 137
  unsigned char result;
#line 137

#line 137
  result = BLocks$Locks$isHeldBy(arg_0x9fbf1b8, arg_0x9fbf320);
#line 137

#line 137
  return result;
#line 137
}
#line 137
# 94 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaError.nc"
inline static  result_t OPgetsetvar4M$Error$error(BombillaContext *arg_0x9db46f8, uint8_t arg_0x9db4840){
#line 94
  unsigned char result;
#line 94

#line 94
  result = BombillaEngineM$Error$error(arg_0x9db46f8, arg_0x9db4840);
#line 94

#line 94
  return result;
#line 94
}
#line 94
# 158 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  BombillaStackVariable *OPgetsetvar4M$Stacks$popOperand(BombillaContext *arg_0x9fb7ad0){
#line 158
  struct __nesc_unnamed4349 *result;
#line 158

#line 158
  result = BStacks$Stacks$popOperand(arg_0x9fb7ad0);
#line 158

#line 158
  return result;
#line 158
}
#line 158
# 92 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaTypes.nc"
inline static  uint8_t OPgetsetvar4M$Types$checkTypes(BombillaContext *arg_0x9fdf160, BombillaStackVariable *arg_0x9fdf2e0, uint8_t arg_0x9fdf438){
#line 92
  unsigned char result;
#line 92

#line 92
  result = BStacks$Types$checkTypes(arg_0x9fdf160, arg_0x9fdf2e0, arg_0x9fdf438);
#line 92

#line 92
  return result;
#line 92
}
#line 92
# 147 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaStacks.nc"
inline static  result_t OPgetsetvar4M$Stacks$pushOperand(BombillaContext *arg_0x9fb7390, BombillaStackVariable *arg_0x9fb7500){
#line 147
  unsigned char result;
#line 147

#line 147
  result = BStacks$Stacks$pushOperand(arg_0x9fb7390, arg_0x9fb7500);
#line 147

#line 147
  return result;
#line 147
}
#line 147
#line 103
inline static  result_t OPpushc6M$BombillaStacks$pushValue(BombillaContext *arg_0x9f8fdc0, int16_t arg_0x9f8ff08){
#line 103
  unsigned char result;
#line 103

#line 103
  result = BStacks$Stacks$pushValue(arg_0x9f8fdc0, arg_0x9f8ff08);
#line 103

#line 103
  return result;
#line 103
}
#line 103
# 115 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaQueue.nc"
inline static  result_t BContextSynch$Queue$enqueue(BombillaContext *arg_0x9dcc7c8, BombillaQueue *arg_0x9dcc940, BombillaContext *arg_0x9dccab8){
#line 115
  unsigned char result;
#line 115

#line 115
  result = BQueue$Queue$enqueue(arg_0x9dcc7c8, arg_0x9dcc940, arg_0x9dccab8);
#line 115

#line 115
  return result;
#line 115
}
#line 115
# 154 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextSynch.nc"
inline static  bool OProuteM$Synch$resumeContext(BombillaContext *arg_0x9df17c0, BombillaContext *arg_0x9df1938){
#line 154
  unsigned char result;
#line 154

#line 154
  result = BContextSynch$Synch$resumeContext(arg_0x9df17c0, arg_0x9df1938);
#line 154

#line 154
  return result;
#line 154
}
#line 154
# 129 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaQueue.nc"
inline static  BombillaContext *OPuartM$Queue$dequeue(BombillaContext *arg_0x9dcd0a0, BombillaQueue *arg_0x9dcd218){
#line 129
  struct __nesc_unnamed4356 *result;
#line 129

#line 129
  result = BQueue$Queue$dequeue(arg_0x9dcd0a0, arg_0x9dcd218);
#line 129

#line 129
  return result;
#line 129
}
#line 129
#line 100
inline static  bool OPuartM$Queue$empty(BombillaQueue *arg_0x9dcc300){
#line 100
  unsigned char result;
#line 100

#line 100
  result = BQueue$Queue$empty(arg_0x9dcc300);
#line 100

#line 100
  return result;
#line 100
}
#line 100
static inline  
# 173 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPuartM.nc"
result_t OPuartM$sendDone(void)
#line 173
{
  BombillaContext *sender;

  if (OPuartM$Queue$empty(&OPuartM$sendWaitQueue[tos_state.current_node])) {
#line 176
      return FAIL;
    }
#line 177
  sender = OPuartM$Queue$dequeue(OPuartM$sendingContext[tos_state.current_node], &OPuartM$sendWaitQueue[tos_state.current_node]);
  if (sender->state != BOMB_STATE_SEND_WAIT) {
      OPuartM$Error$error(sender, BOMB_ERROR_QUEUE_INVALID);
    }
  OPuartM$Synch$resumeContext(sender, sender);
  return SUCCESS;
}

static inline  
# 155 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OProuteM.nc"
result_t OProuteM$sendDone(void)
#line 155
{
  if (OProuteM$sendingContext[tos_state.current_node] == (void *)0) {
#line 156
      return SUCCESS;
    }
#line 157
  if (OProuteM$sendingContext[tos_state.current_node]->state == BOMB_STATE_SEND_WAIT) {
      if (OProuteM$Send$send(&OProuteM$msg[tos_state.current_node], OProuteM$msg[tos_state.current_node].length)) {
          dbg(DBG_USR1, "VM (%i): Routing capsule succeeded.\n", (int )OProuteM$sendingContext[tos_state.current_node]->which);
          OProuteM$sendingContext[tos_state.current_node]->state = BOMB_STATE_SENDING;
          OProuteM$Synch$releaseLocks(OProuteM$sendingContext[tos_state.current_node], OProuteM$sendingContext[tos_state.current_node]);
          OProuteM$Synch$yieldContext(OProuteM$sendingContext[tos_state.current_node]);
        }
      else {
          OProuteM$sendingContext[tos_state.current_node]->state = BOMB_STATE_SEND_WAIT;
          OProuteM$sendingContext[tos_state.current_node] = OProuteM$sendingContext[tos_state.current_node];
          OProuteM$Synch$releaseLocks(OProuteM$sendingContext[tos_state.current_node], OProuteM$sendingContext[tos_state.current_node]);
          OProuteM$Synch$yieldContext(OProuteM$sendingContext[tos_state.current_node]);
        }
    }
  return SUCCESS;
}

# 65 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
inline static  result_t AMPromiscuous$sendDone(void){
#line 65
  unsigned char result;
#line 65

#line 65
  result = OProuteM$sendDone();
#line 65
  result = rcombine(result, OPuartM$sendDone());
#line 65

#line 65
  return result;
#line 65
}
#line 65
# 88 "/root/src/tinyos-1.x/tos/platform/pc/hardware.h"
__inline __nesc_atomic_t  __nesc_atomic_start(void )
{
  return 0;
}

__inline void  __nesc_atomic_end(__nesc_atomic_t oldSreg)
{
}

# 103 "/root/src/tinyos-1.x/beta/TOSSIM-packet/Nido.nc"
void   event_boot_handle(event_t *fevent, 
struct TOS_state *fstate)
#line 104
{
  char timeVal[128];

#line 106
  printTime(timeVal, 128);


  if (!tos_state.cancelBoot[tos_state.current_node]) {
      dbg(DBG_BOOT, "BOOT: Mote booting at time %s.\n", timeVal);
      nido_start_mote((uint16_t )tos_state.current_node);
    }
  else 
#line 112
    {
      dbg(DBG_BOOT, "BOOT: Boot cancelled at time %s since mote turned off.\n", 
      timeVal);
    }
}

static inline  
# 132 "/root/src/tinyos-1.x/tos/lib/VM/contexts/Timer1ContextM.nc"
result_t Timer1ContextM$Comm$analyzeLockSets(BombillaCapsuleBuffer *capsules[])
#line 132
{
  return SUCCESS;
}

static inline  
# 154 "/root/src/tinyos-1.x/tos/lib/VM/contexts/OnceContextM.nc"
result_t OnceContextM$Comm$analyzeLockSets(BombillaCapsuleBuffer *capsules[])
#line 154
{
  return SUCCESS;
}

static inline   
# 212 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
result_t BombillaEngineM$Comm$default$analyzeLockSets(uint8_t type, BombillaCapsuleBuffer *caps[])
#line 212
{
  return SUCCESS;
}

# 96 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextComm.nc"
inline static  result_t BombillaEngineM$Comm$analyzeLockSets(uint8_t arg_0x9ddbd00, BombillaCapsuleBuffer *arg_0x9dd4ec8[]){
#line 96
  unsigned char result;
#line 96

#line 96
  switch (arg_0x9ddbd00) {
#line 96
    case 0:
#line 96
      result = Timer1ContextM$Comm$analyzeLockSets(arg_0x9dd4ec8);
#line 96
      break;
#line 96
    case 1:
#line 96
      result = OnceContextM$Comm$analyzeLockSets(arg_0x9dd4ec8);
#line 96
      break;
#line 96
    default:
#line 96
      result = BombillaEngineM$Comm$default$analyzeLockSets(arg_0x9ddbd00, arg_0x9dd4ec8);
#line 96
    }
#line 96

#line 96
  return result;
#line 96
}
#line 96
static inline  
# 95 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
result_t BContextSynch$StdControl$init(void)
#line 95
{
  BContextSynch$Queue$init(&BContextSynch$readyQueue[tos_state.current_node]);
  return SUCCESS;
}

# 89 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaQueue.nc"
inline static  result_t OPuartM$Queue$init(BombillaQueue *arg_0x9defdb8){
#line 89
  unsigned char result;
#line 89

#line 89
  result = BQueue$Queue$init(arg_0x9defdb8);
#line 89

#line 89
  return result;
#line 89
}
#line 89
static inline  
# 106 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPuartM.nc"
result_t OPuartM$StdControl$init(void)
#line 106
{
  OPuartM$Queue$init(&OPuartM$sendWaitQueue[tos_state.current_node]);
  return SUCCESS;
}

# 57 "/root/src/tinyos-1.x/tos/interfaces/Random.nc"
inline static   result_t OPrandM$Random$init(void){
#line 57
  unsigned char result;
#line 57

#line 57
  result = RandomLFSR$Random$init();
#line 57

#line 57
  return result;
#line 57
}
#line 57
static inline  
# 92 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPrandM.nc"
result_t OPrandM$StdControl$init(void)
#line 92
{
  OPrandM$Random$init();
  return SUCCESS;
}

static inline  
# 185 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
void BombillaEngineM$Comm$registerCapsule(uint8_t type, BombillaCapsuleBuffer *capsule)
#line 185
{
  BombillaEngineM$capsules[tos_state.current_node][type] = capsule;
}

# 90 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextComm.nc"
inline static  void Timer1ContextM$Comm$registerCapsule(BombillaCapsuleBuffer *arg_0x9dd4a30){
#line 90
  BombillaEngineM$Comm$registerCapsule(0, arg_0x9dd4a30);
#line 90
}
#line 90
# 80 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaAnalysis.nc"
inline static  void Timer1ContextM$Analysis$analyzeCapsuleVars(BombillaCapsuleBuffer *arg_0x9dd1c28){
#line 80
  BContextSynch$Analysis$analyzeCapsuleVars(arg_0x9dd1c28);
#line 80
}
#line 80
# 82 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaVirus.nc"
inline static  result_t Timer1ContextM$Virus$registerCapsule(uint8_t arg_0xbf51f2e8, BombillaCapsule *arg_0xbf51f450){
#line 82
  unsigned char result;
#line 82

#line 82
  result = BVirusExtended$Virus$registerCapsule(arg_0xbf51f2e8, arg_0xbf51f450);
#line 82

#line 82
  return result;
#line 82
}
#line 82
# 63 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t Timer1ContextM$SubControlTimer$init(void){
#line 63
  unsigned char result;
#line 63

#line 63
  result = TimerM$StdControl$init();
#line 63

#line 63
  return result;
#line 63
}
#line 63
static inline  
# 100 "/root/src/tinyos-1.x/tos/lib/VM/contexts/Timer1ContextM.nc"
result_t Timer1ContextM$StdControl$init(void)
#line 100
{
  int pc = 0;

#line 102
  Timer1ContextM$SubControlTimer$init();

  Timer1ContextM$clockContext[tos_state.current_node].which = BOMB_CAPSULE_TIMER1;
  Timer1ContextM$clockContext[tos_state.current_node].state = BOMB_STATE_HALT;
  Timer1ContextM$clockContext[tos_state.current_node].rootCapsule.capsule.type = Timer1ContextM$clockContext[tos_state.current_node].which;
  Timer1ContextM$clockContext[tos_state.current_node].rootCapsule.capsule.type |= BOMB_OPTION_FORWARD;

  Timer1ContextM$Virus$registerCapsule(Timer1ContextM$clockContext[tos_state.current_node].rootCapsule.capsule.type, 
  & Timer1ContextM$clockContext[tos_state.current_node].rootCapsule.capsule);

  Timer1ContextM$clockContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = OPhalt;
  Timer1ContextM$clockContext[tos_state.current_node].rootCapsule.capsule.options = 0;
  Timer1ContextM$clockContext[tos_state.current_node].rootCapsule.capsule.version = 0;

  Timer1ContextM$Analysis$analyzeCapsuleVars(& Timer1ContextM$clockContext[tos_state.current_node].rootCapsule);
  Timer1ContextM$Comm$registerCapsule(& Timer1ContextM$clockContext[tos_state.current_node].rootCapsule);
  return SUCCESS;
}

static inline  
# 98 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetlocal3M.nc"
result_t OPgetsetlocal3M$StdControl$init(void)
#line 98
{
  int i;
#line 99
  int j;

#line 100
  for (i = 0; i < BOMB_CAPSULE_NUM; i++) {
      for (j = 0; j < 1 << 3; j++) {
          OPgetsetlocal3M$vars[tos_state.current_node][i][j].type = BOMB_TYPE_VALUE;
          OPgetsetlocal3M$vars[tos_state.current_node][i][j].value.var = 0;
        }
    }
  return SUCCESS;
}

static inline  
# 122 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetvar4M.nc"
result_t OPgetsetvar4M$StdControl$init(void)
#line 122
{
  int i;

#line 124
  for (i = 0; i < OPgetsetvar4M$BOMB_LOCK_4_COUNT; i++) {
      OPgetsetvar4M$heap[tos_state.current_node][(int )i].type = BOMB_TYPE_VALUE;
      OPgetsetvar4M$heap[tos_state.current_node][(int )i].value.var = 0;
    }
  return SUCCESS;
}

static inline  
# 174 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OProuteM.nc"
void OProuteM$Comm$registerCapsule(BombillaCapsuleBuffer *capsule)
#line 174
{
  OProuteM$onceCapsule[tos_state.current_node] = capsule;
}

# 90 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaContextComm.nc"
inline static  void OnceContextM$Comm$registerCapsule(BombillaCapsuleBuffer *arg_0x9dd4a30){
#line 90
  BombillaEngineM$Comm$registerCapsule(1, arg_0x9dd4a30);
#line 90
  OProuteM$Comm$registerCapsule(arg_0x9dd4a30);
#line 90
}
#line 90
# 80 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaAnalysis.nc"
inline static  void OnceContextM$Analysis$analyzeCapsuleVars(BombillaCapsuleBuffer *arg_0x9dd1c28){
#line 80
  BContextSynch$Analysis$analyzeCapsuleVars(arg_0x9dd1c28);
#line 80
}
#line 80
# 82 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaVirus.nc"
inline static  result_t OnceContextM$Virus$registerCapsule(uint8_t arg_0xbf51f2e8, BombillaCapsule *arg_0xbf51f450){
#line 82
  unsigned char result;
#line 82

#line 82
  result = BVirusExtended$Virus$registerCapsule(arg_0xbf51f2e8, arg_0xbf51f450);
#line 82

#line 82
  return result;
#line 82
}
#line 82
static inline  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/contexts/OnceContextM.nc"
result_t OnceContextM$StdControl$init(void)
#line 94
{
  OnceContextM$onceContext[tos_state.current_node].which = BOMB_CAPSULE_ONCE;
  OnceContextM$onceContext[tos_state.current_node].currentCapsule = & OnceContextM$onceContext[tos_state.current_node].rootCapsule;
  OnceContextM$onceContext[tos_state.current_node].state = BOMB_STATE_HALT;
  OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.type = OnceContextM$onceContext[tos_state.current_node].which;
  OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.type |= BOMB_OPTION_FORWARD;

  OnceContextM$Virus$registerCapsule(OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.type, 
  & OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule);

  OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.options = 0;
  OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.version = 0;
  if (TOS_LOCAL_ADDRESS == 210) {
      int pc = 0;
      struct timeval tv;

#line 109
      gettimeofday(&tv, (void *)0);
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.version = 1;
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = OPid;
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = OP2pushc10;
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = 210;
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = OPeq;
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = OPnot;
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = OP2jumps10;
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = 16;
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = OP2pushc10;
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = tv.tv_usec * 5187 % 399 + 1;
      sleep(1);
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = OProute;
      gettimeofday(&tv, (void *)0);
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = OP2pushc10;
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = tv.tv_usec * 3419 % 399 + 1;
      sleep(1);
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = OProute;
      gettimeofday(&tv, (void *)0);
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = OP2pushc10;
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = tv.tv_usec * 6531 % 399 + 1;
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = OProute;
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule.code[pc++] = OPhalt;
    }

  OnceContextM$Analysis$analyzeCapsuleVars(& OnceContextM$onceContext[tos_state.current_node].rootCapsule);
  OnceContextM$Comm$registerCapsule(& OnceContextM$onceContext[tos_state.current_node].rootCapsule);
  return SUCCESS;
}

# 63 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t BombillaEngineM$SubControl$init(void){
#line 63
  unsigned char result;
#line 63

#line 63
  result = OnceContextM$StdControl$init();
#line 63
  result = rcombine(result, OPgetsetvar4M$StdControl$init());
#line 63
  result = rcombine(result, OPgetsetlocal3M$StdControl$init());
#line 63
  result = rcombine(result, Timer1ContextM$StdControl$init());
#line 63
  result = rcombine(result, OPrandM$StdControl$init());
#line 63
  result = rcombine(result, OPuartM$StdControl$init());
#line 63
  result = rcombine(result, BContextSynch$StdControl$init());
#line 63
  result = rcombine(result, TimerM$StdControl$init());
#line 63
  result = rcombine(result, AMPromiscuous$Control$init());
#line 63

#line 63
  return result;
#line 63
}
#line 63
# 89 "/root/src/tinyos-1.x/tos/lib/VM/interfaces/BombillaQueue.nc"
inline static  result_t BombillaEngineM$Queue$init(BombillaQueue *arg_0x9defdb8){
#line 89
  unsigned char result;
#line 89

#line 89
  result = BQueue$Queue$init(arg_0x9defdb8);
#line 89

#line 89
  return result;
#line 89
}
#line 89
static inline   
# 67 "/root/src/tinyos-1.x/tos/platform/pc/LedsC.nc"
result_t LedsC$Leds$init(void)
#line 67
{
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 68
    {
      LedsC$ledsOn[tos_state.current_node] = 0;
      dbg(DBG_BOOT, "LEDS: initialized.\n");
      LedsC$updateLeds();
    }
#line 72
    __nesc_atomic_end(__nesc_atomic); }
  return SUCCESS;
}

# 56 "/root/src/tinyos-1.x/tos/interfaces/Leds.nc"
inline static   result_t BombillaEngineM$Leds$init(void){
#line 56
  unsigned char result;
#line 56

#line 56
  result = LedsC$Leds$init();
#line 56

#line 56
  return result;
#line 56
}
#line 56
static inline  
# 112 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
result_t BombillaEngineM$StdControl$init(void)
#line 112
{
  uint16_t i;

  dbg(DBG_BOOT, "VM: Bombilla initializing.\n");
  BombillaEngineM$Leds$init();
  BombillaEngineM$Queue$init(&BombillaEngineM$runQueue[tos_state.current_node]);
  BombillaEngineM$SubControl$init();

  for (i = 0; i < 3; i++) {
      BombillaEngineM$Comm$analyzeLockSets(i, BombillaEngineM$capsules[tos_state.current_node]);
    }

  BombillaEngineM$inErrorState[tos_state.current_node] = FALSE;
  return SUCCESS;
}

# 57 "/root/src/tinyos-1.x/tos/interfaces/Random.nc"
inline static   result_t BVirusExtended$Random$init(void){
#line 57
  unsigned char result;
#line 57

#line 57
  result = RandomLFSR$Random$init();
#line 57

#line 57
  return result;
#line 57
}
#line 57
static inline  
# 91 "/root/src/tinyos-1.x/tos/lib/Queue/QueuedSendM.nc"
result_t QueuedSendM$StdControl$init(void)
#line 91
{
  int i;

#line 93
  for (i = 0; i < QueuedSendM$MESSAGE_QUEUE_SIZE; i++) {
      QueuedSendM$msgqueue[tos_state.current_node][i].length = 0;
    }



  QueuedSendM$retransmit[tos_state.current_node] = TRUE;

  QueuedSendM$enqueue_next[tos_state.current_node] = 0;
  QueuedSendM$dequeue_next[tos_state.current_node] = 0;
  QueuedSendM$fQueueIdle[tos_state.current_node] = TRUE;
  return SUCCESS;
}

# 63 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t BVirusExtended$SubControl$init(void){
#line 63
  unsigned char result;
#line 63

#line 63
  result = AMPromiscuous$Control$init();
#line 63
  result = rcombine(result, QueuedSendM$StdControl$init());
#line 63

#line 63
  return result;
#line 63
}
#line 63
static inline  
# 170 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
result_t BVirusExtended$StdControl$init(void)
#line 170
{
  int i;

#line 172
  BVirusExtended$SubControl$init();
  BVirusExtended$Random$init();

  for (i = 0; i < BOMB_CAPSULE_NUM; i++) {
      BVirusExtended$capsuleTimerCounters[tos_state.current_node][i] = 0;
      BVirusExtended$capsuleTimerThresholds[tos_state.current_node][i] = BVirusExtended$BVIRUS_CAPSULE_MAX + 1;
      BVirusExtended$capsules[tos_state.current_node][i] = (void *)0;
    }
  BVirusExtended$state[tos_state.current_node] = BVirusExtended$BVIRUS_IDLE;
  BVirusExtended$tau[tos_state.current_node] = BVirusExtended$TAU_MAX;

  BVirusExtended$sendPtr[tos_state.current_node] = (TOS_MsgPtr )&BVirusExtended$sendMessage[tos_state.current_node];
  BVirusExtended$receivePtr[tos_state.current_node] = (TOS_MsgPtr )&BVirusExtended$receiveMsg[tos_state.current_node];
  BVirusExtended$newVersionCounter();
  dbg(DBG_USR3, "BVirus initialized.\n");
  BVirusExtended$sendBusy[tos_state.current_node] = FALSE;
  BVirusExtended$capsuleBusy[tos_state.current_node] = FALSE;

  return SUCCESS;
}

# 63 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t Nido$StdControl$init(void){
#line 63
  unsigned char result;
#line 63

#line 63
  result = BVirusExtended$StdControl$init();
#line 63
  result = rcombine(result, BombillaEngineM$StdControl$init());
#line 63

#line 63
  return result;
#line 63
}
#line 63
inline static  result_t AMPromiscuous$TimerControl$init(void){
#line 63
  unsigned char result;
#line 63

#line 63
  result = TimerM$StdControl$init();
#line 63

#line 63
  return result;
#line 63
}
#line 63
static inline   
# 128 "/root/src/tinyos-1.x/tos/platform/pc/HPLClock.nc"
result_t HPLClock$Clock$setRate(char interval, char scale)
#line 128
{
  HPLClock$mscale[tos_state.current_node] = scale;
  HPLClock$minterval[tos_state.current_node] = interval;
  TOSH_clock_set_rate(interval, scale);
  return SUCCESS;
}

# 96 "/root/src/tinyos-1.x/tos/interfaces/Clock.nc"
inline static   result_t TimerM$Clock$setRate(char arg_0x9e0dad0, char arg_0x9e0dc10){
#line 96
  unsigned char result;
#line 96

#line 96
  result = HPLClock$Clock$setRate(arg_0x9e0dad0, arg_0x9e0dc10);
#line 96

#line 96
  return result;
#line 96
}
#line 96
static inline  
# 55 "/root/src/tinyos-1.x/tos/platform/pc/UARTNoCRCPacketM.nc"
result_t UARTNoCRCPacketM$Control$init(void)
#line 55
{
  return SUCCESS;
}

# 63 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t AMPromiscuous$UARTControl$init(void){
#line 63
  unsigned char result;
#line 63

#line 63
  result = UARTNoCRCPacketM$Control$init();
#line 63

#line 63
  return result;
#line 63
}
#line 63
static inline  
# 64 "/root/src/tinyos-1.x/beta/TOSSIM-packet/TossimPacketM.nc"
result_t TossimPacketM$Control$init(void)
#line 64
{
  TossimPacketM$bufferPtr[tos_state.current_node] = &TossimPacketM$buffer[tos_state.current_node];

  return SUCCESS;
}

# 63 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t AMPromiscuous$RadioControl$init(void){
#line 63
  unsigned char result;
#line 63

#line 63
  result = TossimPacketM$Control$init();
#line 63

#line 63
  return result;
#line 63
}
#line 63
static inline  
# 82 "/root/src/tinyos-1.x/tos/system/TimerM.nc"
result_t TimerM$StdControl$start(void)
#line 82
{
  return SUCCESS;
}

static inline  
# 100 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
result_t BContextSynch$StdControl$start(void)
#line 100
{
  return SUCCESS;
}

static inline  
# 111 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPuartM.nc"
result_t OPuartM$StdControl$start(void)
#line 111
{
  return SUCCESS;
}

static inline  
# 97 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPrandM.nc"
result_t OPrandM$StdControl$start(void)
#line 97
{
  return SUCCESS;
}

# 70 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t Timer1ContextM$SubControlTimer$start(void){
#line 70
  unsigned char result;
#line 70

#line 70
  result = TimerM$StdControl$start();
#line 70

#line 70
  return result;
#line 70
}
#line 70
static inline  
# 121 "/root/src/tinyos-1.x/tos/lib/VM/contexts/Timer1ContextM.nc"
result_t Timer1ContextM$StdControl$start(void)
#line 121
{
  Timer1ContextM$SubControlTimer$start();
  return SUCCESS;
}

static inline  
# 109 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetlocal3M.nc"
result_t OPgetsetlocal3M$StdControl$start(void)
#line 109
{
  return SUCCESS;
}

static inline  
# 131 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetvar4M.nc"
result_t OPgetsetvar4M$StdControl$start(void)
#line 131
{
  return SUCCESS;
}

# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t OnceContextM$Timer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0){
#line 59
  unsigned char result;
#line 59

#line 59
  result = TimerM$Timer$start(8, arg_0x9de4698, arg_0x9de47f0);
#line 59

#line 59
  return result;
#line 59
}
#line 59
static inline  
# 143 "/root/src/tinyos-1.x/tos/lib/VM/contexts/OnceContextM.nc"
result_t OnceContextM$StdControl$start(void)
#line 143
{
  if (TOS_LOCAL_ADDRESS == 210) {
      OnceContextM$Timer$start(TIMER_ONE_SHOT, 20000);
    }
  return SUCCESS;
}

# 70 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t BombillaEngineM$SubControl$start(void){
#line 70
  unsigned char result;
#line 70

#line 70
  result = OnceContextM$StdControl$start();
#line 70
  result = rcombine(result, OPgetsetvar4M$StdControl$start());
#line 70
  result = rcombine(result, OPgetsetlocal3M$StdControl$start());
#line 70
  result = rcombine(result, Timer1ContextM$StdControl$start());
#line 70
  result = rcombine(result, OPrandM$StdControl$start());
#line 70
  result = rcombine(result, OPuartM$StdControl$start());
#line 70
  result = rcombine(result, BContextSynch$StdControl$start());
#line 70
  result = rcombine(result, TimerM$StdControl$start());
#line 70
  result = rcombine(result, AMPromiscuous$Control$start());
#line 70

#line 70
  return result;
#line 70
}
#line 70
static inline  
# 128 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
result_t BombillaEngineM$StdControl$start(void)
#line 128
{
  dbg(DBG_BOOT, "VM: Starting.\n");
  BombillaEngineM$SubControl$start();
  return SUCCESS;
}

# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t BVirusExtended$VersionTimer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0){
#line 59
  unsigned char result;
#line 59

#line 59
  result = TimerM$Timer$start(2, arg_0x9de4698, arg_0x9de47f0);
#line 59

#line 59
  return result;
#line 59
}
#line 59
static inline  
# 107 "/root/src/tinyos-1.x/tos/lib/Queue/QueuedSendM.nc"
result_t QueuedSendM$StdControl$start(void)
#line 107
{
  return SUCCESS;
}

# 70 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t BVirusExtended$SubControl$start(void){
#line 70
  unsigned char result;
#line 70

#line 70
  result = AMPromiscuous$Control$start();
#line 70
  result = rcombine(result, QueuedSendM$StdControl$start());
#line 70

#line 70
  return result;
#line 70
}
#line 70
static inline  
# 193 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
result_t BVirusExtended$StdControl$start(void)
#line 193
{
  BVirusExtended$SubControl$start();
  BVirusExtended$state[tos_state.current_node] = BVirusExtended$BVIRUS_PULLING;
  dbg(DBG_USR3, "BVirus started.\n");
  BVirusExtended$VersionTimer$start(TIMER_REPEAT, BVirusExtended$BVIRUS_TIMER_VERSION);
  dbg(DBG_USR3, "BVirus version timer started.\n");
  return SUCCESS;
}

# 70 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t Nido$StdControl$start(void){
#line 70
  unsigned char result;
#line 70

#line 70
  result = BVirusExtended$StdControl$start();
#line 70
  result = rcombine(result, BombillaEngineM$StdControl$start());
#line 70

#line 70
  return result;
#line 70
}
#line 70
inline static  result_t AMPromiscuous$TimerControl$start(void){
#line 70
  unsigned char result;
#line 70

#line 70
  result = TimerM$StdControl$start();
#line 70

#line 70
  return result;
#line 70
}
#line 70
static inline  
# 59 "/root/src/tinyos-1.x/tos/platform/pc/UARTNoCRCPacketM.nc"
result_t UARTNoCRCPacketM$Control$start(void)
#line 59
{
  return SUCCESS;
}

# 70 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t AMPromiscuous$UARTControl$start(void){
#line 70
  unsigned char result;
#line 70

#line 70
  result = UARTNoCRCPacketM$Control$start();
#line 70

#line 70
  return result;
#line 70
}
#line 70
static inline  
# 70 "/root/src/tinyos-1.x/beta/TOSSIM-packet/TossimPacketM.nc"
result_t TossimPacketM$Control$start(void)
#line 70
{

  return SUCCESS;
}

# 70 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t AMPromiscuous$RadioControl$start(void){
#line 70
  unsigned char result;
#line 70

#line 70
  result = TossimPacketM$Control$start();
#line 70

#line 70
  return result;
#line 70
}
#line 70
# 59 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t AMPromiscuous$ActivityTimer$start(char arg_0x9de4698, uint32_t arg_0x9de47f0){
#line 59
  unsigned char result;
#line 59

#line 59
  result = TimerM$Timer$start(1, arg_0x9de4698, arg_0x9de47f0);
#line 59

#line 59
  return result;
#line 59
}
#line 59
# 41 "/root/src/tinyos-1.x/tos/interfaces/PowerManagement.nc"
inline static   uint8_t AMPromiscuous$PowerManagement$adjustPower(void){
#line 41
  unsigned char result;
#line 41

#line 41
  result = HPLPowerManagementM$PowerManagement$adjustPower();
#line 41

#line 41
  return result;
#line 41
}
#line 41
static inline 
# 129 "/root/src/tinyos-1.x/tos/system/tos.h"
result_t rcombine4(result_t r1, result_t r2, result_t r3, 
result_t r4)
{
  return rcombine(r1, rcombine(r2, rcombine(r3, r4)));
}

# 107 "/root/src/tinyos-1.x/tos/platform/pc/dbg.c"
void dbg_help(void )
#line 107
{
  int i = 0;

#line 109
  printf("Known dbg modes: ");

  while (dbg_nametab[i].d_name != (void *)0) {
      printf("%s", dbg_nametab[i].d_name);
      if (dbg_nametab[i + 1].d_name != (void *)0) {
          printf(", ");
        }
      i++;
    }

  printf("\n");
}

static inline 
# 73 "/root/src/tinyos-1.x/beta/TOSSIM-packet/Nido.nc"
void Nido$usage(char *progname)
#line 73
{
  fprintf(stderr, "Usage: %s [-h|--help] [options] num_nodes_total\n", progname);
  exit(-1);
}

# 58 "/root/src/tinyos-1.x/tos/platform/pc/dbg.c"
void dbg_add_mode(const char *name)
#line 58
{
  int cancel;
  TOS_dbg_mode_names *mode;

  if (*name == '-') {
      cancel = 1;
      name++;
    }
  else {
    cancel = 0;
    }
  for (mode = dbg_nametab; mode->d_name != (void *)0; mode++) 
    if (strcmp(name, mode->d_name) == 0) {
      break;
      }
#line 72
  if (mode->d_name == (void *)0) {
      fprintf(stderr, "Warning: Unknown debug option: "
      "\"%s\"\n", name);
      return;
    }

  if (cancel) {
    dbg_modes &= ~ mode->d_mode;
    }
  else {
#line 81
    dbg_modes |= mode->d_mode;
    }
}

#line 84
void dbg_add_modes(const char *modes)
#line 84
{
  char env[256];
  char *name;

  strncpy(env, modes, sizeof env);
  for (name = strtok(env, ","); name; name = strtok((void *)0, ",")) 
    dbg_add_mode(name);
}

void dbg_init(void )
#line 93
{
  const char *dbg_env;

  dbg_modes = DBG_NONE;

  dbg_env = getenv("DBG");
  if (!dbg_env) {
      dbg_modes = DBG_DEFAULT;
      return;
    }

  dbg_add_modes(dbg_env);
}

static inline 
# 40 "/root/src/tinyos-1.x/tos/platform/pc/tos.c"
void handle_signal(int sig)
#line 40
{
  if ((sig == 2 || sig == 19) && signaled == 0) {
      char ftime[128];

#line 43
      printTime(ftime, 128);
      printf("Exiting on SIGINT at %s.\n", ftime);


      signaled = 1;
      exit(0);
    }
}

static inline void init_signals(void )
#line 52
{
  struct sigaction action;

#line 54
  action.__sigaction_handler.sa_handler = handle_signal;
  sigemptyset(& action.sa_mask);
  action.sa_flags = 0;
  sigaction(2, &action, (void *)0);
  signal(13, (__sighandler_t )1);
}

static inline 
# 342 "/root/src/tinyos-1.x/tos/platform/pc/external_comm.c"
void event_command_cleanup(event_t *event)
#line 342
{
  incoming_command_data_t *cmdData = (incoming_command_data_t *)event->data;

#line 344
  free(cmdData->msg);
  free(cmdData->payLoad);
  event_total_cleanup(event);
}

static inline  
# 278 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
TOS_MsgPtr AMPromiscuous$UARTReceive$receive(TOS_MsgPtr packet)
#line 278
{
  return prom_received(packet);
}

# 75 "/root/src/tinyos-1.x/tos/interfaces/ReceiveMsg.nc"
inline static  TOS_MsgPtr Nido$UARTReceiveMsg$receive(TOS_MsgPtr arg_0x9e55570){
#line 75
  struct TOS_Msg *result;
#line 75

#line 75
  result = AMPromiscuous$UARTReceive$receive(arg_0x9e55570);
#line 75

#line 75
  return result;
#line 75
}
#line 75
# 373 "/root/src/tinyos-1.x/beta/TOSSIM-packet/Nido.nc"
TOS_MsgPtr   NIDO_received_uart(TOS_MsgPtr packet)
#line 373
{
  packet->crc = 1;
  return Nido$UARTReceiveMsg$receive(packet);
}

#line 363
TOS_MsgPtr   NIDO_received_radio(TOS_MsgPtr packet)
#line 363
{
  packet->crc = 1;
  return Nido$RadioReceiveMsg$receive(packet);
}

static inline  
# 86 "/root/src/tinyos-1.x/tos/system/TimerM.nc"
result_t TimerM$StdControl$stop(void)
#line 86
{
  TimerM$mState[tos_state.current_node] = 0;
  TimerM$mInterval[tos_state.current_node] = TimerM$maxTimerInterval;
  TimerM$setIntervalFlag[tos_state.current_node] = 0;
  return SUCCESS;
}

static inline  
# 104 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
result_t BContextSynch$StdControl$stop(void)
#line 104
{
  return SUCCESS;
}

static inline  
# 115 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPuartM.nc"
result_t OPuartM$StdControl$stop(void)
#line 115
{
  return SUCCESS;
}

static inline  
# 101 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPrandM.nc"
result_t OPrandM$StdControl$stop(void)
#line 101
{
  return SUCCESS;
}

# 78 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t Timer1ContextM$SubControlTimer$stop(void){
#line 78
  unsigned char result;
#line 78

#line 78
  result = TimerM$StdControl$stop();
#line 78

#line 78
  return result;
#line 78
}
#line 78
static inline  
# 126 "/root/src/tinyos-1.x/tos/lib/VM/contexts/Timer1ContextM.nc"
result_t Timer1ContextM$StdControl$stop(void)
#line 126
{
  Timer1ContextM$SubControlTimer$stop();
  Timer1ContextM$ClockTimer$stop();
  return SUCCESS;
}

static inline  
# 113 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetlocal3M.nc"
result_t OPgetsetlocal3M$StdControl$stop(void)
#line 113
{
  return SUCCESS;
}

static inline  
# 135 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetvar4M.nc"
result_t OPgetsetvar4M$StdControl$stop(void)
#line 135
{
  return SUCCESS;
}

static inline  
# 150 "/root/src/tinyos-1.x/tos/lib/VM/contexts/OnceContextM.nc"
result_t OnceContextM$StdControl$stop(void)
#line 150
{
  return SUCCESS;
}

# 78 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t BombillaEngineM$SubControl$stop(void){
#line 78
  unsigned char result;
#line 78

#line 78
  result = OnceContextM$StdControl$stop();
#line 78
  result = rcombine(result, OPgetsetvar4M$StdControl$stop());
#line 78
  result = rcombine(result, OPgetsetlocal3M$StdControl$stop());
#line 78
  result = rcombine(result, Timer1ContextM$StdControl$stop());
#line 78
  result = rcombine(result, OPrandM$StdControl$stop());
#line 78
  result = rcombine(result, OPuartM$StdControl$stop());
#line 78
  result = rcombine(result, BContextSynch$StdControl$stop());
#line 78
  result = rcombine(result, TimerM$StdControl$stop());
#line 78
  result = rcombine(result, AMPromiscuous$Control$stop());
#line 78

#line 78
  return result;
#line 78
}
#line 78
static inline  
# 134 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
result_t BombillaEngineM$StdControl$stop(void)
#line 134
{
  dbg(DBG_BOOT, "VM: Stopping.\n");
  BombillaEngineM$SubControl$stop();
  return SUCCESS;
}

static inline  
# 110 "/root/src/tinyos-1.x/tos/lib/Queue/QueuedSendM.nc"
result_t QueuedSendM$StdControl$stop(void)
#line 110
{
  return SUCCESS;
}

# 78 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t BVirusExtended$SubControl$stop(void){
#line 78
  unsigned char result;
#line 78

#line 78
  result = AMPromiscuous$Control$stop();
#line 78
  result = rcombine(result, QueuedSendM$StdControl$stop());
#line 78

#line 78
  return result;
#line 78
}
#line 78
# 68 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t BVirusExtended$VersionTimer$stop(void){
#line 68
  unsigned char result;
#line 68

#line 68
  result = TimerM$Timer$stop(2);
#line 68

#line 68
  return result;
#line 68
}
#line 68
static inline  
# 202 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
result_t BVirusExtended$StdControl$stop(void)
#line 202
{
  BVirusExtended$VersionTimer$stop();
  BVirusExtended$CapsuleTimer$stop();
  dbg(DBG_USR3, "BVirus stopped.\n");
  return BVirusExtended$SubControl$stop();
}

# 78 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t Nido$StdControl$stop(void){
#line 78
  unsigned char result;
#line 78

#line 78
  result = BVirusExtended$StdControl$stop();
#line 78
  result = rcombine(result, BombillaEngineM$StdControl$stop());
#line 78

#line 78
  return result;
#line 78
}
#line 78
# 349 "/root/src/tinyos-1.x/beta/TOSSIM-packet/Nido.nc"
void   nido_stop_mote(uint16_t moteID)
#line 349
{

  tos_state.cancelBoot[moteID] = 1;

  if (tos_state.moteOn[moteID] && moteID < tos_state.num_nodes) {
      tos_state.moteOn[moteID] = 0;
      tos_state.current_node = moteID;
      { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 356
        TOS_LOCAL_ADDRESS = tos_state.current_node;
#line 356
        __nesc_atomic_end(__nesc_atomic); }
      tos_state.node_state[moteID].time = tos_state.tos_time;
      Nido$StdControl$stop();
    }
}

static inline 
# 467 "/root/src/tinyos-1.x/tos/platform/pc/external_comm.c"
void event_command_in_handle(event_t *event, 
struct TOS_state *state)
#line 468
{
  incoming_command_data_t *cmdData = (incoming_command_data_t *)event->data;
  GuiMsg *msg = cmdData->msg;

#line 471
  dbg_clear(DBG_SIM, "SIM: Handling incoming command type %d for mote %d\n", msg->msgType, msg->moteID);

  switch (msg->msgType) {

      case AM_TURNONMOTECOMMAND: 
        dbg_clear(DBG_SIM, "SIM: Turning on mote %d\n", msg->moteID);
      nido_start_mote(msg->moteID);
      break;

      case AM_TURNOFFMOTECOMMAND: 
        dbg_clear(DBG_SIM, "SIM: Turning off mote %d\n", msg->moteID);
      nido_stop_mote(msg->moteID);
      break;

      case AM_RADIOMSGSENDCOMMAND: 
        {
          RadioMsgSendCommand *rmsg = (RadioMsgSendCommand *)cmdData->payLoad;
          TOS_MsgPtr buffer;

          dbg_clear(DBG_SIM, "SIM: Enqueueing radio message for mote %d (payloadlen %d)\n", msg->moteID, msg->payLoadLen);
          if (external_comm_buffers_[msg->moteID] == (void *)0) {
            external_comm_buffers_[msg->moteID] = &external_comm_msgs_[msg->moteID];
            }
#line 493
          buffer = external_comm_buffers_[msg->moteID];
          memcpy(buffer, & rmsg->message, msg->payLoadLen);
          buffer->group = TOS_AM_GROUP;
          external_comm_buffers_[msg->moteID] = NIDO_received_radio(buffer);
        }
      break;

      case AM_UARTMSGSENDCOMMAND: 
        {
          UARTMsgSendCommand *umsg = (UARTMsgSendCommand *)cmdData->payLoad;
          TOS_MsgPtr buffer;
          int len = msg->payLoadLen > sizeof(TOS_Msg ) ? sizeof(TOS_Msg ) : msg->payLoadLen;

          dbg_clear(DBG_SIM, "SIM: Enqueueing UART message for mote %d (payloadlen %d)\n", msg->moteID, msg->payLoadLen);
          if (external_comm_buffers_[msg->moteID] == (void *)0) {
            external_comm_buffers_[msg->moteID] = &external_comm_msgs_[msg->moteID];
            }
#line 509
          buffer = external_comm_buffers_[msg->moteID];

          memcpy(buffer, & umsg->message, len);
          buffer->group = TOS_AM_GROUP;
          external_comm_buffers_[msg->moteID] = NIDO_received_uart(buffer);
        }
      break;

      case AM_INTERRUPTCOMMAND: 
        {
          InterruptEvent interruptEvent;
          InterruptCommand *pcmd = (InterruptCommand *)cmdData->payLoad;

#line 521
          interruptEvent.id = pcmd->id;
          dbg_clear(DBG_TEMP, "\nSIM: Interrupt command, id: %i.\n\n", pcmd->id);
          sendTossimEvent(TOS_BCAST_ADDR, AM_INTERRUPTEVENT, 
          tos_state.tos_time, &interruptEvent);
          break;
        }

      default: 
        dbg_clear(DBG_SIM, "SIM: Unrecognizable command type received from TinyViz %i\n", msg->msgType);
      break;
    }

  event_cleanup(event);
}

static inline 
#line 350
void event_command_in_create(event_t *event, 
GuiMsg *msg, 
char *payLoad)
#line 352
{
  incoming_command_data_t *data = (incoming_command_data_t *)malloc(sizeof(incoming_command_data_t ));

#line 354
  data->msg = msg;
  data->payLoad = payLoad;

  event->mote = (int )(msg->moteID & 0xffff);
  if (event->mote < TOSNODES && 
  event->mote >= 0) {
      event->force = 1;
    }
  event->pause = 1;
  event->data = data;
  event->time = msg->time;
  event->handle = event_command_in_handle;
  event->cleanup = event_command_cleanup;
}

# 54 "/root/src/tinyos-1.x/tos/platform/pc/dbg.c"
void dbg_set(TOS_dbg_mode modes)
#line 54
{
  dbg_modes = modes;
}

static inline 
# 80 "/root/src/tinyos-1.x/tos/platform/pc/tos.c"
void rate_checkpoint(void)
#line 80
{
  rate_checkpoint_time = tos_state.tos_time;
  gettimeofday(&startTime, (void *)0);
}

static inline 
#line 76
void set_rate_value(double rate)
#line 76
{
  rate_value = rate;
}

# 407 "/root/src/tinyos-1.x/beta/TOSSIM-packet/Nido.nc"
void   set_sim_rate(uint32_t rate)
#line 407
{
  double realRate = (double )rate;

#line 409
  realRate /= 1000.0;
  dbg_clear(DBG_SIM, "SIM: Setting rate to %lf\n", realRate);
  set_rate_value(realRate);
  rate_checkpoint();
}

static inline 
# 106 "/root/src/tinyos-1.x/tos/platform/pc/adc_model.c"
void set_adc_value(int moteID, uint8_t port, uint16_t value)
#line 106
{
  if (moteID >= TOSNODES || moteID < 0) {
      dbg(DBG_ERROR, "GENERIC_ADC_MODEL: trying to set value with invalid parameters: [moteID = %d] [port = %d]", moteID, port);
      return;
    }
  pthread_mutex_lock(&adcValuesLock);
  adcValues[moteID][(int )port] = value;
  pthread_mutex_unlock(&adcValuesLock);
}

static inline 
# 550 "/root/src/tinyos-1.x/tos/platform/pc/rfm_model.c"
void set_link_prob_value(uint16_t moteID1, uint16_t moteID2, double prob)
#line 550
{
  link_t *current_link;
  link_t *new_link;

  pthread_mutex_lock(&radioConnectivityLock);
  current_link = radio_connectivity[moteID1];
  dbg(DBG_SIM, "RFM: MDW: Setting loss prob %d->%d to %0.3f\n", moteID1, moteID2, prob);
  while (current_link) {
      if (current_link->mote == moteID2) {
          current_link->data = prob;
          pthread_mutex_unlock(&radioConnectivityLock);
          return;
        }
      current_link = current_link->next_link;
    }
  new_link = allocate_link(moteID2);
  new_link->next_link = radio_connectivity[moteID1];
  new_link->data = prob;
  radio_connectivity[moteID1] = new_link;
  pthread_mutex_unlock(&radioConnectivityLock);
}

static inline 
# 372 "/root/src/tinyos-1.x/tos/platform/pc/external_comm.c"
int processCommand(int clifd, GuiMsg *msg, char *payLoad, 
unsigned char **replyMsg, int *replyLen)
#line 373
{
  int ret = 0;

#line 375
  switch (msg->msgType) {

      case AM_SETLINKPROBCOMMAND: 
        {
          SetLinkProbCommand *linkmsg = (SetLinkProbCommand *)payLoad;
          double prob = (double )linkmsg->scaledProb / 10000;

#line 381
          set_link_prob_value(msg->moteID, linkmsg->moteReceiver, prob);
          break;
        }
      case AM_SETADCPORTVALUECOMMAND: 
        {
          SetADCPortValueCommand *adcmsg = (SetADCPortValueCommand *)payLoad;

#line 387
          set_adc_value(msg->moteID, adcmsg->port, adcmsg->value);
          break;
        }
      case AM_SETRATECOMMAND: 
        {
          SetRateCommand *ratemsg = (SetRateCommand *)payLoad;

#line 393
          set_sim_rate(ratemsg->rate);
          break;
        }
      case AM_VARIABLERESOLVECOMMAND: 
        {
          VariableResolveResponse varResult;
          VariableResolveCommand *rmsg = (VariableResolveCommand *)payLoad;


          if (
#line 401
          __nesc_nido_resolve(msg->moteID, (char *)rmsg->name, 
          & varResult.addr, & varResult.length) != 0) 
            {
              varResult.addr = 0;
              varResult.length = -1;
            }

          dbg_clear(DBG_SIM, "SIM: Resolving variable %s for mote %d: 0x%x %d\n", 
          rmsg->name, msg->moteID, varResult.addr, varResult.length);

          buildTossimEvent(TOS_BCAST_ADDR, AM_VARIABLERESOLVERESPONSE, 
          tos_state.tos_time, &varResult, replyMsg, replyLen);
          ret = 1;
          break;
        }
      case AM_VARIABLEREQUESTCOMMAND: 
        {
          VariableRequestResponse varResult;
          VariableRequestCommand *rmsg = (VariableRequestCommand *)payLoad;
          uint8_t *ptr = (uint8_t *)rmsg->addr;

#line 421
          memcpy(varResult.value, ptr, rmsg->length);
          varResult.length = rmsg->length;
          buildTossimEvent(TOS_BCAST_ADDR, AM_VARIABLEREQUESTRESPONSE, 
          tos_state.tos_time, &varResult, replyMsg, replyLen);
          ret = 1;
          break;
        }

      case AM_GETMOTECOUNTCOMMAND: 
        {
          int i;
          GetMoteCountResponse countResponse;

          countResponse.totalMotes = tos_state.num_nodes;
          bzero(& countResponse.bitmask, sizeof  countResponse.bitmask);

          for (i = 0; i < TOSNODES; i++) {
              countResponse.bitmask[i / 8] |= 1 << (7 - i % 8);
            }

          buildTossimEvent(TOS_BCAST_ADDR, AM_GETMOTECOUNTRESPONSE, 
          tos_state.tos_time, &countResponse, replyMsg, replyLen);
          ret = 1;
          break;
        }
      case AM_SETDBGCOMMAND: 
        {
          SetDBGCommand *cmd = (SetDBGCommand *)payLoad;

#line 449
          dbg_set(cmd->dbg);
          break;
        }
      default: 
        {


          event_t *event = (event_t *)malloc(sizeof(event_t ));

#line 457
          event_command_in_create(event, msg, payLoad);
          dbg(DBG_SIM, "SIM: Enqueuing command event 0x%lx\n", (unsigned long )event);
          queue_insert_event(& tos_state.queue, event);
#line 459
          ;
        }
    }

  return ret;
}

static inline 
#line 538
int readTossimCommand(int clifd)
#line 538
{
  GuiMsg *msg;
  unsigned char *header;
  char *payLoad = (void *)0;
  int curlen = 0;
  int rval;
  unsigned char ack;
  int reply;
  unsigned char *replyMsg = 0;
  int replyLen = 0;

  dbg_clear(DBG_SIM, "SIM: Reading command from client fd %d\n", clifd);

  header = (unsigned char *)malloc(14);
  msg = (GuiMsg *)malloc(sizeof(GuiMsg ));

  curlen = 0;
  while (curlen < 14) {
      dbg_clear(DBG_SIM, "SIM: Reading in GuiMsg header of size %d with length %d\n", 14, curlen);
      rval = read(clifd, header + curlen, 14 - curlen);
      if (rval <= 0) {
          dbg_clear(DBG_SIM, "SIM: Closing client socket %d.\n", clifd);
          free(msg);
          close(clifd);
          goto done;
        }
      else 
#line 563
        {
          curlen += rval;
        }
    }


  msg->msgType = ntohs(* (unsigned short *)&header[0]);
  msg->moteID = ntohs(* (unsigned short *)&header[2]);
  msg->time = __extension__ ({
#line 571
    union __nesc_unnamed4380 {
#line 571
      __extension__ unsigned long long int __ll;
#line 571
      unsigned long int __l[2];
    } 
#line 571
    __w;
#line 571
    union __nesc_unnamed4380 __r;

#line 571
    if (__builtin_constant_p(* (long long *)&header[4])) {
#line 571
      __r.__ll = ((((((((* (long long *)&header[4] & 0xff00000000000000ull) >> 56) | ((* (long long *)&header[4] & 0x00ff000000000000ull) >> 40)) | ((* (long long *)&header[4] & 0x0000ff0000000000ull) >> 24)) | ((* (long long *)&header[4] & 0x000000ff00000000ull) >> 8)) | ((* (long long *)&header[4] & 0x00000000ff000000ull) << 8)) | ((* (long long *)&header[4] & 0x0000000000ff0000ull) << 24)) | ((* (long long *)&header[4] & 0x000000000000ff00ull) << 40)) | ((* (long long *)&header[4] & 0x00000000000000ffull) << 56);
      }
    else 
#line 571
      {
#line 571
        __w.__ll = * (long long *)&header[4];
#line 571
        __r.__l[0] = __extension__ ({
#line 571
          register unsigned int __v;
#line 571
          register unsigned int __x = __w.__l[1];

#line 571
          if (__builtin_constant_p(__x)) {
#line 571
            __v = ((((__x & 0xff000000) >> 24) | ((__x & 0x00ff0000) >> 8)) | ((__x & 0x0000ff00) << 8)) | ((__x & 0x000000ff) << 24);
            }
          else {
#line 571
             __asm ("rorw $8, %w0;""rorl $16, %0;""rorw $8, %w0" : "=r"(__v) : "0"(__x) : "cc");
            }
#line 571
          __v;
        }
        );
#line 571
        __r.__l[1] = __extension__ ({
#line 571
          register unsigned int __v;
#line 571
          register unsigned int __x = __w.__l[0];

#line 571
          if (__builtin_constant_p(__x)) {
#line 571
            __v = ((((__x & 0xff000000) >> 24) | ((__x & 0x00ff0000) >> 8)) | ((__x & 0x0000ff00) << 8)) | ((__x & 0x000000ff) << 24);
            }
          else {
#line 571
             __asm ("rorw $8, %w0;""rorl $16, %0;""rorw $8, %w0" : "=r"(__v) : "0"(__x) : "cc");
            }
#line 571
          __v;
        }
        );
      }
#line 571
    __r.__ll;
  }
  );
#line 572
  msg->payLoadLen = ntohs(* (unsigned short *)&header[12]);
  dbg_clear(DBG_SIM, "SIM: Command type %d mote %d time 0x%lx payloadlen %d\n", msg->msgType, msg->moteID, msg->time, msg->payLoadLen);
  if (msg->time < tos_state.tos_time) {
      msg->time = tos_state.tos_time;
    }


  if (msg->payLoadLen > 0) {
      payLoad = (char *)malloc(msg->payLoadLen);
      curlen = 0;
      while (curlen < msg->payLoadLen) {
          dbg(DBG_SIM, "SIM: Reading in GuiMsg payload of size %d with length %d\n", msg->payLoadLen, curlen);
          rval = read(clifd, payLoad + curlen, msg->payLoadLen - curlen);
          if (rval <= 0) {
              dbg(DBG_SIM, "SIM: Closing client socket %d.\n", clifd);
              free(msg);
              free(payLoad);
              goto done;
            }
          else 
#line 590
            {
              curlen += rval;
              dbg(DBG_SIM, "SIM: Read from command port, total: %d, need %d\n", curlen, msg->payLoadLen - curlen);
            }
        }
    }

  if (msg->moteID < tos_state.num_nodes) {
      reply = processCommand(clifd, msg, payLoad, &replyMsg, &replyLen);
    }
  else {
      dbg(DBG_SIM | DBG_ERROR, "SIM: Received command for invalid mote: %i\n", (int )msg->moteID);
    }

  do {
      rval = write(clifd, &ack, 1);
      if (rval < 0) {
          dbg(DBG_SIM, "SIM: Closing client socket %d.\n", clifd);
          goto done;
        }
    }
  while (
#line 610
  rval != 1);

  if (reply) {
      dbg(DBG_SIM, "SIM: Sending %d byte reply.\n", replyLen);
      writeTossimEvent(replyMsg, replyLen, clifd);
      free(replyMsg);
    }

  done: 
    return 0;
}

static inline 



void *commandReadThreadFunc(void *arg)
#line 626
{
  int i;
#line 627
  int found = 0;
  fd_set readset;
#line 628
  fd_set exceptset;
  int highest;
  int numclients;
  struct timeval tv;

  dbg_clear(DBG_SIM, "SIM: commandReadThread running.\n");

  while (1) {

      pthread_mutex_lock(&commandClientsLock);
      found = 0;
      while (!found) {
          do {
#line 640
              int __d0;
#line 640
              int __d1;

#line 640
               __asm volatile ("cld; rep; stosl" : "=c"(__d0), "=D"(__d1) : "a"(0), "0"(sizeof(fd_set ) / sizeof(__fd_mask )), "1"(&(&readset)->__fds_bits[0]) : "memory");}
          while (
#line 640
          0);
          do {
#line 641
              int __d0;
#line 641
              int __d1;

#line 641
               __asm volatile ("cld; rep; stosl" : "=c"(__d0), "=D"(__d1) : "a"(0), "0"(sizeof(fd_set ) / sizeof(__fd_mask )), "1"(&(&exceptset)->__fds_bits[0]) : "memory");}
          while (
#line 641
          0);
          highest = -1;
          numclients = 0;
          for (i = 0; i < 4; i++) {
              if (commandClients[i] != -1) {
                  if (commandClients[i] > highest) {
#line 646
                    highest = commandClients[i];
                    }
#line 647
                  ;
                   __asm volatile ("btsl %1,%0" : "=m"((&readset)->__fds_bits[commandClients[i] / (8 * sizeof(__fd_mask ))]) : "r"((int )commandClients[i] % (8 * sizeof(__fd_mask ))) : "cc", "memory");
                   __asm volatile ("btsl %1,%0" : "=m"((&exceptset)->__fds_bits[commandClients[i] / (8 * sizeof(__fd_mask ))]) : "r"((int )commandClients[i] % (8 * sizeof(__fd_mask ))) : "cc", "memory");
                  found = 1;
                  numclients++;
                }
            }
          if (!found) {
              ;
              pthread_cond_wait(&commandClientsCond, &commandClientsLock);
            }
        }
      pthread_mutex_unlock(&commandClientsLock);

      ;

      tv.tv_sec = 5;
      tv.tv_usec = 0;
      if (select(highest + 1, &readset, (void *)0, &exceptset, &tv) < 0) {
          dbg_clear(DBG_SIM, "SIM: commandReadThreadFunc: error in select(): %s\n", strerror(*__errno_location()));
        }
      ;

      pthread_mutex_lock(&commandClientsLock);

      for (i = 0; i < 4; i++) {






          if (commandClients[i] != -1 && __extension__ ({
#line 679
            register char __result;

#line 679
             __asm volatile ("btl %1,%2 ; setcb %b0" : "=q"(__result) : "r"((int )commandClients[i] % (8 * sizeof(__fd_mask ))), "m"((&readset)->__fds_bits[commandClients[i] / (8 * sizeof(__fd_mask ))]) : "cc");__result;
          }
          )) 
#line 679
            {
              if (readTossimCommand(commandClients[i]) < 0) {
                  close(commandClients[i]);
                  commandClients[i] = -1;
                }
            }
          if (commandClients[i] != -1 && __extension__ ({
#line 685
            register char __result;

#line 685
             __asm volatile ("btl %1,%2 ; setcb %b0" : "=q"(__result) : "r"((int )commandClients[i] % (8 * sizeof(__fd_mask ))), "m"((&exceptset)->__fds_bits[commandClients[i] / (8 * sizeof(__fd_mask ))]) : "cc");__result;
          }
          )) 
#line 685
            {

              close(commandClients[i]);
              commandClients[i] = -1;
            }
        }
      pthread_mutex_unlock(&commandClientsLock);
    }
  return 0;
}

static inline 
# 72 "/root/src/tinyos-1.x/tos/platform/pc/tos.c"
double get_rate_value(void)
#line 72
{
  return rate_value;
}

# 415 "/root/src/tinyos-1.x/beta/TOSSIM-packet/Nido.nc"
uint32_t   get_sim_rate(void)
#line 415
{
  return (uint32_t )(1000.0 * get_rate_value());
}

static inline 
# 262 "/root/src/tinyos-1.x/tos/platform/pc/external_comm.c"
void sendInitEvent(int clifd)
#line 262
{
  TossimInitEvent initEv;
  unsigned char *msg;
  int total_size;

  memset((char *)&initEv, 0, sizeof(TossimInitEvent ));
  initEv.numMotes = tos_state.num_nodes;
  initEv.radioModel = tos_state.radioModel;
  initEv.rate = get_sim_rate();
  buildTossimEvent(0, AM_TOSSIMINITEVENT, 
  tos_state.tos_time, &initEv, &msg, &total_size);
  writeTossimEvent(msg, total_size, clifd);
  free(msg);
}

static inline 



void *clientAcceptThreadFunc(void *arg)
#line 281
{
  int clifd;
  fd_set acceptset;
  int highest = commandServerSocket > eventServerSocket ? commandServerSocket : eventServerSocket;

  dbg_clear(DBG_SIM, "SIM: clientAcceptThread running.\n");

  while (1) {
      do {
#line 289
          int __d0;
#line 289
          int __d1;

#line 289
           __asm volatile ("cld; rep; stosl" : "=c"(__d0), "=D"(__d1) : "a"(0), "0"(sizeof(fd_set ) / sizeof(__fd_mask )), "1"(&(&acceptset)->__fds_bits[0]) : "memory");}
      while (
#line 289
      0);
       __asm volatile ("btsl %1,%0" : "=m"((&acceptset)->__fds_bits[commandServerSocket / (8 * sizeof(__fd_mask ))]) : "r"((int )commandServerSocket % (8 * sizeof(__fd_mask ))) : "cc", "memory");
       __asm volatile ("btsl %1,%0" : "=m"((&acceptset)->__fds_bits[eventServerSocket / (8 * sizeof(__fd_mask ))]) : "r"((int )eventServerSocket % (8 * sizeof(__fd_mask ))) : "cc", "memory");
      ;
      if (select(highest + 1, &acceptset, (void *)0, (void *)0, (void *)0) < 0) {
          ;
        }
      ;


      if (__extension__ ({
#line 299
        register char __result;

#line 299
         __asm volatile ("btl %1,%2 ; setcb %b0" : "=q"(__result) : "r"((int )commandServerSocket % (8 * sizeof(__fd_mask ))), "m"((&acceptset)->__fds_bits[commandServerSocket / (8 * sizeof(__fd_mask ))]) : "cc");__result;
      }
      )) 
#line 299
        {
          ;
          clifd = acceptConnection(commandServerSocket);
          ;
          pthread_mutex_lock(&commandClientsLock);
          addClient(commandClients, clifd);
          pthread_cond_broadcast(&commandClientsCond);
          pthread_mutex_unlock(&commandClientsLock);
        }


      if (__extension__ ({
#line 310
        register char __result;

#line 310
         __asm volatile ("btl %1,%2 ; setcb %b0" : "=q"(__result) : "r"((int )eventServerSocket % (8 * sizeof(__fd_mask ))), "m"((&acceptset)->__fds_bits[eventServerSocket / (8 * sizeof(__fd_mask ))]) : "cc");__result;
      }
      )) 
#line 310
        {
          ;
          clifd = acceptConnection(eventServerSocket);
          ;
          pthread_mutex_lock(&eventClientsLock);
          addClient(eventClients, clifd);
          sendInitEvent(clifd);
          pthread_cond_broadcast(&eventClientsCond);
          pthread_mutex_unlock(&eventClientsLock);
        }
    }
  return 0;
}

static inline 
#line 107
void initializeSockets(void)
#line 107
{
  int i;

#line 109
  dbg_clear(DBG_SIM, "SIM: Initializing sockets\n");

  pthread_mutex_init(& tos_state.pause_lock, (void *)0);
  pthread_cond_init(& tos_state.pause_cond, (void *)0);
  pthread_cond_init(& tos_state.pause_ack_cond, (void *)0);

  for (i = 0; i < 4; i++) {
      commandClients[i] = -1;
      eventClients[i] = -1;
    }
  commandServerSocket = createServerSocket(10584);
  eventServerSocket = createServerSocket(10585);
  pthread_mutex_init(&eventClientsLock, (void *)0);
  pthread_mutex_init(&commandClientsLock, (void *)0);
  pthread_cond_init(&commandClientsCond, (void *)0);
  pthread_cond_init(&eventClientsCond, (void *)0);
  pthread_create(&clientAcceptThread, (void *)0, clientAcceptThreadFunc, (void *)0);
  pthread_create(&commandReadThread, (void *)0, commandReadThreadFunc, (void *)0);
  socketsInitialized = 1;
}

static inline  
# 63 "/root/src/tinyos-1.x/tos/platform/pc/UARTNoCRCPacketM.nc"
result_t UARTNoCRCPacketM$Control$stop(void)
#line 63
{
  return SUCCESS;
}

# 78 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t AMPromiscuous$UARTControl$stop(void){
#line 78
  unsigned char result;
#line 78

#line 78
  result = UARTNoCRCPacketM$Control$stop();
#line 78

#line 78
  return result;
#line 78
}
#line 78
static inline  
# 74 "/root/src/tinyos-1.x/beta/TOSSIM-packet/TossimPacketM.nc"
result_t TossimPacketM$Control$stop(void)
#line 74
{

  return SUCCESS;
}

# 78 "/root/src/tinyos-1.x/tos/interfaces/StdControl.nc"
inline static  result_t AMPromiscuous$RadioControl$stop(void){
#line 78
  unsigned char result;
#line 78

#line 78
  result = TossimPacketM$Control$stop();
#line 78

#line 78
  return result;
#line 78
}
#line 78
# 68 "/root/src/tinyos-1.x/tos/interfaces/Timer.nc"
inline static  result_t AMPromiscuous$ActivityTimer$stop(void){
#line 68
  unsigned char result;
#line 68

#line 68
  result = TimerM$Timer$stop(1);
#line 68

#line 68
  return result;
#line 68
}
#line 68
static inline 
# 124 "/root/src/tinyos-1.x/tos/system/tos.h"
result_t rcombine3(result_t r1, result_t r2, result_t r3)
{
  return rcombine(r1, rcombine(r2, r3));
}

static inline 
# 124 "/root/src/tinyos-1.x/tos/platform/pc/rfm_model.c"
link_t *simple_neighbors(int moteID)
#line 124
{
  link_t *thelink;

#line 126
  pthread_mutex_lock(&radioConnectivityLock);
  thelink = radio_connectivity[moteID];
  pthread_mutex_unlock(&radioConnectivityLock);
  return thelink;
}

static inline 
#line 78
bool simple_connected(int moteID1, int moteID2)
#line 78
{
  return TRUE;
}

static inline 
#line 112
char simple_hears(int moteID)
#line 112
{







  return radio_active[moteID] > 0 ? 1 : 0;
}

static inline 
#line 101
void simple_stops_transmit(int moteID)
#line 101
{
  int i;

  if (transmitting[moteID]) {
      transmitting[moteID] = 0;
      for (i = 0; i < tos_state.num_nodes; i++) {
          radio_active[i]--;
        }
    }
}

static inline 
#line 92
void simple_transmit(int moteID, char bit)
#line 92
{
  int i;

  transmitting[moteID] = bit;
  for (i = 0; i < tos_state.num_nodes; i++) {
      radio_active[i] += bit;
    }
}

static inline 
#line 82
void simple_init(void)
#line 82
{
  int i;

#line 84
  pthread_mutex_init(&radioConnectivityLock, (void *)0);
  adjacency_list_init();
  static_one_cell_init();
  for (i = 0; i < tos_state.num_nodes; i++) {
      radio_active[i] = 0;
    }
}

static inline 
#line 132
rfm_model *create_simple_model(void)
#line 132
{
  rfm_model *model = (rfm_model *)malloc(sizeof(rfm_model ));

#line 134
  model->init = simple_init;
  model->transmit = simple_transmit;
  model->stop_transmit = simple_stops_transmit;
  model->hears = simple_hears;
  model->connected = simple_connected;
  model->neighbors = simple_neighbors;
  return model;
}

static inline 
#line 512
link_t *lossy_neighbors(int moteID)
#line 512
{
  link_t *thelink;

#line 514
  pthread_mutex_lock(&radioConnectivityLock);
  thelink = radio_connectivity[moteID];
  pthread_mutex_unlock(&radioConnectivityLock);
  return thelink;
}

static inline 
#line 313
bool lossy_connected(int moteID1, int moteID2)
#line 313
{




  link_t *current_link;

  pthread_mutex_lock(&radioConnectivityLock);
  current_link = radio_connectivity[moteID1];
  dbg(DBG_TEMP, "connections for %i\n", moteID1);
  while (current_link) {
      if (current_link->mote == moteID2 && 
      current_link->data < 1.0) {
          dbg(DBG_TEMP, "connected to %i\n", moteID2);
          pthread_mutex_unlock(&radioConnectivityLock);
          return TRUE;
        }
      current_link = current_link->next_link;
    }
  pthread_mutex_unlock(&radioConnectivityLock);
  return FALSE;
}

static inline 
#line 371
char lossy_hears(int moteID)
#line 371
{
  char bit_heard = radio_active[moteID] > 0 ? 1 : 0;

#line 373
  if (radio_idle_state[moteID]) {
      int r = rand() % 100000;
      double prob = (double )r / 100000.0;

#line 376
      if (prob < noise_prob) {
          bit_heard = bit_heard ? 0 : 1;
        }
    }
  else {
      short temp_heard = radio_heard[moteID];

#line 382
      temp_heard <<= 1;
      temp_heard |= bit_heard;
      radio_heard[moteID] = temp_heard;
      if ((radio_heard[moteID] & IDLE_STATE_MASK) == 0) {
          radio_idle_state[moteID] = 1;
        }
    }
  return bit_heard;
}

static inline 
#line 357
void lossy_stop_transmit(int moteID)
#line 357
{
  link_t *current_link;

  pthread_mutex_lock(&radioConnectivityLock);
  current_link = radio_connectivity[moteID];
  transmitting[moteID] = 0;
  while (current_link) {
      radio_active[current_link->mote] -= current_link->bit;
      current_link->bit = 0;
      current_link = current_link->next_link;
    }
  pthread_mutex_unlock(&radioConnectivityLock);
}

static inline 
#line 336
void lossy_transmit(int moteID, char bit)
#line 336
{
  link_t *current_link;

  pthread_mutex_lock(&radioConnectivityLock);
  current_link = radio_connectivity[moteID];
  transmitting[moteID] = bit;
  while (current_link) {
      int r = rand() % 100000;
      double prob = (double )r / 100000.0;
      int tmp_bit = bit;

#line 346
      if (prob < current_link->data) {
          tmp_bit = tmp_bit ? 0 : 1;
        }
      radio_active[current_link->mote] += tmp_bit;
      radio_idle_state[current_link->mote] = 0;
      current_link->bit = tmp_bit;
      current_link = current_link->next_link;
    }
  pthread_mutex_unlock(&radioConnectivityLock);
}

static inline 
#line 392
int read_lossy_entry(FILE *file, int *mote_one, int *mote_two, double *loss)
#line 392
{
  char buf[128];
  int findex = 0;
  int ch;


  while (1) {
      ch = _IO_getc(file);
      if (ch == -1) {
#line 400
          return 0;
        }
      else {
#line 401
        if (ch >= '0' && ch <= '9') {
            buf[findex] = (char )ch;
            findex++;
          }
        else {
#line 405
          if (ch == ':') {
              buf[findex] = 0;
              break;
            }
          else {
#line 409
            if ((ch == '\n' || ch == ' ') || ch == '\t') {
                if (findex > 0) {
#line 410
                    return 0;
                  }
              }
            else 
#line 412
              {
                return 0;
              }
            }
          }
        }
    }
#line 417
  *mote_one = atoi(buf);
  findex = 0;

  while (1) {
      ch = _IO_getc(file);
      if (ch == -1) {
#line 422
          return 0;
        }
      else {
#line 423
        if (ch >= '0' && ch <= '9') {
            buf[findex] = (char )ch;
            findex++;
          }
        else {
#line 427
          if (ch == ':') {
              buf[findex] = 0;
              break;
            }
          else {
#line 431
            if ((ch == '\n' || ch == ' ') || ch == '\t') {
                if (findex == 0) {
#line 432
                    return 0;
                  }
                else 
#line 433
                  {
                    buf[findex] = 0;
                    break;
                  }
              }
            else {
                return 0;
              }
            }
          }
        }
    }
#line 443
  *mote_two = atoi(buf);

  findex = 0;

  while (1) {
      ch = _IO_getc(file);
      if (ch == -1) {
#line 449
          return 0;
        }
      else {
#line 451
        if (((((
#line 450
        ch >= '0' && ch <= '9') || ch == '.') || ch == '-') || ch == 'E')
         || ch == 'e') {
            buf[findex] = (char )ch;
            findex++;
          }
        else {
#line 455
          if ((ch == '\n' || ch == ' ') || ch == '\t') {
              if (findex == 0) {
#line 456
                  return 0;
                }
              else 
#line 457
                {
                  buf[findex] = 0;
                  break;
                }
            }
          else {
              return 0;
            }
          }
        }
    }
#line 466
  *loss = atof(buf);

  return 1;
}

static inline void lossy_init(void)
#line 471
{
  int sfd = open(lossyFileName, 00);
  int i;
  FILE *file = fdopen(sfd, "r");
  link_t *new_link;

  dbg_clear(DBG_SIM, "Initializing lossy model from %s.\n", lossyFileName);
  pthread_mutex_init(&radioConnectivityLock, (void *)0);
  adjacency_list_init();

  if (sfd < 0) {
      dbg(DBG_SIM, "Cannot open %s - assuming single radio cell\n", lossyFileName);
      static_one_cell_init();
      return;
    }

  for (i = 0; i < TOSNODES; i++) {
      radio_connectivity[i] = (void *)0;
      radio_idle_state[i] = 0;
      radio_heard[i] = 0;
    }
  while (1) {
      int mote_one;
      int mote_two;
      double loss;

#line 496
      if (read_lossy_entry(file, &mote_one, &mote_two, &loss)) {
          if (mote_one != mote_two) {
              new_link = allocate_link(mote_two);
              new_link->data = loss;
              new_link->next_link = radio_connectivity[mote_one];
              radio_connectivity[mote_one] = new_link;
            }
        }
      else {
          break;
        }
    }
  dbg(DBG_BOOT, "RFM connectivity graph constructed.\n");
}

static inline 








rfm_model *create_lossy_model(char *file)
#line 520
{
  rfm_model *model = (rfm_model *)malloc(sizeof(rfm_model ));

#line 522
  if (file != (void *)0) {
      lossyFileName = file;
    }
  model->init = lossy_init;
  model->transmit = lossy_transmit;
  model->stop_transmit = lossy_stop_transmit;
  model->hears = lossy_hears;
  model->connected = lossy_connected;
  model->neighbors = lossy_neighbors;
  return model;
}

static inline 
# 83 "/root/src/tinyos-1.x/tos/platform/pc/adc_model.c"
uint16_t generic_adc_read(int moteID, uint8_t port, long long ftime)
#line 83
{
  uint16_t value;

  if (moteID >= TOSNODES || moteID < 0) {
      dbg(DBG_ERROR, "GENERIC_ADC_MODEL: trying to read value with invalid parameters: [moteID = %d] [port = %d]", moteID, port);
      return -1;
    }
  pthread_mutex_lock(&adcValuesLock);
  value = adcValues[moteID][(int )port];
  pthread_mutex_unlock(&adcValuesLock);
  if (value == 0xffff) {
    return (short )(rand() & 0x3ff);
    }
  else {
#line 96
    return value;
    }
}

static inline 
#line 72
void generic_adc_init(void)
#line 72
{
  int i;
#line 73
  int j;

#line 74
  for (i = 0; i < TOSNODES; i++) {
      for (j = 0; j < ADC_NUM_PORTS_PER_NODE; j++) {
          adcValues[i][j] = 0xffff;
        }
    }
  pthread_mutex_init(&adcValuesLock, (void *)0);
}

static inline 
#line 99
adc_model *create_generic_adc_model(void)
#line 99
{
  adc_model *model = (adc_model *)malloc(sizeof(adc_model ));

#line 101
  model->init = generic_adc_init;
  model->read = generic_adc_read;
  return model;
}

static inline 
#line 50
uint16_t random_adc_read(int moteID, uint8_t port, long long ftime)
#line 50
{
  return (uint16_t )(rand() & 0x3ff);
}

static inline 
#line 48
void random_adc_init(void)
#line 48
{
}

static inline 


adc_model *create_random_adc_model(void)
#line 54
{
  adc_model *model = (adc_model *)malloc(sizeof(adc_model ));

#line 56
  model->init = random_adc_init;
  model->read = random_adc_read;
  return model;
}

static inline 
# 103 "/root/src/tinyos-1.x/tos/platform/pc/eeprom.c"
int namedEEPROM(char *name, int fnumMotes, int eepromSize)
#line 103
{
  int filedes = createEEPROM(name, fnumMotes, eepromSize);

#line 105
  if (filedes >= 0) {
      return 0;
    }
  else {
      dbg(DBG_ERROR, "ERROR: Unable to create named EEPROM region: %s.\n", name);
      return -1;
    }
}

static inline 
#line 90
int anonymousEEPROM(int fnumMotes, int eepromSize)
#line 90
{
  int filedes;

#line 92
  filedes = createEEPROM("/tmp/anonymous", fnumMotes, eepromSize);
  if (filedes >= 0) {
      unlink("/tmp/anonymous");
      return 0;
    }
  else {
      dbg(DBG_ERROR, "ERROR: Unable to create anonymous EEPROM region.\n");
      return -1;
    }
}

static inline 
# 63 "/root/src/tinyos-1.x/tos/platform/pc/spatial_model.c"
void simple_spatial_get_position(int moteID, long long ftime, point3D *point)
#line 63
{
  point->xCoordinate = points[moteID].xCoordinate;
  point->yCoordinate = points[moteID].yCoordinate;
  point->zCoordinate = points[moteID].zCoordinate;
}

static inline 
#line 51
void simple_spatial_init(void)
#line 51
{
  int i;

#line 53
  points = (point3D *)malloc(sizeof(point3D ) * TOSNODES);

  for (i = 0; i < TOSNODES; i++) {
      points[i].xCoordinate = (double )(rand() % 1000);
      points[i].yCoordinate = (double )(rand() % 1000);
      points[i].zCoordinate = (double )(rand() % 1000);
    }
}

static inline 







spatial_model *create_simple_spatial_model(void)
#line 70
{
  spatial_model *model = (spatial_model *)malloc(sizeof(spatial_model ));

#line 72
  model->init = simple_spatial_init;
  model->get_position = simple_spatial_get_position;

  return model;
}

static inline 
# 129 "/root/src/tinyos-1.x/beta/TOSSIM-packet/nido.h"
void tos_state_model_init(void )
{

  tos_state.space->init();


  tos_state.rfm->init();


  tos_state.adc->init();
}

static inline 
# 372 "/root/src/tinyos-1.x/beta/TOSSIM-packet/packet_sim.c"
int read_packet_entry(FILE *file, int *mote_one, int *mote_two, double *packet_loss, double *falsePos, double *falseNeg)
#line 372
{
  bool okFormat = TRUE;

#line 374
  if ((*mote_one = read_int(file)) < 0) {
#line 374
      okFormat = FALSE;
    }
  else {
#line 375
    if ((*mote_two = read_int(file)) < 0) {
#line 375
        okFormat = FALSE;
      }
    else {
#line 376
      if ((*packet_loss = read_double(file)) < 0) {
#line 376
          okFormat = FALSE;
        }
      else {
#line 377
        if ((*falsePos = read_double(file)) < 0) {
#line 377
            okFormat = FALSE;
          }
        else {
#line 378
          if ((*falseNeg = read_double(file)) < 0) {
#line 378
              okFormat = FALSE;
            }
          else 
#line 379
            {
              dbg_clear(DBG_SIM, "SIM: Read in packet entry %i->%i, packet loss: %lf, ack false pos: %lf, neg: %lf\n", *mote_one, *mote_two, *packet_loss, *falsePos, *falseNeg);
            }
          }
        }
      }
    }
#line 382
  return okFormat == TRUE;
}

static inline void connectivity_init(char *cFile)
#line 385
{
  int mote_one;
#line 386
  int mote_two;
  double packet;
#line 387
  double positive;
#line 387
  double negative;
  FILE *f = fopen(cFile, "r");

#line 389
  if (f == (void *)0) {
      fprintf(stderr, "SIM: Could not load packet configuration file %s\n", cFile);
      return;
    }
  while (read_packet_entry(f, &mote_one, &mote_two, &packet, &positive, &negative)) {
      link_t *new_link;

#line 395
      new_link = allocate_link(mote_two);
      new_link->data = packet;
      new_link->neg = negative;
      new_link->pos = positive;
      new_link->next_link = packet_connectivity[mote_one];
      packet_connectivity[mote_one] = new_link;
    }
}

static inline 
#line 108
void packet_sim_init(char *cFile)
#line 108
{
  int i;

#line 110
  for (i = 0; i < TOSNODES; i++) {
      packet_transmitting[i] = (void *)0;
      incoming[i] = (void *)0;
      packet_connectivity[i] = (void *)0;
      rxState[i] = RADIO_RX_IDLE;
      txState[i] = RADIO_TX_IDLE;
      current_ptr[i] = &packet_sim_bufs[i];
    }
  connectivity_init(cFile);
}

static inline 
# 51 "/root/src/tinyos-1.x/tos/platform/pc/hardware.c"
void init_hardware(void)
#line 51
{
  int i;

#line 53
  for (i = 0; i < tos_state.num_nodes; i++) {
      tos_state.current_node = i;
      TOSH_pc_hardware.status_register = 0xff;
    }
}

static inline 
# 68 "/root/src/tinyos-1.x/tos/platform/pc/heap_array.c"
void init_heap(heap_t *heap)
#line 68
{
  heap->size = 0;
  heap->private_size = STARTING_SIZE;
  heap->data = malloc(sizeof(node_t ) * heap->private_size);
}

static inline 
# 51 "/root/src/tinyos-1.x/tos/platform/pc/event_queue.c"
void queue_init(event_queue_t *queue, int fpause)
#line 51
{
  init_heap(& queue->heap);
  queue->pause = fpause;
  pthread_mutex_init(& queue->lock, (void *)0);
}

static inline 
# 207 "/root/src/tinyos-1.x/tos/platform/pc/external_comm.c"
void waitForGuiConnection(void)
#line 207
{
  int numclients = 0;
  int n;

  dbg_clear(DBG_SIM, "SIM: Waiting for connection from GUI...\n");
  pthread_mutex_lock(&eventClientsLock);
  while (numclients == 0) {
      for (n = 0; n < 4; n++) {
          if (eventClients[n] != -1) {
              dbg_clear(DBG_SIM, "SIM: Got client connection fd %d\n", eventClients[n]);
              numclients++;
            }
        }
      if (numclients == 0) {
          pthread_cond_wait(&eventClientsCond, &eventClientsLock);
        }
    }
  pthread_mutex_unlock(&eventClientsLock);
}

static inline 
# 43 "/root/src/tinyos-1.x/tos/platform/pc/events.c"
void event_default_cleanup(event_t *event)
#line 43
{
  free(event->data);
  dbg(DBG_MEM, "event_default_cleanup: freeing event: 0x%x\n", (unsigned int )event);
}

static inline 
# 78 "/root/src/tinyos-1.x/tos/platform/pc/heap_array.c"
int is_empty(heap_t *heap)
#line 78
{
  return heap->size == 0;
}

static inline int heap_is_empty(heap_t *heap)
#line 82
{
  return is_empty(heap);
}

static inline 
# 86 "/root/src/tinyos-1.x/tos/platform/pc/event_queue.c"
int queue_is_empty(event_queue_t *queue)
#line 86
{
  int rval;

#line 88
  pthread_mutex_lock(& queue->lock);
  rval = heap_is_empty(& queue->heap);
  pthread_mutex_unlock(& queue->lock);
  return rval;
}

static inline 
# 86 "/root/src/tinyos-1.x/tos/platform/pc/heap_array.c"
long long heap_get_min_key(heap_t *heap)
#line 86
{
  if (is_empty(heap)) {
      return -1;
    }
  else {
      return ((node_t *)heap->data)[0].key;
    }
}

static inline 
# 94 "/root/src/tinyos-1.x/tos/platform/pc/event_queue.c"
long long queue_peek_event_time(event_queue_t *queue)
#line 94
{
  long long rval;

  pthread_mutex_lock(& queue->lock);
  if (heap_is_empty(& queue->heap)) {
      rval = -1;
    }
  else {
      rval = heap_get_min_key(& queue->heap);
    }

  pthread_mutex_unlock(& queue->lock);
  return rval;
}

static inline 
#line 63
event_t *queue_pop_event(event_queue_t *queue)
#line 63
{
  long long ftime;
  event_t *event;

  pthread_mutex_lock(& queue->lock);
  event = (event_t *)heap_pop_min_data(& queue->heap, &ftime);
  pthread_mutex_unlock(& queue->lock);

  if (dbg_active(DBG_QUEUE)) {
      char timeStr[128];

#line 73
      timeStr[0] = 0;
      printOtherTime(timeStr, 128, ftime);
      dbg(DBG_QUEUE, "Popping event for mote %i with time %s.\n", event->mote, timeStr);
    }

  if (queue->pause > 0 && event->pause) {
      sleep(queue->pause);
    }


  return event;
}

static inline 
#line 109
void queue_handle_next_event(event_queue_t *queue)
#line 109
{
  event_t *event = queue_pop_event(queue);

#line 111
  if (event != (void *)0) {
      if (tos_state.moteOn[event->mote] || event->force) {
          tos_state.current_node = event->mote;
          dbg(DBG_QUEUE, "Setting TOS_LOCAL_ADDRESS to %hi\n", (short )(event->mote & 0xffff));
          { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 115
            TOS_LOCAL_ADDRESS = (short )(event->mote & 0xffff);
#line 115
            __nesc_atomic_end(__nesc_atomic); }
          event->handle(event, &tos_state);
        }
    }
}

static inline 
# 86 "/root/src/tinyos-1.x/tos/platform/pc/tos.c"
void rate_based_wait(void)
#line 86
{
  long long rtElapsed;
  long long diffVal;
  long long secondVal;

#line 90
  gettimeofday(&thisTime, (void *)0);
  rtElapsed = thisTime.tv_usec - startTime.tv_usec;
  secondVal = thisTime.tv_sec - startTime.tv_sec;
  secondVal *= (long long )1000000;
  rtElapsed += secondVal;
  rtElapsed *= (long long )4;
  rtElapsed = (long long )((double )rtElapsed * rate_value);
  if (rtElapsed + 10000 < tos_state.tos_time - rate_checkpoint_time) {
      diffVal = tos_state.tos_time - rate_checkpoint_time - rtElapsed;
      diffVal /= 4;
      usleep(diffVal);
    }
}

# 91 "/root/src/tinyos-1.x/tos/types/dbg.h"
static void dbg(TOS_dbg_mode mode, const char *format, ...)
{
  DebugMsgEvent ev;

#line 94
  if (dbg_active(mode)) {
      va_list args;

      __builtin_va_start(args, format);
      if (!(mode & DBG_SIM)) {
          vsnprintf(ev.debugMessage, sizeof  ev.debugMessage, format, args);
          sendTossimEvent(tos_state.current_node, AM_DEBUGMSGEVENT, tos_state.tos_time, &ev);
        }

      fprintf(stdout, "%i: ", tos_state.current_node);
      vfprintf(stdout, format, args);
      __builtin_va_end(args);
    }
}

static 
# 793 "/root/src/tinyos-1.x/tos/platform/pc/external_comm.c"
void sendTossimEvent(uint16_t moteID, uint16_t type, long long ftime, void *data)
#line 793
{
  unsigned char *msg;
  int total_size;
  int n;
  int numclients = 0;
  int clients[4];

  if (!socketsInitialized) {
#line 800
    return;
    }
  pthread_mutex_lock(&eventClientsLock);
  while (numclients == 0) {
      for (n = 0; n < 4; n++) {
          clients[n] = -1;
          if (eventClients[n] != -1) {
              clients[n] = eventClients[n];
              numclients++;
            }
        }

      if (numclients == 0 && GUI_enabled) {
          ;
          pthread_cond_wait(&eventClientsCond, &eventClientsLock);
          ;
        }
      else {
#line 816
        if (numclients == 0) {

            pthread_mutex_unlock(&eventClientsLock);
            return;
          }
        }
    }
#line 822
  pthread_mutex_unlock(&eventClientsLock);

  ;

  buildTossimEvent(moteID, type, ftime, data, &msg, &total_size);

  for (n = 0; n < 4; n++) {
      if (clients[n] != -1) {
          if (writeTossimEvent(msg, total_size, clients[n]) < 0) {

              pthread_mutex_lock(&eventClientsLock);
              eventClients[n] = -1;
              pthread_mutex_unlock(&eventClientsLock);
            }
        }
    }
  ;
  free(msg);
}

static 
#line 733
void buildTossimEvent(uint16_t moteID, uint16_t type, long long ftime, void *data, 
unsigned char **msgp, int *lenp)
#line 734
{
  unsigned char *msg;
  int payload_size;
#line 736
  int total_size;



  switch (type) {
      case AM_DEBUGMSGEVENT: 
        payload_size = sizeof(DebugMsgEvent );
      break;
      case AM_RADIOMSGSENTEVENT: 
        payload_size = sizeof(RadioMsgSentEvent );
      break;
      case AM_UARTMSGSENTEVENT: 
        payload_size = sizeof(RadioMsgSentEvent );
      break;
      case AM_ADCDATAREADYEVENT: 
        payload_size = sizeof(ADCDataReadyEvent );
      break;
      case AM_TOSSIMINITEVENT: 
        payload_size = sizeof(TossimInitEvent );
      break;
      case AM_VARIABLERESOLVERESPONSE: 
        payload_size = sizeof(VariableResolveResponse );
      break;
      case AM_VARIABLEREQUESTRESPONSE: 
        payload_size = sizeof(VariableRequestCommand );
      break;
      case AM_INTERRUPTEVENT: 
        payload_size = sizeof(InterruptEvent );
      dbg(DBG_TEMP, "SIM: Sending InterruptEvent, payload is %i\n", (int )payload_size);
      break;
      case AM_LEDEVENT: 
        payload_size = sizeof(LedEvent );
      break;
      default: 
        ;
      return;
    }

  total_size = 14 + payload_size;
  msg = (unsigned char *)malloc(total_size);

  * (unsigned short *)&msg[0] = htons(type);
  * (unsigned short *)&msg[2] = htons(moteID);
  * (long long *)&msg[4] = __extension__ ({
#line 779
    union __nesc_unnamed4381 {
#line 779
      __extension__ unsigned long long int __ll;
#line 779
      unsigned long int __l[2];
    } 
#line 779
    __w;
#line 779
    union __nesc_unnamed4381 __r;

#line 779
    if (__builtin_constant_p(ftime)) {
#line 779
      __r.__ll = ((((((((ftime & 0xff00000000000000ull) >> 56) | ((ftime & 0x00ff000000000000ull) >> 40)) | ((ftime & 0x0000ff0000000000ull) >> 24)) | ((ftime & 0x000000ff00000000ull) >> 8)) | ((ftime & 0x00000000ff000000ull) << 8)) | ((ftime & 0x0000000000ff0000ull) << 24)) | ((ftime & 0x000000000000ff00ull) << 40)) | ((ftime & 0x00000000000000ffull) << 56);
      }
    else 
#line 779
      {
#line 779
        __w.__ll = ftime;
#line 779
        __r.__l[0] = __extension__ ({
#line 779
          register unsigned int __v;
#line 779
          register unsigned int __x = __w.__l[1];

#line 779
          if (__builtin_constant_p(__x)) {
#line 779
            __v = ((((__x & 0xff000000) >> 24) | ((__x & 0x00ff0000) >> 8)) | ((__x & 0x0000ff00) << 8)) | ((__x & 0x000000ff) << 24);
            }
          else {
#line 779
             __asm ("rorw $8, %w0;""rorl $16, %0;""rorw $8, %w0" : "=r"(__v) : "0"(__x) : "cc");
            }
#line 779
          __v;
        }
        );
#line 779
        __r.__l[1] = __extension__ ({
#line 779
          register unsigned int __v;
#line 779
          register unsigned int __x = __w.__l[0];

#line 779
          if (__builtin_constant_p(__x)) {
#line 779
            __v = ((((__x & 0xff000000) >> 24) | ((__x & 0x00ff0000) >> 8)) | ((__x & 0x0000ff00) << 8)) | ((__x & 0x000000ff) << 24);
            }
          else {
#line 779
             __asm ("rorw $8, %w0;""rorl $16, %0;""rorw $8, %w0" : "=r"(__v) : "0"(__x) : "cc");
            }
#line 779
          __v;
        }
        );
      }
#line 779
    __r.__ll;
  }
  );
#line 780
  * (unsigned short *)&msg[12] = htons(payload_size);
  memcpy((unsigned char *)msg + 14, data, payload_size);

  ;


  *msgp = msg;
  *lenp = total_size;
}

static 
#line 702
int writeTossimEvent(void *data, int datalen, int clifd)
#line 702
{
  unsigned char ack;
  int i;
#line 704
  int j;









  ;
  j = 0;


  i = send(clifd, data, datalen, 0);
  ;
  if (i >= 0) {
#line 720
    j = read(clifd, &ack, 1);
    }
#line 721
  ;
  if (i < 0 || j < 0) {
      ;
      close(clifd);
      return -1;
    }


  ;
  return 0;
}

static 
# 167 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
result_t AMPromiscuous$reportSendDone(TOS_MsgPtr msg, result_t success)
#line 167
{
  dbg(DBG_AM, "AM report send done for message to 0x%x, type %d.\n", msg->addr, msg->type);
  AMPromiscuous$state[tos_state.current_node] = FALSE;
  AMPromiscuous$SendMsg$sendDone(msg->type, msg, success);
  AMPromiscuous$sendDone();

  return SUCCESS;
}

static  
# 218 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopEngineGridM.nc"
result_t MultiHopEngineGridM$SendMsg$sendDone(uint8_t id, TOS_MsgPtr pMsg, result_t success)
#line 218
{

  if (
#line 219
  id != AM_MULTIHOPMSG && 
  id != 66 && 
  id != 67) {
#line 221
      return SUCCESS;
    }
  if (success == FAIL) {
      MultiHopEngineGridM$RouteSelect$initializeFields(pMsg, id);

      if (MultiHopEngineGridM$RouteSelect$selectRoute(pMsg, id) != SUCCESS) {
          MultiHopEngineGridM$Send$sendDone(id, pMsg, success);
        }

      dbg(DBG_ROUTE, "MHop: out pkt 0x%x to 0x%x\n", ((TOS_MHopMsg *)pMsg->data)->seqno, ((TOS_MHopMsg *)pMsg->data)->originaddr);

      if (MultiHopEngineGridM$SendMsg$send(id, pMsg->addr, pMsg->length, pMsg) != SUCCESS) {
          dbg(DBG_ROUTE, "MHop: send failed\n");
          MultiHopEngineGridM$Send$sendDone(id, pMsg, success);
        }
    }
  else {
#line 236
    if (pMsg == MultiHopEngineGridM$FwdBufList[tos_state.current_node][MultiHopEngineGridM$iFwdBufTail[tos_state.current_node]]) {
        MultiHopEngineGridM$iFwdBufTail[tos_state.current_node]++;
#line 237
        MultiHopEngineGridM$iFwdBufTail[tos_state.current_node] %= MultiHopEngineGridM$FWD_QUEUE_SIZE;
      }
    else {
        MultiHopEngineGridM$Send$sendDone(id, pMsg, success);
      }
    }
#line 242
  return SUCCESS;
}

static  
# 748 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopGrid.nc"
result_t MultiHopGrid$RouteSelect$initializeFields(TOS_MsgPtr Msg, uint8_t id)
#line 748
{
  TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];

  pMHMsg->sourceaddr = TOS_LOCAL_ADDRESS;
  pMHMsg->hopcount = MultiHopGrid$ROUTE_INVALID;

  return SUCCESS;
}

static  
#line 663
result_t MultiHopGrid$RouteSelect$selectRoute(TOS_MsgPtr Msg, uint8_t id)
#line 663
{
  TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];

  uint8_t iNbr;
  bool fIsDuplicate;
  result_t Result = SUCCESS;

#line 692
  if (pMHMsg->sourceaddr == TOS_LOCAL_ADDRESS && 
  pMHMsg->originaddr == TOS_LOCAL_ADDRESS) {
      fIsDuplicate = FALSE;
    }
  else {
      fIsDuplicate = MultiHopGrid$updateNbrCounters(pMHMsg->sourceaddr, pMHMsg->seqno, &iNbr);
    }

  if (!fIsDuplicate) {
      pMHMsg->sourceaddr = TOS_LOCAL_ADDRESS;
      pMHMsg->hopcount = MultiHopGrid$gbCurrentHopCount[tos_state.current_node];





      {
        int16_t destX;
        int16_t destY;
        int16_t myX;
        int16_t myY;
        uint16_t nextAddr = TOS_LOCAL_ADDRESS;

#line 714
        destX = pMHMsg->originaddr % 20;
        destY = pMHMsg->originaddr / 20;
        myX = TOS_LOCAL_ADDRESS % 20;
        myY = TOS_LOCAL_ADDRESS / 20;
        if (MultiHopGrid$Random$rand() & 1) {
            if (destY > myY) {
#line 719
                nextAddr = TOS_LOCAL_ADDRESS + 20;
              }
            else {
#line 720
              if (destY < myY) {
#line 720
                  nextAddr = TOS_LOCAL_ADDRESS - 20;
                }
              else {
#line 721
                if (destX > myX) {
#line 721
                    nextAddr = TOS_LOCAL_ADDRESS + 1;
                  }
                else {
#line 722
                  if (destX < myX) {
#line 722
                      nextAddr = TOS_LOCAL_ADDRESS - 1;
                    }
                  }
                }
              }
          }
        else 
#line 724
          {
            if (destX > myX) {
#line 725
                nextAddr = TOS_LOCAL_ADDRESS + 1;
              }
            else {
#line 726
              if (destX < myX) {
#line 726
                  nextAddr = TOS_LOCAL_ADDRESS - 1;
                }
              else {
#line 727
                if (destY > myY) {
#line 727
                    nextAddr = TOS_LOCAL_ADDRESS + 20;
                  }
                else {
#line 728
                  if (destY < myY) {
#line 728
                      nextAddr = TOS_LOCAL_ADDRESS - 20;
                    }
                  }
                }
              }
          }
#line 731
        Msg->addr = nextAddr;
      }


      if (pMHMsg->originaddr != TOS_LOCAL_ADDRESS) {
          MultiHopGrid$updateDescendant(pMHMsg->originaddr);
        }
    }
  else {
      Result = FAIL;
    }
  dbg(DBG_ROUTE, "MultiHopWMEWMA: Sequence Number: %d\n", pMHMsg->seqno);

  return Result;
}

static 
#line 336
bool MultiHopGrid$updateNbrCounters(uint16_t saddr, int16_t seqno, uint8_t *NbrIndex)
#line 336
{
  MultiHopGrid$TableEntry *pNbr;
  int16_t sDelta;
  uint8_t iNbr;
  bool Result = FALSE;

  iNbr = MultiHopGrid$findPreparedIndex(saddr);
  pNbr = &MultiHopGrid$NeighborTbl[tos_state.current_node][iNbr];

  sDelta = seqno - MultiHopGrid$NeighborTbl[tos_state.current_node][iNbr].lastSeqno - 1;

  if (pNbr->flags & MultiHopGrid$NBRFLAG_NEW) {
      pNbr->received++;
      pNbr->lastSeqno = seqno;
      pNbr->flags ^= MultiHopGrid$NBRFLAG_NEW;
    }
  else {
#line 352
    if (sDelta >= 0) {
        pNbr->missed += sDelta;
        pNbr->received++;
        pNbr->lastSeqno = seqno;
      }
    else {
#line 357
      if (sDelta < MultiHopGrid$ACCEPTABLE_MISSED) {

          MultiHopGrid$newEntry(iNbr, saddr);
          pNbr->received++;
          pNbr->lastSeqno = seqno;
          pNbr->flags ^= MultiHopGrid$NBRFLAG_NEW;
        }
      else {
          Result = FALSE;
        }
      }
    }
#line 368
  *NbrIndex = iNbr;
  return Result;
}

static 
#line 160
uint8_t MultiHopGrid$findEntry(uint8_t id)
#line 160
{
  uint8_t i = 0;

#line 162
  for (i = 0; i < MultiHopGrid$ROUTE_TABLE_SIZE; i++) {
      if (MultiHopGrid$NeighborTbl[tos_state.current_node][i].flags & MultiHopGrid$NBRFLAG_VALID && MultiHopGrid$NeighborTbl[tos_state.current_node][i].id == id) {
          return i;
        }
    }
  return MultiHopGrid$ROUTE_INVALID;
}

static 
#line 202
void MultiHopGrid$newEntry(uint8_t indes, uint16_t id)
#line 202
{
  MultiHopGrid$NeighborTbl[tos_state.current_node][indes].id = id;
  MultiHopGrid$NeighborTbl[tos_state.current_node][indes].flags = MultiHopGrid$NBRFLAG_VALID | MultiHopGrid$NBRFLAG_NEW;
  MultiHopGrid$NeighborTbl[tos_state.current_node][indes].liveliness = 0;
  MultiHopGrid$NeighborTbl[tos_state.current_node][indes].parent = MultiHopGrid$ROUTE_INVALID;
  MultiHopGrid$NeighborTbl[tos_state.current_node][indes].cost = MultiHopGrid$ROUTE_INVALID;
  MultiHopGrid$NeighborTbl[tos_state.current_node][indes].childLiveliness = 0;
  MultiHopGrid$NeighborTbl[tos_state.current_node][indes].hop = MultiHopGrid$ROUTE_INVALID;
  MultiHopGrid$NeighborTbl[tos_state.current_node][indes].missed = 0;
  MultiHopGrid$NeighborTbl[tos_state.current_node][indes].received = 0;
  MultiHopGrid$NeighborTbl[tos_state.current_node][indes].receiveEst = 0;
  MultiHopGrid$NeighborTbl[tos_state.current_node][indes].sendEst = 0;
}

static   
# 70 "/root/src/tinyos-1.x/tos/system/RandomLFSR.nc"
uint16_t RandomLFSR$Random$rand(void)
#line 70
{
  bool endbit;
  uint16_t tmpShiftReg;

#line 73
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 73
    {
      tmpShiftReg = RandomLFSR$shiftReg[tos_state.current_node];
      endbit = (tmpShiftReg & 0x8000) != 0;
      tmpShiftReg <<= 1;
      if (endbit) {
        tmpShiftReg ^= 0x100b;
        }
#line 79
      tmpShiftReg++;
      RandomLFSR$shiftReg[tos_state.current_node] = tmpShiftReg;
      tmpShiftReg = tmpShiftReg ^ RandomLFSR$mask[tos_state.current_node];
    }
#line 82
    __nesc_atomic_end(__nesc_atomic); }
  return tmpShiftReg;
}

static  
# 138 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OProuteM.nc"
result_t OProuteM$Send$sendDone(TOS_MsgPtr mesg, result_t success)
#line 138
{
  BombillaContext *sender = OProuteM$sendingContext[tos_state.current_node];

#line 140
  if (sender == (void *)0) {
      return SUCCESS;
    }
  dbg(DBG_USR1, "VM: Route send completed with code %i\n", (int )success);
  if (sender->state != BOMB_STATE_SENDING) {
      OProuteM$Error$error(sender, BOMB_ERROR_QUEUE_INVALID);
      return FAIL;
    }

  OProuteM$sendingContext[tos_state.current_node] = (void *)0;
  OProuteM$Synch$resumeContext(sender, sender);

  return SUCCESS;
}

static  
# 221 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
result_t BombillaEngineM$Error$error(BombillaContext *context, uint8_t cause)
#line 221
{
  BombillaEngineM$inErrorState[tos_state.current_node] = TRUE;
  dbg(DBG_ERROR | DBG_USR1, "VM: Entering ERROR state. Context: %i, cause %i\n", (int )context->which, (int )cause);
  BombillaEngineM$Leds$redOn();
  BombillaEngineM$Leds$greenOn();
  BombillaEngineM$Leds$yellowOn();
  BombillaEngineM$ErrorTimer$start(TIMER_REPEAT, 1000);
  BombillaEngineM$errorContext[tos_state.current_node] = context;
  if (context != (void *)0) {
      BombillaEngineM$errorContext[tos_state.current_node] = context;
      BombillaEngineM$errorMsg[tos_state.current_node].context = context->which;
      BombillaEngineM$errorMsg[tos_state.current_node].reason = cause;
      BombillaEngineM$errorMsg[tos_state.current_node].capsule = context->currentCapsule->capsule.type;
      BombillaEngineM$errorMsg[tos_state.current_node].instruction = context->pc - 1;
      context->state = BOMB_STATE_HALT;
    }
  else {
      BombillaEngineM$errorMsg[tos_state.current_node].context = BOMB_CAPSULE_INVALID;
      BombillaEngineM$errorMsg[tos_state.current_node].reason = cause;
      BombillaEngineM$errorMsg[tos_state.current_node].capsule = BOMB_CAPSULE_INVALID;
      BombillaEngineM$errorMsg[tos_state.current_node].instruction = 255;
    }
  return SUCCESS;
}

static   
# 76 "/root/src/tinyos-1.x/tos/platform/pc/LedsC.nc"
result_t LedsC$Leds$redOn(void)
#line 76
{
  dbg(DBG_LED, "LEDS: Red on.\n");
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 78
    {
      if (!(LedsC$ledsOn[tos_state.current_node] & LedsC$RED_BIT)) {
          LedsC$ledsOn[tos_state.current_node] |= LedsC$RED_BIT;
          LedsC$updateLeds();
        }
    }
#line 83
    __nesc_atomic_end(__nesc_atomic); }

  return SUCCESS;
}

static 
#line 58
void LedsC$updateLeds(void)
#line 58
{
  LedEvent e;

#line 60
  e.red = (LedsC$ledsOn[tos_state.current_node] & LedsC$RED_BIT) > 0;
  e.green = (LedsC$ledsOn[tos_state.current_node] & LedsC$GREEN_BIT) > 0;
  e.yellow = (LedsC$ledsOn[tos_state.current_node] & LedsC$YELLOW_BIT) > 0;
  sendTossimEvent(tos_state.current_node, AM_LEDEVENT, tos_state.tos_time, &e);
}

static   
#line 110
result_t LedsC$Leds$greenOn(void)
#line 110
{
  dbg(DBG_LED, "LEDS: Green on.\n");
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 112
    {
      if (!(LedsC$ledsOn[tos_state.current_node] & LedsC$GREEN_BIT)) {
          LedsC$ledsOn[tos_state.current_node] |= LedsC$GREEN_BIT;
          LedsC$updateLeds();
        }
    }
#line 117
    __nesc_atomic_end(__nesc_atomic); }
  return SUCCESS;
}

static   
#line 143
result_t LedsC$Leds$yellowOn(void)
#line 143
{
  dbg(DBG_LED, "LEDS: Yellow on.\n");
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 145
    {
      if (!(LedsC$ledsOn[tos_state.current_node] & LedsC$YELLOW_BIT)) {
          LedsC$ledsOn[tos_state.current_node] |= LedsC$YELLOW_BIT;
          LedsC$updateLeds();
        }
    }
#line 150
    __nesc_atomic_end(__nesc_atomic); }
  return SUCCESS;
}

static  
# 93 "/root/src/tinyos-1.x/tos/system/TimerM.nc"
result_t TimerM$Timer$start(uint8_t id, char type, 
uint32_t interval)
#line 94
{
  uint8_t diff;

#line 96
  if (id >= NUM_TIMERS) {
#line 96
    return FAIL;
    }
#line 97
  if (type > 1) {
#line 97
    return FAIL;
    }
#line 98
  TimerM$mTimerList[tos_state.current_node][id].ticks = interval;
  TimerM$mTimerList[tos_state.current_node][id].type = type;

  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 101
    {
      diff = TimerM$Clock$readCounter();
      interval += diff;
      TimerM$mTimerList[tos_state.current_node][id].ticksLeft = interval;
      TimerM$mState[tos_state.current_node] |= 0x1 << id;
      if (interval < TimerM$mInterval[tos_state.current_node]) {
          TimerM$mInterval[tos_state.current_node] = interval;
          TimerM$Clock$setInterval(TimerM$mInterval[tos_state.current_node]);
          TimerM$setIntervalFlag[tos_state.current_node] = 0;
          TimerM$PowerManagement$adjustPower();
        }
    }
#line 112
    __nesc_atomic_end(__nesc_atomic); }
  return SUCCESS;
}

static 
# 51 "/root/src/tinyos-1.x/tos/platform/pc/hpl.c"
void TOSH_clock_set_rate(char interval, char scale)
{
  long long ticks;
  event_t *event = (void *)0;

  dbg(DBG_CLOCK, "CLOCK: Setting clock rate to interval %u, scale %u\n", (unsigned int )(interval & 0xff), (unsigned int )(scale & 0xff));
  if (clockEvents[tos_state.current_node] != (void *)0) {
      event_clocktick_invalidate(clockEvents[tos_state.current_node]);
    }

  ticks = clockScales[(int )(scale & 0xff)] * (int )(interval & 0xff);

  if (ticks > 0) {
      dbg(DBG_BOOT, "Clock initialized for mote %i to %lli ticks.\n", tos_state.current_node, ticks);

      event = (event_t *)malloc(sizeof(event_t ));
      dbg(DBG_MEM, "malloc clock tick event: 0x%x.\n", (int )event);
      event_clocktick_create(event, tos_state.current_node, tos_state.tos_time, ticks);
      queue_insert_event(& tos_state.queue, event);
#line 69
      ;
    }

  clockEvents[tos_state.current_node] = event;
  setTime[tos_state.current_node] = tos_state.tos_time;
  return;
}

static 
# 227 "/root/src/tinyos-1.x/tos/platform/pc/external_comm.c"
int printOtherTime(char *buf, int len, long long int ftime)
#line 227
{
  int hours;
  int minutes;
  int seconds;
  int secondBillionths;

  secondBillionths = (int )(ftime % (long long )4000000);
  seconds = (int )(ftime / (long long )4000000);
  minutes = seconds / 60;
  hours = minutes / 60;
  secondBillionths *= (long long )25;
  seconds %= 60;
  minutes %= 60;

  return snprintf(buf, len, "%i:%i:%i.%08i", hours, minutes, seconds, secondBillionths);
}

static 
# 57 "/root/src/tinyos-1.x/tos/platform/pc/event_queue.c"
void queue_insert_event(event_queue_t *queue, event_t *event)
#line 57
{
  pthread_mutex_lock(& queue->lock);
  heap_insert(& queue->heap, event, event->time);
  pthread_mutex_unlock(& queue->lock);
}

static 
# 187 "/root/src/tinyos-1.x/tos/platform/pc/heap_array.c"
void up_heap(heap_t *heap, int findex)
#line 187
{
  int parent_index;

#line 189
  if (findex == 0) {
      return;
    }

  parent_index = (findex - 1) / 2;

  if (((node_t *)heap->data)[parent_index].key > ((node_t *)heap->data)[findex].key) {
      swap(&((node_t *)heap->data)[findex], &((node_t *)heap->data)[parent_index]);
      up_heap(heap, parent_index);
    }
}

static 
#line 148
void swap(node_t *first, node_t *second)
#line 148
{
  long long key;
  void *data;

  key = first->key;
  first->key = second->key;
  second->key = key;

  data = first->data;
  first->data = second->data;
  second->data = data;
}

static  
# 162 "/root/src/tinyos-1.x/tos/lib/VM/contexts/OnceContextM.nc"
result_t OnceContextM$Virus$capsuleInstalled(BombillaCapsule *capsule)
#line 162
{
  OnceContextM$Synch$initializeContext(&OnceContextM$onceContext[tos_state.current_node]);
  if ((capsule->type & BOMB_OPTION_MASK) == BOMB_CAPSULE_ONCE) {
      dbg(DBG_USR1, "VM: Installing onceContext Capsule. \n");
      OnceContextM$onceContext[tos_state.current_node].rootCapsule.capsule = *capsule;
      OnceContextM$Analysis$analyzeCapsuleVars(& OnceContextM$onceContext[tos_state.current_node].rootCapsule);
      OnceContextM$Comm$reboot();

      OnceContextM$Synch$initializeContext(&OnceContextM$onceContext[tos_state.current_node]);
      OnceContextM$Synch$resumeContext(&OnceContextM$onceContext[tos_state.current_node], &OnceContextM$onceContext[tos_state.current_node]);
    }
  return SUCCESS;
}

static  
# 229 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
void BContextSynch$Synch$initializeContext(BombillaContext *context)
#line 229
{
  int i;

#line 231
  for (i = 0; i < (BOMB_HEAPSIZE + 7) / 8; i++) {
      context->heldSet[i] = 0;
      context->releaseSet[i] = 0;
    }
  context->currentCapsule = & context->rootCapsule;
  nmemcpy(context->acquireSet, context->currentCapsule->usedVars, (BOMB_HEAPSIZE + 7) / 8);
  context->pc = 0;
  BContextSynch$Stacks$resetStacks(context);
  context->queue = 0;
  context->state = BOMB_STATE_HALT;
}

static 
# 145 "/root/src/tinyos-1.x/tos/system/tos.h"
void *nmemcpy(void *to, const void *from, size_t n)
{
  char *cto = to;
  const char *cfrom = from;

  while (n--) * cto++ = * cfrom++;

  return to;
}

static  
# 183 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
void BContextSynch$Analysis$analyzeCapsuleVars(BombillaCapsuleBuffer *buf)
#line 183
{
  int i;

#line 185
  dbg(DBG_USR2, "VM: Analyzing capsule vars for capsule %i: ", (int )(buf->capsule.type & BOMB_OPTION_MASK));
  for (i = 0; i < (BOMB_HEAPSIZE + 7) / 8; i++) {
      buf->usedVars[i] = 0;
    }

  for (i = 0; i < BOMB_PGMSIZE; i++) {
      uint8_t instr = buf->capsule.code[i];
      int16_t lock = BContextSynch$CodeLocks$lockNum(instr, instr);

#line 193
      if (lock >= 0) {
          dbg_clear(DBG_USR2, "%i,", (int )lock);
          buf->usedVars[lock / 8] |= 1 << lock % 8;
        }
    }
  dbg_clear(DBG_USR2, "\n");
  buf->haveSeen = 1;
}

static 
# 139 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetvar4M.nc"
uint8_t OPgetsetvar4M$varToLock(uint8_t num)
#line 139
{
  switch (num) {
      case 0: 
        return OPgetsetvar4M$BOMB_LOCK_4_0;
      case 1: 
        return OPgetsetvar4M$BOMB_LOCK_4_1;
      case 2: 
        return OPgetsetvar4M$BOMB_LOCK_4_2;
      case 3: 
        return OPgetsetvar4M$BOMB_LOCK_4_3;
      case 4: 
        return OPgetsetvar4M$BOMB_LOCK_4_4;
      case 5: 
        return OPgetsetvar4M$BOMB_LOCK_4_5;
      case 6: 
        return OPgetsetvar4M$BOMB_LOCK_4_6;
      case 7: 
        return OPgetsetvar4M$BOMB_LOCK_4_7;
      case 8: 
        return OPgetsetvar4M$BOMB_LOCK_4_8;
      case 9: 
        return OPgetsetvar4M$BOMB_LOCK_4_9;
      case 10: 
        return OPgetsetvar4M$BOMB_LOCK_4_10;
      case 11: 
        return OPgetsetvar4M$BOMB_LOCK_4_11;
      case 12: 
        return OPgetsetvar4M$BOMB_LOCK_4_12;
      case 13: 
        return OPgetsetvar4M$BOMB_LOCK_4_13;
      case 14: 
        return OPgetsetvar4M$BOMB_LOCK_4_14;
      case 15: 
        return OPgetsetvar4M$BOMB_LOCK_4_15;
      default: 
        return 255;
    }
}

# 109 "/root/src/tinyos-1.x/tos/types/dbg.h"
static void dbg_clear(TOS_dbg_mode mode, const char *format, ...)
{
  DebugMsgEvent ev;

#line 112
  if (dbg_active(mode)) {
      va_list args;

#line 114
      __builtin_va_start(args, format);
      if (!(mode & DBG_SIM)) {
          vsnprintf(ev.debugMessage, sizeof  ev.debugMessage, format, args);
          sendTossimEvent(tos_state.current_node, AM_DEBUGMSGEVENT, tos_state.tos_time, &ev);
        }

      vfprintf(stdout, format, args);
      __builtin_va_end(args);
    }
}

static  
# 189 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
void BombillaEngineM$Comm$reboot(uint8_t type)
#line 189
{
  int i;

#line 191
  dbg(DBG_USR1, "VM: Bombilla rebooting.\n");
  BombillaEngineM$Synch$reboot();
  BombillaEngineM$Queue$init(&BombillaEngineM$runQueue[tos_state.current_node]);

  for (i = 0; i < 3; i++) {
      if (BombillaEngineM$capsules[tos_state.current_node][i] != (void *)0) {
          BombillaEngineM$capsules[tos_state.current_node][i]->haveSeen = 0;
        }
    }
  dbg(DBG_USR1, "VM: Analyzing lock sets.\n");
  for (i = 0; i < 3; i++) {
      if (BombillaEngineM$capsules[tos_state.current_node][i] != (void *)0) {
          BombillaEngineM$Analysis$analyzeCapsuleVars(BombillaEngineM$capsules[tos_state.current_node][i]);
        }
    }
  BombillaEngineM$Analysis$analyzeCapsuleCalls(BombillaEngineM$capsules[tos_state.current_node]);

  BombillaEngineM$inErrorState[tos_state.current_node] = FALSE;
  BombillaEngineM$errorContext[tos_state.current_node] = (void *)0;
}

static  
# 268 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
bool BContextSynch$Synch$resumeContext(BombillaContext *caller, 
BombillaContext *context)
#line 269
{
  context->state = BOMB_STATE_RESUMING;
  if (BContextSynch$Synch$isRunnable(context)) {
      BContextSynch$Synch$obtainLocks(caller, context);
      BContextSynch$Synch$makeRunnable(context);
      dbg(DBG_USR2, "VM (%i): Resumption of %i successful.\n", (int )caller->which, (int )context->which);
      return TRUE;
    }
  else {
      dbg(DBG_USR2, "VM (%i): Resumption of %i unsuccessful, putting on the queue.\n", (int )caller->which, (int )context->which);
      BContextSynch$Queue$enqueue(caller, &BContextSynch$readyQueue[tos_state.current_node], context);
      return FALSE;
    }
}

static  
# 135 "/root/src/tinyos-1.x/tos/lib/VM/components/BQueue.nc"
result_t BQueue$Queue$enqueue(BombillaContext *context, 
BombillaQueue *queue, 
BombillaContext *element)
#line 137
{
  dbg(DBG_USR2, "VM (%i): Enqueue %i on 0x%x\n", (int )context->which, (int )element->which, queue);
  if (element->queue) {
      BQueue$BombillaError$error(context, BOMB_ERROR_QUEUE_ENQUEUE);
      return FAIL;
    }
  element->queue = queue;
  BQueue$list_insert_head(& queue->queue, & element->link);
  return SUCCESS;
}

static  
# 152 "/root/src/tinyos-1.x/tos/lib/VM/components/BombillaEngineM.nc"
void BombillaEngineM$RunTask(void)
#line 152
{
  int i;

  if (!BombillaEngineM$inErrorState[tos_state.current_node]) {
      BombillaContext *context = BombillaEngineM$Queue$dequeue((void *)0, &BombillaEngineM$runQueue[tos_state.current_node]);

#line 157
      for (i = 0; i < 4; i++) {
          BombillaEngineM$computeInstruction(context);
          if (context->state != BOMB_STATE_RUN || context->queue == &BombillaEngineM$runQueue[tos_state.current_node]) {
              return;
            }
        }

      BombillaEngineM$Queue$enqueue(context, &BombillaEngineM$runQueue[tos_state.current_node], context);
      TOS_post(BombillaEngineM$RunTask);
    }
}

static  
# 148 "/root/src/tinyos-1.x/tos/lib/VM/components/BQueue.nc"
BombillaContext *BQueue$Queue$dequeue(BombillaContext *context, 
BombillaQueue *queue)
#line 149
{
  BombillaContext *rval;
  list_link_t *listLink;

#line 151
  ;

  if (BQueue$list_empty(& queue->queue)) {
      BQueue$BombillaError$error(context, BOMB_ERROR_QUEUE_DEQUEUE);
      return (void *)0;
    }

  listLink = queue->queue.l_prev;
  rval = (BombillaContext *)((char *)listLink - (size_t )& ((BombillaContext *)0)->link);
  BQueue$list_remove(listLink);
  rval->link.l_next = 0;
  rval->link.l_prev = 0;
  rval->queue = (void *)0;
  if (rval != (void *)0) {
      dbg(DBG_USR2, "VM: Dequeuing context %i from queue 0x%x.\n", (int )rval->which, queue);
    }

  return rval;
}

static  
# 164 "/root/src/tinyos-1.x/tos/lib/VM/components/BStacks.nc"
BombillaStackVariable *BStacks$Stacks$popOperand(BombillaContext *context)
#line 164
{

  BombillaStackVariable *var;

#line 167
  if (context->opStack.sp == 0) {
      dbg(DBG_ERROR, "VM: Tried to pop off end of stack.\n");
      context->opStack.stack[0].type = BOMB_TYPE_INVALID;
      BStacks$BombillaError$error(context, BOMB_ERROR_STACK_UNDERFLOW);
      return &context->opStack.stack[0];
    }
  else {
      uint8_t sIndex;

#line 175
      context->opStack.sp--;
      sIndex = context->opStack.sp;
      var = &context->opStack.stack[(int )sIndex];
      return var;
    }
  return (void *)0;
}

static  
#line 94
result_t BStacks$Stacks$pushValue(BombillaContext *context, 
int16_t val)
#line 95
{
  if (context->opStack.sp >= BOMB_OPDEPTH) {
      dbg(DBG_ERROR, "VM: Tried to push value off end of stack.\n");
      BStacks$BombillaError$error(context, BOMB_ERROR_STACK_OVERFLOW);
      return FAIL;
    }
  else {
      uint8_t sIndex = context->opStack.sp;

#line 103
      context->opStack.stack[(int )sIndex].type = BOMB_TYPE_VALUE;
      context->opStack.stack[(int )sIndex].value.var = val;
      context->opStack.sp++;
      return SUCCESS;
    }
}

static  
# 94 "/root/src/tinyos-1.x/tos/lib/VM/components/BBuffer.nc"
result_t BBuffer$Buffer$checkAndSetTypes(BombillaContext *context, 
BombillaDataBuffer *buffer, 
BombillaStackVariable *var)
#line 96
{
  BombillaSensorType type = BOMB_DATA_NONE;

#line 98
  dbg(DBG_USR1, "VM: Check buffer type %i against %i\n", (int )buffer->type, (int )var->type);
  if (var->type == BOMB_TYPE_VALUE) {
      type = BOMB_DATA_VALUE;
    }
  else {
#line 102
    if (var->type == BOMB_TYPE_SENSE) {
        type = var->sense.type;
      }
    }
  if (buffer->type == BOMB_DATA_NONE) {
      buffer->type = type;
      return SUCCESS;
    }
  else {
#line 110
    if (buffer->type == type) {
        return SUCCESS;
      }
    else {
        return FAIL;
      }
    }
}

static  
#line 204
result_t BBuffer$Buffer$get(BombillaContext *context, 
BombillaDataBuffer *buffer, 
uint8_t bufferIndex, 
BombillaStackVariable *dest)
#line 207
{
  if (bufferIndex >= buffer->size) {
      dbg(DBG_ERROR, "VM: Index %i out of bounds on buffer of size %i.\n", (int )buffer->size, (int )bufferIndex);
      BBuffer$Error$error(context, BOMB_ERROR_INDEX_OUT_OF_BOUNDS);
      return FAIL;
    }
  else {
#line 213
    if (buffer->type == BOMB_DATA_VALUE) {
        dest->type = BOMB_TYPE_VALUE;
        dest->value.var = buffer->entries[bufferIndex];
        return SUCCESS;
      }
    else {
#line 218
      if (buffer->type > BOMB_DATA_VALUE && 
      buffer->type < BOMB_DATA_END) {
          dest->type = BOMB_TYPE_SENSE;
          dest->sense.type = buffer->type;
          dest->sense.var = buffer->entries[bufferIndex];
          return SUCCESS;
        }
      else {
          dbg(DBG_ERROR, "VM: Tried to get entry from buffer of unknown type!\n");
          return FAIL;
        }
      }
    }
}

static  
#line 118
result_t BBuffer$Buffer$append(BombillaContext *context, 
BombillaDataBuffer *buffer, 
BombillaStackVariable *var)
#line 120
{
  if (buffer->size >= BOMB_BUF_LEN) {
      dbg(DBG_ERROR, "VM: Data buffer overrun.\n");
      BBuffer$Error$error(context, BOMB_ERROR_BUFFER_OVERFLOW);
      return FAIL;
    }
  if (BBuffer$Buffer$checkAndSetTypes(context, buffer, var) == FAIL) {
      BBuffer$Error$error(context, BOMB_ERROR_TYPE_CHECK);
      return FAIL;
    }
  if (var->type == BOMB_TYPE_VALUE) {
      buffer->entries[(int )buffer->size] = var->value.var;
      buffer->size++;
      return SUCCESS;
    }
  else {
#line 135
    if (var->type == BOMB_TYPE_SENSE) {
        buffer->entries[(int )buffer->size] = var->sense.var;
        buffer->size++;
        return SUCCESS;
      }
    else {
        dbg(DBG_USR1, "VM: Buffers only contain values or readings.\n");
        return FAIL;
      }
    }
}

static  
# 129 "/root/src/tinyos-1.x/tos/lib/VM/components/BStacks.nc"
result_t BStacks$Stacks$pushBuffer(BombillaContext *context, 
BombillaDataBuffer *buffer)
#line 130
{
  if (context->opStack.sp >= BOMB_OPDEPTH) {
      dbg(DBG_ERROR, "VM: Tried to push value off end of stack.\n");
      BStacks$BombillaError$error(context, BOMB_ERROR_STACK_OVERFLOW);
      return FAIL;
    }
  else {
      uint8_t sIndex = context->opStack.sp;

#line 138
      context->opStack.stack[(int )sIndex].type = BOMB_TYPE_BUFFER;
      context->opStack.stack[(int )sIndex].buffer.var = buffer;
      context->opStack.sp++;
      return SUCCESS;
    }

  return SUCCESS;
}

static  
#line 226
uint8_t BStacks$Types$checkTypes(BombillaContext *context, 
BombillaStackVariable *var, 
uint8_t types)
#line 228
{
  uint8_t rval = (uint8_t )(var->type & types);

#line 230
  if (!rval) {
      dbg(DBG_USR1 | DBG_ERROR, "VM: Operand failed type check: type = %i, allowed types = %i\n", (int )var->type, (int )types);
      BStacks$BombillaError$error(context, BOMB_ERROR_TYPE_CHECK);
    }
  return rval;
}

static  
# 98 "/root/src/tinyos-1.x/tos/lib/VM/components/BLocks.nc"
result_t BLocks$Locks$unlock(BombillaContext *context, uint8_t lockNum)
#line 98
{
  context->heldSet[lockNum / 8] &= ~(1 << lockNum % 8);
  BLocks$locks[tos_state.current_node][lockNum].holder = 0;
  dbg(DBG_USR2, "VM: Context %i unlocking lock %i\n", (int )context->which, (int )lockNum);
  return SUCCESS;
}

static  
# 243 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
void BContextSynch$Synch$yieldContext(BombillaContext *context)
#line 243
{
  BombillaContext *start = (void *)0;
  BombillaContext *current = (void *)0;

#line 246
  dbg(DBG_USR2, "VM (%i): Yielding.\n", (int )context->which);
  if (!BContextSynch$Queue$empty(&BContextSynch$readyQueue[tos_state.current_node])) {
      do {
          current = BContextSynch$Queue$dequeue(context, &BContextSynch$readyQueue[tos_state.current_node]);
          if (!BContextSynch$Synch$resumeContext(context, current)) {
              dbg(DBG_USR2, "VM (%i): Context %i not runnable.\n", (int )context->which, (int )current->which);
              if (start == (void *)0) {
                  start = current;
                }
              else {
#line 255
                if (start == current) {
                    dbg(DBG_USR2, "VM (%i): Looped on ready queue. End checks.\n", (int )context->which);
                    break;
                  }
                }
            }
        }
      while (
#line 261
      !BContextSynch$Queue$empty(&BContextSynch$readyQueue[tos_state.current_node]));
    }
  else {
      dbg(DBG_USR2, "VM (%i): Ready queue empty.\n", (int )context->which);
    }
}

static  
# 129 "/root/src/tinyos-1.x/tos/lib/VM/components/BQueue.nc"
bool BQueue$Queue$empty(BombillaQueue *queue)
#line 129
{
  bool emp = BQueue$list_empty(& queue->queue);

#line 131
  dbg(DBG_USR2, "VM: Testing if queue at 0x%x is empty: %s.\n", queue, emp ? "true" : "false");
  return emp;
}

static  
# 147 "/root/src/tinyos-1.x/tos/lib/VM/components/BStacks.nc"
result_t BStacks$Stacks$pushOperand(BombillaContext *context, 
BombillaStackVariable *var)
#line 148
{
  if (context->opStack.sp >= BOMB_OPDEPTH) {
      dbg(DBG_ERROR, "VM: Tried to push value off end of stack.\n");
      BStacks$BombillaError$error(context, BOMB_ERROR_STACK_OVERFLOW);
      return FAIL;
    }
  else {
      uint8_t sIndex = context->opStack.sp;

#line 156
      context->opStack.stack[(int )sIndex] = *var;
      context->opStack.sp++;
      return SUCCESS;
    }

  return SUCCESS;
}

static   
# 88 "/root/src/tinyos-1.x/tos/platform/pc/LedsC.nc"
result_t LedsC$Leds$redOff(void)
#line 88
{
  dbg(DBG_LED, "LEDS: Red off.\n");
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 90
    {
      if (LedsC$ledsOn[tos_state.current_node] & LedsC$RED_BIT) {
          LedsC$ledsOn[tos_state.current_node] &= ~LedsC$RED_BIT;
          LedsC$updateLeds();
        }
    }
#line 95
    __nesc_atomic_end(__nesc_atomic); }
  return SUCCESS;
}

static   
#line 121
result_t LedsC$Leds$greenOff(void)
#line 121
{
  dbg(DBG_LED, "LEDS: Green off.\n");
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 123
    {
      if (LedsC$ledsOn[tos_state.current_node] & LedsC$GREEN_BIT) {
          LedsC$ledsOn[tos_state.current_node] &= ~LedsC$GREEN_BIT;
          LedsC$updateLeds();
        }
    }
#line 128
    __nesc_atomic_end(__nesc_atomic); }
  return SUCCESS;
}

static   
#line 154
result_t LedsC$Leds$yellowOff(void)
#line 154
{
  dbg(DBG_LED, "LEDS: Yellow off.\n");
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 156
    {
      if (LedsC$ledsOn[tos_state.current_node] & LedsC$YELLOW_BIT) {
          LedsC$ledsOn[tos_state.current_node] &= ~LedsC$YELLOW_BIT;
          LedsC$updateLeds();
        }
    }
#line 161
    __nesc_atomic_end(__nesc_atomic); }
  return SUCCESS;
}

static   
#line 99
result_t LedsC$Leds$redToggle(void)
#line 99
{
  result_t rval;

#line 101
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 101
    {
      if (LedsC$ledsOn[tos_state.current_node] & LedsC$RED_BIT) {
        rval = LedsC$Leds$redOff();
        }
      else {
#line 105
        rval = LedsC$Leds$redOn();
        }
    }
#line 107
    __nesc_atomic_end(__nesc_atomic); }
#line 107
  return rval;
}

static   
#line 132
result_t LedsC$Leds$greenToggle(void)
#line 132
{
  result_t rval;

#line 134
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 134
    {
      if (LedsC$ledsOn[tos_state.current_node] & LedsC$GREEN_BIT) {
        rval = LedsC$Leds$greenOff();
        }
      else {
#line 138
        rval = LedsC$Leds$greenOn();
        }
    }
#line 140
    __nesc_atomic_end(__nesc_atomic); }
#line 140
  return rval;
}

static   
#line 165
result_t LedsC$Leds$yellowToggle(void)
#line 165
{
  result_t rval;

#line 167
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 167
    {
      if (LedsC$ledsOn[tos_state.current_node] & LedsC$YELLOW_BIT) {
        rval = LedsC$Leds$yellowOff();
        }
      else {
#line 171
        rval = LedsC$Leds$yellowOn();
        }
    }
#line 173
    __nesc_atomic_end(__nesc_atomic); }
#line 173
  return rval;
}

static  
# 206 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
result_t AMPromiscuous$SendMsg$send(uint8_t id, uint16_t addr, uint8_t length, TOS_MsgPtr data)
#line 206
{
  if (!AMPromiscuous$state[tos_state.current_node]) {
      AMPromiscuous$state[tos_state.current_node] = TRUE;

      if (length > DATA_LENGTH) {
          dbg(DBG_AM, "AM: Send length too long: %i. Fail.\n", (int )length);
          AMPromiscuous$state[tos_state.current_node] = FALSE;
          return FAIL;
        }
      if (!TOS_post(AMPromiscuous$sendTask)) {
          dbg(DBG_AM, "AM: post sendTask failed.\n");
          AMPromiscuous$state[tos_state.current_node] = FALSE;
          return FAIL;
        }
      else {
          AMPromiscuous$buffer[tos_state.current_node] = data;
          data->length = length;
          data->addr = addr;
          data->type = id;
          AMPromiscuous$buffer[tos_state.current_node]->group = TOS_AM_GROUP;
          if (addr != TOS_BCAST_ADDR && id == 0x1e) {
              AMPromiscuous$am_test_func();
            }
          dbg(DBG_AM, "Sending message: %hx, %hhx\n\t", addr, id);
          AMPromiscuous$dbgPacket(data);
        }
      return SUCCESS;
    }

  return FAIL;
}

static 
# 48 "/root/src/tinyos-1.x/tos/platform/pc/events.c"
void event_total_cleanup(event_t *event)
#line 48
{
  free(event->data);
  dbg(DBG_MEM, "event_total_cleanup: freeing event data: 0x%x\n", (unsigned int )event->data);
  event->data = (void *)0;
  free(event);
  dbg(DBG_MEM, "event_total_cleanup: freeing event: 0x%x\n", (unsigned int )event);
}

static 
# 146 "/root/src/tinyos-1.x/beta/TOSSIM-packet/packet_sim.c"
void event_backoff_create(event_t *event, int node, long long eventTime)
#line 146
{
  event->mote = node;
  event->force = 0;
  event->pause = 0;
  event->data = (void *)0;
  event->time = eventTime;
  event->handle = event_backoff_handle;
  event->cleanup = event_total_cleanup;
}

static 
#line 182
void corruptPacket(IncomingMsg *msg, int src, int dest)
#line 182
{
  int i;
  uint8_t *buf = (uint8_t *)msg->msg;

#line 185
  dbg(DBG_PACKET, "SIM_PACKET: Corrupting message from %i to %i\n", src, dest);
  for (i = 0; i < 36 + 7; i++) {
      buf[i] = (uint8_t )(rand() & 0xff);
    }
  msg->msg->crc = 0;
}

# 246 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
TOS_MsgPtr   prom_received(TOS_MsgPtr packet)
#line 246
{
  AMPromiscuous$counter[tos_state.current_node]++;
  dbg(DBG_AM, "AM_address = %hx, %hhx; counter:%i\n", packet->addr, packet->type, (int )AMPromiscuous$counter[tos_state.current_node]);




  if (
#line 250
  packet->group == TOS_AM_GROUP && ((
  AMPromiscuous$promiscuous_mode[tos_state.current_node] == TRUE || 
  packet->addr == TOS_BCAST_ADDR) || 
  packet->addr == TOS_LOCAL_ADDRESS) && (
  AMPromiscuous$crc_check[tos_state.current_node] == FALSE || packet->crc == 1)) 
    {
      uint8_t type = packet->type;
      TOS_MsgPtr tmp;


      dbg(DBG_AM, "Received message:\n\t");
      AMPromiscuous$dbgPacket(packet);
      dbg(DBG_AM, "AM_type = %d\n", type);


      tmp = AMPromiscuous$ReceiveMsg$receive(type, packet);
      if (tmp) {
        packet = tmp;
        }
    }
  return packet;
}

static 
#line 156
void AMPromiscuous$dbgPacket(TOS_MsgPtr data)
#line 156
{
  uint8_t i;

  for (i = 0; i < sizeof(TOS_Msg ); i++) 
    {
      dbg_clear(DBG_AM, "%02hhx ", ((uint8_t *)data)[i]);
    }
  dbg(DBG_AM, "\n");
}

static  
# 186 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopEngineGridM.nc"
TOS_MsgPtr MultiHopEngineGridM$ReceiveMsg$receive(uint8_t id, TOS_MsgPtr pMsg)
#line 186
{
  TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)pMsg->data;
  uint16_t PayloadLen = pMsg->length - (size_t )& ((TOS_MHopMsg *)0)->data;

  dbg(DBG_ROUTE, "MHop: Msg Rcvd, src 0x%02x, org 0x%02x, parent 0x%02x\n", 
  pMHMsg->sourceaddr, pMHMsg->originaddr, 0);


  if (pMsg->addr == TOS_LOCAL_ADDRESS) {
      if (MultiHopEngineGridM$Intercept$intercept(id, pMsg, &pMHMsg->data[0], PayloadLen) == SUCCESS) {
          if (pMHMsg->originaddr != TOS_LOCAL_ADDRESS) {
              pMsg = MultiHopEngineGridM$mForward(pMsg, id);
            }
          else {
              dbg(DBG_ROUTE, "MHop: Signalling receive\n");
              return MultiHopEngineGridM$Receive$receive(id, pMsg, pMHMsg->data, 36 - 7);
            }
        }
    }
  else {

      MultiHopEngineGridM$Snoop$intercept(id, pMsg, &pMHMsg->data[0], PayloadLen);
    }

  return pMsg;
}

static  
# 469 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
result_t BVirusExtended$InterceptRouted$intercept(TOS_MsgPtr msg, 
void *payload, 
uint16_t payloadLen)
#line 471
{
  BombillaCapsuleMsg *cMsg = (BombillaCapsuleMsg *)payload;
  BombillaCapsule *capsule = & cMsg->capsule;

#line 474
  if (msg->type != 66) {
#line 474
      return FAIL;
    }
  BVirusExtended$receiveCapsule(capsule, payloadLen, "intercepted");
  return SUCCESS;
}

static 
#line 220
result_t BVirusExtended$receiveCapsule(BombillaCapsule *capsule, uint16_t payloadLen, char *type)
#line 220
{
  uint8_t idx = BVirusExtended$typeToIndex(capsule->type);

#line 222
  if (BVirusExtended$capsules[tos_state.current_node][idx] != (void *)0 && 
  capsule->version > BVirusExtended$capsules[tos_state.current_node][idx]->version) {
      int len = payloadLen < sizeof(BombillaCapsule ) ? payloadLen : sizeof(BombillaCapsule );

      {
        char timeVal[128];

#line 228
        printTime(timeVal, 128);
        dbg(DBG_USR3 | DBG_TEMP, "BVirus: Received and installing %s capsule %i, version %i @ %s\n", type, (int )capsule->type, (int )capsule->version, timeVal);
      }

      if (capsule->type & BOMB_OPTION_FORCE) {
          BVirusExtended$Virus$capsuleForce(capsule->type & BOMB_OPTION_MASK);
          nmemcpy(BVirusExtended$capsules[tos_state.current_node][idx], capsule, len);
          BVirusExtended$Virus$capsuleInstalled(BVirusExtended$capsules[tos_state.current_node][idx]);
          dbg(DBG_USR3, "BVirus: installed a routed forced capsule: %i\n", (int )idx);
          BVirusExtended$tau[tos_state.current_node] = BVirusExtended$TAU_INIT;
          BVirusExtended$newVersionCounter();
          return SUCCESS;
        }
      else {
#line 241
        if (BVirusExtended$Virus$capsuleHeard(capsule->type) == SUCCESS) {
            nmemcpy(BVirusExtended$capsules[tos_state.current_node][idx], capsule, len);
            BVirusExtended$Virus$capsuleInstalled(BVirusExtended$capsules[tos_state.current_node][idx]);
            dbg(DBG_USR3, "BVirus: installed a routed capsule\n");
            BVirusExtended$tau[tos_state.current_node] = BVirusExtended$TAU_INIT;
            BVirusExtended$newVersionCounter();
            return SUCCESS;
          }
        else {
            dbg(DBG_USR3, "BVirus: routed capsule installation rejected\n");
          }
        }
    }
  else {
      dbg(DBG_USR3, "%i: BVirus: Received capsule %i (idx %i), version %i, no such capsule or already have it.\n", (int )capsule->type, (int )idx, (int )capsule->version);
    }
  return FAIL;
}

static  
# 210 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetvar4M.nc"
result_t OPgetsetvar4M$Virus$capsuleInstalled(BombillaCapsule *capsule)
#line 210
{
  int i;

#line 212
  for (i = 0; i < BOMB_HEAPSIZE; i++) {
      OPgetsetvar4M$heap[tos_state.current_node][(int )i].type = BOMB_TYPE_VALUE;
      OPgetsetvar4M$heap[tos_state.current_node][(int )i].value.var = 0;
    }
  return SUCCESS;
}

static  
# 138 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetlocal3M.nc"
result_t OPgetsetlocal3M$Virus$capsuleInstalled(BombillaCapsule *capsule)
#line 138
{
  int i;
#line 139
  int j;

#line 140
  for (i = 0; i < BOMB_CAPSULE_NUM; i++) {
      for (j = 0; j < 1 << 3; j++) {
          OPgetsetlocal3M$vars[tos_state.current_node][i][j].type = BOMB_TYPE_VALUE;
          OPgetsetlocal3M$vars[tos_state.current_node][i][j].value.var = 0;
        }
    }
  return SUCCESS;
}

static  
# 158 "/root/src/tinyos-1.x/tos/lib/VM/contexts/Timer1ContextM.nc"
result_t Timer1ContextM$Virus$capsuleInstalled(BombillaCapsule *capsule)
#line 158
{
  Timer1ContextM$Synch$initializeContext(&Timer1ContextM$clockContext[tos_state.current_node]);
  if ((capsule->type & BOMB_OPTION_MASK) == BOMB_CAPSULE_TIMER1) {
      dbg(DBG_USR1, "VM: Installing Timer 1 Capsule. \n");
      Timer1ContextM$clockContext[tos_state.current_node].rootCapsule.capsule = *capsule;
      Timer1ContextM$Analysis$analyzeCapsuleVars(& Timer1ContextM$clockContext[tos_state.current_node].rootCapsule);
      Timer1ContextM$Comm$reboot();
    }
  return SUCCESS;
}

static  
# 134 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbpush1M.nc"
result_t OPbpush1M$Virus$capsuleInstalled(BombillaCapsule *capsule)
#line 134
{
  int i;

#line 136
  for (i = 0; i < BOMB_BUF_NUM; i++) {
      OPbpush1M$buffers[tos_state.current_node][i].type = BOMB_DATA_NONE;
      OPbpush1M$buffers[tos_state.current_node][i].size = 0;
    }
  return SUCCESS;
}

static  
# 189 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPuartM.nc"
result_t OPuartM$Virus$capsuleInstalled(BombillaCapsule *capsule)
#line 189
{
  OPuartM$sendingContext[tos_state.current_node] = (void *)0;
  OPuartM$Queue$init(&OPuartM$sendWaitQueue[tos_state.current_node]);
  return SUCCESS;
}

static 
# 152 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
void BVirusExtended$newVersionCounter(void)
#line 152
{
  BVirusExtended$versionThreshold[tos_state.current_node] = BVirusExtended$tau[tos_state.current_node] / 2 + (uint16_t )BVirusExtended$Random$rand() % (BVirusExtended$tau[tos_state.current_node] / 2);

  BVirusExtended$versionHeard[tos_state.current_node] = 0;
  BVirusExtended$versionCounter[tos_state.current_node] = 0;
  BVirusExtended$versionCancelled[tos_state.current_node] = 0;
}

static  
# 146 "/root/src/tinyos-1.x/tos/lib/Queue/QueuedSendM.nc"
result_t QueuedSendM$QueueSendMsg$send(uint8_t id, uint16_t address, uint8_t length, TOS_MsgPtr msg)
#line 146
{


  if (address != TOS_BCAST_ADDR && (id == 0x1e || id == 0x1c)) {
      QueuedSendM$queue_test_func();
    }
  if ((QueuedSendM$enqueue_next[tos_state.current_node] + 1) % QueuedSendM$MESSAGE_QUEUE_SIZE == QueuedSendM$dequeue_next[tos_state.current_node]) {

      return FAIL;
    }
  QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$enqueue_next[tos_state.current_node]].address = address;
  QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$enqueue_next[tos_state.current_node]].length = length;
  QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$enqueue_next[tos_state.current_node]].id = id;
  QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$enqueue_next[tos_state.current_node]].pMsg = msg;
  QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$enqueue_next[tos_state.current_node]].xmit_count = 0;
  QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$enqueue_next[tos_state.current_node]].pMsg->ack = 0;

  QueuedSendM$enqueue_next[tos_state.current_node]++;
#line 163
  QueuedSendM$enqueue_next[tos_state.current_node] %= QueuedSendM$MESSAGE_QUEUE_SIZE;










  if (QueuedSendM$fQueueIdle[tos_state.current_node]) {
      QueuedSendM$fQueueIdle[tos_state.current_node] = FALSE;
      TOS_post(QueuedSendM$QueueServiceTask);
    }
  return SUCCESS;
}

static  
#line 122
void QueuedSendM$QueueServiceTask(void)
#line 122
{
  uint8_t id;

  if (QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$dequeue_next[tos_state.current_node]].length != 0) {
      QueuedSendM$Leds$greenToggle();

      id = QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$dequeue_next[tos_state.current_node]].id;

      if (!QueuedSendM$SerialSendMsg$send(id, QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$dequeue_next[tos_state.current_node]].address, 
      QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$dequeue_next[tos_state.current_node]].length, 
      QueuedSendM$msgqueue[tos_state.current_node][QueuedSendM$dequeue_next[tos_state.current_node]].pMsg)) {
        }
    }
  else 
    {
      QueuedSendM$fQueueIdle[tos_state.current_node] = TRUE;
    }
}

static  
# 142 "/root/src/tinyos-1.x/tos/system/TimerM.nc"
result_t TimerM$Timer$stop(uint8_t id)
#line 142
{

  if (id >= NUM_TIMERS) {
#line 144
    return FAIL;
    }
#line 145
  if (TimerM$mState[tos_state.current_node] & (0x1 << id)) {
      { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 146
        TimerM$mState[tos_state.current_node] &= ~(0x1 << id);
#line 146
        __nesc_atomic_end(__nesc_atomic); }
      if (!TimerM$mState[tos_state.current_node]) {
          TimerM$setIntervalFlag[tos_state.current_node] = 1;
        }
      return SUCCESS;
    }
  return FAIL;
}

static  
# 151 "/root/src/tinyos-1.x/tos/lib/VM/components/BContextSynch.nc"
result_t BContextSynch$Synch$releaseLocks(BombillaContext *caller, 
BombillaContext *releaser)
#line 152
{
  int8_t i;
  uint8_t *lockSet = releaser->releaseSet;

#line 155
  dbg(DBG_USR2, "VM: Attempting to release specified locks for context %i.\n", releaser->which);
  for (i = 0; i < BOMB_HEAPSIZE; i++) {
      if (lockSet[i / 8] & (1 << i % 8)) {
          BContextSynch$Locks$unlock(releaser, i);
        }
    }
  for (i = 0; i < (BOMB_HEAPSIZE + 7) / 8; i++) {
      releaser->releaseSet[i] = 0;
    }
  return SUCCESS;
}

static  
# 153 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopEngineGridM.nc"
void *MultiHopEngineGridM$Send$getBuffer(uint8_t id, TOS_MsgPtr pMsg, uint16_t *length)
#line 153
{

  TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)pMsg->data;

  *length = 36 - (size_t )& ((TOS_MHopMsg *)0)->data;

  return &pMHMsg->data[0];
}

static  
#line 126
result_t MultiHopEngineGridM$Send$send(uint8_t id, TOS_MsgPtr pMsg, uint16_t PayloadLen)
#line 126
{

  uint16_t usMHLength = (size_t )& ((TOS_MHopMsg *)0)->data + PayloadLen;

  if (usMHLength > 36) {
      return FAIL;
    }

  dbg(DBG_ROUTE, "MHop: send\n");

  MultiHopEngineGridM$RouteSelect$initializeFields(pMsg, id);

  if (MultiHopEngineGridM$RouteSelect$selectRoute(pMsg, id) != SUCCESS) {
      return FAIL;
    }

  dbg(DBG_ROUTE, "MHop: out pkt 0x%x to 0x%x\n", ((TOS_MHopMsg *)pMsg->data)->seqno, ((TOS_MHopMsg *)pMsg->data)->originaddr);

  if (MultiHopEngineGridM$SendMsg$send(id, pMsg->addr, usMHLength, pMsg) != SUCCESS) {
      dbg(DBG_ROUTE, "MHop: send failed\n");
      return FAIL;
    }

  return SUCCESS;
}

static  
# 112 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPbpush1M.nc"
result_t OPbpush1M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 113
{
  uint8_t arg = instr & 1;
  uint8_t lock = OPbpush1M$varToLock(arg);

#line 116
  dbg(DBG_USR1, "VM (%i): Pushing buffer %i onto stack\n", context->which, instr & 0x1);
  if (lock == 255 || !OPbpush1M$Locks$isHeldBy(lock, context)) {
      OPbpush1M$Error$error(context, BOMB_ERROR_INVALID_ACCESS);
      return FAIL;
    }
  OPbpush1M$Stacks$pushBuffer(context, &OPbpush1M$buffers[tos_state.current_node][instr & 0x1]);
  return SUCCESS;
}

static  
# 96 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPsettimer1M.nc"
result_t OPsettimer1M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 97
{
  uint16_t msec;
  BombillaStackVariable *arg = OPsettimer1M$Stacks$popOperand(context);

#line 100
  dbg(DBG_USR1, "VM (%i): Setting timer 1 rate.\n", (int )context->which);
  if (!OPsettimer1M$Types$checkTypes(context, arg, BOMB_VAR_V)) {
#line 101
      return FAIL;
    }
#line 102
  msec = 100 * arg->value.var;
  OPsettimer1M$Timer$stop();
  if (msec > 0) {
      OPsettimer1M$Timer$start(TIMER_REPEAT, msec);
    }
  return SUCCESS;
}

static  
# 87 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OP2pushc10M.nc"
result_t OP2pushc10M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 88
{
  uint16_t arg = instr & 3;

#line 90
  arg = arg << 8;
  arg |= context->currentCapsule->capsule.code[context->pc] & 0xff;
  context->pc++;
  dbg(DBG_USR1, "VM (%i): Executing 2pushc10 with arg %hi\n", (int )context->which, arg);
  return OP2pushc10M$BombillaStacks$pushValue(context, arg);
}

static  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OP2jumps10M.nc"
result_t OP2jumps10M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 91
{
  uint16_t addr = (instr & 0x3) << 8;
  BombillaStackVariable *cond = OP2jumps10M$Stacks$popOperand(context);

  addr |= context->currentCapsule->capsule.code[(int )context->pc];
  context->pc++;

  if (!OP2jumps10M$Types$checkTypes(context, cond, BOMB_VAR_V)) {
#line 98
      return FAIL;
    }
#line 99
  if (cond->value.var > 0) {
      dbg(DBG_USR1, "VM (%i): Stack variable (%i) true, jump to %i.\n", (int )context->which, (int )cond->value.var, (int )addr);
      if (addr < BOMB_PGMSIZE) {
          context->pc = addr;
        }
      else {
          OP2jumps10M$BombillaError$error(context, BOMB_ERROR_INDEX_OUT_OF_BOUNDS);
          return FAIL;
        }
    }
  else {
      dbg(DBG_USR1, "VM (%i): Stack variable false, do not jump.\n", (int )context->which, (int )addr);
    }
  return SUCCESS;
}

static  
# 117 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetlocal3M.nc"
result_t OPgetsetlocal3M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 118
{
  uint8_t arg = instr & 0x7;

#line 120
  if ((instr & ~0x7) == OPsetlocal3) {
      BombillaStackVariable *var = OPgetsetlocal3M$Stacks$popOperand(context);

#line 122
      if (!OPgetsetlocal3M$Types$checkTypes(context, 
      var, 
      BOMB_VAR_V | BOMB_VAR_S)) {
          return FAIL;
        }
      dbg(DBG_USR1, "VM (%i): OPsetlocal3 (%i).\n", (int )context->which, (int )arg);
      OPgetsetlocal3M$vars[tos_state.current_node][context->which][arg] = *var;
      return SUCCESS;
    }
  else {
      dbg(DBG_USR1, "VM (%i): OPgetlocal3 (%i).\n", (int )context->which, (int )arg);
      OPgetsetlocal3M$Stacks$pushOperand(context, &OPgetsetlocal3M$vars[tos_state.current_node][context->which][arg]);
      return SUCCESS;
    }
}

static  
# 184 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPgetsetvar4M.nc"
result_t OPgetsetvar4M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 185
{
  uint8_t arg = instr & 0xf;
  uint8_t lock = OPgetsetvar4M$varToLock(arg);

#line 188
  if (lock == 255 || !OPgetsetvar4M$Locks$isHeldBy(lock, context)) {
      OPgetsetvar4M$Error$error(context, BOMB_ERROR_INVALID_ACCESS);
      return FAIL;
    }
  else {
#line 192
    if ((instr & ~0xf) == OPsetvar4) {
        BombillaStackVariable *var = OPgetsetvar4M$Stacks$popOperand(context);

#line 194
        if (!OPgetsetvar4M$Types$checkTypes(context, 
        var, 
        BOMB_VAR_V | BOMB_VAR_S)) {
            return FAIL;
          }
        dbg(DBG_USR1, "VM (%i): OPsetvarM (%i) executed.\n", (int )context->which, (int )arg);
        OPgetsetvar4M$heap[tos_state.current_node][arg] = *var;
        return SUCCESS;
      }
    else {
        dbg(DBG_USR1, "VM (%i): Executing getvar (%i).\n", (int )context->which, (int )arg);
        OPgetsetvar4M$Stacks$pushOperand(context, &OPgetsetvar4M$heap[tos_state.current_node][arg]);
        return SUCCESS;
      }
    }
}

static  
# 91 "/root/src/tinyos-1.x/tos/lib/VM/opcodes/OPpushc6M.nc"
result_t OPpushc6M$BombillaBytecode$execute(uint8_t instr, 
BombillaContext *context)
#line 92
{
  uint16_t arg = instr & OPpushc6M$OP_PUSHC_ARG_MASKM;

#line 94
  dbg(DBG_USR1, "VM (%i): Executing pushc6 with arg %hi\n", (int )context->which, arg);
  return OPpushc6M$BombillaStacks$pushValue(context, arg);
}

static 
# 260 "/root/src/tinyos-1.x/tos/lib/VM/route/MultiHopGrid.nc"
uint32_t MultiHopGrid$evaluateCost(uint16_t cost, uint8_t sendEst, uint8_t receiveEst)
#line 260
{
  uint32_t transEst = (uint32_t )sendEst * (uint32_t )receiveEst;
  uint32_t immed = (uint32_t )1 << 24;

  if (transEst == 0) {
#line 264
    return (uint32_t )1 << (uint32_t )16;
    }
  immed = immed / transEst;
  immed += (uint32_t )cost << 6;
  return immed;
}

# 98 "/root/src/tinyos-1.x/tos/system/sched.c"
bool  TOS_post(void (*tp)(void))
#line 98
{
  __nesc_atomic_t fInterruptFlags;
  uint8_t tmp;



  fInterruptFlags = __nesc_atomic_start();

  tmp = TOSH_sched_free;
  TOSH_sched_free++;
  TOSH_sched_free &= TOSH_TASK_BITMASK;

  if (TOSH_sched_free != TOSH_sched_full) {
      __nesc_atomic_end(fInterruptFlags);

      TOSH_queue[tmp].tp = tp;
      return TRUE;
    }
  else {
      TOSH_sched_free = tmp;
      __nesc_atomic_end(fInterruptFlags);

      return FALSE;
    }
}

# 334 "/root/src/tinyos-1.x/beta/TOSSIM-packet/Nido.nc"
void   nido_start_mote(uint16_t moteID)
#line 334
{
  if (!tos_state.moteOn[moteID] && moteID < tos_state.num_nodes) {
      __nesc_nido_initialise(moteID);
      tos_state.moteOn[moteID] = 1;
      tos_state.current_node = moteID;
      { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 339
        TOS_LOCAL_ADDRESS = tos_state.current_node;
#line 339
        __nesc_atomic_end(__nesc_atomic); }
      tos_state.node_state[moteID].time = tos_state.tos_time;
      Nido$StdControl$init();
      Nido$StdControl$start();
      tos_state.node_state[moteID].pot_setting = 73;
      while (TOSH_run_next_task()) {
        }
    }
}

static  
# 90 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
result_t AMPromiscuous$Control$init(void)
#line 90
{
  result_t ok1;
#line 91
  result_t ok2;

#line 92
  AMPromiscuous$TimerControl$init();
  ok1 = AMPromiscuous$UARTControl$init();
  ok2 = AMPromiscuous$RadioControl$init();
  AMPromiscuous$state[tos_state.current_node] = FALSE;
  AMPromiscuous$lastCount[tos_state.current_node] = 0;
  AMPromiscuous$counter[tos_state.current_node] = 0;
  AMPromiscuous$promiscuous_mode[tos_state.current_node] = FALSE;
  AMPromiscuous$crc_check[tos_state.current_node] = TRUE;
  dbg(DBG_BOOT, "AM Module initialized\n");

  return rcombine(ok1, ok2);
}

static  
# 72 "/root/src/tinyos-1.x/tos/system/TimerM.nc"
result_t TimerM$StdControl$init(void)
#line 72
{
  TimerM$mState[tos_state.current_node] = 0;
  TimerM$setIntervalFlag[tos_state.current_node] = 0;
  TimerM$queue_head[tos_state.current_node] = TimerM$queue_tail[tos_state.current_node] = -1;
  TimerM$queue_size[tos_state.current_node] = 0;
  TimerM$mScale[tos_state.current_node] = 3;
  TimerM$mInterval[tos_state.current_node] = TimerM$maxTimerInterval;
  return TimerM$Clock$setRate(TimerM$mInterval[tos_state.current_node], TimerM$mScale[tos_state.current_node]);
}

static   
# 59 "/root/src/tinyos-1.x/tos/system/RandomLFSR.nc"
result_t RandomLFSR$Random$init(void)
#line 59
{
  dbg(DBG_BOOT, "RANDOM_LFSR initialized.\n");
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
#line 61
    {
      RandomLFSR$shiftReg[tos_state.current_node] = 119 * 119 * (TOS_LOCAL_ADDRESS + 1);
      RandomLFSR$initSeed[tos_state.current_node] = RandomLFSR$shiftReg[tos_state.current_node];
      RandomLFSR$mask[tos_state.current_node] = 137 * 29 * (TOS_LOCAL_ADDRESS + 1);
    }
#line 65
    __nesc_atomic_end(__nesc_atomic); }
  return SUCCESS;
}

static  
# 210 "/root/src/tinyos-1.x/tos/lib/VM/components/BVirusExtended.nc"
result_t BVirusExtended$Virus$registerCapsule(uint8_t type, BombillaCapsule *capsule)
#line 210
{
  uint8_t idx = BVirusExtended$typeToIndex(type);

#line 212
  if (idx >= BOMB_CAPSULE_NUM) {
      return FAIL;
    }
  BVirusExtended$capsules[tos_state.current_node][idx] = capsule;

  return SUCCESS;
}

static  
# 106 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
result_t AMPromiscuous$Control$start(void)
#line 106
{
  result_t ok0;
#line 107
  result_t ok1;
#line 107
  result_t ok2;
#line 107
  result_t ok3;

  ok0 = AMPromiscuous$TimerControl$start();
  ok1 = AMPromiscuous$UARTControl$start();
  ok2 = AMPromiscuous$RadioControl$start();
  ok3 = AMPromiscuous$ActivityTimer$start(TIMER_REPEAT, 1000);
  AMPromiscuous$PowerManagement$adjustPower();



  AMPromiscuous$state[tos_state.current_node] = FALSE;

  return rcombine4(ok0, ok1, ok2, ok3);
}

static 
# 139 "/root/src/tinyos-1.x/tos/system/sched.c"
bool TOSH_run_next_task(void)
#line 139
{
  __nesc_atomic_t fInterruptFlags;
  uint8_t old_full;
  void (*func)(void );

  if (TOSH_sched_full == TOSH_sched_free) {

      return 0;
    }
  else {

      fInterruptFlags = __nesc_atomic_start();
      old_full = TOSH_sched_full;
      TOSH_sched_full++;
      TOSH_sched_full &= TOSH_TASK_BITMASK;
      func = TOSH_queue[(int )old_full].tp;
      TOSH_queue[(int )old_full].tp = 0;
      __nesc_atomic_end(fInterruptFlags);
      func();
      return 1;
    }
}

# 118 "/root/src/tinyos-1.x/beta/TOSSIM-packet/Nido.nc"
int   main(int argc, char **argv)
#line 118
{
  long long i;

  int num_nodes_total;
  int num_nodes_start = -1;

  unsigned long long max_run_time = 0;

  char *adc_model_name = (void *)0;
  char *model_name = (void *)0;
  char *eeprom_name = (void *)0;

  int start_time = 0;
  int pause_time = 0;
  int start_interval = 10;
  char *rate_constant = "1000.0";
  char *lossy_file = (void *)0;
  char *packet_conf = (void *)0;
  int radio_kb_rate = 40;

  int currentArg;

  if (argc == 2 && (strcmp(argv[1], "-h") == 0 || 
  strcmp(argv[1], "--help") == 0)) {
      Nido$help(argv[0]);
    }

  if (argc < 2) {
#line 145
      Nido$usage(argv[0]);
    }
  dbg_init();

  for (currentArg = 1; currentArg < argc - 1; currentArg++) {
      char *arg = argv[currentArg];

#line 151
      if (strcmp(arg, "-h") == 0 || 
      strcmp(arg, "--help") == 0) {
          Nido$help(argv[0]);
        }
      else {
#line 155
        if (strcmp(argv[currentArg], "--help") == 0) {
            Nido$help(argv[0]);
          }
        else {
#line 158
          if (strcmp(arg, "-gui") == 0) {
              GUI_enabled = 1;
            }
          else {
#line 161
            if (strncmp(arg, "-a=", 3) == 0) {
                arg += 3;
                adc_model_name = arg;
              }
            else {
#line 165
              if (strncmp(arg, "-b=", 3) == 0) {
                  arg += 3;
                  start_interval = atoi(arg);
                }
              else {
#line 169
                if (strncmp(arg, "-ef=", 3) == 0) {
                    arg += 4;
                    eeprom_name = arg;
                  }
                else {
#line 173
                  if (strncmp(arg, "-l=", 3) == 0) {
                      arg += 3;
                      rate_constant = arg;
                    }
                  else {
#line 177
                    if (strncmp(arg, "-r=", 3) == 0) {
                        arg += 3;
                        model_name = arg;
                      }
                    else {
#line 181
                      if (strncmp(arg, "-rf=", 4) == 0) {
                          arg += 4;
                          model_name = "lossy";
                          lossy_file = arg;
                        }
                      else {
#line 186
                        if (strncmp(arg, "-pf=", 4) == 0) {
                            arg += 4;
                            model_name = "lossy";
                            packet_conf = arg;
                          }
                        else {
#line 191
                          if (strncmp(arg, "-s=", 3) == 0) {
                              arg += 3;
                              num_nodes_start = atoi(arg);
                            }
                          else {
#line 195
                            if (strncmp(arg, "-t=", 3) == 0) {
                                arg += 3;
                                max_run_time = (unsigned long long )atoi(arg);
                                max_run_time *= 4000000;
                              }
                            else {
                                Nido$usage(argv[0]);
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
    }
#line 205
  set_rate_value(atof(rate_constant));
  if (get_rate_value() <= 0.0) {
      fprintf(stderr, "SIM: Invalid rate constant: %s.\n", rate_constant);
      exit(-1);
    }

  num_nodes_total = atoi(argv[argc - 1]);
  if (num_nodes_total <= 0) {
#line 212
      Nido$usage(argv[0]);
    }
  if (num_nodes_start < 0 || num_nodes_start > num_nodes_total) {
      num_nodes_start = num_nodes_total;
    }


  if (num_nodes_total > TOSNODES) {
      fprintf(stderr, "Nido: I am compiled for maximum of %d nodes and you have specified %d nodes.\n", TOSNODES, num_nodes_total);
      fprintf(stderr, "Nido: Exiting...\n");
      exit(-1);
    }

  init_signals();
  initializeSockets();
  tos_state.num_nodes = num_nodes_total;



  if (model_name == (void *)0 || strcmp(model_name, "simple") == 0) {
      tos_state.rfm = create_simple_model();
      tos_state.radioModel = TOSSIM_RADIO_MODEL_SIMPLE;
    }
  else {
#line 235
    if (strcmp(model_name, "lossy") == 0) {
        tos_state.rfm = create_lossy_model(lossy_file);
        tos_state.radioModel = TOSSIM_RADIO_MODEL_LOSSY;
      }
    else {
        fprintf(stderr, "SIM: Don't recognize RFM model type %s.\n", model_name);
        exit(-1);
      }
    }


  if (adc_model_name == (void *)0 || strcmp(adc_model_name, "generic") == 0) {
      tos_state.adc = create_generic_adc_model();
    }
  else {
#line 249
    if (strcmp(adc_model_name, "random") == 0) {
        tos_state.adc = create_random_adc_model();
      }
    else {
        fprintf(stderr, "SIM: Bad ADC model name: %s\n", adc_model_name);
        exit(-1);
      }
    }
#line 256
  if (eeprom_name != (void *)0) {
      namedEEPROM(eeprom_name, num_nodes_total, DEFAULT_EEPROM_SIZE);
    }
  else {
      anonymousEEPROM(num_nodes_total, DEFAULT_EEPROM_SIZE);
    }
  dbg_clear(DBG_SIM | DBG_BOOT, "SIM: EEPROM system initialized.\n");

  tos_state.space = create_simple_spatial_model();

  tos_state.radio_kb_rate = radio_kb_rate;
  tos_state_model_init();
  if (packet_conf != (void *)0) {
      packet_sim_init(packet_conf);
    }
  init_hardware();

  queue_init(& tos_state.queue, pause_time);
  dbg_clear(DBG_SIM, "SIM: event queue initialized.\n");

  if (GUI_enabled) {
      waitForGuiConnection();
    }

  for (i = 0; i < num_nodes_start; i++) {

      int rval = rand();

#line 283
      if (start_interval > 0) {
          rval %= 4000000 * start_interval;
        }
      start_time = rval + i;
      tos_state.node_state[i].time = start_time;
      dbg_clear(DBG_SIM | DBG_USR3, "SIM: Time for mote %lli initialized to %lli.\n", 
      i, tos_state.node_state[i].time);
    }

  for (i = 0; i < num_nodes_start; i++) {
      char timeVal[128];
      event_t *fevent = (event_t *)malloc(sizeof(event_t ));

#line 295
      fevent->mote = i;
      fevent->time = tos_state.node_state[i].time;
      fevent->handle = event_boot_handle;
      fevent->cleanup = event_default_cleanup;
      fevent->pause = 0;
      fevent->force = 1;
      queue_insert_event(& tos_state.queue, fevent);
#line 301
      ;
      printOtherTime(timeVal, 128, tos_state.node_state[i].time);
      dbg(DBG_BOOT, "BOOT: Scheduling for boot at %s.\n", timeVal);
    }

  rate_checkpoint();

  for (; ; ) {
      if (max_run_time > 0 && tos_state.tos_time >= max_run_time) {
          break;
        }

      pthread_mutex_lock(& tos_state.pause_lock);
      if (tos_state.paused == TRUE) {
          pthread_cond_signal(& tos_state.pause_ack_cond);
          pthread_cond_wait(& tos_state.pause_cond, & tos_state.pause_lock);
        }
      pthread_mutex_unlock(& tos_state.pause_lock);

      while (TOSH_run_next_task()) {
        }
#line 321
      if (!queue_is_empty(& tos_state.queue)) {
          tos_state.tos_time = queue_peek_event_time(& tos_state.queue);
          queue_handle_next_event(& tos_state.queue);



          rate_based_wait();
        }
    }
  printf("Simulation of %i motes completed.\n", num_nodes_total);
  return 0;
}

static 
#line 78
void Nido$help(char *progname)
#line 78
{
  fprintf(stderr, "Usage: %s [options] num_nodes\n", progname);
  fprintf(stderr, "  [options] are:\n");
  fprintf(stderr, "  -h, --help        Display this message.\n");
  fprintf(stderr, "  -gui              pauses simulation waiting for GUI to connect\n");
  fprintf(stderr, "  -a=<model>        specifies ADC model (generic is default)\n");
  fprintf(stderr, "                    options: generic random\n");
  fprintf(stderr, "  -b=<sec>          motes boot over first <sec> seconds (default 10)\n");
  fprintf(stderr, "  -e=<file>         use <file> for eeprom; otherwise anonymous file is used\n");
  fprintf(stderr, "  -l=<scale>        run sim at <scale> times real time (fp constant)\n");
  fprintf(stderr, "  -r=<model>        specifies a radio model (simple is default)\n");
  fprintf(stderr, "                    options: simple lossy\n");
  fprintf(stderr, "  -pf=<file>        specifies file for packet mode\n");
  fprintf(stderr, "  -rf=<file>        specifies file for lossy mode (lossy.nss is default)\n");
  fprintf(stderr, "                    implicitly selects lossy model\n");
  fprintf(stderr, "  -s=<num>          only boot <num> of nodes\n");
  fprintf(stderr, "  -t=<sec>          run simulation for <sec> virtual seconds\n");
  fprintf(stderr, "  num_nodes         number of nodes to simulate\n");

  fprintf(stderr, "\n");
  dbg_help();
  fprintf(stderr, "\n");
  exit(-1);
}

static 
# 150 "/root/src/tinyos-1.x/tos/platform/pc/external_comm.c"
int createServerSocket(short port)
#line 150
{
  struct sockaddr_in sock;
  int sfd;
  int rval = -1;
  long enable = 1;

  memset(&sock, 0, sizeof sock);
  sock.sin_family = 2;
  sock.sin_port = htons(port);
  sock.sin_addr.s_addr = htonl((in_addr_t )0x00000000);

  sfd = socket(2, SOCK_STREAM, 0);
  if (sfd < 0) {
      dbg_clear(DBG_SIM | DBG_ERROR, "SIM: Could not create server socket: %s\n", strerror(*__errno_location()));
      exit(-1);
    }
  setsockopt(sfd, 1, 2, (char *)&enable, sizeof(int ));

  while (rval < 0) {
      rval = bind(sfd, (struct sockaddr *)&sock, sizeof sock);
      if (rval < 0) {
          dbg_clear(DBG_SIM | DBG_ERROR, "SIM: Could not bind server socket to port %d: %s\n", port, strerror(*__errno_location()));
          dbg_clear(DBG_SIM | DBG_ERROR, "SIM: Perhaps another copy of TOSSIM is already running?\n");
          dbg_clear(DBG_SIM | DBG_ERROR, "SIM: Will retry in 10 seconds.\n");
          sleep(10);
        }
    }

  if (listen(sfd, 1) < 0) {
      dbg_clear(DBG_SIM | DBG_ERROR, "SIM: Could not listen on server socket: %s\n", strerror(*__errno_location()));
      exit(-1);
    }
  dbg_clear(DBG_SIM, "SIM: Created server socket listening on port %d.\n", port);
  return sfd;
}

static 
#line 134
int acceptConnection(int servfd)
#line 134
{
  struct sockaddr_in cli_addr;
  int clilen = sizeof cli_addr;
  int clifd;

  ;
  clifd = accept(servfd, (struct sockaddr *)&cli_addr, &clilen);
  if (clifd < 0) {
      ;

      exit(-1);
    }
  ;
  return clifd;
}

static 
#line 248
void addClient(int *clientSockets, int clifd)
#line 248
{
  int i;

  for (i = 0; i < 4; i++) {
      if (clientSockets[i] == -1) {
          clientSockets[i] = clifd;
          return;
        }
    }


  close(clifd);
}

static 
# 47 "/root/src/tinyos-1.x/tos/platform/pc/adjacency_list.c"
link_t *allocate_link(int mote)
#line 47
{
  link_t *alloc_link;
  int i;

#line 50
  if (0 == num_free_links) {
      alloc_link = (link_t *)malloc(sizeof(link_t ) * NUM_NODES_ALLOC);
      for (i = 0; i < NUM_NODES_ALLOC - 1; i++) {
          alloc_link[i].next_link = &alloc_link[i + 1];
        }
      alloc_link[NUM_NODES_ALLOC - 1].next_link = free_list;
      free_list = alloc_link;
      num_free_links += NUM_NODES_ALLOC;
    }
  else {
      alloc_link = free_list;
    }

  free_list = free_list->next_link;
  alloc_link->mote = mote;
  alloc_link->next_link = (void *)0;
  num_free_links--;
  return alloc_link;
}

static  
# 123 "/root/src/tinyos-1.x/tos/lib/VM/components/AMPromiscuous.nc"
result_t AMPromiscuous$Control$stop(void)
#line 123
{
  result_t ok1;
#line 124
  result_t ok2;
#line 124
  result_t ok3;

#line 125
  if (AMPromiscuous$state[tos_state.current_node]) {
#line 125
    return FALSE;
    }
#line 126
  ok1 = AMPromiscuous$UARTControl$stop();
  ok2 = AMPromiscuous$RadioControl$stop();
  ok3 = AMPromiscuous$ActivityTimer$stop();

  AMPromiscuous$PowerManagement$adjustPower();
  return rcombine3(ok1, ok2, ok3);
}

static 
# 78 "/root/src/tinyos-1.x/tos/platform/pc/adjacency_list.c"
int adjacency_list_init(void)
#line 78
{
  int i;

#line 80
  free_list = (link_t *)malloc(sizeof(link_t ) * NUM_NODES_ALLOC);
  for (i = 0; i < NUM_NODES_ALLOC - 1; i++) {
      free_list[i].next_link = &free_list[i + 1];
    }
  free_list[NUM_NODES_ALLOC - 1].next_link = (void *)0;
  num_free_links = NUM_NODES_ALLOC;
  return SUCCESS;
}

static 
# 194 "/root/src/tinyos-1.x/tos/platform/pc/rfm_model.c"
void static_one_cell_init(void)
#line 194
{
  int i;
#line 195
  int j;
  link_t *new_link;

  pthread_mutex_init(&radioConnectivityLock, (void *)0);
  radio_connectivity[0] = (void *)0;

  for (i = 0; i < tos_state.num_nodes; i++) {
      for (j = 0; j < tos_state.num_nodes; j++) {
          if (i != j) {
              new_link = allocate_link(j);
              new_link->data = 0.0;

              new_link->next_link = radio_connectivity[i];
              radio_connectivity[i] = new_link;
            }
        }
    }
}

static 
# 57 "/root/src/tinyos-1.x/tos/platform/pc/eeprom.c"
int createEEPROM(char *file, int motes, int eempromBytes)
#line 57
{
  int rval;
  char val = 0;

  filename = file;
  numMotes = motes;
  moteSize = eempromBytes;

  if (initialized) {
      dbg(DBG_ERROR, "ERROR: Trying to initialize EEPROM twice.\n");
      return -1;
    }
  fd = open(file, 02 | 0100, (((0400 | 0200) | 0100) | (0400 >> 3)) | ((0400 >> 3) >> 3));

  if (fd < 0) {
      dbg(DBG_ERROR, "ERROR: Unable to create EEPROM backing store file.\n");
      return -1;
    }

  rval = (int )lseek(fd, moteSize * numMotes, 0);
  if (rval < 0) {
      dbg(DBG_ERROR, "ERROR: Unable to establish EEPROM of correct size.\n");
    }

  rval = write(fd, &val, 1);
  if (rval < 0) {
      dbg(DBG_ERROR, "ERROR: Unable to establish EEPROM of correct size.\n");
    }
  initialized = 1;

  return fd;
}

static 
# 311 "/root/src/tinyos-1.x/beta/TOSSIM-packet/packet_sim.c"
int read_int(FILE *file)
#line 311
{
  char buf[128];
  int findex = 0;
  int ch;

#line 315
  while (1) {
      ch = _IO_getc(file);
      if (ch == -1) {
#line 317
          return -1;
        }
      else {
#line 318
        if (ch >= '0' && ch <= '9') {
            buf[findex] = (char )ch;
            findex++;
          }
        else {
#line 322
          if ((ch == '\n' || ch == ' ') || ch == '\t') {
              if (findex == 0) {
                  continue;
                }
              else {
                  buf[findex] = 0;
                  break;
                }
            }
          else {
              return -1;
            }
          }
        }
#line 334
      if (findex >= 127) {
          return -1;
        }
    }
  return atoi(buf);
}

static double read_double(FILE *file)
#line 341
{
  char buf[128];
  int findex = 0;
  int ch;

#line 345
  while (1) {
      ch = _IO_getc(file);
      if (ch == -1) {
#line 347
          return -1;
        }
      else {
#line 349
        if (((((
#line 348
        ch >= '0' && ch <= '9') || ch == '.') || ch == '-') || ch == 'E')
         || ch == 'e') {
            buf[findex] = (char )ch;
            findex++;
          }
        else {
#line 353
          if ((ch == '\n' || ch == ' ') || ch == '\t') {
              if (findex == 0) {
                  continue;
                }
              else {
                  buf[findex] = 0;
                  break;
                }
            }
          else {
              return -1;
            }
          }
        }
#line 365
      if (findex >= 127) {
          return -1;
        }
    }
  return atof(buf);
}

static 
# 104 "/root/src/tinyos-1.x/tos/platform/pc/heap_array.c"
void *heap_pop_min_data(heap_t *heap, long long *key)
#line 104
{
  int last_index = heap->size - 1;
  void *data = ((node_t *)heap->data)[0].data;

#line 107
  if (key != (void *)0) {
      *key = ((node_t *)heap->data)[0].key;
    }
  ((node_t *)heap->data)[0].data = ((node_t *)heap->data)[last_index].data;
  ((node_t *)heap->data)[0].key = ((node_t *)heap->data)[last_index].key;

  heap->size--;

  down_heap(heap, 0);

  return data;
}

static 
#line 161
void down_heap(heap_t *heap, int findex)
#line 161
{
  int right_index = (findex + 1) * 2;
  int left_index = findex * 2 + 1;

  if (right_index < heap->size) {
      long long left_key = ((node_t *)heap->data)[left_index].key;
      long long right_key = ((node_t *)heap->data)[right_index].key;
      int min_key_index = left_key < right_key ? left_index : right_index;

      if (((node_t *)heap->data)[min_key_index].key < ((node_t *)heap->data)[findex].key) {
          swap(&((node_t *)heap->data)[findex], &((node_t *)heap->data)[min_key_index]);
          down_heap(heap, min_key_index);
        }
    }
  else {
#line 175
    if (left_index >= heap->size) {
        return;
      }
    else {
        long long left_key = ((node_t *)heap->data)[left_index].key;

#line 180
        if (left_key < ((node_t *)heap->data)[findex].key) {
            swap(&((node_t *)heap->data)[findex], &((node_t *)heap->data)[left_index]);
            return;
          }
      }
    }
}

/* Nido variable resolver function */

static int __nesc_nido_resolve(int __nesc_mote,
                               char* varname,
                               uint32_t* addr, uint8_t* size)
{
  /* Module BombillaEngineM */
  # 9999 "nesc-generate.c"
  #line 0
  if (!strcmp(varname, "BombillaEngineM$runQueue"))
  {
    *addr = (uint32_t)&BombillaEngineM$runQueue[__nesc_mote];
    *size = sizeof(BombillaEngineM$runQueue[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 10
  if (!strcmp(varname, "BombillaEngineM$capsules"))
  {
    *addr = (uint32_t)&BombillaEngineM$capsules[__nesc_mote];
    *size = sizeof(BombillaEngineM$capsules[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 20
  if (!strcmp(varname, "BombillaEngineM$errorContext"))
  {
    *addr = (uint32_t)&BombillaEngineM$errorContext[__nesc_mote];
    *size = sizeof(BombillaEngineM$errorContext[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 30
  if (!strcmp(varname, "BombillaEngineM$errorMsg"))
  {
    *addr = (uint32_t)&BombillaEngineM$errorMsg[__nesc_mote];
    *size = sizeof(BombillaEngineM$errorMsg[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 40
  if (!strcmp(varname, "BombillaEngineM$inErrorState"))
  {
    *addr = (uint32_t)&BombillaEngineM$inErrorState[__nesc_mote];
    *size = sizeof(BombillaEngineM$inErrorState[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 50
  if (!strcmp(varname, "BombillaEngineM$errorFlipFlop"))
  {
    *addr = (uint32_t)&BombillaEngineM$errorFlipFlop[__nesc_mote];
    *size = sizeof(BombillaEngineM$errorFlipFlop[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 60
  if (!strcmp(varname, "BombillaEngineM$msg"))
  {
    *addr = (uint32_t)&BombillaEngineM$msg[__nesc_mote];
    *size = sizeof(BombillaEngineM$msg[__nesc_mote]);
    return 0;
  }

  /* Module LedsC */
  # 9999 "nesc-generate.c"
  #line 70
  if (!strcmp(varname, "LedsC$ledsOn"))
  {
    *addr = (uint32_t)&LedsC$ledsOn[__nesc_mote];
    *size = sizeof(LedsC$ledsOn[__nesc_mote]);
    return 0;
  }

  /* Module TimerM */
  # 9999 "nesc-generate.c"
  #line 80
  if (!strcmp(varname, "TimerM$mState"))
  {
    *addr = (uint32_t)&TimerM$mState[__nesc_mote];
    *size = sizeof(TimerM$mState[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 90
  if (!strcmp(varname, "TimerM$setIntervalFlag"))
  {
    *addr = (uint32_t)&TimerM$setIntervalFlag[__nesc_mote];
    *size = sizeof(TimerM$setIntervalFlag[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 100
  if (!strcmp(varname, "TimerM$mScale"))
  {
    *addr = (uint32_t)&TimerM$mScale[__nesc_mote];
    *size = sizeof(TimerM$mScale[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 110
  if (!strcmp(varname, "TimerM$mInterval"))
  {
    *addr = (uint32_t)&TimerM$mInterval[__nesc_mote];
    *size = sizeof(TimerM$mInterval[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 120
  if (!strcmp(varname, "TimerM$queue_head"))
  {
    *addr = (uint32_t)&TimerM$queue_head[__nesc_mote];
    *size = sizeof(TimerM$queue_head[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 130
  if (!strcmp(varname, "TimerM$queue_tail"))
  {
    *addr = (uint32_t)&TimerM$queue_tail[__nesc_mote];
    *size = sizeof(TimerM$queue_tail[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 140
  if (!strcmp(varname, "TimerM$queue_size"))
  {
    *addr = (uint32_t)&TimerM$queue_size[__nesc_mote];
    *size = sizeof(TimerM$queue_size[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 150
  if (!strcmp(varname, "TimerM$queue"))
  {
    *addr = (uint32_t)&TimerM$queue[__nesc_mote];
    *size = sizeof(TimerM$queue[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 160
  if (!strcmp(varname, "TimerM$mTimerList"))
  {
    *addr = (uint32_t)&TimerM$mTimerList[__nesc_mote];
    *size = sizeof(TimerM$mTimerList[__nesc_mote]);
    return 0;
  }

  /* Module HPLClock */
  # 9999 "nesc-generate.c"
  #line 170
  if (!strcmp(varname, "HPLClock$set_flag"))
  {
    *addr = (uint32_t)&HPLClock$set_flag[__nesc_mote];
    *size = sizeof(HPLClock$set_flag[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 180
  if (!strcmp(varname, "HPLClock$mscale"))
  {
    *addr = (uint32_t)&HPLClock$mscale[__nesc_mote];
    *size = sizeof(HPLClock$mscale[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 190
  if (!strcmp(varname, "HPLClock$nextScale"))
  {
    *addr = (uint32_t)&HPLClock$nextScale[__nesc_mote];
    *size = sizeof(HPLClock$nextScale[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 200
  if (!strcmp(varname, "HPLClock$minterval"))
  {
    *addr = (uint32_t)&HPLClock$minterval[__nesc_mote];
    *size = sizeof(HPLClock$minterval[__nesc_mote]);
    return 0;
  }

  /* Module NoLeds */

  /* Module HPLPowerManagementM */

  /* Module AMPromiscuous */
  # 9999 "nesc-generate.c"
  #line 210
  if (!strcmp(varname, "AMPromiscuous$state"))
  {
    *addr = (uint32_t)&AMPromiscuous$state[__nesc_mote];
    *size = sizeof(AMPromiscuous$state[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 220
  if (!strcmp(varname, "AMPromiscuous$buffer"))
  {
    *addr = (uint32_t)&AMPromiscuous$buffer[__nesc_mote];
    *size = sizeof(AMPromiscuous$buffer[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 230
  if (!strcmp(varname, "AMPromiscuous$lastCount"))
  {
    *addr = (uint32_t)&AMPromiscuous$lastCount[__nesc_mote];
    *size = sizeof(AMPromiscuous$lastCount[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 240
  if (!strcmp(varname, "AMPromiscuous$counter"))
  {
    *addr = (uint32_t)&AMPromiscuous$counter[__nesc_mote];
    *size = sizeof(AMPromiscuous$counter[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 250
  if (!strcmp(varname, "AMPromiscuous$promiscuous_mode"))
  {
    *addr = (uint32_t)&AMPromiscuous$promiscuous_mode[__nesc_mote];
    *size = sizeof(AMPromiscuous$promiscuous_mode[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 260
  if (!strcmp(varname, "AMPromiscuous$crc_check"))
  {
    *addr = (uint32_t)&AMPromiscuous$crc_check[__nesc_mote];
    *size = sizeof(AMPromiscuous$crc_check[__nesc_mote]);
    return 0;
  }

  /* Module TossimPacketM */
  # 9999 "nesc-generate.c"
  #line 270
  if (!strcmp(varname, "TossimPacketM$buffer"))
  {
    *addr = (uint32_t)&TossimPacketM$buffer[__nesc_mote];
    *size = sizeof(TossimPacketM$buffer[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 280
  if (!strcmp(varname, "TossimPacketM$bufferPtr"))
  {
    *addr = (uint32_t)&TossimPacketM$bufferPtr[__nesc_mote];
    *size = sizeof(TossimPacketM$bufferPtr[__nesc_mote]);
    return 0;
  }

  /* Module Nido */

  /* Module UARTNoCRCPacketM */

  /* Module NoCRCPacket */

  /* Module AMFilter */

  /* Module BContextSynch */
  # 9999 "nesc-generate.c"
  #line 290
  if (!strcmp(varname, "BContextSynch$readyQueue"))
  {
    *addr = (uint32_t)&BContextSynch$readyQueue[__nesc_mote];
    *size = sizeof(BContextSynch$readyQueue[__nesc_mote]);
    return 0;
  }

  /* Module BLocks */
  # 9999 "nesc-generate.c"
  #line 300
  if (!strcmp(varname, "BLocks$locks"))
  {
    *addr = (uint32_t)&BLocks$locks[__nesc_mote];
    *size = sizeof(BLocks$locks[__nesc_mote]);
    return 0;
  }

  /* Module BQueue */

  /* Module BInstruction */

  /* Module BStacks */

  /* Module PotM */

  /* Module HPLPotC */

  /* Module OPaddM */

  /* Module BBuffer */

  /* Module OPsubM */

  /* Module OPhaltM */

  /* Module OPlandM */

  /* Module OPlorM */

  /* Module OPorM */

  /* Module OPandM */

  /* Module OPnotM */

  /* Module OPlnotM */

  /* Module OPdivM */

  /* Module OPbtailM */

  /* Module OPeqvM */

  /* Module OPexpM */

  /* Module OPimpM */

  /* Module OPlxorM */

  /* Module OPmodM */

  /* Module OPmulM */

  /* Module OPbreadM */

  /* Module OPbwriteM */

  /* Module OPpopM */

  /* Module OPeqM */

  /* Module OPgteM */

  /* Module OPgtM */

  /* Module OPltM */

  /* Module OPlteM */

  /* Module OPneqM */

  /* Module OPcopyM */

  /* Module OPinvM */

  /* Module OPputledM */

  /* Module OPbclearM */

  /* Module OPcastM */

  /* Module OPidM */

  /* Module OPuartM */
  # 9999 "nesc-generate.c"
  #line 310
  if (!strcmp(varname, "OPuartM$sendWaitQueue"))
  {
    *addr = (uint32_t)&OPuartM$sendWaitQueue[__nesc_mote];
    *size = sizeof(OPuartM$sendWaitQueue[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 320
  if (!strcmp(varname, "OPuartM$sendingContext"))
  {
    *addr = (uint32_t)&OPuartM$sendingContext[__nesc_mote];
    *size = sizeof(OPuartM$sendingContext[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 330
  if (!strcmp(varname, "OPuartM$msg"))
  {
    *addr = (uint32_t)&OPuartM$msg[__nesc_mote];
    *size = sizeof(OPuartM$msg[__nesc_mote]);
    return 0;
  }

  /* Module BVirusExtended */
  # 9999 "nesc-generate.c"
  #line 340
  if (!strcmp(varname, "BVirusExtended$capsules"))
  {
    *addr = (uint32_t)&BVirusExtended$capsules[__nesc_mote];
    *size = sizeof(BVirusExtended$capsules[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 350
  if (!strcmp(varname, "BVirusExtended$capsuleTimerThresholds"))
  {
    *addr = (uint32_t)&BVirusExtended$capsuleTimerThresholds[__nesc_mote];
    *size = sizeof(BVirusExtended$capsuleTimerThresholds[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 360
  if (!strcmp(varname, "BVirusExtended$capsuleTimerCounters"))
  {
    *addr = (uint32_t)&BVirusExtended$capsuleTimerCounters[__nesc_mote];
    *size = sizeof(BVirusExtended$capsuleTimerCounters[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 370
  if (!strcmp(varname, "BVirusExtended$bCastIdx"))
  {
    *addr = (uint32_t)&BVirusExtended$bCastIdx[__nesc_mote];
    *size = sizeof(BVirusExtended$bCastIdx[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 380
  if (!strcmp(varname, "BVirusExtended$versionCounter"))
  {
    *addr = (uint32_t)&BVirusExtended$versionCounter[__nesc_mote];
    *size = sizeof(BVirusExtended$versionCounter[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 390
  if (!strcmp(varname, "BVirusExtended$versionThreshold"))
  {
    *addr = (uint32_t)&BVirusExtended$versionThreshold[__nesc_mote];
    *size = sizeof(BVirusExtended$versionThreshold[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 400
  if (!strcmp(varname, "BVirusExtended$versionCancelled"))
  {
    *addr = (uint32_t)&BVirusExtended$versionCancelled[__nesc_mote];
    *size = sizeof(BVirusExtended$versionCancelled[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 410
  if (!strcmp(varname, "BVirusExtended$tau"))
  {
    *addr = (uint32_t)&BVirusExtended$tau[__nesc_mote];
    *size = sizeof(BVirusExtended$tau[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 420
  if (!strcmp(varname, "BVirusExtended$versionHeard"))
  {
    *addr = (uint32_t)&BVirusExtended$versionHeard[__nesc_mote];
    *size = sizeof(BVirusExtended$versionHeard[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 430
  if (!strcmp(varname, "BVirusExtended$state"))
  {
    *addr = (uint32_t)&BVirusExtended$state[__nesc_mote];
    *size = sizeof(BVirusExtended$state[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 440
  if (!strcmp(varname, "BVirusExtended$sendBusy"))
  {
    *addr = (uint32_t)&BVirusExtended$sendBusy[__nesc_mote];
    *size = sizeof(BVirusExtended$sendBusy[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 450
  if (!strcmp(varname, "BVirusExtended$capsuleBusy"))
  {
    *addr = (uint32_t)&BVirusExtended$capsuleBusy[__nesc_mote];
    *size = sizeof(BVirusExtended$capsuleBusy[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 460
  if (!strcmp(varname, "BVirusExtended$amBCasting"))
  {
    *addr = (uint32_t)&BVirusExtended$amBCasting[__nesc_mote];
    *size = sizeof(BVirusExtended$amBCasting[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 470
  if (!strcmp(varname, "BVirusExtended$sendMessage"))
  {
    *addr = (uint32_t)&BVirusExtended$sendMessage[__nesc_mote];
    *size = sizeof(BVirusExtended$sendMessage[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 480
  if (!strcmp(varname, "BVirusExtended$sendPtr"))
  {
    *addr = (uint32_t)&BVirusExtended$sendPtr[__nesc_mote];
    *size = sizeof(BVirusExtended$sendPtr[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 490
  if (!strcmp(varname, "BVirusExtended$receiveMsg"))
  {
    *addr = (uint32_t)&BVirusExtended$receiveMsg[__nesc_mote];
    *size = sizeof(BVirusExtended$receiveMsg[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 500
  if (!strcmp(varname, "BVirusExtended$receivePtr"))
  {
    *addr = (uint32_t)&BVirusExtended$receivePtr[__nesc_mote];
    *size = sizeof(BVirusExtended$receivePtr[__nesc_mote]);
    return 0;
  }

  /* Module QueuedSendM */
  # 9999 "nesc-generate.c"
  #line 510
  if (!strcmp(varname, "QueuedSendM$msgqueue"))
  {
    *addr = (uint32_t)&QueuedSendM$msgqueue[__nesc_mote];
    *size = sizeof(QueuedSendM$msgqueue[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 520
  if (!strcmp(varname, "QueuedSendM$enqueue_next"))
  {
    *addr = (uint32_t)&QueuedSendM$enqueue_next[__nesc_mote];
    *size = sizeof(QueuedSendM$enqueue_next[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 530
  if (!strcmp(varname, "QueuedSendM$dequeue_next"))
  {
    *addr = (uint32_t)&QueuedSendM$dequeue_next[__nesc_mote];
    *size = sizeof(QueuedSendM$dequeue_next[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 540
  if (!strcmp(varname, "QueuedSendM$retransmit"))
  {
    *addr = (uint32_t)&QueuedSendM$retransmit[__nesc_mote];
    *size = sizeof(QueuedSendM$retransmit[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 550
  if (!strcmp(varname, "QueuedSendM$fQueueIdle"))
  {
    *addr = (uint32_t)&QueuedSendM$fQueueIdle[__nesc_mote];
    *size = sizeof(QueuedSendM$fQueueIdle[__nesc_mote]);
    return 0;
  }

  /* Module RandomLFSR */
  # 9999 "nesc-generate.c"
  #line 560
  if (!strcmp(varname, "RandomLFSR$shiftReg"))
  {
    *addr = (uint32_t)&RandomLFSR$shiftReg[__nesc_mote];
    *size = sizeof(RandomLFSR$shiftReg[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 570
  if (!strcmp(varname, "RandomLFSR$initSeed"))
  {
    *addr = (uint32_t)&RandomLFSR$initSeed[__nesc_mote];
    *size = sizeof(RandomLFSR$initSeed[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 580
  if (!strcmp(varname, "RandomLFSR$mask"))
  {
    *addr = (uint32_t)&RandomLFSR$mask[__nesc_mote];
    *size = sizeof(RandomLFSR$mask[__nesc_mote]);
    return 0;
  }

  /* Module MultiHopEngineGridM */
  # 9999 "nesc-generate.c"
  #line 590
  if (!strcmp(varname, "MultiHopEngineGridM$FwdBufList"))
  {
    *addr = (uint32_t)&MultiHopEngineGridM$FwdBufList[__nesc_mote];
    *size = sizeof(MultiHopEngineGridM$FwdBufList[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 600
  if (!strcmp(varname, "MultiHopEngineGridM$iFwdBufHead"))
  {
    *addr = (uint32_t)&MultiHopEngineGridM$iFwdBufHead[__nesc_mote];
    *size = sizeof(MultiHopEngineGridM$iFwdBufHead[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 610
  if (!strcmp(varname, "MultiHopEngineGridM$iFwdBufTail"))
  {
    *addr = (uint32_t)&MultiHopEngineGridM$iFwdBufTail[__nesc_mote];
    *size = sizeof(MultiHopEngineGridM$iFwdBufTail[__nesc_mote]);
    return 0;
  }

  /* Module MultiHopGrid */
  # 9999 "nesc-generate.c"
  #line 620
  if (!strcmp(varname, "MultiHopGrid$routeMsg"))
  {
    *addr = (uint32_t)&MultiHopGrid$routeMsg[__nesc_mote];
    *size = sizeof(MultiHopGrid$routeMsg[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 630
  if (!strcmp(varname, "MultiHopGrid$gfSendRouteBusy"))
  {
    *addr = (uint32_t)&MultiHopGrid$gfSendRouteBusy[__nesc_mote];
    *size = sizeof(MultiHopGrid$gfSendRouteBusy[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 640
  if (!strcmp(varname, "MultiHopGrid$NeighborTbl"))
  {
    *addr = (uint32_t)&MultiHopGrid$NeighborTbl[__nesc_mote];
    *size = sizeof(MultiHopGrid$NeighborTbl[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 650
  if (!strcmp(varname, "MultiHopGrid$gpCurrentParent"))
  {
    *addr = (uint32_t)&MultiHopGrid$gpCurrentParent[__nesc_mote];
    *size = sizeof(MultiHopGrid$gpCurrentParent[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 660
  if (!strcmp(varname, "MultiHopGrid$gbCurrentHopCount"))
  {
    *addr = (uint32_t)&MultiHopGrid$gbCurrentHopCount[__nesc_mote];
    *size = sizeof(MultiHopGrid$gbCurrentHopCount[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 670
  if (!strcmp(varname, "MultiHopGrid$gbCurrentCost"))
  {
    *addr = (uint32_t)&MultiHopGrid$gbCurrentCost[__nesc_mote];
    *size = sizeof(MultiHopGrid$gbCurrentCost[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 680
  if (!strcmp(varname, "MultiHopGrid$gCurrentSeqNo"))
  {
    *addr = (uint32_t)&MultiHopGrid$gCurrentSeqNo[__nesc_mote];
    *size = sizeof(MultiHopGrid$gCurrentSeqNo[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 690
  if (!strcmp(varname, "MultiHopGrid$gwEstTicks"))
  {
    *addr = (uint32_t)&MultiHopGrid$gwEstTicks[__nesc_mote];
    *size = sizeof(MultiHopGrid$gwEstTicks[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 700
  if (!strcmp(varname, "MultiHopGrid$last_entry_sent"))
  {
    *addr = (uint32_t)&MultiHopGrid$last_entry_sent[__nesc_mote];
    *size = sizeof(MultiHopGrid$last_entry_sent[__nesc_mote]);
    return 0;
  }

  /* Module OPrandM */

  /* Module OProuteM */
  # 9999 "nesc-generate.c"
  #line 710
  if (!strcmp(varname, "OProuteM$onceCapsule"))
  {
    *addr = (uint32_t)&OProuteM$onceCapsule[__nesc_mote];
    *size = sizeof(OProuteM$onceCapsule[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 720
  if (!strcmp(varname, "OProuteM$sendingContext"))
  {
    *addr = (uint32_t)&OProuteM$sendingContext[__nesc_mote];
    *size = sizeof(OProuteM$sendingContext[__nesc_mote]);
    return 0;
  }
  # 9999 "nesc-generate.c"
  #line 730
  if (!strcmp(varname, "OProuteM$msg"))
  {
    *addr = (uint32_t)&OProuteM$msg[__nesc_mote];
    *size = sizeof(OProuteM$msg[__nesc_mote]);
    return 0;
  }

  /* Module OnceContextM */
  # 9999 "nesc-generate.c"
  #line 740
  if (!strcmp(varname, "OnceContextM$onceContext"))
  {
    *addr = (uint32_t)&OnceContextM$onceContext[__nesc_mote];
    *size = sizeof(OnceContextM$onceContext[__nesc_mote]);
    return 0;
  }

  /* Module OPbpush1M */
  # 9999 "nesc-generate.c"
  #line 750
  if (!strcmp(varname, "OPbpush1M$buffers"))
  {
    *addr = (uint32_t)&OPbpush1M$buffers[__nesc_mote];
    *size = sizeof(OPbpush1M$buffers[__nesc_mote]);
    return 0;
  }

  /* Module OPsettimer1M */

  /* Module Timer1ContextM */
  # 9999 "nesc-generate.c"
  #line 760
  if (!strcmp(varname, "Timer1ContextM$clockContext"))
  {
    *addr = (uint32_t)&Timer1ContextM$clockContext[__nesc_mote];
    *size = sizeof(Timer1ContextM$clockContext[__nesc_mote]);
    return 0;
  }

  /* Module OP2pushc10M */

  /* Module OP2jumps10M */

  /* Module OPgetsetlocal3M */
  # 9999 "nesc-generate.c"
  #line 770
  if (!strcmp(varname, "OPgetsetlocal3M$vars"))
  {
    *addr = (uint32_t)&OPgetsetlocal3M$vars[__nesc_mote];
    *size = sizeof(OPgetsetlocal3M$vars[__nesc_mote]);
    return 0;
  }

  /* Module OPgetsetvar4M */
  # 9999 "nesc-generate.c"
  #line 780
  if (!strcmp(varname, "OPgetsetvar4M$heap"))
  {
    *addr = (uint32_t)&OPgetsetvar4M$heap[__nesc_mote];
    *size = sizeof(OPgetsetvar4M$heap[__nesc_mote]);
    return 0;
  }

  /* Module OPpushc6M */

  return -1;
}
/* Invoke static initialisers for mote '__nesc_mote' */

static void __nesc_nido_initialise(int __nesc_mote)
{
  /* Module BombillaEngineM */
  memset(&BombillaEngineM$runQueue[__nesc_mote], 0, sizeof BombillaEngineM$runQueue[__nesc_mote]);
  memset(&BombillaEngineM$capsules[__nesc_mote], 0, sizeof BombillaEngineM$capsules[__nesc_mote]);
  memset(&BombillaEngineM$errorContext[__nesc_mote], 0, sizeof BombillaEngineM$errorContext[__nesc_mote]);
  memset(&BombillaEngineM$errorMsg[__nesc_mote], 0, sizeof BombillaEngineM$errorMsg[__nesc_mote]);
  memset(&BombillaEngineM$inErrorState[__nesc_mote], 0, sizeof BombillaEngineM$inErrorState[__nesc_mote]);
  memset(&BombillaEngineM$errorFlipFlop[__nesc_mote], 0, sizeof BombillaEngineM$errorFlipFlop[__nesc_mote]);
  memset(&BombillaEngineM$msg[__nesc_mote], 0, sizeof BombillaEngineM$msg[__nesc_mote]);

  /* Module LedsC */
  memset(&LedsC$ledsOn[__nesc_mote], 0, sizeof LedsC$ledsOn[__nesc_mote]);

  /* Module TimerM */
  memset(&TimerM$mState[__nesc_mote], 0, sizeof TimerM$mState[__nesc_mote]);
  memset(&TimerM$setIntervalFlag[__nesc_mote], 0, sizeof TimerM$setIntervalFlag[__nesc_mote]);
  memset(&TimerM$mScale[__nesc_mote], 0, sizeof TimerM$mScale[__nesc_mote]);
  memset(&TimerM$mInterval[__nesc_mote], 0, sizeof TimerM$mInterval[__nesc_mote]);
  memset(&TimerM$queue_head[__nesc_mote], 0, sizeof TimerM$queue_head[__nesc_mote]);
  memset(&TimerM$queue_tail[__nesc_mote], 0, sizeof TimerM$queue_tail[__nesc_mote]);
  memset(&TimerM$queue_size[__nesc_mote], 0, sizeof TimerM$queue_size[__nesc_mote]);
  memset(&TimerM$queue[__nesc_mote], 0, sizeof TimerM$queue[__nesc_mote]);
  memset(&TimerM$mTimerList[__nesc_mote], 0, sizeof TimerM$mTimerList[__nesc_mote]);

  /* Module HPLClock */
  memset(&HPLClock$set_flag[__nesc_mote], 0, sizeof HPLClock$set_flag[__nesc_mote]);
  memset(&HPLClock$mscale[__nesc_mote], 0, sizeof HPLClock$mscale[__nesc_mote]);
  memset(&HPLClock$nextScale[__nesc_mote], 0, sizeof HPLClock$nextScale[__nesc_mote]);
  memset(&HPLClock$minterval[__nesc_mote], 0, sizeof HPLClock$minterval[__nesc_mote]);

  /* Module NoLeds */

  /* Module HPLPowerManagementM */

  /* Module AMPromiscuous */
  memset(&AMPromiscuous$state[__nesc_mote], 0, sizeof AMPromiscuous$state[__nesc_mote]);
  memset(&AMPromiscuous$buffer[__nesc_mote], 0, sizeof AMPromiscuous$buffer[__nesc_mote]);
  memset(&AMPromiscuous$lastCount[__nesc_mote], 0, sizeof AMPromiscuous$lastCount[__nesc_mote]);
  memset(&AMPromiscuous$counter[__nesc_mote], 0, sizeof AMPromiscuous$counter[__nesc_mote]);
  memset(&AMPromiscuous$promiscuous_mode[__nesc_mote], 0, sizeof AMPromiscuous$promiscuous_mode[__nesc_mote]);
  memset(&AMPromiscuous$crc_check[__nesc_mote], 0, sizeof AMPromiscuous$crc_check[__nesc_mote]);

  /* Module TossimPacketM */
  memset(&TossimPacketM$buffer[__nesc_mote], 0, sizeof TossimPacketM$buffer[__nesc_mote]);
  memset(&TossimPacketM$bufferPtr[__nesc_mote], 0, sizeof TossimPacketM$bufferPtr[__nesc_mote]);

  /* Module Nido */

  /* Module UARTNoCRCPacketM */

  /* Module NoCRCPacket */

  /* Module AMFilter */

  /* Module BContextSynch */
  memset(&BContextSynch$readyQueue[__nesc_mote], 0, sizeof BContextSynch$readyQueue[__nesc_mote]);

  /* Module BLocks */
  memset(&BLocks$locks[__nesc_mote], 0, sizeof BLocks$locks[__nesc_mote]);

  /* Module BQueue */

  /* Module BInstruction */

  /* Module BStacks */

  /* Module PotM */

  /* Module HPLPotC */

  /* Module OPaddM */

  /* Module BBuffer */

  /* Module OPsubM */

  /* Module OPhaltM */

  /* Module OPlandM */

  /* Module OPlorM */

  /* Module OPorM */

  /* Module OPandM */

  /* Module OPnotM */

  /* Module OPlnotM */

  /* Module OPdivM */

  /* Module OPbtailM */

  /* Module OPeqvM */

  /* Module OPexpM */

  /* Module OPimpM */

  /* Module OPlxorM */

  /* Module OPmodM */

  /* Module OPmulM */

  /* Module OPbreadM */

  /* Module OPbwriteM */

  /* Module OPpopM */

  /* Module OPeqM */

  /* Module OPgteM */

  /* Module OPgtM */

  /* Module OPltM */

  /* Module OPlteM */

  /* Module OPneqM */

  /* Module OPcopyM */

  /* Module OPinvM */

  /* Module OPputledM */

  /* Module OPbclearM */

  /* Module OPcastM */

  /* Module OPidM */

  /* Module OPuartM */
  memset(&OPuartM$sendWaitQueue[__nesc_mote], 0, sizeof OPuartM$sendWaitQueue[__nesc_mote]);
  OPuartM$sendingContext[__nesc_mote] = (void *)0;
  memset(&OPuartM$msg[__nesc_mote], 0, sizeof OPuartM$msg[__nesc_mote]);

  /* Module BVirusExtended */
  memset(&BVirusExtended$capsules[__nesc_mote], 0, sizeof BVirusExtended$capsules[__nesc_mote]);
  memset(&BVirusExtended$capsuleTimerThresholds[__nesc_mote], 0, sizeof BVirusExtended$capsuleTimerThresholds[__nesc_mote]);
  memset(&BVirusExtended$capsuleTimerCounters[__nesc_mote], 0, sizeof BVirusExtended$capsuleTimerCounters[__nesc_mote]);
  memset(&BVirusExtended$bCastIdx[__nesc_mote], 0, sizeof BVirusExtended$bCastIdx[__nesc_mote]);
  memset(&BVirusExtended$versionCounter[__nesc_mote], 0, sizeof BVirusExtended$versionCounter[__nesc_mote]);
  memset(&BVirusExtended$versionThreshold[__nesc_mote], 0, sizeof BVirusExtended$versionThreshold[__nesc_mote]);
  memset(&BVirusExtended$versionCancelled[__nesc_mote], 0, sizeof BVirusExtended$versionCancelled[__nesc_mote]);
  memset(&BVirusExtended$tau[__nesc_mote], 0, sizeof BVirusExtended$tau[__nesc_mote]);
  memset(&BVirusExtended$versionHeard[__nesc_mote], 0, sizeof BVirusExtended$versionHeard[__nesc_mote]);
  memset(&BVirusExtended$state[__nesc_mote], 0, sizeof BVirusExtended$state[__nesc_mote]);
  memset(&BVirusExtended$sendBusy[__nesc_mote], 0, sizeof BVirusExtended$sendBusy[__nesc_mote]);
  memset(&BVirusExtended$capsuleBusy[__nesc_mote], 0, sizeof BVirusExtended$capsuleBusy[__nesc_mote]);
  memset(&BVirusExtended$amBCasting[__nesc_mote], 0, sizeof BVirusExtended$amBCasting[__nesc_mote]);
  memset(&BVirusExtended$sendMessage[__nesc_mote], 0, sizeof BVirusExtended$sendMessage[__nesc_mote]);
  memset(&BVirusExtended$sendPtr[__nesc_mote], 0, sizeof BVirusExtended$sendPtr[__nesc_mote]);
  memset(&BVirusExtended$receiveMsg[__nesc_mote], 0, sizeof BVirusExtended$receiveMsg[__nesc_mote]);
  memset(&BVirusExtended$receivePtr[__nesc_mote], 0, sizeof BVirusExtended$receivePtr[__nesc_mote]);

  /* Module QueuedSendM */
  memset(&QueuedSendM$msgqueue[__nesc_mote], 0, sizeof QueuedSendM$msgqueue[__nesc_mote]);
  memset(&QueuedSendM$enqueue_next[__nesc_mote], 0, sizeof QueuedSendM$enqueue_next[__nesc_mote]);
  memset(&QueuedSendM$dequeue_next[__nesc_mote], 0, sizeof QueuedSendM$dequeue_next[__nesc_mote]);
  memset(&QueuedSendM$retransmit[__nesc_mote], 0, sizeof QueuedSendM$retransmit[__nesc_mote]);
  memset(&QueuedSendM$fQueueIdle[__nesc_mote], 0, sizeof QueuedSendM$fQueueIdle[__nesc_mote]);

  /* Module RandomLFSR */
  memset(&RandomLFSR$shiftReg[__nesc_mote], 0, sizeof RandomLFSR$shiftReg[__nesc_mote]);
  memset(&RandomLFSR$initSeed[__nesc_mote], 0, sizeof RandomLFSR$initSeed[__nesc_mote]);
  memset(&RandomLFSR$mask[__nesc_mote], 0, sizeof RandomLFSR$mask[__nesc_mote]);

  /* Module MultiHopEngineGridM */
  memset(&MultiHopEngineGridM$FwdBufList[__nesc_mote], 0, sizeof MultiHopEngineGridM$FwdBufList[__nesc_mote]);
  memset(&MultiHopEngineGridM$iFwdBufHead[__nesc_mote], 0, sizeof MultiHopEngineGridM$iFwdBufHead[__nesc_mote]);
  memset(&MultiHopEngineGridM$iFwdBufTail[__nesc_mote], 0, sizeof MultiHopEngineGridM$iFwdBufTail[__nesc_mote]);

  /* Module MultiHopGrid */
  memset(&MultiHopGrid$routeMsg[__nesc_mote], 0, sizeof MultiHopGrid$routeMsg[__nesc_mote]);
  memset(&MultiHopGrid$gfSendRouteBusy[__nesc_mote], 0, sizeof MultiHopGrid$gfSendRouteBusy[__nesc_mote]);
  memset(&MultiHopGrid$NeighborTbl[__nesc_mote], 0, sizeof MultiHopGrid$NeighborTbl[__nesc_mote]);
  memset(&MultiHopGrid$gpCurrentParent[__nesc_mote], 0, sizeof MultiHopGrid$gpCurrentParent[__nesc_mote]);
  memset(&MultiHopGrid$gbCurrentHopCount[__nesc_mote], 0, sizeof MultiHopGrid$gbCurrentHopCount[__nesc_mote]);
  memset(&MultiHopGrid$gbCurrentCost[__nesc_mote], 0, sizeof MultiHopGrid$gbCurrentCost[__nesc_mote]);
  memset(&MultiHopGrid$gCurrentSeqNo[__nesc_mote], 0, sizeof MultiHopGrid$gCurrentSeqNo[__nesc_mote]);
  memset(&MultiHopGrid$gwEstTicks[__nesc_mote], 0, sizeof MultiHopGrid$gwEstTicks[__nesc_mote]);
  memset(&MultiHopGrid$last_entry_sent[__nesc_mote], 0, sizeof MultiHopGrid$last_entry_sent[__nesc_mote]);

  /* Module OPrandM */

  /* Module OProuteM */
  memset(&OProuteM$onceCapsule[__nesc_mote], 0, sizeof OProuteM$onceCapsule[__nesc_mote]);
  memset(&OProuteM$sendingContext[__nesc_mote], 0, sizeof OProuteM$sendingContext[__nesc_mote]);
  memset(&OProuteM$msg[__nesc_mote], 0, sizeof OProuteM$msg[__nesc_mote]);

  /* Module OnceContextM */
  memset(&OnceContextM$onceContext[__nesc_mote], 0, sizeof OnceContextM$onceContext[__nesc_mote]);

  /* Module OPbpush1M */
  memset(&OPbpush1M$buffers[__nesc_mote], 0, sizeof OPbpush1M$buffers[__nesc_mote]);

  /* Module OPsettimer1M */

  /* Module Timer1ContextM */
  memset(&Timer1ContextM$clockContext[__nesc_mote], 0, sizeof Timer1ContextM$clockContext[__nesc_mote]);

  /* Module OP2pushc10M */

  /* Module OP2jumps10M */

  /* Module OPgetsetlocal3M */
  memset(&OPgetsetlocal3M$vars[__nesc_mote], 0, sizeof OPgetsetlocal3M$vars[__nesc_mote]);

  /* Module OPgetsetvar4M */
  memset(&OPgetsetvar4M$heap[__nesc_mote], 0, sizeof OPgetsetvar4M$heap[__nesc_mote]);

  /* Module OPpushc6M */

}
