from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# ✅ MySQL connection string
SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:@localhost/healthmate"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()



from contextlib import contextmanager
from core.cache_config import redis_client

@contextmanager
def get_cache():
    """الحصول على اتصال Redis (للاستخدام المباشر)"""
    if redis_client:
        yield redis_client
    else:
        yield None
