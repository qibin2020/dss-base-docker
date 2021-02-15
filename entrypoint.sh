#!/bin/bash
cd /opt
set -e
source ${ROOTSYS}/bin/thisroot.sh
source ${G4INSTALL}/bin/geant4.sh

export
which root
which geant4.sh

#export G4COMP=/usr/local/geant4/lib/Geant4-10.5.1
#export G4INSTALL=/usr/local/geant4
#export G4EXAMPLES=/usr/local/geant4/share/Geant4-10.5.1/examples

#export XAUTHORITY=/root/.Xauthority 

exec "$@"
