#include "sys/time.h"
#include "BLEDevice.h"
#include "BLEUtils.h"
#include "BLEServer.h"
#include "BLEBeacon.h"
#include "esp_sleep.h"

#include <dummy.h>

#include <Arduino.h>
// #include "BLEDevice.h"

#include <unordered_map>

#define CUSTOM_IDENTIFIER 0xA5  // Expected identifier byte

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "String"
#include <WifiClientSecure.h>
// #include <WifiClient.h>

WiFiClientSecure client;  // or WiFiClientSecure for HTTPS
// WiFiClient client;  // or WiFiClientSecure for HTTPS
HTTPClient http;

#define ssid "espspot"
#define pass "bvtx4675"
// #define ssid "SINGTEL-C6A8"
// #define pass "wkskgx37k7tW"
const char *serverName = "https://resiwash.marcussoh.com/api/v1/events/bulk";
// const char *serverName = "http://192.168.1.3:3000/api/v1/events/bulk";
// const char *registerName = "http://192.168.1.3:3000/api/v1/sensors/register";
const char *registerName = "https://resiwash.marcussoh.com/api/v1/sensors/register";

// const char *host = "192.168.1.6";
// int port = 3000;
// const char *path = "/api/v1/events/bulk";

#define BAUD 9600
#define RXD2 16
#define TXD2 17
#define TXD1 18
#define RXD1 19

#define START_BYTE 251
#define END_BYTE 252

// BLEScan *pBLEScan;

struct MachineData {
  uint8_t active;
  uint8_t type;
  uint8_t reserved;
  uint8_t state;
};

int previousId = 0;  // TODO: convert to map

// <serialId (0 to 255) : actualId (0 to ???)>
std::unordered_map<int, int> serial1Map;
std::unordered_map<int, int> serial2Map;

struct Message {
  uint8_t id;
  bool state;
  uint8_t strategy;
  uint8_t reading1;
  uint8_t thres1;
  uint8_t reading2;
  uint8_t thres2;
};

// TODO: queuing system???
String jsonPost;
bool hasData = false;



struct MachineInfo {
  uint8_t id;
  bool state;
  uint8_t reading;
};

// Initialize the two serial inputs
HardwareSerial mySerial1(1);
HardwareSerial mySerial2(2);
void setup() {

  serial2Map[0] = 2;
  serial2Map[1] = 3;
  serial2Map[2] = 4;
  serial2Map[3] = 5;
  serial2Map[4] = 6;

  Serial.begin(115200);

  Serial.println("Connecting to wifi...");
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, pass);
  Serial.print("Connecting to WiFi ..");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print('.');
    delay(1000);
  }

  Serial.println(WiFi.localIP());

  mySerial2.begin(BAUD, SERIAL_8N1, RXD2, TXD2);
  mySerial1.begin(BAUD, SERIAL_8N1, RXD1, TXD1);

  Serial.println("ESP32 BLE Scanner - Repeated Scanning");

  // BLEDevice::init("ESP32_BLE_Scanner");

  // pBLEScan = BLEDevice::getScan();
  // pBLEScan->setAdvertisedDeviceCallbacks(new MyAdvertisedDeviceCallbacks());
  // pBLEScan->setInterval(100);
  // pBLEScan->setWindow(99);
  // pBLEScan->setActiveScan(true);

  while (mySerial1.available() > 0) {
    mySerial1.read();
  }

  while (mySerial2.available() > 0) {
    mySerial2.read();
  }

  // get mac address
  String wifiMacString = WiFi.macAddress();

  // post request to /sensors/register
  client.setInsecure();
  Serial.printf("Sending post request to %s\n", registerName);
  http.begin(client, registerName);
  http.addHeader("Content-Type", "application/json");
  String jsonPayload = "{\"macAddress\":\"" + wifiMacString + "\"}";

  int httpResponseCode = http.POST(jsonPayload);
  // Read response
  Serial.println(httpResponseCode);
  Serial.print(http.getString());
  Serial.println("End post request");
  // Disconnect
  http.end();
}


Message serial1Messages[255];
int serial1Count = 0;
int serial1Buffer[1024];
int serial2Buffer[1024];
Message serial2Messages[255];
int serial2Count = 0;

bool isCurrentlyReading = false;

void loop() {
  delay(100);
  Serial.print(".");

  if (mySerial2.available()) {
    Serial.println("");
    Serial.println("--- Available message in Serial 2 ---");


    bool isStarted = false;
    bool isReading = true;
    int bytesRead = 0;

    while (mySerial2.available() || isReading) {
      while (!mySerial2.available()) {
        // Need this in case we haven't received the end byte yet!
      }

      uint8_t byteFromSerial = mySerial2.read();

      serial1Buffer[bytesRead] = byteFromSerial;


      bytesRead = bytesRead + 1;
      Serial.printf("%d ", byteFromSerial);
      if ((bytesRead - 1) % sizeof(Message) == 0) {
        Serial.printf("\n");
      }

      if (isReading && byteFromSerial == START_BYTE) {
        // restart from the start, for some reason we had a fail
        isStarted = true;
        bytesRead = 1;

        // Serial.printf("[serial2]received start byte, disregarding previous items");
        continue;
      }

      if (isReading && byteFromSerial == END_BYTE) {
        isStarted = false;

        // clear out buffer
        while (mySerial2.available()) {
          mySerial2.read();
        }

        // sanity check to see if the number of bytes received makes sense
        int messageBytes = bytesRead - 2;
        int remainder = messageBytes % sizeof(Message);

        if (remainder != 0) {
          // some error in reading the length
          Serial.printf("[error][serial2] bytesRead=%d, sizeof message=%d, remainder=%d", bytesRead, sizeof(Message), remainder);
          break;  // exit this inner loop
        }

        // TODO: do some post requests here
        int messageCount = messageBytes / sizeof(Message);
        Serial.printf("\n[serial2] Read %d messages\n", messageCount);

        break;  // exit this inner loop
      }

      // if not start and end byte,
      if (!isStarted) {
        // something went wrong, ignore this
        Serial.println("[error][serial2] first byte received was not start byte");
        bytesRead = 0;
        serial2Count = 0;

        // clear the buffer
         while (mySerial2.available()) {
          mySerial2.read();
        }
        break;  // exit this inner loop
      }

      // read the bytes
      // do some logic here
    }

    if (bytesRead > 0) {
      // buffer[0] is start bit
      // buffer[bytesRead-1] is end bit


      // first validate that there are integer division
      // validated earlier

      String jsonPost;
      JsonDocument doc;
      JsonArray machineArray = doc["data"].to<JsonArray>();
      doc["macAddress"] = WiFi.macAddress();
      for (int i = 0; i < bytesRead - 1; i += sizeof(Message)) {
        uint8_t id = serial1Buffer[1 + i + 0];
        uint8_t state = serial1Buffer[1 + i + 1];
        uint8_t strategy = serial1Buffer[1 + i + 2];
        uint8_t reading1 = serial1Buffer[1 + i + 3];
        uint8_t thres1 = serial1Buffer[1 + i + 4];
        uint8_t reading2 = serial1Buffer[1 + i + 5];
        uint8_t thres2 = serial1Buffer[1 + i + 6];


        JsonObject machineObj = machineArray.add<JsonObject>();
        machineObj["localId"] = id;
        machineObj["state"] = state;
        machineObj["strategy"] = strategy;
        machineObj["source"] = "serial2";


        JsonArray readingsArray = machineObj["readings"].to<JsonArray>();

        JsonObject data_0_readings_0 = readingsArray.add<JsonObject>();
        data_0_readings_0["value"] = reading1;
        data_0_readings_0["threshold"] = thres1;

        JsonObject data_0_readings_1 = readingsArray.add<JsonObject>();
        data_0_readings_1["value"] = reading2;
        data_0_readings_1["threshold"] = thres2;



        Message m = { id, state, strategy, reading1, thres1, reading2, thres2 };

        // save to the serial Map
        serial2Messages[serial2Count] = m;
      }

      // POST request
      serializeJson(doc, jsonPost);

      Serial.println("Sending post request...");
      // client.setInsecure();
      Serial.printf("Sending post request to %s\n", serverName);
      http.begin(client, serverName);
      http.addHeader("Content-Type", "application/json");
      int httpResponseCode = http.POST(jsonPost);
      // Read response
      Serial.println(httpResponseCode);
      Serial.print(http.getString());
      Serial.println("End post request");
      // Disconnect
      http.end();

      // upload
    }
  }
}

// if serial1




// void loop3() {
//   delay(10);

//   Serial.print(".");


//   if (mySerial2.available()) {

//     Serial.println("---");

//     MachineInfo currentMessage;
//     int counter = 0;
//     while (mySerial2.available() || isCurrentlyReading) {
//       while (!mySerial2.available()) {}  // busy waiting until something becomes available

//       uint8_t byteFromSerial = mySerial2.read();

//       Serial.printf("[serial2] Read %d\n", byteFromSerial);

//       // 255 signals start and end
//       if (!isCurrentlyReading && byteFromSerial != START_BYTE) {
//         // Ignore
//         continue;
//       }
//       if (!isCurrentlyReading && byteFromSerial == START_BYTE) {
//         isCurrentlyReading = true;
//         continue;
//       }

//       // end
//       if (isCurrentlyReading && byteFromSerial == END_BYTE) {
//         isCurrentlyReading = false;

//         // do some logic here to reset
//         // clear the buffer
//         while (mySerial2.available()) {
//           mySerial2.read();
//         }

//         break;
//       }

//       // when in this section, we are setting values
//       if (counter == 0) {
//         currentMessage.id = byteFromSerial;
//       }
//       if (counter == 1) {
//         currentMessage.state = byteFromSerial;
//       }

//       if (counter == 2) {
//         currentMessage.reading = byteFromSerial;
//         counter = 0;

//         messages[messageLength] = currentMessage;
//         messageLength++;
//         currentMessage = { 0, 0, 0 };
//         continue;
//       }

//       counter++;
//     }

//     Serial.printf("[serial2] Read %d messages\n", messageLength);

//     // String line = mySerial2.readStringUntil('\n');

//     // Serial.printf("[serial2] %s\n", line);
//   }

//   if (messageLength > 0) {
//     // blah

//     messageLength = 0;
//   }
//   // while (mySerial2.available() > 0) {
//   //   // uint8_t byteFromSerial = mySerial2.read();
//   //   // Serial.printf("byteFromSerial=%d\n", byteFromSerial);
//   // }
// }
// void loop2() {
//   // Serial.println("Scanning...");

//   // pBLEScan->start(1, false);  // Scan for 1 second
//   // pBLEScan->clearResults();   // Free memory from previous scans

//   delay(1000);  // Wait 1 second before restarting the scan
//   Serial.println("[info] looping...");
//   Message *messageList;
//   int count = 0;
//   // if (mySerial1.available()) {
//   //   Serial.println("[info] Serial1 available");
//   //   while (mySerial1.available()) {
//   //     Message incoming;
//   //     Serial1.readBytes((char *)&incoming, sizeof(incoming));
//   //     // add incoming to messageList
//   //     Serial.printf("[serial1] Read %d %d %d", incoming.id, incoming.state, incoming.reading);
//   //     // if id not in map, skip
//   //     if (serial1Map.find(incoming.id) == serial1Map.end()) {
//   //       Serial.printf("[serial1] ID %d not found in map\n", incoming.id);
//   //       continue;
//   //     }

//   //     Serial.printf("[serial1] ID: %d, State: %d, Reading: %d\n", incoming.id, incoming.state, incoming.reading);
//   //     incoming.id = serial1Map[incoming.id];
//   //     messageList[count] = incoming;
//   //     count++;
//   //   }
//   // }

//   // if (mySerial2.available()) {
//   //   Serial.println("[info] Serial2 available");


//   //   while (mySerial2.available() >= sizeof(Message)) {
//   //     uint8_t raw[sizeof(Message)];
//   //     Serial2.readBytes((char *)raw, sizeof(raw));
//   //     Serial.print("Raw bytes: ");
//   //     for (int i = 0; i < sizeof(raw); i++) {
//   //       Serial.printf("%02X ", raw[i]);
//   //     }
//   //     Serial.println();

//   //     //   Message incoming;
//   //     //   Serial2.readBytes((char *)&incoming, sizeof(incoming));

//   //     //   Serial.printf("[serial2] Read %d %d %d\n", incoming.id, incoming.state, incoming.reading);
//   //     //   // add incoming to messageList

//   //     //   // if id not in map, skip
//   //     //   if (serial2Map.find(incoming.id) == serial2Map.end()) {
//   //     //     Serial.printf("[serial2] ID %d not found in map\n", incoming.id);
//   //     //     continue;
//   //     //   }

//   //     //   incoming.id = serial2Map[incoming.id];
//   //     //   Serial.printf("ID: %d, State: %d, Reading: %d\n", incoming.id, incoming.state, incoming.reading);
//   //     //   // messageList[count] = incoming;
//   //     //   count++;
//   //   }

//   //   // clear stupid bytes
//   //   while (mySerial2.available()) mySerial2.read();
//   // }

//   if (count > 0) {
//     return;
//     // send messageList to server
//     // convert messageList to json
//     JsonDocument doc;
//     JsonArray machineArray = doc["data"].to<JsonArray>();
//     for (int i = 0; i < count; i++) {
//       Message incoming = messageList[i];
//       JsonObject machineObj = machineArray.add<JsonObject>();
//       machineObj["machineId"] = incoming.id;
//       machineObj["statusCode"] = incoming.state;
//       machineObj["reading"] = incoming.reading;

//       Serial.printf("Got reading for %d %d %d", incoming.id, incoming.state, incoming.reading);
//     }

//     // POST request
//     serializeJson(doc, jsonPost);
//     hasData = true;

//     Serial.println("Sending post request...");

//     client.setInsecure();

//     Serial.printf("Sending post request to %s\n", serverName);
//     http.begin(client, serverName);

//     http.addHeader("Content-Type", "application/json");
//     int httpResponseCode = http.POST(jsonPost);

//     // Read response
//     Serial.println(httpResponseCode);
//     Serial.print(http.getString());

//     Serial.println("End post request");

//     // Disconnect
//     http.end();
//   } else {
//     Serial.println("No data to send");
//     // clear messageList
//     //
//   }

//   // if data
//   // send post request

//   // --- contents below this line are outdated ---

//   // if (hasData) {

//   //   // POST request
//   //   Serial.println("Sending post request...");

//   //   client.setInsecure();

//   //   Serial.printf("Sending post request to %s\n", serverName);
//   //   http.begin(client, serverName);

//   //   http.addHeader("Content-Type", "application/json");
//   //   int httpResponseCode = http.POST(jsonPost);

//   //   // Read response
//   //   Serial.println(httpResponseCode);
//   //   Serial.print(http.getString());

//   //   Serial.println("End post request");

//   //   // Disconnect
//   //   http.end();

//   //   hasData = false;
//   // }
// }
