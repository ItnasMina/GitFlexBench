#include "MotorControl.hpp"
#include "Pinout.hpp"
#include <TMCStepper.h>

// --- CONFIGURACIÓN DEL DRIVER (Oculta del main) ---
#define R_SENSE 0.11f
#define DRIVER_ADDRESS 0b00

// El objeto 'driver' ahora vive solo aquí adentro
TMC2209Stepper driver(&Serial1, R_SENSE, DRIVER_ADDRESS);

void initMotor() {
  
  // Configuramos pines
  pinMode(STEP_PIN, OUTPUT);
  pinMode(DIR_PIN, OUTPUT);
  pinMode(EN_PIN, OUTPUT);

  digitalWrite(EN_PIN, LOW);    // Activamos el driver

  // Abrimos el canal de comunicación con el TMC2209
  Serial1.begin(115200, SERIAL_8N1, RX_PIN, TX_PIN);

  // Configuramos el "cerebro" del motor
  driver.begin();
  driver.toff(5);
  driver.rms_current(800);
  driver.microsteps(256);
  
  // Activamos el silencio absoluto
  driver.en_spreadCycle(false); 
  driver.pwm_autoscale(true);
  
}

void motorMove(char direccion) {
  if (direccion == 'D') {
    digitalWrite(DIR_PIN, HIGH); // Bajar
    for (int i = 0; i < 600; i++) { // Da una vuelta entera bajando
      digitalWrite(STEP_PIN, HIGH); 
      delayMicroseconds(5000); 
      digitalWrite(STEP_PIN, LOW);
      delayMicroseconds(5000); 
    }
  } 
  else if (direccion == 'U') {
    digitalWrite(DIR_PIN, LOW); // Subir
    for (int i = 0; i < 600; i++) { // Da una vuelta entera subiendo
      digitalWrite(STEP_PIN, HIGH);
      delayMicroseconds(5000);
      digitalWrite(STEP_PIN, LOW);
      delayMicroseconds(5000);
    }
  } 
}