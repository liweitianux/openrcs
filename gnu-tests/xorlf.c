#include <stdio.h>

int main(void) {
	int c;
	while ((c = getchar()) != EOF)
		putchar(c ^ '\n');
	return 0;
}
