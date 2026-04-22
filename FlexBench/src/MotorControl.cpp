#include "MotorControl.hpp"
#include "Pinout.hpp"
#include <TMCStepper.h>

// --- CONFIGURACIÓN DEL DRIVER (Oculta del main) ---
#define R_SENSE 0.11f
#define DRIVER_ADDRESS 0b00

// El objeto 'driver' ahora vive solo aquí adentro
TMC2209Stepper driver(&Serial1, R_SENSE, DRIVER_ADDRESS);

//Funcion de inicialización del motor
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


/* Función para mover el motor en una dirección dada:
- 'U' para subir
- 'D' para bajar
*/
void motorMove(char direccion, int steps) {
  if (direccion == 'U') {
    digitalWrite(DIR_PIN, HIGH); // Subir
    for (int i = 0; i < steps; i++) {
      digitalWrite(STEP_PIN, HIGH); 
      delayMicroseconds(1000);
      digitalWrite(STEP_PIN, LOW);
      delayMicroseconds(1000); 
    }
  } 
  else if (direccion == 'D') {
    digitalWrite(DIR_PIN, LOW); // Bajar
    for (int i = 0; i < steps; i++) {
      digitalWrite(STEP_PIN, HIGH);
      delayMicroseconds(1000);
      digitalWrite(STEP_PIN, LOW);
      delayMicroseconds(1000);
    }
  } 
}


void setInitialPos() {
  // Aquí podrías implementar un homing usando un sensor o simplemente asumir que el motor empieza en una posición conocida.
  // Por ejemplo, podrías mover el motor hacia abajo hasta que un sensor de límite se active, y luego resetear la posición a cero.
}

long getActualPos() {
  // Aquí podrías implementar un homing usando un sensor o simplemente asumir que el motor empieza en una posición conocida.
  // Por ejemplo, podrías mover el motor hacia abajo hasta que un sensor de límite se active, y luego resetear la posición a cero.
  return 0; // Placeholder, reemplazar con la lógica real para obtener la posición actual del motor
}