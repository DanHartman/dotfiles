# Only load Liquid Prompt in interactive shells, not from a script or from scp
[[ $- = *i* ]] && source ~/liquidprompt/liquidprompt

if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ ! "$SSH_AUTH_SOCK" ]]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

alias pbcopy='xclip -sel clip'
alias pbpaste='xclip -o -sel clip'
alias bcpass="lpass show -p 8852603823818195881 | tr -d [:space:]"
alias auxpass="lpass show --notes 8852603823818195881 | grep Aux | awk '{ print \$NF }' | tr -d [:space:]"
alias jenkinspass="lpass show --notes 8852603823818195881 | grep Jenkins | awk '{ print \$NF }' | tr -d [:space:]"
alias bceagle='printf "%s\n1\n" "$(bcpass)" | sudo openconnect -u HARTMADE --passwd-on-stdin eaglevpn.bc.edu'
alias bcaux='printf "%s\n1\n" "$(auxpass)" | sudo openconnect -u dan@scaleout.team --passwd-on-stdin --servercert pin-sha256:awI56hJkEeKZJ1Q/53X341+LYm0cjxUgYq0WcM4eql4= auxvpn.bc.edu'
alias bcdevenv='TERM=xterm ssh -A hartmade@systems-vagrant-18'
