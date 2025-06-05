import jwt
import datetime
from flask import Blueprint, jsonify, request
from werkzeug.security import check_password_hash
from services.admin_service import (
    create_administrador, create_cliente, consulta_cliente, update_cliente, delete_cliente, asignar_instalacion, consulta_contratista, update_contratista, delete_contratista, get_estadisticas, consulta_Nro_orden, consulta_admin_por_usuario, autorizar_instalacion, ordenes_no_autorizadas,
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
    Ruta para que el administrador inicie sesión.
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
    ruta para obtener el menu de opciones del administrador. 
    :return: Un diccionario con las opciones disponibles para el administrador.
    """
    menu = {
        "opciones": [
            {"nombre": "Crear Administrador", "ruta": "/api/v1/admins/crear-admin"},
             {"nombre": "Consultar Estadísticas", "ruta": "/api/v1/admins/estadisticas"},
             {"nombre": "Consultar Orden", "ruta": "/api/v1/admins/consultar-orden"},
             {"nombre": "Consulta Admin por Usuario", "ruta": "/api/v1/admins/consulta-admin-por-usuario"},
             {"nombre": "Asignar Instalacion", "ruta": "/api/v1/admins/asignacion-instalacion"},
            {"nombre": "Crear Cliente", "ruta": "/api/v1/admins/crear-cliente"},
            {"nombre": "Consultar Cliente", "ruta": "/api/v1/admins/consultar-cliente"},
            {"nombre": "Actualizar Cliente", "ruta": "/api/v1/admins/actualizar-cliente"},
            {"nombre": "Eliminar Cliente", "ruta": "/api/v1/admins/eliminar-cliente"},
            {"nombre": "Consultar Contratista", "ruta": "/api/v1/admins/consultar-contratista"},
            {"nombre": "Actualizar Contratista", "ruta": "/api/v1/admins/actualizar-contratista"},
            {"nombre": "Eliminar Contratista", "ruta": "/api/v1/admins/eliminar-contratista"},
            {"nombre": "ordenes no autorizadas", "ruta": "api/v1/admins/ordenes-no-autorizadas"},
            {"nombre": "Autorizacion de clientes", "ruta": "api/v1/admins/autorizacion-cliente"},
            {"nombre": "Descargar PDF de Instalación", "ruta": "/descargar_pdf/<int:nro_orden>"},
            
        ]
    }
    return jsonify(menu), 200

#Crear administrados 
@admin_bp.route("api/v1/admins/crear-admin", methods=["POST"])
@token_required
@handle_errors
def crearAdmin():
    """
    Ruta para crear un administrador. 
    :return: Un mensaje de exito si el administrador fue creado con exito. 
    :raises 400: Si los datos pproporcionados son invalidos. 
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
    Asigna un contratista a una orden de instalación."""
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
    Ruta para obtener estadísticas generales de la aplicación.
    """
    try:
        stats = get_estadisticas()
        return jsonify(stats), 200
    except Exception as e:
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500



#Consulta Numero de Orden 
@admin_bp.route("api/v1/admins/consulta-orden", methods=["GET"])
@token_required
@handle_errors
def consult_NroOrden(): 
    """
    Ruta para consultar una orden de instalacion por su numero de orden. 
    :queyparam Nro_orden: Numero de orden a consultar (en los parametros de URL). 
    :return: Los detalles de la orden si se encuentra. 
    :raises 400: Si no se proporciona el numero de orden. 
    :raises 404: Si no se encuentra la orden.
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
@admin_bp.route("api/v1/admins/consulta-admin-por-usuario", methods=["GET"])
@token_required
@handle_errors
def consult_adiminUsuario(): 
    """
    Ruta para consultar al administrador por el usuario. 
    :queyparam usuario: Nombre del usuario del administrador a consultar (en los parametros de URL). 
    :return: Los detalles del administrador si se encuentra. 
    :raises 400: Si no se proporciona el nombre del usuario. 
    :raises 404: Si no se encuentra el administrador.
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
@admin_bp.route("api/v1/admins/consulta-contratista", methods=["GET"])
@token_required
@handle_errors
def consultaContratista(): 
    """
    Ruta para la consultar a los contratistas con la cedula de identidad o rif. 
    :queryparam ci_rif: Cedula de identidad o rif del contratista a consultar (en los parametros URL). 
    :return: Los detalles del contratista si se encuentra. 
    :raises 400: Si no se proporciona cedula de identidad o rif del contratista.
    :raises 404: Si no se encuentra el contratista. 
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
@admin_bp.route("api/v1/admins/actualizar-contratista", methods=["PUT"])
@token_required
@handle_errors
def actualizarContratista(): 
    """
    ACtualiza los datos de un contratista. 
    :return: Un mensaje de exito si el contratista fue actualizado con exito. 
    :raises 400: Si los datos porporcionados son validos. 
    :raises 404: Si los contratista no se encuentra. 
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
@admin_bp.route("api/v1/admins/eliminar-contratista", methods=["DELETE"])
@token_required
@handle_errors
def eliminarContratista(): 
    """
     Ruta para eliminar un contratista.

    :queryparam ci_rif: Cédula de identidad o RIF del contratista a eliminar (en los parámetros de la URL).
    :return: Un mensaje de éxito si el contratista se elimina correctamente.
    :raises 400: Si no se proporciona la cédula de identidad o RIF.
    :raises 404: Si el contratista no se encuentra.

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
@admin_bp.route("api/v1/admins/crear-cliente", methods=["POST"])
@token_required
@handle_errors
def crearCliente(): 
    """
    Ruta para crear un cliente. 
    :return: Un mensaje de exito si el cliente fue creado con exito.
    :raises 400: Si los datos proporcionados son invalidos. 
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
@admin_bp.route("api/v1/admins/consultar-cliente", methods=["GET"])
@token_required
@handle_errors
def consultarCliente(): 
    """
    Ruta para consultar un cliente por su numero de cuenta. 
    :queryparam Nro_cuenta: Numero de cuenta del cliente a consultar (en los parametros de URL). 
    :return: Los detalles del cliente si se encuentra. 
    :raises 400: Si no se proporciona el numero de cuenta. 
    :raises 404: Si no se encuentra el cliente.
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
@admin_bp.route("api/v1/admins/actualizar-cliente", methods=["PUT"])
@token_required
@handle_errors
def actualizarCliente(): 
    """
    Ruta para actualizar los datos de un cliente. 
    :return: Un mensaje de exito si el cliente fue actualizado con exito. 
    :raises 400: Si los datos proporcionados son invalidos. 
    :raises 404: Si el cliente no se encuentra. 
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
@admin_bp.route("api/v1/admins/eliminar-cliente", methods=["DELETE"])
@token_required
@handle_errors
def eliminarCliente(): 
    """
    Ruta para eliminar un cliente. 
    :queryparam Nro_cuenta: Numero de cuenta del cliente a eliminar (en los parametros de URL). 
    :return: Un mensaje de exito si el cliente fue eliminado con exito. 
    :raises 400: Si no se proporciona el numero de cuenta. 
    :raises 404: Si el cliente no se encuentra. 
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
    
@admin_bp.route("api/v1/admins/autorizacion-cliente", methods=["PUT"])
@token_required
@handle_errors
def autorizacion_cliente():
    """
    Ruta para realizar y confirmar la autorizacion de la entrada del cliente a la red. 
    Espera un JSON con Nro_orden y contratista.
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


@admin_bp.route("/api/v1/admins/autorizar-instalacion", methods=["PUT"])
@token_required
@handle_errors
def autorizar_instalacion_route():
    """
    Ruta para que el administrador autorice una orden de instalación.
    Espera un JSON con Nro_orden y contratista.
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

@admin_bp.route("api/v1/admins/ordenes-no-autorizadas", methods=["GET"])
@token_required
@handle_errors
def instalaciones_no_autorizadas():
    """
    Ruta donde se visualiza todas las ordenes de instalación no autorizadas.
    Espera lista de ordenes.
   """
    try:
        result = ordenes_no_autorizadas()
        if not result:
            return jsonify([]), 200
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": "Error interno del servidor", "details": str(e)}), 500
    

@admin_bp.route("/descargar_pdf/<int:nro_orden>", methods=['GET'])
@token_required
@handle_errors
def descargar_pdf(nro_orden):
    """
    Ruta para descargar el PDF de instalación.
    :param nro_orden: Número de orden de instalación.
    :return: El archivo PDF de instalación.
    :raises 404: Si no existe el PDF o no hay datos para generarlo.
    """
    ruta_pdf = f"orden_instalacion_{nro_orden}.pdf"
    if not os.path.exists(ruta_pdf):
        from Backend.services.contrators_service import datos_instalacion, generar_pdf_instalacion
        datos = datos_instalacion(nro_orden)
        if not datos:
            return {"error": "No existe la orden o no hay datos para generar el PDF"}, 404
        ruta_pdf = generar_pdf_instalacion(nro_orden, datos)
    return send_file(ruta_pdf, as_attachment=True)