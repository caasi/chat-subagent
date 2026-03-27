# Filter out reasoning items from LM Studio native API response
# and strip thinking tags from message content.
#
# LM Studio native API returns:
#   { "output": [ {"type": "reasoning"|"message"|"tool_call", ...} ], "stats": {...} }
#
# This filter:
#   - Removes all items with type "reasoning"
#   - Strips <think>, <thinking>, <analysis> tags from message content
#   - Preserves tool_call and message items intact (except tag stripping)
if (.output | type) == "array" then
  .output |= map(
    select(.type != "reasoning")
    | if .type == "message" and .content then
        .content |= gsub("<think>(.|\n)*?</think>\n*"; "")
        | .content |= gsub("<thinking>(.|\n)*?</thinking>\n*"; "")
        | .content |= gsub("<analysis>(.|\n)*?</analysis>\n*"; "")
      else . end
  )
else
  .
end
