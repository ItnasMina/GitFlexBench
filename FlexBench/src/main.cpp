#include <Arduino.h>
#include <TMCStepper.h> 
#include "Pinout.hpp"

// --- CONFIGURACIÓN DEL DRIVER TMC2209 ---
#define R_SENSE 0.11f       // Resistencia de sensado de tu módulo BigTreeTech
#define DRIVER_ADDRESS 0b00 // Dirección por defecto

// Creamos la conexión por el puerto Serial1
TMC2209Stepper driver(&Serial1, R_SENSE, DRIVER_ADDRESS);

void setup() {
  Serial.begin(115200);
  delay(3000);

  Serial.println("\n=========================================");
  Serial.println("INICIANDO MODO AVANZADO: UART + StealthChop");
  Serial.println("=========================================\n");

  // Configuramos pines
  pinMode(STEP_PIN, OUTPUT);
  pinMode(DIR_PIN, OUTPUT);
  pinMode(EN_PIN, OUTPUT);

  digitalWrite(EN_PIN, LOW);    // Activamos el driver (Low Level)

  // Abrimos el canal de comunicación con el TMC2209
  Serial1.begin(115200, SERIAL_8N1, RX_PIN, TX_PIN);

  // Configuramos el "cerebro" del motor
  driver.begin();
  driver.toff(5);             // Enciende la etapa de potencia
  driver.rms_current(800);    // Ajustamos la fuerza (Corriente en mA)
  driver.microsteps(256);     // Dividimos cada paso en 256 micropasos
  
  // Activamos el silencio absoluto
  driver.en_spreadCycle(false); 
  driver.pwm_autoscale(true);

  // Verificación de seguridad
  uint16_t version = driver.version();
  Serial.print("Versión del chip TMC detectada: ");
  Serial.println(version, HEX);
  
  if(version == 0 || version == 0xFFFF) {
    Serial.println("ERROR CRÍTICO: El ESP32 no escucha al driver.");
    Serial.println("-> Revisa que los cables 17 y 18 estén cruzados correctamente (TX a RX).");
  } else {
    Serial.println("-> ¡Comunicación UART Perfecta! El motor girará en silencio.");
  }
}

void loop() {
  Serial.println("Bajando cremallera...");
  digitalWrite(DIR_PIN, HIGH); 

  // Generamos pulsos básicos. 
  // Modifica el 1000 para cambiar la velocidad (menor número = más rápido)
  for (int i = 0; i < 1600; i++) {
    digitalWrite(STEP_PIN, HIGH);
    delayMicroseconds(500); 
    digitalWrite(STEP_PIN, LOW);
    delayMicroseconds(500); 
  }

  delay(1000); // Pausa

  Serial.println("Subiendo cremallera...");
  digitalWrite(DIR_PIN, LOW); 

  for (int i = 0; i < 1600; i++) {
    digitalWrite(STEP_PIN, HIGH);
    delayMicroseconds(500);
    digitalWrite(STEP_PIN, LOW);
    delayMicroseconds(500);
  }

  delay(1000); // Pausa
}