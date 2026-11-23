# ❓ Preguntas frecuentes

## 🎮 Generalidades y concepto

### 1. ¿Por qué utilizar MPV para jugar en cualquier consola compatible con HDMI?

MPV es un reproductor de vídeo muy potente y rápido cuando se configura correctamente. Además, te permite añadir shaders, marcos, recortes y muchas otras opciones, lo que lo convierte en algo más que «simplemente reproducir» y lo transforma en una herramienta que puedes personalizar a tu gusto para jugar con consolas.

### 2. ¿Por qué MPV y no otro programa?

Existen otros programas que permiten capturar vídeo y hacer algo similar a este proyecto, pero suelen ser más limitados y no ofrecen el mismo nivel de personalización que MPV-SW-Capture aporta a MPV. Además, la mayoría tiende a aumentar el retraso, lo que hace que la experiencia sea insoportable.

> 💡 **Nota:** MPV-SW-Capture incluye su propio complemento de audio nativo (WASAPI), lo que significa que el audio se captura en tiempo real y puede utilizarse en OBS, Discord y otras herramientas sin necesidad de ningún complemento externo.

---

## 🧩 Hardware y tarjetas de captura

### 1. ¿Por qué necesito una tarjeta de captura compatible con 1080p60?

Porque 1080p60 es el estándar de calidad actual para la mayoría de las consolas y dispositivos de captura modernos. Optar por 1080p60 garantiza una buena calidad de imagen y una experiencia de juego fluida.

### 2. ¿Por qué se recomienda el USB 3.0? ¿Qué ocurre si utilizo el USB 2.0?

Se recomienda el USB 3.0 porque ofrece un mayor ancho de banda, lo que se traduce en una mejor calidad de imagen y un rendimiento más estable para vídeos de alta resolución y alta frecuencia de fotogramas. Aún así, puedes utilizar el USB 2.0, pero la calidad y la estabilidad pueden verse afectadas. Si no tienes otra opción, puedes utilizarlo de todos modos, pero ten en cuenta esta limitación.

### 3. ¿Puedo utilizar cualquier tarjeta de captura USB-HDMI?

En teoría, sí. Sin embargo, para este proyecto se recomienda una tarjeta de captura que admita 1080p60 y cuente con salida en bucle (entrada HDMI + salida HDMI). Hay opciones relativamente económicas y fáciles de encontrar. Un ejemplo que puedes buscar es: «Captura de vídeo HD 4K Ultra HD USB 3.0 (MS 2131)». Estos dispositivos admiten entradas de hasta 4K60 y emiten a 1080p60. Por ejemplo, si conectas una consola que admite 4K a 60, la tarjeta de captura lo aceptará, pero la imagen final utilizada por MPV-SW-Capture será de 1080p a 60.

### 4. ¿Qué hay de las tarjetas de captura tipo memoria USB que solo tienen HDMI y USB, y que suelen admitir hasta 720p a 60?

En principio deberían funcionar, pero no se han probado con este proyecto. Si pruebas una y funciona (o no), por favor, comparte tus resultados en el proyecto para que otros puedan beneficiarse de esa información.

### 5. Si tengo una tarjeta de captura USB 3.0 que pueda emitir más de 1080p60 (como 1440p60 o 4K60), ¿funcionará?

Este caso tampoco se ha probado, pero, en principio, debería funcionar sin problemas importantes. Si lo pruebas, por favor, comparte tus resultados.

### 6. Tengo una consola que solo ofrece una resolución de hasta 720p en lugar de 1080p, ¿funcionará?

Sí, funcionará sin problemas. Por ejemplo, se probó con una salida de solo 720p y el resultado fue un escalado automático a 1080p. Con esto, todo funcionó correctamente, incluso los marcos, los recortes y los shaders.

Además, se ha probado con consolas más antiguas que admiten menos de 720p (480p), conectadas mediante un adaptador de AV a HDMI, y el resultado también es una mejora de resolución a 1080p.

---

## 🎮 Software

### 1. ¿Qué software necesitamos para utilizar el MPV-SW-Capture?

Se necesitan tres programas: `MPV` es el principal. También se necesitan `ffplay` y `ffmpeg` para que funcione.

Por eso hay que descargarlos e instalarlos, tal y como se explica en la Guía de instalación.

### 2. He seguido las instrucciones y he configurado correctamente mi `MPV-SW-Capture`. Pero me he dado cuenta de que los tres programas tienen ahora una versión más reciente que la que utilizaba antes. ¿Puedo actualizarlos sin que deje de funcionar MPV-SW-Capture?

Si te refieres a `MPV`, `ffplay` y `ffmpeg`, sí, puedes actualizar o sustituir los tres programas sin problema. Tienes que descargar sus nuevas versiones y sustituir las antiguas por las más recientes.

Eso es todo lo que tienes que hacer. Y siempre se recomienda tener la versión más reciente.

Pero si detectas algún problema, puedes probar con versiones anteriores. Si eso ocurre, por favor, comenta el problema en **[Issues](https://github.com/TyRaS-SW/MPV-SW-Capture/issues)**, para que podamos comprobarlo y solucionarlo.

Si te refieres al propio MPV-SW-Capture en sí, la recomendación es simplemente sustituir todos los archivos.

> 💡 **Nota:** Algunas preferencias de usuario (Audio Boost, modo de salida de audio, barra lateral de volumen al pasar el cursor y perfil ICC automático) se guardan automáticamente y se conservan tras las actualizaciones. No es necesario volver a configurarlas tras sustituir los archivos.

### 3. ¿Qué hace `1_INSTALLER_MSC_First-Usage.cmd`?

`1_INSTALLER_MSC_First-Usage.cmd` es el punto de entrada para la **primera instalación** de MPV-SW-Capture. Al ejecutarlo:

1. Abre una ventana de consola con instrucciones.
2. Descarga e instala todos los componentes necesarios, incluidos `mpv.exe`, `ffplay.exe` y `ffmpeg.exe`.
3. Inicia automáticamente la herramienta de configuración al cerrarse el instalador, para que puedas configurar la aplicación.

Solo tienes que ejecutar este archivo CMD **una vez**. A partir de entonces, todas las actualizaciones futuras utilizarán `MPV-SW-Capture_INSTALLER.vbs`.

### 4. ¿Qué hace `MPV-SW-Capture_INSTALLER.vbs`?

`MPV-SW-Capture_INSTALLER.vbs` es el programa de inicio para **futuras actualizaciones**. Una vez finalizada la instalación inicial, utiliza este archivo `.vbs` para:

- Actualizar MPV-SW-Capture a una versión más reciente.
- Actualizar `ffplay` y `ffmpeg` a sus últimas versiones.
- Volver a descargar los componentes que falten (por ejemplo, si has borrado accidentalmente `ffplay.exe` o `ffmpeg.exe`).
- Realizar una **instalación limpia**; consulta [Preguntas frecuentes sobre el software n.º 8](#8-what-is-the-clean-install-option-in-the-installer) para obtener más detalles.

> ⚠️ **Limitación importante**: Este archivo `.vbs` **requiere que `mpv.exe` esté presente** para poder ejecutarse; utiliza `mpv.exe` para iniciar el script de instalación interno. Si se elimina el propio `mpv.exe`, el archivo `.vbs` no realizará ninguna acción visible.
>
> Por ese motivo, **mantén `1_INSTALLER_MSC_First-Usage.cmd` en la misma carpeta** como herramienta de recuperación. Si alguna vez pierdes `mpv.exe`, ese archivo CMD es la única forma de reinstalarlo sin tener que volver a descargar todo el ZIP.

### 5. He eliminado accidentalmente uno de los ejecutables necesarios. ¿Tengo que reinstalarlo todo?

Depende de **qué** archivo se haya eliminado:

- **Si has eliminado `ffplay.exe` o `ffmpeg.exe`** (pero `mpv.exe` sigue ahí):
  Ejecuta `MPV-SW-Capture_INSTALLER.vbs` y utiliza la función **Check**. Detectará el archivo que falta y te permitirá volver a descargar solo ese componente.

- **Si has borrado `mpv.exe`**:
  El archivo `.vbs` no funcionará, ya que depende de `mpv.exe` para ejecutarse. En este caso, **ejecuta de nuevo `1_INSTALLER_MSC_First-Usage.cmd` de nuevo**; detectará que falta `mpv.exe` y lo volverá a descargar. Por eso recomendamos mantener el archivo CMD en la carpeta incluso después de la primera instalación.

### 6. Estaba utilizando el instalador y ahora no puedo actualizar. ¿Por qué ha ocurrido esto?

Esto se debe a una limitación de GitHub. Si realizas muchas operaciones, GitHub limita las descargas hasta que haya transcurrido una hora. Solo puedes tener este problema si descargas, actualizas, etc., en una cantidad excesiva.

Dado que solo estás actualizando o instalando, esto no debería suponer ningún problema. Pero si te encuentras con este problema, espera una hora o realiza una instalación manual.

Como solución alternativa, puedes realizar una instalación manual mientras esperas, o simplemente esperar una hora e intentarlo de nuevo. Puedes consultar cómo hacerlo en la **[Guía de instalación](https://tyras-sw.github.io/MPV-SW-Capture/)**. Este límite lo impone GitHub para evitar abusos.

### 7. ¿Cómo funcionan los números de actualización en MPV-SW-Capture?

Cuando ves una actualización, aparecen tres números separados por puntos. Aquí se representan como `X`, `Y`, `Z`:

v`X`.`Y`.`Z`.

- `X` = Actualización muy importante que debe aplicarse.
- `Y` = Actualización importante.
- `Z` = Parche menor o pequeña novedad añadida.

### 8. ¿Qué es la opción «Instalación limpia» del instalador?

La opción «Instalación limpia» realiza una configuración completamente nueva. Cuando se activa, el instalador:

1. Primero descarga la nueva versión a una carpeta temporal (aún no se toca nada en tu directorio raíz).
2. Mueve todos los archivos antiguos a una carpeta llamada `OLDMSC` (creada en la misma carpeta).
3. Instala la nueva versión en un directorio raíz limpio.
4. Restaura automáticamente tus configuraciones de Extra Tools.

**Qué se conserva durante una instalación limpia:**

- `mpv.exe`, `ffplay.exe`, `ffmpeg.exe`: los binarios principales.
- `_record\` y `_screenshots\`: tus grabaciones y capturas de pantalla.
- `tools\*.json`: tu configuración de Extra Tools.

**Qué se traslada a `OLDMSC`:** todo lo demás: configuraciones antiguas, shaders, marcos y archivos no utilizados. Puedes recuperar cualquier cosa de allí manualmente antes de que la próxima instalación limpia lo sobrescriba.

La casilla está **marcada por defecto** y solo aparece habilitada cuando se detecta una instalación previa de MPV-SW-Capture. Si solo quieres una actualización normal, desmarca la casilla antes de hacer clic en **Instalar / Actualizar**.

> 💡 **Consejo:** Tras una instalación limpia, el instalador te pide que cierres y vuelvas a abrir el programa. Esto es normal: garantiza que la nueva versión entre plenamente en funcionamiento.

---

## 🛠️ Instalación y lanzadores

### 1. He abierto `MPV-SW-Capture_INSTALLER.vbs` en una instalación nueva y no ha pasado nada. ¿Por qué?

En una instalación nueva, primero debes ejecutar **`1_INSTALLER_MSC_First-Usage.cmd`**. Este archivo descarga e instala todos los componentes necesarios, incluido `mpv.exe`. Una vez hecho esto, `MPV-SW-Capture_INSTALLER.vbs` funcionará con normalidad para futuras actualizaciones.

`MPV-SW-Capture_INSTALLER.vbs` requiere que `mpv.exe` esté presente. Si falta, el ejecutable no realiza ninguna acción visible; esto es así por diseño, pero puede resultar confuso. Comprueba siempre que `mpv.exe` exista en la carpeta antes de utilizar los ejecutables `.vbs`.

> 💡 **Conserva el archivo CMD tras la instalación.** Aunque solo ejecutes `1_INSTALLER_MSC_First-Usage.cmd` una vez, no lo elimines. Es la única forma de recuperar `mpv.exe` si alguna vez se borra; los ejecutables `.vbs`dependen de que `mpv.exe` esté presente, por lo que no pueden recuperarlo por sí mismos.

### 2. Windows muestra una «Advertencia de seguridad» cuando ejecuto el archivo `.cmd` o `.vbs`. ¿Es normal?

Sí. Windows marca los archivos descargados con la *Marca de la Web* y solicita confirmación antes de ejecutarlos, ya que no cuentan con una firma digital.

**Para continuar:**
- Haz clic en **Ejecutar**.

**Para evitar que te lo pregunte cada vez:**
- Antes de hacer clic en **Ejecutar**, desmarca **«Preguntar siempre antes de abrir este archivo»**. Windows recordará tu elección para ese archivo concreto.

Los archivos que activan esta advertencia son:

- `1_INSTALLER_MSC_First-Usage.cmd`
- `MPV-SW-Capture_SETUP.vbs`
- `MPV-SW-Capture_INSTALLER.vbs`

### 3. ¿Puedo ejecutar estas herramientas sin que aparezca la advertencia de seguridad?

Sí. Una vez que MPV-SW-Capture esté en ejecución, ve a la sección **HERRAMIENTAS** del menú. El menú abre el instalador, el programa de configuración y otras herramientas incluidas de forma interna, por lo que no aparecerá ningún cuadro de diálogo de seguridad.

### 4. ¿Cómo instalo las herramientas adicionales (Bezel Manager, Video Manager, Stream Helper)?

Están disponibles de dos formas:

- Descarga el archivo independiente `TOOLS_*.zip` desde la [página de versiones](https://github.com/TyRaS-SW/MPV-SW-Capture/releases) y extráelo.
- O marca la casilla **«¿Instalar herramientas adicionales con Instalar/Actualizar todo?»** en el instalador y haz clic en **«Instalar/Actualizar TODO»**. (Esta casilla es independiente de la de **«Instalación limpia»**; ambas se pueden activar al mismo tiempo).

### 5. He borrado por error `mpv.exe` / `ffplay.exe` / `ffmpeg.exe`. ¿Tengo que reinstalarlo todo?

Depende del archivo que falte:

| Archivo borrado | Método de recuperación |
|---|---|
| `ffplay.exe` o `ffmpeg.exe` | Ejecuta `MPV-SW-Capture_INSTALLER.vbs` → **Marca la casilla** → vuelve a descargar el componente que falta. |
| **`mpv.exe`** | Ejecuta `1_INSTALLER_MSC_First-Usage.cmd` de nuevo. Los ejecutables `.vbs` **no se pueden** utilizar en este caso porque dependen de `mpv.exe` para ejecutarse. |

> 💡 **¿Por qué conservar el archivo CMD?** Aunque solo lo necesitas para la primera instalación, es la única vía de recuperación si alguna vez se borra `mpv.exe`. Déjalo en la carpeta: casi no ocupa espacio (3 KB).

### 6. ¿Qué puedo configurar en la herramienta de configuración?

La herramienta de configuración te permite configurar las opciones básicas de MPV-SW-Capture. Incluye:

- **Selección del dispositivo de captura**: elige tu tarjeta de captura (vídeo y audio) a partir de un escaneo de **Buscar dispositivos**.
- **Idioma**: elige el idioma de la interfaz gráfica de usuario. Pulsa **Aplicar idioma** tras la selección.
- **INICIO AUTOMÁTICO CON LA SIGUIENTE SALIDA DE AUDIO**: elige entre **WASAPI** o **FFPLAY** como backend de audio predeterminado al iniciar el programa.
- **INICIO AUTOMÁTICO CON LA BARRA LATERAL DE VOLUMEN AL PASAR EL CURSOR**: elige si la barra lateral de volumen al pasar el cursor estará activa cuando se inicie MPV-SW-Capture.
- **Formato de vídeo de entrada**: elige `Auto`, `mjpeg`, `yuyv422`, `nv12`, `i420` o `h264` si la opción `Auto` provoca retrasos o problemas de compatibilidad.
- **Inicio automático con shaders especiales**: elige si deseas iniciar automáticamente un shader de **enfoque** o **antialiasing**, o déjalo en **NO**.
- **Parámetros de audio WASAPI**: ajusta con precisión la configuración de audio WASAPI de bajo nivel. Consulta la sección **🔊 Audio** para obtener más detalles.
- **Botón «Opciones predeterminadas»**: carga los valores predeterminados de fábrica en lugar de los que hayas configurado. Solo *marca* las opciones; estas no se aplican hasta que pulses **Aplicar configuración**.

> 💡 **Consejo:** La herramienta de configuración lee y conserva algunos de tus valores existentes, por lo que tu configuración anterior no se pierde cuando vuelves a ejecutarla.

---

## 🎨 Imágenes, shaders, marcos, recortes y formas

### 1. En «Configuración», hay una opción llamada «Inicio automático con shaders especiales». ¿Qué debo elegir?

La herramienta de configuración te permite elegir si deseas que se inicie automáticamente un shader al abrir MPV-SW-Capture. Hay tres opciones:

- **NO (predeterminado)**: no se inicia automáticamente ningún shader especial. Recomendado si prefieres elegir tus propios shaders para cada juego.
- **Sharpen**: inicia automáticamente un shader «Sharpen» de muy bajo consumo.
- **Anti-Aliasing**: inicia automáticamenteinicia un shader de antialiasing de bajo consumo.

Ambas opciones «SÍ» ofrecen una imagen nítida y limpia con un consumo **mínimo** de recursos. Si quieres una imagen más nítida, elige **Sharpen**. Si prefieres bordes más suaves, elige **Anti-Aliasing**.

### 2. He conectado una Switch y utilizo NSO, pero cuando aplico un marco o realizo un recorte en la imagen, se ve mal (mal recortada). ¿Cómo lo soluciono?

Esto suele deberse a la barra negra que NSO muestra en la parte inferior con los controles y el texto de ayuda. Tienes que desactivar esa superposición. Abre cualquier aplicación de NSO y antes de seleccionar un juego, ve al `menú de la derecha` → `Ajustes` → `Control de pantalla` → desactiva `Mostrar controles en el juego`. Una vez que esa barra haya desaparecido, el área de la imagen quedará más limpia (en algunos casos, más grande) y los recortes y marcos funcionarán correctamente. Hay que hacerlo en cada aplicación de NSO.

### 3. ¿Cómo desactivo un shader, un marco o un recorte?

- **Shader**: Utiliza la opción «Limpiar shader» o, simplemente, selecciona un shader diferente (este sustituye al anterior; no se superponen).
- **Marco**: Pulsa el mismo marco que habías seleccionado antes o utiliza la opción «Borrar marcos».
- **Recorte**: pulsa la misma opción de recorte que seleccionaste para desactivarla, o utiliza la opción «Borrar recorte».
- **Forma**: pulsa la misma opción de forma que seleccionaste para desactivarla, o utiliza la opción «Borrar forma».

Si quieres borrarlo todo de una vez (por ejemplo, marco, shader, forma), puedes utilizar la opción «Borrar TODO».

### 4. Quiero crear mis propios marcos, pero no sé cómo. ¿Cómo lo hago?

Los marcos son imágenes PNG de 1920x1080. Se utilizan principalmente con NSO para sustituir los bordes predeterminados por el diseño que desees. La zona central es donde va la imagen del juego; solo tienes que diseñar el marco de forma que el área de juego quede bien alineada y tenga buen aspecto. Para ver un tutorial más detallado sobre cómo crear marcos y añadirlos al menú, puedes ir aquí: **[Personalización avanzada → 8. Crea tu marco personalizado](https://tyras-sw.github.io/MPV-SW-Capture/#advanced)**.

### 5. ¿Puedo añadir mis propios shaders?

Sí, puedes. Los shaders deben ser compatibles con MPV y estar en formato `.glsl`.

Debes colocarlos en la carpeta `/shaders` y editar el archivo `menu.conf` para añadir tu shader, siguiendo el mismo formato que los demás.

### 6. ¿Qué son las FORMAS? ¿Por qué tienen un submenú específico aparte?

Las FORMAS son shaders que tienen la función específica de cambiar la forma de la pantalla.

Por ejemplo, puedes cambiar la pantalla a la forma de un televisor CRT, de modo que la pantalla tenga una curvatura.

¡Puedes crear cualquier combinación posible, sin límites!

Así pues, puedes combinar cualquier shader con cualquier forma en cualquier momento. Si quieres ver algunos ejemplos, entra aquí: **[MPV-SW-Capture en acción](https://tyras-sw.github.io/MPV-SW-Capture/)**.

### 7. ¿Para qué sirven las opciones «Ajustar 16:9 completo al marco» y «Ajustar 16:9 completo al recorte»?

Ambas opciones te ayudan a ajustar una imagen de 16:9 a un área que no sea de 16:9, pero se aplican a cosas diferentes:

- **↹ Ajustar 16:9 completo al marco** — en `MARCOS`. Ajusta perfectamente toda la ventana de contenido 16:9 dentro de un **marco de marco** elegido, para que puedas utilizar un marco sin recortar la imagen.
- **↹ Ajustar 16:9 completo al recorte** — en `RECORTES`. Ajusta una imagen de 16:9 al tamaño de cualquier **recorte**, de modo que la imagen se adapta al área de recorte en lugar de estirarse.

**Cómo utilizar «Ajustar 16:9 completo al marco»:**

1. Selecciona primero un marco (en la sección `MARCOS`).
2. A continuación, ve a `MARCOS → Ajustar 16:9 completo al marco`.

Si no tienes ningún marco seleccionado, aparecerá un mensaje pidiéndote que selecciones uno primero.

> 💡 **Nota:** Cuando está activa la opción **Ajustar 16:9 completo al recorte**, se omite el escalado por GPU en favor del escalador de la CPU. Esto es intencionado: un shader estiraría el fotograma comprimido.

### 8. ¿Qué es «RESOLUCIÓN DE ENTRADA» y cómo funciona?

«RESOLUCIÓN DE ENTRADA» está disponible en «OPCIONES DE VÍDEO → RESOLUCIÓN DE ENTRADA» en el menú. Te permite elegir la resolución a la que MPV-SW-Capture captura realmente la señal de entrada, y la escala hacia arriba o hacia abajo antes de que llegue a la pantalla.

**Por qué es útil:**
- Puedes establecer una resolución de captura más alta (por ejemplo, de 1080p a 1440p o 4K) y dejar que la CPU o la GPU se encarguen del escalado.
- Los resultados son similares o mejores que los del escalado basado en shaders, que consume muchos recursos, con un **consumo muy bajo** consumo adicional de recursos.
- Funciona correctamente con marcos y recortes.

**Opciones disponibles:** `480p`, `720p`, `FHD (1080p)`, `QWXGA (1152p)`, `QHD (1440p)`, `3K (1620p)`, `QHD+ (1800p)`, `4K (2160p)` y `Auto/Nativa`.

> ⚠️ **Importante:** Seleccionar una resolución superior a la nativa **aumenta el consumo de recursos**, aunque sea eficiente. Si experimentas problemas (pérdida de fotogramas, retrasos), reduce un poco la resolución de entrada.

### 9. ¿Cuál es la diferencia entre el escalado por CPU y por GPU en «Resolución de entrada»?

En «RESOLUCIÓN DE ENTRADA», hay un interruptor **⚡ Escalado por GPU**:

- **CPU (predeterminado)**: el escalado se realiza mediante el filtro `scale` de libavfilter (bicúbico, similar a libswscale). Es la opción más compatible y estable. El uso de la CPU aumenta con la resolución, pero se mantiene dentro de unos límites razonables.
- **GPU**: el escalado se realiza mediante un shader de GPU generado automáticamente (`msc_scale`). Es más eficiente en términos de CPU y RAM, ya que no se crea ningún fotograma ampliado en la RAM. Solo se utiliza cuando se realiza un escalado a una resolución **superior** a la de entrada nativa. Las reducciones (480p/720p) y la resolución nativa siempre se procesan a través de la CPU.

El estado se **guarda automáticamente**: si cambias a la GPU, MPV-SW-Capture recordará tu elección la próxima vez que lo inicies.

### 10. ¿Para qué sirven las opciones «Guardar resolución» y «Deshacer guardado de resolución»?

- **💾 Guardar resolución**: guarda la `RESOLUCIÓN DE ENTRADA` seleccionada actualmente para que MPV-SW-Capture se inicie con ella la próxima vez que se abra. Si no se guarda, la resolución se olvida al cerrar el programa.
- **🗑 Desguardar resolución** — elimina la resolución guardada y vuelve a la resolución nativa.

Solo necesitas guardar la resolución si quieres que se mantenga entre sesiones.

### 11. ¿Qué es el botón de cambio rápido de resolución?

Un botón situado en la cabecera del menú (junto a las demás acciones rápidas) que te permite alternar rápidamente entre las opciones de `RESOLUCIÓN DE ENTRADA`. El icono cambia para indicar el estado actual:

- ⏫ **Aumento de resolución**: la resolución elegida es superior a la nativa.
- ⏬ **Reducción de resolución**: la resolución elegida es inferior a la nativa.
- Sin flecha: estás en la resolución nativa.

**Ejemplo:** una entrada nativa de 1080p escalada a QHD muestra «QHD (1440p) ⏫».

### 12. ¿Qué son los shaders SHARPEN y Anti-Aliasing?

En «SHADERS» hay dos categorías dedicadas a la mejora de la imagen:

**Sharpen** — 5 opciones, cada una con un algoritmo de nitidez diferente:
- 👑 **Sharpen Lite MSC** — opción predeterminada ligera, con buen equilibrio.
- **Adaptive Luma** — aumenta la nitidez en función del brillo para evitar halos.
- **NVSharpen RT** — nitidez al estilo de Nvidia.
- **FidelityFX CAS** — nitidez adaptativa al contraste de AMD.
- **AMD FSR1 RCAS RT**: pasada de nitidez de FidelityFX Super Resolution 1 de AMD.

**Antialiasing**: 3 opciones para suavizar los bordes:
- 👑 **AA Lite MSC**: configuración predeterminada equilibrada.
- **AA Lite MSC Extreme**: suavizado de bordes más intenso.
- **AA Lite MSC Soft**: suavizado sutil.

Todas ellas consumen **muy pocos** recursos.

### 13. ¿Qué es Retro Pixel / NSO 5xBRZ?

**Retro Pixel** es una categoría de shaders dentro de `SHADERS` con una subcategoría llamada **NSO 5xBRZ**. Se trata de filtros exclusivos para sistemas NSO (NES, SNES/Genesis, Game Boy/GBC y GBA). Suavizan y redondean los píxeles para conseguir un aspecto «HD» en el contenido retro.

Actualmente, los filtros están **limitados a los sistemas NSO**, pero funcionan correctamente junto con las opciones de recorte y marco.

### 14. ¿Qué es «Convertir SDR a HDR»?

**«Convertir SDR a HDR»** es una opción que se encuentra en `OPCIONES DE VÍDEO → VÍDEO`. Aporta un aspecto similar al HDR al contenido SDR, lo cual resulta útil para tarjetas de captura que solo admiten SDR cuando la consola o el monitor son compatibles con HDR.

La opción se **guarda automáticamente**, por lo que se activará de forma automática la próxima vez que abras MPV-SW-Capture.

**Advertencias importantes:**

- Mientras «Convertir SDR a HDR» esté activo, **no se podrá utilizar AutoICC** hasta que lo desactives.
- Si tu tarjeta de captura, tu monitor y tu consola **son compatibles con HDR auténtico** y el HDR ya está activado, **no utilices esta opción**. Se trata estrictamente de una solución alternativa para señales SDR. Activarla en una señal HDR nativa producirá colores desvaídos e incorrectos.

### 15. ¿Qué es Full RGB (0-255)?

**Full RGB** es una opción en `OPCIONES DE VÍDEO → VÍDEO` que fuerza el espacio de color Full RGB (0–255, en contraposición al rango limitado de emisión de 16–235).

Actívala solo si tu **consola es compatible con Full RGB**. De lo contrario, los negros y los blancos se recortarán. Si tu consola está configurada en RGB limitado, deja esta opción desactivada.

---

## 🔊 Backends de audio (WASAPI frente a FFplay)

### 1. ¿Cuál es la diferencia entre el complemento de audio WASAPI y FFplay de baja latencia?

Ambos backends capturan el audio desde tu tarjeta de captura, pero lo hacen de forma diferente:

**Plugin de audio WASAPI (predeterminado):**
- Un plugin nativo cargado directamente en MPV.
- Gestiona tanto el vídeo como el audio en el mismo proceso.
- Menor consumo de CPU y RAM.
- Capturable de forma nativa por OBS, Discord y herramientas similares **sin plugins de terceros**.
- Disponible en Windows 10 y 11 con la mayoría de las tarjetas de captura modernas.

**FFplay de baja latencia (alternativa):**
- El clásico enfoque de procesos separados: MPV gestiona el vídeo y `ffplay` gestiona el audio.
- Ambos se ejecutan en segundo plano y permanecen sincronizados.
- Requiere el complemento `win-capture-audio` para que OBS capture su audio.
- Utiliza esta opción si tu sistema no es compatible con el complemento WASAPI o si prefieres el proceso anterior.

### 2. ¿Cuál debería utilizar?

**Utiliza el complemento de audio WASAPI (predeterminado)** a menos que tengas una razón específica para no hacerlo. Es más rápido, más ligero y funciona de forma inmediata con OBS y Discord.

**Cambia a FFplay de baja latencia** solo si:
- Tu sistema no sea compatible con el complemento WASAPI.
- Tengas problemas de audio con WASAPI que no puedas resolver.
- Ya tengas una configuración que funcione con FFplay y no quieras cambiarla.

### 3. ¿Cómo cambio de uno a otro?

- **Desde el menú**: ve a **AUDIO → MODO DE SALIDA DE AUDIO** y selecciona el backend que desees.
- **Desde la herramienta de configuración**: utiliza la opción **INICIAR AUTOMÁTICAMENTE CON LA SIGUIENTE SALIDA DE AUDIO**.

En ambos casos, debes **reiniciar MPV-SW-Capture** para que el cambio surta efecto.

### 4. ¿Cómo sé qué modo está activo actualmente?

Abre el menú y ve a **AUDIO → MODO DE SALIDA DE AUDIO**. El modo activo es aquel que tiene la marca de verificación ✓ marca de verificación.

También puedes fijarte en el **encabezado**: la línea de audio muestra «WASAPI AUDIO» o «FFPLAY AUDIO», dependiendo del backend activo.

---

## 🔊 Audio

### 1. ¿Qué backends de audio admite MPV-SW-Capture?

MPV-SW-Capture admite **dos backends de audio**, y puedes elegir el que mejor funcione en tu sistema:

- **Complemento de audio WASAPI** (predeterminado): un complemento nativo que se carga directamente en MPV. Gestiona tanto el vídeo como el audio en el mismo proceso, es capturable por OBS, Discord y otras herramientas **sin necesidad de complementos de terceros**, y consume menos CPU y RAM que el backend FFplay.
- **FFplay de baja latencia** (alternativa): el clásico enfoque de procesos separados: MPV se encarga del vídeo y `ffplay`, del audio. Utilízalo si tu sistema no es compatible con el complemento WASAPI o si prefieres el flujo de trabajo anterior.

Puedes cambiar entre ellos en cualquier momento desde **AUDIO → MODO DE SALIDA DE AUDIO** en el menú, o desde la herramienta de configuración. El cambio requiere reiniciar MPV-SW-Capture.

### 2. ¿Cómo puedo ajustar el volumen de MPV-SW-Capture de forma independiente en Windows?

Tienes varias alternativas:

- **Dentro de MPV-SW-Capture (recomendado)**:
  - Utiliza la **rueda del ratón** (`ARRIBA` para subir, `ABAJO` para bajar).
  - Utiliza las **teclas de flecha** del teclado (`ARRIBA` para subir, `ABAJO` para bajar).
  - Pulsa **`M`** para silenciar o activar el sonido.
  - Abre la sección **`AUDIO`** del menú para acceder a los controles deslizantes de volumen y refuerzo de audio.
- **Barra lateral de volumen flotante**: si está activada, mueve el cursor al borde central izquierdo de la ventana y aparecerá una barra de audio flotante con ambos controles deslizantes.
- **Mezclador de volumen de Windows**:
  - **Modo WASAPI**: MPV-SW-Capture aparece en el mezclador con su propio icono. Ajusta el volumen allí si es necesario.
  - **Modo FFplay**: busca la entrada `ffplay` en el mezclador y ajusta su volumen. Utiliza esta opción solo como alternativa.

### 3. ¿Qué es el «Audio Boost» y cuándo debo utilizarlo?

**Audio Boost** es una opción que amplifica el audio de la tarjeta de captura **más allá del 100 % estándar**, hasta un **400 % (×4)**.

Es ideal para usuarios cuyo contenido capturado tiene un volumen muy bajo y necesita aumentarse más allá de los límites normales.

Lo encontrarás en las secciones **Opciones rápidas** y **AUDIO**, junto al control deslizante de volumen estándar.

### 4. ¿Se mantiene el Audio Boost entre sesiones?

Sí. El valor elegido se guarda en `data/menu/boost.txt` y se restaura automáticamente al iniciar el programa. Si lo configuras al 300 % y cierras el programa, seguirá siendo del 300 % la próxima vez que abras MPV-SW-Capture.

El **modo de salida de audio** y el estado de la **barra lateral de volumen al pasar el cursor** también se mantienen entre sesiones.

### 5. ¿Qué es el indicador de ganancia efectiva?

Una pequeña lectura situada debajo de los controles deslizantes de audio que muestra el resultado combinado de **volumen × refuerzo**. Cambia de color en función del riesgo de saturación:

- **Gris** (≤ 2,0x): normal.
- **Verde** (2,0 – 3,0x): ganancia apreciable.
- **Ámbar** (≥ 3,0x): alto riesgo de saturación.

**Recomendación:** deja el volumen al 100 % y sube el «Boost» poco a poco hasta que oigas la primera distorsión; a continuación, bájalo un poco. Subir el volumen no puede revertir el clipping que ya se haya producido en etapas anteriores.

### 6. ¿Dónde está el botón de silencio?

En dos sitios, ambos con la misma función:

- **En la barra de audio** (junto al porcentaje de volumen).
- **En el encabezado**: el icono verde de audio es clicable y alterna entre silenciar y desactivar el silencio. Funciona igual que el botón de la barra de audio.

Cuando está silenciado, el icono cambia y la etiqueta de volumen pasa a mostrar **«SILENCIADO»**.

### 7. ¿Qué es la «barra lateral de volumen al pasar el cursor» y cómo la activo?

Es una barra de audio flotante que aparece al mover el cursor hacia el borde central izquierdo de la ventana. Te permite acceder rápidamente al volumen y al refuerzo de audio sin necesidad de abrir el menú completo.

Para activarla o desactivarla: ve a **AUDIO → Barra lateral de volumen al pasar el cursor**. El estado se guarda y se restaura entre sesiones. También puedes configurar su estado predeterminado desde la herramienta **Configuración**.

### 8. ¿Qué son los parámetros de audio WASAPI de la herramienta de configuración?

La herramienta de configuración cuenta con una sección **exclusiva** de parámetros de audio WASAPI. Te permite ajustar ciertos parámetros de audio de bajo nivel que, de otro modo, estarían fijados de forma permanente; por ejemplo, para adaptarlos a lo que realmente admite tu PC o tu tarjeta de captura.

**Prácticas recomendadas:**

- Deja los parámetros en sus valores predeterminados a menos que tengas una razón específica para cambiarlos. Los valores predeterminados están ajustados para garantizar la estabilidad.
- Si experimentas fallos de audio (clics, chasquidos, crujidos), puedes intentar ajustar el búfer o los parámetros WASAPI.

> 💡 **Tamaño del búfer:** El tamaño predeterminado del búfer de audio WASAPI es de **25 ms**, ajustado para garantizar la estabilidad sin perder calidad ni inmediatez.

---

## 📹 Grabación y capturas de pantalla

### 1. ¿Por qué el límite de grabación predeterminado es de solo 30 segundos? ¿No es demasiado corto?

En realidad, puedes grabar todo el tiempo que quieras. El límite predeterminado de 30 segundos se debe al funcionamiento de la grabación: mientras reproduces, la herramienta necesita espacio temporal en el disco. Puede utilizar alrededor de 7–10 GB (para 30 segundos de grabación; 1 minuto ocupa el doble) de espacio libre en tu disco duro para almacenar un archivo de vídeo temporal y un archivo de audio temporal. Tras la grabación, ambos se fusionan en un archivo `.mp4` comprimido sin pérdida de calidad, y los archivos temporales de 7–10 GB se eliminan automáticamente.

Si el espacio en disco no supone un problema y deseas una duración predeterminada mayor, puedes aumentar el tiempo en `MPV-SW-Capture_SETUP.vbs`.

### 2. ¿Puedo grabar menos tiempo del predeterminado que he elegido?

Sí. Inicia la grabación desde el menú y, si vuelves a pulsar el mismo botón de grabación antes de que finalice el tiempo predeterminado, la grabación se detendrá inmediatamente en ese momento.

### 3. Cuando grabo un vídeo, ¿se incluyen los marcos, los recortes o los shaders?

No. El vídeo grabado se captura como si ninguno de estos elementos estuviera activo, independientemente de lo que estés utilizando. Esto se debe a que la grabación se realiza «antes» de que se aplique cualquiera de estos efectos.

### 4. Cuando hago una captura de pantalla, ¿incluye marcos, recortes o shaders?

Sí. Las capturas de pantalla se realizan con lo que tengas activo en ese momento. Si quieres una captura de pantalla «limpia», solo tienes que desactivar los shaders (y cualquier otra superposición) antes de realizarla.

### 5. ¿Dónde se almacenan los vídeos y las capturas de pantalla?

Se guardan en las carpetas `_record` y `_screenshots`, situadas en la misma carpeta donde instalaste MPV‑SW‑Capture.

No es necesario crearlas, ya que el software las crea automáticamente tras realizar una captura de pantalla o grabar un vídeo.

Si, por alguna extraña razón, no puedes grabar vídeos ni realizar capturas de pantalla, y no dispones de estas carpetas, puedes crearlas manualmente.

> 💡 **Nota:** Estas dos carpetas se **conservan durante una instalación limpia**. Tus grabaciones y capturas de pantalla nunca se trasladan a `OLDMSC`, por lo que no tienes que preocuparte por perderlas al utilizar esa opción.

### 6. Al grabar un vídeo, veo un contador con el tiempo que queda para terminar la grabación. ¿Es normal?

Sí, es normal. Así puedes comprobar cuánto tiempo te queda para terminar el vídeo.

---

## 🧰 Menú, ventana y controles

### 1. ¿Cómo abro el menú al iniciar el programa?

Solo tienes que hacer clic con el botón derecho del ratón en la ventana y se abrirá el menú. Como alternativa, puedes pulsar la tecla `ESC` del teclado, pero asegúrate de que el ratón esté sobre la ventana de MPV-SW-Capture y de que el programa tenga el foco.

### 2. ¿Cómo cierro el programa? No veo ningún botón «X» para cerrarlo.

Para cerrar MPV‑SW‑Capture, abre el menú y selecciona la opción `❌ CERRAR MPV-SW-Capture`. También puedes hacer clic en el botón **X** de la cabecera del menú, lo que cierra el menú pero no el programa. La **X** del pie de página (zona inferior izquierda) cierra todo el programa.

### 3. ¿Por qué veo una marca de verificación junto a algunas opciones del menú? ¿Qué significa el borde resaltado?

Se trata de dos indicadores visuales **independientes**:

- **✓ Marca de verificación** (parte inferior derecha de una ficha): significa que la opción está **activa actualmente**.
- **Borde resaltado** (contorno de color alrededor de una ficha): significa que **el cursor se encuentra actualmente sobre esa tarjeta**.

Se mueven de forma independiente. El borde sigue al cursor (del teclado o del ratón), mientras que la marca de verificación permanece sobre la opción que esté realmente activa. De esta forma, siempre puedes saber «dónde te encuentras» y «qué está activado» de un solo vistazo.

### 4. ¿Qué es la opción «Info Stream» y cómo la oculto una vez que está activada?

««Info Stream» muestra estadísticas sobre la transmisión actual (resolución, uso de recursos, etc.). Resulta útil cuando quieres comprobar qué está sucediendo internamente. Para ocultarlo, basta con volver a seleccionar la opción «Info Stream» y la superposición desaparecerá.

### 5. En el menú hay muchas opciones en el apartado VENTANA. ¿Para qué sirven?

Estas opciones te permiten personalizar la ventana de MPV‑SW‑Capture a tu gusto.

- Puedes cambiar el tamaño de 0,5x a 2,0x, o pasar a pantalla completa. También puedes establecer una posición específica para la ventana.
- «Siempre visible» mantiene la ventana por encima de las demás (pulsa de nuevo para desactivarla).
- «Ampliar ventana» te permite ampliar la imagen actual a una relación de aspecto más ancha (por ejemplo, de 16:9 a 21:9, o de 4:3 a 16:9). Esto resulta especialmente útil con NSO: si tienes un juego en 4:3, puedes aplicar un recorte y, a continuación, utilizar «Ampliar ventana» para llenar un área de 16:9.
- «Modo mini» reduce la ventana a un tamaño de 0,3x y la coloca en la esquina inferior derecha de la pantalla.

Además, estos modos de ventana son especialmente útiles para los streamers:

- **Modo Mini**: reduce la ventana al 30 % y la coloca en la esquina inferior derecha; es perfecto para mantener una pequeña vista previa en pantalla mientras gestionas otras tareas.
- **Pantalla completa**: te ofrece una visión envolvente con mínimas distracciones.
- **Ventana ampliada**: te permite ajustar la relación de aspecto (p. ej., 4:3 → 16:9) para llenar la pantalla o el área de captura.
- **Siempre encima**: mantiene la ventana por encima de otras aplicaciones, para que nunca pierdas de vista tu juego mientras retransmites.

### 6. ¿Cómo puedo cambiar el volumen de MPV‑SW‑Capture de forma independiente en Windows?

Consulta la sección **🔊 Audio** más arriba (pregunta 2).

### 7. Dices que hay dos programas, uno para el vídeo y otro para el audio. ¿Qué ocurre con el audio si cierro MPV‑SW‑Capture?

> 💡 **Nota:** El backend de audio predeterminado es el **WASAPI Audio Plugin**, que se ejecuta íntegramente dentro de MPV; no hay ningún proceso de audio independiente. La respuesta que figura a continuación se aplica al modo **FFplay Low Latency**.

En el modo FFplay, si cierras la ventana de MPV‑SW‑Capture, el audio también se cierra. Ambas partes están diseñadas para funcionar juntas, por lo que, cuando se cierra MPV‑SW‑Capture, el proceso de audio también se detiene y se cierra por completo.

### 8. ¿Qué ocurre si utilizo shaders, marcos, formas, recortes o cualquier otra opción y cierro el programa?

La mayoría de las opciones visuales (shaders, marcos, formas, recortes) **no se guardan**; solo permanecen activas hasta que cierres MPV-SW-Capture. Si lo vuelves a abrir, volverán a los valores predeterminados.

**Los siguientes ajustes SÍ se conservan entre sesiones:**

- **Amplificación de audio**: el porcentaje que hayas seleccionado.
- **Modo de salida de audio**: WASAPI o FFplay.
- **Barra lateral de volumen al pasar el cursor**: activada o desactivada.
- **Cambiar a perfil ICC automático**: activado o desactivado.
- **Convertir SDR a HDR**: se guarda automáticamente.
- **Modo de escalado de la GPU**: se guarda automáticamente.
- **Resolución de entrada**: solo si has hecho clic en **Guardar resolución**.

Las demás opciones que se conservan son las que puedes seleccionar en **Configuración**, **Instalador** y **Herramientas**.

### 9. En MPV‑SW‑Capture hay que usar el ratón para controlar el MENÚ, ¿verdad? Pero, ¿hay algún atajo de teclado y ratón para algunas funciones?

Sí, hay algunas funciones que puedes utilizar con el teclado y el ratón:

**a) Ratón:**

- **_Pantalla completa_:** Si haces doble clic en la pantalla, puedes alternar entre **activar** y **desactivar** la pantalla completa.
- **_Acceso al MENÚ_:** Haz clic con el botón derecho del ratón en la pantalla para acceder al menú.
- **_Control de audio_:** Usa la rueda del ratón `ARRIBA` para subir el volumen y `ABAJO` para bajarlo. Puedes seguir girando la rueda hasta encontrar el volumen que desees.

**b) Teclado:**

- **_Acceso al MENÚ_:** Pulsa `ESC` para acceder al menú.
- **_Navegar por el MENÚ_:** También puedes utilizar las teclas `ARRIBA`, `ABAJO`, `IZQUIERDA` y `DERECHA` del teclado para navegar por el MENÚ.
- **_Aplicar opción_:** Pulsa `ENTRAR` para activar la opción resaltada.
- **_Cambiar de sección_:** Pulsa `TAB` para pasar a la siguiente sección, o `PGUP`/`PGDN` para desplazarte entre secciones.
- **_Control de audio_:** Utiliza la tecla `ARRIBA` del teclado para subir el volumen en +10 y la tecla `ABAJO` para bajarlo en -10.
  - La tecla `M` sirve para silenciar el sonido y, al pulsarla de nuevo, para reactivarlo.

### 10. ¿Cómo puedo comprobar qué versión de MPV-SW-Capture tengo instalada?

Hay dos formas:

1. Visita la [página oficial de lanzamientos](https://github.com/TyRaS-SW/MPV-SW-Capture/releases) para ver la última versión disponible.
2. Abre MPV-SW-Capture, ve al menú **`AYUDA` → `Comprobar la última versión de MSC`**. El programa te indicará si tienes la última versión o si hay una actualización disponible.

### 11. ¿Qué funciones tiene el menú?

El menú es una interfaz gráfica al estilo de los Smart TV basada en ASS (Advanced SubStation Alpha). Entre sus funciones se incluyen:

- Navegación por secciones con una barra lateral visual e iconos.
- Tarjetas específicas para cada opción, con indicadores de estado activo.
- Controladores de audio arrastrables con lectura en tiempo real de la ganancia efectiva.
- **Selector de idioma en el menú**: cambia el idioma de la interfaz sobre la marcha.
- **Acciones rápidas en el encabezado**: botones en los que se puede hacer clic para `HACER CAPTURA DE PANTALLA`, `GRABAR VÍDEO`, la insignia de idioma (`EN`/`ES`/`JP`), el **conmutador rápido de resolución** y el botón de cierre.
- Sección **Opciones rápidas** para acceder rápidamente a tareas habituales.
- **Secciones específicas**: AYUDA y HERRAMIENTAS están separadas entre sí.
- **Descripciones de las secciones**: cada sección del menú muestra un breve texto explicativo en la parte inferior.
- **Marcos organizados con pestañas**: **Todos**, **NSO** (con subpestañas por consola: NES, SNES, GB, GBA, N64) y **PERSONAL** (aparece automáticamente al crear marcos que no sean NSO).
- **Iconos personalizados** para la mayoría de las opciones del menú, lo que da a la interfaz un aspecto más limpio.
- Selector de **modo de salida de audio** (WASAPI / FFplay) en la sección **AUDIO** .
- **Barra lateral de volumen al pasar el cursor** en la sección **AUDIO**.
- Se ha añadido **Cambiar a perfil ICC automático** a **Opciones rápidas → CONFIGURACIÓN**.
- **Botón de silencio** en la barra de audio e icono de audio en el que se puede hacer clic en el encabezado.
- Sección **`RESOLUCIÓN DE ENTRADA`** en **OPCIONES DE VÍDEO** con escalado por CPU/GPU y opciones para guardar o anular la resolución.
- **`Convertir SDR a HDR`** y **`RGB completo`** en **OPCIONES DE VÍDEO**.
- **Shaders de nitidez y antialiasing** en **SHADERS**.
- Shaders **Retro Pixel / NSO 5xBRZ**.
- Opciones **`Ajustar 16:9 al marco`** y **`Ajustar 16:9 al recorte`**.
- **Navegación tipo TV**: el menú recuerda tu última sección y pestaña (véase la siguiente pregunta).

### 12. El menú recuerda dónde estaba cuando lo vuelvo a abrir. ¿Es eso intencionado?

Sí. El menú conserva la sección y la pestaña en las que te encontrabas al cerrarlo y volver a abrirlo. Siempre vuelves exactamente al punto en el que lo dejaste; esto le da a MPV-SW-Capture una sensación de navegación similar a la de un televisor.

### 13. ¿Por qué a veces el menú se cierra y se vuelve a abrir automáticamente?

Al aplicar una tarjeta en **Shaders**, **Formas**, **Recortes**, o **Marcos** oculta el menú y lo vuelve a abrir 3 segundos después. Esto es intencionado: te permite ver el efecto en el vídeo sin perder el menú a mano.

Las opciones de **Audio Boost** se comportan de la misma manera, por lo que el control deslizante refleja el nuevo valor cuando se vuelve a abrir el menú.

### 14. ¿Cómo cambio el idioma sin salir de MPV?

Haz clic en el **icono de idioma** del encabezado (muestra `EN`, `ES`, `JP`, …) o en el botón equivalente en **Opciones rápidas → CONFIGURACIÓN**. Cada clic cambia al siguiente idioma disponible.

El cambio se aplica **al instante**; no es necesario cerrar y volver a abrir MPV-SW-Capture.

> 💡 Si te encontrabas en una pestaña distinta a la predeterminada y luego cambias el idioma, la pestaña en la que te encuentras permanece activa.

### 15. ¿Qué hace la opción «CLEAN ALL»?

«CLEAN ALL» realiza un restablecimiento completo. Borra todos los shaders, formas, recortes y marcos, y además restablece:

- Tamaño de la ventana → **1,0x**
- Posición de la ventana → **centrada**
- Rotación → **0°**
- Borde → **desactivado**
- Barra de título → **desactivada**
- Siempre encima → **desactivado**
- Anulación de la relación de aspecto → **16:9**
- Eliminación de bandas → **desactivada**

> 💡 **Nota:** `CLEAN ALL` **no** afecta a `RESOLUCIÓN DE ENTRADA`, `Convertir SDR a HDR` ni `RGB completo`; estos se conservan. Tampoco **borra** directamente los filtros `vf`; sino que delega en cada script (marco, recorte, shaders adicionales, colores) para que los procesos de HDR y Full RGB permanezcan intactos.

Puedes activarlo desde el pie de página de la barra lateral o desde **Opciones rápidas → CAPTURA → Limpiar todo**.

---

## 🧰 Herramientas

### 🌐 Transmite con OBS

> **⚠️ IMPORTANTE: lee esto primero:**
>
> **El Stream Helper solo es necesario si utilizas el modo de audio `FFplay Low Latency`.**
>
> Si utilizas el modo predeterminado **`WASAPI Audio Plugin`**, **NO necesitas el Stream Helper**. OBS, Discord y otras herramientas de captura pueden capturar el audio de MPV-SW-Capture de forma nativa, sin necesidad de complementos de terceros.
>
> Utiliza esta herramienta solo si:
> - Has cambiado al modo **`FFplay Low Latency`**, **y**
> - Quieres retransmitir o grabar MPV-SW-Capture a través de OBS con el audio del juego.

#### 1. ¿Qué es el Stream Manager y para qué sirve?

El Stream Manager (MSCGUI) es una herramienta gráfica del paquete `TOOLS_*.zip` que te ayuda a configurar OBS Studio para capturar MPV-SW-Capture. Automatiza la instalación del complemento `win-capture-audio`, configura colecciones de escenas, añade las fuentes necesarias (Captura de ventana + Captura de audio) e incluye un modo Streamer para ocultar los mensajes OSD. También te permite cambiar entre los modos **Instalado** y **Portátil** de OBS.

#### 2. ¿Por qué se necesitan derechos de administrador para instalar el complemento `win-capture-audio` en OBS (modo instalado)?

Cuando OBS está instalado en una carpeta del sistema protegida, como `C:\Archivos de programa`, escribir archivos en su directorio de instalación requiere permisos elevados. El Gestor de transmisiones lo detectará y te pedirá que lo reinicies como administrador. Por el contrario, si utilizas la versión **portátil** de OBS (instalada en cualquier lugar fuera de `Archivos de programa`), no se necesitan permisos especiales.

#### 3. ¿Cuál es la diferencia entre OBS instalado y OBS portátil en el contexto de MPV-SW-Capture?

- OBS **instalado** es la instalación estándar en `Archivos de programa`. Es la más habitual, pero puede requerir derechos de administrador para modificar o instalar complementos.
- OBS **portátil** es una versión autónoma que puedes colocar en cualquier lugar (por ejemplo, en una memoria USB). No requiere derechos de administrador y te permite llevar tu configuración contigo. Sin embargo, debes descargar la versión ZIP y extraerla manualmente. El Stream Manager puede ayudarte a descargar y configurar ambos modos.

#### 4. ¿Cómo puedo utilizar MPV-SW-Capture con OBS de forma más sencilla?

Depende de tu modo de audio:

- **Complemento de audio WASAPI (predeterminado)**: OBS captura el audio de MPV-SW-Capture **de forma nativa**. Solo tienes que añadir una fuente de **Captura de ventana** que apunte a `mpv.exe`: no se necesitan complementos, ni Stream Helper, ni ninguna configuración adicional.
- **FFplay de baja latencia**: utiliza el **Stream Manager** (del paquete `TOOLS_*.zip`). Automatiza todo el proceso: instala el complemento `win-capture-audio`, crea una colección de escenas o añade las fuentes necesarias a una colección existente.

Para obtener guías detalladas paso a paso, consulta:

- [Personalización avanzada](https://tyras-sw.github.io/MPV-SW-Capture/#advanced)

#### 5. ¿Qué es la opción «Ocultar mensajes OSD» y cómo afecta a la grabación?

La opción **«Ocultar mensajes OSD»** se encuentra en el menú, en **AYUDA → Ocultar mensajes OSD**. Cuando está activada, oculta todos los mensajes en pantalla que aparecen al seleccionar cualquier opción (por ejemplo, cambios de shader, ajustes de recorte, etc.). Es ideal para streamers que no quieren que estas notificaciones aparezcan en su retransmisión, o para usuarios que simplemente prefieren una interfaz más limpia.

**Importante:** Por motivos de seguridad, la función **`GRABAR VÍDEO`** queda completamente desactivada cuando está activa la opción `Ocultar mensajes OSD`. Solo puedes utilizar la grabación cuando esta opción está desactivada. Esto garantiza que seas consciente del estado de la grabación y evites grabar accidentalmente sin retroalimentación visual.

### 🖼 Bezel Manager

#### 1. ¿Qué es el Bezel Manager y para qué sirve?

El Gestor de marcos es una herramienta gráfica del paquete `TOOLS_*.zip` que te permite gestionar y personalizar los marcos (bordes decorativos) para MPV-SW-Capture. Con ella, puedes:

- Previsualizar los marcos antes de aplicarlos.
- Añadir nuevos marcos al menú (colocando tus imágenes PNG en la carpeta correspondiente y actualizando la configuración).
- Eliminar o reorganizar los marcos existentes.

Esta herramienta simplifica el proceso de creación y uso de marcos personalizados sin tener que editar manualmente los archivos de configuración. Para obtener una guía detallada, consulta aquí: **[Personalización avanzada → 8. Crea tu marco personalizado](https://tyras-sw.github.io/MPV-SW-Capture/#advanced)**.

### 🎞 Gestor de vídeo

#### 1. ¿Qué es el Gestor de vídeo y para qué sirve?

El Gestor de vídeo es una herramienta gráfica del paquete `TOOLS_*.zip` que te permite ajustar parámetros avanzados de vídeo para MPV-SW-Capture sin tener que editar directamente el archivo `mpv.conf`. Puedes modificar ajustes como:

- **Formato de vídeo de entrada**: elige entre `Auto`, `mjpeg`, `yuyv422`, `nv12`, `i420` o `h264`. Cámbialo solo si experimentas retrasos o problemas de compatibilidad.
- **Velocidad de fotogramas** — hasta **120 fps** (requiere que la tarjeta de captura, el monitor y la consola sean compatibles con 120 fps).
- **API de la GPU**.
- **Profundidad de la cadena de intercambio**.
- Latencia de vídeo.
- Tamaño del búfer de audio.
- Decodificación por hardware (`hwdec`).
- Opciones de renderizado por GPU (`vo=gpu`).
- Otras opciones relacionadas con el rendimiento.

Esta herramienta resulta especialmente útil para los usuarios que desean ajustar con precisión el rendimiento y la calidad, pero prefieren una interfaz intuitiva en lugar de archivos de configuración manuales.

> ⚠️ **Nota sobre los FPS:** Si configuras unos FPS que tu tarjeta de captura no admite, MPV no podrá iniciarse. Si no estás seguro, déjalo en **Auto**.

---

## 📋 Idioma

### 1. ¿Qué idiomas están disponibles?

Actualmente: **inglés** (`en`), **español** (`es`) y **japonés** (`jp`).

La lista se lee desde `scripts/lang/language_list.dat`, lo que significa que **puedes añadir cualquier idioma que desees**: el sistema es totalmente extensible. Si te interesa añadir uno nuevo, consulta la pregunta 5.

### 2. ¿Dónde se cambia el idioma: en el menú o en «Configuración»?

Ambas opciones funcionan:

- **En «Configuración»**: selecciona el idioma de la lista y pulsa **«Aplicar idioma»»**.
- **En el menú**: haz clic en el **icono de idioma** (`EN`/`ES`/`JP`) de la cabecera, o en el botón de **Opciones rápidas → CONFIGURACIÓN**. Cada vez que hagas clic, se pasará al siguiente idioma disponible.

El cambio se aplica **al instante** en el menú; no es necesario cerrar MPV-SW-Capture. Los cambios realizados en «Configuración» requieren reiniciar el programa para que surtan efecto.

### 3. ¿Qué se traduce?

El selector de idioma traduce los siguientes elementos:

- El **menú** (secciones, pestañas, etiquetas de las tarjetas, pie de página, encabezado).
- **Mensajes de MPV-SW-Capture** (notificaciones OSD, mensajes de estado, mensajes de error).

> ⚠️ **Nota sobre las interfaces gráficas de «Configuración», «Instalador» y «Herramientas»**: estas herramientas tienen su **propio soporte de idiomas codificado** y **no** se traducen mediante el selector de idioma del menú. Actualmente solo admiten **inglés** y **español**. Consulta la pregunta 4 para obtener más detalles.

### 4. ¿Se mantiene la selección de idioma en todos los programas (Configuración, Instalador, Herramientas)?

**Respuesta breve:** Sí, pero hay **dos sistemas de idioma independientes**: uno para las interfaces gráficas y otro para el menú.

**Sistema 1 — Todas las interfaces gráficas comparten UNA misma preferencia:**

- La configuración, el instalador, el gestor de marcos, el gestor de vídeo y el gestor de streaming **leen y escriben en el mismo archivo de idioma**.
- Esto significa que siempre muestran el mismo idioma entre sí. Si configuras la Configuración en español, el Instalador también estará en español, y así sucesivamente.
- Actualmente, estas interfaces gráficas solo admiten **inglés y español** (el japonés no está disponible en ellas).

**Sistema 2 — El menú tiene su propia preferencia independiente:**

- El menú del juego utiliza un sistema diferente, basado en `scripts/lang/language_list.dat`.
- Actualmente admite **inglés, español y japonés**.
- Cambiar el idioma de la interfaz gráfica **no** afecta al menú, y cambiar el idioma del menú **no** afecta a las interfaces gráficas.

**Tabla resumen:**

| Componente | Idiomas disponibles | Compartido con |
|---|---|---|
| **Todas las interfaces gráficas** (Configuración, Instalador, Herramientas) | EN, ES | Entre sí (una preferencia compartida) |
| **Menú** (en MPV-SW-Capture) | EN, ES, JP + cualquier otro que añadas | Nada más — totalmente independiente |

### 5. ¿Cómo añado un nuevo idioma?

MPV-SW-Capture admite la incorporación de cualquier idioma, siempre que alguien proporcione los archivos de traducción. El proceso es sencillo y no requiere ningún cambio en el código.

**1. Registra el código del idioma**

Abre `scripts/lang/language_list.dat` y añade el código de dos letras de tu idioma en una línea separada (por ejemplo, `fr` para francés, `de` para alemán, `pt` para portugués).

**2. Crea los 3 archivos de traducción**

Tienes que crear **3 archivos** dentro de `scripts/lang/`. La forma más sencilla es **copiar un archivo existente y traducir solo la parte derecha de cada línea**:

| Archivo que hay que crear | Copia este archivo como punto de partida | Qué se traduce |
|---|---|---|
| `MENUMSG_<lang>.dat` | `MENUMSG_es.dat` | Etiquetas de menú (nombres de secciones, etiquetas de tarjetas, información sobre herramientas) |
| `ASMENU_<lang>.dat` | `ASMENU_en.dat` | Cadenas internas del menú (deslizadores, botones, pie de página) |
| `OSDMSG_<lang>.dat` | `OSDMSG_en.dat` | Mensajes en pantalla (notificaciones, errores, estado) |

Sustituye `<lang>` por el código de tu idioma del paso 1. Por ejemplo, para el francés, crearías `MENUMSG_fr.dat`, `ASMENU_fr.dat` y `OSDMSG_fr.dat`.

> ⚠️ **Importante: traduce solo la parte DERECHA de cada línea.**
>
> Todas las líneas de estos archivos tienen el formato `izquierda=derecha`. La **parte izquierda es la clave original en inglés** y **no** debe modificarse, ya que es así como el programa encuentra la traducción. Traduce únicamente la **parte derecha**, después del signo `=`.
>
> **Ejemplo** (en `MENUMSG_fr.dat`):
> ```
> Take Screenshot=Prendre une Capture d'Écran
> ```
> Fíjate en que `Take Screenshot=` permanece exactamente igual. Solo se traduce el texto que aparece después del `=`.

**3. Reinicia mpv**

Cierra y vuelve a abrir MPV-SW-Capture. Tu idioma aparecerá ahora en el selector de idiomas (tanto en el botón de la cabecera del menú como en Configuración → Aplicar idioma).

> 💡 **Consejo**: No es necesario traducir todas las líneas. Cualquier clave sin traducir se mostrará automáticamente en inglés, por lo que puedes empezar con una traducción parcial e ir mejorándola con el tiempo.

---

## 📋 Solicitudes, incidencias y comentarios

### 1. Tengo algunos comentarios, incidencias o solicitudes sobre este proyecto. ¿Dónde puedo compartir mi opinión en GitHub?

- **Comentarios**: [Debates](https://github.com/TyRaS-SW/MPV-SW-Capture/discussions)
- **Incidencias**: [Incidencias](https://github.com/TyRaS-SW/MPV-SW-Capture/issues)
- **Ideas / Solicitudes**: [Ideas](https://github.com/TyRaS-SW/MPV-SW-Capture/discussions/categories/ideas)

### 2. ¿Puedo preguntar en otra plataforma como Discord?

¡Sí! Puedes compartir comentarios, incidencias, peticiones y mucho más en el Discord oficial: **[Discord oficial de MPV-SW-Capture](https://discord.gg/PaVutUUK9U)**.

---

## 📋 Solución de problemas

### 1. He intentado abrir `MPV.exe` (o su acceso directo), pero no pasa nada. ¡No se abre la pantalla! ¿Qué puedo hacer?

Las tarjetas de captura se tratan como cámaras en Windows.

Además, si abres tu tarjeta de captura con otro programa, no podrás utilizarla en MPV-SW-Capture hasta que cierres primero ese otro programa.

Por ejemplo, si abres la cámara en Ajustes de Windows → Bluetooth y dispositivos → Cámaras, y seleccionas tu tarjeta de captura como cámara, no podrás utilizar MPV-SW-Capture hasta que la cierres desde allí.

Esta es una limitación que tienen las tarjetas de captura por defecto.

Si la ventana aparece un instante y luego se cierra, suele deberse a que el dispositivo de captura no está configurado correctamente. Ejecuta `MPV-SW-Capture_SETUP.vbs`, selecciona tu tarjeta de captura (vídeo y audio), haz clic en «Guardar y salir» y, a continuación, vuelve a iniciar el programa.

### 2. ¿Puedo abrir varias ventanas con `MPV.exe`?

No. `MPV.exe` solo admite una ventana a la vez. Al igual que en la respuesta anterior, la tarjeta de captura actúa como un único dispositivo, por lo que esto es normal.

### 3. Tengo más de una tarjeta de captura conectada. ¿Cómo puedo cambiar la tarjeta de captura predeterminada?

En la configuración, pulsa **«Escanear dispositivo»** y elige la otra tarjeta de captura (vídeo y audio) que quieras utilizar.

Debes cerrar y volver a abrir MPV-SW-Capture para que se apliquen los cambios.

### 4. He ejecutado `MPV-SW-Capture_INSTALLER.vbs` y no ha pasado nada. ¿Qué ocurre?

Lo más probable es que se trate de una instalación nueva y que `mpv.exe` aún no exista. En una instalación nueva, debes ejecutar primero **`1_INSTALLER_MSC_First-Usage.cmd`** primero. Consulta la sección **🛠️ Instalación y lanzadores** para obtener más detalles.

### 5. He cambiado al modo WASAPI, pero no oigo ningún sonido. ¿Qué puedo hacer?

En primer lugar, comprueba que realmente has reiniciado MPV-SW-Capture tras cambiar de modo; el cambio solo se aplica en el siguiente inicio.

Si tras reiniciar sigues sin tener sonido:

- Comprueba que el dispositivo de audio correcto esté seleccionado en la herramienta **Configuración**.
- Comprueba que MPV-SW-Capture no esté silenciado en el **Mezclador de volumen de Windows**. En el modo WASAPI, MPV-SW-Capture aparece en el mezclador con su propio icono (no como `ffplay`).
- Si el problema persiste, vuelve al modo **FFplay de baja latencia** desde **AUDIO → MODO DE SALIDA DE AUDIO**. Es posible que tu sistema no sea totalmente compatible con el complemento WASAPI.

### 6. Mi captura presenta retrasos, interrupciones o problemas de compatibilidad. ¿Qué puedo hacer?

Abre **Configuración** o **Gestor de vídeo** y cambia el **Formato de vídeo de entrada** de `Automático` (predeterminado) a otro formato. A continuación se explica qué significa cada opción:

- **`mjpeg`**: **Comprimido** (intra-fotograma). La tarjeta de captura comprime cada fotograma como un JPEG. Utiliza **menos ancho de banda USB**, pero el proceso de compresión/descompresión añade una pequeña cantidad de latencia. Suele ser la opción *comprimida* más rápida, pero un formato sin procesar normalmente será más rápido si tu ancho de banda lo permite.

- **`yuyv422`** (también conocido como YUY2): **SIN COMPRIMIR / Sin comprimir**. El color se muestrea a 4:2:2. Requiere **un gran ancho de banda USB**, pero ofrece la **latencia más baja posible**, ya que no hay ningún paso de decodificación. En la práctica, puede tener una latencia 30 ms o más inferior a la del MJPEG.

- **`nv12`**: **Sin procesar / Sin comprimir**. El color se muestrea en 4:2:0. Necesita **menos ancho de banda que `yuyv422`** (unos 12 bits por píxel frente a 16) y, al mismo tiempo, evita la compresión, por lo que también ofrece **una latencia muy baja**.

- **`i420`**: **RAW / Sin comprimir**. También utiliza muestreo 4:2:0, pero con una disposición de memoria diferente. El rendimiento y el ancho de banda son **similares a los de `nv12`**: sin compresión, latencia muy baja.

- **`h264`**: **Comprimido** (entre fotogramas). Esta es la opción con mayor compresión. Consume menos ancho de banda, pero suele introducir una **latencia mayor** debido al proceso de codificación/decodificación, a menos que tu GPU lo gestione con aceleración por hardware.

> 💡 **Resumen rápido:**
> - **Mínima latencia (RAW):** `yuyv422`, `nv12`, `i420`
> - **Ancho de banda bajo (comprimido):** `mjpeg`, `h264`
> - **Mejor equilibrio:** Prueba `nv12` o `yuyv422` si el ancho de banda de tu USB te lo permite. Utiliza `mjpeg` solo si tienes problemas de ancho de banda y puedes tolerar un poco más de latencia.

> ⚠️ **Importante: no todos los formatos son compatibles con todas las tarjetas de captura.**  
> Cada tarjeta de captura solo admite un **subconjunto** de estos formatos, y la lista exacta depende del modelo, los controladores e incluso del puerto USB que utilices.
>
> - Si seleccionas un formato que tu tarjeta de captura no admite, **MPV-SW-Capture podría no abrirse**, mostrar una pantalla en negro o cerrarse inmediatamente.
> - En ese caso, **vuelve a abrir `MPV-SW-Capture_SETUP.vbs`** (o el Gestor de vídeo) y selecciona un formato diferente hasta que encuentres uno que funcione.
> - Si no estás seguro de cuáles son los formatos compatibles con tu tarjeta, la opción más segura es volver a **`Auto`**.

Recuerda que `Auto` es el valor predeterminado recomendado. Solo cambia esta configuración si `Auto` provoca retrasos o problemas de compatibilidad con tu tarjeta de captura concreta.

### 7. MPV no se abre después de establecer un FPS específico en el Gestor de vídeo. ¿Qué puedo hacer?

Establecer un valor de FPS que tu tarjeta de captura no admita puede impedir que MPV se abra. Para evitarlo:

- Deja siempre los FPS en **Auto**, a menos que estés seguro de que tu tarjeta de captura admite el valor elegido.
- Si conoces las especificaciones de FPS de tu tarjeta, puedes configurarlo explícitamente. De lo contrario, utiliza Auto.

Si MPV no se abre:

- Vuelve a instalarlo mediante `MPV-SW-Capture_INSTALLER.vbs` (o `1_INSTALLER_MSC_First-Usage.cmd` si también falta `mpv.exe`).
- Tras la recuperación, vuelve a configurar los FPS en **Auto** en el Gestor de vídeo.

Si sigues teniendo problemas, comprueba el FPS que admite realmente tu tarjeta de captura o déjalo en **Automático**.