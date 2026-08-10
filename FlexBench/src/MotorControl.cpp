#include <TMCStepper.h>
#include <Arduino.h>
#include "MotorControl.hpp"
#include "Pinout.hpp"

// Configuración del driver TMC2209
#define R_SENSE 0.11f
#define DRIVER_ADDRESS 0b00

TMC2209Stepper driver(&Serial1, R_SENSE, DRIVER_ADDRESS);

// Variables globales
long posicionActual = 0;
int tiempoMuestreo = 0;



void setTiempoMuestro(int ms) {
  tiempoMuestreo = ms;
}



//Funcion de inicialización del motor
void initMotor() {
  
  // Configuramos pines
  pinMode(STEP_PIN, OUTPUT);
  pinMode(DIR_PIN, OUTPUT);
  pinMode(EN_PIN, OUTPUT);

  // Activamos el driver
  digitalWrite(EN_PIN, LOW);
  
  delay(500);

  // Abrimos el canal de comunicación con el TMC2209
  Serial1.begin(115200, SERIAL_8N1, RX_PIN, TX_PIN);

  // Configuramos el "cerebro" del motor
  driver.begin();
  driver.toff(5);
  driver.rms_current(1100);
  driver.microsteps(64);
  
  // Activamos el silencio absoluto (desactivado)
  driver.en_spreadCycle(true); 
  driver.pwm_autoscale(true);


  uint8_t conexion = driver.test_connection();
  
  if (conexion == 0) {
    Serial.println("[MOTOR] UART OK! Driver recibiendo configuración.");
  } else {
    Serial.print("[MOTOR] ERROR UART (Código ");
    Serial.print(conexion);
    Serial.println("): El driver está en modo por defecto.");
  }
  
}



/* Función para mover el motor en una dirección dada:
- 'U' para subir lento
- 'D' para bajar lento
- 'V' para subir rápido
- 'W' para bajar rápido
*/
void motorMove(char direccion, int steps) {
  if (direccion == 'U') {
    digitalWrite(DIR_PIN, HIGH); // Subir
    for (int i = 0; i < steps; i++) {

      digitalWrite(STEP_PIN, HIGH); 
      delayMicroseconds(400);
      digitalWrite(STEP_PIN, LOW);
      delayMicroseconds(400);
      
      posicionActual++;

      if (i % 50 == 0) yield();
    }
  } else if (direccion == 'D') {
    digitalWrite(DIR_PIN, LOW); // Bajar
    for (int i = 0; i < steps; i++) {

      digitalWrite(STEP_PIN, HIGH);
      delayMicroseconds(400);
      digitalWrite(STEP_PIN, LOW);
      delayMicroseconds(400);

      posicionActual--;

      if (i % 50 == 0) yield();
    }
  }  else if (direccion == 'V') {
    digitalWrite(DIR_PIN, HIGH); // Subir
    for (int i = 0; i < steps; i++) {

      digitalWrite(STEP_PIN, HIGH);
      delayMicroseconds(100);
      digitalWrite(STEP_PIN, LOW);
      delayMicroseconds(100);

      posicionActual++;

      if (i % 50 == 0) yield();
    }
  }
    else if (direccion == 'W') {
    digitalWrite(DIR_PIN, LOW); // Bajar
    for (int i = 0; i < steps; i++) {

      digitalWrite(STEP_PIN, HIGH);
      delayMicroseconds(100);
      digitalWrite(STEP_PIN, LOW);
      delayMicroseconds(100);

      posicionActual--;

      if (i % 50 == 0) yield();
    }
  }
}




void setInitialPos() {
  posicionActual = 0;
}




long getActualPos() {
  return posicionActual;
}