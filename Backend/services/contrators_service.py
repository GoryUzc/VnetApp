from models.database import get_db
from werkzeug.security import generate_password_hash
from flask_socketio import emit, SocketIO
from app import SocketIO, socketio
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
import os


#Creacion de contratista
def create_contrators(ci_rif, nombre, telefono, USUARIO, CONTRASEÑA, correo, sucursal, cuadrillas, cuadrilla1, cuadrilla2, cuadrilla3, cuadrilla4):
    """
    Crear un nuevo contratista en la base de datos. 
    :param ci_rif: Cedula de identidad o RIF del contratista.
    :param nombre: Nombre de la empresa o contratista. 
    :param telefono: Telefono del contratista. 
    :param USUARIO: Usuario de la empresa contratista para ingresar a la app. 
    :param CONTRASEÑA: Contraseña de la empresa contratista para ingresar a la app. 
    :param correo: Direccion de correo electronica de la empresa contratista. 
    :param sucursal: Sucursal en la que se encuentra la empresa contratista. 
    :param cuadrillas: Numero de cuadrillas que maneja la empresa contratista. 
    :param cuadrilla1: Nombre de la persona en la cuadrilla numero uno. 
    :param cuadrilla2: Nombre de la persona en la cuadrilla numero dos. 
    :param cuadrilla3: Nombre de la persona en la cuadrilla numero tres. 
    :param cuadrilla4: Nombre de la persona en la cuadrilla numero cuatro. 
    """
    db = get_db()
    cursor = db.cursor()
    hashed_contraseña = generate_password_hash(CONTRASEÑA, method="pbkdf2:sha256", salt_length=8)
    try: 
        cursor.execute(
         "INSERT INTO contratistas (ci_rif, nombre, telefono, USUARIO, CONTRASEÑA, correo, sucursal, cuadrillas, cuadrilla1, cuadrilla2, cuadrilla3, cuadrilla4) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", 
         (ci_rif, nombre, telefono, USUARIO, hashed_contraseña, correo, sucursal, cuadrillas, cuadrilla1, cuadrilla2, cuadrilla3, cuadrilla4)
    )  
        db.commit()
        return {"message":"Contratista creado con exito."} 
    except Exception as e: 
        db.rollback()
        raise Exception(f"Error al crear cliente: {str(e)}")
    finally: 
        cursor.close()
        db.close()

    
#Todas las intslaciones disponibles
def get_all_installations(): 
    """
    Obtiene todas las instalaciones disponibles en la base de datos.
    :return: Lista de instalaciones disponibles o mensaje de error.
    """
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM ordenes_instalacion WHERE estado= %s", ("pendiente",))
        installations = cursor.fetchall()
        if not installations:
            return {"message": "No hay instalaciones disponibles"}
        return installations
    except Exception as e:
        raise Exception(f"Error al consultas las instalaciones diponibles: {str(e)}")
    finally:
        cursor.close()
        db.close()


#Tomar una instalacion. 
def take_installation(Nro_orden, contratista):
    """
    Asigna una instalacion (orden) a un contratista y actualiza su estado. 
    :param Nro_orden: Numero de orden de la instalacion a tomar.
    :param contratista: Nombre del contratista que toma la instalacion.
    return: Mensaje de exito o error.
    """
    db = get_db()
    cursor = db.cursor()
    try: 
        #Verifica que la orden exista y este disponible. 
        cursor.execute(
            "SELECT * FROM ordenes_instalacion WHERE Nro_orden = %s AND (contratista IS NULL OR contratista = '') AND estado = %s",
            (Nro_orden, "pendiente")
        )
        orden = cursor.fetchone()
        if not orden: 
            return {"error": "La instalacion no esta disponible o ya fue tomada."}
        
        #Asigna el contratista a la orden 
        cursor.execute(
            "UPDATE ordenes_instalacion SET contratista = %s, estado = %s WHERE Nro_orden = %s", 
            (contratista, "asignada", Nro_orden)
        )
        db.commit()

        #notificar al administrador 
        notificar_administrador_orden(Nro_orden, contratista)

        return {"message": "Instalacion tomada con exito."}
    
    except Exception as e:
        db.rollback()
        raise Exception(f"Error al tomar la instalacion: {str(e)}")
    finally:
        cursor.close()
        db.close()


#Instalaciones asignadas a contratista
def get_assigned_installation(contratista):
    """
    Obtiene las instalaciones pendientes para un contratista especifico. 
    :param contratista: Nombre del contratista que solicita las instalaciones. 
    :return: Lista de instalaciones pendientes o mensaje de error.
    """
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            "SELECT * FROM ordenes_instalacion WHERE contratista = %s AND estado = %s", 
            (contratista, "asignada")
        )
        installations = cursor.fetchall()
        if not installations:
            return {"message": "No hay instalaciones asignadas para este contratista."}
        return installations
    except Exception as e:
        raise Exception(f"Error al consultar las instalaciones pendientes: {str(e)}")
    finally:
        cursor.close()
        db.close()


#Inicio proceso de instalacion
def init_installation(Nro_orden, contratista, usuarioID, contraseñaID, estado, observacion):
    """
    Inicia el proceso de instalacion hasta la finalizacion. 
    :param Nro_orden: Numero de orden de la instalacion a procesar. 
    :param contratista: Nombre del contratista que procesa la instalacion. 
    :param usuarioID: Usuario configurado en el modem del cliente por el contratista.
    :param contraseñaID: Contraseña configurada en el modem del cliente por el contratista.
    :param estado: Nuevo estado de la instalacion. 
    :param observacion: Observaciones sobre la instalacion hecha por el contratista. 
    :return: Mensaje de exito o error.
    """
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            "SELECT * FROM ordenes_instalacion WHERE Nro_orden = %s AND contratista = %s",
            (Nro_orden, contratista)
        )
        orden = cursor.fetchone()
        if not orden:
            return {"error": "La instalacion no existe o no esta asignada a este contratista."}

        cursor.execute(
            "UPDATE ordenes_instalacion SET usuarioID = %s, contraseñaID = %s, estado = %s, observaciones = %s WHERE Nro_orden = %s",
            (usuarioID, contraseñaID, "en_proceso", observacion, Nro_orden)
        )
        db.commit()

        # Notificar al administrador
        notificar_administrador_instalacion(Nro_orden, contratista)

        return {"message": "Instalacion procesada con exito."}
    except Exception as e:
        db.rollback()
        raise Exception(f"Error al procesar la instalacion: {str(e)}")
    finally:
        cursor.close()
        db.close()


#emitir notificacion al administrador instalacion. 
def notificar_administrador_instalacion(Nro_orden, contratista):
    socketio.emit(
        'solicitud_autorizacion',
        {
            'message': f'El contratista {contratista} solicita autorización para la orden {Nro_orden}.',
            'Nro_orden': Nro_orden,
            'contratista': contratista
        },
        namespace='/admin'
    )


#emitir notificacion siobre orden de instalacion tomada por el contratista. 
def notificar_administrador_orden(Nro_orden, contratista):
    socketio.emit(
        'solicitud_autorizacion',
        {
            'message': f'El contratista {contratista} a tomado la orden de instalacion {Nro_orden}.',
            'Nro_orden': Nro_orden,
            'contratista': contratista
        },
        namespace='/admin'
        )


#Final proceso de instalacion.
def finish_installation(Nro_orden, estado, verificacion, observacion):
    """
    Finaliza el proceso de instalacion, verificacion de red. 
    :param Nro_orden: Numero de orden de la instalacion a finalizar. 
    :param estado: Nuevo estado de la instalacion. 
    :param observacion: Observaciones sobre la instalacion hecha por el contratista. 
    :return: Mensaje de exito o error.
    """
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute(
            "UPDATE ordenes_instalacion SET estado = %s, observaciones = %s, verificacion = %s WHERE Nro_orden = %s",
        (estado, observacion, True, Nro_orden)
        )
        db.commit()

        # Notificar al administrador
        notificar_administrador_instalacion(Nro_orden, "Finalizada")

        return {"message": "Instalacion finalizada con exito."}
    except Exception as e:
        db.rollback()
        raise Exception(f"Error al finalizar la instalacion: {str(e)}")
    finally:
        cursor.close()
        db.close()


#Datos orden de insalacion.
def orden_instalacion(dato_cliente, ont_1puerto, conector_SC_APC, pathcore_scapc_apcsc, roseta, scapc_adapter, ont_4puertos, conector_scupc, canaletas, cable_drop, cantidad_cabledrop, potencia_planificada, potencia_recibida, mac_ont, serial_ont, puerto_nap, nroequipos_conectar, puerto_olt, etiqueta_cliente, router, tecnico, vehiculo, fecha, hora_inicio, hora_final, contratista, nombre_cliente, firma):
    """
    Datos de la orden de instalacion para gernerar el pdf. 
    :param dato_cliente: Toda a informacion del cliente. 
    :param ont_1puerto: 




















    """
    db = get_db()
    cursor = db.cursor()
    try: 
        cursor.execute(
            "INSERT INTO doc.ordenes (dato_cliente, ont_1puerto, conector_SC_APC, pathcore_scapc_apcsc, roseta, scapc_adapter, ont_4puertos, conector_scupc, canaletas, cable_drop, cantidad_cabledrop, potencia_planificada, potencia_recibida, mac_ont, serial_ont, puerto_nap, nroequipos_conectar, puerto_olt, etiqueta_cliente, router, tecnico, vehiculo, fecha, hora_inicio, hora_final, contratista, nombre_cliente, firma) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
            (dato_cliente, ont_1puerto, conector_SC_APC, pathcore_scapc_apcsc, roseta, scapc_adapter, ont_4puertos, conector_scupc, canaletas, cable_drop, cantidad_cabledrop, potencia_planificada, potencia_recibida, mac_ont, serial_ont, puerto_nap, nroequipos_conectar, puerto_olt, etiqueta_cliente, router, tecnico, vehiculo, fecha, hora_inicio, hora_final, contratista, nombre_cliente, firma)
        )
        db.commit()
        id = cursor.lastrowid
        return {"message": "Datos almacenados con exito."}
    except Exception as e:
        db.rollback()
        raise Exception(f"Error: Error al almacenar los datos {str(e)}")
    finally:
        cursor.close()
        db.close()

 
 #Generar orden instalacion.
def generar_pdf_instalacion(Nro_orden, datos_instalacion, ruta_destino=None):
    """
    Genera un PDF con los datos de la instalación.
    :param Nro_orden: Número de orden de la instalación.
    :param datos_instalacion: Diccionario con los datos relevantes de la instalación.
    :param ruta_destino: Ruta donde guardar el PDF (opcional).
    :return: Ruta del archivo PDF generado.
    """
    if not ruta_destino:
        ruta_destino = f"orden_instalacion_{Nro_orden}.pdf"
    c = canvas.Canvas(ruta_destino, pagesize=letter)
    width, height = letter

    c.setFont("Helvetica-Bold", 16)
    c.drawString(50, height - 50, f"Orden de Instalación N° {Nro_orden}")

    c.setFont("Helvetica", 12)
    y = height - 100
    for key, value in datos_instalacion.items():
        c.drawString(50, y, f"{key}: {value}")
        y -= 20

    c.save()
    return os.path.abspath(ruta_destino)
#Ojo regular las ordenes de instalacion de los contratistas por medio del numero de cuadrillas que tengan disponible. 