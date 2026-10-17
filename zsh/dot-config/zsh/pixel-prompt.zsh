# Pixel prompt cursor: a JRPG-style gem pointer that rolls once on its own axis, bobs, then rests.
# It's a tiny animated image (pixel-cursor.py) shown through kitty's graphics protocol with
# Unicode placeholders: the prompt contains normal text cells, so zle redraws keep working,
# and kitty plays the frames itself, so nothing runs in the shell while it animates.
# Each prompt gets its own image id, so arrows on older prompts stay still; once a new prompt
# appears, the previous one's animation is replaced by a one-frame still (kitty keeps every image).
# Outside kitty it falls back to a plain colored ❯.
# The newline is added here: zsh's $(starship prompt) strips starship's trailing newline.

typeset -g _pp_glyph

if [[ $TERM != xterm-kitty ]]; then
    PROMPT+=$'\n''%(?.%F{green}.%F{red})❯%f '
    return 0
fi

typeset -g _pp_dir=${XDG_CACHE_HOME:-$HOME/.cache}/pixel-prompt
typeset -g _pp_colors=${XDG_STATE_HOME:-$HOME/.local/state}/theme/colors.json
typeset -g _pp_cell _pp_cache _pp_prev # _pp_prev: "id variant" of the last pointer
typeset -gA _pp_payload

# Cell size in pixels (CSI 16 t -> CSI 6 ; height ; width t): the sprite is drawn to match it
# exactly, so kitty shows it 1:1 instead of resampling the pixel art.
_pp_measure() {
    local reply
    print -n '\e[16t' >/dev/tty
    read -rs -t 0.2 -d t reply </dev/tty || return 1
    reply=${reply##*\[6;}
    _pp_cell=${reply#*;}x${reply%%;*} # WxH
}

# (Re)render after a wallpaper change (new colors) or a font-size change (new cell size).
_pp_load() {
    _pp_cache=$_pp_dir/$_pp_cell
    local last=$_pp_cache/err-still.kgp # written last
    if [[ ! -e $last || $_pp_colors -nt $last ]]; then
        python3 -I ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/pixel-cursor.py \
            ${_pp_cell%x*} ${_pp_cell#*x} $_pp_colors $_pp_cache || return 1
        _pp_payload=()
    fi
    if (( ! ${#_pp_payload} )); then
        _pp_payload[ok]=$(<$_pp_cache/ok.kgp)
        _pp_payload[err]=$(<$_pp_cache/err.kgp)
        _pp_payload[ok-still]=$(<$_pp_cache/ok-still.kgp)
        _pp_payload[err-still]=$(<$_pp_cache/err-still.kgp)
    fi
}

_pp_precmd() {
    local variant=ok id
    (( ${STARSHIP_CMD_STATUS:-0} == 0 )) || variant=err
    _pp_load || { _pp_glyph='❯ '; return; }
    id=$(( ((RANDOM << 9) ^ RANDOM) % 16777214 + 1 )) # 24-bit id, encoded in the fg color
    [[ -n $_pp_prev ]] && print -rn -- ${_pp_payload[${_pp_prev#* }-still]//@ID@/${_pp_prev%% *}} >/dev/tty
    print -rn -- ${_pp_payload[$variant]//@ID@/$id} >/dev/tty
    _pp_prev="$id $variant"
    # Three placeholder cells (row 0, col 0, then the next columns); %3{...%} tells zsh they're 3 wide
    _pp_glyph="%3{"$'\e[38;2;'$(( id >> 16 & 255 ))\;$(( id >> 8 & 255 ))\;$(( id & 255 ))$'m\U10EEEE\u0305\u0305\U10EEEE\U10EEEE\e[39m'"%} "
}

if _pp_measure; then
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _pp_precmd # added after starship's, so STARSHIP_CMD_STATUS is set
    PROMPT+=$'\n''${_pp_glyph}'
else
    PROMPT+=$'\n''%(?.%F{green}.%F{red})❯%f '
fi
