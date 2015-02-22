set print pretty on

define connect
  tar ext :4242
end

define soft-reset
  set $pc=*4
  set $sp=*0
end

define regs
  p/x $pc
  p/x $sp
  p/x $lr
  p/x $r0
  p/x $r1
  p/x $r2
  p/x $r3
  p/x $r4
  p/x $r5
  p/x $r6
  p/x $r7
end

# note that these depend on cubemx code being loaded
define load-specials
  set $SCB = (SCB_Type *) 0xe000ed00
  set $NVIC = (NVIC_Type *) 0xe000e100
  set $SysTick = (SysTick_Type *) 0xe000e010
  # set $SCnSCB = (SCnSCB_Type *) 0xe000e000
  set $GPIOA = (GPIO_TypeDef *) 0x40020000
  set $GPIOB = (GPIO_TypeDef *) 0x40020400
  set $GPIOC = (GPIO_TypeDef *) 0x40020800
  set $GPIOD = (GPIO_TypeDef *) 0x40020c00
  set $GPIOE = (GPIO_TypeDef *) 0x40021000
  set $GPIOH = (GPIO_TypeDef *) 0x40021c00
  set $USART2 = (USART_TypeDef *) 0x40004400
end

# pass false to disable
define write-buffering
  if $arg0
    set *0xe000e008 &= ~0x02
  else
    set *0xe000e008 |= 0x02
  end
end

define reload
  file build/image.elf
  load
  load-specials
end



define irqs
  x/32x 0xe000e100
  x/32x 0xe000e200
end

define psr
  p/t $xpsr
end

# display instructions around current pc, systick value and psr
define stats
  disp /t $xpsr
  disp /x *0xE000E018
  disp /3i $pc
end

# expects contents of CFSR
define bus-fault-info
  printf "CFSR: 0x%x\n", $arg0
  if $arg0 & 0x100
    echo Instruction Bus Error\n
  end
  if $arg0 & 0x200
    echo Precise Bus Error\n
  end
  if $arg0 & 0x400
    echo Imprecise Bus Error\n
  end
  if $arg0 & 0x800
    echo Unstacking Error\n
  end
  if $arg0 & 0x1000
    echo Stacking Error\n
  end
  if $arg0 & 0x8000
    printf "BFAR valid: 0x%x\n", $SCB->BFAR
  else
    echo BFAR invalid\n
  end
end

define hard-fault-info
  if $SCB->HFSR & 0x40000000
    echo Forced Hard Fault\n
    if $SCB->CFSR & 0x000000ff
      echo MemManage Fault\n
    end
    if $SCB->CFSR & 0x0000ff00
      echo Bus Fault\n
      bus-fault-info $SCB->CFSR
    end
    if $SCB->CFSR & 0xffff0000
      echo Usage Fault\n
    end
  else
    if $SCB->HFSR & 0x00000002
      echo Bus Fault on vector table read\n
    end
  end
end

define fault-info
  if $xpsr & 0x3 == 3
    echo Hard Fault Active\n
    hard-fault-info
    # print offending code
    if $lr & 0x04
      echo return frame in PSP\n
      x/9wx $psp
    else
      echo return frame in MSP\n
      x/9wx $msp
    end
  else
    echo No Hard Fault Active\n
  end
end

# for use with BET toolchain
set substitute-path /home/freddie/bleeding-edge-toolchain/src/newlib-nano-2.1 D:/gcc-arm-none-eabi-4_8-141002/newlib-nano-2.1
