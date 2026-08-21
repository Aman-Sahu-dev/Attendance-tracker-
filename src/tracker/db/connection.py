import sqlite3

DB_PAth = "attendance.db"

def get_connection():
    return sqlite3.connect(DB_PAth)
