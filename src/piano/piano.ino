#include <Audio.h>
#include "pianoModel.h"
#include "math.h"

pianoModel myDsp;
AudioOutputI2S out;
AudioControlSGTL5000 audioShield;
AudioConnection patchCord0(myDsp,0,out,0);
AudioConnection patchCord1(myDsp,0,out,1);

void setup() {
  Serial.begin(31250);
  AudioMemory(2);
  audioShield.enable();
  audioShield.volume(0.5);
}

void loop() {
  if (usbMIDI.read()) {
    Serial.print("Type: ");
    Serial.print(usbMIDI.getType());
    Serial.print(" Channel: ");
    Serial.print(usbMIDI.getChannel());
    Serial.print(" Data1: ");
    Serial.print(usbMIDI.getData1());
    Serial.print(" Data2: ");
    Serial.println(usbMIDI.getData2());
    float velocity = usbMIDI.getData2();
    float noteOn = 0.0;
    if (velocity > 0.0) {
      noteOn = 1.0;
    }

    float frequency = 440.0 * pow(2.0, (usbMIDI.getData1() - 69.0) / 12.0);
    myDsp.setParamValue("gate", noteOn);
    myDsp.setParamValue("freq", frequency);
    myDsp.setParamValue("gain", velocity / 127.0); // normalization
  }
}