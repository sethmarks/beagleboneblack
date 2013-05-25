.origin 0
.entrypoint START

#include "pru_gpio.hp"

#define GPIO1             0x4804c000
#define GPIO_DATAIN       0x138
#define GPIO_CLEARDATAOUT 0x190
#define GPIO_SETDATAOUT   0x194

#define CMD_VALUE     (1)
#define CMD_PARAMETER (2)      //Memory OFFSET for the parameter
#define CMD_RESULT    (3)      //Response back to application

#define CMD_NO_OP         2
#define CMD_SET_PIN       3
#define CMD_CLEAR_PIN     4
#define CMD_READ_PIN      5


.macro SLEEPUS
.mparam us,inst,lab
    MOV r7, (us*100)-1-inst
lab:
    SUB r7, r7, 1
    QBNE lab, r7, 0
.endm


START:
    // Configure the block index register for PRU0 by setting c24_blk_index[7:0] and
    // c25_blk_index[7:0] field to 0x00 and 0x00, respectively.  This will make C24 point
    // to 0x00000000 (PRU0 DRAM) and C25 point to 0x00002000 (PRU1 DRAM).
    MOV       r0, 0x00000000
    MOV       r1, CTBIR_0
    ST32      r0, r1

    //Not really sure what this is...
    LBCO r0, C4, 4, 4
    CLR r0, r0, 4
    SBCO r0, C4, 4, 4


    //NOTE: The appliaction should clear the pin as the first instruction
    //for some reason clearing the PIN enables the output.....

MAIN:
    //DEBUG: Pull pin GPIO1_13 high 
//    MOV r4, 1
//    LSL r4, r4, 13 
//    MOV r6, GPIO1 | GPIO_SETDATAOUT
//    SBBO r4, r6, 0, 4
//    SLEEPUS 10, 1, START_HIGH_SLEEP
//    MOV r6, GPIO1 | GPIO_CLEARDATAOUT
//    SBBO r4, r6, 0, 4

    // Keep checking for a command until the value isnt a no-op
    MOV r6, CMD_VALUE                   //Pull in the offset for the command into r6
    LBCO r2, CONST_PRUDRAM, r6, 1       //Pull the value of the command into r2
    QBEQ MAIN, r2.b0, CMD_NO_OP         //If the first byte of r2 is CMD_NO_OP then goto START

    //Now we have a valid command
    QBEQ SET_PIN, r2.b0, CMD_SET_PIN    //If the first byte of r2 is CMD_SET_PIN then goto SET_PIN
    QBEQ CLEAR_PIN, r2.b0, CMD_CLEAR_PIN//If the first byte of r2 is CMD_CLEAR_PIN then goto CLEAR_PIN
    QBEQ READ_PIN, r2.b0, CMD_READ_PIN  //If the first byte of r2 is CMD_READ_PIN then goto READ_PIN
    //If it isnt a valid command then jump back to MAIN
//MOV r6, GPIO1 | GPIO_CLEARDATAOUT
//SBBO r4, r6, 0, 4
    QBA MAIN                            //Jump to MAIN
    

SET_PIN:
    //DEBUG: Set pin GPIO1_13 low
//    MOV r6, GPIO1 | GPIO_CLEARDATAOUT
//    SBBO r4, r6, 0, 4
    //SLEEPUS 100, 1, START_LOW_SLEEP

    MOV r6, CMD_PARAMETER               //Load the Parameter offset value into r6
    LBCO r2, CONST_PRUDRAM, r6, 1       //Load 1 byte of data from CONST_PRUDRAM+R6 into r2.  Now r2 has the parameter.
    MOV r4, 1                           //Load a 1 into r4
    LSL r4, r4, r2.b0                   //Take the first byte of r2 and shift r4 by that many bits left. 
                                        //This assumes the parameter is a pin number and sets the nth bit (e.g. bit 13 for GPIO_13)
    MOV r6, GPIO1 | GPIO_SETDATAOUT     //Load r6 with the address of the SETDATAOUT word for GPIO1
    SBBO r4, r6, 0, 4                   //Load all four bytes from r4 (pin bitmask) into r6 (SETDATAOUT) thus setting the bit high

    //Store into RAM[RESULT+4] the pin number
    MOV r6, CMD_RESULT                  //Put the offset of the result location into r6
    ADD r6, r6, 4
    SBCO r2.b0, CONST_PRUDRAM, r6, 1

    QBA CMD_DONE                        //Signal done and then return to MAIN


CLEAR_PIN:
    //DEBUG: Set pin GPIO1_13 low
//    MOV r6, GPIO1 | GPIO_CLEARDATAOUT
//    SBBO r4, r6, 0, 4
    //SLEEPUS 100, 1, START_LOW_SLEEP

    MOV r6, CMD_PARAMETER               //Load the Parameter offset value into r6
    LBCO r2, CONST_PRUDRAM, r6, 1       //Load 1 byte of data from CONST_PRUDRAM+R6 into r2.  Now r2 has the parameter.
    MOV r4, 1                           //Load a 1 into r4
    LSL r4, r4, r2.b0                   //Take the first byte of r2 and shift r4 by that many bits left. 
                                        //This assumes the parameter is a pin number and sets the nth bit (e.g. bit 13 for GPIO_13)
    MOV r6, GPIO1 | GPIO_CLEARDATAOUT   //Load r6 with the address of the CLEARDATAOUT word for GPIO1
    SBBO r4, r6, 0, 4                   //Load all four bytes from r4 (pin bitmask) into r6 (CLEARDATAOUT) thus setting the bit low

    //Store into RAM[RESULT+4] the pin number
    MOV r6, CMD_RESULT                  //Put the offset of the result location into r6
    ADD r6, r6, 4
    SBCO r2.b0, CONST_PRUDRAM, r6, 1

    QBA CMD_DONE                        //Signal done and then return to MAIN

READ_PIN:
    //DEBUG: Pull pin GPIO1_16 high
    MOV r4, 1
    LSL r4, r4, 13
    MOV r6, GPIO1 | GPIO_SETDATAOUT
    SBBO r4, r6, 0, 4
    SLEEPUS 2, 1, START_HIGH_SLEEP
    MOV r6, GPIO1 | GPIO_CLEARDATAOUT
    SBBO r4, r6, 0, 4

    //DEBUG: Set pin GPIO1_13 low
//    MOV r6, GPIO1 | GPIO_CLEARDATAOUT
//    SBBO r4, r6, 0, 4
    //SLEEPUS 100, 1, START_LOW_SLEEP

    MOV r6, CMD_PARAMETER               //Load the Parameter offset value into r6
    LBCO r2, CONST_PRUDRAM, r6, 1       //Load 1 byte of data from CONST_PRUDRAM+R6 into r2.  Now r2 has the parameter.
    MOV r4, 1                           //Load a 1 into r4
    LSL r4, r4, r2.b0                   //Take the first byte of r2 and shift r4 by that many bits left. 
                                        //This assumes the parameter is a pin number and sets the nth bit (e.g. bit 13 for GPIO_13)
    MOV r6, GPIO1 | GPIO_DATAIN         //Load r6 with the address of the DATAIN word for GPIO1
    LBBO r3, r6, 0, 4                   //Load all four bytes from r6 (DATAIN) into r3
    LSR r4, r3, r2.b0                   //Right shift the result into the least significant bit
    AND r4, r4, 1                       //Mask off all the upper bits
    MOV r6, CMD_RESULT                  //Put the offset of the result location into r6
    SBCO r4, CONST_PRUDRAM, r6, 4       //Store 1 byte from r4 into PDU RAM offset r6.  Store the results into the CMD_RESULT word
    //Store into RAM[RESULT+4] the pin number
    ADD r6, r6, 4
    SBCO r2.b0, CONST_PRUDRAM, r6, 1
//    MOV R31.b0, PRU0_ARM_INTERRUPT+16   // Send notification to Host for program completion
    QBA CMD_DONE                        //Signal done and then return to MAIN


CMD_DONE:
    //Signal done by writing NO_OP into the command
    MOV r3, CMD_NO_OP                   //Put the NO_OP command into r3
    MOV r5, CMD_VALUE                   //Put the CMD_VALUE offset into r5
    SBCO r3, CONST_PRUDRAM, r5, 1       //Overwrite the CMD_VALUE (r5) with the NO_OP
    QBA MAIN                            //Return to MAIN
        
