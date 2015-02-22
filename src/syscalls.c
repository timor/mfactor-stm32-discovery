#include "console.h"
#include <sys/stat.h>
#include <stdbool.h>
 
int _close(int file) {
  return 0;
}
 
int _fstat(int file, struct stat *st) {
  st->st_mode = S_IFCHR;
  return 0;
}
 
int _isatty(int file) {
  return 1;
}
 
int _lseek(int file, int ptr, int dir) {
  return 0;
}
 
int _open(const char *name, int flags, int mode) {
return -1;
}

int _write(int,char *, int);

/* blocks until at least 1 char is read, but may return upto len chars*/
int _read(int file, char *ptr, int len) {
  int num_read=0;
  char *orig=ptr;
  bool more = true;
  char c;
  if(len == 0)
    return 0;
  /* loop while still nothing (block) or still something */
  while (more) {
    if (console_getc(&c) == 0) {
      *ptr++=c;
      num_read += 1;
    } else {
      if (num_read >= 1)		/* only settle for this if we have at least one! */
	more = false;
    }
    /* bail out if still data even though less was requested */
    if (num_read >= len) break;
  }
  /* TODO: having the echo here in main context code (usually) only
     echoes characters if they are actually read.  This kind of
     indicates if the console is active.  If direct echo is needed,
     echo needs to be put into the interrupt handler.*/
  /* serial echo */
  /* _write(0,orig,num_read); */
  return num_read;
}
 
register char * stack_ptr asm ("sp");

caddr_t _sbrk(int incr) {
  static char *heap_end = 0;
  extern char end asm ("end");   /* Defined by the linker */
  char *prev_heap_end;
  if (heap_end == 0) {
    heap_end = & end;
  }
  prev_heap_end = heap_end;
  if (heap_end + incr > stack_ptr) {
    /* Heap and stack collision */
    return (caddr_t)-1;
  }
  heap_end += incr;
  return (caddr_t) prev_heap_end;
}
 
/* block till everything has been sent */
int _write(int file, char *ptr, int len) {
  int written = 0;
  int ret;
  if (len == 0 ) return 0;
  while (written < len) {
    ret = console_putc(*ptr);
    if ( ret != -1) {
      written += 1;
      ptr += 1;
    }
  }
  return written;
}
