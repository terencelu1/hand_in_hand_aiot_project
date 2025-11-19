/*****************************************************************
File:        ThingSpeakPublish.ino
Description: Connect ThingSpeak through MQTT parameters and send data to the specified channel
******************************************************************/
#include "ThingSpeakPublish.h"
#include "BMS81M001.h"
#include "BMS26M833.h"

BMC81M001   Wifi(&Serial1);  //Please uncomment out this line of code if you use HW Serial1 on BMduino
BMS81M001 WakeOnShake(2,&Wire); // 建立對象
BMS26M833 Amg(3,&Wire); // 創建對象

uint8_t thr; // 用於保存顯示震動閾值
uint8_t dur; // 用於保存顯示震動持續時間
uint8_t halt_delay; // 用於保存顯示空閒延遲時間
float temp;
float TempMat[64];
uint8_t interruptTable[8];
uint32_t counter=0;
int count=0,cnt=0;
String AD1;

#define TEMP_INT_HIGH 30    //上限溫度
#define TEMP_INT_LOW 15   //最低溫度

void shock()
{
  if(WakeOnShake. getStatus () == 0)
  {
    if(WakeOnShake.getShakeStatus()) // 讀取震動狀態
    {
      counter++;   
    }
  }
}

void setup() 
{ 
  Serial.begin(9600); 
  
  WakeOnShake.begin(); // 模組初始化
  Serial.begin(9600); // 初始化序列埠     
                          
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

  Serial.begin(WakeOnShake.setShake(50,1));   //設定震動觸發條件

  /* 讀取震動設定並顯示 */
  if(!(WakeOnShake.getParameterSetting(thr,dur,halt_delay)))
  {
    Serial.print("Threshold=");
    Serial.print(thr);
    Serial.print("Duration=");
    Serial.print(dur);
    Serial.print("Delay=");
    Serial.println(halt_delay);
    Serial.println("Module is OK!");
  }
  else
  {
    Serial.println("Comunication fail!");
  }

  Amg.begin(); // 模組初始化  
  Amg.setInterruptLevels(TEMP_INT_HIGH, TEMP_INT_LOW);
  Amg.setINT(true);// 配置中斷使能
  Serial.println("======== BMS26M833 8*8 pixels Text ========");
}
void loop() 
{ 
  cnt+=1;
  shock();
  if(Amg.getINT() == 0)// 當 INT 腳為低準位時，說明有中斷發生
  {
    Amg.getINTTable(interruptTable);// 獲取中斷表
    temp = Amg.readThermistorTemp(); // 獲取環境溫度
    count=1;
    Amg.setStatusClear();// 清除中斷標誌位以便於接收下一次中斷
    delay(10);
    shock();
  }
  else
  {
    Amg.readPixels(TempMat); // 獲取 8×8 溫度矩陣
    //temp = Amg.readThermistorTemp(); // 獲取環境溫度
    count=0;
  } 
  Serial.println("Motion detected! "+(String)counter);// 震動發生

   shock();
    
    if(Wifi.writeString(DATA_BUF,topic) && count==1 && counter>0){
      
      AD1=String(temp);
      DATA_BUF = "field1="; 
      DATA_BUF += AD1; 
      
      Serial.println("Send String data sucess");
      delay(10);
    }else{
      AD1=String(0);
      DATA_BUF = "field1="; 
      DATA_BUF += AD1;
    }
    clearBuff();
    delay(10);
    if(cnt==15)
    {
      counter=0;
      cnt=0;
    } 
}  
void clearBuff(){
  memset(OledBuff,'\0',RES_MAX_LENGTH);
  resLen = 0;
}
