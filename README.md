# llm-stack

A small local LLM stack using `llama-server`.

`models.ini` file is used for model configuration.
GGUF files need to be manually downloaded or generated.

To generate GGUF files:

```bash
# clone llama.cpp and create a python virtual environment
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# use convert_hf_to_gguf.py script to create a GGUF file from a HuggingFace repository
# use BF16 first to avoid losing quality
python convert_hf_to_gguf.py \
  --remote Qwen/Qwen3.8-27B
  --outfile models/qwen3.8-27b/bf16.gguf
  --outtype bf16

# then quantize to your desired quantization. use your system-wide installed llama-quantize
llama-quantize \
  models/qwen3.8-27b/bf16.gguf \
  models/qwen3.8-27b/q6-k.gguf \
  Q6_K

# OR build llama.cpp from scratch and use that. on MacOS add -DGGML_METAL=ON
cmake -B build \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build -j#
```

Run `llama-server` using:

```bash
nix run
```

This will run `llama-server` using `process-compose`. `llama-server` will automatically pick up model configurations from `models.ini` file.
