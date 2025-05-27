from models.database import get_db
from app import socketio

def emitir_notificacion_contratista(data):
    """
    Emite una notificación al contratista a través de WebSocket.
    :param data: Datos de la notificación.
    """
    socketio.emit('notificacion_contratista', data, namespace='/contratista')

def emitir_notificacion_admin(data):
    """
    Emite una notificación al administrador a través de WebSocket.
    :param data: Datos de la notificación.
    """
    socketio.emit('notificacion_admin', data, namespace='/admin')


def autentic_client(ci_rif):
    """
    Autentica un cliente en la base de datos.
    :param ci_rif: cedula de identidad o rif del cliente a autenticar.
    :return: Datos del cliente o mensaje de error.
    """
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM clientes WHERE ci_rif = %s", (ci_rif,))
    client = cursor.fetchone()
    
    if client:
        return client
    else:
        return {"error": "Cliente no encontrado"}
    

def create_order(Nro_cuenta, fecha_hora1, fecha_hora2, latitud, longitud, comentario):
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            "INSERT INTO ordenes_instalacion (Nro_cuenta, fecha_hora1, fecha_hora2, estado, latitud, longitud, comentario) VALUES (%s, %s, %s, %s, %s, %s, %s)",
            (Nro_cuenta, fecha_hora1, fecha_hora2, "Pendiente", latitud, longitud, comentario)
        )
        db.commit()
        nro_orden = cursor.lastrowid

               # Notificar al administrador
        socketio.emit(
            'nueva_orden_cliente',
            {
                'message': f'Nuevo pedido de instalación: Orden {nro_orden}',
                'Nro_orden': nro_orden,
                'Nro_cuenta': Nro_cuenta
            },
            namespace='/admin'
        )

        # Notificar a los contratistas
        socketio.emit(
            'nueva_orden_cliente',
            {
                'message': f'Nuevo pedido de instalación disponible: Orden {nro_orden}',
                'Nro_orden': nro_orden,
                'Nro_cuenta': Nro_cuenta
            },
            namespace='/contratista'
        )


        # Datos para la notificación
        notificacion = {
            "message": "Nueva orden creada",
            "Nro_orden": nro_orden,
            "Nro_cuenta": Nro_cuenta,
            "fecha_hora1": fecha_hora1,
            "fecha_hora2": fecha_hora2,
            "latitud": latitud,
            "longitud": longitud,
            "comentario": comentario
        }

        # Notificar al contratista y al administrador
        emitir_notificacion_contratista(notificacion)
        emitir_notificacion_admin(notificacion)

        return {
            "message": "Orden creada exitosamente",
            "Nro_orden": nro_orden
        }
    except Exception as e:
        db.rollback()
        return {"error": f"Error al crear la orden: {str(e)}"}
    finally:
        cursor.close()
        db.close()


def consult_order(Nro_cuenta=None, Nro_orden=None):
    """
    Consulta la orden de instalacion de la base de datos.
    :param Nro_cuenta: numero de cuenta del cliente. 
    :param Nro_orden: numero de orden de instalacion.
    :return: Datos de la orden o mensaje de error.
    """
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        if Nro_cuenta:
            cursor.execute("SELECT * FROM ordenes_instalacion WHERE Nro_cuenta = %s", (Nro_cuenta,))
        elif Nro_orden:
            cursor.execute("SELECT * FROM ordenes_instalacion WHERE Nro_orden = %s", (Nro_orden,))
        else:
            return {"error": "Se debe proporcionar un número de cuenta o un número de orden"}
        
        order = cursor.fetchone()
        
        if order:
            return order
        else:
            return {"error": "Orden no encontrada"}
    except Exception as e:
        return {"error": f"Error al consultar la orden: {str(e)}"}
    finally:
        cursor.close()
        db.close()


