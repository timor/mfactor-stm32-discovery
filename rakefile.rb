require 'rake/clean'
MFACTOR="mfactor"               # directory to mfactor submodule
CUBEMX="cubemx-f4-discovery"    # directory to vendor-supplied files
BINARY="image.elf"              # output binary
# constants needed by the mfactor rake task
MFACTOR_SRC_DIR="src/mfactor"   # local mfactor sources
GENERATOR="Cortex"              # byte code generator backend
MFACTOR_ROOT_VOCAB="application"   # root vocabulary for dependency resolution
START_WORD="application"           # intepreter entry point
# file or task to which the dependencies of the mfactor rake task are added
# MFACTOR_DEPENDING_OBJECTS=["build/mfactor_src_interpreter_ivm32_c.o"]
MFACTOR_DEPENDING_OBJECTS=["build/mfactor_src_interpreter_c.o"]
#TRANSLATION_YAML_FILE = "c_mfactor_trans.yml"

import "#{MFACTOR}/tasks/mfactor.rake" # provides :mfactor rake target which does all the work

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
MFACTOR_SRCS=FileList["#{MFACTOR}/src/reader.c","#{MFACTOR}/src/interpreter.c"]
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

file "build/mfactor_src_interpreter_ivm32.o" => "mfactor/src/ivm32.h"

OBJS=[]
SRCS.each do |f|
  o=build_path(f)
  OBJS.push o
  file o => [f,CFLAGS_FILE,BUILD] do
    sh "#{CC} #{CFLAGS} -c -o #{o} #{f}"
  end
end

OUTPUT="#{BUILD}/#{BINARY}"

file OUTPUT => [:mfactor]+OBJS do
  sh "#{CC} #{LDFLAGS} #{OBJS.join(' ')} -o #{OUTPUT}"
end

task :size => [OUTPUT] do
  sh "#{SIZE} #{OUTPUT}"
end

task :disasm => [OUTPUT] do
  sh "#{OBJDUMP} -S -d #{OUTPUT} > #{OUTPUT.ext('asm')}"
end

task :default => [OUTPUT,:size,:disasm]

task :rebuild => [:clean,:force_image,:default]


CLEAN.include BUILD
CLOBBER.include "generated"
