#!/usr/bin/env bash
# Test suite for thinking/reasoning filters.
# Tests both OpenAI-compatible and LM Studio native API jq filters.
# Dependencies: jq
set -euo pipefail

PASS=0
FAIL=0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENAI_FILTER="$SCRIPT_DIR/thinking-filter.jq"
LMSTUDIO_FILTER="$SCRIPT_DIR/thinking-filter-lmstudio.jq"

run_test() {
  local filter="$1" name="$2" input="$3" expected="$4"
  local actual
  actual=$(printf '%s' "$input" | jq --from-file "$filter")
  local norm_expected norm_actual
  norm_expected=$(printf '%s' "$expected" | jq --compact-output .)
  norm_actual=$(printf '%s' "$actual" | jq --compact-output .)
  if [[ "$norm_actual" == "$norm_expected" ]]; then
    echo "  PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $name"
    echo "    expected: $norm_expected"
    echo "    actual:   $norm_actual"
    FAIL=$((FAIL + 1))
  fi
}

# ============================================================
# OpenAI-compatible filter (thinking-filter.jq)
# ============================================================
echo "=== OpenAI-compatible Filter Tests ==="
echo ""

if [[ ! -f "$OPENAI_FILTER" ]]; then
  echo "Error: thinking-filter.jq not found at $OPENAI_FILTER" >&2
  exit 1
fi

run_test "$OPENAI_FILTER" "DeepSeek reasoning_content removed" \
  '{"choices":[{"message":{"role":"assistant","content":"The answer is 42.","reasoning_content":"Let me think step by step..."}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"The answer is 42."}}]}'

run_test "$OPENAI_FILTER" "OpenRouter reasoning removed" \
  '{"choices":[{"message":{"role":"assistant","content":"Hello world.","reasoning":"I should greet the user."}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"Hello world."}}]}'

run_test "$OPENAI_FILTER" "OpenRouter reasoning_details removed" \
  '{"choices":[{"message":{"role":"assistant","content":"Result.","reasoning_details":[{"type":"reasoning.text","text":"thinking..."}]}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"Result."}}]}'

run_test "$OPENAI_FILTER" "Anthropic thinking_blocks removed" \
  '{"choices":[{"message":{"role":"assistant","content":"Done.","thinking_blocks":[{"type":"thinking","thinking":"deep thought","signature":"abc123"}]}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"Done."}}]}'

run_test "$OPENAI_FILTER" "Qwen3 think block stripped from content" \
  '{"choices":[{"message":{"role":"assistant","content":"<think>\nI need to reason about this.\nStep 1: analyze.\nStep 2: conclude.\n</think>\nThe answer is 42."}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"The answer is 42."}}]}'

run_test "$OPENAI_FILTER" "Qwen3 think block no trailing newline" \
  '{"choices":[{"message":{"role":"assistant","content":"<think>short thought</think>answer"}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"answer"}}]}'

run_test "$OPENAI_FILTER" "Multiple thinking fields combined" \
  '{"choices":[{"message":{"role":"assistant","content":"<think>hmm</think>\nOK.","reasoning_content":"rc","reasoning":"r","reasoning_details":[],"thinking_blocks":[]}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"OK."}}]}'

run_test "$OPENAI_FILTER" "Normal response unchanged" \
  '{"choices":[{"message":{"role":"assistant","content":"Just a normal response."}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"Just a normal response."}}]}'

run_test "$OPENAI_FILTER" "Error response passthrough" \
  '{"error":{"message":"model not found","type":"invalid_request_error"}}' \
  '{"error":{"message":"model not found","type":"invalid_request_error"}}'

run_test "$OPENAI_FILTER" "Null content preserved" \
  '{"choices":[{"message":{"role":"assistant","content":null,"reasoning_content":"thinking..."}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":null}}]}'

run_test "$OPENAI_FILTER" "Multiple choices all filtered" \
  '{"choices":[{"message":{"role":"assistant","content":"A","reasoning":"r1"}},{"message":{"role":"assistant","content":"<think>t</think>\nB","reasoning":"r2"}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"A"}},{"message":{"role":"assistant","content":"B"}}]}'

run_test "$OPENAI_FILTER" "Analysis block stripped from content" \
  '{"choices":[{"message":{"role":"assistant","content":"<analysis>\nLet me break this down.\nStep 1: check.\n</analysis>\n\nThe answer is 42."}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"The answer is 42."}}]}'

run_test "$OPENAI_FILTER" "Analysis block inline" \
  '{"choices":[{"message":{"role":"assistant","content":"<analysis>quick check</analysis>result"}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"result"}}]}'

run_test "$OPENAI_FILTER" "Both think and analysis blocks" \
  '{"choices":[{"message":{"role":"assistant","content":"<think>reasoning</think>\n<analysis>checking</analysis>\nfinal answer"}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"final answer"}}]}'

run_test "$OPENAI_FILTER" "Thinking block (full tag) stripped from content" \
  '{"choices":[{"message":{"role":"assistant","content":"<thinking>\nI need to explain the key differences.\nLet me organize this.\n</thinking>\n\nHere is the answer."}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"Here is the answer."}}]}'

run_test "$OPENAI_FILTER" "Thinking block (full tag) inline" \
  '{"choices":[{"message":{"role":"assistant","content":"<thinking>quick thought</thinking>result"}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"result"}}]}'

run_test "$OPENAI_FILTER" "Think, thinking, and analysis blocks combined" \
  '{"choices":[{"message":{"role":"assistant","content":"<think>r1</think>\n<thinking>r2</thinking>\n<analysis>r3</analysis>\nfinal"}}]}' \
  '{"choices":[{"message":{"role":"assistant","content":"final"}}]}'

# ============================================================
# LM Studio native filter (thinking-filter-lmstudio.jq)
# ============================================================
echo ""
echo "=== LM Studio Native Filter Tests ==="
echo ""

if [[ ! -f "$LMSTUDIO_FILTER" ]]; then
  echo "Error: thinking-filter-lmstudio.jq not found at $LMSTUDIO_FILTER" >&2
  exit 1
fi

# --- L1. Reasoning items filtered out ---
run_test "$LMSTUDIO_FILTER" "Reasoning items removed" \
  '{"output":[{"type":"reasoning","content":"thinking..."},{"type":"message","content":"The answer."}],"stats":{}}' \
  '{"output":[{"type":"message","content":"The answer."}],"stats":{}}'

# --- L2. Multiple reasoning items interleaved ---
run_test "$LMSTUDIO_FILTER" "Multiple reasoning items interleaved" \
  '{"output":[{"type":"reasoning","content":"r1"},{"type":"message","content":"First."},{"type":"reasoning","content":"r2"},{"type":"message","content":"Second."}],"stats":{}}' \
  '{"output":[{"type":"message","content":"First."},{"type":"message","content":"Second."}],"stats":{}}'

# --- L3. Tool call items preserved ---
run_test "$LMSTUDIO_FILTER" "Tool call items preserved" \
  '{"output":[{"type":"reasoning","content":"thinking"},{"type":"tool_call","tool":"web-search","arguments":{"query":"test"},"output":"results"},{"type":"message","content":"Done."}],"stats":{}}' \
  '{"output":[{"type":"tool_call","tool":"web-search","arguments":{"query":"test"},"output":"results"},{"type":"message","content":"Done."}],"stats":{}}'

# --- L4. Think tags stripped from message content ---
run_test "$LMSTUDIO_FILTER" "Think tags stripped from message content" \
  '{"output":[{"type":"message","content":"<think>\nLet me reason.\n</think>\nThe answer is 42."}],"stats":{}}' \
  '{"output":[{"type":"message","content":"The answer is 42."}],"stats":{}}'

# --- L5. Thinking tags stripped from message content ---
run_test "$LMSTUDIO_FILTER" "Thinking tags stripped from message content" \
  '{"output":[{"type":"message","content":"<thinking>reasoning</thinking>result"}],"stats":{}}' \
  '{"output":[{"type":"message","content":"result"}],"stats":{}}'

# --- L6. Analysis tags stripped from message content ---
run_test "$LMSTUDIO_FILTER" "Analysis tags stripped from message content" \
  '{"output":[{"type":"message","content":"<analysis>\nChecking.\n</analysis>\n\nFinal answer."}],"stats":{}}' \
  '{"output":[{"type":"message","content":"Final answer."}],"stats":{}}'

# --- L7. All tag types combined in message ---
run_test "$LMSTUDIO_FILTER" "All tag types combined in message" \
  '{"output":[{"type":"message","content":"<think>t1</think>\n<thinking>t2</thinking>\n<analysis>t3</analysis>\nfinal"}],"stats":{}}' \
  '{"output":[{"type":"message","content":"final"}],"stats":{}}'

# --- L8. No reasoning (passthrough) ---
run_test "$LMSTUDIO_FILTER" "No reasoning items unchanged" \
  '{"output":[{"type":"message","content":"Just a normal response."}],"stats":{"input_tokens":10}}' \
  '{"output":[{"type":"message","content":"Just a normal response."}],"stats":{"input_tokens":10}}'

# --- L9. Empty output array ---
run_test "$LMSTUDIO_FILTER" "Empty output array" \
  '{"output":[],"stats":{}}' \
  '{"output":[],"stats":{}}'

# --- L10. Only reasoning items (all filtered) ---
run_test "$LMSTUDIO_FILTER" "Only reasoning items results in empty output" \
  '{"output":[{"type":"reasoning","content":"r1"},{"type":"reasoning","content":"r2"}],"stats":{}}' \
  '{"output":[],"stats":{}}'

# --- L11. Tool call content not stripped (tags only in message type) ---
run_test "$LMSTUDIO_FILTER" "Tool call output not tag-stripped" \
  '{"output":[{"type":"tool_call","tool":"fetch","output":"<think>not stripped</think>data"}],"stats":{}}' \
  '{"output":[{"type":"tool_call","tool":"fetch","output":"<think>not stripped</think>data"}],"stats":{}}'

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
