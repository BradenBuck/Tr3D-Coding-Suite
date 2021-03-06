#######################################
#        Makefile for GX
#######################################

TARGET    = gx

#######################################
# Include system-dependent make variables
#######################################

ifndef GK_SYSTEM
	ifdef SYSTEM
$(warning SYSTEM environment variable is obsolete)
$(warning use GK_SYSTEM instead)
	GK_SYSTEM = $(SYSTEM)
	else
$(error GK_SYSTEM is not set)
	endif
endif
include Makefiles/Makefile.$(GK_SYSTEM)

############################
## Setup Compiler Flags
###########################

CC = $(NVCC)
LD = $(NVCC)
GEO_LIBS=${GS2}/geometry_c_interface.o 
GS2_CUDA_FLAGS=-I ${GS2} ${GS2}/libgs2.a ${GS2}/libsimpledataio.a 

CFLAGS= ${CUDA_INC} ${MPI_INC} ${GSL_INC} ${CUTENSOR_INC}
LDFLAGS= $(CUDA_LIB) ${MPI_LIB} ${GSL_LIB} ${NETCDF_LIB} ${CUTENSOR_LIB}

#####################################
# Rule for building the system_config
# used by the build script
#####################################

ifdef STANDARD_SYSTEM_CONFIGURATION
system_config: Makefiles/Makefile.$(GK_SYSTEM) Makefile
	@echo "#!/bin/bash " > system_config
	@echo "$(STANDARD_SYSTEM_CONFIGURATION)" >> system_config
	@sed -i 's/^ //' system_config
else
.PHONY: system_config
system_config:
	$(error "STANDARD_SYSTEM_CONFIGURATION is not defined for this system")
endif

VPATH=.:src

##########################
## Suffix Build Rules
#############################

.SUFFIXES:
.SUFFIXES: .c .cpp .cu .o .d
.DEFAULT_GOAL := $(TARGET)

HEADERS=$(wildcard include/*.h) 

obj/%.o: %.cu $(HEADERS) 
	$(NVCC) -w -dc -o $@ $< $(CFLAGS) $(NVCCFLAGS) -I. -I include 

obj/%.o: %.cpp $(HEADERS)
	$(CC) -c -o $@ $< $(CFLAGS) -I. -I include

.SILENT: src/version.c obj/version.o

obj/version.o: src/version.c
	$(CC) -c -o $@ $< $(CFLAGS) -I. -I include

src/version.c: 
	git describe --always --dirty --tags | awk ' BEGIN {print "#include \"version.h\""} {print "const char * build_git_sha = \"" $$0"\";"} END {}' > src/version.c
	date | awk 'BEGIN {} {print "const char * build_git_time = \""$$0"\";"} END {} ' >> src/version.c
	whoami | awk 'BEGIN {} {print "const char * build_user = \""$$0"\";"} END {} ' >> src/version.c
	hostname | awk 'BEGIN {} {print "const char * build_hostname = \""$$0"\";"} END {} ' >> src/version.c

#######################################
# Rules for building gx
####################################
OBJS = device_funcs.o parameters.o grids.o reductions.o reservoir.o grad_perp.o fields.o moments.o forcing.o grad_parallel.o grad_parallel_linked.o geometry.o laguerre_transform.o nca.o ncdf.o solver.o smith_par_closure.o closures.o linear.o nonlinear.o timestepper.o diagnostics.o run_gx.o version.o main.o 

# main program
$(TARGET): $(addprefix obj/, $(OBJS))
	$(NVCC) $(NVCCFLAGS) -o $@ $(addprefix obj/, $(OBJS)) $(LDFLAGS)
	@mv src/version.c old/version.c

########################
# Cleaning up
########################

clean: 
	rm -rf obj/*.o *~ \#*

distclean: clean clean_tests
	rm -rf $(TARGET)

#########################
# Misc
#######################


test_make:
	@echo TARGET=    $(TARGET)
	@echo SDKDIR=    $(SDKDIR)
	@echo NVCC=      $(NVCC)
	@echo CFLAGS= 	 $(CFLAGS)
	@echo LDFLAGS= 	 $(LDFLAGS)
	@echo NVCCFLAGS= $(NVCCFLAGS)
	@echo CUDA_INC=  $(CUDA_INC)
	@echo CUDA_LIB=  $(CUDA_LIB)
	@echo CUTENSOR_LIB=  $(CUTENSOR_LIB)



