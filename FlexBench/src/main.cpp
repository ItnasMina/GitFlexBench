#include <Arduino.h>
#include "MATLABComms.hpp"
#include "MotorControl.hpp"
#include "SensorControl.hpp"


void setup() {

  initMATLABComms();
  initMotor();
  initSensor();
  
  enviarMensajeMATLAB("SISTEM READY AND WAITING");   // Avisa a MATLAB que el sistema está listo
}

void loop() {
  char comando = leerComandoMATLAB();
  
  if (comando != '\0') {
    
    enviarMensajeMATLAB("EXECUTING COMMAND: " + String(comando));

    if (comando == 'R') {
      enviarMensajeMATLAB("RES: " + String(leerResistencia()) + " Ohms");
    } else if (comando == 'P') {
      //enviarMensajeMATLAB("POS: " + String(getPosicionActual()));
    }else {
    
      motorMove(comando);
      enviarMensajeMATLAB("MOVEMENT EXECUTED");
    }
  }
}