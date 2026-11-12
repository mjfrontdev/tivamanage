from datetime import datetime, timedelta
from typing import List
import asyncio

from fastapi import FastAPI, Depends, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from database import engine, get_db, SessionLocal
from models import Base, System, SystemEvent, User, Command
from schemas import (
    SystemOut, SystemEventOut, PowerAction, HeartbeatIn,
    LoginIn, TokenOut, UserOut, CommandOut, CommandAck,
)
from auth import (
    verify_password, create_access_token, get_current_user,
    require_admin, oauth2_scheme,
)

app = FastAPI(title="Company Systems API")

app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)

ONLINE_THRESHOLD = timedelta(seconds=30)


def is_online(s: System) -> bool:
    if s.last_seen is None:
        return False
    return datetime.utcnow() - s.last_seen < ONLINE_THRESHOLD


def to_out(s: System) -> dict:
    online = is_online(s)
    return {
        "id": s.id, "name": s.name, "ip": s.ip, "os": s.os,
        "cpu": s.cpu if online else "-",
        "ram": s.ram if online else "-",
        "uptime": s.uptime if online else "-",
        "isOnline": online, "last_seen": s.last_seen,
    }


class ConnectionManager:
    def __init__(self):
        self.active: List[WebSocket] = []
    async def connect(self, ws: WebSocket):
        await ws.accept()
        self.active.append(ws)
    def disconnect(self, ws: WebSocket):
        if ws in self.active:
            self.active.remove(ws)
    async def broadcast(self, msg: dict):
        dead = []
        for ws in self.active:
            try:
                await ws.send_json(msg)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(ws)


manager = ConnectionManager()


@app.on_event("startup")
async def startup():
    Base.metadata.create_all(bind=engine)
    asyncio.create_task(periodic_broadcast())


async def periodic_broadcast():
    while True:
        await asyncio.sleep(3)
        try:
            db = SessionLocal()
            systems = db.query(System).all()
            payload = {
                "type": "systems_update",
                "data": [to_out(s) for s in systems],
                "timestamp": datetime.utcnow().isoformat(),
            }
            db.close()
            if manager.active:
                await manager.broadcast(payload)
        except Exception as e:
            print(f"Broadcast error: {e}")


# ============ AUTH ============
@app.post("/auth/login", response_model=TokenOut)
def login(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == form.username).first()
    if not user or not verify_password(form.password, user.hashed_password):
        raise HTTPException(401, "Invalid credentials")
    token = create_access_token({"sub": user.username, "role": user.role})
    return TokenOut(access_token=token, role=user.role, username=user.username)


@app.get("/auth/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
    return user


# ============ SYSTEMS ============
@app.get("/systems", response_model=List[SystemOut])
def list_systems(db: Session = Depends(get_db),
                 user: User = Depends(get_current_user)):
    return [to_out(s) for s in db.query(System).all()]


@app.get("/systems/{sid}", response_model=SystemOut)
def get_system(sid: str, db: Session = Depends(get_db),
               user: User = Depends(get_current_user)):
    s = db.query(System).filter(System.id == sid).first()
    if not s:
        raise HTTPException(404, "System not found")
    return to_out(s)


@app.get("/systems/{sid}/events", response_model=List[SystemEventOut])
def get_events(sid: str, db: Session = Depends(get_db),
               user: User = Depends(get_current_user)):
    return (db.query(SystemEvent)
            .filter(SystemEvent.system_id == sid)
            .order_by(SystemEvent.timestamp.desc()).limit(20).all())


@app.post("/systems/{sid}/power", response_model=SystemOut)
async def power_action(
    sid: str, action: PowerAction,
    db: Session = Depends(get_db),
    user: User = Depends(require_admin),  # فقط admin
):
    s = db.query(System).filter(System.id == sid).first()
    if not s:
        raise HTTPException(404, "System not found")
    if action.action not in ("on", "off"):
        raise HTTPException(400, "action must be 'on' or 'off'")

    if action.action == "on":
        # Wake-on-LAN رو در فاز بعدی می‌شه اضافه کرد.
        # فعلاً فقط پیام ثبت می‌کنیم.
        db.add(SystemEvent(system_id=sid, type="power_on",
                           message=f"Power-on requested by {user.username}",
                           timestamp=datetime.utcnow()))
        db.commit()
        await manager.broadcast({"type": "systems_update",
                                 "data": [to_out(x) for x in db.query(System).all()],
                                 "timestamp": datetime.utcnow().isoformat()})
        return to_out(s)

    # action == "off" → دستور به Agent می‌فرستیم
    cmd = Command(system_id=sid, action="shutdown", status="pending")
    db.add(cmd)
    db.add(SystemEvent(system_id=sid, type="power_off",
                       message=f"Shutdown command queued by {user.username}",
                       timestamp=datetime.utcnow()))
    db.commit()
    db.refresh(cmd)

    await manager.broadcast({"type": "systems_update",
                             "data": [to_out(x) for x in db.query(System).all()],
                             "timestamp": datetime.utcnow().isoformat()})
    return to_out(s)


# ============ HEARTBEAT (Agent) ============
@app.post("/heartbeat")
async def heartbeat(hb: HeartbeatIn, db: Session = Depends(get_db)):
    """Agent روی هر سیستم این رو صدا می‌زنه — بدون auth برای سادگی.
    در production باید با توکن سیستم امن بشه."""
    s = db.query(System).filter(System.id == hb.system_id).first()
    if not s:
        raise HTTPException(404, "System not found")
    was_offline = not is_online(s)
    s.last_seen = datetime.utcnow()
    if hb.cpu: s.cpu = hb.cpu
    if hb.ram: s.ram = hb.ram
    if hb.uptime: s.uptime = hb.uptime
    if was_offline:
        db.add(SystemEvent(system_id=s.id, type="power_on",
                           message="Heartbeat resumed",
                           timestamp=datetime.utcnow()))
    db.commit()
    return {"ok": True}


# ============ COMMANDS (Agent polling) ============
@app.get("/agent/{sid}/commands", response_model=List[CommandOut])
def get_pending_commands(sid: str, db: Session = Depends(get_db)):
    """Agent این رو صدا می‌زنه تا دستورات جدید رو بگیره"""
    cmds = (db.query(Command)
            .filter(Command.system_id == sid, Command.status == "pending")
            .order_by(Command.created_at.asc()).all())
    for c in cmds:
        c.status = "delivered"
        c.delivered_at = datetime.utcnow()
    db.commit()
    return cmds


@app.post("/agent/commands/{cmd_id}/ack")
def ack_command(cmd_id: int, ack: CommandAck, db: Session = Depends(get_db)):
    c = db.query(Command).filter(Command.id == cmd_id).first()
    if not c:
        raise HTTPException(404, "Command not found")
    c.status = ack.status
    c.result = ack.result
    c.completed_at = datetime.utcnow()
    db.commit()
    return {"ok": True}


# ============ WEBSOCKET ============
@app.websocket("/ws")
async def ws_endpoint(ws: WebSocket):
    await manager.connect(ws)
    try:
        db = SessionLocal()
        systems = db.query(System).all()
        await ws.send_json({"type": "systems_update",
                            "data": [to_out(s) for s in systems],
                            "timestamp": datetime.utcnow().isoformat()})
        db.close()
        while True:
            await ws.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(ws)
    except Exception:
        manager.disconnect(ws)


@app.get("/")
def root():
    return {"status": "ok", "service": "Company Systems API v2"}
