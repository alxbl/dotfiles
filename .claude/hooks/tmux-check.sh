#!/usr/bin/env bash
# SessionStart hook: report tmux status to the user (systemMessage) and the model (additionalContext).
if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ]; then
  info=$(tmux display-message -p -t "$TMUX_PANE" 'session=#{session_name} window=#{window_index}:#{window_name} pane=#{pane_id}')
  jq -n --arg c "Running inside tmux ($info). Follow the tmux workflow in the user rules." \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
else
  jq -n '{
    systemMessage: "Not running in tmux. To relaunch inside tmux: exit, then run `tmux new-session -s claude claude` (or `tmux new-window claude` from an existing session).",
    hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:"Not running in tmux; the user has already been told how to relaunch. Do not use tmux and do not re-offer unless asked."}
  }'
fi
