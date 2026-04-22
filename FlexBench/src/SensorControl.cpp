#include "SensorControl.hpp"
#include "Pinout.hpp"

// Variable para tu resistencia fija (1k Ohm)
const float RESISTENCIA_FIJA = 1000.0;

//Inicializa el sensor de resistencia
void initSensor() {
  // En el ESP32 no es estrictamente necesario inicializar los pines analógicos,
  // pero es buena práctica configurar la resolución (por defecto es 12 bits: 0 a 4095)
  analogReadResolution(12); 
  Serial.println("[SENSOR] ADC Configurado a 12 bits en el Pin " + String(SENSOR_PIN));
}

float leerResistencia() {

  int valorCrudo = analogRead(SENSOR_PIN);
  
  // Evitamos dividir por cero si el sensor se desconecta y lee 4095
  if (valorCrudo >= 4095) return -1.0; // Código de error: "Circuito abierto"
  if (valorCrudo <= 0) return 0.0;     // Cortocircuito
  
  // Aplicamos la fórmula del divisor de tensión
  float resistenciaFilaflex = (valorCrudo * RESISTENCIA_FIJA) / (4095.0 - valorCrudo);
  
  return resistenciaFilaflex;
}
