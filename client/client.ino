#include <bluefruit.h>

#define LIGHT_SENSOR_PIN A0  // Light sensor input pin
#define COMPANY_ID 0xFFFF    // Custom Company ID (use 0xFFFF if unofficial)
#define CUSTOM_IDENTIFIER 0xAB  // Unique identifier for our NRF52840 devices

void setup() {
    Serial.begin(115200);
    Serial.println("NRF52840 Light Sensor Advertiser");

    Bluefruit.setName("LightSensor_52840");
    Bluefruit.begin();
    Bluefruit.setTxPower(4);

    // Configure BLE advertising
    Bluefruit.Advertising.clearData();
    Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
    Bluefruit.Advertising.addTxPower();

    Bluefruit.ScanResponse.clearData();
    Bluefruit.ScanResponse.addName();

    // ✅ Initialize advertisement with default sensor data
    uint8_t sensorData[5] = { 
        (COMPANY_ID & 0xFF), (COMPANY_ID >> 8) & 0xFF,  // Company ID (Little Endian)
        CUSTOM_IDENTIFIER,  // Unique identifier byte
        0, 0                // Placeholder for light sensor data
    };
    Bluefruit.Advertising.addData(BLE_GAP_AD_TYPE_MANUFACTURER_SPECIFIC_DATA, sensorData, sizeof(sensorData));

    Bluefruit.Advertising.restartOnDisconnect(true);
    Bluefruit.Advertising.setInterval(160, 160);
    Bluefruit.Advertising.setFastTimeout(30);
    Bluefruit.Advertising.start(0);  // 0 = Advertise indefinitely
}

void loop() {
    uint16_t lightValue = analogRead(LIGHT_SENSOR_PIN);

    Serial.print("Light Sensor Value: ");
    Serial.println(lightValue);

    // ✅ Update sensor value in the advertisement packet
    uint8_t sensorData[5] = { 
        (COMPANY_ID & 0xFF), (COMPANY_ID >> 8) & 0xFF,  // Company ID
        CUSTOM_IDENTIFIER,  // Unique identifier
        lightValue & 0xFF, (lightValue >> 8) & 0xFF  // Light sensor value (Little Endian)
    };

    Bluefruit.Advertising.stop();  // Stop advertising before updating
    Bluefruit.Advertising.clearData();
    Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
    Bluefruit.Advertising.addTxPower();
    Bluefruit.Advertising.addData(BLE_GAP_AD_TYPE_MANUFACTURER_SPECIFIC_DATA, sensorData, sizeof(sensorData));
    Bluefruit.ScanResponse.addName();

    Bluefruit.Advertising.start(0);  // Restart advertising

    delay(1000);  // Update sensor data every second
}
