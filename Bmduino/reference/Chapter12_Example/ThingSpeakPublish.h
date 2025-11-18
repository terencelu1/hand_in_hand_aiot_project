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

#define CLIENTLID  "DgQ9JQ0MJT0oIQkPFh4dEgg"  
#define USERNAME  "DgQ9JQ0MJT0oIQkPFh4dEgg"                            
#define PASSWORD  "JLPujUWngc4UYaSfOp0+Q/GS"                   
#define MQTT_HOST "mqtt3.thingspeak.com"             
#define SERVER_PORT 1883

#define PUBLISHTOPIC "channels/2604405/publish"                 
#define SUBSCRIBERTOPIC1 "channels/2604405/subscribe" 
#define SUBSCRIBERTOPIC2 "channels/2604405/subscribe/fields/field1" 
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
String DATA_BUF_1 ;
String topic ;                        //MQTT_Topic

#endif
