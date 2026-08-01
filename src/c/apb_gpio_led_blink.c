#include<stdint.h>

#define SYS_ERR             (-1)
#define SYS_OK              (0)

#define APB_BRAM            (0x10000000)
#define APB_PERIPHERAL_BASE (0x20000000)
#define APB_GPIO            (APB_PERIPHERAL_BASE + 0x0000U)
#define APB_FND             (APB_PERIPHERAL_BASE + 0x1000U)
#define APB_UART            (APB_PERIPHERAL_BASE + 0x2000U)


#define APB_GPIO_CTL        (APB_GPIO + 0x00U)
#define APB_GPIO_ODATA      (APB_GPIO + 0x04U)
#define APB_GPIO_IDATA      (APB_GPIO + 0x08U)

#define APB_FND_ODATA       (APB_FND + 0x00U)

#define APB_UART_CTL        (APB_UART + 0x00U)
#define APB_UART_BAUD       (APB_UART + 0x04U)
#define APB_UART_STATUS     (APB_UART + 0x08U)
#define APB_UART_TXDATA     (APB_UART + 0x0CU)
#define APB_UART_RXDATA     (APB_UART + 0x10U)


#define __IO    volatile 

typedef struct {
    __IO uint32_t CTL;
    __IO uint32_t ODATA;
    __IO uint32_t IDATA;
} GPIO_TYPEDEF;

#define GPIOA   ((GPIO_TYPEDEF *) APB_GPIO)

//FND

#define __FND    volatile 

typedef struct {

    __FND uint32_t ODATA;

} FND_TYPEDEF;

#define FNDA   ((FND_TYPEDEF *) APB_FND)

//


//UART

#define __UART    volatile 

typedef struct {
    __UART uint32_t CTL;
    __UART uint32_t BAUD;
    __UART uint32_t SR;
    __UART uint32_t ODATA;
    __UART uint32_t IDATA;
} UART_TYPEDEF;

#define UARTA   ((UART_TYPEDEF *) APB_UART)
//

/* Type your code here, or load an example. */
int sys_init(void);
void delay_ms(int delay);
void GPIO_init(GPIO_TYPEDEF *GPIOx, unsigned int control);
void led_write(GPIO_TYPEDEF *GPIOx, unsigned int wdata);
unsigned int sw_read(GPIO_TYPEDEF *GPIOx);

//fnd
void fnd_write(FND_TYPEDEF *FNDx, unsigned int wdata);

// UART
void uart_to_pc(UART_TYPEDEF *UARTx, unsigned int wdata);
unsigned int uart_from_pc(UART_TYPEDEF *UARTx);
unsigned int uart_tx_busy(UART_TYPEDEF *UARTx);
unsigned int uart_rx_ready(UART_TYPEDEF *UARTx);
void uart_cntl(UART_TYPEDEF *UARTx, unsigned int wdata);
void uart_baud(UART_TYPEDEF *UARTx, unsigned int wdata);


void main(void){
    int time = 0;
    int ret = SYS_ERR;
    unsigned int gpio0;
    unsigned int blink_flag = 0;

    ret = sys_init();
    if (ret == SYS_ERR) return;

    time = 1000;

    while(1) {
        if (!time) {
            // 1sec
            time = 1000;
            gpio0 = sw_read(GPIOA);
            fnd_write(FNDA, gpio0);
            if(!uart_tx_busy(UARTA)){
                uart_to_pc(UARTA, gpio0);
                uart_cntl(UARTA, 1);
            }

            //rx test
            if(uart_rx_ready(UARTA)){
                (void)uart_from_pc(UARTA);
            }
            
            //LED Blink
            if (!blink_flag) {
                blink_flag = 1;
                led_write(GPIOA, gpio0);
            }
            else {
                blink_flag = 0;
                led_write(GPIOA, ~gpio0); 
            } 
        }
        delay_ms(1);
        time --;
    }

    return;
}
void GPIO_init(GPIO_TYPEDEF *GPIOx, unsigned int control) {
    GPIOx->CTL = control;
}
void led_write(GPIO_TYPEDEF *GPIOx, unsigned int wdata) {
    GPIOx->ODATA = wdata;
}
unsigned int sw_read(GPIO_TYPEDEF *GPIOx){
    return GPIOx->IDATA;
}



//FND
void fnd_write(FND_TYPEDEF *FNDx, unsigned int wdata) {
    FNDx->ODATA = wdata;
}

// //UART
void uart_to_pc(UART_TYPEDEF *UARTx, unsigned int wdata){
    UARTx->ODATA = wdata;
}

unsigned int uart_from_pc(UART_TYPEDEF *UARTx){
    return UARTx->IDATA;
}

unsigned int uart_tx_busy(UART_TYPEDEF *UARTx)
{
    return (UARTx->SR & 0x1);
}

unsigned int uart_rx_ready(UART_TYPEDEF *UARTx)
{
    return ((UARTx->SR >> 1) & 0x1);
}

void uart_cntl(UART_TYPEDEF *UARTx, unsigned int wdata){
    UARTx->CTL = wdata;
}

void uart_baud(UART_TYPEDEF *UARTx, unsigned int wdata){
    UARTx->BAUD = wdata;
}

int sys_init(void) {
    int i = 0;
    // RAM 
    *(volatile unsigned int *) APB_BRAM      = 0x00000001;
    // RAM Read Test
    i = *(volatile unsigned int *) APB_BRAM;
    if (i != 0x00000001){
        // error message output
        // UART_PRINT("SYS_ERR");
        return SYS_ERR;
    }

    // GPIO 
    *(volatile unsigned int *) APB_GPIO_CTL      = 0x00000000;   // GPIO control register 
    *(volatile unsigned int *) APB_GPIO_ODATA    = 0x00000000;   // GPIO output register
    // FND 
    *(volatile unsigned int *) APB_FND_ODATA     = 0x00000000;   // FND output register
    // UART 
    *(volatile unsigned int *) APB_UART_CTL       = 0x00000000;   // UART control register 
    *(volatile unsigned int *) APB_UART_BAUD      = 0x00000002;   // UART baudrate register 
    *(volatile unsigned int *) APB_UART_TXDATA    = 0x00000000;   // UART tx register


    GPIO_init(GPIOA,0x0000ff00);     // GPIO [15:8] : LED output, GPIO[7:0] : SW input mode

    return SYS_OK;
}

void delay_ms(int delay) {
    volatile int k=0;
    for(int i=0;i<delay;i++) {
        for (int j=0;j<3300/3;j++) 
            k = k + 1;
    }
}