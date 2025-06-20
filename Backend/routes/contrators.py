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
    Crear un nuevo contratista
    ---
    tags:
      - Contratistas
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              ci_rif:
                type: string
                example: "V12345678"
              nombre:
                type: string
                example: "Contratista Ejemplo"
              USUARIO:
                type: string
                example: "contratista1"
              CONTRASEÑA:
                type: string
                example: "clave_segura"
              telefono:
                type: string
                example: "04141234567"
              correo:
                type: string
                example: "correo@ejemplo.com"
              sucursal:
                type: string
                example: "Sucursal Centro"
              cuadrillas:
                type: integer
                example: 3
              cuadrilla1:
                type: string
                example: "Cuadrilla A"
              cuadrilla2:
                type: string
                example: "Cuadrilla B"
              cuadrilla3:
                type: string
                example: "Cuadrilla C"
                cuadrilla4:
                type: string
                example: "Cuadrilla D"
                cuadrilla5:
                type: string
                example: "Cuadrilla E"
                cuadrilla6:
                type: string
                example: "Cuadrilla F"
                cuadrilla7:
                type: string
                example: "Cuadrilla G"
                cuadrilla8:
                type: string
                example: "Cuadrilla H"
                cuadrilla9:
                type: string    
                example: "Cuadrilla I"
                cuadrilla10:
                type: string
                example: "Cuadrilla J"
    responses:
      201:
        description: Contratista creado exitosamente
        examples:
          application/json: { "message": "Contratista creado exitosamente", "contrator": { } }
      400:
        description: Datos inválidos o faltantes
        examples:
          application/json: { "error": "Datos inválidos" }
      500:
        description: Error interno del servidor
        examples:
          application/json: { "error": "Error interno del servidor" }
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
    Iniciar sesión de contratista
    ---
    tags:
      - Contratistas
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              USUARIO:
                type: string
                example: "contratista1"
              CONTRASEÑA:
                type: string
                example: "clave_segura"
    responses:
      200:
        description: Inicio de sesión exitoso, retorna un token JWT.
        examples:
          application/json: { "token": "eyJ0eXAiOiJKV1QiLCJhbGciOi..." }
      400:
        description: Datos inválidos o faltantes.
        examples:
          application/json: { "error": "Datos inválidos" }
      401:
        description: Usuario o contraseña incorrectos.
        examples:
          application/json: { "error": "Usuario o contraseña incorrectos" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
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
   Obtener el menú de opciones del contratista
    ---
    tags:
      - Contratistas
    security:
      - ApiKeyAuth: []
    responses:
      200:
        description: Menú de opciones disponible para el contratista.
        examples:
          application/json:
            {
              "opciones": [
                {"nombre": "instalaciones disponibles", "ruta": "/api/v1/contrators/installations"},
                {"nombre": "instalaciones asignadas", "ruta": "/api/v1/contrators/assigned_installations/"},
                {"nombre": "tomar instalacion", "ruta": "/api/v1/contrators/take_installations"},
                {"nombre": "iniciar instalacion", "ruta": "/api/v1/contrators/init_installation"},
                {"nombre": "finalizar instalacion", "ruta": "/api/v1/contrators/finish_installation"},
                {"nombre": "orden de instalacion", "ruta": "/api/v1/contrators/order_installation"},
                {"nombre": "datos de instalacion", "ruta": "/api/v1/contrators/data_installation"},
                {"nombre": "generar PDF de instalacion", "ruta": "/api/v1/contrators/generate_pdf_installation"}
              ]
            }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" } 
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
     Obtener todas las instalaciones disponibles para el contratista
    ---
    tags:
      - Contratistas
    security:
      - ApiKeyAuth: []
    responses:
      200:
        description: Lista de instalaciones disponibles obtenida exitosamente.
        examples:
          application/json:
            {
              "installations": [
                {
                  "Nro_orden": 101,
                  "cliente": "Juan Pérez",
                  "direccion": "Calle Falsa 123",
                  "estado": "Pendiente",
                  "fecha_programada1": "2024-06-21T09:00:00"
                  "fecha_programada2": "2024-06-21T11:00:00"
                  "comentario_cliente": "Instalación de servicio de internet"
                },
                {
                  "Nro_orden": 102,
                  "cliente": "Ana Gómez",
                  "direccion": "Av. Principal 456",
                  "estado": "Pendiente",
                  "fecha_programada1": "2024-06-22T14:00:00"
                  "fecha_programada2": "2024-06-22T16:00:00"
                }
              ]
            }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
    """
    installations = get_all_installations()
    return jsonify({"installations": installations}), 200


#Instalaciones asignadas al contratista
@contrators_bp.route("/api/v1/contrators/assigned_installations", methods=["GET"])
@contratista_token_required
@handle_errors  
def get_assigned_installations():
    """
    Obtener las instalaciones asignadas al contratista autenticado
    ---
    tags:
      - Contratistas
    security:
      - ApiKeyAuth: []
    responses:
      200:
        description: Lista de instalaciones asignadas obtenida exitosamente.
        examples:
          application/json:
            {
              "assigned_installations": [
                {
                  "Nro_orden": 201,
                  "cliente": "Pedro López",
                  "direccion": "Calle 1, Edif. Azul",
                  "estado": "Asignada",
                  "fecha_programada1": "2024-06-22T10:00:00"
                  "fecha_programada2": "2024-06-22T12:00:00"
                  "comentario_cliente": "Instalación de servicio de televisión"
                },
                {
                  "Nro_orden": 202,
                  "cliente": "María Torres",
                  "direccion": "Av. Central 123",
                  "estado": "Asignada",
                  "fecha_programada1": "2024-06-23T14:00:00"
                  "fecha_programada2": "2024-06-23T16:00:00"
                  "comentario_cliente": "Instalación de servicio de telefonía"
                }
              ]
            }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
    """
    assigned_installations = get_assigned_installation(request.contratista_ci_rif)
    return jsonify({"assigned_installations": assigned_installations}), 200


#Tomar una instalacion
@contrators_bp.route("/api/v1/contrators/take_installations", methods=["POST"])
@contratista_token_required
@handle_errors
def take_installation_route():
    """
    Tomar una instalación disponible por el contratista
    ---
    tags:
      - Contratistas
    security:
      - ApiKeyAuth: []
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              Nro_orden:
                type: integer
                example: 101
              contratista:
                type: string
                example: "Contratista Ejemplo"
    responses:
      200:
        description: Instalación tomada exitosamente.
        examples:
          application/json: { "message": "Instalación tomada exitosamente" }
      400:
        description: Datos inválidos o faltantes.
        examples:
          application/json: { "error": "Datos inválidos" }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
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
    Iniciar una instalación por parte del contratista
    ---
    tags:
      - Contratistas
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: Nro_orden
        required: true
        schema:
          type: integer
        description: Número de orden de instalación a iniciar
        in : path
        name : contratista
        required: true
        schema:
          type: string
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              hora _inicio:
                type: timestamp
                example: "2024-06-21T09:00:00"
                "estado":
                type: string
                example: "En progreso"
                usuarioID:
                type: string
                example: "usuario123"
                contraseñaID:
                type: string
                example: "contraseña_segura"
                observacion_contratista:
                type: string
                example: "Iniciando instalación"
    responses:
      200:
        description: Instalación iniciada exitosamente.
        examples:
          application/json: { "message": "Instalación iniciada exitosamente" }
      400:
        description: Datos inválidos o faltantes.
        examples:
          application/json: { "error": "Datos inválidos" }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
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
    Finalizar una instalación por parte del contratista
    ---
    tags:
      - Contratistas
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: Nro_orden
        required: true
        schema:
          type: integer
        description: Número de orden de instalación a finalizar
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              Nro_orden:
                type: integer
                example: 1
              estado:
                type: string
                example: "Finalizada"
              verificacion:
                type: boolean
                example: true
              observacion_contratista:
                type: string
                example: "Instalación finalizada con éxito"
    responses:
      200:
        description: Instalación finalizada exitosamente.
        examples:
          application/json: { "message": "Instalación finalizada exitosamente"}
          application/json: { "message": "Instalación finalizada fallidamente" }
      400:
        description: Datos inválidos o faltantes.
        examples:
          application/json: { "error": "Datos inválidos" }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
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
   Registrar los datos para el PDF de la orden de instalación
    ---
    tags:
      - Contratistas
    security:
      - ApiKeyAuth: []
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              dato_cliente:
                type: string
                example: "cliente_prueba"
              ont_1puerto:
                type: string
                example: "ONT 1 Puerto"
              conector_SC_APC:
                type: string
                example: "Conector SC APC"
              pathcore_scapc_apcsc:
                type: string
                example: "20"
              roseta:
                type: string
                example: "1"
              scapc_adapter:
                type: string
                example: "SC/APC Adapter"
              ont_4puertos:
                type: string
                example: "ONT 4 Puertos"
              conector_scupc:
                type: string
                example: "Conector SC UPC"
              canaletas:
                type: string
                example: "6"
              cable_drop:
                type: string
                example: "Cable Drop"
              cantidad_cabledrop:
                type: string
                example: "10"
              potencia_cajanap:
                type: string
                example: "Potencia Caja NAP"
              potencia_ont:
                type: string
                example: "Potencia ONT"
              mac_ont:
                type: string
                example: "MAC ONT"
              serial_ont:
                type: string
                example: "Serial ONT"
              puerto_nap:
                type: string
                example: "Puerto NAP"
              nroequipos_conectar:
                type: string
                example: "5"
              etiqueta_cliente:
                type: string
                example: "Etiqueta Cliente"
              router:
                type: string
                example: "Router Modelo X"
              fecha:
                type: string
                example: "2023-10-01"
              hora_inicio:
                type: string
                example: "10:00:00"
              hora_final:
                type: string
                example: "12:00:00"
              contratista:
                type: string
                example: "Contratista Prueba"
              nombre_cliente:
                type: string
                example: "Cliente Prueba"
              firma:
                type: blob
                description: Firma del cliente en formato blob
                example: "Firma del Cliente"
    responses:
      200:
        description: Datos de la orden de instalación registrados exitosamente.
        examples:
          application/json: { "message": "Orden de instalación obtenida exitosamente" }
      400:
        description: Datos inválidos o faltantes.
        examples:
          application/json: { "error": "Datos inválidos" }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
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
     Obtener los datos del PDF de una orden de instalación
    ---
    tags:
      - Contratistas
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: id
        required: true
        schema:
          type: integer
        description: ID de la orden de instalación
    responses:
      200:
        description: Datos de la orden de instalación obtenidos exitosamente.
        examples:
          application/json:
            {
              "dato_cliente": "cliente_prueba",
              "ont_1puerto": "ONT 1 Puerto",
              "conector_SC_APC": "Conector SC APC",
              "pathcore_scapc_apcsc": "20",
              "roseta": "1",
              "scapc_adapter": "SC/APC Adapter",
              "ont_4puertos": "ONT 4 Puertos",
              "conector_scupc": "Conector SC UPC",
              "canaletas": "6",
              "cable_drop": "Cable Drop",
              "cantidad_cabledrop": "10",
              "potencia_cajanap": "Potencia Caja NAP",
              "potencia_ont": "Potencia ONT",
              "mac_ont": "MAC ONT",
              "serial_ont": "Serial ONT",
              "puerto_nap": "Puerto NAP",
              "nroequipos_conectar": "5",
              "etiqueta_cliente": "Etiqueta Cliente",
              "router": "Router Modelo X",
              "fecha": "2023-10-01",
              "hora_inicio": "10:00:00",
              "hora_final": "12:00:00",
              "contratista": "Contratista Prueba",
              "nombre_cliente": "Cliente Prueba",
              "firma": "Firma del Cliente"
            }
      400:
        description: Datos inválidos o faltantes.
        examples:
          application/json: { "error": "Datos inválidos" }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      404:
        description: Orden no encontrada.
        examples:
          application/json: { "error": "Orden no encontrada" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
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
    Generar el PDF de la orden de instalación
    ---
    tags:
      - Contratistas
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: Nro_orden
        required: true
        schema:
          type: integer
        description: Número de orden de instalación para generar el PDF
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              datos_pdf:
                type: object
                description: Datos necesarios para generar el PDF
                example:
                  dato_cliente: "cliente_prueba"
                  fecha: "2023-10-01"
                  contratista: "Contratista Prueba"
                  firma: "Firma del Cliente"
    responses:
      200:
        description: PDF generado exitosamente.
        examples:
          application/json: { "message": "PDF de instalación generado exitosamente" }
      400:
        description: Datos inválidos o faltantes.
        examples:
          application/json: { "error": "Datos inválidos" }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      404:
        description: Orden no encontrada.
        examples:
          application/json: { "error": "Orden no encontrada" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
    """
    data = request.json
    try:
        generar_pdf_instalacion(data, request.contratista_ci_rif)
        return jsonify({"message": "PDF de instalación generado exitosamente"}), 200
    except ValidationError as err:
        return jsonify({"error": "Datos inválidos", "details": err.messages}), 400