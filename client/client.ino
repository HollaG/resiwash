#include <bluefruit.h>

#define LIGHT_SENSOR_PIN D2     // Light sensor input pin
#define COMPANY_ID 0xFFFE       // Custom Company ID (use 0xFFFF if unofficial)
#define CUSTOM_IDENTIFIER 0xA5  // Unique identifier for our NRF52840 devices // custom ,no other meaning


// indicator light output
#define LED_PIN D14

// bool machines[16] = { false };
// machines[0] = true;
// machines[1] = true;

// MAX MACHINE ID = 31

// MACHINE ID 0 IS RESERVED ==> INDICATES NOT IN USE

int machine1_ID = 1;
int machine1_PIN = D2;

int machine2_ID = 2;
int machine2_PIN = D2;

struct Machine {
  int ID;
  int PIN;
};

Machine machines[] = {
  { machine1_ID, machine1_PIN },
  { machine2_ID, machine2_PIN }
};

int machineCount = 2;



uint8_t sensorData[4 + 16] = {
  (COMPANY_ID & 0xFF), (COMPANY_ID >> 8) & 0xFF,  // Company ID (Little Endian)
  CUSTOM_IDENTIFIER,                              // Unique ID
  0,                                              // Broadcast number

  0, 0, 0, 0,
  0, 0, 0, 0,
  0, 0, 0, 0,
  0, 0, 0, 0,  // Placeholder for light sensor data = 16 machines
};

void setup() {
  Serial.begin(115200);

  pinMode(LED_PIN, OUTPUT);
  pinMode(LIGHT_SENSOR_PIN, INPUT);
  digitalWrite(LED_PIN, LOW);
  delay(1000);
  digitalWrite(LED_PIN, HIGH);

  delay(1000);
  digitalWrite(LED_PIN, LOW);
  delay(1000);

  digitalWrite(LED_PIN, HIGH);
  delay(1000);
  digitalWrite(LED_PIN, LOW);




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
bool atLeastOneHigh = false;

unsigned long lastReadTime = 0;
const unsigned long period = 10000;  // 10 000ms, 10s


void loop() {

  delay(100);


  atLeastOneHigh = false;
  initialized = true;

  unsigned long currentMillis = millis();

  // scan all inputs and set the LED to high if inputs are HIGH
  for (int i = 0; i < machineCount; i++) {
    Machine m = machines[i];
    int value = digitalRead(m.PIN);

    if (value == HIGH) {

      atLeastOneHigh = true;
      break;
    } else {
      atLeastOneHigh = false;
    }
  }

  if (atLeastOneHigh) {
    digitalWrite(LED_PIN, HIGH);
  } else {
    digitalWrite(LED_PIN, LOW);
  }


  if (currentMillis - lastReadTime >= period) {
    // more than 10 seconds since last update, change the advertising packet

    sensorData[3] = (sensorData[3] + 1) % 16;  // broadcast number

    Serial.printf("Transmitting ID %d\n", sensorData[3]);

    // for every machine, if it is enabled,
    // read its LDR value,
    // compare to threshold,
    // update sensorData bits


    for (int i = 0; i < machineCount; i++) {
      Machine m = machines[i];
      int result = 0b00000000;

      // add machine ID
      result = result | (m.ID << 1);

      // add state
      int value = digitalRead(m.PIN);

      if (value == HIGH) {
        result = result | 1;
      } else {
        result = result & 0b11111110;
      }


      // store in sensorData
      sensorData[4 + i] = result;

      Serial.printf("Stored value %d in sensorData %d. ID of %d was %d\n", result, 4 + i, m.ID, value);
    }



    Bluefruit.Advertising.stop();  // Stop advertising before updating
    Bluefruit.Advertising.clearData();
    Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
    Bluefruit.Advertising.addTxPower();
    Bluefruit.Advertising.addData(BLE_GAP_AD_TYPE_MANUFACTURER_SPECIFIC_DATA, sensorData, sizeof(sensorData));
    Bluefruit.ScanResponse.addName();
    Bluefruit.Advertising.start(0);  // Restart advertising

    lastReadTime = currentMillis;
  }
}
