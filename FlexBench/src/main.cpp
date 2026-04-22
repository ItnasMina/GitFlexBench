#include <Arduino.h>
#include "MATLABComms.hpp"
#include "MotorControl.hpp"
#include "SensorControl.hpp"


void setup() {

  initMATLABComms();
  initMotor();
  initSensor();
  sendMessageMATLAB("SISTEM INITIALIZED: READY FOR SETUP");   // Avisa a MATLAB que el sistema ha sido inicializado

  sendMessageMATLAB("SISTEM READY AND WAITING");   // Avisa a MATLAB que el sistema está listo
}

void loop() {
  Command comando = readCommandMATLAB();
  
  if (comando.type != '\0') {

    if (comando.type == 'U' || comando.type == 'D') {

      comando.value = (comando.value <= 0) ? 100 : comando.value; // Por defecto, 100 pasos
      motorMove(comando.type, comando.value);
      sendMessageMATLAB("MOVEMENT EXECUTED");

    }else if (comando.type == 'R') {
      sendMessageMATLAB("RES: " + String(leerResistencia()));

    }else if (comando.type == 'S') {
      setInitialPos();
      sendMessageMATLAB("ZERO POSITION SET");

    }else if (comando.type == 'P') {

      if (comando.value == 1) {
        sendMessageMATLAB("MIN:" + String(getActualPos()));
      } else if(comando.value == 2) {
        sendMessageMATLAB("MAX:" + String(getActualPos()));
      } else {
        sendMessageMATLAB("POS:" + String(getActualPos()));
      }

    }else{
      sendMessageMATLAB("INVALID COMMAND");
    }
    sendMessageMATLAB("EXECUTING COMMAND: " + String(comando.type) + String(comando.value));
  }
}