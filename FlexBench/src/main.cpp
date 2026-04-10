#include <Arduino.h>
#include "MATLABComms.hpp"
#include "MotorControl.hpp"
#include "SensorControl.hpp"

void setup() {

  initMATLABComms();
  initMotor();
  initSensor();
  
  // Le decimos a MATLAB que ya hemos terminado de configurar todo
  enviarMensajeMATLAB("SISTEM READY AND WAITING");
}

void loop() {
  char comando = leerComandoMATLAB();
  
  if (comando != '\0') {
    
    enviarMensajeMATLAB("EXECUTING COMMAND: " + String(comando));

    if (comando == 'R') {
      float resistencia = leerResistencia();
      if (resistencia < 0) {
        enviarMensajeMATLAB("ERROR: SENSOR DISCONNECTED");
      } else {
        enviarMensajeMATLAB("RESISTANCE: " + String(resistencia) + " Ohms");
      }
    } else {
    
      motorMove(comando);
      
      enviarMensajeMATLAB("MOVEMENT EXECUTED");
  
    }
  }
}