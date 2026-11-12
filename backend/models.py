from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer, ForeignKey, Text
from sqlalchemy.orm import relationship
from database import Base


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="operator")  # admin | operator
    created_at = Column(DateTime, default=datetime.utcnow)


class System(Base):
    __tablename__ = "systems"
    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False)
    ip = Column(String, nullable=False)
    os = Column(String, nullable=False)
    cpu = Column(String, default="-")
    ram = Column(String, default="-")
    uptime = Column(String, default="-")
    last_seen = Column(DateTime, nullable=True)
    events = relationship("SystemEvent", back_populates="system", cascade="all, delete-orphan")


class SystemEvent(Base):
    __tablename__ = "system_events"
    id = Column(Integer, primary_key=True, autoincrement=True)
    system_id = Column(String, ForeignKey("systems.id"), nullable=False)
    type = Column(String, nullable=False)
    message = Column(String, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)
    system = relationship("System", back_populates="events")


class Command(Base):
    """دستوراتی که بک‌اند برای Agent هر سیستم صف می‌کنه"""
    __tablename__ = "commands"
    id = Column(Integer, primary_key=True, autoincrement=True)
    system_id = Column(String, ForeignKey("systems.id"), nullable=False)
    action = Column(String, nullable=False)  # shutdown | restart | ...
    status = Column(String, default="pending")  # pending | delivered | done | failed
    created_at = Column(DateTime, default=datetime.utcnow)
    delivered_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    result = Column(Text, nullable=True)
