# Tiva

**Real-time system monitoring & control dashboard.**

Tiva is a lightweight, self-hosted platform to monitor, manage, and remotely control the systems in your network — desktops, servers, and NAS devices — from a single, elegant dashboard.

Built with **Flutter** (cross-platform), **FastAPI** (backend), and a tiny **Python agent** that runs on each managed machine.

## Features

- Cross-platform dashboard — Windows, Android, Web
- Real-time updates — WebSocket-based status stream
- Live online/offline detection — 30-second heartbeat threshold
- Remote power control — shutdown / restart via agent
- Real system metrics — CPU, RAM, uptime from psutil
- JWT authentication — admin & operator roles
- Event log — every action recorded and timestamped
- Auto-reconnect — handles backend restarts gracefully

## Architecture
Flutter App <--JWT/WS--> FastAPI Backend <--HTTP--> Python Agent
SQLite + JWT heartbeat + commands

## Quick Start

### Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python seed.py
uvicorn main:app --reload --host 0.0.0.0 --port 8000
flutter pub get
flutter run -d windows
cd agent
pip install -r requirements-agent.txt
python agent.py --system-id 1 --server http://127.0.0.1:8000
Default Credentials
UsernamePasswordRole
adminadmin123admin
operatorop123operator
Change these before production use.

Tech Stack
LayerTechnology
FrontendFlutter, GetX, WebSocket
BackendFastAPI, SQLAlchemy, SQLite, JWT
AgentPython, psutil, requests
License
MIT License. See LICENSE file for details.

Author
Fouad Salehi
