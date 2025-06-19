from flask import Blueprint, jsonify, request
from marshmallow import ValidationError
from services.clients_service import (
    autentic_client, create_order, consult_order,
)
from schemas.clients_schema import (
    OrderSchema, AtenthicationClientsSchema, validate_data,
)

clients_bp = Blueprint("clients", __name__)


# Ruta para autenticar al cliente en la base de datos.
@clients_bp.route("/api/v1/clients/autenticacion", methods=["POST"])
def autentic_client_route():
    """
    Ruta para autenticar al cliente en la base de datos.
    :return: Datos del cliente o mensaje de error.

    """
    data = request.get_json()
    validation_error = validate_data(AtenthicationClientsSchema(), data)
    if validation_error:
        return jsonify(validation_error), 400
    ci_rif = data.get("ci_rif")
    try:
        clients = autentic_client(ci_rif)
        return jsonify(clients), 200
    except Exception as e:
        return jsonify({
            "error": "Error interno del servidor",
            "details": str(e),
            "route": request.path
        }), 500


# Ruta para crear una orden de instalación.
@clients_bp.route("/api/v1/clients/orden", methods=["POST"])
def crear_orden():
    """Ruta para crear una orden de instalación.
    :return: Mensaje de éxito o error.  
    """
    data = request.get_json()
    validation_error = validate_data(OrderSchema(), data)
    if validation_error:
        return jsonify(validation_error), 400

    try:
        result = create_order(
            data["Nro_cuenta"],
            data["fecha_hora1"],
            data["fecha_hora2"],
            data["latitud"],
            data["longitud"],
            data["comentario"]
        )
        # Supón que result ya incluye el número de orden si fue exitoso
        if result.get("message") == "Orden creada exitosamente":
            return jsonify(result), 201
        else:
            return jsonify(result), 400
    except Exception as e:
        return jsonify({
            "error": "Error interno del servidor",
            "details": str(e),
            "route": request.path
        }), 500

@clients_bp.route("/api/v1/clients/consulta-orden/<Nro_orden>", methods=["GET"])
def consulta_cliente_orden(Nro_orden):
    """
    Ruta para consultar la orden de instalación de un cliente.
    :param Nro_cuenta: número de cuenta del cliente.
    :param Nro_orden: número de orden de instalación.
    :return: Datos de la orden o mensaje de error.
    """
    Nro_cuenta = request.args.get("Nro_cuenta")
    Nro_orden = request.args.get("Nro_orden")
    if not Nro_cuenta and not Nro_orden:
        return jsonify({"error": "Se requiere Nro_cuenta o Nro_orden"}), 400
    try:
        result = consult_order(Nro_cuenta=Nro_cuenta, Nro_orden=Nro_orden)
        if "error" in result:
            return jsonify(result), 404
        return jsonify(result), 200
    except Exception as e:
        return jsonify({
            "error": "Error interno del servidor",
            "details": str(e),
            "route": request.path
        }), 500
