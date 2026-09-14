# 2-to-1 Handshake Arbiter (Fixed Priority)

A lightweight SystemVerilog/HDL module that arbitrates data transfers between two upstream producers (**Input A** and **Input B**) targeting a single downstream consumer (**Output Payload**). Flow control is governed by standard `Valid` / `Ready` handshakes with a static, fixed-priority policy.

---

## 📌 Features

* **Fixed Priority Policy:** Input A always takes precedence over Input B during simultaneous requests.
* **Handshake Compliant:** Supports standard `Valid`/`Ready` protocol (data transfers strictly when `Valid` and `Ready` are both HIGH on a clock edge).
* **Zero-Latency Pass-through:** Combinational routing of winning payload and control signals to minimize pipeline overhead.
* **Backpressure Stalling:** Holds the losing channel's `Ready` signal LOW until the winning transfer completes.

---
## ⚙️ Priority Truth Table

| Channel A Request (`Valid_A`) | Channel B Request (`Valid_B`) | Winning Channel | Mux Selection | Active Ready Routing |
| :---: | :---: | :---: | :---: | :---: |
| `0` | `0` | **None** | Idle / Default | None |
| **`1`** | `0` | **Input A** | Channel A | `Ready_Out` $\rightarrow$ `Ready_A` |
| **`1`** | **`1`** | **Input A** *(Priority)* | Channel A | `Ready_Out` $\rightarrow$ `Ready_A` |
| `0` | **`1`** | **Input B** | Channel B | `Ready_Out` $\rightarrow$ `Ready_B` |

> ⚠️ **Note on Starvation:** Under high load, continuous transactions on **Input A** will indefinitely block (**starve**) **Input B**. Use fixed priority only when Input A is latency-critical or low-duty-cycle.

---

## 🔄 Signal Interface

### Inputs
* `i_data_a[N-1:0]`, `i_valid_a` : Data payload and valid handshake from Producer A (High Priority).
* `i_data_b[N-1:0]`, `i_valid_b` : Data payload and valid handshake from Producer B (Low Priority).
* `i_ready_out` : Ready feedback signal from the Consumer.

### Outputs
* `o_ready_a` : Ready backpressure signal to Producer A.
* `o_ready_b` : Ready backpressure signal to Producer B.
* `o_data_out[N-1:0]`, `o_valid_out` : Arbitrated data payload and valid signal to the Consumer.

---

## 🛠 Handshake Protocol Rule

A transaction completes **only** on the rising clock edge where:

$$\text{Handshake Complete} = \text{Valid}_{\text{Winner}} \text{ AND } \text{Ready}_{\text{Out}} == 1$$

If `Ready_Out` is LOW, the winning channel retains control of the output bus, and its payload remains stable until the downstream receiver accepts the frame.

## Output 
### Waveform
<img width="935" height="303" alt="image" src="https://github.com/user-attachments/assets/4cdbaef8-f10b-4f86-8f2c-b09b854e4873" />

### Simulation Terminal
<img width="389" height="170" alt="image" src="https://github.com/user-attachments/assets/c32abb75-ca06-4b23-aeb9-484f30b06822" />

