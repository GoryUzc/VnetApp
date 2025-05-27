import os 


class Config: 
    DEBUG = True # Habilitar el modo de depuracion
    # URL de la base de datos MySQL
    DATABASE_URL = os.getenv(
        "DATABASE_URL", 
        "mysql+pymysqlconnector://root:localhost: 3306/eclipse_vnet")
    