# MIPS Assembly Projects Collection

This repository contains a collection of advanced MIPS assembly language programs developed as part of the **CSE 3038 Computer Organization** course at **Marmara University (Spring 2026)**. 

The projects demonstrate core assembly concepts including matrix manipulation, dynamic memory allocation, string processing, stack management, and game logic simulations.

---

## 📄 Project Overview & Structure

### 🧮 Question 1: Matrix Diagonal Processor (`Question1.s`)
Processes an $n \times n$ matrix in row-major order to manipulate anti-diagonals ($i + j = d$).
* **Features:** Extracts non-zero elements, sorts them dynamically based on diagonal index parity (Even $d \rightarrow$ Ascending, Odd $d \rightarrow$ Descending), and writes them back while keeping zero elements in place.
* **Evaluation:** Tracks diagonal statistics (Sum, Non-Zero Count) to dynamically determine the "largest" diagonal based on customized multi-tier priority rules.

### 🔤 Question 2: String Manipulator (`Question2.s`)
A state-managed command-line string processor that reads strings character-by-character.
* **Accumulation:** Appends lowercase letters (`a-z`) directly to a buffer.
* **Special Operations:** Implements custom macro commands triggered by special characters:
  * `*` : Delete last character
  * `#` : Duplicate/concatenate the current string onto itself
  * `%` : Reverse the string
  * `!` : Strips all vowels (`a, e, i, o, u`)
  * `?` : **Undo mechanism** that restores the previous valid string state using a secondary backup memory buffer.

### 🃏 Question 3: Card Pair Matching Game (`Question3.s`)
A card matching evaluation system that reads user-defined 2-character card designations.
* **Scoring Rules:** awards points based on matching types (3 pts for reverse matches, 2 pts for matching first letters, 1 pt for matching second letters).
* **Bonus Logic:** Grants consecutive score matching bonuses.
* **Output:** Generates a clean display of optimal pairs and computes the total number of remaining unpaired cards.

### 🎮 Question 4: Two Walkers Matrix Grid Game (`Question4.s`)
A discrete multi-agent simulation running on a dynamically allocated $m \times n$ heap grid memory.
* **Movement Logic:** Walker A starts at $(0,0)$ (moves Right/Down), Walker B starts at $(m-1, n-1)$ (moves Left/Up).
* **AI Pathfinding:** Step-by-step greedy path selection based on neighboring cell values.
* **Collision Resolution:** Implements an advanced programmatic priority system when both walkers target the same cell, resolving conflicts using boundary constraints or lower-score preference rules.

---

## 🛠️ Environment & How to Run

These programs are fully compliant with the **MARS (MIPS Assembler and Runtime Simulator)** environment.

### Prerequisites
* MARS Simulator (JAR file) or MARS-based CLI tools.
* Java Runtime Environment (JRE) installed.

### Execution Steps
1. Open the MARS Simulator.
2. Go to `File -> Open` and select the desired `.s` file (e.g., `Question1.s`).
3. Press `F3` (or click `Assemble`).
4. Press `F5` (or click `Run`) to execute the simulation.
5. Interact with the program using the **Run I/O** tab for inputs/outputs.

---
