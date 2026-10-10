sum:
        sub     sp, sp, #32
        str     x0, [sp, #24]
        str     w1, [sp, #20]
        str     wzr, [sp, #16]
        str     wzr, [sp, #12]
        b       .LBB0_1
.LBB0_1:
        ldr     w8, [sp, #12]
        ldr     w9, [sp, #20]
        subs    w8, w8, w9
        b.ge    .LBB0_4
        b       .LBB0_2
.LBB0_2:
        ldr     x8, [sp, #24]
        ldrsw   x9, [sp, #12]
        ldr     w9, [x8, x9, lsl #2]
        ldr     w8, [sp, #16]
        add     w8, w8, w9
        str     w8, [sp, #16]
        b       .LBB0_3
.LBB0_3:
        ldr     w8, [sp, #12]
        add     w8, w8, #1
        str     w8, [sp, #12]
        b       .LBB0_1
.LBB0_4:
        ldr     w0, [sp, #16]
        add     sp, sp, #32
        ret