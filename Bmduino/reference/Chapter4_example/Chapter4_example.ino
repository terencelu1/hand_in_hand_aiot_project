/*****************************************************************
File:        Chapter4_example.ino
******************************************************************/
#include "ThingSpeakPublish.h"
#include <BME63M001.h>
#include "BME34M101.h"
#include <BM25S2021-1.h>

BMC81M001   Wifi(&Serial1);  
BME63M001 myTDS(6,7);
BME34M101 mySoilMoistureSensor(5,4);
BM25S2021_1 BMht(&Wire);

float Sensor_Data;
String Humidity;
String Temperature;
uint8_t channel=1;/*TDS chanel*/
String TDSValue ;
String MoistureValue ;

//初始化元件
void setup() 
{ 
  Serial.begin(9600); 
  myTDS.begin();
  mySoilMoistureSensor.begin();
  BMht.begin();                                
  Wifi.begin();
  Wifi.reset(); 
  Serial.print("WIFI Connection Results：");
  if(Wifi.connectToAP(WIFI_SSID,WIFI_PASS)==0) 
  {
    Serial.println("fail");
  } 
  else {Serial.println("success");}
  Serial.print("ThingSpeak Connection Results：");
  if(Wifi.configMqtt(CLIENTLID,USERNAME,PASSWORD,MQTT_HOST,SERVER_PORT)==0)
  {
    Serial.println("fail");
  }
  else {Serial.println("success");}
  delay(200);
  Wifi.setPublishTopic(PUBLISHTOPIC);
  Wifi.setSubscribetopic(SUBSCRIBERTOPIC2);
  Wifi.setSubscribetopic(SUBSCRIBERTOPIC1);
  topic = PUBLISHTOPIC;
}

//輪詢取得感測器數值
void loop() 
{ 
  get_Humidity();
  get_Temperature();
  get_TDSValue();
  get_Moisture();
}  

//取得濕度數值，將數值列印於序列埠並上傳至thingspeak平台
void get_Humidity()
{
  //取得濕度數值
  Sensor_Data=BMht.readHumidity();
  Humidity=String(Sensor_Data,2);
  //將濕度數值列印於序列埠
  Serial.print("Humidity:");
  Serial.print(Humidity);
  Serial.println(" %");
  //將濕度數值上傳至thingspeak平台
  DATA_BUF = "field1="; 
  DATA_BUF += Humidity; 
  if(Wifi.writeString(DATA_BUF,topic)){
    Serial.println("Send String data sucess");
    delay(1000);
  }
}

//取得溫度數值，將數值列印於序列埠並上傳至thingspeak平台
void get_Temperature()
{
  //取得溫度數值
  Sensor_Data=BMht.readTemperature(false);
  Temperature=String(Sensor_Data,2);
  //將溫度數值列印於序列埠
  Serial.print("Temperature:");
  Serial.print(Temperature);
  Serial.println(" °C");
  //將溫度數值上傳至thingspeak平台
  DATA_BUF = "field2="; 
  DATA_BUF += Temperature; 
  if(Wifi.writeString(DATA_BUF,topic)){
    Serial.println("Send String data sucess");
    delay(1000);
  }
}

//取得水質TDS數值，將數值列印於序列埠並上傳至thingspeak平台
//僅取用Channel1的數值
void get_TDSValue()
{
  //取得水質TDS數值
  Sensor_Data=myTDS.readTDS(channel); 
  TDSValue=String(Sensor_Data,2);
  //將水質TDS數值列印於序列埠
  Serial.print("TDSValue:");
  Serial.print(TDSValue);
  Serial.println(" ppm");
  //將水質TDS數值上傳至thingspeak平台
  DATA_BUF = "field3="; 
  DATA_BUF += TDSValue; 
  if(Wifi.writeString(DATA_BUF,topic)){
    Serial.println("Send String data sucess");
    delay(1000);
  }
}

//取得土壤濕度數值，將數值列印於序列埠並上傳至thingspeak平台
void get_Moisture()
{
  //取得土壤濕度數值
  Sensor_Data=mySoilMoistureSensor.getMoisture(); 
  MoistureValue=String(Sensor_Data,2);
  //將土壤濕度數值列印於序列埠
  Serial.print("MoistureValue:");
  Serial.println(MoistureValue);
  //將土壤濕度數值上傳至thingspeak平台
  DATA_BUF = "field4="; 
  DATA_BUF += MoistureValue; 
  if(Wifi.writeString(DATA_BUF,topic)){
    Serial.println("Send String data sucess");
    delay(1000);
  }
}
