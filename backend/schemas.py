from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class SystemEventOut(BaseModel):
    id: int
    system_id: str
    type: str
    message: str
    timestamp: datetime
    class Config:
        from_attributes = True


class SystemOut(BaseModel):
    id: str
    name: str
    ip: str
    os: str
    cpu: str
    ram: str
    uptime: str
    isOnline: bool
    last_seen: Optional[datetime]
    class Config:
        from_attributes = True


class PowerAction(BaseModel):
    action: str  # "on" | "off"


class HeartbeatIn(BaseModel):
    system_id: str
    cpu: Optional[str] = "-"
    ram: Optional[str] = "-"
    uptime: Optional[str] = "-"


class LoginIn(BaseModel):
    username: str
    password: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    username: str


class UserOut(BaseModel):
    id: int
    username: str
    role: str
    class Config:
        from_attributes = True


class CommandOut(BaseModel):
    id: int
    action: str
    status: str
    created_at: datetime
    class Config:
        from_attributes = True


class CommandAck(BaseModel):
    command_id: int
    status: str  # done | failed
    result: Optional[str] = None
