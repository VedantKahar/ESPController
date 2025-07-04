#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>
#include <ArduinoOTA.h>

// Wi-Fi credentials
#define WIFI_SSID "JPSC_ENGI"
#define WIFI_PASSWORD "Jpsc@kotambi24"

// Firebase details
//#define FIREBASE_HOST "espcontroller-79a40-default-rtdb.firebaseio.com"
//#define FIREBASE_AUTH "K93JXfHXvcipo7YizO1XUc1vXuJF6C5rwxolBvcS"  // Leave empty for test mode (no auth)

#define FIREBASE_HOST "flutterespcontroller-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "L4hUuX9PmHbh2O3kd6lmfN5YrFdUubImqEPeoZgI"

FirebaseData fbdo;
FirebaseConfig config;
FirebaseAuth auth;

// Pin definitions
#define AC D5
#define FAN D7
#define HEATER D6

void setup() {
  Serial.begin(74880);

  pinMode(AC, OUTPUT);
  pinMode(FAN, OUTPUT);
  pinMode(HEATER, OUTPUT);

  digitalWrite(AC, HIGH);    // Relay OFF (assuming active LOW)
  digitalWrite(FAN, HIGH);
  digitalWrite(HEATER, HIGH);

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected. IP:");
  Serial.println(WiFi.localIP());

  // Correct Firebase config
  config.database_url = "https://flutterespcontroller-default-rtdb.firebaseio.com";
  config.signer.tokens.legacy_token = FIREBASE_AUTH;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // Start OTA updates
  ArduinoOTA.begin();
}
unsigned long lastCheck = 0;
const int interval = 200;

void loop() {
  ArduinoOTA.handle();

  if (millis() - lastCheck >= interval) {
    lastCheck = millis();

    Serial.println("Checking Firebase...");

    // AC Control
    if (Firebase.getString(fbdo, "/Devices/ac")) {
      String acState = fbdo.stringData();
      digitalWrite(AC, acState == "on" ? LOW : HIGH);
      Serial.println("AC: " + acState);
    }

    // Fan Control
    if (Firebase.getString(fbdo, "/Devices/fan")) {
      String fanState = fbdo.stringData();
      digitalWrite(FAN, fanState == "on" ? LOW : HIGH);
      Serial.println("Fan: " + fanState);
    }

    // Heater Control
    if (Firebase.getString(fbdo, "/Devices/heater")) {
      String heaterState = fbdo.stringData();
      digitalWrite(HEATER, heaterState == "on" ? LOW : HIGH);
      Serial.println("Heater: " + heaterState);
    }
  }
}
