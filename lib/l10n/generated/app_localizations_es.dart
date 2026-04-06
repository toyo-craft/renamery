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
  String get labelNavHistory => '履歴';

  @override
  String get labelNoHistory => '履歴がありません';

  @override
  String get labelScanStop => 'スキャン停止';

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
}
