/** Core file for the ESP32 used as the receiver.*/

// Strategy map: 0->OR, 1->NOR,

// core libraries
#include "sys/time.h"
#include "esp_sleep.h"
#include <Arduino.h>
#include <unordered_map>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "String"

// oled display
#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <stdarg.h>  // for va_list, va_start, va_end
#include <stdio.h>   // for vsnprintf


#include "OneButton.h"  // for debounce rot. enc.
#include <ESP32Encoder.h>
#define SCREEN_WIDTH 128  // OLED display width, in pixels
#define SCREEN_HEIGHT 64  // OLED display height, in pixels

// Declaration for an SSD1306 display connected to I2C (SDA, SCL pins)
#define OLED_RESET -1  // Reset pin # (or -1 if sharing Arduino reset pin)
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);


// == if HTTPS, use Secure, if HTTP (local dev), use non-secure
// #include <WifiClientSecure.h>
#include <WifiClient.h>

// WiFiClientSecure client;  // or WiFiClientSecure for HTTPS
WiFiClient client;  // or WiFiClientSecure for HTTPS

HTTPClient http;

#define ssid "espspot"
#define pass "bvtx4675"
// #define ssid "SINGTEL-C6A8"
// #define pass "wkskgx37k7tW"
const char *serverName = "https://resiwash.marcussoh.com/api/v1/events/bulk";
// const char *serverName = "http://192.168.1.3:3000/api/v1/events/bulk";
// const char *registerName = "http://192.168.1.3:3000/api/v1/sensors/register";
const char *registerName = "https://resiwash.marcussoh.com/api/v1/sensors/register";

#define BAUD 9600
#define RXD2 16
#define TXD2 17
#define TXD1 18
#define RXD1 19

#define BTN_PIN 5
#define ENCODER_PIN1 15  // do NOT use D2
#define ENCODER_PIN2 4

#define START_BYTE 251
#define END_BYTE 252

std::unordered_map<int, int> serial1Map;
std::unordered_map<int, int> serial2Map;

OneButton btn = OneButton(
  BTN_PIN,  // Input pin for the button
  true,     // Button is active LOW
  true      // Enable internal pull-up resistor
);

ESP32Encoder encoder;


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

// Initialize the two serial inputs
HardwareSerial mySerial1(1);
HardwareSerial mySerial2(2);

void safeFlushSerial(HardwareSerial &s) {
  while (s.available() > 0) s.read();
}

void onConnectWifi() {
  HTTPClient http;
  int httpResponseCode = -1;


  if (!http.begin(client, registerName)) {
    Serial.println("[error] http.begin() failed");
    ESP.restart();
    return;
  }

  http.setTimeout(8000);
  http.addHeader("Content-Type", "application/json");

  // Avoid big temporary Strings (less fragmentation)
  char macBuf[18];
  WiFi.macAddress().toCharArray(macBuf, sizeof(macBuf));
  char payload[64];
  snprintf(payload, sizeof(payload), "{\"macAddress\":\"%s\"}", macBuf);

  Serial.println("POST /sensors/register");
  httpResponseCode = http.POST((uint8_t *)payload, strlen(payload));

  Serial.printf("HTTP code: %d\n", httpResponseCode);
  if (httpResponseCode > 0) {
    String body = http.getString();
    Serial.println(body);
  }
  http.end();
}

// Shift entire screen down by 8 pixels (one page) on a 128x64 SSD1306
void shiftDownOneTextRow(Adafruit_SSD1306 &d) {
  uint8_t *buf = d.getBuffer();  // 1024 bytes (128*64/8)
  const int WIDTH = 128;
  const int PAGES = 8;  // 64 / 8

  // move bottom-up to avoid overwrite
  for (int page = PAGES - 1; page >= 1; --page) {
    memcpy(buf + page * WIDTH, buf + (page - 1) * WIDTH, WIDTH);
  }
  // clear top page (y=0..7)
  memset(buf + 0 * WIDTH, 0, WIDTH);
}


void pushTopFast(const String &s) {
  shiftDownOneTextRow(display);
  display.setCursor(0, 0);
  display.setTextSize(1);
  display.setTextWrap(false);
  display.print(s);
  display.display();
}

// New version with printf-style formatting
void pushTopFastFmt(const char *fmt, ...) {
  char buf[64];  // adjust if you need longer lines

  va_list args;
  va_start(args, fmt);
  vsnprintf(buf, sizeof(buf), fmt, args);
  va_end(args);

  pushTopFast(String(buf));
}


/**
* OLED screen controls
* by clicking, the user can change serialSource from 1 to 2 and back
* the user can also rotate the encoder to change the displayId
* the displayId will reset to 0 when the button is pushed
* the displayId will never go below 0
*/

int displayIdSerial1 = 0;  // start with 0
int displayIdSerial2 = 0;


int serialSource = 1;  // serial 1

bool hasReceivedData = false;
Message savedData = { 0, 0, 0, 0, 0, 0, 0 };

// Called when encoder is rotated
void onRotate(int direction, int serialSource) {
  if (serialSource == 1) {

    displayIdSerial1 += direction;
    if (displayIdSerial1 < -1) displayIdSerial1 = -1;
  }

  if (serialSource == 2) {

    displayIdSerial2 += direction;
    if (displayIdSerial2 < -1) displayIdSerial2 = -1;
  }

  // reset the data
  hasReceivedData = false;
  savedData = { 0, 0, 0, 0, 0, 0, 0 };


  Serial.printf("[OLED] Rotated serial %d: direction=%d, displayId1=%d, displayId2=%d\n", serialSource, direction, displayIdSerial1, displayIdSerial2);
}

// Called when encoder button is clicked
void onClick() {
  // Toggle between serial 1 and serial 2
  serialSource = (serialSource == 1) ? 2 : 1;


  // reset the data
  hasReceivedData = false;
  savedData = { 0, 0, 0, 0, 0, 0, 0 };

  Serial.printf("[OLED] Clicked: serialSource=%d\n", serialSource);
}

void drawCenteredText(const char *text, int16_t y, uint8_t textSize = 1) {
  display.setTextSize(textSize);
  display.setTextColor(SSD1306_WHITE);

  int16_t x1, y1;
  uint16_t w, h;
  display.getTextBounds(text, 0, y, &x1, &y1, &w, &h);

  int16_t x = (display.width() - w) / 2;
  display.setCursor(x, y);
  display.print(text);
}

void drawRightAligned(int16_t y, const char *format, ...) {
  char buf[64];  // Adjust as needed for your longest string
  va_list args;
  va_start(args, format);
  vsnprintf(buf, sizeof(buf), format, args);
  va_end(args);

  // Each character = 6 pixels wide in size 1
  int16_t x = display.width() - (strlen(buf) * 6);
  display.setCursor(x, y);
  display.print(buf);
}

void drawHeader() {
  String ip = WiFi.localIP().toString();
  String mac = WiFi.macAddress();  // e.g. "24:6F:28:AA:BB:CC"

  // Draw IP at top
  drawCenteredText(ip.c_str(), 0, 1);

  // Draw MAC just below IP
  drawCenteredText(mac.c_str(), 10, 1);

  // Draw line under both
  display.drawLine(0, 20, display.width(), 20, SSD1306_WHITE);
}



void drawMachineInfo() {
  display.setCursor(0, 24);  // below the line

  if (serialSource == 1) {
    display.setCursor(0, 24);
    display.println("Serial 1");
    if (displayIdSerial1 == -1) {
      // draw DISABLED
      drawCenteredText("DISABLED", 36, 2);
    } else {
      if (!hasReceivedData) {
        display.printf("Waiting for data\n");
      } else {

        display.printf("Left sensor: %d/%d\n", savedData.reading1, savedData.thres1);
        display.printf("Right sensor: %d/%d\n", savedData.reading2, savedData.thres2);
      }

      drawRightAligned(24, "ID %d", serialSource == 1 ? displayIdSerial1 : displayIdSerial2);
    }
  }

  if (serialSource == 2) {
    display.setCursor(0, 24);
    display.println("Serial 2");
    if (displayIdSerial2 == -1) {
      drawCenteredText("DISABLED", 36, 2);
    } else {
      // draw DISABLED
      if (!hasReceivedData) {
        display.printf("Waiting for data\n");
      } else {
        display.printf("Left sensor: %d/%d\n", savedData.reading1, savedData.thres1);
        display.printf("Right sensor: %d/%d\n", savedData.reading2, savedData.thres2);
      }
      drawRightAligned(24, "ID %d", serialSource == 1 ? displayIdSerial1 : displayIdSerial2);
    }
  }
}

void setup() {
  Serial.begin(115200);
  delay(200);

  // initialize screen
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {  // Address 0x3D for 128x64
    Serial.println(F("SSD1306 allocation failed"));
    for (;;)
      ;
  }

  delay(2000);
  display.clearDisplay();

  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0, 0);



  // Display static text
  display.println("Initializing...");
  display.display();

  // initalize buttons
  btn.attachPress(onClick);
  // pinMode(BTN_PIN, INPUT_PULLUP);


  // Bring up UARTs *before* Wi-Fi so they aren't initialized during RF spikes
  // mySerial2.begin(BAUD, SERIAL_8N1, RXD2, TXD2);
  mySerial1.begin(BAUD, SERIAL_8N1, RXD1, TXD1);
  safeFlushSerial(mySerial1);
  safeFlushSerial(mySerial2);
  display.println("Connecting Wi-Fi...");
  display.display();

  Serial.println("\nConnecting to Wi-Fi…");
  WiFi.persistent(false);
  WiFi.setSleep(false);  // keep radio awake; avoids some timing weirdness
  WiFi.mode(WIFI_STA);
  WiFi.disconnect(true, true);  // clear old state
  delay(200);

  WiFi.begin(ssid, pass);
  while (WiFi.status() != WL_CONNECTED) {
    delay(250);
    Serial.print('.');
  }
  Serial.println();

  display.print("Connected ");
  display.println(WiFi.localIP());
  display.display();

  Serial.print("Wi-Fi OK. IP: ");
  Serial.println(WiFi.localIP());
  Serial.printf("Free heap before HTTP: %u\n", ESP.getFreeHeap());

  // Give the stack a breather before TLS
  delay(500);



  onConnectWifi();
  display.println("Registered");
  display.display();
  delay(1000);
  display.clearDisplay();
  display.display();
  display.setCursor(0, 0);


  display.clearDisplay();

  drawHeader();
  display.display();


  ESP32Encoder::useInternalWeakPullResistors = puType::up;
  // pinMode(ENCODER_PIN1, INPUT_PULLUP);
  // pinMode(ENCODER_PIN2, INPUT_PULLUP);
  encoder.attachHalfQuad(ENCODER_PIN1, ENCODER_PIN2);
  Serial.println("Encoder Start = " + String((int32_t)encoder.getCount()));
}

// parsed messages stored here
Message serial1Messages[255];
Message serial2Messages[255];
int serial1Count = 0;
int serial2Count = 0;

// buffer for reading from Serial
int serial1Buffer[1024];
int serial2Buffer[1024];

int prevEncoder = 0;

void loop() {
  int cur = encoder.getCount();

  if (cur > prevEncoder) {
    // go next
    onRotate(1, serialSource);
  } else if (cur < prevEncoder) {
    onRotate(-1, serialSource);
  }

  prevEncoder = cur;

  // Serial.printf("D2 %d", digitalRead(ENCODER_PIN1));
  // Serial.printf(" D4 %d \n", digitalRead(ENCODER_PIN2));
  // Serial.println("Encoder count = " + String((int32_t)encoder.getCount()));

  // loop only every 50ms
  delay(50);

  // functions to run every loop
  btn.tick();



  display.clearDisplay();
  drawHeader();
  drawMachineInfo();
  display.display();


  // we somehow lost connection...
  if (WiFi.status() != WL_CONNECTED) {
    // re-connect
    Serial.println("[error] connection LOST");

    // clear the display
    WiFi.disconnect();
    WiFi.begin(ssid, pass);

    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("Reconnecting...");
    display.display();
    while (WiFi.status() != WL_CONNECTED) {
      delay(250);
      Serial.print('.');
    }

    Serial.println("[info] connection regained");

    onConnectWifi();
  }

  // message from S2
  if (mySerial2.available() && displayIdSerial2 != -1) {


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

      serial2Buffer[serial2Count] = byteFromSerial;

      serial2Count = serial2Count + 1;
      // bytesRead = bytesRead + 1;
      Serial.printf("%d ", byteFromSerial);
      if ((serial2Count - 1) % sizeof(Message) == 0) {
        Serial.printf("\n");
      }

      if (isReading && byteFromSerial == START_BYTE) {
        // restart from the start, for some reason we had a fail
        isStarted = true;
        serial2Count = 1;

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
        int messageBytes = serial2Count - 2;
        int remainder = messageBytes % sizeof(Message);

        if (remainder != 0) {
          // some error in reading the length
          Serial.printf("[error][serial2] bytesRead=%d, sizeof message=%d, remainder=%d", serial2Count, sizeof(Message), remainder);
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
        // bytesRead = 0;
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
  }

  // message from S1
  if (mySerial1.available() && displayIdSerial1 != -1) {
    Serial.println("");
    Serial.println("--- Available message in Serial 1 ---");


    bool isStarted = false;
    bool isReading = true;
    int bytesRead = 0;

    while (mySerial1.available() || isReading) {
      while (!mySerial1.available()) {
        // Need this in case we haven't received the end byte yet!
      }

      uint8_t byteFromSerial = mySerial1.read();

      serial1Buffer[serial1Count] = byteFromSerial;

      serial1Count = serial1Count + 1;
      // bytesRead = bytesRead + 1;
      Serial.printf("%d ", byteFromSerial);
      if ((serial1Count - 1) % sizeof(Message) == 0) {
        Serial.printf("\n");
      }

      if (isReading && byteFromSerial == START_BYTE) {
        // restart from the start, for some reason we had a fail
        isStarted = true;
        serial1Count = 1;

        continue;
      }

      if (isReading && byteFromSerial == END_BYTE) {
        isStarted = false;

        // clear out buffer
        while (mySerial1.available()) {
          mySerial1.read();
        }

        // sanity check to see if the number of bytes received makes sense
        int messageBytes = serial1Count - 2;
        int remainder = messageBytes % sizeof(Message);

        if (remainder != 0) {
          // some error in reading the length
          Serial.printf("[error][serial1] bytesRead=%d, sizeof message=%d, remainder=%d", serial1Count, sizeof(Message), remainder);
          break;  // exit this inner loop
        }

        // TODO: do some post requests here
        int messageCount = messageBytes / sizeof(Message);
        Serial.printf("\n[serial1] Read %d messages\n", messageCount);

        break;  // exit this inner loop
      }

      // if not start and end byte,
      if (!isStarted) {
        // something went wrong, ignore this
        Serial.println("[error][serial1] first byte received was not start byte");
        // bytesRead = 0;
        serial1Count = 0;

        // clear the buffer
        while (mySerial1.available()) {
          mySerial1.read();
        }
        break;  // exit this inner loop
      }

      // read the bytes
      // do some logic here
    }
  }

  if (serial2Count > 0 || serial1Count > 0) {




    // buffer[0] is start bit
    // buffer[bytesRead-1] is end bit


    // first validate that there are integer division
    // validated earlier

    String jsonPost;
    JsonDocument doc;
    JsonArray machineArray = doc["data"].to<JsonArray>();
    doc["macAddress"] = WiFi.macAddress();
    if (serial1Count > 0) {
      Serial.printf("[info] parsing data from serial 1 buffer. size is %d\n", serial1Count);
      for (int i = 0; i < serial1Count - 2; i += sizeof(Message)) {
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
        machineObj["source"] = "serial1";


        JsonArray readingsArray = machineObj["readings"].to<JsonArray>();

        JsonObject data_0_readings_0 = readingsArray.add<JsonObject>();
        data_0_readings_0["value"] = reading1;
        data_0_readings_0["threshold"] = thres1;

        JsonObject data_0_readings_1 = readingsArray.add<JsonObject>();
        data_0_readings_1["value"] = reading2;
        data_0_readings_1["threshold"] = thres2;

        Serial.printf("[info][serial1] %d %d %d %d %d %d %d\n", id, state, strategy, reading1, thres1, reading2, thres2);
        // pushTopFastFmt("1 %d %d %d %d %d %d %d\n", id, state, strategy, reading1, thres1, reading2, thres2);


        // update the display with this machine's information
        if (id == displayIdSerial1 && serialSource == 1) {  // serial1
          // Message m =
          savedData = { id, state, strategy, reading1, thres1, reading2, thres2 };
          hasReceivedData = true;
        }

        // // save to the serial Map
        // // serial2Messages[serial2Count] = m;
      }
      serial1Count = 0;
    }
    if (serial2Count > 0) {
      Serial.println("[info] parsing data from serial 2 buffer");
      for (int i = 0; i < serial2Count - 2; i += sizeof(Message)) {
        uint8_t id = serial2Buffer[1 + i + 0];
        uint8_t state = serial2Buffer[1 + i + 1];
        uint8_t strategy = serial2Buffer[1 + i + 2];
        uint8_t reading1 = serial2Buffer[1 + i + 3];
        uint8_t thres1 = serial2Buffer[1 + i + 4];
        uint8_t reading2 = serial2Buffer[1 + i + 5];
        uint8_t thres2 = serial2Buffer[1 + i + 6];


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

        Serial.printf("[info][serial2] %d %d %d %d %d %d %d\n", id, state, strategy, reading1, thres1, reading2, thres2);
        // pushTopFastFmt("1 %d %d %d %d %d %d %d\n", id, state, strategy, reading1, thres1, reading2, thres2);

        // Message m = { id, state, strategy, reading1, thres1, reading2, thres2 };

        // // save to the serial Map
        // // serial2Messages[serial2Count] = m;

        // update the display with this machine's information
        if (id == displayIdSerial2 && serialSource == 2) {  // serial1
          savedData = { id, state, strategy, reading1, thres1, reading2, thres2 };
          hasReceivedData = true;
        }
      }
      serial2Count = 0;
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
  }
}
