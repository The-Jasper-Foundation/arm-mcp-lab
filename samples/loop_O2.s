.LBB0_5:
        ldp     q2, q3, [x8, #-16]
        subs    x11, x11, #8
        add     x8, x8, #32
        add     v0.4s, v2.4s, v0.4s
        add     v1.4s, v3.4s, v1.4s
        b.ne    .LBB0_5