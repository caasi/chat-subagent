# LM Studio Native API Reference

How to call the LM Studio native chat API via `curl`. This API supports
server-side MCP tool calling — the server handles the full tool loop internally.

## URL Contract

The `url` from endpoint config is the **base URL without version prefix**.
Append `/api/v1/chat` to form the full endpoint.

Example: `http://localhost:1234` → `http://localhost:1234/api/v1/chat`

**Warning:** If the config `url` ends with `/v1` or `/v1/`, it is misconfigured.
Inform the user and strip the suffix before appending the path.

## Request Template

```bash
curl --silent --fail-with-body "${URL}/api/v1/chat" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer ${API_KEY}" \
  --max-time "${TIMEOUT:-120}" \
  --data '{
    "model": "${MODEL}",
    "input": "${PROMPT}",
    "integrations": ${INTEGRATIONS},
    "temperature": 0
  }'
```

**Field sources:**
- `${URL}` — endpoint config `url` field
- `${MODEL}` — endpoint config `model` field
- `${API_KEY}` — read from env var named in `api_key_env` config field; omit header if not set
- `${PROMPT}` — the delegated task prompt (single string, not messages array)
- `${INTEGRATIONS}` — JSON array from endpoint config `integrations` field (e.g. `["mcp/web-search", "mcp/fetch"]`); omit field entirely if not configured
- `${TIMEOUT}` — use 120 seconds unless the task warrants more

**Optional fields:**
- `"context_length": N` — from endpoint config `context_length` field; omit if not set

**JSON escaping:** When building the JSON body, escape `"` as `\"` and newlines as `\n` in all string values.

**Note:** Unlike the OpenAI format, there is no `messages` array or system prompt field.
The native API takes a single `input` string. If you need a system prompt, prepend it
to the input string (e.g. `"System: You are a code reviewer.\n\nUser: Review this code..."`).

## Response Extraction

**Without thinking filter:**
```bash
curl ... | jq --raw-output '[.output[] | select(.type == "message") | .content] | join("\n")'
```

**With thinking filter** (when `thinking: true` in config):
```bash
curl ... | jq -f /path/to/thinking-filter-lmstudio.jq | jq --raw-output '[.output[] | select(.type == "message") | .content] | join("\n")'
```

The `thinking-filter-lmstudio.jq` file is in the same directory as the SKILL.md file.
Resolve its absolute path from the SKILL.md location.

## Response Structure

```json
{
  "output": [
    {"type": "reasoning", "content": "thinking tokens..."},
    {"type": "message", "content": "response text"},
    {
      "type": "tool_call",
      "tool": "full-web-search",
      "arguments": {"query": "..."},
      "output": "search results...",
      "provider_info": {"server_label": "web-search", "type": "plugin"}
    },
    {"type": "message", "content": "final answer"}
  ],
  "stats": {
    "input_tokens": 419,
    "total_output_tokens": 362
  }
}
```

**Output item types:**
- `message` — actual response text. Multiple message items may appear; concatenate them.
- `reasoning` — thinking tokens. Filtered out by the jq filter.
- `tool_call` — server-executed MCP tool call with results. Preserved for logging/review. The model's *interpretation* of tool results is still untrusted (same prompt injection defense applies).

## MCP Integrations

The `integrations` field tells LM Studio which MCP servers to enable for this request.
Values are `"mcp/<server-name>"` strings matching servers configured in LM Studio's mcp.json.

Verified working servers:
- `mcp/web-search` — Bing web search
- `mcp/fetch` — URL fetching (sub-tools: `fetch_readable`, `fetch_markdown`, `fetch_html`)

## Error Handling

Same approach as OpenAI — check exit code and parse error response.
LM Studio returns JSON error responses in a similar format.
