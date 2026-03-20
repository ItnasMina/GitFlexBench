#include <Arduino.h>
#include "Pinout.hpp"

void setup() {
  Serial.begin(115200);
  
  // Damos 3 segundos de respiro a Windows para reconocer el USB
  delay(3000); 

  Serial.println("\n=========================================");
  Serial.println("MODO BÁSICO ACTIVADO: Control STEP/DIR");
  Serial.println("=========================================\n");

  // Configuramos pines
  pinMode(STEP_PIN, OUTPUT);
  pinMode(DIR_PIN, OUTPUT);
  pinMode(EN_PIN, OUTPUT);

  // Activamos el driver (LOW es encendido)
  digitalWrite(EN_PIN, LOW); 
}

void loop() {
  Serial.println("Bajando cremallera...");
  digitalWrite(DIR_PIN, HIGH); 

  // Generamos pulsos básicos. 
  // Modifica el 1000 para cambiar la velocidad (menor número = más rápido)
  for (int i = 0; i < 1600; i++) {
    digitalWrite(STEP_PIN, HIGH);
    delayMicroseconds(1000); 
    digitalWrite(STEP_PIN, LOW);
    delayMicroseconds(1000); 
  }

  delay(1000); // Pausa

  Serial.println("Subiendo cremallera...");
  digitalWrite(DIR_PIN, LOW); 

  for (int i = 0; i < 1600; i++) {
    digitalWrite(STEP_PIN, HIGH);
    delayMicroseconds(1000);
    digitalWrite(STEP_PIN, LOW);
    delayMicroseconds(1000);
  }

  delay(1000); // Pausa
}