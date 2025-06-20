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
    Autenticar cliente por cédula de identidad o RIF
    ---
    tags:
      - Clientes
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
    responses:
      200:
        description: Cliente autenticado exitosamente.
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
        description: Datos inválidos o faltantes.
        examples:
          application/json: { "error": "Datos inválidos" }
      404:
        description: Cliente no encontrado.
        examples:
          application/json: { "error": "Cliente no encontrado" }
      500:
        description: Error interno del servidor.
        examples:
          application/json: { "error": "Error interno del servidor" }

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
    """
   Crear una orden de instalación
    ---
    tags:
      - Clientes
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
              fecha_hora1:
                type: string
                example: "2023-10-01T10:00:00"
              fecha_hora2:
                type: string
                example: "2023-10-01T12:00:00"
              latitud:
                type: number
                example: 10.123456
              longitud:
                type: number
                example: -64.123456
              comentario:
                type: string
                example: "Instalación de servicio"
    responses:
      201:
        description: Orden creada exitosamente
        examples:
          application/json: { "message": "Orden creada exitosamente", "Nro_orden": 1 }
      400:
        description: Datos inválidos o faltantes
        examples:
          application/json: { "error": "Datos inválidos" }
      500:
        description: Error interno del servidor
        examples:
          application/json: { "error": "Error interno del servidor" }
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


# Ruta para consultar la orden de instalación de un cliente.
@clients_bp.route("/api/v1/clients/consulta-orden/<Nro_orden>", methods=["GET"])
def consulta_cliente_orden(Nro_orden):
    """
    Consultar la orden de instalación de un cliente
    ---
    tags:
      - Clientes
    parameters:
      - in: path
        name: Nro_orden
        required: true
        schema:
          type: string
        description: Número de orden de instalación a consultar
      - in: query
        name: Nro_cuenta
        required: false
        schema:
          type: string
        description: Número de cuenta del cliente (opcional)
    responses:
      200:
        description: Datos de la orden encontrados
        examples:
          application/json:
            {
              "Nro_orden": "1",
              "Nro_cuenta": "1234567890",
              "fecha_hora1": "2023-10-01T10:00:00",
              "fecha_hora2": "2023-10-01T12:00:00",
              "latitud": 10.123456,
              "longitud": -64.123456,
              "comentario": "Instalación de servicio",
              "estado": "Asignada",
              "contratista": "Contratista Ejemplo"
            }
      400:
        description: Se requiere Nro_cuenta o Nro_orden
        examples:
          application/json: { "error": "Se requiere Nro_cuenta o Nro_orden" }
      404:
        description: Orden no encontrada
        examples:
          application/json: { "error": "Orden no encontrada" }
      500:
        description: Error interno del servidor
        examples:
          application/json: { "error": "Error interno del servidor" }    
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
