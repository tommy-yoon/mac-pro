
# Created by `pipx` on 2026-04-06 05:31:18
export PATH="$PATH:/Users/tommy/.local/bin"

alias pip=pip3
alias ll="ls -lah"
alias python="python3"

#alias wiki='sudo -u codex -H codex --oss --local-provider ollama --model qwen3.6:35b-a3b --sandbox workspace-write --ask-for-approval on-request --cd "/Users/codex/llm-wiki" --no-alt-screen'

#alias wiki-auto='sudo -u codex -H codex --oss --local-provider ollama --model qwen3.6:35b-a3b --sandbox workspace-write --ask-for-approval never --cd "/Users/codex/llm-wiki" --no-alt-screen'

alias cl="printf '\e[3J' && clear"

# Import only Google Drive-authoritative content.
function _wiki_import {
  sudo -n /Library/PrivilegedHelperTools/llm-wiki/import
}

unalias wiki wiki-auto 2>/dev/null

function wiki {
  (
    lock="/Users/tommy/Library/Logs/llm-wiki/auto.lock"

    if ! /bin/mkdir "$lock"; then
      echo "Wiki is busy, or its lock is unavailable. Not starting."
      exit 1
    fi

    trap '/bin/rmdir "$lock"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    /Users/tommy/.local/bin/wiki-backup || exit $?
    _wiki_import || exit $?

    sudo -n -u codex -H /opt/homebrew/bin/codex \
      --profile ollama-launch \
      --sandbox workspace-write \
      --ask-for-approval on-request \
      --cd "/Users/codex/llm-wiki" \
      --no-alt-screen "$@" \
      || exit $?

    sudo -n /Library/PrivilegedHelperTools/llm-wiki/publish
  )
}

function wiki-auto {
  /Users/tommy/.local/bin/wiki-auto-run
}
