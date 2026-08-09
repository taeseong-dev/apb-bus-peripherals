# RISC-V-based APB Bus and Peripheral Design

Verilog/SystemVerilog를 사용하여 APB Bus와 BRAM, GPIO, FND, UART Peripheral을 설계하고, <br>
RV32I CPU와 연동한 Simulation 및 FPGA 검증과 SystemVerilog/UVM 기반 APB 검증을 수행한 프로젝트입니다.

---

## Overview

| 항목 | 내용 |
|:---|:---|
| Language | Verilog, SystemVerilog |
| CPU | RV32I |
| Bus | AMBA APB |
| Peripherals | BRAM, GPIO, FND, UART |
| Verification | Simulation, UVM, FPGA |
| Development Environment | Vivado, VCS, Verdi |
| FPGA Board | Basys3 |

---

## Contents

- [System Architecture](#system-architecture)
- [APB Bus](#apb-bus)
  - [APB Protocol](#apb-protocol)
  - [APB Master](#apb-master)
- [APB Peripheral](#apb-peripheral)
  - [BRAM](#bram)
  - [GPIO](#gpio)
  - [FND](#fnd)
  - [UART](#uart)
- [APB Verification](#apb-verification)
  - [Simulation](#simulation)
  - [UVM Verification](#uvm-verification)
  - [FPGA Test](#fpga-test)

---

## System Architecture

<img src="images/apb_top.png" width="700">

- Instruction ROM, RV32I CPU, APB Master 및 APB Peripheral로 구성된 시스템 구조
- RV32I CPU에서 Instruction ROM의 명령어를 읽어 프로그램 실행
- CPU의 Memory Read/Write 요청을 APB Master에서 APB Transaction으로 변환
- APB Master를 통해 BRAM, GPIO, FND, UART Peripheral 제어

### APB Address Map

<img src="images/apb_mem.png" width="300">

- Memory-Mapped I/O 방식으로 BRAM 및 Peripheral에 접근
- APB Master에서 Address를 Decode하여 대상 Slave 선택
- BRAM과 각 Peripheral에 서로 다른 Base Address 할당

---

## APB Bus

### APB Protocol

#### Write Transfer

<img src="images/apb_write.png" width="600">

- Setup Phase: Address와 Write Data를 출력하고 `PWRITE = 1`, `PSEL = 1`, `PENABLE = 0`
- Access Phase: `PENABLE = 1`, `PREADY = 1`인 Rising Edge에서 Write Transaction 완료

#### Read Transfer

<img src="images/apb_read.png" width="600">

- Setup Phase: Address를 출력하고 `PWRITE = 0`, `PSEL = 1`, `PENABLE = 0`
- Access Phase: Slave에서 `PRDATA`와 `PREADY = 1`을 출력하고, Rising Edge에서 Read Transaction 완료
  
### APB Master

<img src="images/apb_master_bd.png" width="600">

- CPU의 Address, Write Data 및 Read/Write 요청을 APB Transaction으로 변환
- Address Decoder를 통해 대상 Slave를 선택하고 `PSEL0`~`PSEL3` 출력
- 선택된 Slave의 `PRDATA`와 `PREADY`를 MUX하여 CPU의 Read Data와 Ready 신호로 전달

#### APB Master FSM

<img src="images/apb_master_fsm.png" width="400">

- **IDLE**: CPU의 Read/Write 요청 대기
- **SETUP**: Address Decode 및 대상 Slave 선택
- **ACCESS**: `PENABLE = 1`
  - `Ready = 0`: ACCESS 상태 유지
  - `Ready = 1`: IDLE 상태로 복귀

## APB Peripheral

### BRAM

<img src="images/apb_bram.png" width="400">

- `PADDR`로 Memory Address를 선택하고 `PWDATA`와 `PRDATA`를 통해 32-bit Data Read/Write
- `PREADY`를 통해 Read/Write Transaction 완료 전달

### GPIO

<img src="images/apb_gpio.png" width="500">

- `cntl_reg[15:0]`의 각 Bit를 통해 GPIO 방향 제어 (`1`: Output, `0`: Input)
- `GPIO[7:0]`에 연결된 Switch 입력값을 `idata_reg`를 통해 Read
- `odata_reg`를 통해 `GPIO[15:8]`에 연결된 LED 제어

### FND

<img src="images/apb_fnd.png" width="500">

- APB Write Data를 `odata_reg[15:0]`에 저장
- FND Controller에서 표시할 Digit과 7-Segment Data 생성
- `fnd_digit[3:0]`을 순차적으로 선택하여 4-Digit FND 제어

### UART

<img src="images/apb_uart.png" width="600">

- `baud_reg[1:0]` 설정값을 기준으로 UART 송수신에 사용할 Baud Tick 생성
- `cntl_reg[0]`의 Start 신호와 `tx_reg[7:0]`의 Data를 통해 UART TX Data 전송
- UART RX에서 수신한 `rx_data[7:0]`를 APB Read Data로 전달
- `sr_reg` Read를 통해 `tx_busy`와 `rx_ready` 상태 확인

## APB Verification

### Simulation

#### BRAM

<img src="images/apb_bram_sim.png" width="600">

- BRAM 0번 Address에 `32'd1` Write
- BRAM 0번 Address에서 `32'd1` Read

#### GPIO

<img src="images/apb_gpio_sim.png" width="600">

- GPIO IDATA Address에서 `32'h0000_00A1` Read

#### FND

<img src="images/apb_fnd_sim.png" width="600">

- FND ODATA Address에 `32'h0000_00A1` Write

#### UART

<img src="images/apb_uart_sim1.png" width="800">

- UART SR Address에서 `32'h0000_0000` Read
- UART TXDATA Address에 `32'h0000_00A1` Write

<img src="images/apb_uart_sim2.png" width="800">

- UART CNTL Address에 `32'h0000_0001` Write하여 TX Start
- UART SR Address에서 `32'h0000_0001` Read하여 `tx_busy` 확인

### UVM Verification

SystemVerilog/UVM을 사용하여 APB Master와 BRAM, GPIO, FND, UART Peripheral의 동작을 검증하였습니다.

#### UVM Architecture

- APB Sequence / Sequencer / Driver / Monitor / Agent 구성
- GPIO 외부 입력 검증을 위한 GPIO Sequence / Driver / Monitor / Agent 구성
- APB Monitor의 Transaction을 Scoreboard와 Coverage로 전달
- Scoreboard에서 APB Master 및 Peripheral 동작 비교 검증

#### UVM Test Result

| Test              | Verification                                | Result | Coverage |
| :---------------- | :------------------------------------------ | :----: | :------: |
| `apb_random_test` | BRAM, GPIO, FND, UART Random Read/Write 검증 |  PASS  |  100.0%  |
| `gpio_test`       | GPIO 외부 입력 및 IDATA Read 검증            |  PASS  |   50.0%  |
| `uart_test`       | UART TX/RX Loopback 및 Status 검증           |  PASS  |   50.0%  |

> `gpio_test`와 `uart_test`는 특정 Peripheral을 대상으로 수행하므로 APB 전체 Functional Coverage는 50.0%입니다.

##### APB Random Test

<img src="images/apb_uvm_random_test.png" width="700">

##### GPIO Test

<img src="images/apb_uvm_gpio_test.png" width="700">

##### UART Test

<img src="images/apb_uvm_uart_test.png" width="700">



### FPGA Test

#### 동작 설명
- Switch 입력을 1초 주기로 읽어 FND에 표시
- Switch 입력값을 반전하여 LED에 출력하고 Blink 동작 확인
- Switch 입력값을 UART TX를 통해 PC로 전송
- ComportMaster에서 UART Data 수신 확인

[▶ APB Peripheral FPGA 동작 영상](https://github.com/user-attachments/assets/51d14d51-2989-4ad2-ad91-493467bafe8f)
