#ifndef _BMC81M001_H__
#define _BMC81M001_H__

//*********************************************//
//****************** Header *******************//
//*********************************************//
#include "ThingSpeakPublish.h"
#include "BMC81M001.h"

//*********************************************//
//*********** wifi information ****************//
//*********************************************//

#define WIFI_SSID "iPhone11"
#define WIFI_PASS "0975672791"

/*#define CLIENTLID  "Jw8YCBY4Bx8NDiUmACYIGy8"  
#define USERNAME  "Jw8YCBY4Bx8NDiUmACYIGy8"                            
#define PASSWORD  "UmiDfeoRbVkceoY4RHDxVcBj"                   
#define MQTT_HOST "mqtt3.thingspeak.com"             
#define SERVER_PORT 1883*/
#define CLIENTLID  "FggzBDwDAgstBToyBhYoFhE"  
#define USERNAME  "FggzBDwDAgstBToyBhYoFhE"                            
#define PASSWORD  "pcSHVp2bZatnzq4TONNvAgR1"                   
#define MQTT_HOST "mqtt3.thingspeak.com"             
#define SERVER_PORT 1883

//#define PUBLISHTOPIC1 "GAS"  
//#define PUBLISHTOPIC2 "SMOKE"
//#define PUBLISHTOPIC3 "DUST"

#define PUBLISHTOPIC "channels/2730783/publish"                                
#define SUBSCRIBERTOPIC1 "channels/2730783/subscribe" 
#define SUBSCRIBERTOPIC2 "channels/2730783/subscribe/fields/field1" 
#define CUSTOMTOPIC ""  //Custom Topic

//*********************************************//
//************* IO_Port Define ***************//
//*********************************************//
int LED = 13;                         // LED port
//*********************************************//
//************* Variable Define ***************//
//*********************************************//
#define DEB_CNT     80                //50ms
#define RES_MAX_LENGTH 200            //max buffer length

char  OledBuff[RES_MAX_LENGTH];   //serial buffer
char  data[30];                       //key data buffer
int   resLen;                         //serial buffer use length
String ReciveBuff;
int ReciveBufflen;

String DATA_BUF ;                     //
String topic ;                        //MQTT_Topic

#endif
