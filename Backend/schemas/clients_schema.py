from marshmallow import Schema, fields, validate, ValidationError

# Validaciones reutilizables
length_1_20 = validate.Length(min=1, max=20)
length_1_50 = validate.Length(min=1, max=50)
length_1_15 = validate.Length(min=1, max=15)
length_1_100 = validate.Length(min=1, max=100)
length_1_200 = validate.Length(min=1, max=200)
length_8_20 = validate.Length(min=8, max=20)  # Para contraseñas

    
class OrderSchema(Schema):
    Nro_contrato = fields.Str(required=True, validate=length_1_20)
    fecha_hora1 = fields.DateTime(required=True)
    fecha_hora2 = fields.DateTime(required=True)
    latitud = fields.Float(required=True)
    longitud = fields.Float(required=True)
    comentario = fields.Str(required=True, validate=length_1_200)

class AtenthicationClientsSchema(Schema):
    ci_rif = fields.Str(required=True, validate=length_1_20)

def validate_data(schema, data):
    try:
        schema.load(data)
    except ValidationError as err:
        return {"error": err.messages}
    return None