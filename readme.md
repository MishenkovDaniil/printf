# Printf (const char *format,...) on nasm-64

## working peculiarities
- printf function realizes %s, %d, %o, %x, %c, %% which work as in standart C printf();
- printf function is added with %b (binary printing);
- printf function supports printout of format string;
- negative number are printed in %d format only with 8-bytes numbers, in other case behaviour is undefined;
- in case number is larger than 8-byte, behaviour is undefined;

# calling 
- printf_call.c realizes calling printf (strt_printf() func) from assembly file
- printf func is cdecl and in strt_printf() converted into cdecl from standart stdcall
- assembly calls standart C printf for comparing results

