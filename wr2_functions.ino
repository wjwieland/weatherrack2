int get_dir() {
  float loval, hival;
  float voltage = (3.0 / 1023) * analogRead(pinDir);
  for (int a = 0; a < 16; a++) {
    loval = (volts[a]) - 0.10; 
    hival = (volts[a]) + 0.10;
    if ( (voltage <= hival) & (voltage >= loval) ) {
      return deg[a];
    }
  }
}
//####################################################
float get_rain() {
  return rain_cnt * 0.011;
}
//####################################################
float get_rain_last_mn() {
  
}
//####################################################
bool make_json() {
  StaticJsonBuffer<200> jsonBuffer;
  JsonObject& root = jsonBuffer.createObject();
  root["w_speed"] = get_speed(sec);
  root["w_dir"] = get_dir();
  root["rain"] = rain_cnt;
  root["temp"] = get_temp();
  root.printTo(Serial);
}
//####################################################
float get_temp() {
  sensors.requestTemperatures();
  float tempC = sensors.getTempC(thermometer);
  float tmp =  DallasTemperature::toFahrenheit(tempC);
  return tmp;
}
//############################################
float get_speed(float sec) {
  return (vel / sec) * 1.492;
}
//############################################
void velocity() {
  // increase value
  vel++;
}
//############################################
void rain() {
  rain_cnt++;
}
//############################################
