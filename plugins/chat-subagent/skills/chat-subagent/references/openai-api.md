# OpenAI-Compatible API Reference

How to call an OpenAI-compatible chat completion endpoint via `curl`.

## URL Contract

The `url` from endpoint config is the **base URL without version prefix**.
Append `/v1/chat/completions` to form the full endpoint.

Example: `http://localhost:1234` → `http://localhost:1234/v1/chat/completions`

**Warning:** If the config `url` ends with `/v1` or `/v1/`, it is misconfigured.
Inform the user and strip the suffix before appending the path.

## Request Template

```bash
curl --silent --fail-with-body "${URL}/v1/chat/completions" \
  --header "Content-Type: application/json" \
  ${API_KEY:+--header "Authorization: Bearer ${API_KEY}"} \
  --max-time "${TIMEOUT:-120}" \
  --data '{
    "model": "${MODEL}",
    "messages": [
      {"role": "system", "content": "${SYSTEM_PROMPT}"},
      {"role": "user", "content": "${USER_PROMPT}"}
    ]
  }'
```

**Field sources:**
- `${URL}` — endpoint config `url` field
- `${MODEL}` — endpoint config `model` field (default: `"any"`)
- `${API_KEY}` — read from env var named in `api_key_env` config field; omit header if not set
- `${SYSTEM_PROMPT}` — craft based on delegation task
- `${USER_PROMPT}` — the delegated task prompt
- `${TIMEOUT}` — use 120 seconds unless the task warrants more

**JSON escaping:** When building the JSON body, escape `"` as `\"` and newlines as `\n` in all string values.

## Response Extraction

**Without thinking filter:**
```bash
curl ... | jq --raw-output '.choices[0].message.content'
```

**With thinking filter** (when `thinking: true` in config):
```bash
curl ... | jq --from-file /path/to/thinking-filter.jq | jq --raw-output '.choices[0].message.content'
```

The `thinking-filter.jq` file is in the same directory as the SKILL.md file.
Resolve its absolute path from the SKILL.md location.

## Response Structure

```json
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "The response text"
      }
    }
  ]
}
```

The thinking filter removes these provider-specific fields from `.message`:
- `reasoning_content` (DeepSeek)
- `reasoning`, `reasoning_details` (OpenRouter/OpenAI)
- `thinking_blocks` (Anthropic via litellm)

And strips these tags from `.content`:
- `<think>...</think>` (Qwen3)
- `<thinking>...</thinking>` (some distilled models)
- `<analysis>...</analysis>` (some distilled models)

## Error Handling

If `curl` exits non-zero or the response contains an `error` field:
1. Check HTTP status: non-2xx means the request failed (4xx = client/request error, 5xx = server error)
2. Parse `.error.message` from JSON response if available
3. Report the error to the user — do not retry automatically

Note: `--fail-with-body` requires curl >= 7.76.0. If on an older version,
use `--write-out '\n%{http_code}'` and parse the status code from the last line.
