#!/bin/bash

# cleanup after the program ends
trap 'tput cnorm; tput sgr0; clear; exit' INT TERM
tput smcup  #swithces to alternative screen buffer
tput civis  #set cursor to invisible
stty -echo  #hide escape sequences

# calucating width and height to correctly render the game
WIDTH=$(tput cols)
HEIGHT=$(( $(tput lines) - 3 )) 
(( WIDTH % 2 != 0 )) && (( WIDTH-- ))
COLS=$(( WIDTH / 2 ))

# draws the tooltip menu on top of the screen
draw_header() {
    tput cup 0 0 
    printf "\e[1;93mMODE: %-10s | Arrows: Move | Space: Toggle | Enter: Start | R: Restart\e[0m\n" "$1"
    printf "\e[33m%${WIDTH}s\e[0m" | tr " " "-"
}


# cell renderer 
draw_cell() {
    local x=$1 y=$2 state=$3
    tput cup $((y + 2)) $((x * 2))
    [[ $state -eq 1 ]] && printf "\e[32m██\e[0m" || printf "  "
}


# renders the selection cursor
render_cursor() {
    local x=$1 y=$2 idx=$((y * COLS + x))
    tput cup $((y + 2)) $((x * 2))
    [[ ${grid[$idx]} -eq 1 ]] && printf "\e[45m██\e[0m" || printf "\e[46m  \e[0m"
}


# start of the main logical loop
while true; do
    declare -a grid
    # fills the grid with dead cells to start with
    for ((i=0; i<COLS*HEIGHT; i++)); do grid[$i]=0; done

    clear
    printf "\e[1;36m[ Conway's Game of Life ]\e[0m\n\n"
    printf "  \e[1;32m[R]\e[0m Quick Mode (Random)\n"
    printf "  \e[1;32m[M]\e[0m Manual Selection (TUI)\n"
    printf "  \e[1;31m[Q]\e[0m Quit\n"

    # holds the program while the user selects the gamemode
    while true; do
        read -rsn1 choice
        [[ "$choice" =~ [RrMmQq] ]] && break
    done

    # quits the program
    [[ "$choice" =~ [Qq] ]] && { tput cnorm; tput sgr0; clear; exit; }

    # Random mode 
    if [[ "$choice" =~ [Rr] ]]; then
        for ((i=0; i<COLS*HEIGHT; i++)); do grid[$i]=$((RANDOM % 2)); done

    # mannual TUI mode
    else
        clear
        draw_header "MANUAL"
        cx=$((COLS / 2)) cy=$((HEIGHT / 2))
        
        # Clear play area
        for ((y=0; y<HEIGHT; y++)); do tput cup $((y + 2)) 0; printf "%${WIDTH}s" ""; done

        while true; do
            render_cursor $cx $cy
            IFS= read -rsn1 key
            [[ $key == $'\e' ]] && { read -rsn2 -t 0.001 rest; key+="$rest"; }

            draw_cell $cx $cy ${grid[cy * COLS + cx]}

            case "$key" in
                $'\e[A') ((cy > 0)) && ((cy--)) ;;
                $'\e[B') ((cy < HEIGHT-1)) && ((cy++)) ;;
                $'\e[C') ((cx < COLS-1)) && ((cx++)) ;;
                $'\e[D') ((cx > 0)) && ((cx--)) ;;
                " ") idx=$((cy * COLS + cx)); grid[$idx]=$(( 1 - grid[$idx] )) ;;
                "r"|"R") continue 2 ;; # Jumps to the start of the outer while loop
                "") break ;; 
            esac
        done
    fi

    # Simulation starting point
    clear
    draw_header "RUNNING"
    while true; do
        # check for restart key
        read -rsn1 -t 0.05 input 
        [[ "$input" == "r" || "$input" == "R" ]] && break # Breaks to outer loop

        frame=""
        declare -a next_grid
        for ((y=0; y<HEIGHT; y++)); do
            line=""
            for ((x=0; x<COLS; x++)); do
                idx=$((y * COLS + x))
                n=0
                for dy in -1 0 1; do
                    for dx in -1 0 1; do
                        (( dx == 0 && dy == 0 )) && continue
                        nx=$(( (x + dx + COLS) % COLS ))
                        ny=$(( (y + dy + HEIGHT) % HEIGHT ))
                        (( n += grid[ny * COLS + nx] ))
                    done
                done

                if [[ ${grid[$idx]} -eq 1 ]]; then
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
done