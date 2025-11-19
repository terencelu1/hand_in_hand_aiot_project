#include "ThingSpeakPublish.h"
#include <BMS33M332.h> 

BMC81M001   Wifi(&Serial1);  
BMS33M332 Alsps(8); // 使用 pin 8 作為中斷腳位
float AD;          // 儲存原始接近數據的變數
String AD1,AD_ALS;        // 將數值轉換為字符串以便發佈的變數
int num = 0;       

void setup(){ 
  Serial.begin(9600); // 鮑率設9600
  Alsps.begin();      // 初始化近接環境光感測器
  //Alsps.setINT(400,200);  //設定上閾值及下閾值
  Wifi.begin();       // 初始化 WiFi 模組
  Wifi.reset();       // 重置 WiFi 模組
  
  Serial.print("WIFI 連接結果：");
  if(Wifi.connectToAP(WIFI_SSID, WIFI_PASS) == 0){
    Serial.println("失敗"); 
  } 
  else{
    Serial.println("成功"); 
  }

  Serial.print("ThingSpeak 連接結果：");
  // 配置 MQTT 參數以連接到 ThingSpeak
  if(Wifi.configMqtt(CLIENTLID, USERNAME, PASSWORD, MQTT_HOST, SERVER_PORT) == 0){
    Serial.println("失敗"); 
  }
  else{
    Serial.println("成功"); 
  }
  delay(200); 
  
  // 設置 MQTT 主題進行發佈和訂閱
  Wifi.setPublishTopic(PUBLISHTOPIC);
  Wifi.setSubscribetopic(SUBSCRIBERTOPIC2);
  Wifi.setSubscribetopic(SUBSCRIBERTOPIC1);
  topic = PUBLISHTOPIC; // 設置發佈的主題
}
void loop(){   
    AD = Alsps.readRawProximity(); // 從感測器讀取數據
    Serial.print("接近感應的 A/D 值: ");
    Serial.print(AD); 
    Serial.println();
    delay(1000);
    // 如果 AD 在 200 和 400 之間，則 num 設置為 1，否則設置為 0
    num = (AD > 200 && AD < 400) ? 1 : 0; 
    AD1 = String(num); 

    DATA_BUF = "field1="; 
    DATA_BUF += AD1;
    // 如果 WiFi 寫入操作成功，則發送數據到 ThingSpeak
    bool datasent = Wifi.writeString(DATA_BUF, topic);
    
    if(datasent && num == 1 ){
        Serial.println("Send String data sucess"); // 表示數據發送成功
        delay(500); 
        Serial.println("發現物體！"); // 通知檢測到物體
        delay(1000); 
        int alsValue = Alsps.readRawAmbient();
        Serial.print("   Data_ALS : ");
        Serial.print(alsValue); 
        Serial.println();  
        delay(1000);
        AD_ALS = String(alsValue);
        DATA_BUF = "field2=";
        DATA_BUF += AD_ALS;
        if(Wifi.writeString(DATA_BUF,topic)){
           Serial.println("Send String data sucess");
           delay(1000);
        }
        if(alsValue >= 0 && alsValue < 300){
          Serial.println("光線過暗");
        }
        else if(alsValue >= 300 && alsValue < 700){
          Serial.println("光線正常");
        }
        else if(alsValue >= 700 && alsValue < 1023){
          Serial.println("光線充足");
        }
    } 
    else if(datasent && num != 1){ 
        Serial.println("數據發送成功"); // 表示數據發送成功
        delay(500); 
        Serial.println("未發現物體 ):"); // 通知未檢測到物體
        delay(1000); 
    }
    clearBuff(); // 清除緩衝區
    delay(2000); 
}

void clearBuff(){
  memset(OledBuff, '\0', RES_MAX_LENGTH); // 清空緩衝區
  resLen = 0; // 重置緩衝區長度
}
