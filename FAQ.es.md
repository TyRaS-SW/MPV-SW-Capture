# ❓ Preguntas frecuentes

## 🎮 Generalidades y concepto

### 1. ¿Por qué utilizar MPV para jugar a Switch/2/PS/XB/Retro o cualquier otra consola compatible con HDMI?

MPV es un reproductor de vídeo muy potente y rápido cuando se configura correctamente. Además, te permite añadir shaders, marcos, recortes y muchas otras opciones, lo que lo convierte en algo más que «simplemente reproducir» y lo transforma en una herramienta que puedes personalizar realmente para jugar en consolas.

### 2. ¿Por qué MPV y no otro programa?

Hay otros programas que te permiten capturar vídeo y hacer algo similar a este proyecto, pero suelen ser más limitados y no ofrecen el mismo nivel de personalización que ofrece MPV-SW-Capture además de MPV. Además, la mayoría tiende a aumentar el retraso, lo que hace que la experiencia sea injugable.

---

## 🧩 Hardware y tarjetas de captura

### 1. ¿Por qué necesito una tarjeta de captura compatible con 1080p60?

Porque 1080p60 es el estándar de calidad actual para la mayoría de las consolas y dispositivos de captura modernos. Optar por 1080p60 garantiza una buena calidad de imagen y una experiencia de juego fluida.

### 2. ¿Por qué se recomienda el USB 3.0? ¿Qué ocurre si utilizo el USB 2.0?

Se recomienda el USB 3.0 porque ofrece un mayor ancho de banda, lo que se traduce en una mejor calidad de imagen y un rendimiento más estable para vídeos de alta resolución y alta frecuencia de fotogramas. Puedes seguir utilizando el USB 2.0, pero la calidad y la estabilidad pueden verse afectadas. Si no tienes otra opción, puedes utilizarlo de todos modos, pero ten en cuenta esta limitación.

### 3. ¿Puedo utilizar cualquier tarjeta de captura USB-HDMI?

En teoría, sí. Sin embargo, para este proyecto se recomienda una tarjeta de captura que admita 1080p60 y cuente con salida en bucle (entrada HDMI + salida HDMI). Existen opciones relativamente económicas y fáciles de encontrar. Un ejemplo que puedes buscar es: «Captura de vídeo HD 4K Ultra HD USB 3.0 (MS 2131)». Estos dispositivos admiten entradas de hasta 4K60 y emiten a 1080p60. Por ejemplo, si conectas una consola que admite 4K a 60 fps, la tarjeta de captura lo aceptará, pero la imagen final utilizada por MPV-SW-Capture será de 1080p a 60 fps.

### 4. ¿Qué hay de las tarjetas de captura tipo memoria USB que solo tienen HDMI y USB, y que suelen admitir hasta 720p60?

En general, deberían funcionar, pero no se han probado con este proyecto. Si pruebas una y funciona (o no), por favor, comparte tus resultados en el proyecto para que otros puedan beneficiarse de esa información.

### 5. Si tengo una tarjeta de captura USB 3.0 que puede emitir más de 1080p60 (como 1440p60 o 4K60), ¿funcionará?

Este caso tampoco se ha probado, pero, en principio, debería funcionar sin problemas importantes. Si lo pruebas, por favor, comparte tus resultados.

### 6. Tengo una consola que solo emite hasta 720p en lugar de 1080p, ¿funcionará?

Sí, funcionará sin problemas. Por ejemplo, se probó con una salida de solo 720p y el resultado fue una mejora automática a 1080p. Con esto, todo funcionó correctamente, incluso los biseles, los recortes y los sombreadores.

Además, se probó con consolas más antiguas que admiten menos de 720p (480p), conectadas mediante un adaptador de AV a HDMI, y el resultado también es una mejora de resolución a 1080p.

---

## 🎮 Software

### 1. ¿Qué programas necesitamos para utilizar MPV-SW-Capture?

Se necesitan tres programas: `MPV` es el principal. También se necesitan `ffplay` y `ffmpeg` para que funcione.

Por eso hay que descargarlos, tal y como ya se explica en las instrucciones.

### 2. He seguido las instrucciones y he configurado correctamente mi `MPV-SW-Capture`. Sin embargo, me he dado cuenta de que los tres programas tienen ahora una versión más reciente que la que utilizaba antes. ¿Puedo actualizarlos sin que el MPV-SW-Capture deje de funcionar?

Si te refieres a `MPV`, `ffplay` y `ffmpeg`, sí, puedes actualizar o sustituir los tres programas sin ningún problema. Tienes que descargar sus nuevas versiones y sustituir las antiguas por las más recientes.

Eso es todo lo que tienes que hacer. Además, siempre se recomienda tener la versión más reciente.

Sin embargo, si detectas algún problema, puedes probar con versiones anteriores. Si eso llegara a ocurrir, por favor, comenta el problema en **[Issues](https://github.com/TyRaS-SW/MPV-SW-Capture/issues)**, para que podamos comprobarlo y solucionarlo.

Sin embargo, si te refieres al propio MPV-SW-Capture, lo recomendable es simplemente sustituir todos los archivos.

### 3. ¿Para qué sirve este archivo, `Installer_MPV-SW-Capture.exe`?

`Installer_MPV-SW-Capture.exe` es la nueva forma de descargar e instalar o actualizar `MPV-SW-Capture`, `ffplay`, `ffmpeg` y `mpv`. Al utilizar el instalador, el programa instala automáticamente todos los archivos necesarios. Esto significa que podrás actualizar futuras versiones de MPV-SW-Capture desde el instalador. Además, podrás actualizar todos los demás programas necesarios a sus últimas versiones, sin necesidad de descargarlos manualmente.

Aún puedes actualizar de la forma habitual. Consulta las instrucciones manuales para hacerlo **

### 4. Estaba utilizando `Installer_MPV-SW-Capture.exe` y ahora no puedo actualizar. ¿A qué se debe esto?

Esto se debe a una limitación de GitHub. Si realizas muchas operaciones, GitHub limita las nuevas descargas hasta que haya transcurrido una hora. Solo puedes tener este problema si descargas, actualizas, etc., en una cantidad excesiva.

Dado que solo estás actualizando o instalando, esto no debería suponer ningún problema. No obstante, si te encuentras con este problema, espera una hora o realiza una instalación manual.

Como solución alternativa, puedes realizar una instalación manual mientras esperas, o simplemente esperar una hora e intentarlo de nuevo.
Puedes consultar cómo hacerlo pulsando el botón que aparece al final de esta página: **[Guía de instalación -> Instalación manual](https://tyras-sw.github.io/MPV-SW-Capture/)**.
Este límite lo impone GitHub para evitar abusos.

### 5. ¿Cómo funcionan los números de actualización en MPV-SW-Capture?

Cuando ves una actualización, aparecen tres números separados por puntos. Se representan como `X`, `Y`, `Z`:

v`X`.`Y`.`Z`.

- `X` = Actualización muy importante que hay que instalar.
- `Y` = Actualización importante.
- `Z` = Parche menor o pequeña adición.

---

## 🎨 Imágenes, shaders, biseles, recortes y formas

### 1. ¿Por qué algunos shaders indican 4K si solo estoy utilizando 1080p60?

Esos shaders realizan un aumento de resolución y una mejora de la imagen. Si tienes una pantalla 4K, la imagen se verá mejor en 4K aunque la señal de entrada sea 1080p60. Esto ayuda a mejorar la imagen a una resolución superior a la original (1080p).

### 2. Durante la configuración, hay una opción para activar automáticamente la combinación de shaders «👑1080p→4K Fast⚡». ¿Por qué se recomienda?

Porque es una combinación muy buena de shaders que mejora la calidad de la imagen cuando utilizas la pantalla completa a 4K, al tiempo que consume muy pocos recursos. Dado que la resolución máxima es de 1080p y estás ampliando la imagen por encima de ese valor, hasta 4K, esto te ayudará a obtener una imagen menos borrosa y más nítida.

### 3. He conectado una Switch y utilizo NSO, pero cuando aplico un bisel o recorto la imagen, se ve mal (mal recortada). ¿Cómo lo soluciono?

Esto suele deberse a la barra negra que NSO muestra en la parte inferior con los controles y el texto de ayuda. Tienes que desactivar esa superposición. Abre cualquier aplicación de NSO y, antes de seleccionar un juego, ve al menú de la derecha → Ajustes → Visualización de controles → desactiva «Mostrar controles en el juego». Una vez que esa barra haya desaparecido, el área de la imagen quedará más limpia (y, en algunos casos, más grande) y los recortes y marcos funcionarán correctamente. Hay que hacerlo en cada aplicación de NSO.

### 4. ¿Cómo desactivo un shader, un marco o un recorte?

- **Shader**: Utiliza la opción «Borrar shader» o, simplemente, selecciona un shader diferente (este sustituye al anterior; no se superponen).
- **Marco**: Pulsa el mismo marco que habías seleccionado antes o utiliza la opción «Borrar marcos».
- **Recorte**: pulsa la misma opción de recorte que habías seleccionado para desactivarla, o utiliza la opción «Borrar recorte».
- **Forma**: Pulsa la misma opción de forma que habías seleccionado para desactivarla, o utiliza la opción «Borrar forma».

Si quieres borrarlo todo de una vez (por ejemplo, bisel, sombreador, forma), puedes utilizar la opción «Borrar TODO».

### 5. Quiero crear mis propios biseles, pero no sé cómo. ¿Cómo lo hago?

Los biseles son imágenes PNG de 1920x1080. Se utilizan principalmente con NSO para sustituir los bordes predeterminados por cualquier diseño que desees. El área central es donde va la imagen del juego; solo tienes que diseñar el bisel de manera que el área del juego quede bien alineada y tenga un buen aspecto. Para ver un tutorial más detallado sobre cómo crear biseles y añadirlos al menú, puedes consultar aquí: **[Personalización avanzada -> 8. Crea tu bisel personalizado](https://tyras-sw.github.io/MPV-SW-Capture/#advanced)**.

### 6. ¿Puedo añadir mis propios shaders?

Sí, puedes. Los shaders deben ser compatibles con MPV y estar en formato .glsl.

Debes colocarlos en la carpeta /shaders y editar el archivo menu.conf para añadir tu shader, siguiendo el mismo formato que los demás.

### 7. ¿Qué son las SHAPES? ¿Por qué tienen un submenú específico aparte?

Las SHAPES son shaders que tienen la función específica de cambiar la forma de la pantalla.

Por ejemplo, puedes cambiar la pantalla a la forma de un televisor CRT, de modo que la pantalla tenga curvatura.

En una versión antigua de MPV-SW-Capture, algunos shaders cambiaban el aspecto a retro y modificaban la forma de la pantalla al mismo tiempo.

Sin embargo, la forma era específica de ese shader.

Ahora, esto está separado, ya que puedes cambiar la forma y seleccionar el shader que desees.

¡Puedes crear cualquier combinación posible, sin límites!

Todos los shaders antiguos que tenían una forma específica ahora son «planos». Así pues, puedes elegir entre tener el shader «plano» o combinarlo con una forma; tú decides.

---

## 📹 Grabación y capturas de pantalla

### 1. ¿Por qué el límite de grabación predeterminado es de solo 30 segundos? ¿No es demasiado corto?

En realidad, puedes grabar todo el tiempo que quieras. El límite predeterminado de 30 segundos se debe al funcionamiento de la grabación: mientras reproduces, la herramienta necesita espacio temporal en el disco. Puede utilizar entre 7 y 10 GB (para 30 segundos de grabación; 1 minuto duplica ese tamaño) de espacio libre en tu disco duro para almacenar un archivo de vídeo temporal y un archivo de audio temporal. Tras la grabación, ambos se fusionan en un archivo `.mp4` comprimido sin pérdida de calidad, y los archivos temporales de entre 7 y 10 GB se eliminan automáticamente.

Si el espacio en disco no es un problema y deseas una duración predeterminada mayor, puedes editar `scripts/record.lua` y cambiar el número en `data.max_record_time =` por cualquier valor que desees (en segundos).

### 2. Quiero cambiar la duración predeterminada de la grabación de vídeo a más de los 30 segundos predeterminados. ¿Puedo hacerlo sin editar el archivo `record.lua`?

Sí, desde la versión 2.0.0 puedes cambiar libremente la duración predeterminada de la grabación en «Configuración» a 30, 60, 90 o 120 segundos.

### 3. ¿Puedo grabar menos tiempo del que he elegido como predeterminado?

Sí. Inicia la grabación desde el menú y, si vuelves a pulsar el mismo botón de grabación antes de que finalice el tiempo predeterminado, la grabación se detendrá inmediatamente en ese momento.

### 4. Cuando grabo un vídeo, ¿se incluyen los biseles, recortes o shaders?

No. El vídeo grabado se captura como si ninguno de estos elementos estuviera activo, independientemente de lo que estés utilizando. Esto se debe a que la grabación se realiza «antes» de que se aplique cualquiera de estos efectos.

### 5. Cuando hago una captura de pantalla, ¿incluye marcos, recortes o sombreadores?

Sí. Las capturas de pantalla se realizan con lo que tengas activo en ese momento. Si quieres una captura de pantalla «limpia», solo tienes que desactivar los sombreadores (y cualquier otra superposición) antes de capturarla.

### 6. ¿Dónde se almacenan los vídeos y las capturas de pantalla?

Se guardan en las carpetas `_record` y `_screenshots`, situadas en la misma carpeta donde has instalado MPV‑SW‑Capture.

No es necesario crearlas, ya que el software las crea automáticamente tras realizar una captura de pantalla o grabar un vídeo.

Si, por alguna extraña razón, no puedes grabar vídeos o hacer capturas de pantalla, y no tienes estas carpetas, puedes crearlas manualmente.

### 7. Al grabar un vídeo, veo un contador con el tiempo que queda para terminar la grabación. ¿Es normal?

Sí, es normal. Así puedes comprobar cuánto tiempo te queda para tu vídeo.

---

## 🧰 Menú, ventana y controles

### 1. ¿Cómo abro el menú al iniciar el programa?

Solo tienes que hacer clic con el botón derecho del ratón en la ventana y se abrirá el menú. También puedes pulsar la tecla `ESC` del teclado, pero asegúrate de que el ratón esté sobre la ventana de MPV‑SW‑Capture y de que el programa tenga el foco.

### 2. ¿Cómo cierro el programa? No veo ningún botón «X» para cerrarlo.

Para cerrar MPV‑SW‑Capture, abre el menú y selecciona la opción «QUIT».

### 3. ¿Por qué veo una marca de verificación junto a algunas opciones del menú?

La marca de verificación significa que la opción está activada actualmente. No todas las opciones tienen una marca de verificación, pero la mayoría sí. De este modo, puedes ver rápidamente qué está activo y qué no.

### 4. ¿Qué es la opción «Info Stream» y cómo la oculto una vez que está activada?

«Info Stream» muestra estadísticas sobre la transmisión actual (resolución, uso de recursos, etc.). Resulta útil cuando quieres comprobar qué está sucediendo internamente. Para ocultarla, basta con volver a seleccionar la opción «Info Stream» y la superposición desaparecerá.

### 5. En el menú hay muchas opciones en el apartado VENTANA. ¿Para qué sirven?

Estas opciones te permiten personalizar la ventana de MPV‑SW‑Capture a tu gusto.

- Puedes cambiar el tamaño de 0,5x a 2,0x, o pasar a pantalla completa. También puedes establecer una posición específica para la ventana.
- «Siempre visible» mantiene la ventana por encima de las demás (pulsa de nuevo para desactivarla).
- «Ampliar ventana» te permite ampliar la imagen actual a una relación de aspecto más ancha (por ejemplo, de 16:9 a 21:9, o de 4:3 a 16:9). Esto resulta especialmente útil con NSO: si tienes un juego en 4:3, puedes aplicar un recorte y, a continuación, utilizar «Ampliar ventana» para llenar un área de 16:9.
- «Modo mini» ajusta la ventana a un tamaño más pequeño de 0,3x y la desplaza a la esquina inferior derecha de la pantalla.

Además, estos modos de ventana son especialmente útiles para los streamers:
- **Modo Mini**: reduce la ventana al 30 % y la coloca en la esquina inferior derecha; es perfecto para mantener una pequeña vista previa en pantalla mientras gestionas otras tareas.
- **Pantalla completa**: te ofrece una visión envolvente con mínimas distracciones.
- **Ventana ampliada**: te permite ajustar la relación de aspecto (p. ej., 4:3 → 16:9) para llenar la pantalla o el área de captura.
- **Siempre encima**: mantiene la ventana por encima de otras aplicaciones, para que nunca pierdas de vista tu juego mientras retransmites.

### 6. ¿Cómo puedo ajustar el volumen de MPV‑SW‑Capture de forma independiente en Windows?

En Windows, haz clic en el icono de sonido de la bandeja del sistema, abre el panel de salida/mezclador, busca la entrada `ffplay` y ajusta su volumen al nivel que desees. Esto cambiará específicamente el volumen de MPV‑SW‑Capture.

En la versión 2.1.0 puedes ajustar el audio desde dentro de MPV-SW-Capture, sin necesidad de modificarlo en el panel de salida/mezclador.

Puedes utilizar la rueda del ratón, las teclas del teclado y un nuevo submenú llamado «AUDIO» en el MENÚ para ajustar el audio.

### 7. Dices que hay dos programas, uno para el vídeo y otro para el audio. ¿Qué ocurre con el audio si cierro MPV‑SW‑Capture?

Si cierras la ventana de MPV‑SW‑Capture, el audio también se cierra. Ambas partes están diseñadas para funcionar juntas, por lo que, cuando se cierra MPV‑SW‑Capture, el proceso de audio que lo acompaña también se detiene y se cierra por completo.

### 8. ¿Qué ocurre si utilizo sombreadores, biseles, formas, recortes o cualquier otra opción y cierro el programa?

Cualquier opción, sea cual sea la que elijas, solo se mantiene hasta que cierres MPV-SW-Capture.

Por lo tanto, si lo vuelves a abrir, todo volverá a las opciones predeterminadas.

Las únicas opciones que puedes guardar para el inicio automático son algunas de las que puedes seleccionar en la configuración.

### 9. Para MPV‑SW‑Capture hay que usar el ratón para controlar el MENÚ, ¿verdad? Pero, ¿existen atajos de teclado y ratón para algunas funciones?

Sí, hay algunas funciones que puedes utilizar con el teclado y el ratón:

**a) Ratón:**

- **_Pantalla completa_:** Si haces doble clic en la pantalla, puedes alternar entre **activar** y **desactivar** la pantalla completa.
- **_Acceso al MENÚ_:** Haz clic con el botón derecho en la pantalla para acceder al menú.
- **_Control de audio_:** Si giras la rueda del ratón hacia ARRIBA, subes el volumen; hacia ABAJO, lo bajas. Puedes seguir girando la rueda hasta encontrar el volumen que desees.

**b) Teclado:**

- **_Acceso al MENÚ_:** Pulsa la tecla ESC en la pantalla para acceder al menú.
- **_Navegación por el MENÚ_:** También puedes utilizar las teclas de flecha ARRIBA, ABAJO, IZQUIERDA y DERECHA del teclado para navegar por el menú si lo deseas.
- **_Acceso rápido_:** Tecla CTRL + una tecla del 1 al 4, para cambiar rápidamente a una selección de shaders.
  - CTRL+5 es para «Clean Shaders».
  - CTRL+0 es para «Clean ALL».
- **_Control de audio_:** Si utilizas la tecla ARRIBA del teclado, aumentas el volumen en +10. Con la tecla ABAJO, lo reduces en -10.
  - La tecla «M» sirve para silenciar y, al pulsarla de nuevo, se restablece el sonido.

### 10. ¿Cómo puedo comprobar qué versión de MPV-SW-Capture tengo instalada?

Hay dos formas:  
1. Visita la [página oficial de lanzamientos](https://github.com/TyRaS-SW/MPV-SW-Capture/releases) para ver la última versión disponible.  
2. Abre MPV-SW-Capture, ve al menú **AYUDA → Comprobar la última versión de MSC**. El programa te indicará si tienes la última versión o si hay una actualización disponible.

---

## 🧰 Herramientas

### 🌐 Transmite con OBS

#### 1. ¿Qué es el Stream Manager y para qué sirve?

El Stream Manager (MSCGUI) es una herramienta gráfica ubicada en la carpeta `tools/` que te ayuda a configurar OBS Studio para capturar con MPV-SW-Capture. Automatiza la instalación del complemento `win-capture-audio`, configura colecciones de escenas, añade las fuentes necesarias (Captura de ventana + Captura de audio) e incluye un «Modo Streamer» para ocultar los mensajes OSD. También te permite cambiar entre los modos **Instalado** y **Portátil** de OBS.

#### 2. ¿Por qué se necesitan derechos de administrador para instalar el complemento win-capture-audio en OBS (modo Instalado)?

Cuando OBS está instalado en una carpeta del sistema protegida, como `C:\Archivos de programa`, escribir archivos en su directorio de instalación requiere permisos elevados. El Gestor de transmisiones lo detectará y te pedirá que lo reinicies como administrador. Por el contrario, si utilizas la versión **portátil** de OBS (instalada en cualquier lugar fuera de `Archivos de programa`), no se necesitan permisos especiales.

#### 3. ¿Cuál es la diferencia entre OBS instalado y OBS portátil en el contexto de MPV-SW-Capture?

- OBS **instalado** es la instalación estándar en `Archivos de programa`. Es la más habitual, pero puede requerir derechos de administrador para modificar o instalar complementos.  
- OBS **portátil** es una versión autónoma que puedes colocar en cualquier lugar (por ejemplo, en una memoria USB). No requiere derechos de administrador y te permite llevar tu configuración contigo. Sin embargo, debes descargar la versión ZIP y extraerla manualmente. El Stream Manager puede ayudarte a descargar y configurar ambos modos.

#### 4. ¿Cómo puedo utilizar MPV-SW-Capture con OBS de forma más sencilla?

El Stream Manager (en la carpeta `tools/`) automatiza todo el proceso. Instala el complemento `win-capture-audio`, crea una colección de escenas o añade las fuentes necesarias a una colección ya existente. Para obtener guías detalladas paso a paso, consulta:  
- [Personalización avanzada](https://tyras-sw.github.io/MPV-SW-Capture/#advanced)

#### 5. ¿Qué es la opción «Ocultar mensajes OSD» y cómo afecta a la grabación?

La opción **«Ocultar mensajes OSD»** se encuentra en el menú, en **OTROS → Ocultar mensajes OSD**. Cuando está activada, oculta todos los mensajes en pantalla que aparecen al seleccionar cualquier opción (por ejemplo, cambios de shader, ajustes de recorte, etc.). Esto es ideal para streamers que no quieren que estas notificaciones aparezcan en su emisión, o para usuarios que simplemente prefieren una interfaz más limpia.

**Importante:** Por motivos de seguridad, la función **GRABAR VÍDEO** queda completamente desactivada cuando «Ocultar mensajes OSD» está activa. Solo podrás utilizar la grabación cuando esta opción esté desactivada. Esto garantiza que seas consciente del estado de la grabación y evites grabar accidentalmente sin retroalimentación visual.

### 🖼 Gestor de biseles

#### 1. ¿Qué es `MSC_Bezel_Manager.exe` y para qué sirve?

`MSC_Bezel_Manager.exe` es una herramienta ubicada en la carpeta `tools/` que te permite gestionar y personalizar los biseles (bordes decorativos) para MPV-SW-Capture. Con ella, puedes:
- Previsualizar los biseles antes de aplicarlos.
- Añadir nuevos biseles al menú (colocando tus imágenes PNG en la carpeta correspondiente y actualizando la configuración).
- Eliminar o reorganizar los biseles existentes.

Esta herramienta simplifica el proceso de creación y uso de biseles personalizados sin necesidad de editar manualmente los archivos de configuración. Para consultar una guía detallada, entra aquí: **[Personalización avanzada -> 8. Crea tu marco personalizado](https://tyras-sw.github.io/MPV-SW-Capture/#advanced)**.

### 🎞 Gestor de vídeo

#### 1. ¿Qué es `MSC_Video_Manager.exe` y para qué sirve?

`MSC_Video_Manager.exe` es una herramienta gráfica ubicada en la carpeta `tools/` que te permite ajustar parámetros avanzados de vídeo para MPV-SW-Capture sin tener que editar directamente el archivo `mpv.conf`. Puedes modificar ajustes como:
- Latencia de vídeo
- Tamaño del búfer de audio
- Decodificación por hardware (`hwdec`)
- Opciones de renderizado por GPU (`vo=gpu`)
- Y otras opciones relacionadas con el rendimiento

Esta herramienta resulta especialmente útil para los usuarios que desean ajustar con precisión el rendimiento y la calidad, pero prefieren una interfaz intuitiva en lugar de los archivos de configuración manuales.

---

## 📋 Idioma

### 1. He visto que se puede cambiar el idioma entre inglés y español. ¿Cómo funciona?

Con la configuración de la interfaz gráfica de usuario (GUI), puedes cambiar fácilmente el idioma utilizando únicamente el botón **«MENÚ: Inglés <- -> Español»** en `Setup_MPV-SW-Capture.exe`.

Al pulsar el botón, todo el texto se actualiza automáticamente del inglés al español. Si lo pulsas de nuevo, puedes cambiar del español al inglés.

Nota: Solo podrás ver los cambios de idioma después de cerrar MPV-SW-Capture y volver a abrirlo.

### 2. ¿Qué se traduce con el botón?

Casi todo. El MENÚ está prácticamente completo en español.

¡Los mensajes de MPV-SW-Capture también están traducidos!

### 3. ¿Se mantiene la selección de idioma en todos los programas (Setup, Installer, Tools)?

Sí, el idioma que elijas en cualquiera de los programas —como `Setup_MPV-SW-Capture.exe`, `Installer_MPV-SW-Capture.exe` o cualquiera de las herramientas (p. ej.,, Stream Manager, Video Manager, Bezel Manager)— se guarda y se carga automáticamente en todos ellos.

Por ejemplo, si abres la Configuración y cambias el idioma a español, luego la cierras y la vuelves a abrir, el idioma seguirá siendo el español. Además, si más tarde abres el Instalador, también se iniciará en español, reflejando la misma preferencia.

---

## 📋 Solicitudes, incidencias y comentarios

### 1. Tengo algunos comentarios, incidencias o solicitudes sobre este proyecto. ¿Dónde puedo compartir mi opinión en GitHub?

Puedes compartir tus comentarios aquí: **[Discusiones](https://github.com/TyRaS-SW/MPV-SW-Capture/discussions)**
Puedes compartir tus incidencias aquí: **[Incidencias](https://github.com/TyRaS-SW/MPV-SW-Capture/issues)**
Puedes compartir tus ideas o peticiones aquí: **[Ideas](https://github.com/TyRaS-SW/MPV-SW-Capture/discussions/categories/ideas)**

### 2. ¿Puedo preguntar en otra plataforma como `Discord`?

¡Sí! Puedes compartir comentarios, problemas, peticiones y mucho más en el Discord oficial: **[Discord oficial de MPV-SW-Capture](https://discord.gg/PaVutUUK9U)**.

---

## 📋 Solución de problemas

### 1. He intentado abrir `MPV-SW-Capture.exe` (o el acceso directo), pero no pasa nada. ¡No se abre la pantalla! ¿Qué puedo hacer?

Las tarjetas de captura se tratan como cámaras en Windows.

Además, si abres tu tarjeta de captura con otro programa, no podrás utilizarla en MPV-SW-Capture hasta que cierres primero ese otro programa.

Por ejemplo, si abres la cámara en Configuración de Windows -> Bluetooth y dispositivos -> Cámaras, y seleccionas tu tarjeta de captura como cámara, no podrás utilizar MPV-SW-Capture hasta que la cierres allí.

Esta es una limitación que tienen las tarjetas de captura por defecto.

Si la ventana aparece un instante y luego se cierra, suele deberse a que el dispositivo de captura no está configurado correctamente. Ejecuta `Setup_MPV-SW-Capture.exe`, selecciona tu tarjeta de captura (vídeo y audio), haz clic en «Guardar y salir» y, a continuación, vuelve a iniciar el programa.

### 2. ¿Se pueden abrir varias ventanas con `MPV-SW-Capture.exe`?

No. MPV-SW-Capture.exe solo admite una ventana a la vez. Al igual que en la respuesta anterior, la tarjeta de captura actúa como un único dispositivo, por lo que esto es normal.

### 3. Tengo más de una tarjeta de captura conectada. ¿Cómo puedo cambiar la tarjeta de captura predeterminada?

En la configuración, pulsa **«Escanear dispositivo»** y elige la otra tarjeta de captura (vídeo y audio) que quieras utilizar.

Debes cerrar y volver a abrir MPV-SW-Capture para que se apliquen los cambios.