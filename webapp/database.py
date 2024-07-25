from sqlalchemy import create_engine,engine,text
import os
import sqlalchemy




def start_db():
    engine = sqlalchemy.create_engine(f'mysql://{os.getenv("DB_USER")}:{os.getenv("DB_PASSWORD")}@{os.getenv("DB_URL")}')
    #engine = create_engine(f'mysql://{os.getenv("DB_USER")}:{os.getenv("DB_PASSWORD")}@localhost:3306/USER')
    with engine.connect() as conn:
        result = conn.execute(text("CREATE DATABASE IF NOT EXISTS USER")) 
        conn.execute(text("USE USER"))
