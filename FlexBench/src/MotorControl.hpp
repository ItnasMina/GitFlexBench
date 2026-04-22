#ifndef _MOTORCONTROL_HPP_
#define _MOTORCONTROL_HPP_

#include <Arduino.h>

// Funciones expuestas
void initMotor();

void motorMove(char direc, int steps);

void setInitialPos();

long getActualPos();

#endif