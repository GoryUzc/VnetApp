from marshmallow import Schema, fields, validate 
    
class AdminSchema(Schema):
    ci_rif = fields.Str(required=True, validate=validate.Length(min=1, max=20))
    nombre = fields.Str(required=True, validate=validate.Length(min=1, max=30))
    telefono = fields.Str(required=True, validate=validate.Length(min=1, max=20))
    USUARIO = fields.Str(required=True, validate=validate.Length(min=1, max=20))
    CONTRASEÑA = fields.Str(required=True, validate=validate.Length(min=1, max=20))
    correo = fields.Str(required=True, validate=validate.Length(min=1, max=30))
    sucursal = fields.Str(required=True, validate=validate.Length(min=1, max=50))
    cuadrillas = fields.Str(required=True, validate=validate.Length(min=1, max=4))
    cuadrilla1 = fields.Str(required=True, validate=validate.Length(min=1, max=40))
    cuadrilla2 = fields.Str(required=True, validate=validate.Length(min=1, max=40))
    cuadrilla3 = fields.Str(required=True, validate=validate.Length(min=1, max=40))
    cuadrilla4 = fields.Str(required=True, validate=validate.Length(min=1, max=40))
    intalaciones_exitosas = fields.Str(required=True, validate=validate.Length(min=1, max=20))
    intalaciones_fallidas = fields.Str(required=True, validate=validate.Length(min=1, max=20))

class ContratorShema(Schema):
    USUARIO = fields.Str(required=True, validate=validate.Length(min=1, max=20))
    CONTRASEÑA = fields.Str(required=True, validate=validate.Length(min=1, max=20))

class InstalationSchema(Schema):
     id_cliente= fields.Int(required=True)
    id_contrator = fields.Int(required=True)
    id_cliente = fields.Int(required=True)
    fecha = fields.Str(required=True, validate=validate.Length(min=1, max=20))
    hora = fields.Str(required=True, validate=validate.Length(min=1, max=20))
    status = fields.Str(required=True, validate=validate.Length(min=1, max=20))
    cuadrilla = fields.Str(required=True, validate=validate.Length(min=1, max=20))
