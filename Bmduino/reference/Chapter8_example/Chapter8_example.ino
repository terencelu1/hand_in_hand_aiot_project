/*****************************************************************
File:        Chapter8_example.ino
******************************************************************/
#include "ThingSpeakPublish.h"
#include <BMD31M090.h>
#include <BMK52M134.h>
#include <BMH08002-4.h>
#include <BMH06203.h>

#define BMD31M090_WIDTH   128        // BMD31M090 Module display width, in pixels
#define BMD31M090_HEIGHT  64         // BMD31M090 Module display height, in pixels
#define BMD31M090_ADDRESS 0x3C       

BMC81M001 Wifi(5,4);  
BMD31M090 BMD31(BMD31M090_WIDTH, BMD31M090_HEIGHT, &Wire); 
BMK52M134 BMK52(3, &Wire); 
BMH08002_4 mySpo2(22,&Serial1);  
BMH06203 mytherm(&Wire); 

float data1;
uint8_t Key_Value=0;

uint8_t BMH08002_flag=0;
String SpO2_Value="";
String Heart_rate="";
String PI_Value="";
uint8_t rBuf[15]={0};
uint8_t Status=0;
uint8_t flag=0;

String Body_Temp;
String lastTemp;
int sameValueCount = 0;
uint8_t BMH06203_flag=0;

//初始化元件
void setup() 
{ 
  BMD31.begin(0x3C);
  BMD31.setFont(FontTable_8X16);
  delay(100);     
  mySpo2.begin();
  mySpo2.setModeConfig(0x02);//Query response mode, red light on when finger is detected
  delay(100); 
  mytherm.begin();
  Serial.begin(9600);                                
  Wifi.begin();
  Wifi.reset(); 
  BMK52.begin();
  Display();
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

//偵測按鍵中斷，呼叫key_fun()
void loop() 
{ 
  if (BMK52.getINT() == 0)
  {
    Key_Value=BMK52.getKeyValue();
    BMD31.clearDisplay();
    BMD31.display();
    key_fun();
  }
}  

//判斷按下之按鍵做出相應指令
void key_fun()
{
  switch(Key_Value)
  {
    //按鍵一: 讀取血氧、心率、PI值
    case 1:
      Get_SpO2_HeartRate_PI();
      BMH08002_flag=0;
      break;
    //按鍵二: 讀取人體溫度
    case 2:
      Get_BodyTemp();
      BMH06203_flag=0;
      break;
    //按鍵三或四: 跳回主選單
    default:
      Key_Value=0;
      Display();
      Serial.println("Main Menu"); 
      break;
  }
}

//讀取血氧、心率、PI值
void Get_SpO2_HeartRate_PI()
{
    
    Serial.println("Place finger"); 
    BMD31.drawString(25,0,(u8*)"Place finger");
    delay(2000);  //Wait for finger placement
    mySpo2.beginMeasure();
    while(BMH08002_flag==0)
    {
      Status= mySpo2.requestInfoPackage(rBuf);
      if (Status==0x02)
      {
        BMD31.clearDisplay();
        BMD31.display();
        Serial.println("Measurement completed,Can remove fingers"); 
        SpO2Value_Print();
        HeartRate_Print();
        PIValue_Print();
        mySpo2.endMeasure(); //stop Measure
        mySpo2.sleep();   //enter Halt
        BMD31.drawString(5,6,(u8*)"key3&4:Menu");
        BMH08002_flag=1;
      }
      if (Status==0x01&&flag!=1)
      {
          BMD31.clearDisplay();
          BMD31.display();
          Serial.println("DontMoveFinger");
          BMD31.drawString(5,2,(u8*)"Dont Move");
          BMD31.drawString(5,4,(u8*)"Finger");
          flag=1;
      }
      if (Status==0x00&&flag!=0)
      {
          BMD31.clearDisplay();
          BMD31.display();
          Serial.println("RepositionFinger");
          BMD31.drawString(5,2,(u8*)"Reposition");
          BMD31.drawString(5,4,(u8*)"Finger");
          flag=0;
      }
    }
    
}

//將血氧數值列印於OLED與序列埠並上傳至thingspeak平台
void SpO2Value_Print()
{
  SpO2_Value=String(rBuf[0],DEC);
  Serial.print("SpO2:"); 
  Serial.print(rBuf[0],DEC);
  Serial.println("%"); 
  SpO2_Value.toCharArray(OledBuff,7);
  BMD31.drawString(5,0,(u8*)"SpO2:");
  BMD31.drawString(50,0,(u8*)OledBuff);
  BMD31.drawString(85,0,(u8*)"%");
  DATA_BUF = "field1="; 
  DATA_BUF += SpO2_Value; 
  if(Wifi.writeString(DATA_BUF,topic)){
    Serial.println("Send String data sucess");
    delay(700);
  }
}

//將心率數值列印於OLED與序列埠並上傳至thingspeak平台
void HeartRate_Print()
{
  Heart_rate=String(rBuf[1],DEC);
  Serial.print("Heart rate:"); 
  Serial.print(rBuf[1],DEC);
  Serial.println("BMP"); 
  Heart_rate.toCharArray(OledBuff,7);
  BMD31.drawString(5,2,(u8*)"H_R :");
  BMD31.drawString(50,2,(u8*)OledBuff);
  BMD31.drawString(85,2,(u8*)"BMP");
  DATA_BUF = "field2="; 
  DATA_BUF += Heart_rate; 
  if(Wifi.writeString(DATA_BUF,topic)){
    Serial.println("Send String data sucess");
    delay(700);
  }
}

//將PI數值列印於OLED與序列埠並上傳至thingspeak平台
void PIValue_Print()
{
  PI_Value=String(rBuf[2],DEC);
  Serial.print("PI:"); 
  Serial.print((float)rBuf[2] / 10);
  Serial.println("%");
  PI_Value.toCharArray(OledBuff,7);
  BMD31.drawString(5,4,(u8*)"PI  :");
  BMD31.drawString(50,4,(u8*)OledBuff);
  BMD31.drawString(85,4,(u8*)"%");
  DATA_BUF = "field3="; 
  DATA_BUF += PI_Value; 
  if(Wifi.writeString(DATA_BUF,topic)){
    Serial.println("Send String data sucess");
    delay(700);
  }
}

//讀取人體溫度
void Get_BodyTemp()
{
  Serial.println("Put On Forehead"); 
  BMD31.drawString(5,0,(u8*)"Put On Forehead");
  delay(2000);  //Wait for finger placement
  while(BMH06203_flag==0)
  {
    Body_Temp = mytherm.readTemperature(BODY_TEMP);
    
    if (Body_Temp == lastTemp) {
      sameValueCount++;
    } 
    else {
      sameValueCount = 0;  
    }
    lastTemp = Body_Temp;
    if (sameValueCount >= 10) 
    {
      Serial.println("Measurement completed");
      BodyTemp_Print();
      mytherm.sleep();
      BMD31.drawString(5,6,(u8*)"key3&4:Menu");
      BMH06203_flag=1;
    }
    delay(50);
  }
}

//將人體溫度數值列印於OLED與序列埠並上傳至thingspeak平台
void BodyTemp_Print()
{
  Serial.print("Temp:"); 
  Serial.print(Body_Temp);
  Serial.println("°C");
  Body_Temp.toCharArray(OledBuff,7);
  BMD31.drawString(5,4,(u8*)"Temp:");
  BMD31.drawString(50,4,(u8*)OledBuff);
  BMD31.drawString(85,4,(u8*)"C");
  DATA_BUF = "field4="; 
  DATA_BUF += Body_Temp; 
  if(Wifi.writeString(DATA_BUF,topic)){
    Serial.println("Send String data sucess");
    delay(700);
  }
}

void clearBuff()
{
  memset(OledBuff,'\0',RES_MAX_LENGTH);
  resLen = 0;
}

//主選單
void Display()
{
  BMD31.drawString(35,0,(u8*)"Main menu");
  BMD31.drawString(5,4,(u8*)"key1:BMH83M002");
  BMD31.drawString(5,6,(u8*)"key2:BMH63K203");
}
