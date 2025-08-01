#define NILE_SPI_MODE_WRITE         0x0000
#define NILE_SPI_MODE_READ          0x0200
#define NILE_SPI_MODE_WAIT_READ     0x0600
#define NILE_SPI_MODE_MASK          0x0600
#define NILE_SPI_CLOCK_CART         0x0800
#define NILE_SPI_CLOCK_FAST         0x0000
#define NILE_SPI_CLOCK_MASK         0x0800
#define NILE_SPI_DEV_NONE           0x0000
#define NILE_SPI_DEV_MCU            0x3000
#define NILE_SPI_DEV_MASK           0x3000
#define NILE_SPI_BUFFER_IDX         0x4000
#define NILE_SPI_START              0x8000
#define NILE_SPI_BUSY               0x8000
#define NILE_SPI_CFG_MASK           (NILE_SPI_BUFFER_IDX)
#define IO_NILE_SPI_CNT    0xE0

#define NILE_SEG_MASK_ROM0_ENABLE 0x0200
#define NILE_SEG_MASK_ROM1_ENABLE 0x0400
#define NILE_SEG_MASK_RAM_ENABLE  0x0800
#define IO_NILE_SEG_MASK   0xE4

#define NILE_SPI_CNT_MCU  (NILE_SPI_DEV_MCU | NILE_SPI_CLOCK_CART)
#define NILE_SPI_CNT_NONE (NILE_SPI_CLOCK_CART)

#define NILE_SEG_RAM_SPI_TX 15
#define NILE_SEG_ROM_SPI_RX 510
#define IO_BANK_2003_RAM 0xD0
#define IO_BANK_2003_ROM0 0xD2
#define IO_BANK_2003_ROM1 0xD4
