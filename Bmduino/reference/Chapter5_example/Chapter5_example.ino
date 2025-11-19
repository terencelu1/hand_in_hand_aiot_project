#include <Event.h>
#include <Timer.h>

/*****************************************************************
File:        Chapter5_example.ino
******************************************************************/
#include <SoftwareSerial.h>

#include <BM22S3021-1.h>
#include "BM22S2021-1.h" 
#include <BM25S3221-1.h>
#include <BM25S2021-1.h>

#include "ThingSpeakPublish.h"
#include "voice_cmd_list.h"
#include "Timer.h"                     //http://github.com/JChristensen/Timer

#define SMOKE_STATUS 6
#define GAS_STATUS 29
#define DUST_STATUS 22

#define PM1_0 dustValue[0]
#define PM2_5 dustValue[1]
#define PM10 dustValue[2]

Timer t;    //建立計時器物件
Timer t1;    //建立計時器物件

uint8_t dataBuf[32] = {0};
uint16_t dustValue[3] = {0};

uint16_t smokeA,smokeB;
uint8_t Smoke_Data[41];

uint8_t ADValue,gasAlarmPoint;
uint8_t Gas_moduleInfo[18] = {0};
uint8_t MQTT_count=1;
BMC81M001   Wifi(15,14);
BM22S2021_1 SMOKE(SMOKE_STATUS,17,16);
BM22S3021_1 gas(GAS_STATUS, &Serial3); // Hardware serial, 22->STATUS
BM25S3221_1 dust(DUST_STATUS, &Serial1); // Hardware serial: BMC81M001

void setup() { 
  Serial.begin(9600);
  SMOKE.begin(); //Module initialization, baud rate 9600
  gas.begin(); //Module initialization, baud rate 9600
  dust.begin();       // Initialize module, baud rate: 9600bps

  
  pinMode(SMOKE_STATUS,INPUT);
  pinMode(GAS_STATUS,INPUT);
  Wifi.begin();
  Wifi.reset(); 
  Serial.print("WIFI Connection Results：");
  if(Wifi.connectToAP(WIFI_SSID,WIFI_PASS)==0) {
    Serial.println("fail");
  } 
  else {Serial.println("success");}
  Serial.print("ThingSpeak Connection Results：");
  if(Wifi.configMqtt(CLIENTLID,USERNAME,PASSWORD,MQTT_HOST,SERVER_PORT)==0){
    Serial.println("fail");
  }
  else {Serial.println("success");}
  delay(200);


  // 設置 MQTT 主題進行發佈和訂閱
  Wifi.setPublishTopic(PUBLISHTOPIC);
  Wifi.setSubscribetopic(SUBSCRIBERTOPIC2);
  Wifi.setSubscribetopic(SUBSCRIBERTOPIC1);
  topic = PUBLISHTOPIC; // 設置發佈的主題
  
  Serial.println("GAS module preheat...(about 3 mins)");
  gas.preheatCountdown(); // Wait for the module to warm up
  Serial.println("DUST module preheat...(about 3 mins)");
  dust.preheatCountdown(); // Wait for the End of module preheating.
  Serial.println("End of module preheat.");
  Serial.println();
  
  gas.writeCommand(0xe0, 0x12, 0x56);
  delay(500);
  int Event1 = t.every(3000,MQTTGO);//設定固定時間，呼叫函示
}

void loop() {
  t.update();//在loop裡面會檢查更新計時器;
}

//取得感測器數值
void getDATA(){
  Serial.println("get data");

  if (gas.isInfoAvailable() == 1) // 輪詢是否接收到燃氣模組發出的數據
    gas.readInfoPackage(Gas_moduleInfo);// 讀取模組發送的數據到Gas_moduleInfo[]
    
  if(SMOKE.isInfoAvailable()==1)// 輪詢是否接收到煙霧模組發出的數據
    SMOKE.readInfoPackage(Smoke_Data);// 讀取模組發送的數據到Smoke_Data
  
  if (dust.isInfoAvailable() == 1){// 輪詢是否接收到粉塵模組發出的數據
    dust.readInfoPacket(dataBuf);// 讀取模組發送的數據到dataBuf
    //PM1_0 = ((uint16_t)dataBuf[10] << 8) + dataBuf[11];
    PM2_5 = ((uint16_t)dataBuf[12] << 8) + dataBuf[13];
    //PM10 = ((uint16_t)dataBuf[14] << 8) + dataBuf[15];
  }  else{
    Serial.println("dust read failed!");
  }
}

//將感測數值輸出至序列埠監控視窗
void printInfo()
{
  Serial.println("printInfo");
  
  /*Print Smoke detection value of channel A*/
  smokeA=(Smoke_Data[17]<<8 | Smoke_Data[16]);
  Serial.print("The current smoke detection value of channel A is "); 
  Serial.println(smokeA,DEC);

  /* 列印當前燃氣 A/D 值 (8-bit)*/
  Serial.print("Gas A/D Value ");
  ADValue = (Gas_moduleInfo[6]);
  Serial.println(ADValue);
  
  /* 列印當前粉塵濃度*/
  Serial.print("PM2.5: ");
  Serial.print(PM2_5);
  Serial.println(" μg/m³");
}

void MQTTGO() { 
  getDATA();
  printInfo();
  switch(MQTT_count) {
    case 1:
      //topic="GAS";
      DATA_BUF = "field1=";
      DATA_BUF += String(ADValue);  
      if(Wifi.writeString(DATA_BUF,topic)){
        Serial.println("Send String data sucess");
        delay(1000);
      }
      clearBuff();
      MQTT_count = 2;
      break;
    case 2:
      //topic="SMOKE";
      DATA_BUF = "field2=";
      DATA_BUF += String(smokeA, DEC);  
      if(Wifi.writeString(DATA_BUF,topic)){
        Serial.println("Send String data sucess");
        delay(1000);
      }
      clearBuff();
      MQTT_count = 3;
      break;
    case 3:
      //topic="DUST";
      DATA_BUF = "field3=";
      DATA_BUF += String(PM2_5);  
      if(Wifi.writeString(DATA_BUF,topic)){
        Serial.println("Send String data sucess");
        delay(1000);
      }
      clearBuff();
      MQTT_count = 1;
      break;
  }
}  

void clearBuff(){
  memset(OledBuff,'\0',RES_MAX_LENGTH);
  resLen = 0;
}
