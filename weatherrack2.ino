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
#include <Wire.h>
#include <PinChangeInterrupt.h>
#include <ArduinoJson.h>
#include <DallasTemperature.h>
#include <OneWire.h>
#include <TimerObject.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_TSL2561_U.h>


// choose a valid PinChangeInterrupt pin of your Arduino board
#define pinVel 9
#define pinRain 10
#define pinTmp 6
#define ONE_WIRE_BUS pinTmp
#define pinLux A3
#define pinDir A0

OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
DeviceAddress thermometer = { 0x28, 0xC1, 0xD1, 0xDC, 0x06, 0x00, 0x00, 0xE7 };
Adafruit_TSL2561_Unified tsl0 = Adafruit_TSL2561_Unified(TSL2561_ADDR_FLOAT, 12345);

volatile unsigned long int vel = 0;
volatile unsigned long int rain_cnt = 0;
const float per_tip = 0.0110;
int rpt_ms = 15000;
int rpt_sec = rpt_ms / 1000;
int analog_lux = 0;
int battVolts;
boolean debugger = false;
uint16_t broadband = 0;
uint16_t infrared = 0;

//3.3V
float volts[8] = {
  3.05,
  2.86,  
  2.54,  
  1.49,
  0.31,
  0.60,  
  0.93,
  2.03
};

int deg[8] = {
  0,
  45,
  90,
  135,
  180,
  225,
  270,
  315
};

void velocity(void);
void rain(void);
void dbug();
int getBandgap(void);
float get_lux0(void);
void make_json();
TimerObject *report = new TimerObject(rpt_ms);
TimerObject *debug  = new TimerObject(rpt_ms);
//############################################3
void setup() {
  Serial.begin(115200);
  pinMode(pinVel, INPUT_PULLUP);
  pinMode(pinRain, INPUT_PULLUP);
  pinMode(pinTmp, INPUT_PULLUP);

  attachPinChangeInterrupt(digitalPinToPinChangeInterrupt(pinVel), velocity, RISING);
  attachPinChangeInterrupt(digitalPinToPinChangeInterrupt(pinRain), rain, RISING);
//  get_i2c(); This does not seem to work on pro trinket.  works fine on pro mini
  if(!tsl0.begin()) {
    /* There was a problem detecting the ADXL345 ... check your connections */
    Serial.print("Ooops, first TSL2561 not detected ... Check your wiring or I2C ADDR!");
    while(1);
  } else {
    configureSensor();
    displaySensorDetails();
  }
  
  sensors.begin();
  // set the resolution to 10 bit (good enough?)
  sensors.setResolution(thermometer, 10);

  report->setOnTimer(&make_json);
  report->Start();

  debug->setOnTimer(&dbug);
  if (debugger == true) {
    debug->Start();
  }
}
//#############################################
void loop() {
  if (debugger == true) {
    rpt_ms = 5000;
    debug->Update();
  }
  report->Update();
}
//##########################################
void dbug() {
  Serial.println("");
  Serial.println();
  Serial.println("Debug Start");
  Serial.print("Velocity Count ");
  Serial.println(vel);
  Serial.print("Rain Count ");
  Serial.println(rain_cnt);
  Serial.print("pinDir value ");
  Serial.println(analogRead(pinDir));
  Serial.print("Oper. Voltage ");
  Serial.println(getBandgap());
  Serial.print("light reading ");
  Serial.println(get_lux0());
  Serial.println();
  Serial.print("broad band light");
  Serial.println(get_bb_light());
  Serial.print("infrared light");
  Serial.println(get_ir_light());
  Serial.println("Debug End");
}
//############################################

