#include <pcmConfig.h>
#include <pcmRF.h>
#include <TMRpcm.h>
#include <SD.h>               // need to include the SD library
#define SD_ChipSelectPin 10   // SD_CS varies by manufacture set this for your CD card interface unit
#include <TMRpcm.h>           //  also need to include this library...
#include <SPI.h>

TMRpcm tmrpcm;   // create an object for use in this sketch

unsigned long time = 0;
#define WAVFILE "bonanza.wav"

void setup(){

  tmrpcm.speakerPin = 9; //5,6,11 or 46 on Mega, 9 on Uno, Nano, etc for speaker output
  
  Serial.begin(9600);
  //pinMode(13,OUTPUT); //LED Connected to analog pin 0
  if (!SD.begin(SD_ChipSelectPin)) {  // see if the card is present and can be initialized:
    Serial.println("SD fail");
    return;   // don't do anything more if not
  }
  else{   
    Serial.println("SD ok");
    Serial.println("SystemBooted");   
  }
  tmrpcm.loop(1); //loop the following file in playback
  tmrpcm.play(WAVFILE); //the sound file will play each time the arduino powers up, or is reset
}
//the following is just for debug and troubleshooting, this is not required for production
void loop(){  
  if(Serial.available()){    
    switch(Serial.read()){
    case 'P': tmrpcm.play(WAVFILE); break;
    case 'p': tmrpcm.pause(); break;
    case 'L': tmrpcm.loop(1); break;
    case 'l': tmrpcm.loop(0); break; //lowercase L
    case '?': if(tmrpcm.isPlaying()){ Serial.println("A wav file is being played");} break;
    case '=': tmrpcm.volume(1); break;
    case '-': tmrpcm.volume(0); break;
    case '0': tmrpcm.quality(0); break;
    case '1': tmrpcm.quality(1); break; //number one
    default: break;
    }
  }

}
