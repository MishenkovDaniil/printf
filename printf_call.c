
#include <stdio.h>

extern "C" void strt_printf (const char *format,...);

int main ()
{
    
    strt_printf ("<<<%d %d %o %c \n %d %s %x %d%%%c%b\n >>>", (long)-2, 15, 14, 'd', -1L, "love", 3802, 100, 33, 127);
    strt_printf ("\n<<<%d%f>>>\n", 1);    
    return 0;
}