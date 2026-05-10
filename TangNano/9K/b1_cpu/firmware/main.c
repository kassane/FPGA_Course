#ifndef DELAY
#define DELAY 50000
#endif

#define GPIO_BASE ((volatile unsigned int *)0x20000000)

static void delay(unsigned int n) {
    while (n--) __asm__ volatile ("");
}

int main(void) {
    unsigned int count = 0;
    while (1) {
        /* active-low: invert the 3-bit count so 000=all on, 111=all off */
        *GPIO_BASE = (~count) & 0x7;
        delay(DELAY);
        count = (count + 1) & 0x7;
    }
}
