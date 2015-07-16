#include "FastLED.h"

CRGB leds[1];


void setup() {

  FastLED.addLeds<NEOPIXEL, 6>(leds, 1);
  
}


void loop() {
  
}
