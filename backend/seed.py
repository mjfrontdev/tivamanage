from datetime import datetime, timedelta
from database import SessionLocal, engine, Base
from models import System, SystemEvent, User
from auth import hash_password


def seed():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    # ============ USERS ============
    # چک می‌کنه هر کاربر جداگانه، اگه نبود اضافه می‌کنه
    users_to_create = [
        ("admin", "admin123", "admin"),
        ("operator", "op123", "operator"),
    ]

    for username, password, role in users_to_create:
        existing = db.query(User).filter(User.username == username).first()
        if existing is None:
            db.add(User(
                username=username,
                hashed_password=hash_password(password),
                role=role,
            ))
            print(f"✅ Created user: {username} / {password} ({role})")
        else:
            print(f"⏭️  User '{username}' already exists")

    db.commit()

    # ============ SYSTEMS ============
    if db.query(System).count() == 0:
        now = datetime.utcnow()
        systems = [
            System(id="1", name="Server-01", ip="192.168.1.10", os="Linux",
                   cpu="23%", ram="4.2 GB / 16 GB", uptime="14d 6h", last_seen=now),
            System(id="2", name="Server-02", ip="192.168.1.11", os="Linux",
                   cpu="-", ram="-", uptime="-", last_seen=now - timedelta(hours=2)),
            System(id="3", name="PC-Manager", ip="192.168.1.20", os="Windows",
                   cpu="8%", ram="6.1 GB / 16 GB", uptime="3d 12h", last_seen=now),
            System(id="4", name="PC-Accounting", ip="192.168.1.21", os="Windows",
                   cpu="-", ram="-", uptime="-", last_seen=now - timedelta(minutes=30)),
            System(id="5", name="NAS", ip="192.168.1.30", os="Linux",
                   cpu="5%", ram="2.0 GB / 8 GB", uptime="45d 2h", last_seen=now),
        ]
        for s in systems:
            db.add(s)
            db.add(SystemEvent(
                system_id=s.id,
                type="power_on" if s.cpu != "-" else "power_off",
                message="Initial seed",
                timestamp=now,
            ))
        print(f"✅ Seeded {len(systems)} systems.")
    else:
        print(f"⏭️  Systems already exist ({db.query(System).count()} found)")

    db.commit()
    db.close()
    print("\n🎉 Seed completed!")


if __name__ == "__main__":
    seed()