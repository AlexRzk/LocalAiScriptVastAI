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
4. Reasoning + coding + tool quality
5. Long-context needle test
6. Compare two profiles — quick
7. Compare two profiles — full
8. Benchmark history
9. Custom prompt benchmark

## What the suite measures

### Generation speed

A fixed 512-token-cap technical prompt. The suite records:

- generation tokens/s
- prompt tokens/s
- wall-clock time
- generated tokens
- MTP drafted/accepted tokens
- MTP acceptance ratio

The quick suite runs this once. The full suite runs it three times and averages the results.

### Prompt prefill

A deterministic synthetic technical corpus tests prompt-processing throughput. This is useful for OpenCode because large system prompts, tool schemas and repository context can make prefill latency important even when decode speed is high.

### Reasoning

Four deterministic arithmetic/logic questions with known answers are automatically scored.

### Coding

Four deterministic code-understanding/debugging questions are automatically scored, including Python and JavaScript execution reasoning and recognition of the mutable-default-argument bug.

### Instruction following

The model must return an exact JSON structure. The result is parsed and validated with `jq`.

### Tool calling

The server is given a real OpenAI-compatible function schema and instructed to call `get_weather` for Paris. The test verifies that a structured tool call is emitted with the expected function and argument.

This is particularly useful for comparing models intended for OpenCode or other agentic clients.

### Long-context retrieval

A random secret token is inserted into a large synthetic corpus. The model must retrieve it. The benchmark also records prompt-processing metrics for that request.

The full suite adds a larger long-context test when the running llama.cpp context is at least 65,536 tokens.

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

The comparison table includes runtime context, automatic quality score, generation tokens/s, prompt tokens/s and MTP acceptance.

## Individual tests

Three-run speed benchmark:

```bash
vast-llm bench-speed qwen38 0 3
```

Quality tests only:

```bash
vast-llm bench-quality qwen38
```

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

Each result saves the model/profile configuration alongside its scores, including context, KV types, Flash Attention, MTP settings, reasoning mode and a GPU snapshot. This makes results useful when tuning one parameter at a time.

## Recommended tuning workflow

Keep the model and prompt suite fixed and change one variable at a time:

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

Use the full suite on the most promising configurations to reduce noise and test long-context behavior.

## Important interpretation note

The automatic quality score is a small regression suite, not a general intelligence benchmark. It is designed to catch practical differences in reasoning, code comprehension, instruction following, tool calling and context retrieval while tuning local models. For serious model selection, combine it with real OpenCode tasks from your own projects.
