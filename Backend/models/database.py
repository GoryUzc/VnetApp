import mysql.connector
from flask import g 
from config import Config


def get_db(): 
    if "db" not in g: 
        g.db = mysql.connector.connect(
            host = "localhost",
            user = "root",
            password = "",
            database = "eclipse_vnet",
            port = 3306
        ) 
    return g.db 
    
def close_db(e=None): 
    db = g.pop("db", None)
    if db is not None:
        db.close()

def init_db(app):
    app.teardown_appcontext(close_db)