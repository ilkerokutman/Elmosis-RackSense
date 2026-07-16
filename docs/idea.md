# Server Cabinet AC & Environmental Controller System

## System Architecture & Technical Specifications

---

## Executive Summary

This document outlines the software and hardware architecture for an embedded, industrial-grade monitoring and control solution designed for server room cabinet cooling units.

The system runs on a **Raspberry Pi 4** driving a **7" capacitive touchscreen** running a custom full-screen **Flutter on Embedded Linux** application. The software provides local real-time monitoring, threshold management, event logging, and cloud synchronization to Azure, while operating completely decoupled from low-level timing loops to guarantee reliability and zero UI latency.

---

## System Layering & Topography

The software is structured into four distinct layers using a clear separation of concerns, managed via reactive state bindings.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                            │
│    Splash  │  Dashboard  │  Settings  │  Sync History  │  Alarms        │
└────────────────────────────────────▲────────────────────────────────────┘
                                     │ Reactive UI Updates (Rx / Obx)
┌────────────────────────────────────┴────────────────────────────────────┐
│                            CONTROLLER LAYER                             │
│  AppController ──► BusinessController ──► AcUnitController ──► SyncCtrl │
└────────────────────────────────────▲────────────────────────────────────┘
                                     │ Validated Data / High-Level Requests
┌────────────────────────────────────┴────────────────────────────────────┐
│                            PROVIDER LAYER                               │
│        DbProvider        │    ApiProvider     │     Hardware Providers  │
└────────────────────────────────────▲────────────────────────────────────┘
                                     │ Low-Level Hardware Drivers / Buses
┌────────────────────────────────────┴────────────────────────────────────┐
│                             HARDWARE LAYER                              │
│  7" Display │ UART Serial │ Shift Registers │ GPIO Inputs │ ADC NTC │ Azure │
└─────────────────────────────────────────────────────────────────────────┘

```

---

## Component Responsibilities

### 1. Hardware & Driver Layer

* **7" Touchscreen:** Provides the physical interactive surface running in borderless kiosk mode.
* **UART Serial Link:** Bi-directional serial bus interfacing directly with the two internal cabinet A/C units for telemetry and command transmission.
* **Output Shift Register:** 8-channel relay output expansion driver managing discrete control lines while conserving Pi GPIO pins.
* **Input Interfaces:** Digital GPIO lines monitoring dry-contact relays (Door status, Smoke detector, Water level sensor) and an analog-to-digital converter (ADC) sampling 4 analog NTC thermistor channels.

---

### 2. Provider Layer (Data & Communication Drivers)

* **Local Database Provider:** Manages local persistence using SQLite FFI bindings suited for Linux Desktop/Embedded. Handles schema creation, queue insertion, and transactional query fetching for un-synced historical logs.
* **API / Cloud Provider:** Manages HTTP REST/MQTT transport pipelines with Azure, handling authorization headers, batch request formatting, and retry timeouts.
* **UART Serial Provider:** Manages Linux serial port configurations (baud rate, parity, stop bits), byte streaming, framing validation, and CRC calculation/checking routines.
* **GPIO & ADC Provider:** Interfaces directly with Linux hardware buses (gpiod/sysfs and SPI/I2C for ADC) to execute pin reads, ADC conversions, and bit-shifter clock sequences.

---

### 3. Controller Layer (Application Logic)

#### **AppController (Parent)**

* Serves as the master root controller managing application lifecycle, system bootstrap states, global error handling, and navigation middleware.

#### **GpioController**

* Functions as the direct hardware abstraction boundary.
* **Outputs:** Encapsulates the 8-bit shift register logic, maintaining cached pin states to ensure bitwise modifications don't corrupt active relay positions.
* **Inputs & Sensing:** Handles digital pin debouncing for door, smoke, and water level switches. Executes voltage-to-resistance-to-temperature math (Steinhart-Hart equation) for NTC thermistor channels.
* **Communications:** Performs frame assembly, CRC-16 generation, and incoming byte string parsing over UART. Drops malformed packets to insulate higher logic from serial noise.

#### **AcUnitController**

* Orchestrates the hardware execution loop. Runs a deterministic background polling loop (every 1–2 seconds) to sample digital inputs, NTC temperatures, and UART A/C statuses via the `GpioController`.
* Accepts high-level UI requests (e.g., "Toggle A/C Unit 1") and translates them into appropriate hardware driver executions.

#### **BusinessController**

* Receives raw structured telemetry from `AcUnitController`.
* Evaluates active operational thresholds (e.g., high-temperature warning limits, auto-failover rules between A/C units).
* Triggers active critical alarm flags and populates human-readable status messages when smoke, water, door, or thermal parameters breach configured limits.
* Automatically hands off verified telemetry snapshots to `DbProvider` for local logging.

#### **SyncController**

* Runs a scheduled background routine (e.g., every 5 minutes) to query the local SQLite store for pending, unsynced telemetry logs.
* Packages batch payloads and sends them to Azure via `ApiProvider`.
* Upon receiving a successful server acknowledgment (HTTP 200/201), marks the corresponding local database records as synced or purges expired logs to minimize storage writes on the SD card.

---

### 4. Presentation Layer (UI Modules)

Designed specifically for touch interaction on a 7-inch embedded panel with high contrast and clear visual zones.

* **Initialization Screen (Splash):** Displays hardware initialization progress, validates local database connections, verifies serial bus presence, and loads system settings before presenting the main interface.
* **Dashboard Module:** Primary view displaying real-time environmental metrics (large-format cabinet temperature reading), visual indicators for Door, Smoke, and Water alarms, and dedicated touch-friendly control cards for toggling A/C Unit 1 and A/C Unit 2.
* **Settings Module:** Allows operators to adjust thermal alarm thresholds, modify A/C alternation schedules, change cloud sync intervals, and configure communication parameters.
* **Sync History Module:** Visualizes local database queue metrics, last successful Azure connection timestamps, pending record counts, and manual sync triggering controls.
* **Alarm Screen:** Full-screen high-priority alert overlay that activates immediately when critical threshold events occur (e.g., smoke detection or severe overheating), flashing actionable recovery instructions and silencer toggles.

---

## CI/CD & Deployment Strategy

To ensure zero cross-compilation toolchain friction between macOS and Linux ARM64:

```
[Mac Mini (M4 Pro)] ─── 1. SSH Command ───► [Raspberry Pi 5 (Build Node)]
        ▲                                                │
        │                                       2. Native Linux Compile
        │                                       3. Zip Output Bundle
        │                                                │
        └────────────── 4. SCP Pull Zip ─────────────────┘
                                │
                      5. Local Zip Archive
                                │
    [Deploy Command] ───────────┴─────────► [Target Pi 4 (Touchscreen Unit)]
                                            - Stop running app
                                            - Replace app bundle
                                            - Apply permissions & launch

```

1. **Mac Mini (Development Node):** Serves as the developer workspace and central build orchestrator. Pubspec version bumps trigger remote orchestration scripts.
2. **Raspberry Pi 5 (Build Server):** Compiles the project natively in a true ARM64 Linux environment, eliminating `glibc` and C++ cross-compiler issues. Generates an executable Linux release bundle zipped with all required library dependencies (`.so` binaries, ICU assets, and asset bundles).
3. **Mac Local Repository:** Downloads and archives versioned build zip files locally (`~/cabinet_builds/app_vX.Y.Z.zip`), allowing instantly selectable or roll-backable deployments to any physical hardware unit.
4. **Target Pi 4 Units:** Receives the deployment bundle via remote execution scripts that gracefully terminate the active instance, extract the new bundle into the application root, update file permissions, and restart the full-screen kiosk execution.