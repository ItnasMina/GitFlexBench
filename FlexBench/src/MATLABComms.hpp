#pragma once
#include <Arduino.h>


struct Command {
  char type;
  int  value;
};


void initMATLABComms();

Command readCommandMATLAB();

void sendMessageMATLAB(String mensaje);