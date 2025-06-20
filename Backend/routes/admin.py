import jwt
import datetime
from flask import Blueprint, jsonify, request
from werkzeug.security import check_password_hash
from services.admin_service import (
    create_administrador, create_cliente, consulta_cliente, update_cliente, delete_cliente, asignar_instalacion, consulta_contratista, update_contratista, delete_contratista, get_estadisticas, consulta_Nro_orden, consulta_admin_por_usuario, autorizar_instalacion, ordenes_no_autorizadas, delete_orden, ordenes_instalacion, 
)
from schemas.admin_schema import (
    CreateAdminSchema, CreateClienteSchema, AsignacionInstalacionSchema, validate_data, LoginSchema, UpdateContratistaSchema, UpdateClienteSchema,
)
from functools import wraps
from flask import send_file
import os


SECRET_KEY = "miclavesegura123"  
admin_bp = Blueprint("admin", __name__)


# Decorador para verificar el token JWT
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get("Authorization")
        if not token:
            return jsonify({"error": "Token es requerido"}), 401
        try:
            data = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
            request.admin_id = data["admin_id"]
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


#ruta para iniciar sesión de un administrador
@admin_bp.route("/api/v1/admins/login", methods=["POST"])
@handle_errors
def login_admin():
    """
    Iniciar sesión de administrador
    ---
    tags:
      - Administradores
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              USUARIO:
                type: string
                example: admin1
              CONTRASEÑA:
                type: string
                example: clave_segura
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
        # Obtener el administrador por su nombre de usuario
        admin = consulta_admin_por_usuario(usuario)
        if not admin:
            return jsonify({"error": "Usuario o contraseña incorrectos"}), 401

        # Verificar la contraseña
        if not check_password_hash(admin["CONTRASEÑA"], contraseña):
            return jsonify({"error": "Usuario o contraseña incorrectos"}), 401

        # Generar el token JWT
        token = jwt.encode(
            {
                "admin_id": admin["id"],
                "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1)
            },
            SECRET_KEY,
            algorithm="HS256"
        )
        return jsonify({"token": token}), 200
    except Exception as e:
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500


#Ruta para obtener el menu de opciones del administrador
@admin_bp.route("/api/v1/admins/menu", methods=["GET"])
@token_required
@handle_errors
def admin_menu():
    """
     Obtener el menú de opciones del administrador
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    responses:
      200:
        description: Menú de opciones disponible para el administrador.
        examples:
          application/json:
            {
              "opciones": [
                {"nombre": "Crear Administrador", "ruta": "/api/v1/admins/crear-admin"},
                {"nombre": "Consultar Estadísticas", "ruta": "/api/v1/admins/estadisticas"},
                {"nombre": "Consultar Orden", "ruta": "/api/v1/admins/consultar-orden/<Nro_orden>"},
                {"nombre": "Consulta Admin por Usuario", "ruta": "/api/v1/admins/consulta-admin-por-usuario/<usuario>"},
                {"nombre": "Asignar Instalacion", "ruta": "/api/v1/admins/asignacion-instalacion"},
                {"nombre": "Crear Cliente", "ruta": "/api/v1/admins/crear-cliente"},
                {"nombre": "Consultar Cliente", "ruta": "/api/v1/admins/consultar-cliente/<ci_rif>"},
                {"nombre": "Actualizar Cliente", "ruta": "/api/v1/admins/actualizar-cliente/<ci_rif>"},
                {"nombre": "Eliminar Cliente", "ruta": "/api/v1/admins/eliminar-cliente/<ci_rif>"},
                {"nombre": "Consultar Contratista", "ruta": "/api/v1/admins/consultar-contratista/<contratista>"},
                {"nombre": "Actualizar Contratista", "ruta": "/api/v1/admins/actualizar-contratista/<ci_rif>"},
                {"nombre": "Eliminar Contratista", "ruta": "/api/v1/admins/eliminar-contratista/<ci_rif>"},
                {"nombre": "Eliminar Orden instalacion", "ruta": "/api/v1/admins/eliminar-orden/<int:Nro_orden>"},
                {"nombre": "Ver Ordenes de Instalacion", "ruta": "/api/v1/admins/ordenes"},
                {"nombre": "ordenes no autorizadas", "ruta": "/api/v1/admins/ordenes-no-autorizadas"},
                {"nombre": "Autorizacion de clientes", "ruta": "/api/v1/admins/autorizacion-cliente/<Nro_orden>"},
                {"nombre": "Descargar PDF de Instalación", "ruta": "/descargar_pdf/<Nro_orden>"}
              ]
            }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
    """
    menu = {
        "opciones": [
            {"nombre": "Crear Administrador", "ruta": "/api/v1/admins/crear-admin"},
            {"nombre": "Consultar Estadísticas", "ruta": "/api/v1/admins/estadisticas"},
            {"nombre": "Consultar Orden", "ruta": "/api/v1/admins/consultar-orden/<Nro_orden>"},
            {"nombre": "Consulta Admin por Usuario", "ruta": "/api/v1/admins/consulta-admin-por-usuario/<usuario>"},
            {"nombre": "Asignar Instalacion", "ruta": "/api/v1/admins/asignacion-instalacion"},
            {"nombre": "Crear Cliente", "ruta": "/api/v1/admins/crear-cliente"},
            {"nombre": "Consultar Cliente", "ruta": "/api/v1/admins/consultar-cliente/<ci_rif>"},
            {"nombre": "Actualizar Cliente", "ruta": "/api/v1/admins/actualizar-cliente/<ci_rif>"},
            {"nombre": "Eliminar Cliente", "ruta": "/api/v1/admins/eliminar-cliente/<ci_rif>"},
            {"nombre": "Consultar Contratista", "ruta": "/api/v1/admins/consultar-contratista/<contratista>"},
            {"nombre": "Actualizar Contratista", "ruta": "/api/v1/admins/actualizar-contratista/<ci_rif>"},
            {"nombre": "Eliminar Contratista", "ruta": "/api/v1/admins/eliminar-contratista/<ci_rif>"},
            {"nombre": "Eliminar Orden instalacion", "ruta": "/api/v1/admins/eliminar-orden/<int:Nro_orden>"},
            {"nombre": "Ver Ordenes de Instalacion", "ruta": "/api/v1/admins/ordenes"},
            {"nombre": "ordenes no autorizadas", "ruta": "/api/v1/admins/ordenes-no-autorizadas"},
            {"nombre": "Autorizacion de clientes", "ruta": "/api/v1/admins/autorizacion-cliente/<Nro_orden>"},
            {"nombre": "Descargar PDF de Instalación", "ruta": "/descargar_pdf/<Nro_orden>"},
            
        ]
    }
    return jsonify(menu), 200

#Crear administrados 
@admin_bp.route("/api/v1/admins/crear-admin", methods=["POST"])
@token_required
@handle_errors
def crearAdmin():
    """
   Crear un nuevo administrador
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              ci_rif:
                type: string
                example: V12345678
              nombre:
                type: string
                example: Juan Pérez
              USUARIO:
                type: string
                example: admin1
              CONTRASEÑA:
                type: string
                example: clave_segura
              telefono:
                type: string
                example: "04141234567"
              sucursal:
                type: string
                example: Sucursal Centro
    responses:
      201:
        description: Administrador creado con éxito
        examples:
          application/json: { "message": "Administrador creado con éxito" }
      400:
        description: Datos inválidos o faltantes
        examples:
          application/json: { "error": "Datos inválidos" }
      401:
        description: Token no válido o no enviado
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor
        examples:
          application/json: { "error": "Error al crear al administrador" }
    """
    data = request.get_json()

    #Validar datos usando esquema 
    validation_error = validate_data(CreateAdminSchema(), data)
    if validation_error: 
        return jsonify(validation_error), 400
    
    #extraer los datos validados
    ci_rif = data["ci_rif"]
    nombre = data ["nombre"]
    usuario = data["USUARIO"]
    contraseña = data["CONTRASEÑA"]
    telefono = data["telefono"]
    sucursal = data["sucursal"]

    try: 
        #crear el administrador en la base de datos 
        result = create_administrador(ci_rif, nombre, usuario, contraseña, telefono, sucursal)
        return jsonify(result), 201
    except Exception as e: 
        return jsonify({"error": "Error al crear al administrador", "details": str(e)}), 500
    

#Asigna un contratista a una orden.
@admin_bp.route("/api/v1/admins/asignacion-instalacion", methods=["POST"])
@token_required
@handle_errors
def asignaciones_instalaciones():
    """ 
    Asignar un contratista a una orden de instalación
    ---
    tags:
      - Administradores
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
                example: 123
              contratista:
                type: string
                example: "contratista_prueba"
    responses:
      200:
        description: Contratista asignado exitosamente a la orden.
        examples:
          application/json: { "message": "Contratista asignado exitosamente" }
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
    data = request.get_json()
    validation_error = validate_data(AsignacionInstalacionSchema(), data)
    if validation_error:
        return jsonify(validation_error), 400
    result = asignar_instalacion(data["Nro_orden"], data["contratista"])
    return jsonify(result), 200


#Consulta estadísticas generales de la aplicación.
@admin_bp.route("/api/v1/admins/estadisticas", methods=["GET"])
@token_required
@handle_errors
def get_app_estadisticas():
    """
    Obtener estadísticas generales de la aplicación
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    responses:
      200:
        description: Estadísticas generales obtenidas exitosamente.
        examples:
          application/json:
            {
              "total_administradores": 5,
              "total_clientes": 120,
              "total_contratistas": 8,
              "ordenes_instalacion": 45,
              "ordenes_finalizadas": 30,
              "ordenes_pendientes": 15
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
    try:
        stats = get_estadisticas()
        return jsonify(stats), 200
    except Exception as e:
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500



#Consulta Numero de Orden 
@admin_bp.route("/api/v1/admins/consultar-orden/<Nro_orden>", methods=["GET"])
@token_required
@handle_errors
def consult_NroOrden(): 
    """
    Consultar una orden de instalación por su número de orden
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: Nro_orden
        required: true
        schema:
          type: integer
        description: Número de orden a consultar
    responses:
      200:
        description: Detalles de la orden encontrados
        examples:
          application/json:
            {
              "Nro_orden": 123,
              "cliente": "Juan Pérez",
              "contratista": "contratista_prueba",
              "estado": "En Proceso",
              "fecha": "2024-06-20T10:00:00"
            }
      400:
        description: El número de orden es requerido
        examples:
          application/json: { "error": "El numero de orden es requerido" }
      404:
        description: Orden no encontrada
        examples:
          application/json: { "error": "Orden no encontrada" }
      500:
        description: Error interno del servidor
        examples:
          application/json: { "error": "Error interno del servidor" }
    """
    #obtener el numero de orden de los parametros de la URL 
    nro_orden = request.args.get("Nro_orden")
    if not nro_orden: 
        return jsonify({"error": "El numero de orden es requerido"}), 400
    
    try: 
        #consultar la orden de la base de datos
        orden = consulta_Nro_orden(nro_orden)
        if not orden: 
            return jsonify({"error": "Orden no encontrada"}), 404
        return jsonify(orden), 200
    except Exception as e: 
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500


#Consulta Admin por usuario 
@admin_bp.route("/api/v1/admins/consulta-admin-por-usuario/<usuario>", methods=["GET"])
@token_required
@handle_errors
def consult_adiminUsuario(): 
    """
   Consultar administrador por nombre de usuario
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: usuario
        required: true
        schema:
          type: string
        description: Nombre de usuario del administrador a consultar
    responses:
      200:
        description: Detalles del administrador encontrados
        examples:
          application/json:
            {
              "ci_rif": "V12345678",
              "nombre": "Juan Pérez",
              "USUARIO": "admin1",
              "CONTRASEÑA": "clave_segura",
              "telefono": "04141234567",
              "sucursal": "Sucursal Centro"
            }
      400:
        description: El nombre del usuario es requerido
        examples:
          application/json: { "error": "El nombre del usuario es requerido" }
      404:
        description: Administrador no encontrado
        examples:
          application/json: { "error": "Administrador no encontrado" }
      500:
        description: Error interno del servidor
        examples:
          application/json: { "error": "Error interno del servidor" }
    """
    #obtener el nombre del administrador de los parametros de la URL 
    usuario = request.args.get("USUARIO")
    if not usuario: 
        return jsonify({"error": "El nombre del usuario es requerido"}), 400
    
    try: 
        #consultar el administardor en la base de datos
        admin = consulta_admin_por_usuario(usuario)
        if not admin: 
            return jsonify({"error": "Administrador no encontrado"}), 404
        return jsonify(admin), 200
    except Exception as e: 
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500


#Consulta Contratista 
@admin_bp.route("/api/v1/admins/consulta-contratista/<contratista>", methods=["GET"])
@token_required
@handle_errors
def consultaContratista(): 
    """
    Consultar contratista por cédula de identidad o RIF
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: contratista
        required: true
        schema:
          type: string
        description: Cédula de identidad o RIF del contratista a consultar
    responses:
      200:
        description: Detalles del contratista encontrados
        examples:
          application/json:
            {
              "ci_rif": "V12345678",
              "nombre": "Contratista Ejemplo",
              "telefono": "04141234567",
              "USUARIO": "contratista1",
              "correo": "correo@ejemplo.com",
              "sucursal": "Sucursal Centro",
              "cuadrillas": 3,
              "cuadrilla1": "Cuadrilla A",
              "cuadrilla2": "Cuadrilla B",
              "cuadrilla3": "Cuadrilla C"
            }
      400:
        description: La cédula de identidad o RIF es requerida
        examples:
          application/json: { "error": "La cédula de identidad o RIF es requerido" }
      404:
        description: Contratista no encontrado
        examples:
          application/json: { "error": "Contratista no encontrado" }
      500:
        description: Error interno del servidor
        examples:
          application/json: { "error": "Error interno del servidor" }
    """
#Obtener la cedula de identidad o rif del contratistas. 
    keycontratista = request.args.get("ci_rif")
    if not keycontratista: 
     return jsonify({"error": "La cedula de identidad o RIF es requerido "})
    
    try: 
        #Consultar al contratista en la abse de datos. 
        contratista = consulta_contratista(keycontratista)
        if not contratista: 
            return jsonify({"error": "Contratista no encontrado"}), 404 
        return jsonify(contratista), 200
    except Exception as e: 
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500


#Actualizacion contratista
@admin_bp.route("/api/v1/admins/actualizar-contratista/<ci_rif>", methods=["PUT"])
@token_required
@handle_errors
def actualizarContratista(): 
    """
   Actualizar los datos de un contratista
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: ci_rif
        required: true
        schema:
          type: string
        description: Cédula de identidad o RIF del contratista a actualizar
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              nombre:
                type: string
                example: "Contratista Actualizado"
              telefono:
                type: string
                example: "04123456789"
              USUARIO:
                type: string
                example: "usuario_actualizado"
              CONTRASEÑA:
                type: string
                example: "clave_actualizada"
              correo:
                type: string
                example: "correo@ejemplo.com"
              sucursal:
                type: string
                example: "Sucursal Actualizada"
              cuadrillas:
                type: integer
                example: 4
              cuadrilla1:
                type: string
                example: "Cuadrilla 1 Actualizada"
              cuadrilla2:
                type: string
                example: "Cuadrilla 2 Actualizada"
              cuadrilla3:
                type: string
                example: "Cuadrilla 3 Actualizada"
              cuadrilla4:
                type: string
                example: "Cuadrilla 4 Actualizada"
              cuadrilla5:
                type: string
                example: "Cuadrilla 5 Actualizada"
              cuadrilla6:
                type: string
                example: "Cuadrilla 6 Actualizada"
              cuadrilla7:
                type: string
                example: "Cuadrilla 7 Actualizada"
              cuadrilla8:
                type: string
                example: "Cuadrilla 8 Actualizada"
              cuadrilla9: 
                type: string
                example: "Cuadrilla 9 Actualizada"
              cuadrilla10:
                type: string
                example: "Cuadrilla 10 Actualizada"
    responses:
      200:
        description: Contratista actualizado con éxito.
        examples:
          application/json: { "message": "Contratista actualizado con exito.", "details": { } }
      400:
        description: Datos inválidos o faltantes.
        examples:
          application/json: { "error": "Datos inválidos" }
      404:
        description: Contratista no encontrado.
        examples:
          application/json: { "error": "Contratista no encontrado" }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" } 
    """
    data = request.get_json()

    #Validar los datos usando esquema 
    validation_error = validate_data(UpdateContratistaSchema(), data)
    if validation_error: 
        return jsonify(validation_error), 400
    
    #Extraer datos validos
    ci_rif = data["ci_rif"]
    nombre = data.get("nombre")
    telefono = data.get("telefono")
    usuario = data.get("USUARIO")
    contraseña = data.get("CONTRASEÑA")
    correo = data.get("correo")
    sucursal = data.get("sucursal")
    cuadrillas = data.get("cuadrillas")
    cuadrilla1 = data.get("cuadrilla1")
    cuadrilla2 = data.get("cuadrilla2")
    cuadrilla3 = data.get("cuadrilla3")
    cuadrilla4 = data.get("cuadrilla4")
    cuadrilla5 = data.get("cuadrilla5")
    cuadrilla6 = data.get("cuadrilla6")
    cuadrilla7 = data.get("cuadrilla7")
    cuadrilla8 = data.get("cuadrilla8") 
    cuadrilla9 = data.get("cuadrilla9")
    cuadrilla10 = data.get("cuadrilla10")

    try: 
        #Verificar si el contratista existe.
        contratista = consulta_contratista(ci_rif)
        if not contratista: 
            return jsonify({"error": "Contratista no encontrado"}), 404
        #Actualizar los datos del contratista. 
        result = update_contratista(ci_rif, nombre, telefono, usuario, contraseña, correo, sucursal, cuadrillas, cuadrilla1, cuadrilla2, cuadrilla3, cuadrilla4)
        return jsonify({"message": "Contratista actualizado con exito.", "details": result}), 200
    except Exception as e: 
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500
    

# Eliminar contratista  
@admin_bp.route("/api/v1/admins/eliminar-contratista/<ci_rif>", methods=["DELETE"])
@token_required
@handle_errors
def eliminarContratista(): 
    """
     Eliminar un contratista por cédula de identidad o RIF
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: ci_rif
        required: true
        schema:
          type: string
        description: Cédula de identidad o RIF del contratista a eliminar
    responses:
      200:
        description: Contratista eliminado con éxito.
        examples:
          application/json: { "message": "Contratista eliminado con éxito.", "details": {} }
      400:
        description: La cédula de identidad o RIF es requerida.
        examples:
          application/json: { "error": "La cédula de identidad o RIF es requerida" }
      404:
        description: Contratista no encontrado.
        examples:
          application/json: { "error": "Contratista no encontrado" }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
    

    """
    # Obtener la cédula de identidad o RIF del contratista de los parámetros de la URL
    keycontratista = request.args.get("ci_rif")
    if not keycontratista:
        return jsonify({"error": "La cédula de identidad o RIF es requerida"}), 400

    try:
        # Consultar al contratista en la base de datos
        contratista = consulta_contratista(keycontratista)
        if not contratista:
            return jsonify({"error": "Contratista no encontrado"}), 404

        # Eliminar al contratista de la base de datos
        result = delete_contratista(keycontratista)
        return jsonify({"message": "Contratista eliminado con éxito.", "details": result}), 200
    except Exception as e:
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500


#Crear cliente
@admin_bp.route("/api/v1/admins/crear-cliente", methods=["POST"])
@token_required
@handle_errors
def crearCliente(): 
    """
    Crear un nuevo cliente
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              Nro_cuenta:
                type: string
                example: "1234567890"
              nombre:
                type: string
                example: "Cliente Prueba"
              ci_rif:
                type: string
                example: "V12345678"
              telefono:
                type: string
                example: "04141234567"
              direccion:
                type: string
                example: "Calle Falsa 123"
              municipio:
                type: string
                example: "Municipio Prueba"
              sector:
                type: string
                example: "Sector Prueba"
              plan_contrato:
                type: string
                example: "Plan Basico 200"
    responses:
      201:
        description: Cliente creado con éxito
        examples:
          application/json: { "message": "Cliente creado con éxito" }
      400:
        description: Datos inválidos o faltantes
        examples:
          application/json: { "error": "Datos inválidos" }
      401:
        description: Token no válido o no enviado
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor
        examples:
          application/json: { "error": "Error al crear al cliente" }
    """
    data = request.get_json()

    #Validar los datos usando el esquema 
    validation_error = validate_data(CreateClienteSchema(), data)
    if validation_error: 
        return jsonify(validation_error), 400
    
    #Extraer los datos validados
    nro_cuenta = data["Nro_cuenta"]
    nombre = data["nombre"]
    ci_rif = data["ci_rif"]
    telefono = data["telefono"]
    direccion = data["direccion"]
    municipio = data["municipio"]
    sector = data["sector"]
    plan_contrato = data["plan_contrato"]

    try: 
        #Crear el cliente en la base de datos 
        result = create_cliente(nro_cuenta, nombre, ci_rif, telefono, direccion, municipio, sector, plan_contrato)
        return jsonify(result), 201
    except Exception as e: 
        return jsonify({"error": "Error al crear al cliente", "details": str(e)}), 500


#Consultar cliente
@admin_bp.route("/api/v1/admins/consultar-cliente/<ci_rif>", methods=["GET"])
@token_required
@handle_errors
def consultarCliente(): 
    """
    Consultar un cliente por su cédula de identidad o RIF
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: ci_rif
        required: true
        schema:
          type: string
        description: Cédula de identidad o RIF del cliente a consultar
    responses:
      200:
        description: Detalles del cliente encontrados
        examples:
          application/json:
            {
              "Nro_cuenta": "1234567890",
              "nombre": "Cliente Prueba",
              "ci_rif": "V12345678",
              "telefono": "04141234567",
              "direccion": "Calle Falsa 123",
              "municipio": "Municipio Prueba",
              "sector": "Sector Prueba",
              "plan_contrato": "Plan Basico 200"
            }
      400:
        description: La cédula de identidad o RIF es requerida
        examples:
          application/json: { "error": "La cédula de identidad o RIF es requerida" }
      404:
        description: Cliente no encontrado
        examples:
          application/json: { "error": "Cliente no encontrado" }
      401:
        description: Token no válido o no enviado
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor
        examples:
          application/json: { "error": "Error interno del servidor" }
    """
    #Obtener el numero de cuenta de los parametros de la URL 
    nro_cuenta = request.args.get("Nro_cuenta")
    if not nro_cuenta: 
        return jsonify({"error": "El número de cuenta es requerido"}), 400
    
    try: 
        #consultar el cliente en la base de datos
        cliente = consulta_cliente(nro_cuenta)
        if not cliente: 
            return jsonify({"error": "Cliente no encontrado"}), 404
        return jsonify(cliente), 200
    except Exception as e: 
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500
    

#Actualizar cliente
@admin_bp.route("/api/v1/admins/actualizar-cliente/<ci_rif>", methods=["PUT"])
@token_required
@handle_errors
def actualizarCliente(): 
    """
   Actualizar los datos de un cliente
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: ci_rif
        required: true
        schema:
          type: string
        description: Cédula de identidad o RIF del cliente a actualizar
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              Nro_cuenta:
                type: string
                example: "1234567890"
              nombre:
                type: string
                example: "Cliente Actualizado"
              ci_rif:
                type: string
                example: "V12345678"
              telefono:
                type: string
                example: "04141234567"
              direccion:
                type: string
                example: "Calle Nueva 456"
              municipio:
                type: string
                example: "Municipio Actualizado"
              sector:
                type: string
                example: "Sector Actualizado"
              plan_contrato:
                type: string
                example: "Plan Avanzado 500"
    responses:
      200:
        description: Cliente actualizado con éxito.
        examples:
          application/json: { "message": "Cliente actualizado con exito.", "details": {} }
      400:
        description: Datos inválidos o faltantes.
        examples:
          application/json: { "error": "Datos inválidos" }
      404:
        description: Cliente no encontrado.
        examples:
          application/json: { "error": "Cliente no encontrado" }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
    """
    data = request.get_json()

    #Validar los datos usando el esquema 
    validation_error = validate_data(UpdateClienteSchema(), data)
    if validation_error: 
        return jsonify(validation_error), 400
    
    #Extraer los datos validados
    nro_cuenta = data["Nro_cuenta"]
    nombre = data.get("nombre")
    ci_rif = data.get("ci_rif")
    telefono = data.get("telefono")
    direccion = data.get("direccion")
    municipio = data.get("municipio")
    sector = data.get("sector")
    plan_contrato = data.get("plan_contrato")

    try: 
        #Verificar si el cliente existe.
        cliente = consulta_cliente(nro_cuenta)
        if not cliente: 
            return jsonify({"error": "Cliente no encontrado"}), 404
        #Actualizar los datos del cliente. 
        result = update_cliente(nro_cuenta, nombre, ci_rif, telefono, direccion, municipio, sector, plan_contrato)
        return jsonify({"message": "Cliente actualizado con exito.", "details": result}), 200
    except Exception as e: 
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500    


#Eliminar cliente
@admin_bp.route("/api/v1/admins/eliminar-cliente/<ci_rif>", methods=["DELETE"])
@token_required
@handle_errors
def eliminarCliente(): 
    """
    Eliminar un cliente por su cédula de identidad o RIF
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: ci_rif
        required: true
        schema:
          type: string
        description: Cédula de identidad o RIF del cliente a eliminar
    responses:
      200:
        description: Cliente eliminado con éxito.
        examples:
          application/json: { "message": "Cliente eliminado con exito.", "details": {} }
      400:
        description: La cédula de identidad o RIF es requerida.
        examples:
          application/json: { "error": "La cédula de identidad o RIF es requerida" }
      404:
        description: Cliente no encontrado.
        examples:
          application/json: { "error": "Cliente no encontrado" }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
    """
    #Obtener el numero de cuenta de los parametros de la URL 
    nro_cuenta = request.args.get("Nro_cuenta")
    if not nro_cuenta: 
        return jsonify({"error": "El número de cuenta es requerido"}), 400
    
    try: 
        #Consultar al cliente en la base de datos
        cliente = consulta_cliente(nro_cuenta)
        if not cliente: 
            return jsonify({"error": "Cliente no encontrado"}), 404
        #Eliminar al cliente de la base de datos
        result = delete_cliente(nro_cuenta) 
        return jsonify({"message": "Cliente eliminado con exito.", "details": result}), 200
    except Exception as e:
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500


#Ruta para autorizar la entrada del cliente a la red
@admin_bp.route("/api/v1/admins/autorizacion-cliente/<Nro_orden>", methods=["PUT"])
@token_required
@handle_errors
def autorizacion_cliente():
    """
    Autorizar la entrada del cliente a la red
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: Nro_orden
        required: true
        schema:
          type: integer
        description: Número de orden de instalación a autorizar
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            properties:
              Nro_orden:
                type: integer
                example: 123
              contratista:
                type: string
                example: "contratista_prueba"
    responses:
      200:
        description: Autorización realizada con éxito.
        examples:
          application/json: { "message": "Cliente autorizado para la red" }
      400:
        description: Nro_orden y contratista son requeridos o datos inválidos.
        examples:
          application/json: { "error": "Nro_orden y contratista son requeridos" }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
    """
    data = request.get_json()
    nro_orden = data.get("Nro_orden")
    contratista = data.get("contratista")
    if not nro_orden or not contratista: 
        return jsonify({"error": "Nro_orden y contratista son requeridos"}), 400
    result = autorizar_instalacion(nro_orden, contratista)
    if "error" in result: 
        return jsonify(result), 400
    return jsonify(result), 200


#Ruta para eliminar una orden de instalacion
@admin_bp.route("/api/v1/admins/eliminar-orden/<Nro_orden>", methods=["DELETE"]) 
@token_required
@handle_errors
def eliminar_orden():
    """
   Eliminar una orden de instalación por su número de orden
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: Nro_orden
        required: true
        schema:
          type: integer
        description: Número de orden a eliminar
      - in: query
        name: Nro_cuenta
        required: true
        schema:
          type: string
        description: Número de cuenta asociado a la orden
    responses:
      200:
        description: Orden eliminada con éxito.
        examples:
          application/json: { "message": "Orden eliminada con éxito.", "details": {} }
      400:
        description: El número de orden o el número de cuenta es requerido.
        examples:
          application/json: { "error": "El número de orden es requerido o el numero de cuenta" }
      404:
        description: Orden no encontrada.
        examples:
          application/json: { "error": "Orden no encontrada" }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
    """
    nro_orden = request.args.get("Nro_orden")
    nro_cuenta = request.args.get("Nro_cuenta")
    if not nro_orden or not nro_cuenta:
        return jsonify({"error": "El número de orden es requerido o el numero de cuenta"}), 400

    try:
        # Consultar la orden en la base de datos
        orden = consulta_Nro_orden(nro_orden)
        if not orden:
            return jsonify({"error": "Orden no encontrada"}), 404

        # Eliminar la orden de la base de datos
        result = delete_orden(nro_orden)
        return jsonify({"message": "Orden eliminada con éxito.", "details": result}), 200
    except Exception as e:
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500


#Ruta para ver una lista de ordenes de instalacion. 
@admin_bp.route("/api/v1/admins/ordenes", methods=["GET"])
@token_required
@handle_errors
def ver_ordenes():
    """
     Ver lista de órdenes de instalación
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    responses:
      200:
        description: Lista de órdenes de instalación obtenida exitosamente.
        examples:
          application/json:
            [
              {
                "Nro_orden": 123,
                "cliente": "Juan Pérez",
                "contratista": "contratista_prueba",
                "estado": "En Proceso",
                "fecha": "2024-06-20T10:00:00"
              },
              {
                "Nro_orden": 124,
                "cliente": "Ana Gómez",
                "contratista": "contratista2",
                "estado": "Finalizada",
                "fecha": "2024-06-19T09:00:00"
              }
            ]
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
    """
    try:
        result = ordenes_instalacion()
        if not result:
            return jsonify([]), 200
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500
    


#Ruta para ver las ordenes de instalacion no autorizadas
@admin_bp.route("/api/v1/admins/ordenes-no-autorizadas", methods=["GET"])
@token_required
@handle_errors
def instalaciones_no_autorizadas():
    """
    Ver lista de órdenes de instalación no autorizadas
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    responses:
      200:
        description: Lista de órdenes de instalación no autorizadas obtenida exitosamente.
        examples:
          application/json:
            [
              {
                "Nro_orden": 125,
                "cliente": "Carlos Ruiz",
                "contratista": "contratista3",
                "estado": "En proceso",
                "fecha": "2024-06-18T15:00:00"
              }
            ]
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
   """
    try:
        result = ordenes_no_autorizadas()
        if not result:
            return jsonify([]), 200
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500

    
# Ruta para descargar el PDF de instalación
@admin_bp.route("/descargar_pdf/<Nro_orden>", methods=['GET'])
@token_required
@handle_errors
def descargar_pdf(nro_orden):
    """
   Descargar el PDF de la orden de instalación
    ---
    tags:
      - Administradores
    security:
      - ApiKeyAuth: []
    parameters:
      - in: path
        name: Nro_orden
        required: true
        schema:
          type: integer
        description: Número de orden de instalación para generar o descargar el PDF
    responses:
      200:
        description: PDF generado y descargado exitosamente.
        content:
          application/pdf:
            schema:
              type: string
              format: binary
      404:
        description: No existe la orden o no hay datos para generar el PDF.
        examples:
          application/json: { "error": "No existe la orden o no hay datos para generar el PDF" }
      401:
        description: Token no válido o no enviado.
        examples:
          application/json: { "error": "Token es requerido" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }
    """
    ruta_pdf = f"orden_instalacion_{nro_orden}.pdf"
    if not os.path.exists(ruta_pdf):
        from Backend.services.contrators_service import datos_instalacion, generar_pdf_instalacion
        datos = datos_instalacion(nro_orden)
        if not datos:
            return {"error": "No existe la orden o no hay datos para generar el PDF"}, 404
        ruta_pdf = generar_pdf_instalacion(nro_orden, datos)
    return send_file(ruta_pdf, as_attachment=True)