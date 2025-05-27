from marshmallow import Schema, fields, validate, ValidationError

# Validaciones reutilizables
length_1_20 = validate.Length(min=1, max=20)
length_1_50 = validate.Length(min=1, max=50)
length_1_15 = validate.Length(min=1, max=15)
length_1_100 = validate.Length(min=1, max=100)
length_1_200 = validate.Length(min=1, max=200)
length_8_20 = validate.Length(min=8, max=20)  # Para contraseñas

# Validación personalizada para contraseñas
def validacion_contraseña(password):
    """
    Valida que una contraseña cumpla con los requisitos de seguridad.

    :param password: La contraseña a validar.
    :raises ValidationError: Si la contraseña no cumple con los requisitos.
    """
    if not any(char.isdigit() for char in password):
        raise ValidationError("La contraseña debe contener al menos un número.")
    if not any(char.isupper() for char in password):
        raise ValidationError("La contraseña debe contener al menos una letra mayúscula.")
    if not any(char in "!@#$%^&*()_+-=[]{}|;:,.<>?/" for char in password):
        raise ValidationError("La contraseña debe contener al menos un carácter especial.")

# Validación personalizada para campos numéricos
def validacion_numerica(valor):
    """
    Valida que un campo contenga solo números.

    :param valor: El valor a validar.
    :raises ValidationError: Si el valor no contiene solo números.
    """
    if not str(valor).isdigit():
        raise ValidationError("Este campo debe contener solo números.")

# Esquema para Administradores
class CreateAdminSchema(Schema):
    """
    Esquema de validación para la creación de administradores.
    """
    ci_rif = fields.Str(required=True, validate=length_1_20)
    nombre = fields.Str(required=True, validate=length_1_50)
    USUARIO = fields.Str(required=True, validate=length_1_20)
    CONTRASEÑA = fields.Str(required=True, validate=[length_8_20, validacion_contraseña])
    telefono = fields.Str(required=True, validate=[length_1_15, validacion_numerica])
    sucursal = fields.Str(required=True, validate=length_1_50)

# Esquema para Clientes
class CreateClienteSchema(Schema):
    """
    Esquema de validación para la creación de clientes.
    """
    Nro_cuenta = fields.Str(required=True, validate=[length_1_20, validacion_numerica])
    nombre = fields.Str(required=True, validate=length_1_50)
    ci_rif = fields.Str(required=True, validate=length_1_20)
    telefono = fields.Str(required=True, validate=[length_1_15, validacion_numerica])
    direccion = fields.Str(required=True, validate=length_1_200)
    municipio = fields.Str(required=True, validate=length_1_50)
    sector = fields.Str(required=True, validate=length_1_100)
    plan_contrato = fields.Str(required=True, validate=length_1_50)

#Esquema para contratistas.
class UpdateContratistaSchema(Schema):
    ci_rif = fields.Int(required=True, validate=[length_1_20, validacion_numerica])
    nombre = fields.Str(required=True, validate=length_1_50)
    telefono = fields.Str(required=True, validate=length_1_20)
    USUARIO = fields.Str(required=True, validate=length_1_20)
    CONTRASEÑA = fields.Str(required=True, validate=[length_8_20, validacion_contraseña])
    correo = fields.Str(required=True, validate=length_1_15)
    sucursal = fields.Str(required=True, validate=length_1_20) 
    cuadrillas = fields.Int(required=True, validate=[length_1_15, validacion_numerica])
    cuadrilla1 = fields.Str(required=True, validate=length_1_100)
    cuadrilla2 = fields.Str(required=True, validate=length_1_100)
    cuadrilla3 = fields.Str(required=True, validate=length_1_100)
    cuadrilla4 = fields.Str(required=True, validate=length_1_100)

class LoginSchema(Schema):
    USUARIO = fields.Str(required=True)
    CONTRASEÑA = fields.Str(required=True, validate=[length_8_20, validacion_contraseña])


class AsignacionInstalacionSchema(Schema):
    Nro_orden = fields.Int(required=True, validate=[length_1_20, validacion_numerica])
    contratista = fields.Str(required=True, validate=length_1_50)


class UpdateClienteSchema(Schema):
    Nro_cuenta = fields.Str(required=True, validate=[length_1_20, validacion_numerica])
    nombre = fields.Str(validate=length_1_50)
    ci_rif = fields.Str(validate=length_1_20)
    telefono = fields.Str(validate=[length_1_15, validacion_numerica])
    direccion = fields.Str(validate=length_1_200)
    municipio = fields.Str(validate=length_1_50)
    sector = fields.Str(validate=length_1_100)
    plan_contrato = fields.Str(validate=length_1_50)

    
def validate_data(schema, data):
    try:
        schema.load(data)
    except ValidationError as err:
        return {"error": err.messages}
    return None