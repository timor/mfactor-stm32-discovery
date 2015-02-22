#ifndef CONSOLE_H
#define CONSOLE_H

#include <stdint.h>
void console_init();
int console_putc(uint8_t);
int console_getc(uint8_t *);

#endif
