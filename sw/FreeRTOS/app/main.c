#include <FreeRTOS.h>
#include <task.h>
#include <queue.h>
#include <stdio.h>
#include "printf.h"
#include "riscv_csr_encoding.h"

#define FREQ_SYSTEM 50000000
#define BR_UART     115200

#define REAL_UART

#define ERR_CFG     0xFFFF0000
#define PRINT_ADDR  0xD0000008
#define LEDS_ADDR   0xD0000000
#define RST_CFG     0xC0000000
#define UART_TX     0xB000000C
#define UART_RX     0xB0000008
#define UART_STATS  0xB0000004
#define UART_CFG    0xB0000000

volatile uint32_t* const addr_leds  = (uint32_t*) LEDS_ADDR;
volatile uint32_t* const addr_print = (uint32_t*) PRINT_ADDR;
volatile uint32_t* const uart_stats = (uint32_t*) UART_STATS;
volatile uint32_t* const uart_print = (uint32_t*) UART_TX;
volatile uint32_t* const uart_rx    = (uint32_t*) UART_RX;
volatile uint32_t* const uart_cfg   = (uint32_t*) UART_CFG;
volatile uint32_t* const rst_cfg    = (uint32_t*) RST_CFG;
volatile uint32_t* const err_cfg    = (uint32_t*) ERR_CFG;

/* Run a simple demo just prints 'Blink' */
#define DEMO_BLINKY	1
/* Priorities used by the tasks. */
#define mainQUEUE_RECEIVE_TASK_PRIORITY		( tskIDLE_PRIORITY + 2 )
#define	mainQUEUE_SEND_TASK_PRIORITY		( tskIDLE_PRIORITY + 1 )
/* The rate at which data is sent to the queue.  The 200ms value is converted
to ticks using the pdMS_TO_TICKS() macro. */
#define mainQUEUE_SEND_FREQUENCY_MS			pdMS_TO_TICKS( 200 )
/* The maximum number items the queue can hold.  The priority of the receiving
task is above the priority of the sending task, so the receiving task will
preempt the sending task and remove the queue items each time the sending task
writes to the queue.  Therefore the queue will never have more than one item in
it at any time, and even with a queue length of 1, the sending task will never
find the queue full. */
#define mainQUEUE_LENGTH					( 1 )

void vApplicationMallocFailedHook( void );
void vApplicationIdleHook( void );
void vApplicationStackOverflowHook( TaskHandle_t pxTask, char *pcTaskName );
void vApplicationTickHook( void );
void vSendString( const char * const pcString );
uint8_t xGetCoreID(void);

int main_blinky( void );

#ifndef REAL_UART
void _putchar(char character){
  *addr_print = character;
}
#else
void _putchar(char character){
  while((*uart_stats & 0x10000) == 0);
  *uart_print = character;
}
#endif

void setup_nox(void){
  *uart_cfg = FREQ_SYSTEM/BR_UART;
}

int main( void )
{
	int ret;
  setup_nox();
	ret = main_blinky();
	return ret;
}

/*-----------------------------------------------------------*/
uint8_t xGetCoreID(void){
  return 0;
}

void vApplicationMallocFailedHook( void )
{
	/* vApplicationMallocFailedHook() will only be called if
	configUSE_MALLOC_FAILED_HOOK is set to 1 in FreeRTOSConfig.h.  It is a hook
	function that will get called if a call to pvPortMalloc() fails.
	pvPortMalloc() is called internally by the kernel whenever a task, queue,
	timer or semaphore is created.  It is also called by various parts of the
	demo application.  If heap_1.c or heap_2.c are used, then the size of the
	heap available to pvPortMalloc() is defined by configTOTAL_HEAP_SIZE in
	FreeRTOSConfig.h, and the xPortGetFreeHeapSize() API function can be used
	to query the size of free heap space that remains (although it does not
	provide information on how the remaining heap might be fragmented). */
	taskDISABLE_INTERRUPTS();
	for( ;; );
}
/*-----------------------------------------------------------*/

void vApplicationIdleHook( void )
{
	/* vApplicationIdleHook() will only be called if configUSE_IDLE_HOOK is set
	to 1 in FreeRTOSConfig.h.  It will be called on each iteration of the idle
	task.  It is essential that code added to this hook function never attempts
	to block in any way (for example, call xQueueReceive() with a block time
	specified, or call vTaskDelay()).  If the application makes use of the
	vTaskDelete() API function (as this demo application does) then it is also
	important that vApplicationIdleHook() is permitted to return to its calling
	function, because it is the responsibility of the idle task to clean up
	memory allocated by the kernel to any task that has since been deleted. */
}
/*-----------------------------------------------------------*/

void vApplicationStackOverflowHook( TaskHandle_t pxTask, char *pcTaskName )
{
	( void ) pcTaskName;
	( void ) pxTask;

	/* Run time stack overflow checking is performed if
	configCHECK_FOR_STACK_OVERFLOW is defined to 1 or 2.  This hook
	function is called if a stack overflow is detected. */
	taskDISABLE_INTERRUPTS();
  printf("\n\rStack Overflow task: ");
  vSendString(pcTaskName);
	for( ;; );
}
/*-----------------------------------------------------------*/

void vApplicationTickHook( void )
{
}
/*-----------------------------------------------------------*/

void vAssertCalled( void )
{
volatile uint32_t ulSetTo1ToExitFunction = 0;

	taskDISABLE_INTERRUPTS();
	while( ulSetTo1ToExitFunction != 1 )
	{
		__asm volatile( "NOP" );
	}
}

/* The queue used by both tasks. */
static QueueHandle_t xQueue = NULL;

/*-----------------------------------------------------------*/

static void prvQueueSendTask( void *pvParameters )
{
	TickType_t xNextWakeTime;
	unsigned long ulValueToSend = 0UL;

	/* Remove compiler warning about unused parameter. */
	( void ) pvParameters;
  uint32_t	free_heap_size;
	/* Initialise xNextWakeTime - this only needs to be done once. */
	/*xNextWakeTime = xTaskGetTickCount();*/
  /*printf("\n\rSend task: %d / %d",xNextWakeTime, mainQUEUE_SEND_FREQUENCY_MS);*/
	for( ;; )
	{

    /*vSendString("\n\r Task: prvQueueSendTask");*/
		/* Place this task in the blocked state until it is time to run again. */
    /*vTaskDelayUntil( &xNextWakeTime, mainQUEUE_SEND_FREQUENCY_MS );*/
    vTaskDelay(100);

		ulValueToSend++;
    free_heap_size = xPortGetFreeHeapSize();
		/*char buf[40];*/
		/*sprintf( buf, "%d: %s: send %ld", xGetCoreID(),*/
				/*pcTaskGetName( xTaskGetCurrentTaskHandle() ),*/
				/*ulValueToSend );*/
		/*vSendString( buf );*/
    /*asm volatile("add x0, 0(%[mbx])"::[mbx]"r"(&mbox_aligned_addr)*/
    /*asm volatile("sw sp, 0(%[val])"::[val]"r"(&free_heap_size));*/
    printf( "\n\r[%d] Tx: %d", free_heap_size, ulValueToSend );

		/* 0 is used as the block time so the sending operation will not block -
		 * it shouldn't need to block as the queue should always be empty at
		 * this point in the code. */
    xQueueSend( xQueue, &ulValueToSend, 0U );
	}
}

/*-----------------------------------------------------------*/

static void prvQueueReceiveTask( void *pvParameters )
{
	/* Remove compiler warning about unused parameter. */
	( void ) pvParameters;

  vSendString("\n\rReceive task");

	for( ;; )
	{

    /*vSendString("\n\r Task: prvQueueReceiveTask");*/
		unsigned long ulReceivedValue;
		/* Wait until something arrives in the queue - this task will block
		indefinitely provided INCLUDE_vTaskSuspend is set to 1 in
		FreeRTOSConfig.h. */
		xQueueReceive( xQueue, &ulReceivedValue, portMAX_DELAY );

    /*printf( "\n\rRx: %d", ulReceivedValue );*/
		/*  To get here something must have been received from the queue. */
		/*char buf[40];*/
		/*sprintf( buf, "%d: %s: received %ld", xGetCoreID(),*/
				/*pcTaskGetName( xTaskGetCurrentTaskHandle() ),*/
				/*ulReceivedValue );*/
		/*vSendString( buf );*/
	}
}

/*-----------------------------------------------------------*/

int main_blinky( void )
{
  if (configSUPPORT_DYNAMIC_ALLOCATION)
  	vSendString( "\n\rHello FreeRTOS!" );
  else
  	vSendString( "\n\rHello FreeRTOS! - No support" );

	/* Create the queue. */
	xQueue = xQueueCreate( mainQUEUE_LENGTH, sizeof( unsigned long ) );

	if( xQueue != NULL )
	{
		/* Start the two tasks as described in the comments at the top of this
		file. */
    xTaskCreate( prvQueueReceiveTask, "Rx", configMINIMAL_STACK_SIZE * 2U, NULL,
          mainQUEUE_RECEIVE_TASK_PRIORITY, NULL );
		xTaskCreate( prvQueueSendTask, "Tx", configMINIMAL_STACK_SIZE * 2U, NULL,
					mainQUEUE_SEND_TASK_PRIORITY, NULL );
	}

	vTaskStartScheduler();

	return 0;
}

void vSendString( const char * const pcString )
{
  uint32_t ulIndex = 0;

  printf(pcString);
}
