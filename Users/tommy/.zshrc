
# Created by `pipx` on 2026-04-06 05:31:18
export PATH="$PATH:/Users/tommy/.local/bin"

alias pip=pip3
alias ll="ls -lah"
alias python="python3"

alias wiki='sudo -u codex -H codex --oss --local-provider ollama --model qwen3.6:35b-a3b --sandbox workspace-write --ask-for-approval on-request --cd "/Users/codex/llm-wiki" --no-alt-screen'

alias wiki-auto='sudo -u codex -H codex --oss --local-provider ollama --model qwen3.6:35b-a3b --sandbox workspace-write --ask-for-approval never --cd "/Users/codex/llm-wiki" --no-alt-screen'

alias cl="printf '\e[3J' && clear"

