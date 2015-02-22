#include "console.h"
#include "stm32f4xx_hal.h"
/* #include "stm32f4xx_hal_gpio.h" */
#include "usart.h"
#include "ringbuffer.h"
#include "globals.h"

#include <stdint.h>
#include <stdbool.h>
 
/* defined in globals, actual allocation here */
ringbuffer rx_buffer, tx_buffer;

static UART_HandleTypeDef * huart = &huart2;

#include <stdint.h>

/* if RTS is on (asserted low), data may be sent */
static void set_RTS(bool on) {
  HAL_GPIO_WritePin(GPIOA,GPIO_PIN_1,(on ? GPIO_PIN_RESET : GPIO_PIN_SET));
}


void console_init() {
  ringbuffer_init(&rx_buffer);
  ringbuffer_init(&tx_buffer);
  /* enable receiver */
  __HAL_UART_ENABLE_IT(huart, UART_IT_RXNE);
  set_RTS(true);
}

int console_putc(uint8_t c) {
  int ret = ringbuffer_put(&tx_buffer,c);
  if (ret == -1)
    return -1;
  /* enable transmitter */
  __HAL_UART_ENABLE_IT(huart, UART_IT_TXE);
  return c;
}

/* Returns 0 if char in buffer, -1 otherwise.  Handles setting RTS
   when buffer runs full.*/
int console_getc(uint8_t *c) {
  uint8_t byte;
  int ret = ringbuffer_get(&rx_buffer,&byte);
  if (ret == -1)
    return -1;
  if (ret == 0)
    set_RTS(true);
  *c=byte;
  return 0;
}

void USART2_IRQHandler(){
  int ret;
  uint8_t byte;
  /* TX */
  if (__HAL_UART_GET_FLAG(huart,UART_FLAG_TXE)){
    ret = ringbuffer_get(&tx_buffer,&byte);
    if (ret == -1) {
      /* empty, disable TX empty interrupt */
      /* TODO: check if activating interrupt while flag still on
	 reactivates transmission correctly */
      __HAL_UART_DISABLE_IT(huart,UART_IT_TXE);
    } else {
      /* writing data clears TXE flag */
      huart->Instance->DR = (uint16_t)byte;
    }
  }
  /* RX */
  if (__HAL_UART_GET_FLAG(huart,UART_FLAG_RXNE)) {
    byte=huart->Instance->DR;	/* clears RXNE */
    ret=ringbuffer_put(&rx_buffer,byte);
    if (ret == 1)		/* almost full, disable RTS */
      set_RTS(false);
  }
}
