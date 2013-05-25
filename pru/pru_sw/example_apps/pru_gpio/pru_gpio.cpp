/* This is an example that uses the PRU of the AM335 on the BeagleBone Black
 * to access GPIO.
 * 
 * This code is based on the PRU examples as well as the DMX example from
 * boxysean and probably many other pieces of code that I found during
 * my research.
 * 
 * This is intened mostly to learn about the PRU but also as a much higher
 * performance access to the GPIO pins rather than through the standard
 * linux GPIO interface.
 * 
 * I was unable to get the GPIO interface to mmmap after much trying 
 * and decided to use the PRU.
 *
 * This code is mostly hacked together so use at your own risk.
 */

#define _XOPEN_SOURCE 500


/*****************************************************************************
* Include Files                                                              *
*****************************************************************************/

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

#include <dirent.h>
#include <signal.h>

// Driver header file
#include <prussdrv.h>
#include <pruss_intc_mapping.h>

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>

/*****************************************************************************
* Local Macro Declarations                                                   *
*****************************************************************************/

#define PRU_NUM 	0

// This pin is GPIO1_28 pin 12 on the P9 header
#define DHT_PIN (28)

#define CMD_VALUE     	1
#define CMD_PARAMETER 	2      //Memory OFFSET for the parameter
#define CMD_RESULT    	3      //Response back to application
//Command values to be placed in the CMD_VALUE byte to control the PRU
#define CMD_NO_OP	2
#define CMD_SET_PIN     3
#define CMD_CLEAR_PIN   4
#define CMD_READ_PIN    5

#define AM33XX

/*****************************************************************************
* Local Function Declarations                                                *
*****************************************************************************/

static int LOCAL_exampleInit ();
static void LOCAL_export_pin (int pin,char* direction);
static void LOCAL_unexport_pin (int pin);

/*****************************************************************************
* Global Variable Definitions                                                *
*****************************************************************************/

static volatile void *pruDataMem;
static volatile unsigned char *pruDataMem_byte;

//GPIO Functions.  Specify the pin number within GPIO1
void set_pin(int pin);
void clear_pin(int pin);
char read_pin(int pin);

int read_dht11(char *data); 


/*****************************************************************************
* Global Function Definitions                                                *
*****************************************************************************/

int main (void)
{
    unsigned int ret, i, j, k;
    tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;
    
    printf("\nINFO: Starting %s example.\r\n", "pru_gpio");
    /* Initialize the PRU */
    prussdrv_init ();		

    //NOTE : The PRU code does not export the PIN so this must be
    //done for any pin that used.
    LOCAL_export_pin(32 + 16,"out"); //GPIO1_16
    LOCAL_export_pin(32 + 13,"in");  //GPIO1_13

    /* Open PRU Interrupt */
    ret = prussdrv_open(PRU_EVTOUT_0);
    if (ret)
    {
        printf("prussdrv_open open failed\n");
        return (ret);
    }
    
    /* Get the interrupt initialized */
    prussdrv_pruintc_init(&pruss_intc_initdata);

    /* Initialize example */
    printf("\tINFO: Initializing example.\r\n");
    LOCAL_exampleInit();

    //Start th emain loop
    pruDataMem_byte[CMD_VALUE] = CMD_NO_OP;
    
    /* Execute example on PRU */
    printf("\tINFO: Executing example.\r\n");
    prussdrv_exec_program (PRU_NUM, "./pru_gpio.bin");

    //The PRU is just configured to use GPIO1 for now.  This can be changed easily in the assembly.
    set_pin(16); //GPIO1_16
    clear_pin(16);
    int value = read_pin(13); //GPIO1_13

    printf("PIN value is %d\n",value); 

    printf("\tINFO: PRU completed transfer.\r\n");
    prussdrv_pru_clear_event (PRU0_ARM_INTERRUPT);

    /* Disable PRU and close memory mapping*/
    prussdrv_pru_disable (PRU_NUM);
    prussdrv_exit ();

    LOCAL_unexport_pin(38);

    return(0);

}

void set_pin(int pin)
{
   pruDataMem_byte[CMD_PARAMETER] = pin;
   pruDataMem_byte[CMD_VALUE] = CMD_SET_PIN;
   while(pruDataMem_byte[CMD_VALUE] != CMD_NO_OP);
}

void clear_pin(int pin)
{
   pruDataMem_byte[CMD_PARAMETER] = pin;
   pruDataMem_byte[CMD_VALUE] = CMD_CLEAR_PIN;
   while(pruDataMem_byte[CMD_VALUE] != CMD_NO_OP);
}

char read_pin(int pin)
{
   pruDataMem_byte[CMD_PARAMETER] = pin;
   pruDataMem_byte[CMD_VALUE] = CMD_READ_PIN;
   pruDataMem_byte[CMD_PARAMETER] = pin;
   while(pruDataMem_byte[CMD_VALUE] != CMD_NO_OP);
   return(pruDataMem_byte[CMD_RESULT]);
}
/*****************************************************************************
* Local Function Definitions                                                 *
*****************************************************************************/

static int LOCAL_exampleInit ()
{  
    int i;

    prussdrv_map_prumem (PRUSS0_PRU0_DATARAM,(void**) &pruDataMem);
    pruDataMem_byte = (unsigned char*) pruDataMem;

    pruDataMem_byte[CMD_VALUE] = CMD_NO_OP;
    pruDataMem_byte[CMD_PARAMETER] = 0;
    pruDataMem_byte[CMD_RESULT] = 0;

    return(0);
}

static void LOCAL_export_pin (int pin, char *dir) {
	FILE *file;
	char dir_file_name[50];

	// Export the GPIO pin
	file = fopen("/sys/class/gpio/export", "w");
	fprintf(file, "%d", pin);
	fclose(file);

	// Let GPIO know what direction we are writing
	sprintf(dir_file_name, "/sys/class/gpio/gpio%d/direction", pin);
	file = fopen(dir_file_name, "w");
	fprintf(file, "%s",dir);
	fclose(file);
}

static void LOCAL_unexport_pin (int pin) {
	FILE *file;
	file = fopen("/sys/class/gpio/unexport", "w");
	fwrite(&pin, 4, 1, file);
	fclose(file);
}





