#define LDR1_PIN 7
#define LDR2_PIN 6
#define LED1_PIN 2
#define LED2_PIN 3
#define POT_PIN 0
#define TRIG_PIN 1

#define TX_PIN 5
#define RX_PIN 4
#define UPDI_PIN 11

#define START_BYTE 251
#define END_BYTE 252

struct Message {
  uint8_t id;
  bool state;
  uint8_t strategy;
  uint8_t reading1;
  uint8_t thres1;
  uint8_t reading2;
  uint8_t thres2;
};


void sendMessage(const Message& msg) {
  Serial.write(msg.id);
  Serial.write(msg.state);  // bool is treated as 1 byte (0 or 1)
  Serial.write(msg.strategy);
  Serial.write(msg.reading1);
  Serial.write(msg.thres1);
  Serial.write(msg.reading2);
  Serial.write(msg.thres2);
}

bool sender = false;

void setup() {
  // put your setup code here, to run once:
  pinMode(LDR1_PIN, INPUT);
  pinMode(LDR2_PIN, INPUT);
  pinMode(POT_PIN, INPUT);
  pinMode(TRIG_PIN, INPUT);
  pinMode(LED1_PIN, OUTPUT);
  pinMode(LED2_PIN, OUTPUT);

  // int trigger = digitalRead(TRIG_PIN);
  // if (trigger) {
  //   sender = true;
  // }


  Serial.begin(9600);
  // clear all messages in Serial
  while (Serial.available()) {
    Serial.read();
  }

  // configure lights to flash
  digitalWrite(LED1_PIN, HIGH);
  delay(1000);
  digitalWrite(LED2_PIN, HIGH);
  digitalWrite(LED1_PIN, LOW);
  delay(1000);
  digitalWrite(LED2_PIN, LOW);
  delay(1000);
  digitalWrite(LED1_PIN, HIGH);
  digitalWrite(LED2_PIN, HIGH);
  delay(1000);
  digitalWrite(LED1_PIN, LOW);
  digitalWrite(LED2_PIN, LOW);
  delay(1000);
  digitalWrite(LED1_PIN, HIGH);
  digitalWrite(LED2_PIN, HIGH);
  delay(1000);
  digitalWrite(LED1_PIN, LOW);
  digitalWrite(LED2_PIN, LOW);
  delay(1000);
  digitalWrite(LED1_PIN, HIGH);
  digitalWrite(LED2_PIN, HIGH);
  delay(1000);
  digitalWrite(LED1_PIN, LOW);
  digitalWrite(LED2_PIN, LOW);
  delay(100);
  delay(1000);
}

int state = 0;
unsigned long previousMillis = 0;
const unsigned long interval = 5000;  // 1 second

uint8_t buffer[128];
int i = 0;
void loop() {
  // put your main code here, to run repeatedly:

  unsigned long currentMillis = millis();

  int ldr1 = (analogRead(LDR1_PIN) * 250L) / 1024;
  int ldr2 = (analogRead(LDR2_PIN) * 250L) / 1024;

  int ldr = max(ldr1, ldr2);

  int pot = (analogRead(POT_PIN) * 250L) / 1024;



  if (ldr < pot) {
    state = 0;
  } else {
    state = 1;
  }

  if (ldr1 < pot) {
    digitalWrite(LED1_PIN, LOW);
  } else {
    digitalWrite(LED1_PIN, HIGH);
  }

  if (ldr2 < pot) {
    digitalWrite(LED2_PIN, LOW);
  } else {
    digitalWrite(LED2_PIN, HIGH);
  }



  bool isCurrentlyReading = false;
  int byteCount = 0;
  if (Serial.available() && sender == false) {
    // start reading into array until no more bytes left to read

    // while (Serial.available()) {
    //   uint8_t incomingByte = Serial.read();
    //   Serial.write(incomingByte);
    // }


    while (Serial.available() || isCurrentlyReading) {
      while (!Serial.available()) {
        // TODO: do a timeout here
      }  // busy waiting until all messages are recieved
      uint8_t incomingByte = Serial.read();

      if (incomingByte == START_BYTE && isCurrentlyReading == true) {
        // error, restart from start
        byteCount = 0;
        // i = 0; // temporarily don't restart
      }

      if (incomingByte == START_BYTE && isCurrentlyReading == false) {
        isCurrentlyReading = true;
        i = 0;
        byteCount = 0;
      }





      byteCount++;

      if (incomingByte == END_BYTE && isCurrentlyReading == true) {
        // end of transmission
        isCurrentlyReading = false;

        // clear the buffer
        while (Serial.available()) {
          Serial.read();
        }

        int numberOfMachines = (byteCount - 2) / sizeof(Message);

        buffer[i] = numberOfMachines;
        buffer[i + 1] = state;
        buffer[i + 2] = 0;
        buffer[i + 3] = ldr1;
        buffer[i + 4] = pot;
        buffer[i + 5] = ldr2;
        buffer[i + 6] = pot;
        buffer[i + 7] = END_BYTE;
        i = i + 8;

     

        Serial.write(buffer, i);  // send in one go


        // delay(50);
        // Serial.write(END_BYTE);

        Serial.flush();

        // clear the buffer
        i = 0;
        byteCount = 0; // technically not needed...?
        break;
      }

      // Forward
      // Serial.write(incomingByte);
      buffer[i] = incomingByte;
      i = i + 1;
    }
  }

  if (sender == true) {

    if (currentMillis - previousMillis >= interval) {
      previousMillis = currentMillis;
      // Do something here (non-blocking)

      Serial.write(START_BYTE);
      Message self = { 0, state, 0, ldr1, pot, ldr2, pot };
      sendMessage(self);
      // Serial.write(0);
      // Serial.write(state);
      Serial.write(END_BYTE);



      // delay(1000);  // every 10 seconds
    }
  }

  // delay(100);
}
