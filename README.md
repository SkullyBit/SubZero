# SubZero

**SubZero** is an ultra-low-latency trading connectivity library for C and C++. Built to support high-performance trading systems, it delivers minimal overhead and maximum efficiency for modern financial applications.

SubZero is a fork of [Libtrading](https://github.com/libtrading/libtrading), which served as the foundation for this project. Building upon Libtrading's robust design, SubZero introduces ongoing improvements, optimizations, and new features tailored to high-frequency trading (HFT) environments.

---

## Features

### High-Performance, Low-Latency Design
SubZero is engineered for demanding trading systems, ensuring efficient message handling and near-zero latency.

### Protocol Support
Out-of-the-box support for:
- **FIX** (Financial Information eXchange) - Fully implemented with session and message-handling logic.
- **FIX/FAST** (Financial Information eXchange – Faster FIX) - Fully implemented with session and message-handling logic.
- **SoupBin3** - Provides a transport layer used for some protocols like ITCH.

### In Progress / Planned Protocols
While basic structures for these protocols are included, full implementation (e.g., sessions, message handling, and tools) is planned:
- **ITCH** (used in exchanges for market data dissemination).
- **OUCH** (used for order entry and management at exchanges).

### Modular Architecture
A flexible design simplifies integration into trading systems, enabling rapid deployment and customization.

---

## Getting Started

To get started, refer to the [**SubZero Wiki**](https://github.com/simondevenish/SubZero/wiki). The wiki provides comprehensive documentation, including:
- Installation and build instructions.
- Supported protocols and configuration guides.
- Usage examples for integrating SubZero into trading systems.
- Frequently asked questions and troubleshooting tips.

---

## Roadmap

### Current Status
- **FIX** and **FIX/FAST** are fully supported with tools for both client and server use cases.
- **SoupBin3** is partially implemented to support transport for **ITCH**.

### Future Work
- **ITCH**: Add session handling, message processing, and tools for client/server use.
- **OUCH**: Implement session logic, message handling, and tool support.
- Enhanced testing tools for all supported protocols.
- Add examples for integrating SubZero into production systems.

---

## Why SubZero?

SubZero is designed for financial institutions, quantitative traders, and anyone building low-latency trading systems. It combines performance, extensibility, and ease of use to deliver a library that meets the needs of modern trading platforms.

By leveraging SubZero, developers can focus on implementing their strategies without worrying about the complexities of trading connectivity.
