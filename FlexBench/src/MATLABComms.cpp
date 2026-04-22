#include "MATLABComms.hpp"

void initMATLABComms() {
  Serial.begin(115200);
  delay(3000); // El respiro necesario para el USB del ESP32-S3
  Serial.println("\n[SISTEM] Comunication Module Initialized.");
}


/* Función para leer el comando enviado por MATLAB a través del USB.
   Si no hay ningún comando o el comando no es válido, devuelve '\0'.
   Filtra para aceptar solo los comandos:
   - U: Mover hacia arriba
   - D: Mover hacia abajo
   - R: Leer resistencia
*/
Command readCommandMATLAB() {
  Command cmd = {'\0', 0}; // Comando por defecto: "vacío"
  // Si hay datos esperando en el cable USB...
  if (Serial.available() > 0) {
    String texto = Serial.readStringUntil('\n');
    texto.trim();                   // Elimina espacios en blanco y saltos de línea
    texto.toUpperCase();            // Convierte a mayúscula para evitar problemas de formato

    if (texto.length() > 0) {
      // Metemos la primera letra en la variable 'letra' de la caja
      cmd.type = texto.charAt(0);
      
      // Si hay más texto después de la letra, lo convertimos a número
      if (texto.length() > 1) {
        String numeroEnTexto = texto.substring(1);
        cmd.value = numeroEnTexto.toInt();
      }
    }
  }
  return cmd;
}

// Función para enviar un mensaje de texto a MATLAB a través del USB
void sendMessageMATLAB(String mensaje) {
  Serial.println(mensaje); // Envía el texto con un salto de línea al final
}
