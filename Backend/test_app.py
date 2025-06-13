import pytest
from app import app 
@pytest.fixture


#Configuracion de mi cliente de pruebas
def client(): 
    app.config["TESTING"]= True 
    with app.test_client() as client: 
        yield client 

def test_login_contrator(client):
    response = client.post(
        "/api/v1/contrators/login",
        json={"USUARIO": "usuario_prueba", "CONTRASEÑA": "clave_prueba"}
    )
    print(response.json) 
    assert response.status_code in [200, 401, 400]

def test_login_admin(client):
    response = client.post(
        "/api/v1/admins/login",
        json={"USUARIO": "usuario_prueba", "CONTRASEÑA": "clave_prueba"}
    )
    print(response.json) 
    assert response.status_code in [200, 401, 400]

#Ejemplo Metodo GET testing
def test_get_menu_contrator(client):
    # token para acceder
    login = client.post(
        "/api/v1/contrators/login",
        json={"USUARIO": "usuario_prueba", "CONTRASEÑA": "clave_prueba"}
    )
    token = login.json.get("token")
    headers = {"Authorization": token} if token else {}
    response = client.get("/api/v1/contrators/menu", headers=headers)
    print(response.json)
    assert response.status_code in [200, 401]

#Ejemplo Metodo post testing
def test_create_contrator(client):
    response = client.post(
        "/api/v1/contrators/create",
        json={
            "USUARIO": "nuevo_usuario",
            "CONTRASEÑA": "clave_segura",
            "nombre": "Nombre Prueba",
            "ci_rif": "12345678",
            "telefono": "04141234567",
            "cuadrillas": 1
        }
    )
    print(response.json)
    assert response.status_code in [201, 400]

#Ejemplo Metodo PUT testing
def test_update_contrator(client):
    # Supón que necesitas un token y un ID de contratista existente
    login = client.post(
        "/api/v1/contrators/login",
        json={"USUARIO": "usuario_prueba", "CONTRASEÑA": "clave_prueba"}
    
    )
    token = login.json.get("token")
    headers = {"Authorization": token} if token else {}
    response = client.put(
        "/api/v1/contrators/update/12345678",  # Cambia por el endpoint real y el ID correcto
        json={"telefono": "04140000000"},
        headers=headers
    )
    print(response.json)
    assert response.status_code in [200, 400, 404]

#Ejemplo Metodo DELETE testing
#def test_delete_contrator(client):
    # Supón que necesitas un token y un ID de contratista existente
    #login = client.post(
        #

