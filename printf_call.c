
#include <stdio.h>

extern "C" void strt_printf (const char *format,...);

int main ()
{
    
    strt_printf ("%d %d %o %c\n ", (long)-2, 15, 14, 'f');
    
    return 0;
}