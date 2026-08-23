# LocalAiScriptVastAI

Interactive llama.cpp manager for Vast.ai GPU instances.

The goal is to stop rebuilding long `llama-server` commands by hand every time you change:

- GGUF model / Hugging Face repository
- context size
- MTP speculative decoding
- reasoning mode / budget
- KV-cache quantization
- Flash Attention
- GPU assignment
- number of independent GPU replicas
- API ports and aliases
- extra llama.cpp arguments

Profiles and downloaded models live under `/data` by default so they can survive normal container restarts when your Vast storage persists.

## Intended Vast image

This manager is designed around the llama.cpp CUDA server image, for example:

```text
ghcr.io/ggml-org/llama.cpp:server-cuda
```

It also searches for `llama-server` in `$PATH`, `/app/llama-server`, and common install directories.

## Install

On a fresh Vast.ai instance:

```bash
git clone https://github.com/AlexRzk/LocalAiScriptVastAI.git
cd LocalAiScriptVastAI
bash install.sh
```

Then verify the environment:

```bash
vast-llm doctor
```

Start the interactive configuration wizard:

```bash
vast-llm wizard default
```

Or simply:

```bash
vast-llm
```

which opens the menu.

## First-run wizard

The wizard asks for the Hugging Face repository and GGUF filename, then lets you configure GPU replicas and llama.cpp inference settings.

Example Qwen profile:

```text
Hugging Face repository: 0bserverx/Qwen3.8-27B-Heretic-Abliterated-Uncensored-GGUF
GGUF filename: RVN-Q4_K_M-multilingual-mtp.gguf
Model alias base: qwen-heretic
GPU IDs: 0,1
First API port: 8000
Context size: 65536
Parallel slots: 1
GPU layers: 99
Flash attention: on
KV cache K: q4_0
KV cache V: q4_0
MTP: enabled
MTP draft max: 4
MTP p-min: 0.65
```

With `GPU_IDS=0,1`, the manager starts **two independent llama-server processes**:

```text
GPU 0 -> port 8000 -> qwen-heretic-0
GPU 1 -> port 8001 -> qwen-heretic-1
```

This is useful for setups such as:

```text
GPU 0 -> OpenCode main implementation agent
GPU 1 -> OpenCode reviewer/subagent
```

The replicas do not tensor-parallelize one inference request; they are independent servers and can work concurrently.

## Commands

```bash
vast-llm wizard [profile]      # create/edit a profile
vast-llm use <profile>         # choose current profile
vast-llm profiles              # list profiles
vast-llm show [profile]        # display configuration
vast-llm download [profile]    # download selected GGUF
vast-llm start [profile]       # start configured replicas
vast-llm stop [profile]        # stop them
vast-llm restart [profile]     # restart after changing settings
vast-llm status [profile]      # health + GPU usage
vast-llm logs [index]          # follow llama.cpp logs
vast-llm benchmark [index]     # 512-token speed test
vast-llm key                   # show API key
vast-llm doctor                # diagnose CUDA / llama.cpp / storage
vast-llm menu                  # interactive menu
```

## Change context size

Instead of manually killing and rebuilding the server:

```bash
vast-llm wizard default
```

Change:

```text
Context size: 131072
```

Then choose to start it from the wizard, or run:

```bash
vast-llm restart default
```

## Tune MTP

Run:

```bash
vast-llm wizard default
```

Typical fields:

```text
Enable MTP speculative decoding? Y
MTP max drafted tokens: 4
MTP minimum draft probability: 0.65
```

You can then compare settings quickly:

```bash
vast-llm restart
vast-llm benchmark 0
```

The benchmark reports llama.cpp's output-token throughput and MTP drafted/accepted counts when they are returned by the server.

## Switch models

Create another profile:

```bash
vast-llm wizard another-model
```

Set its Hugging Face repository and exact GGUF filename.

List profiles:

```bash
vast-llm profiles
```

Switch:

```bash
vast-llm use another-model
vast-llm start
```

The downloader uses `huggingface_hub` + `hf_xet` and only downloads a model when the exact file is missing from `/data/models`.

For gated/private repositories:

```bash
export HF_TOKEN="hf_your_read_token"
```

Do not commit Hugging Face tokens to this repository.

## Persistent data

Default paths:

```text
/data/vast-llm/profiles     profile configuration
/data/vast-llm/logs         llama-server logs
/data/vast-llm/pids         managed PIDs
/data/vast-llm/api_key.txt  generated OpenAI-compatible API key
/data/models                GGUF files
/data/huggingface           Hugging Face/Xet cache
```

Override the main paths if needed:

```bash
export VAST_LLM_STATE_DIR=/somewhere/vast-llm
export VAST_LLM_MODEL_DIR=/somewhere/models
```

## SSH tunnels

The servers bind to `127.0.0.1` by default for safety. Forward them from your local machine.

For two replicas:

```powershell
ssh -N `
  -o IdentitiesOnly=yes `
  -i "$env:USERPROFILE\.ssh\id_ed25519" `
  -L 8000:127.0.0.1:8000 `
  -L 8001:127.0.0.1:8001 `
  -p YOUR_VAST_SSH_PORT `
  root@YOUR_VAST_IP
```

Then locally:

```text
http://127.0.0.1:8000/v1
http://127.0.0.1:8001/v1
```

## OpenCode example

For the two independent replicas, configure two OpenAI-compatible providers. Example concept:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "vast-main": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://127.0.0.1:8000/v1",
        "apiKey": "{env:VAST_QWEN_API_KEY}"
      },
      "models": {
        "qwen-heretic-0": {
          "name": "Vast Main",
          "limit": { "context": 65536, "output": 8192 }
        }
      }
    },
    "vast-review": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://127.0.0.1:8001/v1",
        "apiKey": "{env:VAST_QWEN_API_KEY}"
      },
      "models": {
        "qwen-heretic-1": {
          "name": "Vast Reviewer",
          "limit": { "context": 65536, "output": 8192 }
        }
      }
    }
  }
}
```

Retrieve the key on Vast with:

```bash
vast-llm key
```

and set it locally in PowerShell:

```powershell
$env:VAST_QWEN_API_KEY="..."
```

## Power-limit diagnostics

`vast-llm status` prints GPU utilization, VRAM, temperature and power draw/limit.

For more detail:

```bash
nvidia-smi --query-gpu=index,name,power.limit,power.default_limit,power.min_limit,power.max_limit --format=csv
```

A 3090 showing roughly `179 W / 180 W` at 100% utilization is strongly power-limited compared with a normal ~350 W power ceiling.

## Notes

- MTP requires a compatible model/runtime combination. Disable MTP in the wizard when switching to a GGUF that does not support it.
- llama.cpp flags evolve. `EXTRA_ARGS` exists so new flags can be added without modifying this manager.
- Keep the API bound to localhost and use SSH tunneling unless you intentionally deploy authentication/network controls for a public endpoint.
- Each GPU listed in `GPU_IDS` receives a full independent copy of the selected model.
