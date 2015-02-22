require 'rake/clean'
MFACTOR="mfactor"               # directory to mfactor submodule
CUBEMX="cubemx-f4-discovery"    # directory to vendor-supplied files
BINARY="image.elf"              # output binary
# constants needed by the mfactor rake task
MFACTOR_SRC_DIR="src/mfactor"   # local mfactor sources
GENERATOR="Cortex"              # byte code generator backend
MFACTOR_ROOT_VOCAB="listener"   # root vocabulary for dependency resolution
START_WORD="listener"           # intepreter entry point
# MFACTOR_DEPENDING_OBJECT="mfactor/src/interpreter.c" # file or task to which the dependencies of the mfactor rake task are added
#TRANSLATION_YAML_FILE = "c_mfactor_trans.yml"

import "#{MFACTOR}/tasks/stdlib.rake" # provides :stdlib rake target which does all the work

BUILD="build"                   # output directory
directory BUILD

# LDSCRIPT="ld/minimal.ld"
LDSCRIPT="\"#{CUBEMX}/TrueSTUDIO/#{CUBEMX} Configuration/STM32F407VG_FLASH.ld\""

CFLAGS_FILE="cflags.rb"
load CFLAGS_FILE
ARCH_FLAGS="-mcpu=cortex-m4 -mthumb"
CFLAGS = "-ffunction-sections -fdata-sections -std=gnu99 -O#{OPT} #{ARCH_FLAGS} #{FLAGS}"         # used by interpreter code
CFLAGS << " "+DEFINES.map {|k,v| "-D#{k.to_s}=#{v.to_s}"}.join(' ')
LDFLAGS="-O#{OPT} -Wl,-Map=#{BUILD}/#{BINARY.ext('map')} --specs=nano.specs -Lld -lc -lnosys -flto -Wl,--gc-sections -Wl,--cref #{ARCH_FLAGS} -T #{LDSCRIPT}"
PREFIX="arm-none-eabi"
CC="#{PREFIX}-gcc"
LD="#{PREFIX}-gcc"
AR="#{PREFIX}-ar"
SIZE="#{PREFIX}-size"
OBJDUMP="#{PREFIX}-objdump"

# STARTUP="src/startup_ARMCM3.S"
STARTUP="#{CUBEMX}/Drivers/CMSIS/Device/ST/STM32F4xx/Source/Templates/gcc/startup_stm32f407xx.s"
LOCAL_SRCS=FileList["src/**.c",STARTUP]
MFACTOR_SRCS=FileList["#{MFACTOR}/src/[reader,interpreter]*.c"]
CUBEMX_SRCS=FileList["#{CUBEMX}/Src/*.c",
                     "#{CUBEMX}/Drivers/STM32F4xx_HAL_Driver/Src/*.c",
                     "#{CUBEMX}/Drivers/CMSIS/Device/ST/STM32F4xx/Source/Templates/system_stm32f4xx.c"]
LOCAL_INCLUDES=[".","inc","#{MFACTOR}/src"]
CUBEMX_INCLUDES=["#{CUBEMX}/Inc",
                 "#{CUBEMX}/Drivers/CMSIS/Device/ST/STM32F4xx/Include",
                 "#{CUBEMX}/Drivers/CMSIS/Include",
                 "#{CUBEMX}/Drivers/STM32F4xx_HAL_Driver/Inc"]

INCLUDES=LOCAL_INCLUDES+CUBEMX_INCLUDES
CFLAGS << " #{INCLUDES.map{|i| i.prepend('-I')}.join(' ')}"
SRCS=LOCAL_SRCS+MFACTOR_SRCS+CUBEMX_SRCS

def build_path(sourcefile)
  "#{BUILD}/"+sourcefile.gsub("/","_").ext("o")
end

OBJS=[]
SRCS.each do |f|
  o=build_path(f)
  OBJS.push o
  file o => [f,CFLAGS_FILE,BUILD] do
    sh "#{CC} #{CFLAGS} -c -o #{o} #{f}"
  end
end

OUTPUT="#{BUILD}/#{BINARY}"

file OUTPUT => [:stdlib]+OBJS do 
  sh "#{CC} #{LDFLAGS} #{OBJS.join(' ')} -o #{OUTPUT}"
end

task :size => [OUTPUT] do
  sh "#{SIZE} #{OUTPUT}"
end

task :disasm => [OUTPUT] do
  sh "#{OBJDUMP} -S -d #{OUTPUT} > #{OUTPUT.ext('asm')}"
end

task :default => [OUTPUT,:size,:disasm]

CLEAN.include BUILD
CLEAN.include "generated"
