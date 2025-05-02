#include <dummy.h>

#include <Arduino.h>
#include "BLEDevice.h"

#include <unordered_map>

#define CUSTOM_IDENTIFIER 0xA5  // Expected identifier byte

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "String"
// #include <WifiClientSecure.h>
#include <WifiClient.h>

// WiFiClientSecure client;  // or WiFiClientSecure for HTTPS
WiFiClient client;  // or WiFiClientSecure for HTTPS
HTTPClient http;

// #define ssid "espspot"
// #define pass "1234567890"
#define ssid "SINGTEL-C6A8"
#define pass "wkskgx37k7tW"
// const char *serverName = "https://resiwash.marcussoh.com/api/rvrc/block_e/";
const char *serverName = "http://192.168.1.6:3000/api/v1/events/bulk";

const char *host = "192.168.1.6";
int port = 3000;
const char *path = "/api/v1/events/bulk";

int machineId = 1;


BLEScan *pBLEScan;

struct MachineData {
  uint8_t active;
  uint8_t type;
  uint8_t reserved;
  uint8_t state;
};

int previousId = 0;  // TODO: convert to map

void getMachineData(uint8_t data, uint8_t &active, uint8_t &type, uint8_t &reserved, uint8_t &state) {
  active = (data >> 7) & 0x01;          // MSB (Bit 7)
  type = (data >> 6) & 0x01;            // 2nd MSB (Bit 6)
  reserved = (data & 0b00111110) >> 1;  // 3rd MSB (Bit 5)
  state = data & 0x01;                  // Lower 5 bits (Bits 4-0)
}

// Function to print the struct using Serial.printf()
void printMachineData(const MachineData &data) {
  Serial.printf("Machine Data:\n");
  Serial.printf("  Active   : %s\n", data.active ? "true" : "false");
  Serial.printf("  Type     : %s\n", data.type ? "Dryer" : "Washer");
  Serial.printf("  Reserved : %d\n", data.reserved);
  Serial.printf("  State    : %d\n", data.state);
}

std::unordered_map<int, int> idMap;

// TODO: queuing system???
String jsonPost;
bool hasData = false;

class MyAdvertisedDeviceCallbacks : public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice advertisedDevice) override {
    if (advertisedDevice.haveManufacturerData()) {
      String manufacturerData = advertisedDevice.getManufacturerData();
      // Serial.println(manufacturerData);

      if (manufacturerData.length() >= 3) {  // Ensure at least 3 bytes (Company ID + Identifier)
        uint16_t companyID = (uint8_t)manufacturerData[0] | ((uint8_t)manufacturerData[1] << 8);
        uint8_t identifier = (uint8_t)manufacturerData[2];

        if (identifier == CUSTOM_IDENTIFIER) {  // ✅ Filter only NRF52840 devices
                                                // uint16_t lightValue = (uint8_t)manufacturerData[3] | ((uint8_t)manufacturerData[4] << 8);

          // uint8_t machine2 = (uint8_t)manufacturerData[3] & 0x0F;
          // uint8_t machine1 = (uint8_t)manufacturerData[3] >> 4;
          Serial.println(manufacturerData[0]);
          Serial.println(manufacturerData[1]);
          Serial.println(manufacturerData[2]);
          Serial.println(manufacturerData[3]);
          Serial.println(manufacturerData[4]);

          uint8_t transmissionId = (uint8_t)manufacturerData[3];
          Serial.printf("Transmission ID is %d\n", transmissionId);
          if (transmissionId == previousId) {
            Serial.printf("Received the same transmission as earlier\n");

            return;
          }

          previousId = transmissionId;

          Serial.print("Device Found - Company ID: 0x");
          Serial.println(companyID, HEX);

          // Process 16 machines starting from manufacturerData[4]
          JsonDocument doc;
          // doc["group"] = 0;
          JsonArray machineArray = doc["data"].to<JsonArray>();
          for (int i = 0; i < 16; i++) {
            uint8_t rawMachineData = manufacturerData[4 + i];
            Serial.printf("Raw Data Machine%d: %d\n", i + 1, rawMachineData);

            if (rawMachineData == 0) {
              continue;  // not active
            }

            int machineId = rawMachineData >> 1 & 0b01111111;
            int state = rawMachineData & 0b00000001;



            if (idMap.find(machineId) != idMap.end()) {
              Serial.print("Actual ID: ");
              Serial.println(idMap[machineId]);
            } else {
              Serial.println("localId not found");

              continue;
            }

            JsonObject machineObj = machineArray.add<JsonObject>();
            // machineObj["id"] = i;  // TODO: convert this to actual ids maybe through a map?
            machineObj["machineId"] = idMap[machineId];  // TODO: convert this to actual ids maybe through a map?
            // machineObj["type"] = machineData.type;
            machineObj["statusCode"] = state;




            // MachineData machineData = { 0, 0, 0, 0 };
            // getMachineData(rawMachineData, machineData.active, machineData.type, machineData.reserved, machineData.state);

            // if (machineData.active) {
            //   printMachineData(machineData);

            //   JsonObject machineObj = machineArray.add<JsonObject>();
            //   // machineObj["id"] = i;  // TODO: convert this to actual ids maybe through a map?
            //   machineObj["machineId"] = 1;  // TODO: convert this to actual ids maybe through a map?
            //   // machineObj["type"] = machineData.type;
            //   machineObj["statusCode"] = machineData.state;
            // }
          }

          // // try get request
          // Serial.println("Attempting GET request...");
          // if (http.begin(client, "httpbin.org", 443, "/get", true)) {
          //   int httpCode = http.GET();
          //   if (httpCode > 0) {
          //     Serial.print("GET Response code: ");
          //     Serial.println(httpCode);
          //     Serial.println("Response:");
          //     Serial.println(http.getString());
          //   } else {
          //     Serial.print("GET request failed: ");
          //     Serial.println(http.errorToString(httpCode));
          //   }
          //   http.end();
          // } else {
          //   Serial.println("Unable to connect for GET request");
          // }


          // POST request
          // String json;
          serializeJson(doc, jsonPost);
          hasData = true;
          // client.setInsecure();

          // http.begin(client, "https://httpbin.org/post");

          // http.addHeader("Content-Type", "application/json");
          // int httpResponseCode = http.POST("");

          // Read response
          // Serial.println(httpResponseCode);
          // Serial.print(http.getString());
          //
          // Serial.println("End post request");

          // Disconnect
          // http.end();
        }
      }
    }
  }
};



void setup() {
  idMap[1] = 1;  // map localId 1 to globalId 1
  idMap[2] = 2;


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

  Serial.println("ESP32 BLE Scanner - Repeated Scanning");

  BLEDevice::init("ESP32_BLE_Scanner");

  pBLEScan = BLEDevice::getScan();
  pBLEScan->setAdvertisedDeviceCallbacks(new MyAdvertisedDeviceCallbacks());
  pBLEScan->setInterval(100);
  pBLEScan->setWindow(99);
  pBLEScan->setActiveScan(true);
}

void loop() {
  Serial.println("Scanning...");

  pBLEScan->start(1, false);  // Scan for 1 second
  pBLEScan->clearResults();   // Free memory from previous scans

  delay(1000);  // Wait 1 second before restarting the scan

  if (hasData) {

    // POST request
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

    hasData = false;
  }
  // try get request
  // if (http.begin(client, host, port, path, false)) {  // false = HTTP
  //   int httpCode = http.GET();
  //   if (httpCode > 0) {
  //     Serial.printf("GET Response code: %d\n", httpCode);
  //     Serial.println(http.getString());
  //   } else {
  //     Serial.print("GET failed: ");
  //     Serial.println(http.errorToString(httpCode));
  //   }
  //   http.end();
  // } else {
  //   Serial.println("Unable to connect");
  // }
}

// #include <WiFi.h>
// #include <WiFiClientSecure.h>
// #include <HTTPClient.h>

// const char* ssid = "espspot";
// const char* password = "bvtx4675";

// void setup() {
//   Serial.begin(115200);
//   WiFi.begin(ssid, password);
//   while (WiFi.status() != WL_CONNECTED) {
//     delay(500);
//     Serial.print(".");
//   }
//   Serial.println("\nWiFi connected!");
//   Serial.print("IP Address: ");
//   Serial.println(WiFi.localIP());

//   WiFiClientSecure client;
//   client.setInsecure(); // For testing only

//   HTTPClient http;

//   // Try using the alternate overload for GET:
//   Serial.println("Attempting GET request...");
//   if (http.begin(client, "httpbin.org", 443, "/get", true)) {
//       int httpCode = http.GET();
//       if (httpCode > 0) {
//           Serial.print("GET Response code: ");
//           Serial.println(httpCode);
//           Serial.println("Response:");
//           Serial.println(http.getString());
//       } else {
//           Serial.print("GET request failed: ");
//           Serial.println(http.errorToString(httpCode));
//       }
//       http.end();
//   } else {
//       Serial.println("Unable to connect for GET request");
//   }
// }

// void loop() {
//   // Nothing to do here
// }
