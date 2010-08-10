// Based on Timer UART code by L. Westlund at Texas Instruments from the IAR Embedded Workbench examples

#include  <msp430x42x0.h>

#define RXD   0x02    // RXD on P1.1
#define TXD   0x01    // TXD on P1.0

//  Conditions for 115200 Baud SW UART, SMCLK = 1048576

#define Bitime_5  0x024  // ~ 0.5 bit length + small adjustment
#define Bitime    0x045  // 8.6 us bit length ~ 115942 baud

unsigned int TXData;
unsigned int RXData;
unsigned int sampData;
unsigned int ledOffData_1;
unsigned int ledOffData_2;
unsigned char BitCnt;

void TX_Byte (unsigned char data);
void RX_Ready (void);
void Capture_Data (double i);
void Sample_Data (void);

void main (void)
{
  WDTCTL = WDTPW + WDTHOLD; // Stop watchdog timer
  FLL_CTL0 |= DCOPLUS + XCAP14PF; // DCO+, Configure load caps
  SCFI0 |= FN_4;       // x2 DCO frequency, 8MHz nominal
  SCFQCTL = 121;       // (121+1) x 32768 x 2 = 7.99 MHz
  CCTL0 = OUT;         // TXD Idle as Mark
  TACTL = TASSEL_2 + MC_2; // SMCLK, continuous mode
  
  P1SEL = TXD + RXD;   // P1.0/1 TA0 for TXD/RXD function
  P1DIR = TXD;         // TXD output on P1
  
  SD16CTL = SD16REFON + SD16SSEL_1;// Use 1.2V ref, ACLK
  SD16INCTL0 = SD16INCH_0;      // SD16 A0+/-
  SD16CCTL0 =  SD16UNI + SD16SNGL;// Unipolar, Single Conversion
  SD16AE = SD16AE0 + SD16AE2;   // A0/1+ = Signal, A0/1- = VSS 
  
  P6DIR |= 0x10;
  P6DIR |= 0x20;
  P1DIR |= 0x10;
  //P1OUT ^= 0x10;
  
  unsigned char test = '!';
  double sample = 2000;
  // Mainloop
  for (;;)
  {
    RX_Ready();            // UART ready to RX one Byte
    _BIS_SR(CPUOFF + GIE); // Enter LPM0 Until character RXed
    switch (RXData) {
    case 'T':
      TX_Byte(test);
      break;
    case 'S':
      Capture_Data(sample);
      break;
    default:
     /* if (RXData >= '0' && RXData <= '9'){
        sample = sample*10 +  (int)RXData - 48;
        TX_Byte ((int)sample);
      }*/
      break;
    }
  }
}

void Capture_Data (double i) {
  volatile double n;
  for (n=0;n<=i; n++){
  /** ALL OFF **/
    P6OUT = 0x00;      // Just to make sure
    __delay_cycles (6667);  // delay for ~ 10/12 ms 
    // 1 - OPT101 
    SD16INCTL0 = SD16INCH_0; // SD16 A0+/-
    SD16CCTL0 |= SD16SC;     // Read the sample
    while((SD16CCTL0 & SD16IFG) == 0); // Wait until ready
    ledOffData_1 = SD16MEM0;
    // 2 - OPT101
    SD16INCTL0 = SD16INCH_1; // SD16 A1+/-
    SD16CCTL0 |= SD16SC;     // Read the sample
    while((SD16CCTL0 & SD16IFG) == 0); // Wait until ready
    ledOffData_2 = SD16MEM0;
    
  /** 750 nm **/
    P6OUT = 0x10;
    __delay_cycles (6667); // delay for ~ 10/12 ms
    Sample_Data ();
    
  /** 850 nm **/
    P6OUT = 0x20;
    __delay_cycles (6667); // delay for ~ 10/12 m
    Sample_Data ();
    
    P6OUT= 0x00;
    __delay_cycles (6667); // delay for ~ 10/12 ms
  }
}

void Sample_Data (void) {
  // 1 - OPT101 
  SD16INCTL0 = SD16INCH_0;             // SD16 A0+/-
  SD16CCTL0 |= SD16SC;                 // Read the sample
  while((SD16CCTL0 & SD16IFG) == 0);  // Wait until ready
  sampData = SD16MEM0 - ledOffData_1;       
  TX_Byte ((sampData >> 8) & 0x00FF);  // Tx high order byte
  TX_Byte ((sampData) & 0x00FF);       // Tx low order byte
  
  // 2 - OPT101
  SD16INCTL0 = SD16INCH_1;             // SD16 A1+/-
  SD16CCTL0 |= SD16SC;                 // Read the sample
  while((SD16CCTL0 & SD16IFG) == 0);  // Wait until ready
  sampData = SD16MEM0 - ledOffData_2;
  TX_Byte ((sampData >> 8) & 0x00FF);  // Tx high order byte
  TX_Byte ((sampData) & 0x00FF);       // Tx low order byte 
}

// Function Transmits Character from data
void TX_Byte (unsigned char data){
  TXData = data;
  BitCnt = 0xA;    // Load Bit counter, 8data + ST/SP
  CCR0 = TAR;      // Current state of TA counter
  CCR0 += Bitime;  // Some time till first bit
  TXData |= 0x100; // Add mark stop bit to RXTXData
  TXData = TXData << 1;  // Add space start bit
  CCTL0 = OUTMOD0 + CCIE; // TXD = mark = idle
  while ( CCTL0 & CCIE ); // Wait for TX completion
}


// Function Readies UART to Receive Character into RXData Buffer
void RX_Ready (void){
  BitCnt = 0x8;        // Load Bit counter
  // Sync, Neg Edge, Capture
  CCTL0 = SCS + CCIS0 + OUTMOD0 + CM1 + CAP + CCIE;  
}


// Timer A0 interrupt service routine
#pragma vector=TIMERA0_VECTOR
__interrupt void Timer_A (void) {
  CCR0 += Bitime;             // Add Offset to CCR0
  // RX
  if (CCTL0 & CCIS0) {       // RX on CCI0B?
    if( CCTL0 & CAP ) {      // Capture mode = start bit edge
      CCTL0 &= ~ CAP;        // Capture to compare mode
      CCR0 += Bitime_5;
    } else {
      RXData = RXData >> 1;
      if (CCTL0 & SCCI)     // Get bit waiting in receive latch
        RXData |= 0x80;
      BitCnt --;            // All bits RXed?
      if ( BitCnt == 0) {
        CCTL0 &= ~ CCIE;    // All bits RXed, disable interrupt
        _BIC_SR_IRQ(CPUOFF) // Clear LPM0 bits from 0(SR)
      }
    }
  } else { //TX
    if ( BitCnt == 0)
      CCTL0 &= ~ CCIE;      // All bits TXed, disable interrupt
    else {
      CCTL0 |=  OUTMOD2;    // TX Space
      if (TXData & 0x01)
        CCTL0 &= ~ OUTMOD2; // TX Mark
      TXData = TXData >> 1;
      BitCnt --;
    }
  }
}
