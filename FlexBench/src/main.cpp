#include <Arduino.h>
#include "Pinout.hpp"
#include "MATLABComms.hpp"
#include "MotorControl.hpp"
#include "SensorControl.hpp"

#define MESSAGE // Habilita mensajes de depuración a MATLAB


void setup() {

  initMATLABComms();
  initMotor();
  initSensor();

  #ifdef MESSAGE
    sendMessageMATLAB("SISTEM READY AND WAITING");   // Avisa a MATLAB que el sistema está listo
  #endif
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
    }else if (comando.type == 'T') {
      setTiempoMuestro(comando.value);
      #ifdef MESSAGE
        sendMessageMATLAB("SAMPLE TIME SET TO: " + String(comando.value) + " ms");
      #endif
    }else{
      #ifdef MESSAGE
         sendMessageMATLAB("INVALID COMMAND");
      #endif
    }
  }
}