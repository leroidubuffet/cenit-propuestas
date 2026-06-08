#!/bin/bash
# Helpers compartidos por los scripts de ataque.

ENDPOINT="${ENDPOINT:-http://localhost:8001/chat}"

attack() {
    local label="$1"
    local prompt="$2"
    echo
    echo "============================================================"
    echo "ATAQUE: $label"
    echo "============================================================"
    echo "Prompt enviado:"
    echo "  $prompt"
    echo "------------------------------------------------------------"
    echo "Respuesta:"
    curl -s -X POST "$ENDPOINT" \
        -H "Content-Type: application/json" \
        -d "$(jq -nc --arg c "$prompt" '{content:$c}')" \
        | python3 -m json.tool
}
