#pragma once
#include <Arduino.h>

long getPosicionActual();

void initMATLABComms();

char leerComandoMATLAB();

void enviarMensajeMATLAB(String mensaje);