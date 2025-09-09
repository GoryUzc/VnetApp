class AppStrings {
  static const String appTitle = "Sistema de Gestión VNET";
  static const String systemDescription =
      "Seleccione el tipo de usuario para continuar";
  static const String vnetUsers = "Usuarios VNET";
  static const String clients = "Clientes";
  static const String vnetUsersSemantics =
      "Iniciar sesión como usuario del sistema VNET";
  static const String clientsSemantics = "Iniciar sesión como cliente";
  static const String welcomeMessage = "Bienvenido, por favor inicie sesión";
  static const String email = "Correo electrónico";
  static const String emailRequired = "El correo electrónico es obligatorio";
  static const String invalidEmail = "Correo electrónico inválido";
  static const String password = "Contraseña";
  static const String passwordRequired = "La contraseña es obligatoria";
  static const String passwordTooShort =
      "La contraseña debe tener al menos 8 caracteres";
  static const String login = "Iniciar sesión";
  static const String loginFailed =
      "Error al iniciar sesion. Por favor verificar credenciales";
  static const String confirmDeleteTitle = "Confirmar eliminación";
  static String confirmDeleteMessage(String name) =>
      "¿Está seguro que desea eliminar el prospecto '$name'? Esta acción no se puede deshacer.";
  static const String cancel = "Cancelar";
  static const String delete = "Eliminar";
  static const String prospectDeleted = "Prospecto eliminado exitosamente";
  static const String refresh = "Actualizar";
  static const String addProspect = "Agregar prospecto";
  static const String errorLoadingProspects = "Error al cargar prospectos";
  static const String retry = "Reintentar";
  static const String noProspectsRegistered = "No hay prospectos registrados";
  static const String createFirstProspectDescription =
      "No hay prospectos en el sistema. Cree el primer prospecto para comenzar.";
  static const String createFirstProspect = "Crear primer prospecto";
  static const String notAvailable = "No disponible";
  static const String anonymous = "Sin nombre";
  static const String networkError =
      "Error de conexión. Verifique su conexión a internet.";
  static const String unauthorizedError =
      "Sesión expirada. Por favor inicie sesión nuevamente.";
  static const String notFoundError =
      "Recurso no encontrado. Contacte al administrador.";
  static const String genericError =
      "Ocurrió un error inesperado. Intente nuevamente.";
  static const String searchProspects = "Buscar prospectos...";
  static const String personalInformation = "Información Personal";
  static const String contactInformation = "Información de Contacto";
  static const String franchise = "Franquicia";
  static const String name = "Nombre";
  static const String lastName = "Apellido";
  static const String document = "Documento";
  static const String documentType = "Tipo de Documento";
  static const String phone = "Teléfono";
  static const String address = "Dirección";
  static const String city = "Ciudad";
  static const String plan = "Plan";
  static const String selectFranchise = "Seleccione una franquicia";
  static const String untitledFranchise = "Franquicia sin nombre";
  static const String noFranchises = "Sin franquicias";
  static const String selectRole = "Seleccione un rol";
  static const String noFranchisesAvailable = "No hay franquicias disponibles";
  static const String updateProspect = "Actualizar Prospecto";
  static const String prospectUpdated = "Prospecto actualizado exitosamente";
  static const String errorUpdatingProspect = "Error al actualizar prospecto";
  static const String validationError =
      "Error de validación. Por favor revise los campos.";
  static String maxCharactersError(int max) =>
      "No debe exceder $max caracteres";
  static const String fieldRequired = "Este campo es requerido";
  static const String errorLoadingData = "Error al cargar datos";
}
