/*************************************************
Maple compatible driver for MMA8452 accelerometer.

This code was cribbed from example code found at:
https://www.sparkfun.com/products/10955

by David Cranor
cranor@media.mit.edu
9.20.2013
**************************************************/

// The SparkFun breakout board defaults to 1, set to 0 if SA0 jumper on the bottom of the board is set
#define MMA8452_ADDRESS 0x1D  // 0x1D if SA0 is high, 0x1C if low

//Define a few of the registers that we will be accessing on the MMA8452
#define OUT_X_MSB 0x01
#define XYZ_DATA_CFG  0x0E
#define WHO_AM_I   0x0D
#define CTRL_REG1  0x2A

#define GSCALE 2 // Sets full-scale range to +/-2, 4, or 8g. Used to calc real g values.

void readAccelData(int *destination);
void readRegisters(byte addressToRead, int bytesToRead, byte * dest);
void initMMA8452();
void MMA8452Standby();
void MMA8452Active();
void writeRegister(byte addressToWrite, byte dataToWrite);
byte readRegister(byte addressToRead);


void readAccelData(int *destination)
{
  byte rawData[6];  // x/y/z accel register data stored here

  readRegisters(OUT_X_MSB, 6, rawData);  // Read the six raw data registers into data array

  // Loop to calculate 12-bit ADC and g value for each axis
  for(int i = 0; i < 3 ; i++)
  {
    //Combine the two 8 bit registers into one 12-bit number
    int gCount = (rawData[i*2] << 8) | rawData[(i*2)+1];  
   
    //The registers are left align, here we right align the 12-bit integer
    gCount >>= 4; 
    
    
    //Normalize to middle of range
    if(gCount >= 2048)
    {
      
      gCount = 2048 - (4096 - gCount);
      
    } else if (gCount <= 2048) {
      
      gCount = 2048 + gCount;
      
    }
    destination[i] = gCount; //Record this gCount into the 3 int array
  }
}

// Read bytesToRead sequentially, starting at addressToRead into the dest byte array
void readRegisters(byte addressToRead, int bytesToRead, byte * dest)
{
  Wire.beginTransmission(MMA8452_ADDRESS);
  Wire.send(addressToRead);
  Wire.endTransmission(false); //endTransmission but keep the connection active

  Wire.requestFrom(MMA8452_ADDRESS, bytesToRead); //Ask for bytes, once done, bus is released by default

  while(Wire.available() < bytesToRead); //Hang out until we get the # of bytes we expect

  for(int x = 0 ; x < bytesToRead ; x++)
    dest[x] = Wire.receive();  
}

void initMMA8452()
{
  byte c = readRegister(WHO_AM_I);  // Read WHO_AM_I register
  if (c == 0x2A) // WHO_AM_I should always be 0x2A
  {  
    //SerialUSB.println("MMA8452Q is online...");
  }
  else
  {
    //SerialUSB.print("Could not connect to MMA8452Q: 0x");
    //SerialUSB.println(c, HEX);
    while(1)  // Loop forever if communication doesn't happen
    {
      delay(20);
      toggleLED();   
    } 
  }

  MMA8452Standby();  // Must be in standby to change registers

  // Set up the full scale range to 2, 4, or 8g.
  byte fsr = GSCALE;
  if(fsr > 8) fsr = 8; //Easy error check
  fsr >>= 2; // Neat trick, see page 22. 00 = 2G, 01 = 4A, 10 = 8G
  writeRegister(XYZ_DATA_CFG, fsr);

  //The default data rate is 800Hz and we don't modify it in this example code

  MMA8452Active();  // Set to active to start reading
}

// Sets the MMA8452 to standby mode. It must be in standby to change most register settings
void MMA8452Standby()
{
  byte c = readRegister(CTRL_REG1);
  writeRegister(CTRL_REG1, c & ~(0x01)); //Clear the active bit to go into standby
}

void MMA8452Active()
{
  byte c = readRegister(CTRL_REG1);
  writeRegister(CTRL_REG1, c | 0x01); //Set the active bit to begin detection
}

// Writes a single byte (dataToWrite) into addressToWrite
void writeRegister(byte addressToWrite, byte dataToWrite)
{
  Wire.beginTransmission(MMA8452_ADDRESS);
  Wire.send(addressToWrite);
  Wire.send(dataToWrite);
  Wire.endTransmission(); //Stop transmitting
}

// Read a single byte from addressToRead and return it as a byte
byte readRegister(byte addressToRead)
{
  
  //SerialUSB.println("Starting transmission...");
  Wire.beginTransmission(MMA8452_ADDRESS);
  
  //SerialUSB.println("Loading address into send buffer...");
  Wire.send(addressToRead); //changed
  
  //SerialUSB.println("Sending everything and ending transmission...");
  Wire.endTransmission(false); //endTransmission but keep the connection active

  //SerialUSB.println("Ask for one byte...");
  Wire.requestFrom(MMA8452_ADDRESS, 1); //Ask for 1 byte, once done, bus is released by default

  //SerialUSB.println("Reading data...");
  while(!Wire.available()) ; //Wait for the data to come back
  return Wire.receive(); //Return this one byte
}
