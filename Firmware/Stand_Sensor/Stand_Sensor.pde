/**********************************************************
Firmware for accelerometer-based sit/stand sensor and 
electrolaminate driver

NOTES:
 
-Make sure that you have my hacked up version of
 the Wire library installed, as we need repeated start I2C.
 To insatll it, make  backup of the old files and copy my 
 Wire.cpp and Wire.h over them in the
 MapleIDE.app/Contents/Resources/Java/libraries/Wire/
 directory (If you're on Mac).
 
 This is a gross hack, sorry.
  
 -When uploading firmware, remember to build/install
  the Maple Mini target.
  
by David Cranor
cranor@media.mit.edu
9.20.2013
***********************************************************/

#include <Wire.h> // Used for I2C
#include "MMA8452.h"

//Enable/disable debug output.  Only enable when connected to computer
//and reading termainal output.  Things get weird if you try
//to print to the USB terminal without opening the port in terminal first.
int DEBUG = 0;

//Moving average buffer
int BUFFER_LENGTH = 16;

//Determined emperically in debug mode
//Strap enclosure to outside of left thigh, phono jacks facing up.
int X_THRESHOLD = 1400;

//Output LED and serial debug data framerate, 30Hz
int OUTPUT_PERIOD_US = 33333;

//Sample framerate, 120Hz
int SAMPLE_PERIOD_US = 8333;

//Blinky LED
int LED_PIN = BOARD_LED_PIN;

//5V output driver, inverted signal
int OUTPUT_PIN = 12;

//5V supply control
int EN_PIN = 1;
int PS_PIN = 0;

//Not used
int POWER_SENSE_PIN = 19;
int FSR_PIN = 6;

int rawAccel[3];  // x/y/z raw accelerometer values. 12 bits.
int accelBuffer[3][16];  //Dimension must match BUFFER_LENGTH
int bufferPointer = 0;
int averageAccel[3];

HardwareTimer outputTimer(1);
HardwareTimer sampleTimer(2);

void setup()
{

  //Delay 2 seconds to give a chance to open serial window for debugging
  delay(2000);

  //Configure pins
  pinMode(LED_PIN, OUTPUT);
  pinMode(OUTPUT_PIN, OUTPUT);
  pinMode(POWER_SENSE_PIN, INPUT);
  pinMode(FSR_PIN, INPUT_ANALOG);
  pinMode(EN_PIN, OUTPUT);
  pinMode(PS_PIN, OUTPUT);

  //Turn on the 5V supply, turn off driver output
  digitalWrite(EN_PIN, HIGH);
  digitalWrite(OUTPUT_PIN, HIGH);

  //Join the bus as a master
  Wire.begin(); 

  //Test and intialize the MMA8452
  initMMA8452(); 

  //Init the timers and timer interrupts
  initTimers();  

}

void loop()
{

  if(standDetected())
  {

    //Activate output driver
    digitalWrite(OUTPUT_PIN, LOW);

  } else {

    digitalWrite(OUTPUT_PIN, HIGH);

  }

}

void initTimers()
{

  //********OUTPUT TIMER SETUP************

  //Setup the output timer
  outputTimer.pause();

  //Set up period
  outputTimer.setPeriod(OUTPUT_PERIOD_US); //in microseconds

  // Set up an interrupt on channel 1
  outputTimer.setChannel1Mode(TIMER_OUTPUT_COMPARE);
  outputTimer.setCompare(TIMER_CH1, 1);  // Interrupt 1 count after each update
  outputTimer.attachCompare1Interrupt(handler_UI_update);

  // Refresh the timer's count, prescale, and overflow
  outputTimer.refresh();

  // Start the timer counting
  outputTimer.resume();

  //********SAMPLE TIMER SETUP**********

  //Set up the sampling/averaging timer
  sampleTimer.pause();

  //Set up period
  sampleTimer.setPeriod(SAMPLE_PERIOD_US); //in microseconds

  // Set up an interrupt on channel 1
  sampleTimer.setChannel1Mode(TIMER_OUTPUT_COMPARE);
  sampleTimer.setCompare(TIMER_CH1, 1);  // Interrupt 1 count after each update
  sampleTimer.attachCompare1Interrupt(handler_sensors_update);

  // Refresh the timer's count, prescale, and overflow
  sampleTimer.refresh();

  // Start the timer counting
  sampleTimer.resume();
}

int standDetected()
{

  if(averageAccel[0] >= X_THRESHOLD)
  {
    return 1;
  }  

  return 0;
}

void handler_sensors_update()
{  

  int total;

  //Read the x/y/z adc values and add them to circular buffer
  readAccelData(rawAccel);  

  for(int i = 0; i < 3; i++)
  {
    accelBuffer[i][bufferPointer] = rawAccel[i];

    bufferPointer = bufferPointer + 1;
    if(bufferPointer >= BUFFER_LENGTH)
    {
      bufferPointer = 0;
    }

  }

  //update the moving average
  for(int i = 0; i < 3; i++)
  {

    total = 0;

    for(int j = 0; j < BUFFER_LENGTH; j++)
    {
      total = total + accelBuffer[i][j];
    }

    averageAccel[i] = total / BUFFER_LENGTH;

  }
}


void handler_UI_update()
{

  if(standDetected())
  {

    digitalWrite(LED_PIN, HIGH);

  } else {

    digitalWrite(LED_PIN, LOW);

  }

  if(DEBUG)
  {  
    
    for (int i = 0 ; i < 3 ; i++)
    {
      SerialUSB.print(averageAccel[i]);  // Print g values (full 16 bits)
      SerialUSB.print('\t');
    }
    
  }

  if(DEBUG)
  {
    SerialUSB.println();
  }  

}



