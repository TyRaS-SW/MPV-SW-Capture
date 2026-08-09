# ❓ Preguntas frecuentes

## 🎮 Generalidades y concepto

### 1. ¿Por qué utilizar MPV para jugar a Switch, 2, PS, XB, Retro o cualquier otra consola compatible con HDMI?

MPV es un reproductor de vídeo muy potente y rápido cuando se configura correctamente. Además, te permite añadir shaders, marcos, recortes y muchas otras opciones, lo que lo convierte en algo más que «un simple reproductor» y lo transforma en una herramienta que puedes personalizar realmente para jugar en consola.

### 2. ¿Por qué MPV y no otro programa?

Existen otros programas que permiten grabar vídeo y hacer algo similar a este proyecto, pero suelen ser más limitados y no ofrecen el mismo nivel de personalización que ofrece MPV-SW-Capture como complemento de MPV. Además, la mayoría tiende a aumentar el retraso, lo que hace que la experiencia sea insoportable.

---

## 🧩 Hardware y tarjetas de captura

### 1. ¿Por qué necesito una tarjeta de captura compatible con 1080p60?

Porque 1080p60 es el estándar de calidad actual para la mayoría de las consolas y dispositivos de captura modernos. Fijarse como objetivo 1080p60 garantiza una buena calidad de imagen y una experiencia de juego fluida.

### 2. ¿Por qué recomendáis el USB 3.0? ¿Qué pasa si utilizo el USB 2.0?

Se recomienda utilizar USB 3.0, ya que ofrece un mayor ancho de banda, lo que se traduce en una mejor calidad de imagen y un rendimiento más estable para vídeos de alta resolución y alta frecuencia de fotogramas. También puedes utilizar USB 2.0, pero la calidad y la estabilidad pueden verse afectadas. Si no tienes otra opción, puedes utilizarlo de todos modos, pero ten en cuenta esta limitación.

### 3. ¿Puedo utilizar cualquier tarjeta de captura USB-HDMI?

En teoría, sí. Sin embargo, para este proyecto se recomienda una tarjeta de captura que admita 1080p60 y cuente con salida en bucle (entrada HDMI + salida HDMI). Hay opciones relativamente económicas y fáciles de encontrar. Un ejemplo que puedes buscar es: «Captura de vídeo HD 4K Ultra HD USB 3.0 (MS 2131)». Estos dispositivos admiten entradas de hasta 4K60 y emiten en 1080p60. Por ejemplo, si conectas una consola compatible con 4K60, la tarjeta de captura la aceptará, pero la imagen final utilizada por MPV-SW-Capture será de 1080p60.

### 4. ¿Qué hay de las tarjetas de captura tipo memoria USB que solo tienen HDMI y USB, y que suelen admitir hasta 720p60?

En principio deberían funcionar, pero no se han probado con este proyecto. Si pruebas alguna y funciona (o no), por favor, comparte tus resultados en el proyecto para que otros puedan beneficiarse de esa información.

### 5. Si tengo una tarjeta de captura USB 3.0 capaz de generar una señal superior a 1080p60 (como 1440p60 o 4K60), ¿funcionará?

Este escenario tampoco se ha probado, pero, en principio, debería funcionar sin problemas importantes. Si lo pruebas, por favor, comparte tus resultados.

### 6. Tengo una consola que solo admite una resolución de hasta 720p en lugar de 1080p, ¿funcionará?

Sí, esto funcionará perfectamente. Por ejemplo, se ha probado con una salida exclusiva de 720p y el resultado fue una mejora automática de la resolución a 1080p. Con esto, todo funcionó correctamente, incluso los biseles, los recortes y los sombreadores.

Además, se ha probado con consolas más antiguas que admiten una resolución inferior a 720p (480p), conectadas mediante un adaptador de AV a HDMI, y el resultado también es una mejora de la resolución a 1080p.

---

## 🎮 Software

### 1. ¿Qué programas necesitamos para utilizar MPV-SW-Capture?

Se necesitan tres programas: `MPV` es el principal. También se necesitan `ffplay` y `ffmpeg` para que funcione.

Por eso hay que descargarlo y ya se explica en las instrucciones.

### 2. He seguido las instrucciones y he configurado correctamente mi `MPV-SW-Capture`. Sin embargo, me he dado cuenta de que los tres programas tienen ahora una versión más reciente que la que utilizaba antes. ¿Puedo actualizarlos sin que el MPV-SW-Capture deje de funcionar?

Si te refieres a «MPV», «ffplay» y «ffmpeg», sí, puedes actualizar o sustituir estos tres programas sin ningún problema. Solo tienes que descargar sus nuevas versiones y sustituir las antiguas por las más recientes.

Eso es todo lo que tienes que hacer. Además, siempre es recomendable tener la versión más reciente.

No obstante, si detectas algún problema, puedes probar con versiones anteriores. Si eso llegara a ocurrir, por favor, describe el problema en **[Issues](https://github.com/TyRaS-SW/MPV-SW-Capture/issues)**, para que podamos comprobarlo y solucionarlo.

Pero, si te refieres al propio MPV-SW-Capture, lo mejor es simplemente sustituir todos los archivos.

### 3. ¿Para qué sirve este archivo, `Installer_MPV-SW-Capture.exe`?

`Installer_MPV-SW-Capture.exe`: es la nueva forma de descargar e instalar o actualizar `MPV-SW-Capture`, `ffplay`, `ffmpeg` y `mpv`. Al utilizar el instalador, el programa instala automáticamente todos los archivos necesarios. Esto significa que podrás actualizar futuras versiones de MPV-SW-Capture desde el propio instalador. Además, podrás actualizar todos los demás programas necesarios a sus últimas versiones sin necesidad de descargarlos manualmente.

Aún puedes actualizar siguiendo el método anterior. Las instrucciones para ello se encuentran aquí: **[Instalación MANUAL](https://github.com/TyRaS-SW/MPV-SW-Capture/wiki/MANUAL-Installation-Guide)**

### 4. Estaba utilizando `Installer_MPV-SW-Capture.exe` y ahora no puedo actualizar. ¿A qué se debe esto?

Esto se debe a una limitación de GitHub. Si realizas muchas operaciones, GitHub te impide volver a descargar hasta que haya transcurrido una hora. Solo puedes tener este problema si descargas, actualizas, etc., en cantidades excesivas.

Dado que solo estás actualizando o instalando, esto no debería suponer ningún problema. No obstante, si te encuentras con este problema, espera una hora o realiza una instalación manual.

Como solución provisional, puedes realizar una **[instalación manual](https://github.com/TyRaS-SW/MPV-SW-Capture/wiki/MANUAL-Installation-Guide)** mientras esperas, o simplemente esperar una hora y volver a intentarlo. GitHub impone este límite para evitar abusos.

### 5. ¿Cómo funcionan los números de actualización en MPV-SW-Capture?

Cuando ves una actualización, aparecen tres números, separados por puntos. Estos se representan como `X`, `Y` y `Z`:

v`X`.`Y`.`Z`.

- `X` = Actualización muy importante que hay que instalar.
- `Y` = Actualización importante.
- `Z` = Parche menor o pequeña novedad añadida.

---

## 🎨 Imágenes, sombreadores, biseles, recortes y formas

### 1. ¿Por qué algunos shaders indican 4K si solo estoy utilizando 1080p a 60?

Esos shaders se encargan de la extrapolación y la mejora de la imagen. Si tienes una pantalla 4K, la imagen se verá mejor en 4K aunque la señal de entrada sea de 1080p a 60 Hz. Esto ayuda a mejorar la imagen a una resolución superior a la original (1080p).

### 2. Durante la configuración, hay una opción para activar automáticamente la combinación de shaders «👑1080p→4K Fast⚡». ¿Por qué se recomienda?

Porque es una combinación muy buena de shaders que mejoran la calidad de la imagen cuando se utiliza la pantalla completa a 4K, al tiempo que consumen muy pocos recursos. Dado que la resolución máxima es de 1080p y se amplía la imagen por encima de esa resolución, hasta 4K, esto ayudará a obtener una imagen menos borrosa y más nítida.

### 3. He conectado una Switch y utilizo NSO, pero cuando aplico un bisel o recorto la imagen, se ve mal (mal recortada). ¿Cómo puedo solucionarlo?

Esto suele deberse a la barra negra que muestra NSO en la parte inferior con los controles y el texto de ayuda. Tienes que desactivar esa superposición. Abre cualquier aplicación de NSO y, antes de seleccionar un juego, ve al menú de la derecha → Ajustes → Visualización de controles → desactiva «Mostrar controles en el juego». Una vez que desaparezca esa barra, el área de imagen quedará más despejada (en algunos casos, más grande) y los recortes y los marcos funcionarán correctamente. Hay que hacerlo en cada aplicación de NSO.

### 4. ¿Cómo desactivo un shader, un bisel o un recorte?

- **Shader**: Utiliza la opción «Borrar shader» o, simplemente, selecciona un shader diferente (este sustituirá al anterior; no se superponen).
- **Bisel**: Pulsa el mismo bisel que habías seleccionado anteriormente o utiliza la opción «Borrar biseles».
- **Recorte**: Pulsa la misma opción de recorte que habías seleccionado para desactivarla, o utiliza la opción «Borrar recorte».
- **Forma**: Pulsa la misma opción de forma que habías seleccionado para desactivarla, o utiliza la opción «Borrar forma».

Si quieres borrarlo todo de una vez (por ejemplo, el borde, el sombreador y la forma), puedes utilizar la opción «Borrar TODO».

### 5. Quiero crear mis propios biseles, pero no sé cómo. ¿Cómo lo hago?

Los marcos son imágenes PNG de 1920x1080. Se utilizan principalmente con NSO para sustituir los bordes predeterminados por el diseño que desees. La zona central es donde se coloca la imagen del juego; solo tienes que diseñar el marco de forma que el área de juego quede bien alineada y tenga un buen aspecto. Si quieres ver un tutorial más detallado sobre cómo crear marcos y añadirlos al menú, puedes consultar esta página: [Marcos personalizados](https://github.com/TyRaS-SW/MPV-SW-Capture/wiki/Custom-Bezels)

### 6. ¿Puedo añadir mis propios shaders?

Sí, puedes. Los shaders deben ser compatibles con MPV y estar en formato .glsl.

Debes colocarlos en la carpeta /shaders y editar el archivo menu.conf para añadir tu shader, siguiendo el mismo formato que los demás.

### 7. ¿Qué son las «FORMAS»? ¿Por qué tienen un submenú específico aparte?

Los SHAPES son shaders que tienen la función específica de modificar la forma de la pantalla.

Por ejemplo, puedes cambiar la forma de la pantalla para que se parezca a la de un televisor CRT, de modo que la pantalla tenga una curvatura.

En una versión antigua de MPV-SW-Capture, algunos shaders cambian el aspecto a estilo retro y, al mismo tiempo, modifican la forma de la pantalla.

Sin embargo, la forma era específica de ese shader.

Ahora bien, esto está separado, ya que puedes cambiar la forma y seleccionar el shader que quieras.

¡Puedes crear cualquier combinación que se te ocurra, sin límites!

Todos los shaders antiguos que tenían una forma concreta ahora son «planos». Así pues, puedes elegir entre tener el shader «plano» o combinarlo con una forma; tú decides.

---

## 📹 Grabaciones y capturas de pantalla

### 1. ¿Por qué el límite de grabación predeterminado es de solo 30 segundos? ¿No es demasiado corto?

En realidad, puedes grabar todo el tiempo que quieras. El límite predeterminado de 30 segundos se debe al funcionamiento de la grabación: mientras reproduces, la herramienta necesita espacio temporal en el disco. Puede utilizar entre 7 y 10 GB (para 30 segundos de grabación; 1 minuto ocupa el doble) de espacio libre en tu disco duro para almacenar un archivo de vídeo temporal y un archivo de audio temporal. Tras la grabación, ambos se fusionan en un archivo comprimido `.mp4` sin pérdida de calidad, y los archivos temporales de entre 7 y 10 GB se eliminan automáticamente.

Si el espacio en disco no supone un problema y deseas una duración predeterminada más larga, puedes editar el archivo `scripts/record.lua` y cambiar el número que aparece en `data.max_record_time =` por el valor que desees (en segundos).

### 2. Quiero cambiar la duración predeterminada de la grabación de vídeo para que sea superior a los 30 segundos predeterminados. ¿Puedo hacerlo sin editar el archivo record.lua?

Sí, a partir de la versión 2.0.0 puedes cambiar libremente el tiempo de grabación predeterminado en la configuración a 30, 60, 90 o 120 segundos.

### 3. ¿Puedo grabar menos tiempo del que he elegido por defecto?

Sí. Empieza a grabar desde el menú y, si vuelves a pulsar el mismo botón de grabación antes de que finalice el tiempo predeterminado, la grabación se detendrá inmediatamente en ese momento.

### 4. Cuando grabo un vídeo, ¿incluye los marcos, los recortes y los efectos de sombreado?

No. El vídeo grabado se captura como si ninguno de estos efectos estuviera activo, independientemente de lo que estés utilizando. Esto se debe a que la grabación se realiza «antes» de que se aplique cualquiera de estos efectos.

### 5. Cuando hago una captura de pantalla, ¿incluye los biseles, los recortes o los efectos de sombreado?

Sí. Las capturas de pantalla se realizan con lo que tengas activo en ese momento. Si quieres una captura de pantalla «limpia», solo tienes que desactivar los shaders (y cualquier otra superposición) antes de realizarla.

### 6. ¿Dónde se almacenan los vídeos y las capturas de pantalla?

Se guardan en las carpetas `_record` y `_screenshots`, situadas en la misma carpeta en la que instalaste MPV‑SW‑Capture.

No es necesario crearlos, ya que el programa los genera automáticamente tras hacer una captura de pantalla o grabar un vídeo.

Si, por alguna extraña razón, no puedes grabar vídeos o hacer capturas de pantalla, y no tuvieras estas carpetas, puedes crearlas manualmente.

### 7. Cuando grabo un vídeo, veo un contador que indica el tiempo que queda para terminar la grabación. ¿Es normal?

Sí, eso es normal. Así podrás comprobar cuánto tiempo te queda para tu vídeo.

---

## 🧰 Menú, ventana y controles

### 1. ¿Cómo puedo abrir el menú al iniciar el programa?

Solo tienes que hacer clic con el botón derecho del ratón en la ventana y se abrirá el menú. También puedes pulsar la tecla `ESC` del teclado, pero asegúrate de que el cursor esté sobre la ventana de MPV-SW-Capture y de que el programa tenga el foco.

### 2. ¿Cómo cierro el programa? No veo ningún botón con una «X» para cerrarlo.

Para cerrar MPV‑SW‑Capture, abre el menú y selecciona la opción «SALIR».

### 3. ¿Por qué aparece una marca de verificación junto a algunas opciones del menú?

La marca de verificación indica que la opción está activada actualmente. No todas las opciones tienen una marca de verificación, pero la mayoría sí. De este modo, puedes ver rápidamente cuáles están activas y cuáles no.

### 4. ¿Qué es la opción «Info Stream» y cómo puedo ocultarla una vez que está activada?

«Info Stream» muestra estadísticas sobre la transmisión actual (resolución, uso de recursos, etc.). Resulta útil cuando quieres comprobar qué está sucediendo internamente. Para ocultarlo, basta con volver a seleccionar la opción «Info Stream» y la ventana superpuesta desaparecerá.

### 5. En el menú hay muchas opciones en la sección «VENTANA». ¿Para qué sirven?

Estas opciones te permiten personalizar la ventana de MPV‑SW‑Capture a tu gusto.

- Puedes cambiar el tamaño entre 0,5x y 2,0x, o pasar a pantalla completa. También puedes establecer una posición concreta para la ventana.
- «Siempre encima» mantiene la ventana por encima de las demás (pulsa de nuevo para desactivarlo).
- «Ampliar ventana» te permite ampliar la imagen actual a una relación de aspecto más ancha (por ejemplo, de 16:9 a 21:9, o de 4:3 a 16:9). Esto resulta especialmente útil con NSO: si tienes un juego en 4:3, puedes aplicar un recorte y, a continuación, utilizar «Ampliar ventana» para llenar un área de 16:9.
- «Modo mini» ajusta la ventana a un tamaño más pequeño de 0,3x y la desplaza a la esquina inferior derecha de la pantalla.

Además, estos modos de ventana resultan especialmente útiles para los streamers:
- **Modo Mini**: reduce la ventana al 30 % y la coloca en la esquina inferior derecha; es perfecto para mantener una pequeña vista previa en pantalla mientras realizas otras tareas.
- **Pantalla completa**: te ofrece una visión envolvente con mínimas distracciones.
- **Ventana ampliada**: te permite ajustar la relación de aspecto (por ejemplo, de 4:3 a 16:9) para llenar la pantalla o el área de captura.
- **Siempre encima**: mantiene la ventana por encima de otras aplicaciones, para que nunca pierdas de vista tu partida mientras retransmites.

### 6. ¿Cómo puedo ajustar el volumen de MPV‑SW‑Capture de forma independiente en Windows?

En Windows, haz clic en el icono de sonido de la bandeja del sistema, abre el panel de salida/mezclador, busca la entrada «ffplay» y ajusta su volumen al nivel que desees. De este modo, cambiarás específicamente el volumen de MPV‑SW‑Capture.

En la versión 2.1.0 puedes modificar el audio desde MPV-SW-Capture, sin necesidad de realizar cambios en el panel de salida o en el mezclador.

Puedes utilizar la rueda del ratón, las teclas del teclado y un nuevo submenú llamado «AUDIO» en el MENÚ para ajustar el audio.

### 7. Dices que hay dos programas, uno para el vídeo y otro para el audio. ¿Qué pasa con el audio si cierro MPV‑SW‑Capture?

Si cierras la ventana de MPV‑SW‑Capture, el audio también se cierra. Ambas partes están diseñadas para funcionar conjuntamente, por lo que, al cerrar MPV‑SW‑Capture, el proceso de audio que lo acompaña también se detiene y se cierra por completo.

### 8. ¿Qué ocurre si utilizo sombreadores, biseles, formas, recortes o cualquier otra opción y cierro el programa?

Cualquier opción, lo que elijas, solo se mantendrá hasta que cierres MPV-SW-Capture.

Así que, si lo vuelves a abrir, aparecerán todas las opciones predeterminadas.

Las únicas opciones que puedes guardar para que se ejecuten al iniciar el sistema son algunas de las que puedes seleccionar en la configuración.

### 9. En MPV‑SW‑Capture hay que usar el ratón para manejar el MENÚ, ¿verdad? Pero, ¿hay algún atajo de teclado y ratón para algunas funciones?

Sí, hay algunas funciones que puedes utilizar con el teclado y el ratón:

**a) Ratón:**

- **_Pantalla completa_:** Si haces doble clic en la pantalla, puedes activar y desactivar la pantalla completa **ON** y **OFF**.
- **_Acceso al MENÚ_:** Haz clic con el botón derecho del ratón en la pantalla para acceder al menú.
- **_Control de audio_:** Si giras la rueda del ratón hacia ARRIBA, subes el volumen; hacia ABAJO, lo bajas. Puedes seguir girando la rueda hasta encontrar el volumen que desees.

b) Teclado:

- **_Acceso al MENÚ_:** Pulsa la tecla ESC en la pantalla para acceder al menú.
- **_Navegación por el MENÚ_:** Si lo prefieres, también puedes utilizar las teclas de teclado ARRIBA, ABAJO, IZQUIERDA y DERECHA para navegar por el MENÚ.
- **_Acceso rápido_:** Tecla CTRL + una tecla del 1 al 4, para cambiar rápidamente a una selección de shaders.
  - CTRL+5 sirve para «Limpiar shaders».
  - CTRL+0 sirve para «Limpiar todo».
- **_Control de audio_:** Si utilizas la tecla ARRIBA del teclado, aumentas el volumen en +10. Con la tecla ABAJO, lo reduces en -10.
  - La tecla M sirve para silenciar y, al pulsarla de nuevo, se reanuda el sonido.

### 10. ¿Cómo puedo comprobar qué versión de MPV-SW-Capture tengo instalada?

Hay dos formas de hacerlo:  
1. Visita la [página oficial de versiones](https://github.com/TyRaS-SW/MPV-SW-Capture/releases) para ver la última versión disponible.  
2. Abre MPV-SW-Capture, ve al menú **AYUDA → Comprobar la última versión de MSC**. El programa te indicará si tienes la última versión o si hay una actualización disponible.

---

## 🧰 Herramientas

### 🌐 Transmite con OBS

#### 1. ¿Qué es el Stream Manager y para qué sirve?

El Stream Manager (MSCGUI) es una herramienta gráfica ubicada en la carpeta `tools/` que te ayuda a configurar OBS Studio para capturar con MPV-SW-Capture. Automatiza la instalación del complemento `win-capture-audio`, configura colecciones de escenas, añade las fuentes necesarias (Captura de ventana + Captura de audio) e incluye un modo «Streamer» para ocultar los mensajes OSD. También te permite cambiar entre los modos **Instalado** y **Portátil** de OBS.

#### 2. ¿Por qué se necesitan derechos de administrador para instalar el complemento «win-capture-audio» en OBS (modo «Instalado»)?

Cuando OBS se instala en una carpeta del sistema protegida, como `C:\Archivos de programa`, para escribir archivos en su directorio de instalación se necesitan permisos elevados. El Stream Manager lo detectará y te pedirá que lo reinicies como administrador. Por el contrario, si utilizas la versión **portátil** de OBS (instalada en cualquier lugar fuera de `Archivos de programa`), no se necesitan permisos especiales.

#### 3. ¿Cuál es la diferencia entre OBS instalado y OBS portátil en el contexto de MPV-SW-Capture?

- **Instalado**: OBS se instala de forma predeterminada en `Archivos de programa`. Es la opción más habitual, pero puede que se necesiten derechos de administrador para modificar el programa o instalar complementos.  
- **Portátil**: OBS es una versión independiente que puedes guardar en cualquier lugar (por ejemplo, en una memoria USB). No requiere derechos de administrador y te permite llevar tu configuración contigo. Sin embargo, debes descargar la versión ZIP y extraerla manualmente. El Stream Manager puede ayudarte a descargar y configurar ambos modos.

#### 4. ¿Cómo puedo utilizar MPV-SW-Capture con OBS de forma más sencilla?

El Stream Manager (en la carpeta `tools/`) automatiza todo el proceso. Instala el complemento `win-capture-audio`, crea una colección de escenas o añade las fuentes necesarias a una colección ya existente. Para obtener guías detalladas paso a paso, consulta:  
- [Guía de Stream Manager](https://github.com/TyRaS-SW/MPV-SW-Capture/wiki/Guide-Stream-Manager)  
- [Guía de instalación](https://github.com/TyRaS-SW/MPV-SW-Capture/wiki/Guide-Installation)

#### 5. ¿En qué consiste la opción «Ocultar mensajes OSD» y cómo afecta a la grabación?

La opción **«Ocultar mensajes OSD»** se encuentra en el menú, en **OTROS → Ocultar mensajes OSD**. Cuando está activada, oculta todos los mensajes en pantalla que aparecen al seleccionar cualquier opción (por ejemplo, cambios en los shaders, ajustes de recorte, etc.). Es ideal para streamers que no quieren que estas notificaciones aparezcan en su retransmisión, o para usuarios que simplemente prefieren una interfaz más limpia.

**Importante:** Por motivos de seguridad, la función **GRABAR VÍDEO** queda totalmente desactivada cuando la opción «Ocultar mensajes OSD» está activada. Solo podrás utilizar la función de grabación cuando esta opción esté desactivada. De este modo, te aseguras de estar al tanto del estado de la grabación y evitas grabar accidentalmente sin recibir ninguna indicación visual.

### 🖼 Gestor de biseles

#### 1. ¿Qué es «MSC_Bezel_Manager.exe» y para qué sirve?

`MSC_Bezel_Manager.exe` es una herramienta ubicada en la carpeta `tools/` que te permite gestionar y personalizar los marcos decorativos (bezels) para MPV-SW-Capture. Con ella, puedes:
- Previsualizar los marcos decorativos antes de aplicarlos.
- Añadir nuevos biseles al menú (colocando tus imágenes PNG en la carpeta correspondiente y actualizando la configuración).
- Eliminar o reorganizar los biseles existentes.

Esta herramienta simplifica el proceso de creación y uso de marcos personalizados sin necesidad de editar manualmente los archivos de configuración. Para obtener una guía detallada, consulta la página [Marcos personalizados](https://github.com/TyRaS-SW/MPV-SW-Capture/wiki/Custom-Bezels).

### 🎞 Gestor de vídeos

#### 1. ¿Qué es «MSC_Video_Manager.exe» y para qué sirve?

`MSC_Video_Manager.exe` es una herramienta gráfica ubicada en la carpeta `tools/` que te permite ajustar parámetros avanzados de vídeo para MPV-SW-Capture sin tener que editar directamente el archivo `mpv.conf`. Puedes modificar ajustes como:
- Latencia de vídeo
- Tamaño del búfer de audio
- Decodificación por hardware (`hwdec`)
- Opciones de renderizado por GPU (`vo=gpu`)
- Y otras opciones relacionadas con el rendimiento

Esta herramienta resulta especialmente útil para aquellos usuarios que desean ajustar con precisión el rendimiento y la calidad, pero prefieren una interfaz intuitiva en lugar de archivos de configuración manuales.

---

## 📋 Idioma

### 1. Con la versión 2.0.0, me he dado cuenta de que se puede cambiar el idioma entre inglés y español. ¿Cómo funciona?

Con la nueva configuración de la interfaz gráfica de usuario (GUI) de la versión 2.0.0, puedes cambiar fácilmente el idioma simplemente utilizando el botón **«MENÚ: Inglés <- -> Español»** en `Setup_MPV-SW-Capture.exe`.

Al pulsar el botón, todo el texto se actualiza automáticamente del inglés al español. Si vuelves a pulsarlo, podrás cambiar del español al inglés.

Nota: Solo podrás ver los cambios en los idiomas después de cerrar MPV-SW-Capture y volver a abrirlo.

### 2. ¿Qué se traduce con ese botón?

Casi todo. El MENÚ está casi totalmente traducido al español.

¡Los mensajes de MPV-SW-Capture también se han traducido!

### 3. ¿Se mantiene la selección de idioma en todos los programas (Configuración, Instalador, Herramientas)?

Sí, el idioma que elijas en cualquiera de los programas —como `Setup_MPV-SW-Capture.exe`, `Installer_MPV-SW-Capture.exe` o cualquiera de las herramientas (por ejemplo, Stream Manager, Video Manager o Bezel Manager)—, se guarda y se carga automáticamente en todos ellos.

Por ejemplo, si abres la configuración y cambias el idioma a español, y luego la cierras y la vuelves a abrir, el idioma seguirá siendo el español. Además, si más tarde abres el instalador, también se iniciará en español, reflejando la misma preferencia.

---

## 📋 Solicitudes, incidencias y comentarios

### 1. Tengo algunos comentarios sobre estos proyectos. ¿Dónde puedo dar mi opinión?

Puedes compartir tus comentarios aquí: **[Debates](https://github.com/TyRaS-SW/MPV-SW-Capture/discussions)**

### 2. Tengo algunos problemas. ¿Dónde puedo comentarlos?

Puedes compartir tus incidencias aquí: **[Incidencias](https://github.com/TyRaS-SW/MPV-SW-Capture/issues)**

### 3. Tengo algunas ideas o peticiones. ¿Puedo compartirlas? ¿Y dónde?

Puedes compartir tus ideas o sugerencias aquí: **[Ideas](https://github.com/TyRaS-SW/MPV-SW-Capture/discussions/categories/ideas)**

---

## 📋 Solución de problemas

### 1. He intentado abrir `MPV-SW-Capture.exe` (o el acceso directo), pero no pasa nada. ¡No se abre la pantalla! ¿Qué puedo hacer?

Las tarjetas de captura se consideran cámaras en Windows.

Además, si abres tu tarjeta de captura con otro programa, no podrás utilizarla en MPV-SW-Capture hasta que cierres primero ese otro programa.

Por ejemplo, si abres la cámara en «Configuración de Windows» -> «Bluetooth y dispositivos» -> «Cámaras» y seleccionas tu tarjeta de captura como cámara, no podrás utilizar MPV-SW-Capture hasta que cierres esa ventana.

Esta es una limitación que tienen las tarjetas de captura por defecto.

Si la ventana aparece un instante y luego se cierra, suele deberse a que el dispositivo de captura no está configurado correctamente. Ejecuta `Setup_MPV-SW-Capture.exe`, selecciona tu tarjeta de captura (vídeo y audio), haz clic en «Guardar y salir» y, a continuación, vuelve a iniciar el programa.

### 2. ¿Se pueden abrir varias ventanas con `MPV-SW-Capture.exe`?

No. MPV-SW-Capture.exe solo admite una ventana a la vez. Tal y como se ha indicado en la respuesta anterior, la tarjeta de captura funciona como un único dispositivo, por lo que esto es normal.

### 3. Tengo más de una tarjeta de captura conectada. ¿Cómo puedo cambiar la tarjeta de captura predeterminada?

En «Configuración», pulsa **«Escanear dispositivo»** y selecciona la otra tarjeta de captura (vídeo y audio) que quieras utilizar.

Debes cerrar y volver a abrir MPV-SW-Capture para ver los cambios.