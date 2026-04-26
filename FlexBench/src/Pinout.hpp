#ifndef PINOUT_HPP
#define PINOUT_HPP

// --- DEFINICIÓN DE PINES (Lado izquierdo del ESP32-S3) ---

#define STEP_PIN 11
#define DIR_PIN  10
#define EN_PIN   12

#define TX_PIN   17  // TX del ESP32 (Va al pin RX del driver)
#define RX_PIN   18  // RX del ESP32 (Va al pin TX del driver)

#define SENSOR_PIN 4 // Pin analógico (ADC1) para leer los datos del ensayo

#endif