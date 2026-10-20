[[ -z $SSH_CONNECTION && -n $_pp_cell ]] || return 0
(( COLUMNS >= 70 && LINES >= 16 )) || return 0
if [[ -n $TMUX ]]; then
    # one title per window: panes share the image id, so two on screen restart each other
    [[ $(tmux display -p '#{window_panes}#{@title_win}') == 1 ]] || return 0
    tmux set -wq @title_win 1
else
    [[ -z $_TITLE_SHOWN ]] || return 0
    export _TITLE_SHOWN=1
fi

_title_draw() {
    (( COLUMNS >= 70 && LINES >= 16 )) || return 0
    local dir=$_pp_dir/$_pp_cell zdir=${XDG_CONFIG_HOME:-$HOME/.config}/zsh
    local vars=$dir/title.vars # written last
    if [[ ! -e $vars || $_pp_colors -nt $vars || $zdir/armillary.py -nt $vars || $zdir/pixel-cursor.py -nt $vars ]]; then
        local lock=$dir/.armillary-rendering
        local -a stale=($lock(Nmm+5))
        if [[ ! -e $lock || -n $stale ]]; then
            mkdir -p $dir && : >| $lock
            { python3 -I $zdir/armillary.py ${_pp_cell%x*} ${_pp_cell#*x} $_pp_colors $dir; rm -f $lock } &>/dev/null &!
        fi
        return
    fi

    local -A v=(${=$(<$vars)})
    local -i c0=22
    local -i inner=$(( COLUMNS - c0 - 1 < 60 ? COLUMNS - c0 - 1 : 60 ))
    local -i right=$(( c0 + inner ))
    local E=$'\e' ph=$'\U10EEEE'
    local esc=$E'[38;2;' dim=$E'[2m' rst=$E'[0m'

    local -a quotes=(${(f)"$(<$zdir/quotes.txt)"}) lines
    local q text author line word i
    for i in {1..5}; do
        q="$quotes[RANDOM % ${#quotes} + 1]"
        text=${q%%$'\t'*} author="— ${q#*$'\t'}" lines=() line=
        for word in ${=text}; do
            if (( ${#line} && ${#line} + ${#word} + 1 > inner )); then
                lines+=$line line=$word
            else
                line=${line:+$line }$word
            fi
        done
        lines+=$line
        (( ${#lines} <= 2 && ${#author} <= inner )) && break
    done
    (( ${#lines} <= 2 )) || lines=() author=

    local up=$(</proc/uptime)
    up=${${up%% *}%.*}
    local uptime="up $(( up / 3600 ))h $(( up % 3600 / 60 ))m"
    (( up < 3600 )) && uptime="up $(( up / 60 ))m"
    (( up >= 86400 )) && uptime="up $(( up / 86400 ))d $(( up % 86400 / 3600 ))h"

    local when='%D{%a %-d %b · %-I:%M %p}'
    local -a row=(
        ""
        "${E}[1m$USER$rst$dim @ $HOST${E}[$(( right - ${#uptime} ))G$uptime"
        "$dim${(%)when}"
        "$dim${(l:inner::┈:)}"
        "${E}[3m${lines[1]}"
        "${E}[3m${lines[2]}"
        "${E}[$(( right - ${#author} ))G$dim$author"
        ""
    )
    local -a rowmark=($'\u0305' $'\u030D' $'\u030E' $'\u0310' $'\u0312' $'\u033D' $'\u033E' $'\u033F')
    local id=$v[art_id] fill=${(l:15::x:)} out
    local artfg="${esc}$(( id >> 16 & 255 ));$(( id >> 8 & 255 ));$(( id & 255 ))m"
    fill=${fill//x/$ph}
    _pp_title_art=$dir/armillary.kgp
    _pp_out "$(<$_pp_title_art)"
    for i in {1..8}; do
        out+="$artfg$ph$rowmark[i]"$'\u0305'"$fill$rst${E}[${c0}G$row[i]$rst"$'\n'
    done
    print -rn -- $out
}

clear() { command clear "$@" && _title_draw }

_title_clear_screen() {
    zle -I
    echoti clear
    _title_draw
}
zle -N _title_clear_screen
bindkey '^L' _title_clear_screen

_title_draw

