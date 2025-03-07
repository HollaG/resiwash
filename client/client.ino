#include <bluefruit.h>

#define LIGHT_SENSOR_PIN A0     // Light sensor input pin
#define COMPANY_ID 0xFFFE       // Custom Company ID (use 0xFFFF if unofficial)
#define CUSTOM_IDENTIFIER 0xA5  // Unique identifier for our NRF52840 devices

// bool machines[16] = { false };
// machines[0] = true;
// machines[1] = true;

int MACHINE_0_STATE = true;
int MACHINE_1_STATE = true;

uint8_t sensorData[4 + 16] = {
  (COMPANY_ID & 0xFF), (COMPANY_ID >> 8) & 0xFF,  // Company ID (Little Endian)
  CUSTOM_IDENTIFIER,                              // Unique ID 
  0,                                              // 1 byte value representing the "wake ID"
                           
  0, 0, 0, 0,
  0, 0, 0, 0,
  0, 0, 0, 0,
  0, 0, 0, 0,                                // Placeholder for light sensor data
};

void setup() {
  Serial.begin(115200);
  Serial.println("NRF52840 Light Sensor Advertiser");

  Bluefruit.setName("client");
  Bluefruit.begin();
  Bluefruit.setTxPower(4);

  // Configure BLE advertising
  Bluefruit.Advertising.clearData();
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();

  Bluefruit.ScanResponse.clearData();
  Bluefruit.ScanResponse.addName();

  // ✅ Initialize advertisement with default sensor data

  Bluefruit.Advertising.addData(BLE_GAP_AD_TYPE_MANUFACTURER_SPECIFIC_DATA, sensorData, sizeof(sensorData));

  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(160, 160);
  Bluefruit.Advertising.setFastTimeout(30);
  Bluefruit.Advertising.start(0);  // 0 = Advertise indefinitely
}

int threshold = 50;

bool initialized = false;
void loop() {
  uint16_t lightValue = analogRead(LIGHT_SENSOR_PIN);

  Serial.print("Light Sensor Value: ");
  Serial.println(lightValue);



  // ✅ Update sensor value in the advertisement packet
  // uint8_t sensorData[6] = {
  //   (COMPANY_ID & 0xFF), (COMPANY_ID >> 8) & 0xFF,  // Company ID = 0xFFFE
  //   CUSTOM_IDENTIFIER,                              // Unique identifier
  //   lightValue & 0xFF, (lightValue >> 8) & 0xFF     // Light sensor value (Little Endian)
  // };

  // pretend one above 50 = send all
  if (lightValue > 50 || !init) {
    initialized = true;

    sensorData[3] = (sensorData[3] + 1) % 16;

    sensorData[4] = 0x81; // 1001 1100
    sensorData[5] = 0xC0;
    sensorData[10] = 0xC1;

    Serial.printf("Broadcasting for 10 seconds... with ID %d", sensorData[3]);

    Bluefruit.Advertising.stop();  // Stop advertising before updating
    Bluefruit.Advertising.clearData();
    Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
    Bluefruit.Advertising.addTxPower();
    Bluefruit.Advertising.addData(BLE_GAP_AD_TYPE_MANUFACTURER_SPECIFIC_DATA, sensorData, sizeof(sensorData));
    Bluefruit.ScanResponse.addName();
    Bluefruit.Advertising.start(0);  // Restart advertising

    delay(10000);
  }

  Bluefruit.Advertising.stop();




  delay(5000);  // Update sensor data every second
}
