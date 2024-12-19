#include <stdio.h>
#include <time.h>

int main() {
  printf("Hello World!\n");
  struct timespec ts;
  int ret = clock_gettime(CLOCK_MONOTONIC, &ts);
  printf("ret=%d\n", ret);
  perror("clock_gettime");
}
