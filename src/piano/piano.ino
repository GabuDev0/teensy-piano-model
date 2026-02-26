#include <Audio.h>
#include "pianoModel.h"
#include "math.h"

#define NUM_VOICES 8

int current_voice = 0;
int voices[NUM_VOICES]; // voices[0] = midi_note
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

  // *** Teensy usb midi set handle functions ***
  usbMIDI.setHandleNoteOn(onNoteON);
  usbMIDI.setHandleNoteOff(onNoteOFF);
  usbMIDI.setHandleControlChange(onControleChange);
}
void onControleChange(byte channel, byte control, byte value) {
  Serial.print("Channel: ");
  Serial.print(channel);
  Serial.print(" Control ");
  Serial.print(control);
  Serial.print(" Value: ");
  Serial.println(value);

  // The CC70 knob
  if (control == 70) {
    myDsp.setParamValue("brightness", value/127.0);
  }
}

void onNoteON(byte channel, byte note, byte velocity) {
  Serial.print("Voice number: ");
  Serial.print(current_voice);
  Serial.print(" Channel: ");
  Serial.print(channel);
  Serial.print(" Data1: ");
  Serial.print(note);
  Serial.print(" Data2: ");
  Serial.println(velocity);
  float velocityNormalized = velocity / 127.0;

  Serial.print(" VelocityNormalized ");
  Serial.println(velocityNormalized);

  // Frequency computation from midi note id
  float frequency = 440.0 * pow(2.0, (note - 69.0) / 12.0);


  char paramGate[16];
  snprintf(paramGate, sizeof(paramGate), "gate%d", current_voice);

  char paramFreq[16];
  snprintf(paramFreq, sizeof(paramFreq), "freq%d", current_voice);

  char paramGain[16];
  snprintf(paramGain, sizeof(paramGain), "gain%d", current_voice);
  

  myDsp.setParamValue(paramGate, 1.0);
  myDsp.setParamValue(paramFreq, frequency);
  myDsp.setParamValue(paramGain, velocityNormalized); // normalization

  voices[current_voice] = note;
  Serial.print(" Voices[current_voice]: " );
  Serial.println(voices[current_voice]);

  // Use next voice
  current_voice += 1;
  if (current_voice >= NUM_VOICES) {
    current_voice = 0;
  }
  
}
void onNoteOFF(byte channel, byte note, byte velocity) {
  for (int i = 0; i < NUM_VOICES; i++) {
    // Look for the played note in "voices"
    if (voices[i] == note && voices[i] != -1) {
      char paramGate[16];
      snprintf(paramGate, sizeof(paramGate), "gate%d", i);
      Serial.print("Note off: paramGate: ");
      Serial.println(paramGate);
      myDsp.setParamValue(paramGate, 0.0);
      voices[i] = -1;
    }
  }
}

void loop() {
  usbMIDI.read();
}