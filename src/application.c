#include <stdint.h>
#include <stdio.h>
#include <errno.h>
#include "interpreter.h"
#include "tests.h"

/* testing */
#include "console.h"

void reset_system(){
  /* tbd */
}

void HAL_SYSTICK_Callback(void){
}

void HardFault_Handler(){ asm("bkpt 43"); }
volatile int dummy = 0;
void application(void) {
  char c;
  run_tests();
  printf("libc running\n");
  while(1)
    interpreter(0);
}
