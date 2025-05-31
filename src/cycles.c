// read_cpu_timer.c

#include <stdint.h>

uint64_t readCpuTimer() {
#if defined(__i386__)
  uint64_t ret;
  __asm__ volatile("rdtsc" : "=A"(ret));
  return ret;
#elif defined(__x86_64__) || defined(__amd64__)
  uint64_t low, high;
  __asm__ volatile("rdtsc" : "=a"(low), "=d"(high));
  return (high << 32) | low;
#elif defined(__aarch64__)
  uint64_t val;
  asm volatile("mrs %0, pmccntr_el0" : "=r"(val));
  return val;
#else
#error "You need to define readCpuTimer for your OS and CPU architecture"
#endif
}
