#!/usr/bin/env bash
shopt -s extglob 2> /dev/null 
setopt extended_glob 2> /dev/null 
setopt KSH_ARRAYS 2> /dev/null 
tput civis
trap "tput cnorm; tput sgr0; clear; exit 1" SIGINT SIGTERM EXIT

if [[ -z $1 ]];then blocks=0; else blocks=1 ;fi

bound_color=3
snake_color=2
appale_color=1
score_color=6
clock_color=8


if [[ $blocks -eq 1 ]];then
    tputseta="setab"
else
    tputseta="setaf"
fi

die() {
    tput sgr0
    clear
    game_over="GAME OVER!"
    l=${#game_over}
    tput cup $((heigth / 2)) $((width / 2 - $l / 2))
    printf -- "$(tput setaf 1)$game_over"
    result="Score: $score"
    l=${#result}
    tput cup $((heigth / 2 + 1)) $((width / 2 - $l / 2))
    printf -- "$(tput setaf 1)$result"
    read
    main
}

hide_input() {
        tput cup $heigth 0
	    printf -- "$(tput $tputseta $bound_color)$(tput setaf $bound_color)"
}

draw_boundaries() {
    tput sgr0
    width=`tput cols`
    heigth=`tput lines`
    i=0
    clear
    while [[ $i -le $width ]];do
        tput cup 1 $i
        printf -- "$(tput $tputseta $bound_color)$(tput setaf $bound_color)#"
        tput cup $heigth $i
        printf -- "$(tput $tputseta $bound_color)$(tput setaf $bound_color)#"
        i=$((i+1))
    done
    i=1
    while [[ $i -le $heigth ]];do
        tput cup $i 0
        printf -- "$(tput $tputseta $bound_color)$(tput setaf $bound_color)#"
        tput cup $i $width
        printf -- "$(tput $tputseta $bound_color)$(tput setaf $bound_color)#"
        i=$((i+1))
    done
    hide_input
    tput sgr0
}

read_key() {
    read -t 0.001 -s -n 1 key 2> /dev/null || read -t 0.001 -s -k 1 key 2> /dev/null
    if [[ ${key:-0} == "w" ]];then 
        if [[ yspeed -ne 1 ]]; then
            yspeed=-1; xspeed=0;
        fi
    elif [[ ${key:-0} == "a" ]];then
        if [[ xspeed -ne 1 ]]; then
            xspeed=-1; yspeed=0;
        fi
    elif [[ ${key:-0} == "s" ]];then 
        if [[ yspeed -ne -1 ]]; then
            yspeed=1; xspeed=0;
        fi
    elif [[ ${key:-0} == "d" ]];then 
        if [[ xspeed -ne -1 ]]; then
            xspeed=1; yspeed=0;
        fi
    elif [[ ${key:-0} == "-" ]];then 
        fps=$((fps - 2));
    elif [[ ${key:-0} == "=" ]];then 
        fps=$((fps + 2));
    elif [[ ${key:-0} == "+" ]];then 
        fps=$((fps + 2));
    elif [[ ${key:-0} == "r" ]];then 
        draw_boundaries
    fi
    key=""
    if [[ $fps -le 0 ]]; then fps=2; fi
    if [[ $fps -gt 125 ]]; then fps=125; fi
    sleep=`printf "scale = 3; 1 / $fps\n" | bc`
    hide_input
}

draw_screen() {
    tput sgr0
    i=0
    last=$((${#prevpos[@]}-1))
    tput cup ${prevpos[$last]} ${prevpos[$((last-1))]}
    printf -- " "
    while [[ $i -lt ${#pos[@]} ]]; do
        tput cup $((${pos[$((i+1))]})) ${pos[$i]}
        if [[ $i -eq 0 ]]; then
            printf -- "$(tput $tputseta $snake_color)$(tput setaf $snake_color)@$(tput sgr0)"
        else 
            printf -- "$(tput $tputseta $snake_color)$(tput setaf $snake_color)0$(tput sgr0)"
        fi
        i=$((i+2))
        hide_input
    done
    tput cup $a_ypos $a_xpos
    printf -- "$(tput setaf $appale_color)$(tput $tputseta $appale_color)O$(tput sgr0)"
    tput cup 0 0
    tput el
    score_board="Score: $score"
    score_board_len=${#score_board}
    tput cup 0 $((width - $score_board_len))
    if [[ $blocks -eq 1 ]];then
        printf -- "$(tput setaf $score_color)$(tput smso)$score_board$(tput sgr0)"
    else
        printf -- "$(tput setaf $score_color)$score_board$(tput sgr0)"
    fi
    tput cup 0 0
    if [[ $blocks -eq 1 ]];then
        printf -- "$(tput setaf $clock_color)$(tput smso)`date +%H:%M`$(tput sgr0)"
    else
        printf -- "$(tput setaf $clock_color)`date +%H:%M`$(tput sgr0)"
    fi
    hide_input
}

move_snake() {
    i=0
    prevpos=("${pos[@]}")
    while [[ $i -lt ${#pos[@]} ]]; do
        if [[ $i -eq 0 ]];then
            pos[0]=$((${pos[0]} + $xspeed))
            pos[1]=$((${pos[1]} + $yspeed))
        else
            pos[$i]=$((${prevpos[$((i-2))]}))
            pos[$((i+1))]=$((${prevpos[$((i-1))]}))
        fi
        i=$((i+2))
    done
    hide_input
}

eat_apple() {
    if [[ ${pos[0]} -eq a_xpos ]] && [[ ${pos[1]} -eq a_ypos ]];then
        pos+=(${pos[$(($last-1))]})
        pos+=(${pos[$last]})
        a_xpos=$((1 + $RANDOM % ($width - 2) ))
        a_ypos=$((2 + $RANDOM % ($heigth - 3) ))
        score=$((score+1))
        if [[ $((score % 5)) -eq 0 ]];then
            fps=$((fps+4))
        fi
    fi
    hide_input
}

detect_collision() {
    if [[ ${pos[0]} -eq 0 ]] ||
    [[ ${pos[0]} -eq $((width-1)) ]] ||
    [[ ${pos[1]} -eq 1 ]] ||
    [[ ${pos[1]} -eq $((heigth-1)) ]]
    then
         die
    fi
    i=2
    while [[ $i -lt ${#pos[@]} ]]; do
        if [[ ${pos[0]} -eq ${pos[$i]} ]] && 
        [[ ${pos[1]} -eq ${pos[$((i+1))]} ]]
        then
            die
        fi
        i=$((i+2))
        tput cup $heigth 0
	    hide_input
    done
    hide_input
}

main() {
    width=`tput cols`
    heigth=`tput lines`
    xspeed=1
    yspeed=0
    pos=($((width / 4)) $((heigth / 2)))
    fps=14
    sleep=`printf "scale = 3; 1 / $fps\n" | bc`
    a_xpos=$((1 + $RANDOM % ($width - 2) ))
    a_ypos=$((2 + $RANDOM % ($heigth - 3) ))
    score=0
    draw_boundaries
    while true; do
        read_key
        move_snake
        draw_screen
        detect_collision
        eat_apple
        sleep $sleep
    done
}

main