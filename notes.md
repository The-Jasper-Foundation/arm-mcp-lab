Calling mca without input_path returns status: ok and llvm-mca’s help text, with no error telling the caller that no analysis happened.

## mca: triple field always fails (10 Oct 20:59)
- Tried: input_path=/workspace/samples/sum_O0.s, triple=aarch64, cpu=neoverse-v3
- Got: status "error", code 1, stderr: [paste full message]
- Why: cmd shows the server passes --triple; llvm-mca's flag is --mtriple
  (mcp-local/utils/llvm_mca_tool.py, line 26)
- Workaround: leave triple empty, pass --mtriple via extra_args

## mca: neoverse-v3 not recognised (10 Oct 21:00)
- Tried: cpu=neoverse-v3, extra_args=["--mtriple=aarch64"]
- Got: status "error", code 1, stderr "'neoverse-v3' is not a
  recognized processor for this target (ignoring processor)" (twice)
- Why: the container ships LLVM 18 (Dockerfile installs llvm-mca-18),
  which predates V3 support
- V3 is the core in Arm's AGI CPU, so the tool can't model Arm's newest server core

## mca: sum_O0.s on neoverse-v2 (10 Oct 21:07)
- extra_args=["--mtriple=aarch64"], status ok
- Instructions 2500 | Total Cycles 474 | IPC 5.27 | Block RThroughput 3.0
- Busiest units: load/store (~4.7/iteration); vector units unused
- At -O0 every variable goes via memory (str/ldr), so the bottleneck is memory traffic, not arithmetic
- Caveat: llvm-mca ignores branches (warning in stderr), so this models the
  whole function as straight-line code, not the real loop

  ## Predictions for sum_O2.s (written before running)
1. Vector units used?  YES, because this time a weightier model is used

2. Busiest unit:       My guess: unsure

3. Fair to compare Total Cycles with -O0?  I dont think so.

## Result: sum_O2.s on neoverse-v2
- Instructions 3500 (35 lines vs 25) | Total Cycles 403 | IPC 8.68 | Block RThroughput 4.0

- 1. Vector units used: YES (right). Cause: clang vectorised the loop
  (ldp q2,q3 = 8 ints; add v0.4s = 4 adds), not a different CPU model

- 2. Busiest: branch units (4.00). Load/store fell ~4.7 to ~1; store data fell to 0

- 3. Whole-file comparison not fair: llvm-mca ignores branches and charges every
  line once per pass; the -O2 loop does 8 numbers per pass, -O0 does 1

# Loop_O0
cycles per pass   = Total Cycles ÷ 100   = 308 ÷ 100 = 3.08
numbers per pass  = 1   (the -O0 loop adds one number each time round)
cycles per number = 3.08 ÷ 1 = 3.08

# Loop_O2 - is 12x faster per number added

cycles per pass   = Total Cycles ÷ 100 = 209 ÷ 100 = 2.09
numbers per pass  = 8   (look for subs x11, x11, #8 in the code)
cycles per number = 2.09 ÷ 8 = 0.26

IPC went down but the code got 12× faster per element, because each vector instruction does four times the work. IPC measures how busy the CPU is, not how much useful work it does.

## Fair test: loop bodies only (neoverse-v2)
- loop_O0: 308 cycles/100 = 3.08 per pass, 1 number/pass  → 3.08 cycles/number
- loop_O2: 209 cycles/100 = 2.09 per pass, 8 numbers/pass → 0.26 cycles/number
- -O2 ≈ 12× faster per number (whole-file comparison misleadingly showed ~15%)
- IPC fell 5.19 → 2.87 while speed rose: IPC = busyness, not useful work
- -O2 loop limited by the 2-cycle latency of add v0.4s (dependency chain), not unit pressure
- Caveat: llvm-mca assumes no load/store aliasing by default, which flatters -O0

### Four solid findings:

    The triple bug in Arm’s MCP server, confirmed in their source code.

    LLVM 18 can’t model Neoverse V3, the core in Arm’s own AGI CPU.

    Whole-file vs loop-only comparison: ~15% vs ~12×. The measuring method changes the answer.

    IPC fell while speed rose: busyness isn’t the same as useful work.

    ## -march test
- armv9.7-a: first clang release that accepts it = armv8-a clang 22.1.0
  (versions that rejected it: 21.1 and lower)


  - armv9.8-a on armv8-a clang (trunk): accepted (10 Oct 22:00 2026)


**Create Issue?**
Title: mca tool: `triple` is passed as `--triple`, which llvm-mca rejects

**What happens**
Calling the `mca` tool with `triple` set (e.g. `aarch64`) fails:
status "error", code 1,
stderr: llvm-mca: Unknown command line argument '--triple'.

**Cause**
mcp-local/utils/llvm_mca_tool.py, line 26:
    cmd += ["--triple", triple]
llvm-mca's option is `--mtriple` (it suggests this itself:
"Did you mean '--mtriple'?").

**To reproduce**
armlimited/arm-mcp:latest via MCP Inspector, mca tool:
input_path=/workspace/samples/sum_O0.s, triple=aarch64, cpu=neoverse-v2

**Workaround**
Leave `triple` empty and pass ["--mtriple=aarch64"] in extra_args.

**Suggested fix**
Change "--triple" to "--mtriple" on line 26. There doesn't appear to be a
test covering `triple`, so one might be worth adding.