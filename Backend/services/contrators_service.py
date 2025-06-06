from models.database import get_db
from werkzeug.security import generate_password_hash
from flask_socketio import emit, SocketIO
from app import SocketIO, socketio
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
import tempfile
import os
from datetime import datetime, timedelta



#Creacion de contratista
def create_contrators(ci_rif, nombre, telefono, USUARIO, CONTRASEÑA, correo, sucursal, cuadrillas, cuadrilla1, cuadrilla2, cuadrilla3, cuadrilla4, cuadrilla5, cuadrilla6, cuadrilla7, cuadrilla8, cuadrilla9, cuadrilla10):
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
         "INSERT INTO contratistas (ci_rif, nombre, telefono, USUARIO, CONTRASEÑA, correo, sucursal, cuadrillas, cuadrilla1, cuadrilla2, cuadrilla3, cuadrilla4,  cuadrilla5, cuadrilla6, cuadrilla7, cuadrilla8, cuadrilla9, cuadrilla10) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", 
         (ci_rif, nombre, telefono, USUARIO, hashed_contraseña, correo, sucursal, cuadrillas, cuadrilla1, cuadrilla2, cuadrilla3, cuadrilla4,  cuadrilla5, cuadrilla6, cuadrilla7, cuadrilla8, cuadrilla9, cuadrilla10)
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
def init_installation(Nro_orden, contratista, usuarioID, contraseñaID, estado, observacion_contratista):
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
        hora_inicio = datetime.now()
        cursor.execute(
            "SELECT * FROM ordenes_instalacion WHERE Nro_orden = %s AND contratista = %s",
            (Nro_orden, contratista)
        )
        orden = cursor.fetchone()
        if not orden:
            return {"error": "La instalacion no existe o no esta asignada a este contratista."}

        cursor.execute(
            "UPDATE ordenes_instalacion SET usuarioID = %s, contraseñaID = %s, estado = %s, observacion_contratista = %s, hora_inicio = %s WHERE Nro_orden = %s",
            (usuarioID, contraseñaID, "en_proceso", observacion_contratista, hora_inicio, Nro_orden)
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
def finish_installation(ci_rif, Nro_orden, estado, verificacion, observacion_contratista):
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
        # Obtener la hora de inicio de la instalacion
        cursor.execute(
            "SELECT hora_inicio FROM ordenes_instalacion WHERE Nro_orden = %s",
            (Nro_orden,)
        )
        orden = cursor.fetchone()
        if not orden or not orden['hora_inicio']:
            raise Exception ("No se encontró la hora de inicio de la orden de instalacion.")
        
        hora_inicio = orden['hora_inicio']
        hora_final = datetime.now()

        # Verificar si ya pasaron mas de 12 horas 
        if hora_final - hora_inicio > timedelta(hours=12):
            estado = "fallida"
            # Sumar al contador de fallidas
            cursor.execute(
                "UPDATE contratistas SET instalaciones_fallidas = instalaciones_fallidas + 1 WHERE ci_rif = %s",
                (ci_rif,)
            )
            # Actualizar el estado de la orden de instalacion a fallida
            cursor.execute(
                "UPDATE ordenes_instalacion SET estado = %s, observacion_contratista = %s, verificacion = %s WHERE Nro_orden = %s",
                (estado, observacion_contratista, False, Nro_orden)
            )
            db.commit()
            notificar_administrador_instalacion(Nro_orden, "Finalizada")
            return {"message": "Instalacion finalizada como fallida."}
        else:
            estado = "exitosa"
            # Actualizar el estado de la orden de instalacion
            cursor.execute(
                "UPDATE ordenes_instalacion SET estado = %s, observacion_contratista = %s, verificacion = %s WHERE Nro_orden = %s",
                (estado, observacion_contratista, True, Nro_orden)
            )
            # Sumar al contador de exitosas
            cursor.execute(
                "UPDATE contratistas SET instalaciones_exitosas = instalaciones_exitosas + 1 WHERE ci_rif = %s",
                (ci_rif,)
            )
            db.commit()
            notificar_administrador_instalacion(Nro_orden, "Finalizada")
            return {"message": "Instalacion finalizada con exito."}
    except Exception as e:
        db.rollback()
        raise Exception(f"Error al finalizar la instalacion: {str(e)}")
    finally:
        cursor.close()
        db.close()


#Datos orden de insalacion.
def orden_instalacion(dato_cliente, ont_1puerto, conector_SC_APC, pathcore_scapc_apcsc, roseta, scapc_adapter, ont_4puertos, conector_scupc, canaletas, cable_drop, cantidad_cabledrop, potencia_cajanap, potencia_ont, mac_ont, serial_ont, puerto_nap, nroequipos_conectar, etiqueta_cliente, router, fecha, hora_inicio, hora_final, contratista, nombre_cliente, firma):
    """
    Datos de la orden de instalacion para gernerar el pdf.
    :param dato_cliente: Toda a informacion del cliente (numero de cuenta, direccion, telefono, etc.). 
    :param ont_1puerto: Cantidad de ONT de 1 puerto.
    :param conector_SC_APC: Cantidad de conectores SC/APC.
    :param pathcore_scapc_apcsc: Cantidad del cable de fibra optica desde la ONT hasta el conector SC/APC.
    :param roseta: Cantidad de roseta utilizada para la instalacion.
    :param scapc_adapter: Cantidad adaptador SC/APC utilizado.
    :param ont_4puertos: Cantidad ONT de 4 puertos.
    :param conector_scupc: Cantidad de conector SC/UPC utilizado.
    :param canaletas: Cantidad de canaletas utilizadas para la instalacion.
    :param cable_drop: Cable drop utilizado (hilo de fibra optica).
    :param cantidad_cabledrop: Cantidad de cable drop utilizado.
    :param potencia_cajanap: Potencia recibida para la instalacion en la roseta.
    :param potencia_ont: Potencia recibida para la instalacion en la caja nap.
    :param mac_ont: MAC address 
    :param serial_ont: Numero de serial.
    :param puerto_nap: Indica el puerto donde esta conectado en la caja nap.
    :param nroequipos_conectar: Numero de equipos a conectar a la onu.
    :param etiqueta_cliente: Numero de identificacion del cliente. 
    :param router: Marca y modelo del router del cliente. 
    :param fecha: Fecha que se hizo la instalacion.
    :param hora_inicio: Hora de inicio de la instalacion
    :param hora_final: Hora de finalizacion de la instalacion. 
    :param contratista: Nombre del contratista 
    :param nombre_cliente: Nombre del cliente. 
    :param firma: Firma digital del cliente.
    :return: Diccionario con los datos
    
    """
    db = get_db()
    cursor = db.cursor()
    try: 
        cursor.execute(
            "INSERT INTO doc.ordenes (dato_cliente, ont_1puerto, conector_SC_APC, pathcore_scapc_apcsc, roseta, scapc_adapter, ont_4puertos, conector_scupc, canaletas, cable_drop, cantidad_cabledrop, potencia_cajanap, potencia_ont, mac_ont, serial_ont, puerto_nap, nroequipos_conectar, etiqueta_cliente, router, fecha, hora_inicio, hora_final, contratista, nombre_cliente, firma) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            (dato_cliente, ont_1puerto, conector_SC_APC, pathcore_scapc_apcsc, roseta, scapc_adapter, ont_4puertos, conector_scupc, canaletas, cable_drop, cantidad_cabledrop, potencia_cajanap, potencia_ont, mac_ont, serial_ont, puerto_nap, nroequipos_conectar, etiqueta_cliente, router, fecha, hora_inicio, hora_final, contratista, nombre_cliente, firma)
        )
        db.commit()
        id = cursor.lastrowid
        return {
            "id": id,
            "message": "Datos almacenados con exito."
        }
    except Exception as e:
        db.rollback()
        raise Exception(f"Error: Error al almacenar los datos {str(e)}")
    finally:
        cursor.close()
        db.close()


#Datos de la orden de instalacion
def datos_instalacion(id): 
    """
    Obtiene los datos de la orden de instalacion como diccionario a partir de la id. 
    :param id: Numero de identificacion de los datos en la base de datos.
    :return: Diccionario con los datos de la orden o None si no existe. 
    
    """
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try: 
        cursor.execute(
            "SELECT * FROM doc.ordenes WHERE id = %s", (id,)
        )
        datos = cursor.fetchone()
        return datos #Un diccionario o un none 
    except Exception as e: 
        raise Exception(f"Error al consultar los datos de la orden: {str(e)}")
    finally: 
        cursor.close()
        db.close()


#Cambiar el formato de la firma del cliente 
def guardar_firma_blob_en_imagen(firma_blob):
    """
    Guarda el blob de la firma en un archivo temporal y retorna la ruta.
    """
    temp = tempfile.NamedTemporaryFile(delete=False, suffix=".png")
    temp.write(firma_blob)
    temp.close()
    return temp.name


#Generar orden instalacion.
def generar_pdf_instalacion(Nro_orden, datos_instalacion, ruta_destino=None):
    if not ruta_destino:
        ruta_destino = f"orden_instalacion_{Nro_orden}.pdf"
    c = canvas.Canvas(ruta_destino, pagesize=letter)
    width, height = letter

    # --- Logo ---
    logo_path = "ruta/al/logo.png"
    if os.path.exists(logo_path):
        c.drawImage(logo_path, 50, height - 100, width=120, height=60, mask='auto')

    # --- Título ---
    c.setFont("Helvetica-Bold", 16)
    c.drawString(200, height - 60, f"Orden de Instalación N° {Nro_orden}")

    # --- Línea separadora ---
    c.setLineWidth(1)
    c.line(40, height - 110, width - 40, height - 110)

    # --- Datos de la instalación ---
    c.setFont("Helvetica", 12)
    y = height - 140
    for key, value in datos_instalacion.items():
        if key == "firma":
            continue
        c.drawString(50, y, f"{key}: {value}")
        y -= 18
        if y < 100:
            c.showPage()
            y = height - 50

    # --- Firma digital (desde BLOB) ---
    firma_blob = datos_instalacion.get("firma")
    if firma_blob:
        firma_path = guardar_firma_blob_en_imagen(firma_blob)
        c.drawString(50, y - 30, "Firma digital del cliente:")
        c.drawImage(firma_path, 200, y - 50, width=120, height=60, mask='auto')
        os.remove(firma_path)

    c.save()
    return os.path.abspath(ruta_destino)


#Generar y notificar pdf
def generar_y_notificar_pdf(Nro_orden, datos_instalacion, socketio):
    ruta_pdf = generar_pdf_instalacion(Nro_orden, datos_instalacion)
    socketio.emit(
        'pdf_generado',
        {
            'message': f'Se generó el PDF de la orden {Nro_orden}.',
            'Nro_orden': Nro_orden,
            'ruta_pdf': f'/descargar_pdf/{Nro_orden}'
        },
        namespace='/admin'
    )
    return ruta_pdf

#Ojo regular las ordenes de instalacion de los contratistas por medio del numero de cuadrillas que tengan disponible.

