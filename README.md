# ⚡ Quantum Janitor: Sector 7

> A 68k Assembly game where you clean quantum anomalies before entropy tears space apart.

![Platform](https://img.shields.io/badge/platform-EASy68K-blue)
![Language](https://img.shields.io/badge/language-68k%20Assembly-orange)
![Status](https://img.shields.io/badge/status-working-brightgreen)

---

## 📖 Description

You are a **Quantum Janitor** assigned to Sector 7.
Your job is to pick a mission, choose the right tool, and resolve anomalies
before your entropy hits **120** or your energy drops to **0**.

The twist? **Gravity can invert at any moment** — flipping how every
collision resolves. A hit that normally damages you might charge you up.
A clean dodge might tear a hole in space.

---

## 🎮 Gameplay

  each round:

1) choose your tool

2) choose a mission

3) game checks your energy

4) physics randomly inverts (or not)

5) anomaly is resolved → hit or miss

6) stats update → game checks if you survived

7) press any key to continue or 0 to quit


---

## 🛠️ Tools

| Tool | ID | Best on |
|---|---|---|
| Tachyon Broom | `1` | Mission 1 — guaranteed dodge |
| Gravity Boots | `2` | Mission 3 — guaranteed dodge |

---

## 🎯 Missions

| Mission | Cost | Description |
|---|---|---|
| Patrol | 10 energy | Low risk sweep of the sector |
| Scout Anomaly | 15 energy | Investigate a quantum disturbance |
| Full Cleanup | 20 energy | High-risk total anomaly removal |

---

## ⚙️ Physics System

| Event | Normal Gravity | Inverted Gravity |
|---|---|---|
| HIT | -8 energy, +8 entropy | +12 energy (charged!) |
| MISS | -8 entropy | +8 entropy (space torn) |

---

## 📊 Stats

| Stat | Start | Game Over if... |
|---|---|---|
| ⚡ Energy | 50 | reaches 0 |
| 🌀 Entropy | 0 | reaches 120 |

---

## 🚀 How to Run

1. Open **EASy68K Editor/Assembler**
2. Load `project.S68`
3. Press **Assemble** → then **Run**
4. Play in the **Sim68K I/O** window

---

## 🐛 Known Bugs Fixed

- `ENTROPY` underflow — `0 - 8` wrapped to `248` on byte subtraction → fixed with clamp to 0
- `ENERGY` underflow — same issue on damage → fixed with clamp to 0
- Stack overflow after 10+ rounds — `BSR GAMELOOP` recursive call → replaced with `BRA`
- Game ending after first round — `CLEAR_SCREEN` was at end of round → moved to start
- Replay freeze — `TRAP #4` returned 0 on Enter key → replaced with `TRAP #5` single char read

---

## 📁 Project Info

| Field | Value |
|---|---|
| Author | Ihor Maslovskyi |
| Student ID | C00325691 |
| Date | 03/03/2026 |
| Module | Assembly Project – Option 1 |
| Platform | EASy68K / Sim68K |

---

## 📜 License

Academic project — College of Computing, SETU Carlow.
