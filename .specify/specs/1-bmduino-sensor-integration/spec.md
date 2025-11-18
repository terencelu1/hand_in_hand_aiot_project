# Feature Specification: Bmduino Sensor Integration and Communication Setup

**Feature Branch**: `1-bmduino-sensor-integration`
**Created**: 2025-11-10
**Status**: Draft
**Input**: User description: "先做bmdunio的部分，先測試各個感測器，然後要分配bmduino上的接口，最後把資料傳輸給樹梅派，並可以接收樹梅派的訊息"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Test Individual Sensors (Priority: P1)

As a developer, I want to write and run individual test scripts for each sensor (AS608, MAX30102, DHT11, GY-906) on the Bmduino to verify they are working correctly and returning data in the expected format.

**Why this priority**: This is the foundational step to ensure all hardware components are functional before integration.

**Independent Test**: Each sensor can be tested with a dedicated Arduino sketch that prints sensor readings to the Serial Monitor.

**Acceptance Scenarios**:

1. **Given** the AS608 fingerprint sensor is connected, **When** the test script is run, **Then** a fingerprint reading is successfully captured or fails with a clear error message in the Serial Monitor.
2. **Given** the MAX30102 heart rate/SpO2 sensor is connected, **When** the test script is run, **Then** valid (non-zero, within expected range) heart rate and SpO2 values are printed to the Serial Monitor.
3. **Given** the DHT11 temperature/humidity sensor is connected, **When** the test script is run, **Then** valid (non-zero, within expected range) temperature and humidity values are printed to the Serial Monitor.
4. **Given** the GY-906 non-contact temperature sensor is connected, **When** the test script is run, **Then** a valid (non-zero, within expected range) temperature value is printed to the Serial Monitor.

---

### User Story 2 - Establish Bmduino-RPi Communication (Priority: P2)

As a developer, I want to establish a reliable wired communication channel between the Bmduino and the Raspberry Pi, allowing for robust bidirectional data flow.

**Why this priority**: This establishes the critical link between the hardware controller and the central processing unit.

**Independent Test**: A simple "ping-pong" test can be performed where the RPi sends a "ping" message, and the Bmduino responds with a "pong" message, which is then verified by the RPi.

**Acceptance Scenarios**:

1. **Given** the Bmduino and Raspberry Pi are connected via a wired interface (e.g., USB/Serial), **When** the Raspberry Pi sends a "ping" message, **Then** the Bmduino successfully receives it and sends a "pong" message back within 1 second.
2. **Given** the communication channel is established, **When** the Raspberry Pi sends a command to open a specific lock (e.g., `OPEN:2`), **Then** the Bmduino receives the command, parses it correctly, and prints a confirmation to the Serial Monitor (e.g., "Executing command to open lock 2").

---

### User Story 3 - Integrate Sensor Data Transmission (Priority: P3)

As a developer, I want the Bmduino to periodically read data from all connected sensors and transmit it as a single, structured message to the Raspberry Pi.

**Why this priority**: This integrates the hardware testing and communication into a single, functional data-gathering feature.

**Independent Test**: The Raspberry Pi can run a script to listen for incoming data packets from the Bmduino and print the parsed data to the console for verification.

**Acceptance Scenarios**:

1. **Given** all sensors are connected and communication is established, **When** the Bmduino's main loop runs, **Then** a single, structured data packet (e.g., JSON format) containing readings from all sensors is sent to the Raspberry Pi.
2. **Given** the Raspberry Pi is listening for data, **When** a data packet is received, **Then** it successfully parses the packet and logs the values for each sensor without errors.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide individual Arduino sketches (`.ino` files) to test each connected sensor (AS608, MAX30102, DHT11, GY-906) independently.
- **FR-002**: The project documentation MUST clearly define the GPIO pin assignments on the Bmduino for all sensors and the 4-channel relay module.
- **FR-003**: The system MUST implement a bidirectional communication protocol over a wired connection (e.g., Serial over USB) between the Bmduino and Raspberry Pi.
- **FR-004**: The Bmduino MUST send a consolidated data packet containing readings from all sensors to the Raspberry Pi at a regular interval. **[NEEDS CLARIFICATION: What is the required data transmission interval (e.g., every 5 seconds, 30 seconds, 60 seconds)?]**
- **FR-005**: The Bmduino MUST continuously listen for and execute commands received from the Raspberry Pi, specifically commands to activate one of the four relays.
- **FR-006**: The communication protocol MUST include basic error checking to ensure message integrity. **[NEEDS CLARIFICATION: What level of error checking is required (e.g., simple start/end markers, a checksum)?]**

### Key Entities *(include if feature involves data)*

- **SensorDataPacket**: A data structure sent from Bmduino to RPi, containing key-value pairs for each sensor reading. Example: `{"fingerprint_status": "success", "heart_rate": 80, "spo2": 98, "temp": 25.5, "humidity": 60}`.
- **CommandPacket**: A data structure sent from RPi to Bmduino, containing a command and its parameters. Example: `{"command": "open_lock", "lock_id": 2}`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All four specified sensors (AS608, MAX30102, DHT11, GY-906) can be successfully tested and validated independently on the Bmduino, with their data printed to the Serial Monitor.
- **SC-002**: The Raspberry Pi can reliably receive and correctly parse 99.9% of data packets sent from the Bmduino under normal operating conditions.
- **SC-003**: The Bmduino correctly executes 99.9% of valid "open lock" commands received from the Raspberry Pi within 500ms of receipt.
