from functools import wraps
from flask import Blueprint, jsonify, request
from marshmallow import ValidationError
from werkzeug.security import check_password_hash
import jwt
import datetime
from services.contrators_service import (
    create_contrators, get_all_installations, take_installation, get_assigned_installation, init_installation, finish_installation, orden_instalacion, datos_instalacion, generar_pdf_instalacion, consulta_contratista_por_usuario, 
)
from schemas.contrators_shema import (
    ConstraSchema, InitInstallSchema, FinishInstallSchema, DateOrderInstallSchema, LoginSchema, validate_data,
)


SECRETA_KEY = "miclavesegura456"
contrators_bp = Blueprint("contrators", __name__)


# Decorador para validar el token de autenticación del contratista
def contratista_token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get("Authorization")
        if not token:
            return jsonify({"error": "Token es requerido"}), 401
        try:
            data = jwt.decode(token, SECRETA_KEY, algorithms=["HS256"])
            # Verifica que el token sea de un contratista
            if "contratista_id" not in data:
                return jsonify({"error": "Token inválido para contratista"}), 401
            request.contratista_ci_rif = data["contratista_id"]
        except jwt.ExpiredSignatureError:
            return jsonify({"error": "El token ha expirado"}), 401
        except jwt.InvalidTokenError:
            return jsonify({"error": "Token inválido"}), 401
        return f(*args, **kwargs)
    return decorated



# Decorador para manejar errores
def handle_errors(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except Exception as e:
            return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500
    return decorated


@contrators_bp.route("/api/v1/contrators/create", methods=["POST"])
@handle_errors
def create_contrator():
    """
    Endpoint para crear un nuevo contratista.
    :return: Un mensaje de éxito o error.
    :raises 400: Si los datos son inválidos o faltan campos requeridos.
    """
    data = request.json
    try:
        contrator_schema = ConstraSchema()
        contrator_data = contrator_schema.load(data)
        contrator = create_contrators(contrator_data)
        return jsonify({"message": "Contratista creado exitosamente", "contrator": contrator}), 201
    except ValidationError as err:
        return jsonify({"error": "Datos inválidos", "details": err.messages}), 400
    

@contrators_bp.route("/api/v1/contrators/login", methods=["POST"])
@handle_errors
def login_contrator():
    """
    Ruta para que el contratista inicie sesión.
    :return: Un token JWT si las credenciales son correctas.
    :raises 400: Si faltan datos en la solicitud o los datos son inválidos.
    :raises 401: Si las credenciales son incorrectas.
    """
    data = request.get_json()

    # Validar los datos usando LoginSchema
    validation_error = validate_data(LoginSchema(), data)
    if validation_error:
        return jsonify(validation_error), 400

    usuario = data.get("USUARIO")
    contraseña = data.get("CONTRASEÑA")

    try:
        # Obtener el contratista por su nombre de usuario
        contratista = consulta_contratista_por_usuario(usuario)
        if not contratista:
            return jsonify({"error": "Usuario o contraseña incorrectos"}), 401

        # Verificar la contraseña
        if not check_password_hash(contratista["CONTRASEÑA"], contraseña):
            return jsonify({"error": "Usuario o contraseña incorrectos"}), 401

        # Generar el token JWT
        token = jwt.encode(
            {
                "contratista_id": contratista["id"],
                "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1)
            },
            SECRETA_KEY,
            algorithm="HS256"
        )
        return jsonify({"token": token}), 200
    except Exception as e:
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500
    

#Ruta menu para el contratista 
@contrators_bp.route("/api/v1/contrators/menu", methods=["GET"])
@contratista_token_required
@handle_errors
def contratista_menu():
    """
    Ruta para obtener el menu de opciones del contratista. 
    :return: Un diccionario con las opciones del contratista. 
    """
    menu = {
        "opciones": 
        [
             {"nombre": "instalaciones disponibles", "ruta": "/api/v1/contrators/installations"},
             {"nombre": "instalaciones asignadas", "ruta": "/api/v1/contrators/assigned_installations/"},
             {"nombre": "tomar instalacion", "ruta": "/api/v1/contrators/take_installations"},
             {"nombre": "iniciar instalacion", "ruta": "/api/v1/contrators/init_installation"},
             {"nombre": "finalizar instalacion", "ruta": "/api/v1/contrators/finish_installation"},
             {"nombre": "orden de instalacion", "ruta": "/api/v1/contrators/order_installation"},
             {"nombre": "datos de instalacion", "ruta": "/api/v1/contrators/data_installation"},
             {"nombre": "generar PDF de instalacion", "ruta": "/api/v1/contrators/generate_pdf_installation"},
         ]
    }
    return jsonify(menu), 200


#Instalaciones disponibles para el contratista
@contrators_bp.route("/api/v1/contrators/installations", methods=["GET"])
@contratista_token_required
@handle_errors
def get_installations():
    """
    Ruta para obtener todas las instalaciones disponibles para el contratista.
    :return: Una lista de instalaciones disponibles.
    """
    installations = get_all_installations()
    return jsonify({"installations": installations}), 200


#Instalaciones asignadas al contratista
@contrators_bp.route("/api/v1/contrators/assigned_installations", methods=["GET"])
@contratista_token_required
@handle_errors  
def get_assigned_installations():
    """
    Ruta para obtener las instalaciones asignadas al contratista.
    :return: Una lista de instalaciones asignadas.
    """
    assigned_installations = get_assigned_installation(request.contratista_ci_rif)
    return jsonify({"assigned_installations": assigned_installations}), 200


#Tomar una instalacion
@contrators_bp.route("/api/v1/contrators/take_installations", methods=["POST"])
@contratista_token_required
@handle_errors
def take_installation_route():
    """
    Ruta para que el contratista tome una instalación.
    :return: Un mensaje de éxito o error.
    """
    data = request.json
    try:
        result = take_installation(data, request.contratista_ci_rif)
        if isinstance(result, dict) and "error" in result:
            return jsonify(result), 400
        return jsonify({"message": "Instalación tomada exitosamente"}), 200
    except ValidationError as err:
        return jsonify({"error": "Datos inválidos", "details": err.messages}), 400


#Iniciar una instalacion
@contrators_bp.route("/api/v1/contrators/init_installation/<Nro_orden>", methods=["POST"])
@contratista_token_required
@handle_errors
def init_installation_route(Nro_orden):
    """
    Ruta para que el contratista inicie una instalación.
    :return: Un mensaje de éxito o error.
    """
    data = request.json
    try:
        init_installation_schema = InitInstallSchema()
        init_installation_data = init_installation_schema.load(data)
        init_installation(init_installation_data, request.contratista_ci_rif)
        return jsonify({"message": "Instalación iniciada exitosamente"}), 200
    except ValidationError as err:
        return jsonify({"error": "Datos inválidos", "details": err.messages}), 400



#Finalizar una instalacion
@contrators_bp.route("/api/v1/contrators/finish_installation/<Nro_orden>", methods=["POST"])
@contratista_token_required
@handle_errors
def finish_installation_route(Nro_orden):
    """
    Ruta para que el contratista finalice una instalación.
    :return: Un mensaje de éxito o error.
    """
    data = request.json
    try:
        finish_installation_schema = FinishInstallSchema()
        finish_installation_data = finish_installation_schema.load(data)
        finish_installation(finish_installation_data, request.contratista_ci_rif)
        return jsonify({"message": "Instalación finalizada exitosamente"}), 200
    except ValidationError as err:
        return jsonify({"error": "Datos inválidos", "details": err.messages}), 400



# Datos para el pdf de la orden de instalacion
@contrators_bp.route("/api/v1/contrators/order_installation", methods=["POST"])
@contratista_token_required
@handle_errors
def order_installation_route():
    """
    Ruta para que el contratista obtenga el pdf de la orden de instalación.
    :return: Un mensaje de éxito o error.
    """
    data = request.json
    try:
        date_order_install_schema = DateOrderInstallSchema()
        date_order_install_data = date_order_install_schema.load(data)
        orden_instalacion(date_order_install_data, request.contratista_ci_rif)
        return jsonify({"message": "Orden de instalación obtenida exitosamente"}), 200
    except ValidationError as err:
        return jsonify({"error": "Datos inválidos", "details": err.messages}), 400



#Datos del pdf de la orden instalacion
@contrators_bp.route("/api/v1/contrators/data_installation/<id>", methods=["GET"])
@contratista_token_required
@handle_errors
def data_installation_route(id):
    """
    Ruta para que el contratista obtenga los datos del pdf de una orden de instalacion.
    :return: Un mensaje de éxito o error.
    """
    data = request.json
    try:
        datos_instalacion(data, request.contratista_ci_rif)
        return jsonify({"message": "Datos de instalación obtenidos exitosamente"}), 200
    except ValidationError as err:
        return jsonify({"error": "Datos inválidos", "details": err.messages}), 400

   
    
#Generar PDF de instalacion
@contrators_bp.route("/api/v1/contrators/generate_pdf_installation/<Nro_orden>", methods=["POST"])
@contratista_token_required
@handle_errors
def generate_pdf_installation_route(Nro_orden):
    """
    Ruta para que el contratista genere un PDF de una instalación.
    :return: Un mensaje de éxito o error.
    """
    data = request.json
    try:
        generar_pdf_instalacion(data, request.contratista_ci_rif)
        return jsonify({"message": "PDF de instalación generado exitosamente"}), 200
    except ValidationError as err:
        return jsonify({"error": "Datos inválidos", "details": err.messages}), 400