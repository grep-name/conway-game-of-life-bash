#!/bin/bash

# --- Setup ---
trap 'tput cnorm; tput sgr0; clear; exit' INT TERM
tput smcup
tput civis
stty -echo

WIDTH=$(tput cols)
HEIGHT=$(( $(tput lines) - 3 )) 
(( WIDTH % 2 != 0 )) && (( WIDTH-- ))
COLS=$(( WIDTH / 2 ))

declare -a grid
for ((i=0; i<COLS*HEIGHT; i++)); do grid[$i]=0; done

# --- UI Components ---
draw_header() {
    tput cup 0 0
    # Bright Yellow Header
    printf "\e[1;93mMODE: %-10s | Arrows: Move | Space: Toggle | Enter: Start\e[0m\n" "$1"
    printf "\e[33m%${WIDTH}s\e[0m" | tr " " "-"
}

draw_cell() {
    local x=$1 y=$2 state=$3
    tput cup $((y + 2)) $((x * 2))
    if [[ $state -eq 1 ]]; then
        printf "\e[32m██\e[0m" 
    else
        printf "  "
    fi
}

render_cursor() {
    local x=$1 y=$2
    local idx=$((y * COLS + x))
    tput cup $((y + 2)) $((x * 2))
    # Teal if Dead, Magenta if Alive
    if [[ ${grid[$idx]} -eq 1 ]]; then
        printf "\e[45m██\e[0m" 
    else
        printf "\e[46m  \e[0m" 
    fi
}

# --- Splash Screen ---
clear
printf "\e[1;36m[ Conway's Game of Life ]\e[0m\n\n"
printf "  \e[1;32m[R]\e[0m Quick Mode (Random)\n"
printf "  \e[1;32m[M]\e[0m Manual Selection (TUI)\n"

while true; do
    read -rsn1 choice
    [[ "$choice" =~ [RrMm] ]] && break
done

if [[ "$choice" =~ [Rr] ]]; then
    for ((i=0; i<COLS*HEIGHT; i++)); do grid[$i]=$((RANDOM % 2)); done
else
    clear
    draw_header "MANUAL"
    cx=$((COLS / 2))
    cy=$((HEIGHT / 2))
    
    # Draw initial blank state
    for ((y=0; y<HEIGHT; y++)); do
        tput cup $((y + 2)) 0
        printf "%${WIDTH}s" ""
    done

    while true; do
        render_cursor $cx $cy
        
        # The FIX: Using IFS= to ensure Space isn't eaten
        IFS= read -rsn1 key
        
        if [[ $key == $'\e' ]]; then
            read -rsn2 -t 0.001 rest
            key+="$rest"
        fi

        # Restore cell before moving
        draw_cell $cx $cy ${grid[cy * COLS + cx]}

        case "$key" in
            $'\e[A') ((cy > 0)) && ((cy--)) ;;
            $'\e[B') ((cy < HEIGHT-1)) && ((cy++)) ;;
            $'\e[C') ((cx < COLS-1)) && ((cx++)) ;;
            $'\e[D') ((cx > 0)) && ((cx--)) ;;
            " ") 
                idx=$((cy * COLS + cx))
                grid[$idx]=$(( 1 - grid[$idx] ))
                # Stay in loop, just redraw
                ;;
            "") # Enter key ONLY triggers simulation
                break 
                ;;
        esac
    done
fi

# --- Simulation Loop ---
clear
draw_header "RUNNING"
while true; do
    frame=""
    declare -a next_grid
    
    for ((y=0; y<HEIGHT; y++)); do
        line=""
        for ((x=0; x<COLS; x++)); do
            idx=$((y * COLS + x))
            
            # Neighbors
            n=0
            for dy in -1 0 1; do
                for dx in -1 0 1; do
                    (( dx == 0 && dy == 0 )) && continue
                    nx=$(( (x + dx + COLS) % COLS ))
                    ny=$(( (y + dy + HEIGHT) % HEIGHT ))
                    (( n += grid[ny * COLS + nx] ))
                done
            done

            curr=${grid[$idx]}
            if [[ $curr -eq 1 ]]; then
                if [[ $n -eq 2 || $n -eq 3 ]]; then next_grid[$idx]=1; line+="\e[32m██\e[0m";
                else next_grid[$idx]=0; line+="  "; fi
            else
                if [[ $n -eq 3 ]]; then next_grid[$idx]=1; line+="\e[32m██\e[0m";
                else next_grid[$idx]=0; line+="  "; fi
            fi
        done
        frame+="$line\n"
    done

    tput cup 2 0
    printf "%b" "$frame"
    grid=("${next_grid[@]}")
done