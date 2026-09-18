# ❓ Preguntas frecuentes

## 🎮 Generalidades y concepto

### 1. ¿Por qué utilizar MPV para jugar en cualquier consola compatible con HDMI?

MPV es un reproductor de vídeo muy potente y rápido cuando se configura correctamente. Además, te permite añadir shaders, marcos, recortes y muchas otras opciones, lo que lo convierte en algo más que «simplemente reproducir» y lo transforma en una herramienta que puedes personalizar realmente para jugar con la consola.

### 2. ¿Por qué MPV y no otro programa?

Existen otros programas que permiten capturar vídeo y hacer algo similar a este proyecto, pero suelen ser más limitados y no ofrecen el mismo nivel de personalización que MPV-SW-Capture aporta a MPV. Además, la mayoría tiende a aumentar el retraso, lo que hace que la experiencia sea insoportable.

> 💡 **Nota:** Desde la versión 5.1.0, MPV-SW-Capture incluye su propio complemento de audio nativo (WASAPI), lo que significa que el audio se captura en tiempo real y puede utilizarse en OBS, Discord y otras herramientas sin necesidad de ningún complemento externo.

---

## 🧩 Hardware y tarjetas de captura

### 1. ¿Por qué necesito una tarjeta de captura compatible con 1080p60?

Porque 1080p60 es el estándar de calidad actual para la mayoría de las consolas y dispositivos de captura modernos. Optar por 1080p60 garantiza una buena calidad de imagen y una experiencia de juego fluida.

### 2. ¿Por qué se recomienda el USB 3.0? ¿Qué ocurre si utilizo el USB 2.0?

Se recomienda el USB 3.0 porque ofrece un mayor ancho de banda, lo que se traduce en una mejor calidad de imagen y un rendimiento más estable para vídeos de alta resolución y alta frecuencia de fotogramas. Aún así, puedes utilizar el USB 2.0, pero la calidad y la estabilidad pueden verse afectadas. Si no tienes otra opción, puedes utilizarlo de todos modos, pero ten en cuenta esta limitación.

### 3. ¿Puedo utilizar cualquier tarjeta de captura USB-HDMI?

En teoría, sí. Sin embargo, para este proyecto se recomienda una tarjeta de captura que admita 1080p60 y cuente con conexión en bucle (entrada HDMI + salida HDMI). Existen opciones relativamente económicas que son fáciles de encontrar. Un ejemplo que puedes buscar es: «4K Ultra HD USB 3.0 HD Video Capture (MS 2131)». Estos dispositivos admiten entradas de hasta 4K60 y emiten a 1080p60. Por ejemplo, si conectas una consola que admite 4K a 60 fps, la tarjeta de captura la aceptará, pero la imagen final utilizada por MPV-SW-Capture será de 1080p a 60 fps.

### 4. ¿Qué hay de las tarjetas de captura tipo memoria USB que solo tienen HDMI y USB, y que suelen admitir hasta 720p60?

En principio deberían funcionar, pero no se han probado con este proyecto. Si pruebas una y funciona (o no), por favor, comparte tus resultados en el proyecto para que otros puedan beneficiarse de esa información.

### 5. Si tengo una tarjeta de captura USB 3.0 capaz de emitir más de 1080p60 (como 1440p60 o 4K60), ¿funcionará?

Este caso tampoco se ha probado, pero, en principio, debería funcionar sin problemas importantes. Si lo pruebas, por favor, comparte tus resultados.

### 6. Tengo una consola que solo emite hasta 720p en lugar de 1080p, ¿funcionará?

Sí, funcionará perfectamente. Por ejemplo, se probó con una salida de solo 720p y el resultado fue un escalado automático a 1080p. Con esto, todo funcionó correctamente, incluso los marcos, los recortes y los shaders.

Además, se ha probado con consolas más antiguas que admiten menos de 720p (480p), conectadas mediante un adaptador de AV a HDMI, y el resultado también es un aumento de resolución a 1080p.

---

## 🎮 Software

### 1. ¿Qué software necesitamos para utilizar MPV-SW-Capture?

Se necesitan tres programas: `MPV` es el principal. También se necesitan `ffplay` y `ffmpeg` para que funcione.

Por eso hay que descargarlos e instalarlos, tal y como se explica en la Guía de instalación.

### 2. He seguido las instrucciones y he configurado correctamente mi `MPV-SW-Capture`. Pero me he dado cuenta de que los tres programas tienen ahora una versión más reciente que la que utilizaba antes. ¿Puedo actualizarlos sin que deje de funcionar el MPV-SW-Capture?

Si te refieres a `MPV`, `ffplay` y `ffmpeg`, sí, puedes actualizar osustituir los tres programas sin ningún problema. Tienes que descargar sus nuevas versiones y sustituir las antiguas por las más recientes.

Eso es todo lo que tienes que hacer. Además, siempre es recomendable tener la versión más reciente.

Pero si detectas algún problema, puedes probar con versiones anteriores. Si eso ocurre, por favor, comenta el problema en **[Issues](https://github.com/TyRaS-SW/MPV-SW-Capture/issues)**, para que podamos revisarlo y solucionarlo.

Si te refieres al propio MPV-SW-Capture, lo recomendable es simplemente sustituir todos los archivos.

> 💡 **Nota:** A partir de la versión 5.1.0, algunas preferencias de usuario (Audio Boost, Modo de salida de audio, Barra lateral de volumen al pasar el cursor y Perfil ICC automático) se guardan automáticamente y se conservan tras las actualizaciones. No es necesario volver a configurarlas tras sustituir los archivos.

### 3. ¿Qué hace `1_INSTALLER_MSC_First-Usage.cmd`?

`1_INSTALLER_MSC_First-Usage.cmd` es el punto de entrada para la **primera instalación** de MPV-SW-Capture. Al ejecutarlo:

1. Abre una ventana de consola con instrucciones.
2. Descarga e instala todos los componentes necesarios, incluidos `mpv.exe`, `ffplay.exe` y `ffmpeg.exe`.
3. Inicia automáticamente la herramienta de configuración cuando se cierra el instalador, para que puedas configurar la aplicación.

Solo tienes que ejecutar este archivo CMD **una vez**. A partir de entonces, todas las actualizaciones futuras utilizarán `MPV-SW-Capture_INSTALLER.vbs`.

### 4. ¿Qué hace `MPV-SW-Capture_INSTALLER.vbs`?

`MPV-SW-Capture_INSTALLER.vbs` es el programa de inicio para **futuras actualizaciones**. Una vez finalizada la instalación inicial, utiliza este archivo `.vbs` para:

- Actualizar MPV-SW-Capture a una versión más reciente.
- Actualizar `ffplay` y `ffmpeg` a sus últimas versiones.
- Volver a descargar los componentes que falten (por ejemplo, si has borrado accidentalmente `ffplay.exe` o `ffmpeg.exe`).

> ⚠️ **Limitación importante**: Este archivo `.vbs` **requiere que `mpv.exe` esté presente** para poder ejecutarse; utiliza `mpv.exe` para iniciar el script de instalación interno. Si se elimina el propio `mpv.exe`, el archivo `.vbs` no realizará ninguna acción visible.
>
> Por ese motivo, **mantén el archivo `1_INSTALLER_MSC_First-Usage.cmd` en la misma carpeta** como herramienta de recuperación. Si alguna vez pierdes `mpv.exe`, ese archivo CMD es la única forma de reinstalarlo sin tener que volver a descargar todo el ZIP.

### 5. He eliminado accidentalmente uno de los ejecutables necesarios. ¿Tengo que reinstalarlo todo?

Depende de **qué** archivo se haya eliminado:

- **Si has eliminado `ffplay.exe` o `ffmpeg.exe`** (pero `mpv.exe` sigue ahí):
  Ejecuta `MPV-SW-Capture_INSTALLER.vbs` y utiliza la función **Check**. Detectará el archivo que falta y te permitirá volver a descargar solo ese componente.

- **Si has eliminado `mpv.exe`**:
  El archivo `.vbs` no funcionará, ya que depende de `mpv.exe` para ejecutarse. En este caso, **ejecuta de nuevo `1_INSTALLER_MSC_First-Usage.cmd`**: detectará que falta `mpv.exe` y lo volverá a descargar. Por eso recomendamos mantener el archivo CMD en la carpeta incluso después de la primera instalación.

### 6. Estaba utilizando el instalador y ahora no puedo actualizar. ¿A qué se debe esto?

Esto se debe a una limitación de GitHub. Si realizas muchas operaciones, GitHub limita las descargas hasta que haya transcurrido una hora. Solo puedes tener este problema si descargas, actualizas, etc., en una cantidad excesiva.

Dado que solo estás actualizando o instalando, esto no debería suponer un problema. Pero si tienes este problema, espera una hora o realiza una instalación manual.

Como solución alternativa, puedes realizar una instalación manual mientras esperas, o simplemente esperar una hora e intentarlo de nuevo. Puedes consultar cómo hacerlo en la **[Guía de instalación](https://tyras-sw.github.io/MPV-SW-Capture/)**. Este límite lo impone GitHub para evitar abusos.

### 7. ¿Cómo funcionan los números de actualización en MPV-SW-Capture?

Cuando ves una actualización, aparecen tres números separados por puntos. Aquí se representan como `X`, `Y`, `Z`:

v`X`.`Y`.`Z`.

- `X` = Actualización muy importante que debe aplicarse.
- `Y` = Actualización importante.
- `Z` = Parche menor o pequeña novedad añadida.

---

## 🛠️ Instalación y lanzadores

### 1. He abierto `MPV-SW-Capture_INSTALLER.vbs` en una instalación nueva y no ha pasado nada. ¿Por qué?

En una instalación nueva, primero debes ejecutar **`1_INSTALLER_MSC_First-Usage.cmd`**. Este archivo descarga e instala todos los componentes necesarios, incluido `mpv.exe`. Una vez hecho esto, `MPV-SW-Capture_INSTALLER.vbs` funcionará con normalidad para futuras actualizaciones.

`MPV-SW-Capture_INSTALLER.vbs` requiere que `mpv.exe` esté presente. Si falta, el ejecutable no realiza ninguna acción visible; esto es así por diseño, pero puede resultar confuso. Comprueba siempre que `mpv.exe` se encuentre en la carpeta antes de utilizar los ejecutables `.vbs`.

> 💡 **Conserva el archivo CMD tras la instalación.** Aunque solo ejecutarás `1_INSTALLER_MSC_First-Usage.cmd` una vez, no lo elimines. Es la única forma de recuperar `mpv.exe` si alguna vez se borra; los ejecutables `.vbs` dependen de que `mpv.exe` esté presente, por lo que no pueden recuperarlo por sí mismos.

### 2. Windows muestra una «Advertencia de seguridad» cuando ejecuto el archivo `.cmd` o `.vbs`. ¿Es normal?

Sí. Windows marca los archivos descargados con la *Marca de la Web* y pide confirmación antes de ejecutarlos, ya que no cuentan con una firma digital.

**Para continuar:**
- Haz clic en **Ejecutar**.

**Para que no te lo pregunte cada vez:**
- Antes de hacer clic en **Ejecutar**, desmarca **«Preguntar siempre antes de abrir este archivo»**. Windows recordará tu elección para ese archivo concreto.

Los archivos que activan esta advertencia son:

- `1_INSTALLER_MSC_First-Usage.cmd`
- `MPV-SW-Capture_SETUP.vbs`
- `MPV-SW-Capture_INSTALLER.vbs`

### 3. ¿Puedo ejecutar estas herramientas sin que aparezca la advertencia de seguridad?

Sí: una vez que MPV-SW-Capture esté en ejecución, ve a la sección **HERRAMIENTAS** del menú. El menú abre internamente el instalador, el programa de configuración y otras herramientas incluidas, por lo que no aparece ningún cuadro de diálogo de seguridad.

### 4. ¿Cómo instalo las herramientas adicionales (Bezel Manager, Video Manager, Stream Helper)?

Están disponibles de dos formas:

- Descarga el archivo independiente `TOOLS_*.zip` desde la [página de versiones](https://github.com/TyRaS-SW/MPV-SW-Capture/releases) y extráelo.
- O marca **«¿Instalar herramientas adicionales con Instalar/Actualizar todo?»** en el instalador y haz clic en **«Instalar/Actualizar TODO»**.

### 5. He borrado por error `mpv.exe` / `ffplay.exe` / `ffmpeg.exe`. ¿Tengo que reinstalarlo todo?

Depende del archivo que falte:

| Archivo eliminado | Método de recuperación |
|---|---|
| `ffplay.exe` o `ffmpeg.exe` | Ejecuta `MPV-SW-Capture_INSTALLER.vbs` → **Marca la casilla** → vuelve a descargar el componente que falta. |
| **`mpv.exe`** | Ejecuta de nuevo `1_INSTALLER_MSC_First-Usage.cmd`. Los ejecutables `.vbs` **no se pueden** utilizar en este caso, ya que dependen de `mpv.exe` para ejecutarse. |

> 💡 **¿Por qué conservar el archivo CMD?** Aunque solo lo necesites para la primera instalación, es la única vía de recuperación si alguna vez se elimina `mpv.exe`. Déjalo en la carpeta: casi no ocupa espacio (3 KB).

### 6. ¿Qué nuevas opciones se han añadido a la herramienta de configuración en la versión 5.1.0?

La herramienta de configuración incluye ahora dos opciones de configuración adicionales:

- **INICIO AUTOMÁTICO CON LA SIGUIENTE SALIDA DE AUDIO**: elige entre **WASAPI** o **FFPLAY** como backend predeterminado al iniciarse.
- **INICIO AUTOMÁTICO CON LA BARRA LATERAL DE VOLUMEN AL PASAR EL CURSOR**: elige si la barra lateral de volumen al pasar el cursor está activa cuando se inicia MPV-SW-Capture.

Ambas opciones se guardan en sus respectivos archivos `.txt` (`audio_mode.txt` y `hover_volume.txt`) y se aplican en el siguiente inicio.

---

## 🎨 Imágenes, shaders, marcos, recortes y formas

### 1. ¿Por qué algunos shaders indican 4K si solo estoy utilizando 1080p60?

Esos shaders realizan una mejora de la imagen. Si tienes una pantalla 4K, esto ayuda a mejorar la imagen a una resolución superior a la original (1080p).

### 2. Durante la configuración, hay una opción para activar automáticamente la combinación de shaders «👑1080p→4K Fast⚡». ¿Por qué se recomienda?

Porque es una combinación muy buena de shaders que mejora la calidad de la imagen cuando utilizas la pantalla completa a 4K, al tiempo que consume muy pocos recursos, lo que te ayudará a conseguir una imagen menos borrosa y más nítida.

### 3. He conectado una Switch y utilizo NSO, pero cuando aplico un marco o realizo un recorte en la imagen, se ve mal (mal recortada). ¿Cómo lo soluciono?

Esto suele deberse a la barra negra que NSO muestra en la parte inferior con los controles y el texto de ayuda. Tienes que desactivar esa superposición. Abre cualquier aplicación de NSO y, antes de seleccionar un juego, ve al «menú de la derecha» → «Ajustes» → «Control de pantalla» → desactiva «Mostrar controles en el juego». Una vez que esa barra haya desaparecido, el área de la imagen queda más despejada (en algunos casos, más grande) y los recortes y marcos funcionarán correctamente. Hay que hacerlo en cada aplicación de NSO.

### 4. ¿Cómo desactivo un shader, un marco o un recorte?

- **Shader**: Utiliza la opción «Limpiar shader» o, simplemente, selecciona un shader diferente (este sustituye al anterior; no se acumulan).
- **Marco**: pulsa el mismo marco que habías seleccionado antes o utiliza la opción «Borrar marcos».
- **Recorte**: pulsa la misma opción de recorte que habías seleccionado para desactivarla, o utiliza la opción «Borrar recorte».
- **Forma**: Pulsa la misma opción de forma que hayas seleccionado para desactivarla, o utiliza la opción «Borrar forma».

Si quieres borrarlo todo de una vez (por ejemplo, Los marcos son imágenes PNG de 1920x1080. Se utilizan principalmente con NSO para sustituir los marcos predeterminados por cualquier diseño que desees. La zona central es donde va la imagen del juego; solo tienes que diseñar el marco de manera que el área de juego quede bien alineada y tenga buen aspecto. Para ver un tutorial más detallado sobre cómo crear marcos y añadirlos al menú, puedes ir aquí: **[Personalización avanzada → 8. Crea tu marco personalizado](https://tyras-sw.github.io/MPV-SW-Capture/#advanced)**.

### 6. ¿Puedo añadir mis propios shaders?

Sí, puedes. Los shaders deben ser compatibles con MPV y estar en formato `.glsl`.

Debes colocarlos en la carpeta `/shaders` y editar el archivo `menu.conf` para añadir tu shader, siguiendo el mismo formato que los demás.

### 7. ¿Qué son las FORMAS? ¿Por qué tienen un submenú específico aparte?

Las FORMAS son shaders que tienen la función específica de cambiar la forma de la pantalla.

Por ejemplo, puedes cambiar la pantalla a la forma de un televisor CRT, de modo que la pantalla tenga curvatura.

¡Puedes crear cualquier combinación posible, sin límites!

Así pues, puedes combinar cualquier shader con cualquier forma en cualquier momento. Si quieres ver algunos ejemplos, entra aquí: **[MPV-SW-Capture en acción](https://tyras-sw.github.io/MPV-SW-Capture/)**.

### 8. ¿Qué es «Ajustar 16:9 completo al marco» y cómo se utiliza?

Esta opción ajusta perfectamente toda la ventana de contenido 16:9 dentro de un marco de bisel elegido. Te permite disfrutar de tu contenido 16:9 en tus marcos favoritos sin recortar la imagen.

**Cómo utilizarlo:**

1. Selecciona primero un marco de bisel (en la sección `BEZELS`).
2. A continuación, ve a `MARCOS → Ajustar 16:9 completo al marco`.

Si no tienes ningún marco seleccionado, aparecerá un mensaje pidiéndote que selecciones uno primero.

---

## 🔊 Backends de audio (WASAPI frente a FFplay)

### 1. ¿Cuál es la diferencia entre el complemento de audio WASAPI y FFplay de baja latencia?

Ambos backends capturan el audio desde tu tarjeta de captura, pero lo hacen de forma diferente:

**Complemento de audio WASAPI (predeterminado desde la v5.1.0):**
- Un complemento nativo que se carga directamente en MPV.
- Gestiona tanto el vídeo como el audio en el mismo proceso.
- Menor consumo de CPU y RAM.
- Se puede capturar de forma nativa con OBS, Discord y herramientas similares **sin necesidad de complementos de terceros**.
- Disponible en Windows 10 y 11 con la mayoría de las tarjetas de captura modernas.

**FFplay de baja latencia (opción alternativa):**
- El clásico enfoque de procesos separados: MPV gestiona el vídeo y `ffplay` gestiona el audio.
- Ambos se ejecutan en segundo plano y permanecen sincronizados.
- Requiere el complemento `win-capture-audio` para OBS para capturar el audio.
- Utilízalo si tu sistema no es compatible con el complemento WASAPI o si prefieres el proceso anterior.

### 2. ¿Cuál debería utilizar?

**Utiliza el complemento de audio WASAPI (predeterminado)** a menos que tengas una razón específica para no hacerlo. Es más rápido, más ligero y funciona de forma inmediata con OBS y Discord.

**Cambia a FFplay de baja latencia** solo si:
- Tu sistema no es compatible con el complemento WASAPI.
- Tienes problemas de audio con WASAPI que no puedes resolver.
- Ya tienes una configuración que funciona con FFplay y no quieres cambiarla.

### 3. ¿Cómo cambio de uno a otro?

- **Desde el menú**: ve a **AUDIO → MODO DE SALIDA DE AUDIO** y selecciona el backend que desees.
- **Desde la herramienta de configuración**: utiliza la opción **INICIAR AUTOMÁTICAMENTE CON LA SIGUIENTE SALIDA DE AUDIO**.

En ambos casos, debes **reiniciar MPV-SW-Capture** para que el cambio surta efecto.

### 4. ¿Cómo sé qué modo está activo actualmente?

Abre el menú y ve a **AUDIO → MODO DE SALIDA DE AUDIO**. El modo activo es aquel que tiene la marca de verificación ✓.

También puedes fijarte en el **encabezado**: la línea de audio muestra «WASAPI AUDIO» o «FFPLAY AUDIO», dependiendo del backend activo.

---

## 🔊 Audio

### 1. ¿Qué backends de audio admite MPV-SW-Capture?

A partir de la versión 5.1.0, MPV-SW-Capture es compatible con **dos backends de audio**, y puedes elegir el que mejor funcione en tu sistema:

- **Complemento de audio WASAPI** (predeterminado): un complemento nativo que se carga directamente en MPV. Gestiona tanto el vídeo como el audio en el mismo proceso, se puede capturar con OBS, Discord y otras herramientas **sin necesidad de complementos de terceros**, y consume menos CPU y RAM que el backend FFplay.
- **FFplay de baja latencia** (alternativa) — el clásico enfoque de procesos separados: MPV gestiona el vídeo y `ffplay` gestiona el audio. Utilízalo si tu sistema no es compatible con el complemento WASAPI o si prefieres el flujo de trabajo anterior.

Puedes cambiar entre ambos en cualquier momento desde **AUDIO → MODO DE SALIDA DE AUDIO** en el menú, o desde la herramienta de configuración. El cambio requiere reiniciar MPV-SW-Capture.

### 2. ¿Cómo puedo ajustar el volumen de MPV-SW-Capture de forma independiente en Windows?

Tienes varias alternativas:

- **Dentro de MPV-SW-Capture (recomendado)**:
  - Utiliza la **rueda del ratón** (`ARRIBA` para subir, `ABAJO` para bajar).
  - Utiliza las **teclas de flecha** del teclado (`ARRIBA` para subir, `ABAJO` para bajarlo).
  - Pulsa **`M`** para silenciar o activar el sonido.
  - Abre la sección **`AUDIO`** del menú para acceder a los controles deslizantes de volumen y refuerzo de audio.
- **Barra lateral de volumen al pasar el cursor**: si está activada, mueve el cursor al borde central izquierdo de la ventana y aparecerá una barra de audio flotante con ambos controles deslizantes.
- **Mezclador de volumen de Windows**:
  - **Modo WASAPI**: MPV-SW-Capture aparece en el mezclador con su propio icono. Ajusta el volumen allí si es necesario.
  - **Modo FFplay**: busca la entrada `ffplay` en el mezclador y ajusta su volumen. Utiliza esta opción solo como alternativa.

### 3. ¿Qué es el «Audio Boost» y cuándo debo utilizarlo?

**Audio Boost** es una opción que amplifica el audio de la tarjeta de captura **más allá del 100 % estándar**, hasta un **400 % (×4)**.

Es ideal para usuarios cuyo contenido capturado tiene un volumen muy bajo y necesita aumentarse más allá de los límites normales.

La encontrarás en las secciones **Opciones rápidas** y **AUDIO**, junto al control deslizante de volumen estándar.

### 4. ¿Se mantiene el «Audio Boost» entre sesiones?

Sí. El valor elegido se guarda en `data/menu/boost.txt` y se restaura automáticamente al iniciar el programa. Si lo configuras al 300 % y cierras el programa, seguirá siendo del 300 % la próxima vez que abras MPV-SW-Capture.

El **modo de salida de audio** y el **estado de la barra lateral de volumen al pasar el cursor** también se mantienen entre sesiones.

### 5. ¿Qué es el indicador de ganancia efectiva?

Una pequeña lectura situada debajo de los controles deslizantes de audio que muestra el resultado combinado de **Volumen × Boost**. Cambia de color en función del riesgo de saturación:

- **Gris** (≤ 2,0x): normal.
- **Verde** (2,0 – 3,0x): ganancia apreciable.
- **Ámbar** (≥ 3,0x): alto riesgo de saturación.

**Práctica recomendada:** deja el volumen al 100 % y sube el «Boost» poco a poco hasta que oigas la primera distorsión; a continuación, bájalo un poco. Subir el volumen no puede revertir el clipping que ya se haya producido en etapas anteriores.

### 6. ¿Dónde está el botón de silencio?

En dos sitios, ambos con la misma función:

- **En la barra de audio** (junto al porcentaje de volumen).
- **En el encabezado**: el icono verde de audio es interactivo y alterna entre silenciar y desactivar el silencio. Funciona igual que el botón de la barra de audio.

Cuando está silenciado, el icono cambia y la etiqueta de volumen pasa a **«SILENCIADO»**.

### 7. ¿Qué es la «barra lateral de volumen al pasar el cursor» y cómo la activo?

Es una barra de audio flotante que aparece al mover el cursor al borde central izquierdo de la ventana. Te permite acceder rápidamente al volumen y al refuerzo de audio sin necesidad de abrir el menú completo.

Para activarla o desactivarla: ve a **AUDIO → Barra lateral de volumen al pasar el cursor**. El estado se guarda y se restaura entre sesiones. También puedes configurar su estado predeterminado desde la herramienta **Configuración**.

---

## 📹 Grabación y capturas de pantalla

### 1. ¿Por qué el límite de grabación predeterminado es de solo 30 segundos? ¿¿No es demasiado corto?

En realidad, puedes grabar todo el tiempo que quieras. El límite predeterminado de 30 segundos se debe al funcionamiento de la grabación: mientras grabas, la herramienta necesita espacio temporal en el disco. Puede utilizar entre 7 y 10 GB (para 30 segundos de grabación; 1 minuto ocupa el doble) de espacio libre en tu disco duro para almacenar un archivo de vídeo temporal y un archivo de audio temporal. Tras la grabación, ambos se fusionan en un archivo `.mp4` comprimido sin pérdida de calidad, y los archivos temporales de entre 7 y 10 GB se eliminan automáticamente.

Si el espacio en disco no supone un problema y deseas una duración predeterminada mayor, puedes aumentar el tiempo en `MPV-SW-Capture_SETUP.vbs`.

### 2. ¿Puedo grabar menos tiempo del predeterminado que haya elegido?

Sí. Inicia la grabación desde el menú y, si vuelves a pulsar el mismo botón de grabación antes de que finalice el tiempo predeterminado, la grabación se detendrá inmediatamente en ese momento.

### 3. Cuando grabo un vídeo, ¿incluye marcos, recortes o shaders?

No. El vídeo grabado se captura como si ninguno de estos elementos estuviera activo, independientemente de lo que estés utilizando. Esto se debe a que la grabación se realiza «antes» de que se aplique cualquiera de estos efectos.

### 4. Cuando hago una captura de pantalla, ¿incluye marcos, recortes o shaders?

Sí. Las capturas de pantalla se realizan con lo que tengas activo en ese momento. Si quieres una captura de pantalla «limpia», solo tienes que desactivar los shaders (y cualquier otra superposición) antes de capturarla.

### 5. ¿Dónde se almacenan los vídeos y las capturas de pantalla?

Se guardan en las carpetas `_record` y `_screenshots`, situadas en la misma carpeta donde hayas instalado MPV‑SW‑Capture.

No es necesario crearlas, ya que el software las crea automáticamente tras realizar una captura de pantalla o grabar un vídeo.

Si, por alguna extraña razón, no puedes grabar vídeos ni realizar capturas de pantalla, y no dispones de estas carpetas, puedes crearlas manualmente.

### 6. Al grabar un vídeo, veo un contador con el tiempo que queda para terminar la grabación. ¿Es normal?

Sí, es normal. Así puedes comprobar cuánto tiempo te queda para grabar el vídeo.

---

## 🧰 Menú, ventana y controles

### 1. ¿Cómo abro el menú al iniciar el programa?

Basta con hacer clic con el botón derecho del ratón en la ventana y se abrirá el menú. También puedes pulsar la tecla `ESC` del teclado, pero asegúrate de que el ratón se encuentre sobre la ventana de MPV‑SW‑Capture y de que el programa tenga el foco.

### 2. ¿Cómo cierro el programa? No veo ningún botón «X» para cerrarlo.

Para cerrar MPV‑SW‑Capture, abre el menú y selecciona la opción `❌ CERRAR MPV-SW-Capture`. También puedes hacer clic en el botón **X** en el encabezado del menú, lo que cierra el menú pero no el programa. La **X** del pie de página (zona inferior izquierda) cierra todo el programa.

### 3. ¿Por qué veo una marca de verificación junto a algunas opciones del menú? ¿Qué significa el borde resaltado?

Se trata de dos indicadores visuales **independientes**:

- **✓ Marca de verificación** (parte inferior derecha de una ficha): significa que la opción está **activa actualmente**.
- **Borde resaltado** (contorno de color alrededor de una tarjeta): significa que **el cursor se encuentra actualmente sobre esa tarjeta**.

Se mueven de forma independiente. El borde sigue al cursor (del teclado o del ratón), mientras que la marca de verificación permanece en la opción que esté realmente activa. De esta forma, siempre puedes saber «dónde te encuentras» y «qué está activado» de un solo vistazo.

### 4. ¿Qué es la opción «Info Stream» y cómo la oculto una vez que está activada?

«Info Stream» muestra estadísticas sobre la transmisión actual (resolución, uso de recursos, etc.). Resulta útil cuando quieres comprobar qué está sucediendo internamente. Para ocultarlo, basta con volver a seleccionar la opción «Info Stream» y la superposición desaparecerá.

### 5. En el menú hay muchas opciones en el apartado VENTANA. ¿Para qué sirven?

Estas opciones te permiten personalizar la ventana de MPV‑SW‑Capture a tu gusto.

- Puedes cambiar el tamaño de 0,5x a 2,0x, o pasar a pantalla completa. También puedes establecer una posición específica para la ventana.
- «Siempre visible» mantiene la ventana por encima de otras ventanas (pulsa de nuevo para desactivarla).
- «Ampliar ventana» te permite ampliar la imagen actual a una relación de aspecto más ancha (por ejemplo, de 16:9 a 21:9, o de 4:3 a 16:9). Esto resulta especialmente útil con NSO: si tienes un juego en formato 4:3, puedes aplicar un recorte y, a continuación, utilizar «Ampliar ventana» para llenar un área de 16:9.
- «Modo mini» reduce la ventana a un tamaño de 0,3x y la desplaza a la esquina inferior derecha de la pantalla.

Además, estos modos de ventana resultan especialmente útiles para los streamers:

- ****Modo Mini**: reduce la ventana al 30 % y la coloca en la esquina inferior derecha; es perfecto para mantener una pequeña vista previa en pantalla mientras realizas otras tareas.
- **Pantalla completa**: te ofrece una visión envolvente con mínimas distracciones.
- **Ventana ampliada**: te permite ajustar la relación de aspecto (p. ej., 4:3 → 16:9) para llenar la pantalla o el área de captura.
- **Siempre visible**: mantiene la ventana por encima de otras aplicaciones, para que nunca pierdas de vista tu juego mientras retransmites.

### 6. ¿Cómo puedo cambiar el volumen de MPV‑SW‑Capture de forma independiente en Windows?

Consulta la sección **🔊 Audio** más arriba (pregunta 2).

### 7. Dices que hay dos programas, uno para el vídeo y otro para el audio. ¿Qué ocurre con el audio si cierro MPV‑SW‑Capture?

> 💡 **Nota:** A partir de la versión 5.1.0, el backend de audio predeterminado es el **WASAPI Audio Plugin**, que se ejecuta íntegramente dentro de MPV; no hay ningún proceso de audio independiente. La respuesta que figura a continuación se aplica al modo **FFplay Low Latency**.

En el modo FFplay, si cierras la ventana de MPV‑SW‑Capture, el audio también se cierra. Ambas partes están diseñadas para funcionar juntas, por lo que, cuando se cierra MPV‑SW‑Capture, el proceso de audio también se detiene y se cierra por completo.

### 8. ¿Qué ocurre si utilizo shaders, marcos, formas, recortes o cualquier otra opción y cierro el programa?

La mayoría de las opciones visuales (shaders, marcos, formas, recortes) **no se guardan**: solo permanecen activas hasta que cierres MPV-SW-Capture. Si lo vuelves a abrir, volverán a los valores predeterminados.

**Los siguientes ajustes SÍ se conservan entre sesiones:**

- **Amplificación de audio**: el porcentaje que hayas seleccionado.
- **Modo de salida de audio**: WASAPI o FFplay.
- **Barra lateral de volumen al pasar el cursor**: activada o desactivada.
- **Cambiar a perfil ICC automático**: activado o desactivado.

Las demás opciones que se conservan son las que puedes seleccionar en **Configuración**, **Instalador** y **Herramientas**.

### 9. En MPV-SW-Capture hay que usar el ratón para controlar el MENÚ, ¿verdad? Pero, ¿hay algún atajo de teclado y ratón para algunas funciones?

Sí, hay algunas funciones que puedes utilizar con el teclado y el ratón:

**a) Ratón:**

- **_Pantalla completa_:** Si haces doble clic en la pantalla, puedes alternar entre **activar** y **desactivar** la pantalla completa.
- **_Acceso al MENÚ_:** Haz clic con el botón derecho del ratón en la pantalla para acceder al menú.
- **_Controlar el audio_:** Utiliza la rueda del ratón `ARRIBA` para subir el volumen y `ABAJO` para bajarlo. Puedes seguir girando la rueda hasta encontrar el volumen deseado.

**b) Teclado:**

- **_Acceder al MENÚ_:** Pulsa `ESC` para acceder al menú.
- **_Navegar por el MENÚ_:** También puedes utilizar las teclas `ARRIBA`, `ABAJO`, `IZQUIERDA` y `DERECHA` del teclado para navegar por el MENÚ.
- **_Aplicar opción_:** Pulsa `ENTER` para activar la opción resaltada.
- **_Cambiar de sección_:** Pulsa `TAB` para saltar a la siguiente sección, o `PGUP`/`PGDN` para desplazarte entre secciones.
- **_Controlar el audio_:** Utiliza la tecla `ARRIBA` del teclado para subir el volumen en +10, y la tecla `ABAJO` para bajarlo en -10.
  - La tecla `M` sirve para silenciar el sonido y, al pulsarla de nuevo, para reactivarlo.

### 10. ¿Cómo puedo comprobar qué versión de MPV-SW-Capture tengo instalada?

Hay dos formas:

1. Visita la [página oficial de versiones](https://github.com/TyRaS-SW/MPV-SW-Capture/releases) para ver la última versión disponible.
2. Abre MPV-SW-Capture, ve al menú **`AYUDA` → `Comprobar la última versión de MSC`**. El programa te indicará si tienes la última versión o si hay una actualización disponible.

### 11. ¿Qué novedades presenta el menú en comparación con las versiones anteriores?

El antiguo menú basado en listas se sustituyó por una interfaz gráfica al estilo de los televisores inteligentes, desarrollada con ASS (Advanced SubStation Alpha). Desde entonces, no ha dejado de evolucionar. Las características actuales incluyen:

- Navegación por secciones con una barra lateral visual e iconos.
- Tarjetas específicas para cada opción, con indicadores de estado activo.
- Controladores de audio arrastrables con lectura en tiempo real de la ganancia efectiva.
- **Selector de idioma en el menú**: cambia el idioma de la interfaz sobre la marcha.
- **Acciones rápidas en la cabecera**: botones en los que se puede hacer clic para «HACER CAPTURA DE PANTALLA», «GRABAR VÍDEO», el indicador de idioma («EN»/«ES»/«JP») y el botón de cierre.
- Sección **Opciones rápidas** para acceder rápidamente a las tareas más habituales.
- **Secciones reestructuradas**: la antigua sección «OTROS» se ha dividido en dos entradas independientes: **AYUDA** y **HERRAMIENTAS**.
- **Descripciones de las secciones**: ahora cada sección del menú muestra un breve texto explicativo en la parte inferior.
- **Marcos reestructurados con pestañas**: **Todos**, **NSO** (con subpestañas por consola: NES, SNES, GB, GBA, N64) y **PERSONAL** (aparece automáticamente al crear marcos que no sean NSO).
- **Iconos personalizados** para la mayoría de las opciones del menú, lo que da a la interfaz un aspecto más limpio.
- Selector de **modo de salida de audio** (WASAPI / FFplay) en la sección **AUDIO**.
- **Barra lateral de volumen al pasar el cursor** en la sección **AUDIO**.
- Se ha añadido **Cambiar a perfil ICC automático** a **Opciones rápidas → AJUSTES**.
- **Botón de silencio** en la barra de audio e icono de audio en el que se puede hacer clic en el encabezado.

### 12. ¿Por qué a veces el menú se cierra y se vuelve a abrir automáticamente?

Al aplicar una tarjeta en **Shaders**, **Formas**, **Recortes** o **Marcos**, el menú se oculta y se vuelve a abrir 3 segundos después. Esto es intencionado: te permite ver el efecto en el vídeo sin perder el menú a mano.

Las opciones de **Audio Boost** funcionan de la misma manera, por lo que el control deslizante refleja el nuevo valor cuando se vuelve a abrir el menú.

### 13. ¿Cómo cambio el idioma sin salir de MPV?

Haz clic en el **icono de idioma** del encabezado (muestra `EN`, `ES`, `JP`, …) o en el botón equivalente en **Opciones rápidas → CONFIGURACIÓN**. Cada clic cambia al siguiente idioma disponible.

El cambio se aplica **al instante**; no es necesario cerrar y volver a abrir MPV-SW-Capture.

### 14. ¿Para qué sirve «CLEAN ALL»?

«CLEAN ALL» realiza un restablecimiento completo. Borra todos los shaders, formas, recortes y marcos, y además restablece:

- Tamaño de la ventana → **1,0x**
- Posición de la ventana → **centrada**
- Rotación → **0°**
- Borde → **desactivado**
- Barra de título → **desactivada**
- Siempre encima → **desactivado**
- Anulación de la relación de aspecto → **16:9**
- Eliminación de bandas → **desactivada**

Puedes activarlo desde el pie de página de la barra lateral o desde **Opciones rápidas → CAPTURA → Limpiar todo**.

---

## 🧰 Herramientas

### 🌐 Transmite con OBS

> **⚠️ IMPORTANTE — lee esto primero:**
>
> **El Stream Helper solo es necesario si utilizas el modo de audio `FFplay Low Latency`.**
>
> Si utilizas el modo predeterminado **`WASAPI Audio Plugin`**, **NO necesitas el Stream Helper**. OBS, Discord y otras herramientas de captura pueden capturar el audio de MPV-SW-Capture de forma nativa, sin necesidad de complementos de terceros.
>
> Utiliza esta herramienta solo si:
> - Has cambiado al modo **`FFplay Low Latency`**, **y**
> - Quieres retransmitir o grabar MPV-SW-Capture a través de OBS con el audio del juego.

#### 1. ¿Qué es el Stream Manager y para qué sirve?

El Stream Manager (MSCGUI) es una herramienta gráfica del paquete `TOOLS_*.zip` que te ayuda a configurar OBS Studio para capturar MPV-SW-Capture. Automatiza la instalación del complemento `win-capture-audio`, configura colecciones de escenas, añade las fuentes necesarias (Captura de ventana + Captura de audio) e incluye un «Modo Streamer» para ocultar los mensajes OSD. También te permite cambiar entre los modos **Instalado** y **Portátil** de OBS.

#### 2. ¿Por qué se necesitan derechos de administrador para instalar el complemento `win-capture-audio` en OBS (modo «Instalado»)?

Cuando OBS está instalado en una carpeta del sistema protegida, como `C:\Archivos de programa`, escribir archivos en su directorio de instalación requiere permisos elevados. El Stream Manager lo detectará y te pedirá que lo reinicies como administrador. Por el contrario, si utilizas la versión **portátil** de OBS (instalada en cualquier lugar fuera de `Archivos de programa`), no se necesitan permisos especiales.

#### 3. ¿Cuál es la diferencia entre OBS instalado y OBS portátil en el contexto de MPV-SW-Capture?

- OBS **instalado** es la instalación estándar en `Archivos de programa`. Es la más habitual, pero puede requerir derechos de administrador para modificar o instalar complementos.
- El OBS **portátil** es una versión autónoma que puedes colocar en cualquier lugar (por ejemplo, en una memoria USB). No requiere derechos de administrador y te permite llevar tu configuración contigo. Sin embargo, debes descargar la versión ZIP y extraerla manualmente. El Stream Manager puede ayudarte a descargar y configurar ambos modos.

#### 4. ¿Cómo puedo utilizar MPV-SW-Capture con OBS de forma más sencilla?

Depende de tu modo de audio:

- **Complemento de audio WASAPI (predeterminado)**: OBS captura el audio de MPV-SW-Capture de forma **nativa**. Solo tienes que añadir una fuente de **Captura de ventana** que apunte a `mpv.exe`: no se necesitan complementos, ni Stream Helper, ni ninguna configuración adicional.
- **FFplay de baja latencia**: utiliza el **Stream Manager** (del paquete `TOOLS_*.zip`). Automatiza todo el proceso: instala el complemento `win-capture-audio`, crea una colección de escenas, o añade las fuentes necesarias a una colección ya existente.

Para obtener guías detalladas paso a paso, consulta:

- [Personalización avanzada](https://tyras-sw.github.io/MPV-SW-Capture/#advanced)

#### 5. ¿Qué es la opción «Ocultar mensajes OSD» y cómo afecta a la grabación?

La opción **«Ocultar mensajes OSD»** se encuentra en el menú, en **AYUDA → Ocultar mensajes OSD**. Cuando está activada, oculta todos los mensajes en pantalla que aparecen al seleccionar cualquier opción (por ejemplo, cambios de shader, ajustes de recorte, etc.). Esto es ideal para streamers que no quieren que estas notificaciones aparezcan en su retransmisión, o para usuarios que simplemente prefieren una interfaz más limpia.

**Importante:** Por razones de seguridad, la **`GRABAR VÍDEO`** queda completamente desactivada cuando está activa la opción `Ocultar mensajes OSD`. Solo podrás utilizar la función de grabación cuando esta opción esté desactivada. De este modo, te aseguras de estar al tanto del estado de la grabación y evitas grabar accidentalmente sin recibir ninguna indicación visual.

### 🖼 Bezel Manager

#### 1. ¿Qué es el Bezel Manager y para qué sirve?

El Gestor de marcos es una herramienta gráfica del paquete `TOOLS_*.zip` que te permite gestionar y personalizar los marcos (bordes decorativos) para MPV-SW-Capture. Con ella, puedes:

- Previsualizar los marcos antes de aplicarlos.
- Añadir nuevos marcos al menú (colocando tus imágenes PNG en la carpeta correspondiente y actualizando la configuración).
- Eliminar o reorganizar los marcos existentes.

Esta herramienta simplifica el proceso de creación y uso de marcos personalizados sin necesidad de editar manualmente los archivos de configuración. Para obtener una guía detallada, consulta aquí: **[Personalización avanzada → 8. Crea tu marco personalizado](https://tyras-sw.github.io/MPV-SW-Capture/#advanced)**.

### 🎞 Gestor de vídeos

#### 1. ¿Qué es el Gestor de vídeo y para qué sirve?

El Gestor de vídeo es una herramienta gráfica del paquete `TOOLS_*.zip` que te permite ajustar parámetros avanzados de vídeo para MPV-SW-Capture sin tener que editar directamente el archivo `mpv.conf`. Puedes modificar ajustes como:

- Latencia de vídeo
- Tamaño del búfer de audio
- Decodificación por hardware (`hwdec`)
- Opciones de renderizado por GPU (`vo=gpu`)
- Y otras opciones relacionadas con el rendimiento

Esta herramienta resulta especialmente útil para los usuarios que desean ajustar con precisión el rendimiento y la calidad, pero prefieren una interfaz intuitiva en lugar de los archivos de configuración manuales.

---

## 📋 Idioma

### 1. ¿Qué idiomas están disponibles?

Actualmente: **inglés** (`en`), **español** (`es`) y **japonés** (`jp`).

La lista se lee desde `scripts/lang/language_list.dat`, lo que significa que **puedes añadir cualquier idioma que desees**: el sistema es totalmente extensible. Si te interesa añadir uno nuevo, consulta la pregunta 5.

### 2. ¿Dónde cambio el idioma: en el menú o en «Configuración»?

Ambas opciones funcionan:

- **En «Configuración»**: selecciona el idioma de la lista y pulsa **«Aplicar idioma»»**.
- **En el menú**: haz clic en el **icono de idioma** (`EN`/`ES`/`JP`) de la cabecera, o en el botón de **Opciones rápidas → CONFIGURACIÓN**. Cada clic cambia al siguiente idioma disponible.

El cambio se aplica **al instante** en el menú; no es necesario cerrar MPV-SW-Capture. Los cambios realizados en «Configuración» requieren reiniciar el programa para que surtan efecto.

### 3. ¿Qué se traduce?

El selector de idioma traduce los siguientes elementos:

- El **menú** (secciones, pestañas, etiquetas de las tarjetas, pie de página, encabezado).
- **Mensajes de MPV-SW-Capture** (notificaciones OSD, mensajes de estado, mensajes de error).

> ⚠️ **Nota sobre las interfaces gráficas de «Configuración», «Instalador» y «Herramientas»**: estas herramientas tienen su **propio soporte de idiomas codificado** y **no** se traducen mediante el selector de idioma del menú. Actualmente solo admiten **inglés** y **español**. Consulta la pregunta 4 para obtener más detalles.

### 4. ¿Se mantiene la selección de idioma en todos los programas (Configuración, Instalador, Herramientas)?

**Respuesta breve:** Sí, pero hay **dos sistemas de idioma independientes**: uno para las interfaces gráficas y otro para el menú.

**Sistema 1 — Todas las interfaces gráficas comparten UNA misma preferencia:**

- La Configuración, el Instalador, el Gestor de marcos, el Gestor de vídeo y el Gestor de Transmisión **leen y escriben en el mismo archivo de idioma**.
- Esto significa que siempre muestran el mismo idioma entre sí. Si configuras la Configuración en español, el Instalador también estará en español, y así sucesivamente.
- Estas interfaces gráficas solo admiten actualmente **inglés y español** (el japonés no está disponible en ellas).

**Sistema 2 — El menú tiene su propia preferencia independiente:**

- El menú del juego utiliza un sistema diferente, basado en `scripts/lang/language_list.dat`.
- Actualmente admite **inglés, español y japonés**.
- Cambiar el idioma de la interfaz gráfica de usuario **no** afecta al menú, y cambiar el idioma del menú **no** afecta a las interfaces gráficas de usuario.

**Tabla resumen:**

| Componente | Idiomas disponibles | Compartido con |
|---|---|---|
| **Todas las interfaces gráficas** (Configuración, Instalador, Herramientas) | EN, ES | Entre sí (una opción compartida) |
| **Menú** (en MPV-SW-Capture) | EN, ES, JP + cualquier otro que añadas | Nada más — totalmente independiente |

### 5. ¿Cómo añado un nuevo idioma?

MPV-SW-Capture admite la incorporación de cualquier idioma, siempre que alguien proporcione los archivos de traducción. El proceso es sencillo y no requiere ningún cambio en el código.

**1. Registra el código del idioma**

Abre `scripts/lang/language_list.dat` y añade el código de dos letras de tu idioma en una línea aparte (por ejemplo, `fr` para francés, `de` para alemán, `pt` para portugués).

**2. Crea los 3 archivos de traducción**

Tienes que crear **3 archivos** dentro de `scripts/lang/`. La forma más sencilla es **copiar un archivo existente y traducir solo la parte derecha de cada línea**:

| Archivo a crear | Copia este archivo como punto de partida | Qué se traduce |
|---|---|---|
| `MENUMSG_<lang>.dat` | `MENUMSG_es.dat` | Etiquetas de menú (nombres de secciones, etiquetas de tarjetas, información sobre herramientas) |
| `ASMENU_<lang>.dat` | `ASMENU_en.dat` | Cadenas internas del menú (deslizadores, botones, pie de página) |
| `OSDMSG_<lang>.dat` | `OSDMSG_en.dat` | Mensajes en pantalla (notificaciones, errores, estado) |

Sustituye `<lang>` por el código de tu idioma del paso 1. Por ejemplo, para el francés crearías `MENUMSG_fr.dat`, `ASMENU_fr.dat` y `OSDMSG_fr.dat`.

> ⚠️ **Importante: traduce solo la parte DERECHA de cada línea.**
>
> Todas las líneas de estos archivos tienen el formato `izquierda=derecha`. La **parte izquierda es la clave original en inglés** y **no** debe modificarse, ya que es así como el programa encuentra la traducción. Traduce únicamente la **parte derecha**, después del `=`.
>
> **Ejemplo** (en `MENUMSG_fr.dat`):
> ```
> Take Screenshot=Prendre une Capture d'Écran
> ```
> Fíjate en que `Take Screenshot=` se mantiene exactamente igual. Solo se traduce el texto que aparece después de `=`.

**3. Reinicia mpv**

Cierra y vuelve a abrir MPV-SW-Capture. Tu idioma aparecerá ahora en el selector de idiomas (tanto en el botón de la cabecera del menú como en Configuración → Aplicar idioma).

> 💡 **Consejo**: No es necesario traducir todas las líneas. Cualquier clave sin traducir se mostrará automáticamente en inglés, por lo que puedes empezar con una traducción parcial e ir mejorándola con el tiempo.

---

## 📋 Solicitudes, incidencias y comentarios

### 1. Tengo algunos comentarios, incidencias o solicitudes sobre este proyecto. ¿Dónde puedo compartir mi opinión en GitHub?

- **Comentarios**: [Debates](https://github.com/TyRaS-SW/MPV-SW-Capture/discussions)
- **Incidencias**: [Incidencias](https://github.com/TyRaS-SW/MPV-SW-Capture/issues)
- **Ideas / Peticiones**: [Ideas](https://github.com/TyRaS-SW/MPV-SW-Capture/discussions/categories/ideas)

### 2. ¿Puedo preguntar en otra plataforma como Discord?

¡Sí! Puedes compartir comentarios, incidencias, solicitudes y mucho más en el Discord oficial: **[Discord oficial de MPV-SW-Capture](https://discord.gg/PaVutUUK9U)**.

---

## 📋 Solución de problemas

### 1. He intentado abrir `MPV.exe` (o su acceso directo), pero no pasa nada. ¡No se abre la pantalla! ¿Qué puedo hacer?

Las tarjetas de captura se tratan como cámaras en Windows.

Además, si abres tu tarjeta de captura con otro programa, no podrás utilizarla en MPV-SW-Capture hasta que cierres primero ese otro programa.

Por ejemplo, si abres la cámara en Configuración de Windows → Bluetooth y dispositivos → Cámaras, y seleccionas tu tarjeta de captura como cámara, no podrás utilizar MPV-SW-Capture hasta que la cierres desde allí.

Esta es una limitación que tienen las tarjetas de captura por defecto.

Si la ventana aparece un instante y luego se cierra, suele deberse a que el dispositivo de captura no está configurado correctamente. Ejecuta `MPV-SW-Capture_SETUP.vbs`, selecciona tu tarjeta de captura (vídeo y audio), haz clic en «Guardar y salir» y, a continuación, vuelve a iniciar el programa.

### 2. ¿Puedo abrir varias ventanas con `MPV.exe`?

No. `MPV.exe` solo admite una ventana a la vez. Al igual que en la respuesta anterior, la tarjeta de captura actúa como un único dispositivo, por lo que esto es normal.

### 3. Tengo más de una tarjeta de captura conectada. ¿Cómo puedo cambiar la tarjeta de captura predeterminada?

En la configuración, pulsa **«Escanear dispositivo»** y elige la otra tarjeta de captura (vídeo y audio) que desees utilizar.

Debes cerrar y volver a abrir MPV-SW-Capture para que se apliquen los cambios.

### 4. He ejecutado `MPV-SW-Capture_INSTALLER.vbs` y no ha pasado nada. ¿Qué ha pasado?

Lo más probable es que se trate de una instalación nueva y que `mpv.exe` aún no exista. En una instalación nueva, debes ejecutar primero **`1_INSTALLER_MSC_First-Usage.cmd`**. Consulta la sección **🛠️ Instalación y lanzadores** para obtener más detalles.

### 5. He cambiado al modo WASAPI, pero no oigo ningún sonido. ¿Qué puedo hacer?

En primer lugar, comprueba que realmente has reiniciado MPV-SW-Capture tras cambiar de modo; el cambio solo se aplica en el siguiente inicio.

Si tras reiniciar sigues sin tener sonido:

- Comprueba que el dispositivo de audio correcto esté seleccionado en la herramienta **Configuración**.
- Comprueba que MPV-SW-Capture no esté silenciado en el **Mezclador de volumen de Windows**. En el modo WASAPI, MPV-SW-Capture aparece en el mezclador con su propio icono (no como `ffplay`).
- Si el problema persiste, vuelve al modo **FFplay Low Latency** desde **AUDIO → MODO DE SALIDA DE AUDIO**. Es posible que tu sistema no sea totalmente compatible con el complemento WASAPI.