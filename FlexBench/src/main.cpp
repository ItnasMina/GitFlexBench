#include <Arduino.h>
#include "MATLABComms.hpp"
#include "MotorControl.hpp"

void setup() {
  initMATLABComms();
  initMotor();
  
  // Le decimos a MATLAB que ya hemos terminado de configurar todo
  enviarMensajeMATLAB("SISTEM READY AND WAITING");
}

void loop() {
  char comando = leerComandoMATLAB();
  
  if (comando != '\0') {
    
    enviarMensajeMATLAB("EXECUTING COMMAND: " + String(comando));
    
    motorMove(comando);
    
    enviarMensajeMATLAB("MOVEMENT EXECUTED");
  }
}