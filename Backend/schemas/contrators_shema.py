from marshmallow import Schema, fields, validate, ValidationError



# Validaciones reutilizables
length_1_20 = validate.Length(min=1, max=20)
length_1_50 = validate.Length(min=1, max=50)
length_1_15 = validate.Length(min=1, max=15)
length_1_500 = validate.Length(min=1, max=500)
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


# Validación personalizada para firmas en formato blob
def validar_firma_blob(firma):
    """
    Valida que la firma sea un blob válido.

    :param firma: La firma a validar.
    :raises ValidationError: Si la firma no es un blob válido.
    """
    if not isinstance(firma, bytes):
        raise ValidationError("La firma debe ser un blob (bytes).")
    

class ConstraSchema(Schema):
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


class InitInstallSchema(Schema):
    """
    Esquema de validación para la inicializacion de la instalacion.
    """
    usuarioID = fields.Str(required=True, validate=length_1_20)
    contraseñaID = fields.Str(required=True, validate=length_1_20)
    estado = fields.Str(required=None)
    observacion_contratista = fields.Str(required=True, validate=length_1_200)

class FinishInstallSchema(Schema):
    """
    Esquema de validación para la finalización de instalaciones.
    """
    estado = fields.Str(required=None)
    observacion_contratista = fields.Str(required=True, validate=length_1_200)

class DateOrderInstallSchema(Schema):
    """
    Esquema de validación para los datos de orden de instalación.
    """
    dato_cliente = fields.Str(required=True, validate=length_1_500)
    ont_1puerto = fields.Str(required=True, validate=length_1_20)
    conector_SC_APC = fields.Str(required=True, validate=length_1_20)
    pathcore_scapc_apcsc = fields.Str(required=True, validate=length_1_20)
    roseta = fields.Str(required=True, validate=length_1_20)
    scapc_adapter = fields.Str(required=True, validate=length_1_20)
    ont_4puertos = fields.Str(required=True, validate=length_1_20)
    conector_scupc = fields.Str(required=True, validate=length_1_20)
    canaletas = fields.Str(required=True, validate=length_1_20)
    cable_drop = fields.Str(required=True, validate=length_1_20)
    cantidad_cabledrop = fields.Str(required=True, validate=length_1_20)
    potencia_cajanap = fields.Str(required=True, validate=length_1_20)
    potencia_ont = fields.Str(required=True, validate=length_1_20)
    mac_ont = fields.Str(required=True, validate=length_1_20)
    serial_ont = fields.Str(required=True, validate=length_1_20)
    puerto_nap = fields.Str(required=True, validate=length_1_20)
    nroequipos_conectar = fields.Str(required=True, validate=length_1_20)
    etiqueta_cliente = fields.Str(required=True, validate=length_1_20)
    router = fields.Str(required=True, validate=length_1_50)
    fecha = fields.Date(required=True, validate=length_1_20)
    hora_inicio = fields.Time(required=True, validate=length_1_20)
    hora_final = fields.Time(required=True, validate=length_1_20)
    contratista = fields.Str(required=True, validate=length_1_50)
    nombre_cliente = fields.Str(required=True, validate=length_1_50)
    firma = fields.Raw(required=True, validate=validar_firma_blob)