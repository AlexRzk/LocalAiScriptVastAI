# Vast LLM Benchmark Center

`vast-llm` includes a repeatable benchmark lab for comparing models, quants and inference settings on the same Vast.ai hardware.

## Open the benchmark menu

```bash
vast-llm benchmarks
```

The menu provides:

1. Quick benchmark suite
2. Full benchmark suite
3. Raw generation speed (3 runs)
4. Correctness + agentic checks
5. Long-context needle test
6. Compare two profiles — quick
7. Compare two profiles — full
8. Benchmark history
9. Custom prompt benchmark

## Benchmark v2

Benchmark v2 intentionally does **not** present one synthetic `quality %` as if it were a general intelligence score. The summary separates four different things:

- **Performance** — decode throughput, long-prompt prefill throughput and MTP acceptance
- **Correctness** — deterministic reasoning and code-understanding checks
- **Agentic/API** — structured JSON and OpenAI-compatible tool-call behavior
- **Context retrieval** — needle retrieval at moderate and, in full mode, larger context sizes

A `Checks passed` total is still stored for regression tracking. Legacy `quality_*` JSON keys remain as aliases for compatibility with older result consumers, but the CLI no longer labels that value as model quality.

## What the suite measures

### Generation speed

Each run uses a 512-token-cap technical generation prompt. A unique nonce is placed at the beginning of every prompt so llama.cpp prefix-cache reuse cannot make later runs artificially cheap.

The suite records:

- output tokens
- decode time
- generation tokens/s
- prompt tokens and prompt-processing time
- wall-clock time
- MTP drafted/accepted tokens
- MTP acceptance ratio

For multi-run tests, throughput is computed from aggregate token/time totals rather than taking a simple arithmetic mean of per-request rates.

The quick suite runs this once. The full suite runs it three times.

### Long-prompt prefill

A synthetic technical corpus measures prompt-processing throughput. A unique nonce at the start defeats prefix-cache reuse.

The benchmark summary reports **the prompt tokens/s from this dedicated long-prompt prefill request**. It does not use the tiny prompt-processing rate from the generation-speed request.

This is especially relevant for OpenCode because large system prompts, tool schemas and repository context can make prefill latency important even when decode speed is high.

### Correctness: reasoning

Four deterministic arithmetic/logic questions with known answers are automatically scored.

For these deterministic checks, the request asks llama.cpp to disable thinking using `reasoning_effort: "none"` and `chat_template_kwargs.enable_thinking=false`. The output allowance is also large enough that a model which ignores that hint is less likely to be cut off before its final answer.

Only final `message.content` is scored. `reasoning_content` is retained as a diagnostic excerpt but cannot accidentally make a wrong final answer pass.

### Correctness: coding

Four deterministic code-understanding/debugging checks cover Python and JavaScript execution reasoning plus recognition of the mutable-default-argument bug.

Exact-output questions are normalized and compared exactly instead of passing merely because the expected substring appeared somewhere in hidden reasoning. The mutable-default bug check intentionally uses a phrase-containment match because several short correct descriptions are reasonable.

### Agentic/API: instruction following

The model must return an exact JSON structure. The result is parsed and validated with `jq`.

### Agentic/API: tool calling

The server is given an OpenAI-compatible function schema and instructed to call `get_weather` for Paris. The test verifies that a structured tool call is emitted with the expected function and argument.

A failure here should be interpreted as an **agent/template/API compatibility** failure, not automatically as low model intelligence. Tool behavior can depend on the model chat template and llama.cpp integration.

### Context retrieval

A random secret token is inserted into a large synthetic corpus. The model must retrieve it. A unique prompt nonce prevents accidental prefix-cache reuse.

The full suite adds a larger long-context test when the running llama.cpp context is at least 65,536 tokens.

## Result summary

A v2 result looks conceptually like:

```text
Benchmark result
  Profile:             qwen36
  Model:               example.gguf
  Runtime ctx:         120064

  Performance
    Generation:        43.2 tok/s
    Long prefill:      742.6 tok/s
    MTP acceptance:    85.4%

  Correctness:         7/8
  Agentic/API:         2/2
  Context retrieval:   2/2
  Checks passed:       11/12 (91.7%)
```

Do not interpret `Checks passed` as an academic or general-intelligence percentage. It is a compact regression-suite result.

## Run suites from the CLI

Quick:

```bash
vast-llm bench-suite qwen38 quick
```

Full:

```bash
vast-llm bench-suite qwen38 full
```

## Compare two simultaneously running profiles

For example:

```text
GPU0 -> qwen38 -> port 8000
GPU1 -> qwen36 -> port 8001
```

Run:

```bash
vast-llm bench-compare qwen38 qwen36 quick
```

or:

```bash
vast-llm bench-compare qwen38 qwen36 full
```

The comparison table reports runtime context, correctness, agentic/API checks, context retrieval, generation throughput, dedicated long-prompt prefill throughput and MTP acceptance.

## Individual tests

Three-run speed benchmark:

```bash
vast-llm bench-speed qwen38 0 3
```

Correctness + agentic checks:

```bash
vast-llm bench-quality qwen38
```

The command name `bench-quality` is retained for CLI compatibility even though its output is now split into correctness and agentic categories.

Needle test with about 20,000 input words:

```bash
vast-llm bench-needle qwen38 20000
```

Custom prompt:

```bash
vast-llm bench-custom qwen38
```

## Results and history

Results are stored as JSON under:

```text
/data/vast-llm/benchmarks/
```

Show recent runs:

```bash
vast-llm bench-history
```

New results contain `benchmark_schema_version: 2`. Legacy `quality_score`, `quality_max` and `quality_pct` fields remain present as aliases of the regression check total so older scripts do not immediately break.

## Recommended tuning workflow

Keep the model and test suite fixed and change one inference variable at a time:

```bash
vast-llm set mtp-draft 2 qwen38
vast-llm restart qwen38
vast-llm bench-suite qwen38 quick

vast-llm set mtp-draft 4 qwen38
vast-llm restart qwen38
vast-llm bench-suite qwen38 quick

vast-llm set mtp-draft 6 qwen38
vast-llm restart qwen38
vast-llm bench-suite qwen38 quick
```

Use the full suite on the most promising configurations to reduce noise and test long-context behavior. For serious model selection, combine these regression checks with real OpenCode tasks from your own projects.
