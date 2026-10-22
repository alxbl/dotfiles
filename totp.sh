# This has to be bash because xlm.sh is bash.
_pid=

_reap() {
    if [[ -n $_pid ]]; then
        kill $_pid 2>/dev/null
    fi
}

{
    for i in {1..20}; do
    sleep 1
    env -u LD_PRELOAD wget "http://127.0.0.1:4646/ffxivlauncher/$(rbw code 'Square Enix')"
    _ret=$?
    if [[ $_ret -eq 0 ]]; then
        break
    fi
    done
} &

_pid=$!
trap _reap EXIT
