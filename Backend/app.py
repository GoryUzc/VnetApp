from flask import Flask
from routes.admin import admin_bp # Importacion de la ruta de los modulos 
from routes.clients import clients_bp # Importacion de la base de datos
from routes.contrators import contrators_bp # Importacion de la configuracion de la base de datos
from models.database import init_db
from config import Config 
from flask_cors import CORS 
from flask_socketio import SocketIO



app = Flask(__name__)
app.config.from_object(Config) # Configuracion de la base de datos
socketio = SocketIO(app, cors_allowed_origins="*") # Inicializar SocketIO con la aplicacion Flask

CORS(app) # Habilitar CORS para la aplicacion
 
init_db(app) # Inicializar la base de datos

#Registrar los blueprints de las rutas
app.register_blueprint(admin_bp)
app.register_blueprint(clients_bp)
app.register_blueprint(contrators_bp)


if __name__ == '__main__':
 app.run(host="0.0.0.0", port=5000, debug=True)  # Iniciar la aplicacion en el puerto 5000 y habilitar el modo de depuracion

