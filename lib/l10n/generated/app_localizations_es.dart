// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get labelMainTab => 'Básico';

  @override
  String get labelSubTab => 'Extendido';

  @override
  String get labelExtraTab => 'Avanzado';

  @override
  String get labelEtcTab => 'Atributos';

  @override
  String get labelCategoryAdd => 'Agregar texto';

  @override
  String get labelCategoryRemove => 'Eliminar texto';

  @override
  String get labelCategoryReplace => 'Reemplazar/Convertir';

  @override
  String get labelCategoryNumbering => 'Numeración';

  @override
  String get labelCategoryExtension => 'Extensión';

  @override
  String get labelCategoryAdvanced => 'Avanzado';

  @override
  String get labelStringInput => 'Cadena';

  @override
  String get labelColName => 'Nombre';

  @override
  String get labelColNewName => 'Nuevo nombre';

  @override
  String get labelColSize => 'Tamaño';

  @override
  String get labelColPath => 'Ruta';

  @override
  String get labelColType => 'Tipo';

  @override
  String get labelColDate => 'Fecha de modificación';

  @override
  String get labelColAttr => 'Atrib';

  @override
  String get labelOpPrefix => 'Agregar al principio';

  @override
  String get labelOpSuffix => 'Agregar al final';

  @override
  String get labelOpInsert => 'Insertar en pos';

  @override
  String get labelOpDeleteStart => 'Eliminar desde principio';

  @override
  String get labelOpDeleteEnd => 'Eliminar desde el final';

  @override
  String get labelOpDeleteFrom => 'Eliminar desde pos';

  @override
  String get labelOpCapitalize => 'Capitalizar frente';

  @override
  String get labelOpUpper => 'Todo en mayúsculas';

  @override
  String get labelOpLower => 'Todo en minúsculas';

  @override
  String get labelOpExtChange => 'Cambiar ext';

  @override
  String get labelOpExtAdd => 'Agregar ext';

  @override
  String get labelOpExtRemove => 'Eliminar ext';

  @override
  String get labelOpExtUpper => 'Ext en mayúsculas';

  @override
  String get labelOpExtLower => 'Ext en minúsculas';

  @override
  String get labelSubExtChangeTitle => 'Cambio de extensión';

  @override
  String get labelSubFormatTitle => 'Formato de palabra';

  @override
  String get labelSubFormatProperCase =>
      'Caso adecuado (Espacio/Guion/Subrayado)';

  @override
  String get labelSubListTitle => 'Renombrar lista';

  @override
  String get labelSubListModeText => 'Entrada de texto (Original[TAB]Nuevo)';

  @override
  String get labelSubListSample1 => 'Ejemplo: Archivos numerados';

  @override
  String get labelSubListSample2 => 'Ejemplo: Cambio de ext masivo';

  @override
  String get labelSubListSample3 => 'Ejemplo: Reemplazo específico';

  @override
  String get labelSubListHint =>
      'nombre_viejo.txt\tnombre_nuevo.txt\narchivo01.png\timagen01.png';

  @override
  String get labelExtraAppendDate => 'Añadir fecha de archivo';

  @override
  String get labelExtraDateFormatHint => 'Formato de fecha (Ej: yyyymmdd_)';

  @override
  String get labelExtraPosition => 'Posición';

  @override
  String get labelExtraFront => 'Frente';

  @override
  String get labelExtraBack => 'Atrás';

  @override
  String get labelExtraConvHalfToFull => 'Media a ancho completo';

  @override
  String get labelExtraConvFullToHalf => 'Ancho completo a medio';

  @override
  String get labelExtraConvKataToHira => 'Katakana a Hiragana';

  @override
  String get labelExtraConvHiraToKata => 'Hiragana a Katakana';

  @override
  String get labelExtraConvFullAlphaToHalf => 'Alfa completo a medio';

  @override
  String get labelExtraConvNumToHalf => 'Números a la mitad';

  @override
  String get labelEtcAttribReadOnly => 'Solo lectura';

  @override
  String get labelEtcAttribHidden => 'Oculto';

  @override
  String get labelEtcAttribArchive => 'Archivo';

  @override
  String get labelEtcAttribSystem => 'Sistema';

  @override
  String get labelEtcTimestampChange => 'Cambiar marca de tiempo';

  @override
  String get labelEtcPickTime => 'Elegir hora';

  @override
  String get labelEtcPickDateTooltip => 'Elegir fecha y hora';

  @override
  String get labelEtcTimestampNote => '(Ej: 2002/03/30 17:30)';

  @override
  String get labelEtcAttributeChange => 'Cambiar atributos';

  @override
  String get labelEtcCautionTitle => 'No se puede deshacer';

  @override
  String get labelEtcCautionMessage =>
      'Los cambios en esta categoría (marca de tiempo/atributos) no se pueden deshacer con la función Deshacer. Por favor, opere con precaución.';

  @override
  String get labelUndo => 'Deshacer';

  @override
  String get labelExecute => 'Ir';

  @override
  String get labelErrorInvalidFilename =>
      'Error: Caracteres prohibidos en el nombre de archivo';

  @override
  String get labelCopyName => 'Copiar nombre';

  @override
  String get labelCopyPath => 'Copiar ruta';

  @override
  String get labelCopyFullPath => 'Copiar lista de rutas completas';

  @override
  String get labelCopyOptions => 'Copiar lista actual';

  @override
  String get labelCopyUndo => 'Copiar lista de nombres renombrados';

  @override
  String get labelCopyListClipboard => 'Copiar lista de nombres actuales';

  @override
  String get labelMoveUp => 'Subir';

  @override
  String get labelMoveDown => 'Bajar';

  @override
  String get labelRefresh => 'Refrescar todo';

  @override
  String get labelMenuMore => 'Más operaciones';

  @override
  String get labelMenuSettings => 'Ajustes';

  @override
  String get labelMenuFolder => 'Menú de carpetas';

  @override
  String get labelNumStringNumber => 'Cadena + Número';

  @override
  String get labelNumOriginalNumber => 'Original + Número';

  @override
  String get labelNumNumberString => 'Número + Cadena';

  @override
  String get labelNumNumberOriginal => 'Número + Original';

  @override
  String get labelNumBaseStringNumber => 'Base + Cadena + Número';

  @override
  String get labelNumBaseStringOriginal => 'Base + Cadena + Original';

  @override
  String get labelNumRelativeStringNumber => 'Relativo + Cadena + Número';

  @override
  String get labelNumRelativeStringOriginal => 'Relativo + Cadena + Original';

  @override
  String get labelNumNumberStringBase => 'Número + Cadena + Base';

  @override
  String get labelNumNumberStringRelative => 'Número + Cadena + Relativo';

  @override
  String get labelReplaceFrom => 'Buscar';

  @override
  String get labelReplaceTo => 'Reemplazar con';

  @override
  String get labelFullPath => 'Actual > ';

  @override
  String get labelSelectAll => 'Seleccionar todo';

  @override
  String get labelDeselectAll => 'Deseleccionar';

  @override
  String get labelSettingsFilterTitle => 'Filtro de vista';

  @override
  String get labelFilterAll => 'Todos los archivos';

  @override
  String get labelFilterSpecific => 'Específico';

  @override
  String get labelFilterHideSystem => 'Ocultar archivos del sistema';

  @override
  String get labelFilterRecursive => 'Búsqueda recursiva';

  @override
  String get labelBetaListRenameHint => 'Visible porque Beta está habilitado';

  @override
  String get labelCtxUpOneFolder => 'Subir';

  @override
  String get labelCtxRenameGeneral => 'Renombrar (estándar)';

  @override
  String get labelCtxBatchRename => 'Renombrado por lotes (Namery)';

  @override
  String get labelCtxOpenWithAssoc => 'Abrir con asoc';

  @override
  String get labelCtxMoveToTop => 'Mover al principio';

  @override
  String get labelCtxMoveToBottom => 'Mover al final';

  @override
  String get labelCtxDeleteItems => 'Eliminar elementos (Supr)';

  @override
  String get labelCtxMoveCaret => 'Mover cursor';

  @override
  String get labelCtxCaretSettings => 'Configuración del cursor';

  @override
  String get labelCtxRefresh => 'Refrescar (F5)';

  @override
  String get labelCtxProperties => 'Propiedades(R)';

  @override
  String get labelFilterPreview => 'Mostrar vista previa';

  @override
  String get labelExtensionLower => 'Ext a minúsculas';

  @override
  String get labelNavBack => 'Atrás';

  @override
  String get labelNavForward => 'Adelante';

  @override
  String get labelNavUp => 'Subir';

  @override
  String get labelNavHistory => 'Historial';

  @override
  String get labelNoHistory => 'Sin historial';

  @override
  String get labelScanStop => 'Detener escaneo';

  @override
  String get labelHistoryBack => 'Atrás (Historial)';

  @override
  String get labelHistoryForward => 'Adelante (Historial)';

  @override
  String get labelNavQuickAccess => 'Acceso rápido';

  @override
  String get labelDeleteFront => 'desde el frente';

  @override
  String get labelDeleteBack => 'desde atrás';

  @override
  String get labelDeleteUntil => 'Eliminar hasta';

  @override
  String get labelFindHint => 'Buscar';

  @override
  String get labelReplaceHint => 'Reemplazar';

  @override
  String get labelRegex => 'Regex';

  @override
  String get labelString => 'Cadena';

  @override
  String get labelStartDigit => 'Inicio/Dígito';

  @override
  String get labelStart => 'Inicio';

  @override
  String get labelDigit => 'Dígito';

  @override
  String get labelSettingsTitle => 'Ajustes';

  @override
  String get labelSettingsSectionDisplay => 'Pantalla';

  @override
  String get labelSettingsSectionAppearance => 'Apariencia';

  @override
  String get labelSettingsSectionOS => 'Modo de funcionamiento (SO)';

  @override
  String get labelSettingsSectionInitialDir => 'Carpeta inicial';

  @override
  String get labelSettingsSectionReset => 'Restablecer';

  @override
  String get labelSettingsTouchModeTitle => 'Modo táctil';

  @override
  String get labelSettingsTouchModeSubtitle =>
      'Aumentar el espacio para listas y botones';

  @override
  String get labelSettingsMenuLabelTitle => 'Idioma / Etiquetas';

  @override
  String get labelSettingsLangJP => 'Japonés';

  @override
  String get labelSettingsLangNamery => 'Namery';

  @override
  String get labelSettingsLangEN => 'Inglés';

  @override
  String get labelSettingsLangCN => 'Chino';

  @override
  String get labelSettingsLangES => 'Español';

  @override
  String get labelSettingsThemeTitle => 'Modo de tema';

  @override
  String get labelSettingsThemeSystem => 'Sistema';

  @override
  String get labelSettingsThemeLight => 'Luz';

  @override
  String get labelSettingsThemeDark => 'Oscuro';

  @override
  String get labelSettingsThemeGray => 'Gris';

  @override
  String get labelSettingsColorTitle => 'Color del tema';

  @override
  String get labelSettingsOSTitle => 'Modo SO';

  @override
  String get labelSettingsOSSubtitle =>
      'Ajustar los límites del nombre de archivo para que coincidan con el SO';

  @override
  String get labelSettingsOSAuto => 'Auto';

  @override
  String get labelSettingsInitDirTitle => 'Ubicación de inicio';

  @override
  String get labelSettingsInitDirLast => 'Última ubicación utilizada';

  @override
  String get labelSettingsInitDirFixed => 'Ubicación fija';

  @override
  String get labelSettingsClearHistory => 'Borrar historial de entrada';

  @override
  String get labelSettingsClearHistorySub =>
      'Borrar el historial de completado de cadenas';

  @override
  String get labelSettingsResetAll => 'Restablecer todos los ajustes';

  @override
  String get labelSettingsResetAllSub => 'Volver al estado predeterminado';

  @override
  String get labelSettingsBetaTitle => 'Habilitar funciones Beta';

  @override
  String get labelSettingsBetaSubtitle =>
      'Mostrar funciones experimentales (por ejemplo, renombrar lista)';

  @override
  String get labelDialogCancel => 'Cancelar';

  @override
  String get labelDialogDelete => 'Eliminar';

  @override
  String get labelDialogReset => 'Restablecer';

  @override
  String get labelMsgHistoryCleared => 'Historial borrado';

  @override
  String get labelMsgSettingsReset => 'Ajustes restablecidos';

  @override
  String get labelFilterHideFolders => 'Ocultar carpetas';

  @override
  String get labelFilterShowFolders => 'Mostrar carpetas';

  @override
  String get labelPreviewNoSelection => 'Ningún archivo seleccionado';

  @override
  String labelPreviewSelectedCount(int count) {
    return '$count archivos seleccionados';
  }

  @override
  String get labelPreviewImageLoadFailed => 'Error al cargar la imagen';

  @override
  String get labelPreviewUnavailable => 'Vista previa no disponible';

  @override
  String labelPreviewOmitted(String size) {
    return '... (Omitido: $size KB en total)';
  }

  @override
  String get labelPreviewBinaryError =>
      'Vista previa no disponible: binario o codificación desconocida';

  @override
  String get labelGoRenamery => 'Renombrar todo';

  @override
  String get labelTermFolder => 'Carpeta';

  @override
  String get labelTermFile => 'Archivo';

  @override
  String get labelTypeImage => 'Imagen';

  @override
  String get labelTypePDF => 'PDF';

  @override
  String get labelTypeVideo => 'Vídeo';

  @override
  String get labelTypeAudio => 'Audio';

  @override
  String get labelTypeDocument => 'Documento';

  @override
  String get labelTypeExecutable => 'App';

  @override
  String get labelTypeArchive => 'Archivo';

  @override
  String get labelTypeOther => 'Otro';

  @override
  String get labelSettingsOSMac => 'Mac (compatible con Finder)';

  @override
  String get labelSettingsOSLinux => 'Linux';

  @override
  String get labelSettingsOSiOS => 'iOS (iPhone/iPad)';

  @override
  String get labelSettingsOSAndroid => 'Android';

  @override
  String labelMsgExecutedCount(int count) {
    return 'Cambiado el nombre de $count archivos';
  }

  @override
  String get labelMsgNoSelection => 'No hay archivos seleccionados';

  @override
  String get labelCopyListPath => 'Copiar lista al portapapeles (ruta)';

  @override
  String get labelMenuGo => 'Ir';

  @override
  String get labelNoFiles => 'Sin archivos';

  @override
  String labelSelectFolderPrompt(Object term) {
    return 'Por favor seleccione un $term';
  }

  @override
  String get labelNavTitle => 'Navegación';

  @override
  String get labelNavPC => 'PC';

  @override
  String get labelNumSaveSequenceTooltip =>
      'Guardar el número de secuencia después del cambio (continuar la próxima vez)';

  @override
  String labelStatusDisplayCount(int current, int total, int selected) {
    return 'Pantalla: $current / Total $total archivos : Seleccionado $selected';
  }

  @override
  String labelStatusTotalCount(int total, int selected) {
    return 'Total $total archivos : Seleccionado $selected';
  }

  @override
  String get labelStatusProcessing => 'Procesando...';

  @override
  String get labelStatusReady => 'Listo';

  @override
  String get labelDeleteConfirmTitle => 'Confirmar eliminación';

  @override
  String labelDeleteConfirmMessage(int count) {
    return '¿Eliminar $count archivos permanentemente?\nEsto no se puede deshacer.';
  }

  @override
  String labelMsgDeletedCount(int count) {
    return 'Eliminado $count archivos';
  }

  @override
  String get labelUndoTitle => 'Restaurar / Deshacer';

  @override
  String labelUndoConfirm(int count) {
    return '¿Revertir $count cambios de la última operación?';
  }

  @override
  String get labelMsgUndoSuccess => 'Restaurado con éxito';

  @override
  String get labelUndoRecoverBtn => 'Restaurar';

  @override
  String get labelMsgNoUndoRecord => 'No hay historial de deshacer disponible';

  @override
  String get labelMsgUndoRecordCopied =>
      'Registro de cambios copiado al portapapeles';

  @override
  String labelMsgCopyNamesSuccess(int count) {
    return 'Copiado $count nombres de archivo';
  }

  @override
  String labelMsgCopyFilesSuccess(int count) {
    return 'Copiado $count archivos';
  }

  @override
  String labelMsgCutFilesSuccess(int count) {
    return 'Cortado $count archivos';
  }

  @override
  String labelMsgCopyRelativePathsSuccess(int count) {
    return 'Copiado $count rutas relativas';
  }

  @override
  String labelMsgCopyFullPathsSuccess(int count) {
    return 'Copiado $count rutas completas';
  }

  @override
  String get labelSettingsAboutTitle => 'Acerca de';

  @override
  String get labelAboutVersion => 'Versión';

  @override
  String get labelAboutOriginal => 'Idea original';

  @override
  String get labelAboutDev => 'Planificación/Desarrollo';

  @override
  String get labelAboutCopyright => '© 2024 Toyo Craft Lab.';

  @override
  String get labelAboutRespect =>
      'Esta aplicación fue creada con respeto por \'Namery\' del Sr. Jun Arai.';

  @override
  String get labelAboutVisitWebsite => 'Visitar sitio web';

  @override
  String get labelHistoryTooltip => 'Mostrar historial';

  @override
  String get labelSettingsFolders => 'Mostrar carpetas';

  @override
  String get labelSettingsShowSystemFiles => 'Mostrar archivos del sistema';

  @override
  String get labelSettingsSystemFiles => 'Archivos del sistema';

  @override
  String get labelSettingsDisableRecursive => 'Desactivar recursivo';

  @override
  String get labelSettingsRecursive => 'Búsqueda recursiva';

  @override
  String get labelDialogTrashTitle => 'Eliminar elementos';

  @override
  String get labelDialogTrashMessage =>
      '¿Mover los archivos seleccionados a la papelera de reciclaje?';

  @override
  String get labelCtxPasteItems => 'Pegar elementos';

  @override
  String get labelCtxCopyItems => 'Copiar';

  @override
  String get labelCtxCutItems => 'Cortar';

  @override
  String get labelCtxCreateFolder => 'Crear nueva carpeta';

  @override
  String get labelFilterOptions => 'Configuración de búsqueda y pantalla';

  @override
  String get labelMenuRenameSettings => 'Configuración de cambio de nombre';

  @override
  String get labelDialogClose => 'Cerrar';

  @override
  String get labelSearchHint => 'Buscar por nombre de archivo...';

  @override
  String get labelRegexSearchHint => 'Buscar con Regex...';

  @override
  String get labelPermissionFileAccessTitle =>
      'Configuración de permisos de acceso a archivos';

  @override
  String get labelPermissionFileAccessMessage =>
      'Para renombrar archivos con esta aplicación, debe permitir el \"Acceso a todos los archivos\" en la configuración del sistema Android.\n\nBusque \"ReNamery\" en la siguiente pantalla y active el interruptor.';

  @override
  String get labelPermissionFileAccessButton => 'Ir a Ajustes';

  @override
  String get labelLicenseAgreementTitle => 'Acuerdo de licencia de software';

  @override
  String get labelLicenseAgreementMessage =>
      'Para usar este software, debe aceptar los siguientes términos de licencia.';

  @override
  String get labelLicenseDeclineExit => 'No aceptar y salir de la app';

  @override
  String get labelLicenseAcceptStart => 'Aceptar y empezar a usar';

  @override
  String get labelAppTitle =>
      'ReNamery - Cambio seguro de nombres por lotes | Toyo Craft';

  @override
  String labelUpdateAvailable(String version) {
    return 'Hay una nueva versión (v$version) disponible';
  }

  @override
  String get labelViewSettings => 'Ver ajustes';

  @override
  String get labelAppExitTitle => 'Salir de la app';

  @override
  String get labelAppExitConfirm => '¿Salir de ReNamery?';

  @override
  String get labelExit => 'Salir';

  @override
  String get labelSkipInvalidTitle => '¿Omitir archivos con errores?';

  @override
  String labelSkipInvalidMessage(int invalidCount, int validCount) {
    return '$invalidCount archivos seleccionados tienen nombres no válidos, como caracteres prohibidos o duplicados.\n\n¿Excluirlos y renombrar solo los $validCount archivos válidos?';
  }

  @override
  String get labelSkipAndContinue => 'Omitir y continuar';

  @override
  String labelMsgExecutedWithSkipped(int executedCount, int invalidCount) {
    return '$executedCount correctos, $invalidCount omitidos por errores';
  }

  @override
  String get labelMsgNoExecutableFiles =>
      'No hay archivos que se puedan procesar';

  @override
  String get labelWebSelectFolderPromptTitle =>
      'Seleccione una carpeta local para empezar';

  @override
  String get labelWebSelectFolderPromptMessage =>
      'En navegadores basados en Chromium puede renombrar por lotes los archivos de la carpeta seleccionada.';

  @override
  String get labelWebSelectFolderPromptPrivacy =>
      'Los datos seleccionados no se suben fuera del navegador.';

  @override
  String get labelWebSelectFolderPromptDesktopBeforeLink =>
      'Para una experiencia más fluida, recomendamos la ';

  @override
  String get labelDesktopAppVersionLink => 'versión de escritorio';

  @override
  String get labelWebSelectFolderPromptDesktopAfterLink => '.';

  @override
  String get labelWebUnsupportedPromptTitle =>
      'Este navegador no es compatible';

  @override
  String get labelWebUnsupportedPromptMessage =>
      'Pruebe un navegador compatible como Chrome o Edge.';

  @override
  String get labelSelectFolder => 'Seleccionar carpeta';

  @override
  String get labelLicenseCannotExitTitle => 'No se puede salir de la app';

  @override
  String get labelLicenseCannotExitMessage =>
      'El navegador no permite que la app cierre esta pestaña. Si no desea usar la app, cierre esta pestaña manualmente.';

  @override
  String get labelDropOneFolder => 'Suelte exactamente una carpeta.';

  @override
  String get labelDropFolderNotFile => 'Suelte una carpeta, no un archivo.';

  @override
  String get labelDropUnsupported =>
      'Arrastrar y soltar carpetas no es compatible en este entorno.';

  @override
  String get labelDropOpenFailed => 'No se pudo abrir la carpeta.';

  @override
  String get labelDropHereToOpen => 'Suelte una carpeta aquí para abrirla';

  @override
  String get labelFileNotFound => 'El archivo no existe';

  @override
  String get labelWindowsPropertiesFailed =>
      'No se pudo abrir Propiedades de Windows';

  @override
  String labelPropertiesTitle(String name) {
    return 'Propiedades: $name';
  }

  @override
  String get labelPropertyKind => 'Tipo';

  @override
  String get labelPropertyFileFolder => 'Carpeta de archivos';

  @override
  String get labelPropertyFile => 'Archivo';

  @override
  String get labelPropertyLocation => 'Ubicación';

  @override
  String get labelPropertySize => 'Tamaño';

  @override
  String get labelPropertyModified => 'Fecha de modificación';

  @override
  String get labelPropertyAttributes => 'Atributos';

  @override
  String get labelWebUnsupportedBrowserMessage =>
      'Este navegador no puede usar las funciones necesarias para integrar carpetas locales. Pruebe con un navegador de PC compatible, como Chrome o Edge.';

  @override
  String get labelWebLocalFolderPickerTitle => 'Seleccionar carpeta local';

  @override
  String get labelWebLocalFolderPickerSubtitle =>
      'Disponible en navegadores compatibles como Chrome / Edge';

  @override
  String get labelWebNoSavedDirectories =>
      'Aún no se han seleccionado carpetas.';

  @override
  String get labelWebDirectoryPermissionDenied =>
      'No se concedió acceso a la carpeta.';

  @override
  String get labelWebAccessUnavailable =>
      'No se pudo leer una carpeta o archivo. Algunos elementos pueden no estar disponibles porque se movieron, eliminaron o se están sincronizando.';

  @override
  String get labelWebNameRequired => 'Introduzca un nombre de archivo.';

  @override
  String get labelWebInvalidFileNameChars =>
      'El nombre de archivo contiene caracteres prohibidos: / \\ : * ? \" < > |';

  @override
  String get labelWebDuplicateItem =>
      'Ya existe un elemento con el mismo nombre.';

  @override
  String get labelWebDuplicateFile =>
      'Ya existe un archivo con el mismo nombre.';

  @override
  String get labelWebItemAccessLost =>
      'Se perdió la información de acceso de este elemento. Seleccione la carpeta de nuevo.';

  @override
  String get labelWebFileAccessLost =>
      'Se perdió la información de acceso de este archivo. Seleccione la carpeta de nuevo.';

  @override
  String get labelForgetQuickAccessTitle => '¿Quitar de Acceso rápido?';

  @override
  String labelForgetQuickAccessMessage(String name) {
    return 'Quitar \"$name\" del Acceso rápido de ReNamery.\n\nLa carpeta y los archivos no se eliminarán.\nPara usarla de nuevo, agréguela desde \"Seleccionar carpeta local\".';
  }

  @override
  String get labelForget => 'Quitar';

  @override
  String get labelForgetQuickAccessAction => 'Quitar de Acceso rápido';

  @override
  String get labelForgetQuickAccessSuccess =>
      'Quitado de Acceso rápido. Los archivos no se eliminaron.';

  @override
  String get labelForgetQuickAccessFailure =>
      'No se pudo quitar de Acceso rápido.';

  @override
  String get labelArchiveContents => 'Contenido del archivo:';

  @override
  String labelPreviewError(String message) {
    return 'Error: $message';
  }

  @override
  String labelPreviewUnsupportedWeb(String target) {
    return 'La vista previa de contenido de $target no es compatible en la versión web.\nPuede consultar el nombre, tipo, tamaño y otra información en la lista.';
  }

  @override
  String get labelPreviewTargetThisFile => 'este archivo';

  @override
  String labelPreviewTargetExtensionFile(String extension) {
    return 'archivo $extension';
  }

  @override
  String get labelScanConfirmTitle => 'Confirmar escaneo';

  @override
  String labelScanConfirmCount(int count) {
    return 'Se encontraron $count archivos.\n¿Continuar escaneando?';
  }

  @override
  String labelScanConfirmTime(int count) {
    return 'Han pasado 5 segundos desde que comenzó el escaneo ($count archivos hasta ahora).\n¿Continuar?';
  }

  @override
  String get labelScanConfirmStall =>
      'La respuesta se ha detenido temporalmente. ¿Continuar escaneando?';

  @override
  String get labelScanCancelClear => 'Cancelar y borrar';

  @override
  String get labelScanStopAndShow => 'Detener aquí y mostrar';

  @override
  String get labelScanContinue => 'Continuar';
}
