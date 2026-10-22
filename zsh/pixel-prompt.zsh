typeset -g _pp_glyph

if [[ $TERM != xterm-kitty && ! ( -n $TMUX && $(tmux display -p '#{client_termname}' 2>/dev/null) == xterm-kitty ) ]]; then
    PROMPT+=$'\n''%(?.%F{green}.%F{red})❯%f '
    return 0
fi

typeset -g _pp_dir=${XDG_CACHE_HOME:-$HOME/.cache}/pixel-prompt
typeset -g _pp_colors=${XDG_STATE_HOME:-$HOME/.local/state}/theme/colors.json
typeset -g _pp_cell _pp_cache _pp_prev
typeset -g _pp_starship _pp_hdr _pp_strip _pp_dim
typeset -g _pp_title_art
typeset -gi _pp_hdr_w _pp_sid _pp_stale _pp_lamp_check
typeset -gA _pp_payload

_pp_out() {
    if [[ -z $TMUX ]]; then
        print -rn -- $1 >/dev/tty
        return
    fi
    local d=${1//$'\e'/$'\e\e'}
    d=${d//$'\e\e\\'/$'\e\e\\\e\\\ePtmux;'}
    print -rn -- $'\ePtmux;'${d%$'\ePtmux;'} >/dev/tty
}

_pp_lamp() {
    _pp_lamp_check=0
    [[ -n $TMUX ]] || return 0
    local kgp=$_pp_cache/lava.kgp lava=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/lava.py
    if [[ ! -e $kgp || $_pp_colors -nt $kgp || $lava -nt $kgp ]]; then
        { python3 -I $lava ${_pp_cell%x*} ${_pp_cell#*x} $_pp_colors $_pp_cache && kill -USR1 $$ } &>/dev/null &!
        return 0
    fi
    local fd
    zmodload -F zsh/system b:zsystem
    zsystem flock -t 0 -f fd $_pp_cache/.lamp-$(tmux display -p '#{session_id}') 2>/dev/null || return 0
    if [[ $(tmux show -qv @lamp_need) != 0 ]]; then
        _pp_out "$(<$kgp)"
        tmux set -q @lamp_need 0
    fi
    zsystem flock -u $fd
}

_pp_measure() {
    local reply
    print -n '\e[16t' >/dev/tty
    read -rs -t 0.2 -d t reply </dev/tty || return 1
    reply=${reply##*\[6;}
    _pp_cell=${reply#*;}x${reply%%;*}
}

_pp_load() {
    _pp_cache=$_pp_dir/$_pp_cell
    local last=$_pp_cache/err-still.kgp
    local script=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/pixel-cursor.py
    if [[ ! -e $last || $_pp_colors -nt $last || $script -nt $last ]]; then
        python3 -I $script ${_pp_cell%x*} ${_pp_cell#*x} $_pp_colors $_pp_cache || return 1
        _pp_payload=()
    fi
    if (( ! ${#_pp_payload} )); then
        local f
        for f in ok err strip; do
            _pp_payload[$f]=$(<$_pp_cache/$f.kgp)
            _pp_payload[$f-still]=$(<$_pp_cache/$f-still.kgp)
        done
        _pp_dim=$(<$_pp_cache/dim)
    fi
}

_pp_header() {
    local h=${(e)_pp_starship} rest dir plain
    rest=${h#*\%\}}
    dir=${rest%%\%\{*}
    _pp_hdr=${h%%\%\}*}'%}'${dir//\// › }${rest#$dir}
    plain=${(S)_pp_hdr//\%\{*\%\}}
    plain=${plain//\%\%/%}
    _pp_hdr_w=${(m)#${plain##*$'\n'}}
}

_pp_strip_build() {
    local n=$(( COLUMNS - _pp_hdr_w - 2 )) i k=1 s
    (( n >= 12 && _pp_sid )) || { _pp_strip=; return; }
    local dot=$'%{\e[38;2;'$_pp_dim'm%}'
    local star=$'%1{\e[38;2;'$(( _pp_sid >> 16 & 255 ))\;$(( _pp_sid >> 8 & 255 ))\;$(( _pp_sid & 255 ))$'m\U10EEEE\u0305'
    local -a at=($(( n * 13 / 100 )) $(( n * 37 / 100 )) $(( n * 61 / 100 )) $(( n * 84 / 100 )))
    local -a col=($'\u0305' $'\u030D' $'\u030E' $'\u0310' $'\u0312')
    s=$dot
    for (( i = 0; i < n - 2; i++ )); do
        if (( k <= $#at && i == at[k] )); then
            s+=$star$col[k]'%}'$dot
            (( k++ ))
        else
            s+='┈'
        fi
    done
    _pp_strip=$s' '$star$col[5]$'\e[39m%}'
}

_pp_freeze() {
    [[ -n $_pp_prev ]] || return 0
    local -a p=(${=_pp_prev})
    _pp_out ${_pp_payload[$p[2]-still]//@ID@/$p[1]}${_pp_payload[strip-still]//@ID@/$p[3]}
    _pp_prev=
}

_pp_precmd() {
    local variant=ok id
    (( ${STARSHIP_CMD_STATUS:-0} == 0 )) || variant=err
    _pp_header
    (( ! _pp_stale )) || _pp_restyle
    _pp_load || { _pp_glyph='❯ ' _pp_strip=; return; }
    _pp_freeze
    id=$(( ((RANDOM << 9) ^ RANDOM) % 16777214 + 1 ))
    _pp_sid=$(( ((RANDOM << 9) ^ RANDOM) % 16777214 + 1 ))
    _pp_out ${_pp_payload[$variant]//@ID@/$id}${_pp_payload[strip]//@ID@/$_pp_sid}
    (( ! _pp_lamp_check )) || _pp_lamp
    _pp_prev="$id $variant $_pp_sid"
    _pp_glyph="%3{"$'\e[38;2;'$(( id >> 16 & 255 ))\;$(( id >> 8 & 255 ))\;$(( id & 255 ))$'m\U10EEEE\u0305\u0305\U10EEEE\U10EEEE\e[39m'"%} "
    _pp_strip_build
}

TRAPWINCH() {
    _pp_strip_build
    zle && zle reset-prompt
}

_pp_restyle() {
    _pp_stale=0 _pp_payload=()
    (( ! $+functions[_ls_colors] )) || _ls_colors
    _pp_load || return 0
    [[ -z $_pp_title_art ]] || _pp_out "$(<$_pp_title_art)"
}

TRAPUSR1() {
    _pp_stale=1 _pp_lamp_check=1
    zle || return 0
    _pp_restyle
    if [[ -n $_pp_prev ]]; then
        local -a p=(${=_pp_prev})
        _pp_out ${_pp_payload[$p[2]]//@ID@/$p[1]}${_pp_payload[strip]//@ID@/$p[3]}
    fi
    _pp_lamp
    _pp_header
    _pp_strip_build
    zle reset-prompt
    return 0
}

_pp_unregister() { rm -f $_pp_dir/shells/$$ }

if _pp_measure; then
    [[ -z $TMUX ]] || _pp_lamp_check=1
    mkdir -p $_pp_dir/shells
    () {
        local st=$(</proc/$$/stat)
        print -r -- ${${=st##*\) }[20]} >| $_pp_dir/shells/$$
    }
    autoload -Uz add-zsh-hook
    add-zsh-hook zshexit _pp_unregister
    add-zsh-hook precmd _pp_precmd
    add-zsh-hook preexec _pp_freeze
    _pp_starship=$PROMPT
    PROMPT='${_pp_hdr}${_pp_strip}'$'\n''${_pp_glyph}'
    RPROMPT=
else
    PROMPT+=$'\n''%(?.%F{green}.%F{red})❯%f '
fi
