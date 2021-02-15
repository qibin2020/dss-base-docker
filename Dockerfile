FROM ubuntu:20.04
#build base image, keep ROOT version and G4 version same as cvmfs LCG_97a
LABEL maintainer.name="DSS team"
LABEL version="20210215"
LABEL maintainer.email="qibin.liu@cern.ch"

ENV LANG=C.UTF-8

#Layer1: apt addition
WORKDIR /opt
COPY packages packages
# Disable Prompt During Packages Installation
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update  \
 && ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
 && apt-get -y install $(cat packages) wget\
 && dpkg-reconfigure locales \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* 

#Layer2: ROOT
WORKDIR /tmp
ARG ROOT_VERSION=6.20.06
ARG ROOT_SRC=root_v${ROOT_VERSION}.source.tar.gz
RUN wget https://root.cern/download/${ROOT_SRC} \
 && tar -xzvf ${ROOT_SRC} && rm -f ${ROOT_SRC} \
 && mkdir root-build && cd root-build \
 && cmake - qt5web=ON -DCMAKE_INSTALL_PREFIX=/opt/root -DCMAKE_CXX_STANDARD=17 ../root-${ROOT_VERSION} ;\
    make -j12;\
    make install && cd .. && rm -rf root-build root-${ROOT_VERSION} \
 && echo /opt/root/lib >> /etc/ld.so.conf \
 && ldconfig

ENV ROOTSYS /opt/root
ENV PATH $ROOTSYS/bin:$PATH
ENV PYTHONPATH $ROOTSYS/lib:$PYTHONPATH
ENV CLING_STANDARD_PCH none

#Layer3: GEANT4
SHELL ["/bin/bash", "-c"]
WORKDIR /tmp
ARG GEANT_NAME=geant4.10.06.p02
ARG GEANT4_VERSION=10.06.2
RUN wget http://cern.ch/geant4-data/releases/${GEANT_NAME}.tar.gz \
    && tar -xzvf ${GEANT_NAME}.tar.gz && rm -f ${GEANT_NAME}.tar.gz \
    && mkdir geant4-build && cd geant4-build\
    && . ${ROOTSYS}/bin/thisroot.sh\
    && cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo \
          -DCMAKE_INSTALL_PREFIX=/opt/geant4 \
          -DGEANT4_BUILD_CXXSTD=17 \
          -DGEANT4_INSTALL_DATA=ON \
          -DGEANT4_USE_SYSTEM_CLHEP=OFF \
          -DGEANT4_USE_SYSTEM_EXPAT=OFF \
          -DGEANT4_USE_GDML=ON \
          -DGEANT4_USE_OPENGL_X11=ON \
          -DGEANT4_USE_QT=ON \
          -DGEANT4_USE_XM=ON \
          -DGEANT4_BUILD_MULTITHREADED=ON \
          ../${GEANT_NAME} ;\
    make -j8 ;\
    make install && cd .. && rm -rf ${GEANT_NAME} geant4-build

ENV G4COMP /opt/geant4/lib/Geant4-${GEANT4_VERSION}
ENV G4INSTALL /opt/geant4
ENV PATH ${G4INSTALL}/bin:${PATH}

#Final: chdir to opt and source necessary environment.
WORKDIR /opt
COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

ENTRYPOINT [ "/opt/entrypoint.sh" ]
