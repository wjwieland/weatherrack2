int get_dir() {
  float loval, hival;
  float voltage = (analogRead(A0)) * (3.300 / 1024);
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
  StaticJsonBuffer<200> jsonBuffer;
  JsonObject& root = jsonBuffer.createObject();
  root["wv"] = rpt_velocity();
  root["wd"] = get_dir();
  root["ra"] = get_rain();
  root["rr"] = rpt_rain_rate();
  root["tF"] = rpt_temp();
  root["ov"] = getBandgap();
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
