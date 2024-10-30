.section ".itcm", "ax"
.altmacro

#include "AsmMacros.inc"
#include "VMDtcmDefs.inc"

.macro vm_armUndefinedMsrRegCpsrRm rm
    arm_func vm_armUndefinedMsrRegCpsrR\rm
        .if \rm == 15
            // pc is not allowed
            msr cpsr_c, #0xDB
            movs pc, lr
            .mexit
        .endif

        .if \rm < 8
            mov r8, r\rm
            b vm_updateCpsr
        .elseif \rm < 15
            stmdb sp, {r\rm}^
            b vm_updateCpsrHiReg
        .endif
.endm

arm_func vm_armUndefinedMsrImm
    and r8, lr, #0xF
    and r10, lr, #0xF00
    orr r8, r8, r10, lsr #4
    and r10, lr, #0xF000
    mov r10, r10, lsr #11
    mov r8, r8, ror r10
    tst lr, #0x400000
    beq vm_updateCpsr
    b vm_updateSpsr

vm_updateCpsrHiReg:
    ldr r8, [sp, #-4]
vm_updateCpsr:
    mov r9, r12
    tst lr, #0x10000
    beq vm_cpsrNoControlChange // skip updating control part of cpsr
    tst lr, #0x80000
    ldr r10, [r9, #(vm_cpsr - vm_armUndefinedDispatchTable)]
    and lr, r10, #0xF
    and r11, r8, #0xDF // note that the thumb bit is set to 0
    orr r11, r11, #0x10
    ldr r12, [r9, #(vm_modeSwitchTableAddr - vm_armUndefinedDispatchTable)]
    strb r11, [r9, #(vm_cpsr - vm_armUndefinedDispatchTable)]
    and r11, r11, #0xF
    add r12, r12, r11, lsl #5
    add r12, r12, lr, lsl #1
    ldrh r12, [r12]
    adreq r11, vm_finishCpsrOnlyControl
    adrne r11, vm_finishCpsrControlAndFlags
    bx r12

vm_cpsrNoControlChange:
    tst lr, #0x80000
    bne vm_finishCpsrWithFlags
vm_cpsrFinish:
    msr cpsr_c, #0xDB
    movs pc, lr

vm_finishCpsrControlAndFlags:
    bl emu_updateIrqs

vm_finishCpsrWithFlags:
    ldrb r10, [r9, #(vm_undefinedSpsr - vm_armUndefinedDispatchTable)]
    and r8, r8, #0xF0000000
    ldr lr, [r9, #(vm_undefinedInstructionAddr - vm_armUndefinedDispatchTable)]
    orr r10, r10, r8
    msr spsr, r10
    movs pc, lr

vm_finishCpsrOnlyControl:
    adr lr, vm_cpsrFinish
    b emu_updateIrqs

generate vm_armUndefinedMsrRegCpsrRm, 16

.macro vm_armUndefinedMsrRegSpsrRm rm
    arm_func vm_armUndefinedMsrRegSpsrR\rm
        .if \rm == 15
            // pc is not allowed
            msr cpsr_c, #0xDB
            movs pc, lr
            .mexit
        .endif

        ldr r9, [r12, #(vm_cpsr - vm_armUndefinedDispatchTable)]!
        .if \rm < 8
            mov r8, r\rm
            b vm_updateSpsr
        .elseif \rm < 15
            add r11, r12, #(vm_undefinedRegTmp - vm_cpsr)
            stmia r11, {r\rm}^
            b vm_updateSpsrHiReg
        .endif
.endm

generate vm_armUndefinedMsrRegSpsrRm, 16

vm_updateSpsrHiReg:
    ldr r8, [r11]
vm_updateSpsr:
    and r9, r9, #0xF
    add r12, r12, r9, lsl #2
    orr r8, r8, #0x10
    ldr r10, [r12, #(vm_spsr - vm_cpsr)]
    mov r11, #0
    tst lr, #0x80000
    movne r11, #0xF0000000
    tst lr, #0x10000
    orrne r11, r11, #0xFF
    and r8, r8, r11
    bic r10, r10, r11
    orr r10, r10, r8
    str r10, [r12, #(vm_spsr - vm_cpsr)]
    msr cpsr_c, #0xDB
    movs pc, lr

.section ".dtcm", "aw"

.balign 64

.global vm_armUndefinedMsrRegCpsrRmTable
vm_armUndefinedMsrRegCpsrRmTable:
    .word vm_armUndefinedMsrRegCpsrR0
    .word vm_armUndefinedMsrRegCpsrR1
    .word vm_armUndefinedMsrRegCpsrR2
    .word vm_armUndefinedMsrRegCpsrR3
    .word vm_armUndefinedMsrRegCpsrR4
    .word vm_armUndefinedMsrRegCpsrR5
    .word vm_armUndefinedMsrRegCpsrR6
    .word vm_armUndefinedMsrRegCpsrR7
    .word vm_armUndefinedMsrRegCpsrR8
    .word vm_armUndefinedMsrRegCpsrR9
    .word vm_armUndefinedMsrRegCpsrR10
    .word vm_armUndefinedMsrRegCpsrR11
    .word vm_armUndefinedMsrRegCpsrR12
    .word vm_armUndefinedMsrRegCpsrR13
    .word vm_armUndefinedMsrRegCpsrR14
    .word vm_armUndefinedMsrRegCpsrR15

.global vm_armUndefinedMsrRegSpsrRmTable
vm_armUndefinedMsrRegSpsrRmTable:
    .word vm_armUndefinedMsrRegSpsrR0
    .word vm_armUndefinedMsrRegSpsrR1
    .word vm_armUndefinedMsrRegSpsrR2
    .word vm_armUndefinedMsrRegSpsrR3
    .word vm_armUndefinedMsrRegSpsrR4
    .word vm_armUndefinedMsrRegSpsrR5
    .word vm_armUndefinedMsrRegSpsrR6
    .word vm_armUndefinedMsrRegSpsrR7
    .word vm_armUndefinedMsrRegSpsrR8
    .word vm_armUndefinedMsrRegSpsrR9
    .word vm_armUndefinedMsrRegSpsrR10
    .word vm_armUndefinedMsrRegSpsrR11
    .word vm_armUndefinedMsrRegSpsrR12
    .word vm_armUndefinedMsrRegSpsrR13
    .word vm_armUndefinedMsrRegSpsrR14
    .word vm_armUndefinedMsrRegSpsrR15

.global vm_armUndefinedMsrImmTable
vm_armUndefinedMsrImmTable:
.rept 16
    .word vm_armUndefinedMsrImm
.endr
