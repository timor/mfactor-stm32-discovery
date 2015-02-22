#include "ringbuffer.h"
#include <stdio.h>

void test_ringbuffer() {
  ringbuffer buf1;
  ringbuffer_init(&buf1);
  int ret;
  char c;
  /* expect empty */
  if (ringbuffer_free(&buf1) != (RINGBUFFER_SIZE -1))
    asm("BKPT 01");
  /* fill up to full */
  for (int i = 0; i < (RINGBUFFER_SIZE - 1); i++) {
    if (ringbuffer_put(&buf1,0xa5) == -1)
      asm("BKPT 01");
  }
  /* expect full */
  if (ringbuffer_free(&buf1) != 0)
    asm("BKPT 02");
  if (ringbuffer_put(&buf1,0xa5) != -1)
    asm("BKPT 02");
  if (ringbuffer_put(&buf1,0xa5) != -1)
    asm("BKPT 02");
  for( int i = 0; i < (RINGBUFFER_SIZE - 1); i++) {
    if (ringbuffer_get(&buf1,&c) == -1)
      asm("BKPT 03");
  }
  /* expect empty */
  if (ringbuffer_free(&buf1) != (RINGBUFFER_SIZE -1))
    asm("BKPT 01");
}

void run_tests () {
  test_ringbuffer();
}
