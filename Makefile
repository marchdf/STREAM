#================================================================================
#
# STANDARD COMPILERS
#
#================================================================================
CC = gcc
CFLAGS = -O2 -fopenmp

FC = gfortran
FFLAGS = -O2 -fopenmp

#================================================================================
#
# Problem definitions
#
#================================================================================
PROB_DEFS = -DSTREAM_ARRAY_SIZE=80000000 -DNTIMES=20

#================================================================================
#
# Architecture to compile for
#
#================================================================================

# defaults
ARCHFLAGS = 
KOKKOS_ARCH = "SNB"

# Knights corner
ifeq ($(ARCH),KNC)
ARCHFLAGS = -mmic
KOKKOS_ARCH = "KNC"
endif

#================================================================================
#
# KOKKOS DEFINITIONS
#
#================================================================================
ifeq ($(COMPILE_KOKKOS),TRUE)
KOKKOS_PATH = ${HOME}/kokkos
KOKKOS_DEVICES = "OpenMP"

SRC = stream.cpp

CXX = icc

CXXFLAGS = -O3
LINK = ${CXX}
LINKFLAGS = 

DEPFLAGS = -M

OBJ = $(SRC:.cpp=.o)
LIB =

include $(KOKKOS_PATH)/Makefile.kokkos
KOKKOS_CPPFLAGS := $(KOKKOS_CPPFLAGS) -DKOKKOS
endif

#================================================================================
#
# ACTUAL MAKE COMMANDS
#
#================================================================================

# Make all targets
all: original.stream_f.exe original.stream_c.exe

# Compile original Fortran version
original.stream_f.exe: stream.f mysecond.o
	$(CC) $(CFLAGS) -c mysecond.c
	$(FC) $(FFLAGS) -c stream.f
	$(FC) $(FFLAGS) stream.o mysecond.o -o original.stream_f.exe

# Compile original C version
original.stream_c.exe: stream.c
	$(CC) $(CFLAGS) stream.c -o original.stream_c.exe

# Compile original C version with icc (if anything its a little slower than the cpp version)
original.stream.icc.exe: stream.c
	icc -O3 -fopenmp $(PROB_DEFS) $(ARCHFLAGS) stream.c -o original.stream.icc.exe

# Compile minimally changed STREAM
stream.icc.exe: stream.cpp
	icc -O3 -fopenmp $(PROB_DEFS) $(ARCHFLAGS) stream.c -o stream.icc.exe

# Compile for the Kokkos version of STREAM
stream.kokkos.icc: $(OBJ) $(KOKKOS_LINK_DEPENDS)
	$(LINK) $(KOKKOS_LDFLAGS) $(LINKFLAGS) $(EXTRA_PATH) $(OBJ) $(KOKKOS_LIBS) $(LIB) $(PROB_DEFS) -o stream.kokkos.exe

# Kokkos compilation rules
%.o:%.cpp $(KOKKOS_CPP_DEPENDS)
	$(CXX) $(KOKKOS_CPPFLAGS) $(KOKKOS_CXXFLAGS) $(CXXFLAGS) $(EXTRA_INC) $(PROB_DEFS) -c $<

# Clean
clean:
	rm -f *.exe *.o Kokkos* libkokkos.a
