#include "MATLABComms.hpp"

void initMATLABComms() {
  Serial.begin(115200);
  delay(3000); // El respiro necesario para el USB del ESP32-S3
  Serial.println("\n[SISTEM] Comunication Module Initialized.");
}

// Función para leer el comando enviado por MATLAB a través del USB
char leerComandoMATLAB() {
  // Si hay datos esperando en el cable USB...
  if (Serial.available() > 0) {
    char comando = Serial.read();
    
    // Filtramos para hacer caso solo a nuestras letras clave
    // (Esto evita que saltos de línea o basura activen el motor)
    if (comando == 'U' || comando == 'D' || comando == 'R') {
      return comando;
    }
  }
  return '\0'; // Si no hay nada o es una letra no válida, devolvemos "vacío"
}

// Función para enviar un mensaje de texto a MATLAB a través del USB
void enviarMensajeMATLAB(String mensaje) {
  Serial.println(mensaje); // Envía el texto con un salto de línea al final
}
