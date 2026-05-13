#  Conway's Bash of Life

An optimized, terminal-native implementation of Conway's Game of Life written in pure Bash. This project focuses on high-performance rendering and a robust TUI for a language typically constrained by execution speed.

##  Features

*   **Interactive TUI Editor:** A "painter" mode allowing you to move with arrow keys and toggle cells before starting.
*   **Zero-Flicker Rendering:** Full-frame buffering ensures smooth transitions without the typical "scanline" flicker of shell scripts.
*   **Intelligent Cursor:** A context-aware selection block that switches between **Teal** (dead cells) and **Magenta** (live cells) for maximum visibility.
*   **Performance Engineering:** 
    *   Uses **Flat Indexed Arrays** ($O(1)$ lookup) instead of string-keyed associative arrays.
    *   **Differential Updates** in the editor to ensure instantaneous input response.
    *   Pure ANSI escape sequences for color and cursor positioning.
*   **Quick Start:** Randomized universe generation mode for instant action.
*   **Clean Exit:** Robust signal handling to restore your terminal settings and cursor visibility on exit.

##  Controls

| Key | Action |
| :--- | :--- |
| **Arrow Keys** | Move selection cursor |
| **Space** | Toggle cell state (Alive/Dead) |
| **Enter** | Launch the simulation |
| **R** | Instant restart to main menu |
| **Q** | Quit and cleanup terminal |

##  Getting Started

1.  **Clone the script:**
    ```bash
    curl -O [https://raw.githubusercontent.com/yourusername/bash-life/main/life.sh](https://raw.githubusercontent.com/yourusername/bash-life/main/life.sh)
2. **Run the script.**
   ```bash
   ./script.sh
## 🛠️ Technical Implementation

### The Geometry
The script calculates the terminal dimensions using `tput cols` and `tput lines`. Because Unicode blocks (`██`) are twice as wide as they are tall, the script maps two character columns to one logical game column to maintain a 1:1 aspect ratio.

### Optimized Memory
Instead of nested loops or string manipulation for coordinates, the grid is stored in a one-dimensional array. Coordinates $(x, y)$ are calculated using:
$$Index = (y \times \text{Width}) + x$$

### Robust Input
To handle the "Space vs Arrow" problem in Bash, the script uses a non-blocking `read` with a microscopic timeout. This allows it to capture the multi-character escape sequences sent by arrow keys without delaying the recognition of single-character keys like Space or R.

---
**Note:** For best performance, run this in a GPU-accelerated terminal (like Alacritty or Kitty), though it is fully compatible with standard `xterm` and `gnome-terminal`.
