int get_dir() {
  float loval, hival;
  float voltage = (analogRead(pinDir)) * (3.300 / 1024);
  for (int a = 0; a < 8; a++) {
    loval = (volts[a]) - 0.1; 
    hival = (volts[a]) + 0.1;
    if ( (voltage <= hival) & (voltage >= loval) ) {
      return deg[a];
    }
  }
}
//####################################################
//returns inches
float get_rain() {
  return (rain_cnt * per_tip) / 2 ;
}
//####################################################
void make_json() {
  StaticJsonBuffer<300> jsonBuffer;
  JsonObject& root = jsonBuffer.createObject();
  root["wv"] = rpt_velocity();
  root["wd"] = get_dir();
  root["tF"] = rpt_temp();
  root["ov"] = getBandgap() / 100.00;
  root["lux"] = get_lux0();
  root["bbl"] = get_bb_light();
  root["irl"] = get_ir_light();
  //if (rain_cnt > 0) {
  root["ra"] = get_rain();
  root["rr"] = rpt_rain_rate();
  //}
  root.printTo(Serial);
  Serial.println();  
  rain_cnt = 0;
  vel = 0;  
}
//###################################################
// returns inches per second
float rpt_rain_rate() {
  float rate = ( (get_rain() ) / rpt_sec );
  return rate;
}
//####################################################
/* On Pin 5, uses OneWire protocol */
float rpt_temp() {
  sensors.requestTemperatures();
  float tempC = sensors.getTempC(thermometer);
  float tmp =  DallasTemperature::toFahrenheit(tempC);
  return tmp;
}
//############################################
// we get 3 interupt counts per round - returns intantaneous mph
// The above assumption is incorrect. The pertinent relationship
// is expressed as switch closes each second. Each swclose/sec is
// equal to 1.492 mpg. So the number of switch closes/revolution
// does not matter. Modified the following to reflect this. Note
// that the rpt_sec variable impacts resolution of measurements!
float rpt_velocity() {
  float cur_vel = ( (vel * 1.492) / rpt_sec );
  return cur_vel;
}
//############################################
//######## interupt driven functions #########
//############################################
/* On Pin 9 set as an interupt */
void velocity() {
  vel++;
}
//############################################
/* On Pin 10 set as an interupt */
void rain() {
  rain_cnt++;
}
//############################################


// Function created to obtain chip's actual Vcc voltage value, using internal bandgap reference
// This demonstrates ability to read processors Vcc voltage and the ability to maintain A/D calibration with changing Vcc
// Now works for 168/328 and mega boards.
// Thanks to "Coding Badly" for direct register control for A/D mux
// 1/9/10 "retrolefty"

int getBandgap(void)  {    // Returns actual value of Vcc (x 100) {
  #if defined(__AVR_ATmega1280__) || defined(__AVR_ATmega2560__)
     // For mega boards
     const long InternalReferenceVoltage = 1115L;  // Adjust this value to your boards specific internal BG voltage x1000
     ADMUX = (0<<REFS1) | (1<<REFS0) | (0<<ADLAR)| (0<<MUX5) | (1<<MUX4) | (1<<MUX3) | (1<<MUX2) | (1<<MUX1) | (0<<MUX0);
  #else
     // For 168/328 boards
     const long InternalReferenceVoltage = 1056L;  // Adjust this value to your boards specific internal BG voltage x1000
     ADMUX = (0<<REFS1) | (1<<REFS0) | (0<<ADLAR) | (1<<MUX3) | (1<<MUX2) | (1<<MUX1) | (0<<MUX0);
  #endif
     delay(50);  // Let mux settle a little to get a more stable A/D conversion
        // Start a conversion  
     ADCSRA |= _BV( ADSC );
        // Wait for it to complete
     while( ( (ADCSRA & (1<<ADSC)) != 0 ) );
        // Scale the value
     int results = (((InternalReferenceVoltage * 1024L) / ADC) + 5L) / 10L; // calculates for straight line value
     return results;
}

/**************************************************************************/
void configureSensor(void) {
  /* You can also manually set the gain or enable auto-gain support */
  // tsl0.setGain(TSL2561_GAIN_1X);      /* No gain ... use in bright light to avoid sensor saturation */
  // tsl0.setGain(TSL2561_GAIN_16X);     /* 16x gain ... use in low light to boost sensitivity */
  tsl0.enableAutoRange(true); 
  /* Changing the integration time gives you better sensor resolution (402ms = 16-bit data) */
  //tsl0.setIntegrationTime(TSL2561_INTEGRATIONTIME_13MS);      /* fast but low resolution */
  //tsl0.setIntegrationTime(TSL2561_INTEGRATIONTIME_101MS);  /* medium resolution and speed   */
  tsl0.setIntegrationTime(TSL2561_INTEGRATIONTIME_402MS);  /* 16-bit data but slowest conversions */
  /* Update these values depending on what you've set above! */
  if (debugger == true) {
  Serial.println("------------------------------------");
  Serial.print  ("Gain:         "); Serial.println("Auto");
  Serial.print  ("Timing:       "); Serial.println("402 ms");
  Serial.println("------------------------------------");
  }
}
//#################################################################################
float get_lux0() {
   sensors_event_t event;
   tsl0.getEvent(&event);
  /* Display the results (light is measured in lux) */
  if (event.light)
  {
//    Serial.print(event.light); Serial.print(" lux S1   ");
    return event.light;
  }
  else
  {
    /* If event.light = 0 lux the sensor is probably saturated
       and no reliable data could be generated! */
    if (debugger == true) {
      Serial.println("Sensor overload");
    }
  }
}
//#####################################################################
float get_bb_light() { 
  tsl0.getLuminosity(&broadband, &infrared); //return broadband light level
  return broadband;
}
//#####################################################################
float get_ir_light() { //return infra-red light level
  tsl0.getLuminosity(&broadband, &infrared);
  return infrared;
}

//#####################################################################

void get_i2c() {
  byte error, address;
  int nDevices;

  Serial.println("Scanning...");

  nDevices = 0;
  for(address = 1; address < 127; address++ ) 
  {
    Serial.print("Address "); Serial.println(address);
    // The i2c_scanner uses the return value of
    // the Write.endTransmisstion to see if
    // a device did acknowledge to the address.
    Wire.beginTransmission(address);
    error = Wire.endTransmission();

    if (error == 0)
    {
      Serial.print("I2C device found at address 0x");
      if (address<16) 
        Serial.print("0");
      Serial.print(address,HEX);
      Serial.println("  !");

      nDevices++;
    }
    else if (error==4) 
    {
      Serial.print("Unknow error at address 0x");
      if (address<16) 
        Serial.print("0");
      Serial.println(address,HEX);
    }    
  }
}
//############################################################################3
void displaySensorDetails(void) {
  sensor_t sensor;
  tsl0.getSensor(&sensor);
  Serial.println("------------------------------------");
  Serial.print  ("Sensor:       "); Serial.println(sensor.name);
  Serial.print  ("Driver Ver:   "); Serial.println(sensor.version);
  Serial.print  ("Unique ID:    "); Serial.println(sensor.sensor_id);
  Serial.print  ("Max Value:    "); Serial.print(sensor.max_value); Serial.println(" lux");
  Serial.print  ("Min Value:    "); Serial.print(sensor.min_value); Serial.println(" lux");
  Serial.print  ("Resolution:   "); Serial.print(sensor.resolution); Serial.println(" lux");  
  Serial.println("------------------------------------");
  Serial.println("");
}
