// read_cpu_timer.h

#ifndef READ_CPU_TIMER_H
#define READ_CPU_TIMER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Reads the current CPU cycle timer value.
 *
 * This function provides access to a high-resolution timer
 * via architecture-specific instructions (RDTSC on x86, PMCCNTR_EL0 on ARM).
 *
 * @return A 64-bit unsigned integer representing the current CPU timer value.
 */
uint64_t readCpuTimer(void);

#ifdef __cplusplus
}
#endif

#endif // READ_CPU_TIMER_H
