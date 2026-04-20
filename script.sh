#!/bin/bash

# the grid
width=$(($(tput cols) / 2))
height=$((( $(tput lines) - 2 )))
declare -A grid

for ((y=0; y<height; y++)); do
    for ((x=0; x<width; x++)); do
        grid[$x,$y]=$((RANDOM%2))
    done
done

while true; do
    printf "\033[H\033[?25l"

    for ((y=0; y<height; y++)); do
        line=""
        for ((x=0; x<width; x++)); do
            if [[ ${grid[$x,$y]} -eq 1 ]]; then
                line+="██"
            else
                line+="  ";
            fi
        done
        echo "$line"
    done

    declare -A new_grid
    for ((y=0; y<height; y++)); do
        for ((x=0; x<width; x++)); do
            neighbors=0
            for i in {-1..1}; do
                for j in {-1..1}; do
                    if [[ $i -eq 0 && $j -eq 0 ]]; then continue;fi
                    neighbors=$((neighbors+grid[$((((x+i+width)%width))),$(((y+j+height)%height))]))
                done
            done

            current_cell=${grid[$x,$y]}
            if [[ $current_cell -eq 1 && ( $neighbors -lt 2 || $neighbors -gt 3 )]]; then
                new_grid[$x,$y]=0
            elif [[ $current_cell -eq 0 && $neighbors -eq 3 ]]; then
                new_grid[$x,$y]=1
            else
                new_grid[$x,$y]=$current_cell
            fi
        done
    done

    for key in "${!new_grid[@]}"; do
        grid[$key]=${new_grid[$key]}
    done

done
