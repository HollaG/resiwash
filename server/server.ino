#include <Arduino.h>
#include "BLEDevice.h"

#define CUSTOM_IDENTIFIER 0xAB  // Expected identifier byte

#include <WiFi.h>

#define ssid "espspot"
#define pass "bvtx4675"

BLEScan* pBLEScan;

class MyAdvertisedDeviceCallbacks : public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice advertisedDevice) override {
    if (advertisedDevice.haveManufacturerData()) {
      String manufacturerData = advertisedDevice.getManufacturerData();
      // Serial.println(manufacturerData);

      if (manufacturerData.length() >= 5) {  // Ensure at least 5 bytes (Company ID + Identifier + Sensor Data)
        uint16_t companyID = (uint8_t)manufacturerData[0] | ((uint8_t)manufacturerData[1] << 8);
        uint8_t identifier = (uint8_t)manufacturerData[2];

        if (identifier == CUSTOM_IDENTIFIER) {  // ✅ Filter only NRF52840 devices
          uint16_t lightValue = (uint8_t)manufacturerData[3] | ((uint8_t)manufacturerData[4] << 8);

          Serial.print("Device Found - Company ID: 0x");
          Serial.println(companyID, HEX);
          Serial.print("Light Sensor Value: ");
          Serial.println(lightValue);
        }
      }
    }
  }
};

void setup() {
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
}
