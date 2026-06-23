#!/usr/bin/env bash

function detect_gpu_driver() {
    if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
        echo 'nvidia'
    elif lspci 2>/dev/null | grep -qi 'vga.*amd\|display.*amd'; then
        echo 'amd'
    else
        echo 'cpu'
    fi
}

function usage() {
    cat <<EOF
Convenience wrapper for deploying open-webui and other related LLM services.

Usage: $(basename "$0") [OPTIONS] -- [COMPOSE OPTIONS]

Options:
    --gpu                   Enable Ollama GPU support with vendor detection.
                            Falls back to CPU if no supported GPU is found.
    --ollama                Deploy ollama
EOF
}

enable_ollama='no'
enable_gpu='no'

args="$(getopt -o ogh -l ollama,gpu,help --name "$0" -- "$@")"
eval set -- "$args"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ollama) enable_ollama='yes'; shift ;;
        --gpu) enable_gpu='yes'; shift ;;
        --help) usage; exit 0 ;;
        --) shift; break ;;
        *)
            {
                echo "Unknown option: '$1'"
                usage
            } >&2;
            exit 1;
            ;;
    esac
done

docker_compose_options=('-f' './docker-compose.yaml')

if [ "$enable_ollama" = 'yes' ]; then
    docker_compose_options+=('-f' './compose-extensions/ollama/docker-compose.yaml')

    if [ "$enable_gpu" = 'yes' ]; then
        declare gpu_vendor
        gpu_vendor="$(detect_gpu_driver)"

        if [ "$gpu_vendor" != 'cpu' ]; then
            docker_compose_options+=(
                '-f'
                "./compose-extensions/ollama/docker-compose.${gpu_vendor}.yaml"
            )
        fi
    fi
fi

docker compose "${docker_compose_options[@]}" "$@"
