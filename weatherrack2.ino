/*
 Copyright (c) 2014-2015 NicoHood
 See the readme for credit to other people.

 PinChangeInterrupt_TickTock
 Demonstrates how to use the library

 Connect a button/cable to pin 10/11 and ground.
 The value printed on the serial port will increase
 if pin 10 is rising and decrease if pin 11 is falling.

 PinChangeInterrupts are different than normal Interrupts.
 See readme for more information.
 Dont use Serial or delay inside interrupts!
 This library is not compatible with SoftSerial.

 The following pins are usable for PinChangeInterrupt:
 Arduino Uno/Nano/Mini: All pins are usable
 Arduino Mega: 10, 11, 12, 13, 50, 51, 52, 53, A8 (62), A9 (63), A10 (64),
               A11 (65), A12 (66), A13 (67), A14 (68), A15 (69)
 Arduino Leonardo/Micro: 8, 9, 10, 11, 14 (MISO), 15 (SCK), 16 (MOSI)
 HoodLoader2: All (broken out 1-7) pins are usable
 Attiny 24/44/84: All pins are usable
 Attiny 25/45/85: All pins are usable
 ATmega644P/ATmega1284P: All pins are usable
 */
#include <PinChangeInterrupt.h>
#include <ArduinoJson.h>
#include <DallasTemperature.h>
#include <OneWire.h>

// choose a valid PinChangeInterrupt pin of your Arduino board
#define pinVel 8
#define pinRain 9
#define pinDir A0
#define pinTmp 5
#define ONE_WIRE_BUS pinTmp
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
DeviceAddress thermometer = { 0x28, 0xC1, 0xD1, 0xDC, 0x06, 0x00, 0x00, 0xE7 };

volatile long vel = 0;
volatile unsigned long int rain_cnt = 0;

const long int sc = 1000;
const long int mn = 60000;
const long int hr = 3600000;
const long int dy = 86400000;

float sec = 0;
float rpt_vel = 0;
float elapsed = 0;
unsigned long int cur_millis = 0;
unsigned long int last_millis = 0;
int rpt_period = 3000;

//5V
//byte dirva_lu[8][2] = {
//  {0.465,90},
//  {0.8968,135},
//  {1.3984,180},
//  {3.0856,235},
//  {2.2648,45},
//  {3.8456,0},
//  {4.3472,315},
//  {4.636,270}
//};
//3.3V
float volts[17] = {
  2.53,
  1.31,
  1.42,
  0.27,
  0.30,
  0.21,
  0.59,
  0.41,
  0.92,
  0.79,
  2.03,
  1.93,
  3.05,
  2,67,
  2.86,
  2.26  
};

int deg[16] = {
  0,
  22,
  45,
  67,
  90,
  112,
  135,
  157,
  180,
  202,
  225,
  247,
  270,
  292,
  315,
  337  
};

char dirad_lu[17][4] = {"N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW","\0"};
void velocity(void);
void rain(void);
//############################################3
void setup() {
  Serial.begin(115200);
  pinMode(pinVel, INPUT_PULLUP);
  pinMode(pinRain, INPUT_PULLUP);
  pinMode(pinDir, INPUT);
  pinMode(pinTmp, INPUT);

  attachPinChangeInterrupt(digitalPinToPinChangeInterrupt(pinVel), velocity, RISING);
  attachPinChangeInterrupt(digitalPinToPinChangeInterrupt(pinRain), rain, FALLING);

  sensors.begin();
  // set the resolution to 10 bit (good enough?)
  sensors.setResolution(thermometer, 10);

}
//#############################################
void loop() {
  cur_millis = millis();
  elapsed = cur_millis - last_millis;
  if ( elapsed >= rpt_period ) {
    sec = elapsed * .001;
    make_json();
    Serial.println();
    Serial.println("########"); 
    vel = 0;  //reset velocity after each report period
    last_millis = cur_millis;
  }
}
//##########################################
