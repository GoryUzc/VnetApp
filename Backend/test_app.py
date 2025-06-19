import pytest
from app import app 
@pytest.fixture


#Configuracion de mi cliente de pruebas
def client(): 
    app.config["TESTING"]= True 
    with app.test_client() as client: 
        yield client 

 
 
#                                INICIO TEST RUTAS ADMINISTRADOR 




# Test para el endpoint de login de administradores
def test_login_admin(client):
    response = client.post(
        "/api/v1/admins/login",
        json={"USUARIO": "usuario_prueba", "CONTRASEÑA": "clave_prueba"}
    )
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el edpoint del menu de administardores
def test_menu_admin(client):
    response = client.get("/api/v1/admins/menu")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint de estadisticas
def test_estadisticas(client):
    response = client.get("/api/v1/admins/estadisticas")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

#Test para el endpoint consultar orden
def test_consultar_orden(client):
    response = client.get("/api/v1/admins/consultar-orden/1")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint de consultar admin por usuario
def test_consultar_admin_por_usuario(client):
    response = client.get("/api/v1/admins/consulta-admin-por-usuario/usuario_prueba")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

#Test para el endpoint asignar instalacion
def test_asignar_instalacion(client):
    response = client.post(
        "/api/v1/admins/asignacion-instalacion",
        json={"Nro_orden": 1, "contratista": "contratista_prueba"}
    )
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint para crear cliente 
def test_crear_cliente(client):
    response = client.post(
        "/api/v1/admins/crear-cliente",
        json={
            "Nro_cuenta": "1234567890",
            "nombre": "Cliente Prueba",
            "ci_rif": "V12345678",
            "telefono": "04123456789",
            "direccion": "Calle Falsa 123",
            "municipio": "Municipio Prueba",
            "sector": "Sector Prueba",
            "plan_contrato": "Plan Basico 200"
        }
    )
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint para consultar cliente 
def test_consultar_cliente(client):
    response = client.get("/api/v1/admins/consultar-cliente/1234567890")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint para actualizar cliente
def test_actualizar_cliente(client):    
    response = client.put(
        "/api/v1/admins/actualizar-cliente/1234567890",
        json={
            "nombre": "Cliente Actualizado",
            "telefono": "04123456789",
            "direccion": "Calle Actualizada 456",
            "municipio": "Municipio Actualizado",
            "sector": "Sector Actualizado",
            "plan_contrato": "Plan Avanzado 500"
        }
    )
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint para eliminar cliente
def test_eliminar_cliente(client):
    response = client.delete("/api/v1/admins/eliminar-cliente/1234567890")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint de consultar contratista
def test_consultar_contratista(client):
    response = client.get("/api/v1/admins/consulta-contratista/contratista_prueba")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint actualizar contratista
def test_actualizar_contratista(client):
    response = client.put(
        "/api/v1/admins/actualizar-contratista/contratista_prueba",
        json={
             "ci_rif": "V12345678",
             "nombre": "Contratista Actualizado",
             "telefono": "04123456789",
             "USUARIO": "usuario_actualizado",
            "CONTRASEÑA": "clave_actualizada",
            "correo": "hgwqfyfdwyfdw.com",
            "sucursal": "Sucursal Actualizada",
            "cuadrillas": 4,
            "cuadrilla1": "Cuadrilla 1 Actualizada",
            "cuadrilla2": "Cuadrilla 2 Actualizada",    
            "cuadrilla3": "Cuadrilla 3 Actualizada",
            "cuadrilla4": "Cuadrilla 4 Actualizada"
        }
    )
    print(response.json)
    assert response.status_code in [200, 401, 400]

# Test para el endpoint eliminar contratista
def test_eliminar_contratista(client):
    response = client.delete("/api/v1/admins/eliminar-contratista/contratista_prueba")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para eliminar ordenes
def test_eliminar_orden(client):
    response = client.delete("/api/v1/admins/eliminar-orden/1")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint de consultar ordenes
def test_consultar_ordenes(client):
    response = client.get("/api/v1/admins/ordenes")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test de el endpoint de consultar ordenes no autorizadas.
def test_consultar_ordenes_no_autorizadas(client):
    response = client.get("/api/v1/admins/ordenes-no-autorizadas")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint para autorizar ordenes
def test_autorizar_orden(client):
    response = client.put(
        "/api/v1/admins/autorizacion-cliente/1",
        json={"contratista": "contratista_prueba"}
    )
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el descaragar pdf de ordenes 
def test_descargar_pdf_orden(client):
    response = client.get("/descargar_pdf/1")
    print(response.json) 
    assert response.status_code in [200, 401, 400]



#                FIN TEST DE ADMINISTRADOR




#                INICIO TEST RUTAS CLIENTES 



# Test para el endpoint autenticacion de clientes
def test_autenticacion_cliente(client):
    response = client.post(
       "/api/v1/clients/autenticacion",
        json={"ci_rif": "V12345678"}
    )
    print(response.json) 
    assert response.status_code in [200, 401, 400]

#Test para el endpoint crear orden
def test_crear_orden(client):
    response = client.post(
        "/api/v1/clients/orden",
        json={
            "Nro_cuenta": "1234567890",
            "fecha_hora1": "2023-10-01T10:00:00",
            "fecha_hora2": "2023-10-01T12:00:00",
            "latitud": 10.123456,
            "longitud": -64.123456,
            "comentario": "Instalación de servicio"
        }
    )
    print(response.json) 
    assert response.status_code in [201, 400]

# Test para el endpoint consultar orden de cliente
def test_consultar_orden_cliente(client):
    responce = client.get("/api/v1/clients/consulta-orden/12345678")
    print(responce.json)
    assert responce.status_code in [200, 401, 400]



#                    FIN TEST RUTAS CLIENTES




    #INICIO TEST RUTAS CONTRATISTAS



#Test para el endpoint de crear contratista 
def test_crear_administrador(client):
    response = client.post(
        "/api/v1/contrators/create",
        json={
            "ci_rif": "V12345678",
            "nombre": "Contratista Prueba",
            "telefono": "04123456789",
            "USUARIO": "usuario_contratista",
            "CONTRASEÑA": "clave_contratista",
            "correo": "dhfdwqfdgwqugud.com",
            "sucursal": "Sucursal Prueba",
            "cuadrillas": 3,
            "cuadrilla1": "Cuadrilla 1",
            "cuadrilla2": "Cuadrilla 2",
            "cuadrilla3": "Cuadrilla 3",
        }
    )

# Test para el endpoint autenticacion de contratistas
def test_login_contratista(client):
    response = client.post(
        "/api/v1/contrators/login",
        json={"USUARIO": "usuario_contratista", "CONTRASEÑA": "clave_contratista"}
    )
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test de el endpoint del menu contratista
def test_menu_contratista(client):
    response = client.get("/api/v1/contrators/menu")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint de ordenes de instalacion disponible contratista
def test_ordenes_disponibles_contratista(client):
    response = client.get("/api/v1/contrators/installations")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint de ordenes  de instalacion asignadas al contratista
def test_asignar_orden_instalacion(client):
    response = client.get(
        "/api/v1/contrators/assigned_installations")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint del contratista toma una orden de instalacion 
def test_tomar_orden_instalacion(client):
    response = client.post(
        "/api/v1/contrators/take_installations",
        json={"Nro_orden": 1}
    )
    print(response.json) 
    assert response.status_code in [200, 401, 400]

#Test para el endpoint para el contratista inicie instalacion 
def test_iniciar_instalacion(client):
    response = client.post(
        "/api/v1/contrators/init_installation/1",
        json={
            "Nro_orden": 1,
            "contratista": "contratista_prueba",
            "usuarioID": "usuario_contratista",
            "contraseñaID": "clave_contratista",
            "Estado": "En Proceso",
            "observacion_contratista": "Iniciando instalación"
            }
    )
    
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint del contratista finaliza instalacion
def test_finalizar_instalacion(client):
    response = client.post(
        "/api/v1/contrators/finish_installation/1",
        json={
            "ci_rif": "V12345678",
            "Nro_orden": 1,
            "contratista": "contratista_prueba",
            "estado": "Finalizada",
            "verificacion": True,
            "observacion_contratista": "Instalación finalizada con éxito"
        }
    )
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint para los datos del pdf de la orden de instalacion.
def test_datos_pdf_orden_instalacion(client):
    response = client.post("/api/v1/contrators/order_installation",
                           json={
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
            )
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test de el endpoint de la visualizacion de los datos para generar el pdf de la orden de instalacion 
def test_visualizar_datos_pdf_orden_instalacion(client):
    response = client.get("/api/v1/contrators/data_installation/1")
    print(response.json) 
    assert response.status_code in [200, 401, 400]

# Test para el endpoint de descarga pdf de la orden de instalacion
def test_descargar_pdf_orden_instalacion(client):
    response = client.post("/api/v1/contrators/generate_pdf_installation/1")
    print(response.json) 
    assert response.status_code in [200, 401, 400]




#                               FIN TEST RUTAS CONTRATISTAS