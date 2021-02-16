FROM ubuntu:20.04
#build base image, keep ROOT version and G4 version same as cvmfs LCG_97a
LABEL maintainer.name="DSS team"
LABEL version="20210216"
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
 && rm -rf /var/lib/apt/lists/* \
 && ldconfig \
 && strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so \
 && ldconfig -v
#strip is to solve the problem in qt5 which checks the compatibility with the host kernel.
#check by yourself then.

#Layer2: ROOT
WORKDIR /tmp
ARG ROOT_VERSION=6.20.06
ARG ROOT_SRC=root_v${ROOT_VERSION}.source.tar.gz
ENV ROOTSYS /opt/root
RUN wget https://root.cern/download/${ROOT_SRC} \
 && tar -xzvf ${ROOT_SRC} && rm -f ${ROOT_SRC} \
 && mkdir root-build && cd root-build \
 && cmake - qt5web=ON -DCMAKE_INSTALL_PREFIX=${ROOTSYS} -DCMAKE_CXX_STANDARD=17 ../root-${ROOT_VERSION} ;\
    make -j12;\
    make install && cd .. && rm -rf root-build root-${ROOT_VERSION} \
 && echo ${ROOTSYS}/lib >> /etc/ld.so.conf \
 && ldconfig -v

ENV PATH ${ROOTSYS}/bin:$PATH
ENV PYTHONPATH ${ROOTSYS}/lib:${PYTHONPATH}
ENV CLING_STANDARD_PCH none

#Layer3: GEANT4
# we do not source root anymore like
#SHELL ["/bin/bash", "-c"]
#    && . ${ROOTSYS}/bin/thisroot.sh\
# since we have already set necessary ENV
WORKDIR /tmp
#the versiongig is intertesting...
ARG GEANT_NAME=geant4.10.06.p02
ARG GEANT4_VERSION=10.06.2
ARG GEANT4_DATA_VERSION=10.6.2
ENV G4INSTALL /opt/geant4
RUN wget http://cern.ch/geant4-data/releases/${GEANT_NAME}.tar.gz \
    && tar -xzvf ${GEANT_NAME}.tar.gz && rm -f ${GEANT_NAME}.tar.gz \
    && mkdir geant4-build && cd geant4-build\
    && cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo \
          -DCMAKE_INSTALL_PREFIX=${G4INSTALL} \
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
    make -j12 ;\
    make install && cd .. && rm -rf ${GEANT_NAME} geant4-build \
    && echo ${G4INSTALL}/lib >> /etc/ld.so.conf \
    && ldconfig -v 

ENV PATH ${G4INSTALL}/bin:${PATH}
ENV G4COMP ${G4INSTALL}/lib/Geant4-${GEANT4_VERSION}
ENV G4DATA ${G4INSTALL}/share/Geant4-${GEANT4_DATA_VERSION}/data

#need better method set version-dependent version
#this is to avoid source geant4.sh
ENV G4NEUTRONHPDATA ${G4DATA}/G4NDL4.6
ENV G4LEDATA ${G4DATA}/G4EMLOW7.9.1
ENV G4LEVELGAMMADATA ${G4DATA}/PhotonEvaporation5.5
ENV G4RADIOACTIVEDATA ${G4DATA}/RadioactiveDecay5.4
ENV G4PARTICLEXSDATA ${G4DATA}/G4PARTICLEXS2.1
ENV G4PIIDATA ${G4DATA}/G4PII1.3
ENV G4REALSURFACEDATA ${G4DATA}/RealSurface2.1.1
ENV G4SAIDXSDATA ${G4DATA}/G4SAIDDATA2.0
ENV G4ABLADATA ${G4DATA}/G4ABLA3.1
ENV G4INCLDATA ${G4DATA}/G4INCL1.0
ENV G4ENSDFSTATEDATA ${G4DATA}/G4ENSDFSTATE2.2

#Final: chdir to opt and source necessary environment.
WORKDIR /opt
COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

ENTRYPOINT [ "/opt/entrypoint.sh" ]
