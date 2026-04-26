#ifndef _MATLABCOMMS_HPP_
#define _MATLABCOMMS_HPP_

#include "Arduino.h"

struct Command {
  char type;
  int  value;
};


void initMATLABComms();

Command readCommandMATLAB();

void sendMessageMATLAB(String mensaje);

#endif