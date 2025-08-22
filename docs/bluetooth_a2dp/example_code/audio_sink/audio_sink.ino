/*
  Streaming Music from Bluetooth (modified from original)
  Originally written by Phil Schatzmann and modified by Asami De Almeida

  Copyright (C) 2020 Phil Schatzmann, 2025 Asami De ALmeida
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "AudioTools.h"
#include "BluetoothA2DPSink.h"

I2SStream out;
BluetoothA2DPSink a2dp_sink(out);

void setup() {
  Serial.begin(115200);
  Serial.println("Starting Step 1");
  AudioToolsLogger.begin(Serial, AudioLogger::Info);
  Serial.println("Finished Step 1");

  // Configure i2s
  Serial.println("Starting Step 2");
  auto cfg = out.defaultConfig(TX_MODE);
  out.begin(cfg);
  Serial.println("Finished Step 2");

    // start a2dp
  Serial.println("Starting Step 3");
  a2dp_sink.start("AudioKit", true);
  Serial.println("Finished Step 3");
  
  a2dp_sink.play();
}


void loop() {
  delay(1000); // do nothing
}