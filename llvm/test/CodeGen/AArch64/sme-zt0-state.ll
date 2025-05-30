; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 4
; RUN: llc -mtriple=aarch64-linux-gnu -mattr=+sme2 -start-after=simplifycfg -enable-tail-merge=false -verify-machineinstrs < %s | FileCheck %s

declare void @callee();

;
; Private-ZA Callee
;

; Expect spill & fill of ZT0 around call
; Expect smstop/smstart za around call
define void @zt0_in_caller_no_state_callee() "aarch64_in_zt0" nounwind {
; CHECK-LABEL: zt0_in_caller_no_state_callee:
; CHECK:       // %bb.0:
; CHECK-NEXT:    sub sp, sp, #80
; CHECK-NEXT:    stp x30, x19, [sp, #64] // 16-byte Folded Spill
; CHECK-NEXT:    mov x19, sp
; CHECK-NEXT:    str zt0, [x19]
; CHECK-NEXT:    smstop za
; CHECK-NEXT:    bl callee
; CHECK-NEXT:    smstart za
; CHECK-NEXT:    ldr zt0, [x19]
; CHECK-NEXT:    ldp x30, x19, [sp, #64] // 16-byte Folded Reload
; CHECK-NEXT:    add sp, sp, #80
; CHECK-NEXT:    ret
  call void @callee();
  ret void;
}

; Expect spill & fill of ZT0 around call
; Expect setup and restore lazy-save around call
; Expect smstart za after call
define void @za_zt0_shared_caller_no_state_callee() "aarch64_inout_za" "aarch64_in_zt0" nounwind {
; CHECK-LABEL: za_zt0_shared_caller_no_state_callee:
; CHECK:       // %bb.0:
; CHECK-NEXT:    stp x29, x30, [sp, #-32]! // 16-byte Folded Spill
; CHECK-NEXT:    str x19, [sp, #16] // 8-byte Folded Spill
; CHECK-NEXT:    mov x29, sp
; CHECK-NEXT:    sub sp, sp, #80
; CHECK-NEXT:    rdsvl x8, #1
; CHECK-NEXT:    mov x9, sp
; CHECK-NEXT:    msub x9, x8, x8, x9
; CHECK-NEXT:    mov sp, x9
; CHECK-NEXT:    stur x9, [x29, #-16]
; CHECK-NEXT:    sub x9, x29, #16
; CHECK-NEXT:    sub x19, x29, #80
; CHECK-NEXT:    sturh wzr, [x29, #-6]
; CHECK-NEXT:    stur wzr, [x29, #-4]
; CHECK-NEXT:    sturh w8, [x29, #-8]
; CHECK-NEXT:    msr TPIDR2_EL0, x9
; CHECK-NEXT:    str zt0, [x19]
; CHECK-NEXT:    bl callee
; CHECK-NEXT:    smstart za
; CHECK-NEXT:    ldr zt0, [x19]
; CHECK-NEXT:    mrs x8, TPIDR2_EL0
; CHECK-NEXT:    sub x0, x29, #16
; CHECK-NEXT:    cbnz x8, .LBB1_2
; CHECK-NEXT:  // %bb.1:
; CHECK-NEXT:    bl __arm_tpidr2_restore
; CHECK-NEXT:  .LBB1_2:
; CHECK-NEXT:    msr TPIDR2_EL0, xzr
; CHECK-NEXT:    mov sp, x29
; CHECK-NEXT:    ldr x19, [sp, #16] // 8-byte Folded Reload
; CHECK-NEXT:    ldp x29, x30, [sp], #32 // 16-byte Folded Reload
; CHECK-NEXT:    ret
  call void @callee();
  ret void;
}

;
; Shared-ZA Callee
;

; Caller and callee have shared ZT0 state, no spill/fill of ZT0 required
define void @zt0_shared_caller_zt0_shared_callee() "aarch64_in_zt0" nounwind {
; CHECK-LABEL: zt0_shared_caller_zt0_shared_callee:
; CHECK:       // %bb.0:
; CHECK-NEXT:    str x30, [sp, #-16]! // 8-byte Folded Spill
; CHECK-NEXT:    bl callee
; CHECK-NEXT:    ldr x30, [sp], #16 // 8-byte Folded Reload
; CHECK-NEXT:    ret
  call void @callee() "aarch64_in_zt0";
  ret void;
}

; Expect spill & fill of ZT0 around call
define void @za_zt0_shared_caller_za_shared_callee() "aarch64_inout_za" "aarch64_in_zt0" nounwind {
; CHECK-LABEL: za_zt0_shared_caller_za_shared_callee:
; CHECK:       // %bb.0:
; CHECK-NEXT:    sub sp, sp, #80
; CHECK-NEXT:    stp x30, x19, [sp, #64] // 16-byte Folded Spill
; CHECK-NEXT:    mov x19, sp
; CHECK-NEXT:    str zt0, [x19]
; CHECK-NEXT:    bl callee
; CHECK-NEXT:    ldr zt0, [x19]
; CHECK-NEXT:    ldp x30, x19, [sp, #64] // 16-byte Folded Reload
; CHECK-NEXT:    add sp, sp, #80
; CHECK-NEXT:    ret
  call void @callee() "aarch64_inout_za";
  ret void;
}

; Caller and callee have shared ZA & ZT0
define void @za_zt0_shared_caller_za_zt0_shared_callee() "aarch64_inout_za" "aarch64_in_zt0" nounwind {
; CHECK-LABEL: za_zt0_shared_caller_za_zt0_shared_callee:
; CHECK:       // %bb.0:
; CHECK-NEXT:    str x30, [sp, #-16]! // 8-byte Folded Spill
; CHECK-NEXT:    bl callee
; CHECK-NEXT:    ldr x30, [sp], #16 // 8-byte Folded Reload
; CHECK-NEXT:    ret
  call void @callee() "aarch64_inout_za" "aarch64_in_zt0";
  ret void;
}

; New-ZT0 Callee

; Expect spill & fill of ZT0 around call
; Expect smstop/smstart za around call
define void @zt0_in_caller_zt0_new_callee() "aarch64_in_zt0" nounwind {
; CHECK-LABEL: zt0_in_caller_zt0_new_callee:
; CHECK:       // %bb.0:
; CHECK-NEXT:    sub sp, sp, #80
; CHECK-NEXT:    stp x30, x19, [sp, #64] // 16-byte Folded Spill
; CHECK-NEXT:    mov x19, sp
; CHECK-NEXT:    str zt0, [x19]
; CHECK-NEXT:    smstop za
; CHECK-NEXT:    bl callee
; CHECK-NEXT:    smstart za
; CHECK-NEXT:    ldr zt0, [x19]
; CHECK-NEXT:    ldp x30, x19, [sp, #64] // 16-byte Folded Reload
; CHECK-NEXT:    add sp, sp, #80
; CHECK-NEXT:    ret
  call void @callee() "aarch64_new_zt0";
  ret void;
}

; New-ZT0 Callee

; Expect commit of lazy-save if ZA is dormant
; Expect smstart ZA & clear ZT0
; Expect spill & fill of ZT0 around call
; Before return, expect smstop ZA
define void @zt0_new_caller_zt0_new_callee() "aarch64_new_zt0" nounwind {
; CHECK-LABEL: zt0_new_caller_zt0_new_callee:
; CHECK:       // %bb.0: // %prelude
; CHECK-NEXT:    sub sp, sp, #80
; CHECK-NEXT:    stp x30, x19, [sp, #64] // 16-byte Folded Spill
; CHECK-NEXT:    mrs x8, TPIDR2_EL0
; CHECK-NEXT:    cbz x8, .LBB6_2
; CHECK-NEXT:  // %bb.1: // %save.za
; CHECK-NEXT:    bl __arm_tpidr2_save
; CHECK-NEXT:    msr TPIDR2_EL0, xzr
; CHECK-NEXT:  .LBB6_2:
; CHECK-NEXT:    smstart za
; CHECK-NEXT:    zero { zt0 }
; CHECK-NEXT:    mov x19, sp
; CHECK-NEXT:    str zt0, [x19]
; CHECK-NEXT:    smstop za
; CHECK-NEXT:    bl callee
; CHECK-NEXT:    smstart za
; CHECK-NEXT:    ldr zt0, [x19]
; CHECK-NEXT:    smstop za
; CHECK-NEXT:    ldp x30, x19, [sp, #64] // 16-byte Folded Reload
; CHECK-NEXT:    add sp, sp, #80
; CHECK-NEXT:    ret
  call void @callee() "aarch64_new_zt0";
  ret void;
}

; Expect commit of lazy-save if ZA is dormant
; Expect smstart ZA & clear ZT0
; No spill & fill of ZT0 around __arm_tpidr2_save
; Expect spill & fill of ZT0 around __arm_sme_state call
; Before return, expect smstop ZA
define i64 @zt0_new_caller_abi_routine_callee() "aarch64_new_zt0" nounwind {
; CHECK-LABEL: zt0_new_caller_abi_routine_callee:
; CHECK:       // %bb.0: // %prelude
; CHECK-NEXT:    sub sp, sp, #80
; CHECK-NEXT:    stp x30, x19, [sp, #64] // 16-byte Folded Spill
; CHECK-NEXT:    mrs x8, TPIDR2_EL0
; CHECK-NEXT:    cbz x8, .LBB7_2
; CHECK-NEXT:  // %bb.1: // %save.za
; CHECK-NEXT:    bl __arm_tpidr2_save
; CHECK-NEXT:    msr TPIDR2_EL0, xzr
; CHECK-NEXT:  .LBB7_2:
; CHECK-NEXT:    smstart za
; CHECK-NEXT:    zero { zt0 }
; CHECK-NEXT:    mov x19, sp
; CHECK-NEXT:    str zt0, [x19]
; CHECK-NEXT:    bl __arm_sme_state
; CHECK-NEXT:    ldr zt0, [x19]
; CHECK-NEXT:    smstop za
; CHECK-NEXT:    ldp x30, x19, [sp, #64] // 16-byte Folded Reload
; CHECK-NEXT:    add sp, sp, #80
; CHECK-NEXT:    ret
  %res = call {i64, i64} @__arm_sme_state()
  %res.0 = extractvalue {i64, i64} %res, 0
  ret i64 %res.0
}

declare {i64, i64} @__arm_sme_state()

;
; New-ZA Caller
;

; Expect commit of lazy-save if ZA is dormant
; Expect smstart ZA & clear ZT0
; Before return, expect smstop ZA
define void @zt0_new_caller() "aarch64_new_zt0" nounwind {
; CHECK-LABEL: zt0_new_caller:
; CHECK:       // %bb.0: // %prelude
; CHECK-NEXT:    str x30, [sp, #-16]! // 8-byte Folded Spill
; CHECK-NEXT:    mrs x8, TPIDR2_EL0
; CHECK-NEXT:    cbz x8, .LBB8_2
; CHECK-NEXT:  // %bb.1: // %save.za
; CHECK-NEXT:    bl __arm_tpidr2_save
; CHECK-NEXT:    msr TPIDR2_EL0, xzr
; CHECK-NEXT:  .LBB8_2:
; CHECK-NEXT:    smstart za
; CHECK-NEXT:    zero { zt0 }
; CHECK-NEXT:    bl callee
; CHECK-NEXT:    smstop za
; CHECK-NEXT:    ldr x30, [sp], #16 // 8-byte Folded Reload
; CHECK-NEXT:    ret
  call void @callee() "aarch64_in_zt0";
  ret void;
}

; Expect commit of lazy-save if ZA is dormant
; Expect smstart ZA, clear ZA & clear ZT0
; Before return, expect smstop ZA
define void @new_za_zt0_caller() "aarch64_new_za" "aarch64_new_zt0" nounwind {
; CHECK-LABEL: new_za_zt0_caller:
; CHECK:       // %bb.0: // %prelude
; CHECK-NEXT:    str x30, [sp, #-16]! // 8-byte Folded Spill
; CHECK-NEXT:    mrs x8, TPIDR2_EL0
; CHECK-NEXT:    cbz x8, .LBB9_2
; CHECK-NEXT:  // %bb.1: // %save.za
; CHECK-NEXT:    bl __arm_tpidr2_save
; CHECK-NEXT:    msr TPIDR2_EL0, xzr
; CHECK-NEXT:  .LBB9_2:
; CHECK-NEXT:    smstart za
; CHECK-NEXT:    zero {za}
; CHECK-NEXT:    zero { zt0 }
; CHECK-NEXT:    bl callee
; CHECK-NEXT:    smstop za
; CHECK-NEXT:    ldr x30, [sp], #16 // 8-byte Folded Reload
; CHECK-NEXT:    ret
  call void @callee() "aarch64_inout_za" "aarch64_in_zt0";
  ret void;
}

; Expect clear ZA on entry
define void @new_za_shared_zt0_caller() "aarch64_new_za" "aarch64_in_zt0" nounwind {
; CHECK-LABEL: new_za_shared_zt0_caller:
; CHECK:       // %bb.0:
; CHECK-NEXT:    str x30, [sp, #-16]! // 8-byte Folded Spill
; CHECK-NEXT:    zero {za}
; CHECK-NEXT:    bl callee
; CHECK-NEXT:    ldr x30, [sp], #16 // 8-byte Folded Reload
; CHECK-NEXT:    ret
  call void @callee() "aarch64_inout_za" "aarch64_in_zt0";
  ret void;
}

; Expect clear ZT0 on entry
define void @shared_za_new_zt0() "aarch64_inout_za" "aarch64_new_zt0" nounwind {
; CHECK-LABEL: shared_za_new_zt0:
; CHECK:       // %bb.0:
; CHECK-NEXT:    str x30, [sp, #-16]! // 8-byte Folded Spill
; CHECK-NEXT:    zero { zt0 }
; CHECK-NEXT:    bl callee
; CHECK-NEXT:    ldr x30, [sp], #16 // 8-byte Folded Reload
; CHECK-NEXT:    ret
  call void @callee() "aarch64_inout_za" "aarch64_in_zt0";
  ret void;
}
