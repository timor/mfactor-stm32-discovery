#ifndef RINGBUFFER_H
#define RINGBUFFER_H

#include <stdint.h>

#ifndef RINGBUFFER_SIZE
#define RINGBUFFER_SIZE 32
#endif

typedef volatile struct ringbuffer {
  uint8_t data[RINGBUFFER_SIZE];
  uint32_t read;
  uint32_t write;
  uint32_t almost_full_threshold;
} ringbuffer;


int ringbuffer_init(ringbuffer *);

/* returns 0 if ok, -1 if full, 1 if over threshold */
int ringbuffer_put(ringbuffer *buffer, uint8_t c);
/* returns 0 if ok, -1 if empty, 1 if over threshold */
int ringbuffer_get(ringbuffer *buffer, uint8_t *c);
/* return number of free bytes */
uint32_t ringbuffer_free(ringbuffer *);

#endif
