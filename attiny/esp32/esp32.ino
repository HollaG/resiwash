// #define LDR1_PIN 7
// #define LDR2_PIN 6
// #define LED1_PIN 2
// #define LED2_PIN 3
// #define POT_PIN 0
// #define TRIG_PIN 1

#define TX_PIN 17
#define RX_PIN 16
#define UPDI_PIN 11

struct __attribute__((packed)) Message {
  uint8_t id;
  bool state;
  uint8_t reading;
};

// 5 example machines
Message exampleMachines[5] = {
  { 0, false, 0 },
  { 1, false, 21 },
  { 2, true, 126 },
  { 3, true, 150 },
  { 4, false, 10 }
};
bool sender = false;
HardwareSerial mySerial(2);

void sendMessages(Message* arr, size_t count) {
  mySerial.write(255);
  for (size_t i = 0; i < count; i++) {
    mySerial.write(arr[i].id);
    mySerial.write(arr[i].state);  // bool is 1 byte
    mySerial.write(arr[i].reading);

    // write delimiter
    // mySerial.write()
    Message message = arr[i];
    // mySerial.write((uint8_t*) &arr[i], sizeof(message));  // Forward it
    Serial.printf("Wrote %d, %d, %d\n", arr[i].id, arr[i].state, arr[i].reading);

    // In order: id byte, state byte, reading byte
 
  }
  mySerial.write(255);
}



void setup() {
  // put your setup code here, to run once:
  // pinMode(LDR1_PIN, INPUT);
  // pinMode(LDR2_PIN, INPUT);
  // pinMode(POT_PIN, INPUT);
  // pinMode(TRIG_PIN, INPUT);
  // pinMode(LED1_PIN, OUTPUT);
  // pinMode(LED2_PIN, OUTPUT);

  // int trigger = digitalRead(TRIG_PIN);
  // if (trigger) {
  //   sender = true;
  // }
  
  sender = true;

  mySerial.begin(9600, SERIAL_8N1, RX_PIN, TX_PIN);
  Serial.begin(115200);
}

int state = 0; 
  int counter = 0;
void loop() {
  // put your main code here, to run repeatedly:

  // int ldr1 = analogRead(LDR1_PIN);
  // int ldr2 = analogRead(LDR2_PIN);
  // int ldr = max(ldr1, ldr2);

  // int pot = analogRead(POT_PIN);



  // if (ldr < pot) {
  //   state = 0;
  // } else {
  //   state = 1;
  // }

  // if (ldr1 < pot) { 
  //   digitalWrite(LED1_PIN, LOW);
  // } else { 
  //   digitalWrite(LED1_PIN, HIGH);
  // }

  // if (ldr2 < pot) { 
  //   digitalWrite(LED2_PIN, LOW);
  // } else { 
  //   digitalWrite(LED2_PIN, HIGH);
  // }



  // if (Serial.available() && sender == false) {
  //   // start reading into array until no more bytes left to read
  //   int count = 0;
  //   while (Serial.available()) {
  //     Message incoming;
  //     Serial.readBytes((char*)&incoming, sizeof(incoming));
  //     Serial.write((uint8_t*)&incoming, sizeof(incoming));  // Forward it
  //     count = count + 1;
  //   }
  //   // write the current state
  //   Message self = { count, state, constrain(ldr / 4, 0, 255)  };
  //   Serial.write((uint8_t*)&self, sizeof(self));
  // }

  if (sender == true) { 
    // write the current state
    // Message self = { 0, state, constrain(ldr / 4, 0, 255)  };
    // Serial.write((uint8_t*)&self, sizeof(self));

    // send example machines
    sendMessages(exampleMachines, sizeof(exampleMachines) / sizeof(Message));

    delay(10000); // every 10 seconds
  }

  delay(100);


  // mySerial.write(counter);

    // Format string: "4,1,25"
  // mySerial.print(2);
  // mySerial.print(",");
  // mySerial.print(1);
  // mySerial.print(",");
  // mySerial.println(124);
  // SermySerialial.printf("Wrote %d\n", counter);
  // counter = counter + 1;

  // delay(1000);




  



}
