#include <linux/module.h>
#include <linux/kernel.h>

/* #define from /lib/modules/uname-r/source/arch/arm64/include/asm/perf_event.h in ASM Aarch 64 */
#define ARMV8_PMCR_MASK         0x3f
#define ARMV8_PMCR_E            (1 << 0) /*  Enable all counters */
#define ARMV8_PMCR_P            (1 << 1) /*  Reset all counters */
#define ARMV8_PMCR_C            (1 << 2) /*  Cycle counter reset */
#define ARMV8_PMCR_N_MASK       0x1f

#define ARMV8_PMUSERENR_EN_EL0  (1 << 0) /*  EL0 access enable */
#define ARMV8_PMUSERENR_CR      (1 << 2) /*  Cycle counter read enable */
#define ARMV8_PMUSERENR_ER      (1 << 3) /*  Event counter read enable */

#define ARMV8_PMCNTENSET_EL0_ENABLE (1<<31) /* *< Enable Perf count reg */

 
void enable_ccr(void *info) {
  /*Enable user-mode access to counters. */
  asm volatile("msr pmuserenr_el0, %0" : : "r"((u64)ARMV8_PMUSERENR_EN_EL0|ARMV8_PMUSERENR_ER|ARMV8_PMUSERENR_CR));
  
  /*   Performance Monitors Count Enable Set register bit 30:0 disable, 31 enable. Can also enable other event counters here. */
  asm volatile("msr pmcntenset_el0, %0" : : "r" (ARMV8_PMCNTENSET_EL0_ENABLE));
  
  /* Enable counters */
  u64 val=0;
  asm volatile("mrs %0, pmcr_el0" : "=r" (val));
  asm volatile("msr pmcr_el0, %0" : : "r" (val|ARMV8_PMCR_E));
}
 
int init_module(void) {
  // Each cpu has its own set of registers
  on_each_cpu(enable_ccr,NULL,0);
  printk (KERN_INFO "Userspace access to CCR enabled\n");
  return 0;
}
 
void cleanup_module(void) {
}

MODULE_LICENSE("MIT");
