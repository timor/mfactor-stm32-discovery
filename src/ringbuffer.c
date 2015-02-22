#include "ringbuffer.h"

#include <stdint.h>
#include <string.h>

/* #define RINGBUFFER_MASK (RINGBUFFER_SIZE-1) */
static const uint32_t BufferMask = (RINGBUFFER_SIZE-1);

int ringbuffer_init(ringbuffer * buf) {
  if (buf == NULL) return -1;
  buf->read=0;
  buf->write=0;
  buf->almost_full_threshold=4;
  return 0;
}

uint32_t ringbuffer_free(ringbuffer *buffer) {
  uint32_t free = (buffer->read - buffer->write - 1) & BufferMask;
  return free;
}

int ringbuffer_put(ringbuffer *buffer, uint8_t c) {
  uint8_t next = ((buffer->write + 1) & BufferMask);
  if (buffer->read == next)
    return -1 ;
  buffer->data[buffer->write]=c;
  buffer->write = next;
  if (ringbuffer_free(buffer) < buffer->almost_full_threshold)
    return 1;
  return 0;
}

int ringbuffer_get(ringbuffer *buffer, uint8_t *c) {
  uint32_t cur_read = buffer->read;
  uint32_t cur_write = buffer->write;
  if (cur_read == cur_write)
    return -1;
  *c = buffer->data[cur_read];
  buffer->read = (cur_read+1) & BufferMask;
  if (ringbuffer_free(buffer) < buffer->almost_full_threshold)
    return 1;
  return 0;
}



