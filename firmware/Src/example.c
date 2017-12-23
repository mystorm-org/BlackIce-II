/*
 * example myStorm program:
 *	send embedded bitstream to the ice40 vi spi3
 *	if ice40 programming fails, flash led5 at 1Hz
 *  send repeated message to host via uart1
 */

#include "main.h"
#include "stm32l4xx_hal.h"
#include "errno.h"

enum { OK, TIMEOUT, ICE_ERROR };

extern UART_HandleTypeDef huart1;
extern SPI_HandleTypeDef hspi3;
extern QSPI_HandleTypeDef hqspi;

extern uint8_t _binary_bitmap_bin_start;
extern uint8_t _binary_bitmap_bin_end;

#define gpio_setmode(pin, mode) gpio_port_setmode(pin##_GPIO_Port, pin##_Pin, mode)
#define gpio_write(pin, value)	HAL_GPIO_WritePin(pin##_GPIO_Port, pin##_Pin, value)
#define gpio_low(pin)	gpio_write(pin, 0)
#define gpio_high(pin)	gpio_write(pin, 1)
#define gpio_ishigh(pin)	(HAL_GPIO_ReadPin(pin##_GPIO_Port, pin##_Pin) == GPIO_PIN_SET)
#define msec_delay(ms)	HAL_Delay(ms)

static int loadstatus = OK;

/*
 * Dummy memory allocator for newlib, so we can call snprintf
 */
caddr_t
_sbrk(int incr)
{
	errno = ENOMEM;
	return (caddr_t) -1;
}

/*
 * Set a gpio pin to input or output
 */
static void
gpio_port_setmode(GPIO_TypeDef *port, int pin, int mode)
{
	GPIO_InitTypeDef g;

	switch (mode) {
	case GPIO_MODE_INPUT:
	case GPIO_MODE_OUTPUT_PP:
		g.Pin = pin;
		g.Mode = mode;
		g.Pull = GPIO_NOPULL;
		g.Speed = GPIO_SPEED_FREQ_LOW;
		HAL_GPIO_Init(port, &g);
	}
}
	
/*
 * Write a string to uart1, adding an extra CR if it ends with LF
 */
static void
uart_puts(char *s)
{
	char *p;
	static unsigned char cr = '\r';

	for (p = s; *p; p++)
		;
	HAL_UART_Transmit(&huart1, (unsigned char*)s, p - s, 500);
	if (p > s && p[-1] == '\n')
		HAL_UART_Transmit(&huart1, &cr, 1, 1);
}

/*
 * Write to spi3 in multiple chunks (HAL_SPI_Transmit length is limited to 16 bits)
 */
static int
spi_write(uint8_t *p, uint32_t len)
{
	int ret;
	uint16_t n;

	ret = HAL_OK;
	n = 0x8000;
	while (len > 0) {
		if (len < n)
			n = len;
		ret = HAL_SPI_Transmit(&hspi3, p, n, HAL_MAX_DELAY);
		if (ret != HAL_OK)
			return ret;
		len -= n;
		p += n;
	}
	return ret;
}

/*
 * Tri-state spi3 pins which are shared with ice40 LED1-4 signals
 */
static void
spi_detach(void)
{
	HAL_SPI_MspDeInit(&hspi3);
	gpio_setmode(ICE40_SPI_CS, GPIO_MODE_INPUT);
}

/*
 * Reset the ICE40 while holding SPI_SS_B low to force a spi-slave configuration
 */
int
ice40_reset(void)
{
	int timeout;

	gpio_low(ICE40_CRST);
	gpio_low(ICE40_SPI_CS);
	msec_delay(1);
	gpio_high(ICE40_CRST);
	timeout = 100;
	while (gpio_ishigh(ICE40_CDONE)) {
		if (--timeout == 0)
			return TIMEOUT;
	}
	msec_delay(2);
	return OK;
}

/*
 * Reset the ICE40 and send the given bitstream via spi
 */
int
ice40_reset_and_send(uint8_t *bitimg, uint32_t len)
{
	int timeout, ret;
	uint8_t any;

	any = 0xFF;
	if (ice40_reset() != OK)
		return ICE_ERROR;
	gpio_low(LED5);
	ret = spi_write(bitimg, len);
	switch (ret) {
	case HAL_OK:
		break;
	case HAL_ERROR:
		uart_puts("spi_write: error\n");
		break;
	case HAL_BUSY:
		uart_puts("spi_write: busy\n");
		break;
	case HAL_TIMEOUT:
		uart_puts("spi_write: timeout\n");
		break;
	default:
		uart_puts("spi_write: unknown error\n");
	}
	if (ret)
		return ret;
	timeout = 100;
	while (!gpio_ishigh(ICE40_CDONE)) {
		if (--timeout == 0)
			return TIMEOUT;
		spi_write(&any, 1);
	}
	/*
	 * Lattice TN1248 says:
	 *   "After the CDONE output goes High, send at least 49 additional
	 *   dummy bits ... After the additional SPI_CLK cycles, the SPI
	 *   interface pins then ecome available to the user application
	 *   loaded in FPGA."
	 */
	for (int i = 0; i < 7; i++)
		spi_write(&any, 1);
	gpio_high(LED5);
	return OK;
}

/*
 * Configure the ICE40 with given bitstream
 */
int
ice40_program(uint8_t *bitimg, uint32_t len)
{
	int ret;

	ret = ice40_reset_and_send(bitimg, len);
	gpio_high(ICE40_SPI_CS);
	return ret;
}

/*
 * setup - called by main() once at reset
 */
void
setup(void)
{
  size_t len;
  static char buf[128];

  snprintf(buf, sizeof buf, "sysclk: %d HSE: %d\n", (int)SystemCoreClock, (int)HSE_VALUE);
  uart_puts(buf);

  /* use one quadspi data line as a simple oneway signal */
  HAL_QSPI_DeInit(&hqspi);
  gpio_setmode(QSPI_D0, GPIO_MODE_OUTPUT_PP);
  gpio_setmode(LED5, GPIO_MODE_OUTPUT_PP);

  len = &_binary_bitmap_bin_end - &_binary_bitmap_bin_start;
  if (len > 0) {
	loadstatus = ice40_program(&_binary_bitmap_bin_start, len);
	spi_detach();
  }
}

/*
 * loop - called by main() repeatedly until reset or powerdown
 */
void
loop(void)
{
	static int toggle = 0;

	gpio_write(LED5, toggle);
	gpio_write(QSPI_D0, toggle);
	if (toggle)
		uart_puts("Hello, myStorm!\n");
	toggle ^= 1;
	msec_delay(500);
}
