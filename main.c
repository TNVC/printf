#include <stdio.h>

extern void _printf(const char *format, ...);

void c_main()
{
  _printf("I %s %x %d%%%c%b%r from C\n", "love", 3802, 100, 33, 127);
   printf("I %s %x %d%%%c%b%r from C\n", "love", 3802, 100, 33, 127);
}

