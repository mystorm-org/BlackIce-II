/*
 * Configure the ICE40 with new bitstreams:
 *	- first from flash at offset FLASH_ICE40_START (if one exists there)
 *	- then repeatedly from usb dfu interface
 * After initial startup message, uart1 is disconnected so shared rx/tx
 * pins can be used by ICE40.
 */

#include "main.h"
#include "usbd_dfu_if.h"
#include "stm32l4xx_hal.h"
#include "errno.h"

#define VER "0.3"

enum { FLASH_ICE40_START = 0x0801F000, FLASH_ICE40_END = 0x08040000 };
enum { OK, TIMEOUT, ICE_ERROR };
enum { UART_FIFOSIZE = 2048 };	/* must be power of 2 */

typedef int (*Reader)(uint8_t*, uint16_t*);

#define gpio_low(pin)	HAL_GPIO_WritePin(pin##_GPIO_Port, pin##_Pin, GPIO_PIN_RESET)
#define gpio_high(pin)	HAL_GPIO_WritePin(pin##_GPIO_Port, pin##_Pin, GPIO_PIN_SET)
#define gpio_ishigh(pin)	(HAL_GPIO_ReadPin(pin##_GPIO_Port, pin##_Pin) == GPIO_PIN_SET)
#define gpio_toggle(pin)	HAL_GPIO_TogglePin(pin##_GPIO_Port, pin##_Pin)

extern UART_HandleTypeDef huart1;
extern SPI_HandleTypeDef hspi3;
extern USBD_HandleTypeDef hUsbDeviceFS;
extern int DFU_LoadStatus;

static uint16_t crc;
static uint8_t *memp, *endmem;
static int uart_detached;

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
 * Readahead fifo for input
 */
static struct fifo {
	int head, tail, max;
	uint8_t buf[UART_FIFOSIZE];
} in_fifo;

static int
fifo_put(struct fifo *f, int c)
{
	int tl;
	int count;

	tl = f->tail;
	count = tl - f->head;
	if (count < 0)
		count += UART_FIFOSIZE;
	if (count > f->max)
		f->max = count;
	if (count == UART_FIFOSIZE - 1)
		return -1;
	f->buf[tl++] = c;
	f->tail = tl & (UART_FIFOSIZE-1);
	return OK;
}

static int
fifo_get(struct fifo *f, uint8_t *b)
{
	int hd;
	int count;

	hd = f->head;
	count = f->tail - hd;
	if (count < 0)
		count += UART_FIFOSIZE;
	if (count == 0)
		return -1;
	*b = f->buf[hd++];
	f->head = hd & (UART_FIFOSIZE-1);
	return OK;
}

/*
 * Write a string to uart1, adding an extra CR if it ends with LF
 */
static void
uart_puts(char *s)
{
	char *p;
	static unsigned char cr = '\r';

	if (uart_detached)
		return;
	for (p = s; *p; p++)
		;
	HAL_UART_Transmit(&huart1, (unsigned char*)s, p - s, 500);
	if (p > s && p[-1] == '\n')
		HAL_UART_Transmit(&huart1, &cr, 1, 1);
}

/*
 * Read one byte from input fifo, waiting until one is available
 */
static int
uart_getc(uint8_t *b)
{
	while (in_fifo.head == in_fifo.tail)
		;
	return fifo_get(&in_fifo, b);
}


/*
 * Read one byte from uart1, returning TIMEOUT immediately if one is not available
 */
static int
uart_trygetc(uint8_t *b)
{
	if (HAL_UART_Receive(&huart1, b, 1, 0) != HAL_OK)
		return TIMEOUT;
	return OK;
}

/*
 * Interrupt callback when a packet has been read from usb dfu
 */
void
DFU_RxCpltCallback(uint8_t *buf, int len)
{
	while (len-- > 0)
		fifo_put(&in_fifo, *buf++);
}

/*
 * Delay for n msec
 */
static void
msec_delay(int n)
{
	HAL_Delay(n);
}

static uint8_t spibuf[64];
static int nspi;

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
 * Append one byte to output buffer for spi3.
 * If arg is negative, flush the buffer.
 */
static void
spi_write1(int b)
{
	if (b >= 0)
		spibuf[nspi++] = b;
	if ((b < 0 && nspi > 0) || nspi == sizeof spibuf) {
		spi_write(spibuf, sizeof spibuf);
		nspi = 0;
	}
}

/*
 * Tri-state spi3 pins which are shared with ice40 LED1-4 signals,
 * and enable the mux which connects LED1-4 to the ice40
 */
static void
spi_detach(void)
{
	HAL_SPI_MspDeInit(&hspi3);
	HAL_GPIO_DeInit(ICE40_SPI_CS_GPIO_Port, ICE40_SPI_CS_Pin);
	gpio_low(SPI3_MUX_OE);
}

/*
 * Reconnect the spi3 pins
 */
static void
spi_reattach(void)
{
	GPIO_InitTypeDef g;

	HAL_SPI_MspInit(&hspi3);
	g.Pin = ICE40_SPI_CS_Pin;
	g.Mode = GPIO_MODE_OUTPUT_PP;
	g.Pull = GPIO_NOPULL;
	g.Speed = GPIO_SPEED_FREQ_LOW;
	HAL_GPIO_Init(ICE40_SPI_CS_GPIO_Port, &g);
	gpio_high(SPI3_MUX_OE);
}

/*
 * Tristate the uart1 rx/tx pins
 */
static void
uart_detach(void)
{
	uart_detached = 1;
	HAL_UART_MspDeInit(&huart1);
}

/*
 * Reset the ICE40 while holding SPI_SS_B low to force a spi-slave configuration
 */
static int
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
 * Wait for end of ICE40 configuration
 */
static int
ice40_configdone(void)
{
	uint8_t b = 0;

	for (int timeout = 100; !gpio_ishigh(ICE40_CDONE); timeout--) {
		if (timeout == 0) {
			uart_puts("CDONE not set\n");
			return ICE_ERROR;
		}
		spi_write(&b, 1);
	}
	for (int i = 0; i < 7; i++)
		spi_write(&b, 1);
	uart_puts("Config done\n");
	return OK;
}

/*
 * Update bitstream checksum
 */
static void
crc_update(uint8_t b)
{
	int c, v;

	v = b << 8;
	c = crc;
	for (int i = 0; i < 8; i++) {
		int x = 0;
		if ((c ^ v) & 0x8000)
			x = 0x1021;
		c = (c << 1) ^ x;
		v <<= 1;
	}
	crc = c;
}

/*
 * Restart bitstream checksum
 */
static void
crc_reset(void)
{
	crc = 0xFFFF;
}

/*
 * Read a byte from uart, update checksum, and send it to spi3
 */
static int
rbyte_uart_send(uint8_t *b, uint16_t *crc)
{
	if (b == NULL) {
		spi_write1(-1);
		return OK;
	}
	if (uart_getc(b) != OK)
		return -1;
	spi_write1(*b);
	crc_update(*b);
	return OK;
}

/*
 * Read a byte from flash or RAM, and update checksum
 */
static int
rbyte_mem_check(uint8_t *b, uint16_t *crc)
{
	if (memp >= endmem)
		return -1;
	if (b == NULL)
		return OK;
	*b = *memp++;
	crc_update(*b);
	return OK;
}

/*
 * Read a byte from flash or RAM, update checksum, and send it to spi3
 */
static int
rbyte_mem_send(uint8_t *b, uint16_t *crc)
{
	if (memp >= endmem)
		return -1;
	if (b == NULL) {
		spi_write1(-1);
		return OK;
	}
	*b = *memp++;
	spi_write(b, 1);
	crc_update(*b);
	return OK;
}

/*
 * Read n bytes using the given reader
 */
static int
rbytes(Reader rbyte, int n, uint8_t *b, uint16_t *crc)
{
	while (n-- > 0) {
		if (rbyte(b, crc) < 0)
			return -1;
	}
	return 0;
}

/*
 * Read and parse a bitstream using the given reader
 */
static int
rbits(Reader rbyte, int firstb)
{
	int preamble;
	int crc_checked = 0;
	uint8_t b;
	int cmd, len, arg;
	int width = 0, height = 0;

	/* find the synchronising marker */
	preamble = firstb;
	while (preamble != 0x7EAA997E) {
		if (rbyte(&b, &crc) < 0)
			return -1;
		preamble <<= 8;
		preamble |= b;
	}

	/* parse the bitstream to find crc reset+check commands */
	while (rbyte(&b, &crc) == 0) {
		cmd = b >> 4;
		len = b & 0xF;
		arg = 0;
		while (len-- > 0) {
			if (rbyte(&b, &crc) < 0)
				return -1;
			arg <<= 8;
			arg |= b;
		}
		switch (cmd) {
		default:	/* unknown */
			return -1;
		case 1:		/* current bank */
		case 5:		/* frequency range */
		case 8:		/* offset of section */
		case 9:		/* warm boot */
			break;
		case 2:		/* check crc */
			if (crc != 0) {
				uart_puts("CRC error..");
				return -1;
			}
			break;
		case 6:		/* width of section */
			width = arg + 1;
			break;
		case 7:		/* height of section */
			height = arg;
			break;
		case 0:
			switch (arg) {
			default:	/* unknown */
				return -1;
			case 1:		/* CRAM data */
			case 3:		/* BRAM data */
				if (rbytes(rbyte, height*width/8, &b, &crc) < 0)
					return -1;
				if (rbyte(&b, &crc) < 0 || b != 0)
					return -1;
				if (rbyte(&b, &crc) < 0 || b != 0)
					return -1;
				break;
			case 5:		/* crc reset */
				crc_reset();
				break;
			case 6:		/* wakeup */
				if (!crc_checked)
					return -1;
				/* discard the final padding byte added by icepack */
				rbyte(&b, &crc);
				rbyte(NULL, NULL);
				return OK;
			}
		}
		crc_checked = (cmd == 2);
	}
	return -1;
}

/*
 * Setup function (called once at powerup)
 *	- flush any input in uart buffer
 *	- if there's a bitstream in flash, send it to the ice40
 */
void
setup(void)
{
	uint8_t b;

	spi_detach();
	gpio_low(LED5);
	memp = (uint8_t*)FLASH_ICE40_START;
	endmem = (uint8_t*)FLASH_ICE40_END;
	uart_puts("Mystorm version ");
	uart_puts(VER);
	uart_puts("\n");
	crc_reset();
	if (rbits(rbyte_mem_check, 0) == OK) {
		uart_puts("Programming from flash\n");
		memp = (uint8_t*)FLASH_ICE40_START;
		crc_reset();
		gpio_high(LED5);
		gpio_low(ICE40_CRST);
		spi_reattach();
		if (ice40_reset() != OK)
			uart_puts("reset failed\n");
		else if (rbits(rbyte_mem_send, 0) != OK)
			uart_puts("rbits failed\n");
		else if (ice40_configdone() != OK)
			uart_puts("configdone failed\n");
		spi_detach();
		gpio_low(LED5);
	}
	uart_puts("Setup done - waiting for USB DFU\n");
	while (uart_trygetc(&b) == OK)
		;
	uart_detach();
}

/*
 * Loop function (called repeatedly)
 *	- wait for the start of a bitstream to be received on uart1 or usbdfu
 *	- receive the bitstream and pass it to the ice40
 */
void
loop(void)
{
	uint8_t b = 0;
	static int err = 0;

	if (err) {
		gpio_toggle(LED5);
		HAL_Delay(100);
		return;
	}
	uart_puts("Waiting for UART or USB DFU\n");
	do {
		uart_getc(&b);
	} while (b != 0x7E);
	gpio_high(LED5);
	gpio_low(ICE40_CRST);
	spi_reattach();
	err = ice40_reset();
	if (err)
		return;
	crc_reset();
	spi_write(&b, 1);
	crc_update(b);
	if ((err = rbits(rbyte_uart_send, b)) != OK) {
		DFU_LoadStatus = err;
		uart_puts("rbits failed\n");
		return;
	}
	err = ice40_configdone();
	spi_detach();
	gpio_low(LED5);
}
