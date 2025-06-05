from models.database import get_db
from werkzeug.security import generate_password_hash
from flask_socketio import emit, SocketIO
from app import socketio
from contrators_service import (notificacion_contratista,)

#creacion Administrador
def create_administrador(ci_rif, nombre, USUARIO, CONTRASEÑA, telefono, sucursal):
    """
    Crea un nuevo administrador en la base de datos.

    :param ci_rif: Identificación del administrador (Cédula o RIF).
    :param nombre: Nombre completo del administrador.
    :param USUARIO: Nombre de usuario para el administrador.
    :param CONTRASEÑA: Contraseña del administrador (sin hash).
    :param telefono: Número de teléfono del administrador.
    :param sucursal: Sucursal asociada al administrador.
    :return: Un diccionario con un mensaje de éxito.
    :raises Exception: Si ocurre un error al insertar en la base de datos.
    """
    db = get_db()
    cursor = db.cursor()
    hashed_contraseña = generate_password_hash(CONTRASEÑA, method="pbkdf2:sha256", salt_length=8)
    try:
        cursor.execute(
            "INSERT INTO administradores (ci_rif, nombre, USUARIO, CONTRASEÑA, telefono, sucursal) VALUES (%s, %s, %s, %s, %s, %s)",
            (ci_rif, nombre, USUARIO, hashed_contraseña, telefono, sucursal)
        )
        db.commit()
        return {"message": "Administrador creado con éxito"}
    except Exception as e:
        db.rollback()
        raise Exception(f"Error al crear administrador: {str(e)}")
    finally:
        cursor.close()
        db.close()


#creacion de cliente
def create_cliente(Nro_cuenta, nombre, ci_rif, telefono, direccion, municipio, sector, plan_contrato):
    """
    Crea un nuevo cliente en la base de datos.

    :param Nro_cuenta: Número de cuenta del cliente.
    :param nombre: Nombre completo del cliente.
    :param ci_rif: Identificación del cliente (Cédula o RIF).
    :param telefono: Número de teléfono del cliente.
    :param direccion: Dirección del cliente.
    :param municipio: Municipio donde reside el cliente.
    :param sector: Sector donde reside el cliente.
    :param plan_contrato: Plan de contrato asociado al cliente.
    :return: Un diccionario con un mensaje de éxito.
    :raises Exception: Si ocurre un error al insertar en la base de datos.
    """
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            "INSERT INTO clientes (Nro_cuenta, nombre, ci_rif, telefono, direccion, municipio, sector, plan_contrato) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
            (Nro_cuenta, nombre, ci_rif, telefono, direccion, municipio, sector, plan_contrato)
        )
        db.commit()
        return {"message": "Cliente creado con éxito"}
    except Exception as e:
        db.rollback()
        raise Exception(f"Error al crear cliente: {str(e)}")
    finally:
        cursor.close()
        db.close()
    

#Consulta de cliente
def consulta_cliente(Nro_cuenta):
    """
    Consulta un cliente en la base de datos por su número de cuenta."""
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            "SELECT * FROM clientes WHERE Nro_cuenta = %s",
            (Nro_cuenta,)
        )
        cliente = cursor.fetchone()
        if cliente:
            return cliente
        else:
            raise Exception("Cliente no encontrado")
    except Exception as e:
        raise Exception(f"Error al consultar cliente con Nro_cuenta {Nro_cuenta}: {str(e)}")
    finally:
        cursor.close()
        db.close()
    

#Actualizar cliente
def update_cliente(Nro_cuenta, nombre, ci_rif, telefono, direccion, municipio, sector, plan_contrato):
    """
    Actualiza la información de un cliente en la base de datos.

    :param Nro_cuenta: Número de cuenta del cliente.
    :param nombre: Nuevo nombre del cliente.
    :param ci_rif: Nueva identificación del cliente (Cédula o RIF).
    :param telefono: Nuevo número de teléfono del cliente.
    :param direccion: Nueva dirección del cliente.
    :param municipio: Nuevo municipio del cliente.
    :param sector: Nuevo sector del cliente.
    :param plan_contrato: Nuevo plan de contrato del cliente.
    :return: Un diccionario con un mensaje de éxito.
    :raises Exception: Si ocurre un error al actualizar en la base de datos.
    """
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            "UPDATE clientes SET nombre = %s, ci_rif = %s, telefono = %s, direccion = %s, municipio = %s, sector = %s, plan_contrato = %s WHERE Nro_cuenta = %s",
            (nombre, ci_rif, telefono, direccion, municipio, sector, plan_contrato, Nro_cuenta)
        )
        db.commit()
        return {"message": "Cliente actualizado con éxito"}
    except Exception as e:
        db.rollback()
        raise Exception(f"Error al actualizar cliente: {str(e)}")
    finally:
        cursor.close()
        db.close()


#Eliminar cliente
def delete_cliente(Nro_cuenta):
    """
    Elimina un cliente de la base de datos.

    :param Nro_cuenta: Número de cuenta del cliente a eliminar.
    :return: Un diccionario con un mensaje de éxito.
    :raises Exception: Si ocurre un error al eliminar en la base de datos.
    """
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            "DELETE FROM clientes WHERE Nro_cuenta = %s",
            (Nro_cuenta,)
        )
        db.commit()
        return {"message": "Cliente eliminado con éxito"}
    except Exception as e:
        db.rollback()
        raise Exception(f"Error al eliminar cliente: {str(e)}")
    finally:
        cursor.close()
        db.close()


#Asigna un contratista a una orden específica.
def asignar_instalacion(Nro_orden, contratista):
    """
    Asigna un contratista a una instalación específica en la base de datos."""
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            "UPDATE ordenes_instalacion SET contratista = %s WHERE Nro_orden = %s",
            (contratista, Nro_orden)
        )
        db.commit()
        return {"message": "Contratista asignado con éxito"}
    except Exception as e:
        db.rollback()
        raise Exception(f"Error al asignar contratista con Nro_orden {Nro_orden}: {str(e)}")
    finally:
        cursor.close()
        db.close()


#Consulta de contratista
def consulta_contratista(ci_rif, nombre):
    """
    Consulta un contratista en la base de datos por su cédula o nombre."""
    db = get_db()
    cursor = db.cursor(dictionary=True) 
    try:
        cursor.execute(
            "SELECT * FROM contratistas WHERE ci_rif = %s OR nombre = %s",
            (ci_rif, nombre,)
        )
        contratista_data = cursor.fetchone()
        if contratista_data:
            return contratista_data
        else:
            raise Exception("Contratista no encontrado")
    except Exception as e:
        raise Exception(f"Error al consultar contratista: {str(e)}")
    finally:
        cursor.close()
        db.close()
  
    
#Actualiza la información de un contratista.
def update_contratista (ci_rif, nombre, telefono, USUARIO, CONTRASEÑA, correo, sucursal, cuadrillas, cuadrilla1, cuadrilla2, cuadrilla3, cuadrilla4,  cuadrilla5, cuadrilla6, cuadrilla7, cuadrilla8, cuadrilla9, cuadrilla10, instalaciones_exitosas, instalaciones_fallidas):
    """
    Actualiza la información de un contratista en la base de datos.
    """
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            "UPDATE contratistas SET nombre = %s, telefono = %s, USUARIO = %s, CONTRASEÑA = %s, correo = %s, sucursal = %s, cuadrillas = %s, cuadrilla1 = %s, cuadrilla2 = %s, cuadrilla3 = %s, cuadrilla4 = %s,  cuadrilla5 = %s, cuadrilla6 = %s, cuadrilla7 = %s, cuadrilla8 = %s, cuadrilla9 = %s, cuadrilla10 = %s, instalaciones_exitosas = %s, instalaciones_fallidas = %s WHERE ci_rif = %s",
            (nombre, telefono, USUARIO, CONTRASEÑA, correo, sucursal, cuadrillas, cuadrilla1, cuadrilla2, cuadrilla3, cuadrilla4,  cuadrilla5, cuadrilla6, cuadrilla7, cuadrilla8, cuadrilla9, cuadrilla10, instalaciones_exitosas, instalaciones_fallidas, ci_rif)
        )
        db.commit()
        return {"message": "Contratista actualizado con éxito"}
    except Exception as e:
        db.rollback()
        raise Exception(f"Error al actualizar contratista: {str(e)}")
    finally:
        cursor.close()
        db.close()
    

#Borra un contratista de la base de datos.
def delete_contratista(ci_rif):
    """
    Elimina un contratista de la base de datos."""
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            "DELETE FROM contratistas WHERE ci_rif = %s",
            (ci_rif,)
         )
        db.commit()
        return {"message": "Contratista eliminado con éxito"}
    except Exception as e:
        db.rollback()
        raise Exception(f"Error al eliminar contratista: {str(e)}")
    finally:
        cursor.close()
        db.close()
            
   
#Obtiene estadísticas generales de la aplicación.
def get_estadisticas():
    """
    Obtiene estadísticas generales de la aplicación.

    :return: Un diccionario con las estadísticas:
        - total_clients: Número total de clientes.
        - total_contractors: Número total de contratistas.
        - total_orders_completed: Número total de órdenes completadas.
        - total_orders_pending: Número total de órdenes pendientes.
        - total_orders_failed: Número total de órdenes fallidas.
    :raises Exception: Si ocurre un error al consultar las estadísticas.
    """
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT 
                (SELECT COUNT(*) FROM clientes) AS total_clients,
                (SELECT COUNT(*) FROM contratistas) AS total_contractors,
                (SELECT COUNT(*) FROM ordenes_instalacion WHERE estado = 'completado') AS total_orders_completed,
                (SELECT COUNT(*) FROM ordenes_instalacion WHERE estado = 'pendiente') AS total_orders_pending,
                (SELECT COUNT(*) FROM ordenes_instalacion WHERE estado = 'fallido') AS total_orders_failed
        """)
        estadisticas = cursor.fetchone()

        return {
            "total_clients": estadisticas["total_clients"],
            "total_contractors": estadisticas["total_contractors"],
            "total_orders_completed": estadisticas["total_orders_completed"],
            "total_orders_pending": estadisticas["total_orders_pending"],
            "total_orders_failed": estadisticas["total_orders_failed"]
        }
    except Exception as e:
        raise Exception(f"Error al obtener estadísticas: {str(e)}")
    finally:
        cursor.close()
        db.close()


#PROCESOS DE ADMINISTRACION DE INSTALACIONES
def consulta_Nro_orden(Nro_orden):
    """
    Consulta una instalación en la base de datos por su número de orden.
    :param Nro_orden: Número de orden de la instalación.
    :return: Un diccionario con los detalles de la instalación o un mensaje de error si no se encuentra.
    """
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            "SELECT * FROM ordenes_instalacion WHERE Nro_orden = %s",
            (Nro_orden,)
        )
        instalacion = cursor.fetchone()
        if instalacion:
            return instalacion
        return {"error": "Instalación no encontrada"}
    except Exception as e:
        raise Exception(f"Error al consultar instalación: {str(e)}")
    finally:
        cursor.close()
        db.close()


#Obtiene un administrador por su nombre de usuario.
def consulta_admin_por_usuario(usuario):
    """
    Obtiene un administrador por su nombre de usuario.
    """
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM administradores WHERE USUARIO = %s", (usuario,))
        admin = cursor.fetchone()
        return admin
    except Exception as e:
        raise Exception(f"Error al obtener el administrador: {str(e)}")
    finally:
        cursor.close()
        db.close()
    

#Autoriza el acceso en la olt y aradial/HACER RUTA 
def autorizar_instalacion(Nro_orden, contratista):
    """
    Autoizacion a aradial y olt hechas por el administrador y actualiza el olt_aradial a True, luego notifica al contratista. 
    :param Nro_orden: Número de orden de la instalación.
    :param contratista: Nombre del contratista que toma la instalación.
    :return: Un diccionario con un mensaje de éxito o error.
    """
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            "UPDATE ordenes_instalacion SET aradial_olt = %s WHERE Nro_orden = %s AND contratista = %s",
            (True, Nro_orden, contratista)
        )
        db.commit()


        # Notificar al contratista
        notificar_contratista_autorizacion(Nro_orden, contratista)
        return {"message": "Instalación autorizada y contratista notificado."}
    except Exception as e:
        db.rollback()
        return {"error": f"Error al autorizar la instalación: {str(e)}"}
    finally:
        cursor.close()
        db.close()


#Notificacion al contratista. 
def notificar_contratista_autorizacion(Nro_orden, contratista):
    socketio.emit(
        'autorizacion_instalacion',
        {
            'message': f'La orden {Nro_orden} ha sido autorizada. Puede continuar.',
            'Nro_orden': Nro_orden
        },
        namespace='/contratista'
    )


#lista de ordenes sin autorizar 
def ordenes_no_autorizadas():
    """
    Retorna la lista de ordenes de instalacionque no estan autorizadas (aradial_olt = False).
    :return: Lista de ordenes no autorizadas.
    """
    db = get_db()
    cursor = db.cursor(dicctionary=True)
    try: 
        cursor.execute(
            "SELECT * FROM ordenes_instalacion WHERE aradial_olt = %s OR aradial_olt IS NULL",
            (False,)
        )
        ordenes = cursor.fetchall()
        return ordenes
    except Exception as e:
        return {"error": f"Error a consultar las ordenes no autorizadas: {str(e)}"}
    finally: 
        cursor.close()
        db.close()