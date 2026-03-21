#include <Arduino.h>
#include "MATLABComms.hpp"
#include "MotorControl.hpp"

void setup() {
  initMATLABComms();
  initMotor();
  
  // Le decimos a MATLAB que ya hemos terminado de configurar todo
  enviarMensajeMATLAB("SISTEMA_PREPARADO_Y_A_LA_ESPERA");
}

void loop() {
  char comando = leerComandoMATLAB();
  
  if (comando != '\0') {
    
    enviarMensajeMATLAB("CONFIRMADO: Ejecutando comando " + String(comando));
    
    motorMove(comando);
    
    enviarMensajeMATLAB("MOVIMIENTO_FINALIZADO");
  }
}