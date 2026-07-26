# RISC-V based APB Bus and Peripheral Design

Verilog HDL을 사용하여 APB Bus 및 BRAM, GPIO, UART, FND Peripheral를 설계하고,<br>
RISC-V 기반 시스템에서 FPGA 동작을 검증한 프로젝트입니다.

## Overview

## Contents

- [System Architecture](#system-architecture)
- [APB Bus](#apb-bus)
  - [APB Protocol](#apb-protocol)
  - [APB Master](#apb-master)
- [APB Peripheral](#apb-peripheral)
  - [BRAM](#bram)
  - [GPIO](#gpio)
  - [UART](#uart)
  - [FND](#fnd)
- [FPGA Test](#fpga-test)

## System Architecture

<img src="images/apb_top.png" width="700">

- RV32I CPU와 APB Master로 구성된 Top-Level 구조
- APB Bus를 통해 BRAM, GPIO, FND, UART Peripheral 제어
- Instruction ROM에 저장된 명령어를 실행하여 APB Peripheral 제어

<img src="images/apb_mem.png" width="300">

- Memory-Mapped I/O 방식 사용
- APB Master는 주소(Address)를 기반으로 BRAM 및 각 Peripheral을 선택하여 Read/Write를 수행

### APB Protocol

<img src="images/apb_write.png" width="600">

- Setup Phase에서 Address 및 Control Signal 설정
- Access Phase에서 PENABLE을 활성화하여 Write 수행
- PREADY가 High가 되면 Transaction 완료

### APB Master

<img src="images/apb_read.png" width="600">

- Setup Phase에서 Address 및 Control Signal 설정
- Access Phase에서 Slave가 PRDATA를 출력
- PREADY가 High가 되면 Transaction 완료

<img src="images/apb_master_bd.png" width="500">

- CPU의 Read/Write 요청을 APB Transaction으로 변환
- Address Decoder를 통해 APB Peripheral 선택
- Read Data 및 Ready MUX를 통해 선택된 Peripheral의 응답 전달

### APB Master FSM

<img src="images/apb_master_fsm.png" width="400">

- **IDLE**
  - Read/Write 요청 대기
- **SETUP**
  - Address를 Decode하여 Peripheral 선택
  - APB Control Signal 출력
- **ACCESS**
  - PENABLE을 활성화하여 APB Transaction 수행
  - PREADY가 High가 되면 Transaction 종료 후 IDLE 상태로 복귀

## APB Peripheral
### BRAM

<img src="images/apb_bram.png" width="400">

- APB Slave Interface 기반 BRAM 설계
- 32-bit 메모리 Read/Write 기능 구현
- PREADY를 이용한 APB Transaction 완료 처리

### GPIO

<img src="images/apb_gpio.png" width="500">

- GPIO_CNTL Register를 이용하여 GPIO의 입출력 방향 제어
- GPIO_ODATA 및 GPIO_IDATA Register를 통해 GPIO 데이터 송수신


### FND

<img src="images/apb_fnd.png" width="500">

- APB Register를 통해 표시할 데이터 저장
- FND Controller를 이용하여 4-Digit 7-Segment Display 제어
- Multiplexing 방식으로 각 Digit을 순차적으로 출력

### UART

<img src="images/apb_uart.png" width="600">

- APB Register를 통해 Baud Rate 및 송수신 데이터 설정
- Baud Tick Generator 기반 UART 통신 타이밍 생성
- TX/RX FSM을 이용하여 Serial 데이터 송수신

## Simulation

### BRAM

<img src="images/apb_bram_sim.png" width="600">

- BRAM 0번 address에 1의 값 write 및 read

### GPIO

<img src="images/apb_gpio_sim.png" width="600">

- GPIO read (32'h0000_00a1)

### FND

<img src="images/apb_fnd_sim.png" width="600">

- FND write (32'h0000_00a1)

### UART

<img src="images/apb_uart_sim1.png" width="800">

- tx_busy read
- tx_data(8'ha1) write

<img src="images/apb_uart_sim2.png" width="800">

- tx_start write
- tx_busy read

## FPGA Test

### 동작 설명
- Switch 입력을 1초 주기로 읽어 FND에 표시
- 입력된 Switch 값에 따라 LED를 반전하며 Blink
- 입력된 Switch 값을 UART를 통해 PC로 전송
- ComportMaster를 통해 PC 데이터 수신 확인

https://github.com/user-attachments/assets/ae2844d9-64f5-49a9-98fb-368255ccf311
