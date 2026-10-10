sum:
        cmp     w1, #1
        b.lt    .LBB0_3
        cmp     w1, #7
        mov     w9, w1
        b.hi    .LBB0_4
        mov     x10, xzr
        mov     w8, wzr
        b       .LBB0_7
.LBB0_3:
        mov     w8, wzr
        mov     w0, w8
        ret
.LBB0_4:
        movi    v0.2d, #0000000000000000
        movi    v1.2d, #0000000000000000
        and     x10, x9, #0x7ffffff8
        add     x8, x0, #16
        mov     x11, x10
.LBB0_5:
        ldp     q2, q3, [x8, #-16]
        subs    x11, x11, #8
        add     x8, x8, #32
        add     v0.4s, v2.4s, v0.4s
        add     v1.4s, v3.4s, v1.4s
        b.ne    .LBB0_5
        add     v0.4s, v1.4s, v0.4s
        cmp     x10, x9
        addv    s0, v0.4s
        fmov    w8, s0
        b.eq    .LBB0_9
.LBB0_7:
        add     x11, x0, x10, lsl #2
        sub     x9, x9, x10
.LBB0_8:
        ldr     w10, [x11], #4
        subs    x9, x9, #1
        add     w8, w10, w8
        b.ne    .LBB0_8
.LBB0_9:
        mov     w0, w8
        ret