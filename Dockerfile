FROM ubuntu:latest
LABEL author="Anderson Ignacio da Silva"
LABEL maintainer="anderson@aignacio.com"
RUN apt-get update && apt-get upgrade -y
RUN apt-get install git file gcc make time wget zip -y
#sv2v
RUN wget https://github.com/zachjs/sv2v/releases/download/v0.0.9/sv2v-Linux.zip
RUN unzip sv2v-Linux.zip && rm sv2v-Linux.zip
RUN ln -s /sv2v-Linux/sv2v /usr/bin/sv2v && chmod +x /sv2v-Linux/sv2v
#RUN apt-get install verilator -y
# Verilator dependencies
RUN apt-get install git perl python3 make autoconf g++ flex bison ccache -y
RUN apt-get install libgoogle-perftools-dev numactl perl-doc -y
RUN apt-get install libfl2 -y # Ubuntu only (ignore if gives error)
RUN apt-get install libfl-dev -y # Ubuntu only (ignore if gives error)
RUN apt-get install zlibc zlib1g zlib1g-dev -y # Ubuntu only (ignore if gives error)
#Building verilator
RUN git clone https://github.com/verilator/verilator
WORKDIR verilator
RUN export VERILATOR_ROOT=.  # For csh; ignore error if on bash
RUN git checkout stable      # Update latest stable
RUN autoconf                 # Create ./configure script
RUN ./configure              # Configure and create Makefile
RUN make -j4                 # Build Verilator itself (if error, try just 'make')
RUN make install
