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
//  root["vel_cnt"] = vel;
//  root["rain_cnt"] = rain_cnt;
//  root["w_dir_v"] = (analogRead(A0)) * (3.300 / 1024);
  root["wv"] = rpt_velocity();
  root["wd"] = get_dir();
  root["ra"] = get_rain();
  root["rr"] = rpt_rain_rate();
  root["tF"] = rpt_temp();
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
float rpt_velocity() {
  float cur_vel = ( ((vel / 3.000 ) * 1.492) / rpt_sec );
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
