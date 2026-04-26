#ifndef _MOTORCONTROL_HPP_
#define _MOTORCONTROL_HPP_


void initMotor();

void motorMove(char direc, int steps);

void setInitialPos();

long getActualPos();

void setTiempoMuestro(int ms);

#endif