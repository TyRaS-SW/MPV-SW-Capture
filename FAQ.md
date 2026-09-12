# ❓ FAQ

## 🎮 General & Concept

### 1. Why use MPV to play any HDMI compatible console?

MPV is a very capable and fast video player when configured correctly. It also lets you add shaders, bezels, crops and many other options, which expands it beyond "just playing" into something you can really customize for console gaming.

### 2. Why MPV and not another program?

There are other programs that let you capture video and do something similar to this project, but they tend to be more limited and do not allow the same level of customization that MPV-SW-Capture offers on top of MPV. On top of that, most tend to increase the lag, making the experience unplayable.

---

## 🧩 Hardware & Capture Cards

### 1. Why do I need a capture card that supports 1080p60?

Because 1080p60 is the current standard quality for most modern consoles and capture devices. Targeting 1080p60 ensures good image quality and smooth gameplay.

### 2. Why do you recommend USB 3.0? What happens if I use USB 2.0?

USB 3.0 is recommended because it offers higher bandwidth, which translates into better image quality and more stable performance for high‑resolution, high‑frame‑rate video. You can still use USB 2.0, but quality and stability may be affected. If you have no other option, you can use it anyway, just keep this limitation in mind.

### 3. Can I use any USB HDMI capture card?

In theory, yes. However, for this project the recommendation is a capture card that supports 1080p60 and has loop‑through (HDMI input + HDMI output). There are relatively inexpensive options that are easy to find. One example you can search for is: "4K Ultra HD USB 3.0 HD Video Capture (MS 2131)". These devices accept up to 4K60 input and output 1080p60. For example, if you connect a console that supports 4K60, the capture card will accept that, but the final image used by MPV‑SW‑Capture will be 1080p60.

### 4. What about USB stick‑style capture cards that only have HDMI and USB, and usually support up to 720p60?

They should generally work, but they have not been tested with this project. If you try one and it works (or doesn't), please share your results in the project so others can benefit from that information.

### 5. If I have a USB 3.0 capture card that can output more than 1080p60 (like 1440p60 or 4K60), will it work?

This scenario has not been tested either, but in principle it should work without major issues. If you try it, please share your results.

### 6. I have a console that only outputs up to 720p instead of 1080p, will it work?

Yes, this will work fine. For example, this was tested with a 720p only output, the result was an automatic upscale to 1080p. With this, all worked fine, even bezels, crops and shaders.

Also, it was tested with older consoles that support less than 720p (480p), connected with an AV to HDMI adapter, and the result is also an upscale to 1080p.

---

## 🎮 Software

### 1. What is the software we need to use with MPV-SW-Capture?

There are 3 software needed: `MPV` is the central one. `ffplay` and `ffmpeg` are also needed to make it work.

That's why they need to be downloaded and installed, as explained in the Installation Guide.

### 2. I followed the instructions and successfully set up my `MPV-SW-Capture`. But I noticed that the 3 software now have a newer version than I used before. Can I update them without breaking MPV-SW-Capture?

If you are talking about `MPV`, `ffplay` and `ffmpeg`, yes, you can update/replace the 3 software without problem. You need to download their new versions and replace the older with their newer ones.

That's all you need to do. And it's always recommended to have the newer version.

But if you notice some problems, you can try older versions. If that happens, please comment the problem in **[Issues](https://github.com/TyRaS-SW/MPV-SW-Capture/issues)**, to check and fix that.

If you are talking about MPV-SW-Capture itself, the recommendation is just replace all the files.

### 3. What does `1_INSTALLER_MSC_First-Usage.cmd` do?

`1_INSTALLER_MSC_First-Usage.cmd` is the entry point for the **first-time installation** of MPV-SW-Capture. When you run it, it:

1. Opens a console window with instructions.
2. Downloads and installs all required components — including `mpv.exe`, `ffplay.exe`, and `ffmpeg.exe`.
3. Automatically launches the Setup tool when the installer closes, so you can configure the app.

You only need to run this CMD **once**. After that, all future updates use `MPV-SW-Capture_INSTALLER.vbs`.

### 4. What does `MPV-SW-Capture_INSTALLER.vbs` do?

`MPV-SW-Capture_INSTALLER.vbs` is the launcher for **future updates**. Once the initial installation is done, you use this `.vbs` to:

- Update MPV-SW-Capture to a newer version.
- Update `ffplay` and `ffmpeg` to their latest versions.
- Re-download components that are missing (e.g., if you accidentally deleted `ffplay.exe` or `ffmpeg.exe`).

> ⚠️ **Important limitation**: This `.vbs` **requires `mpv.exe` to be present** in order to run — it uses `mpv.exe` to launch the internal installer script. If `mpv.exe` itself is deleted, the `.vbs` will do nothing visible.
>
> For that reason, **keep `1_INSTALLER_MSC_First-Usage.cmd` in the same folder** as a recovery tool. If you ever lose `mpv.exe`, that CMD is the only way to reinstall it without downloading the whole ZIP again.

### 5. I accidentally deleted one of the required executables. Do I have to reinstall everything?

It depends on **which** file was deleted:

- **If you deleted `ffplay.exe` or `ffmpeg.exe`** (but `mpv.exe` is still there):
  Run `MPV-SW-Capture_INSTALLER.vbs` and use the **Check** function. It will detect the missing file and let you re-download only that component.

- **If you deleted `mpv.exe`**:
  The `.vbs` won't work, because it depends on `mpv.exe` to run. In this case, **run `1_INSTALLER_MSC_First-Usage.cmd` again** — it will detect the missing `mpv.exe` and re-download it. This is why we recommend keeping the CMD file in the folder even after the first install.

### 6. I was using the Installer and now I cannot update. Why did this happen?

This is because of a limitation of GitHub. If you check a lot, GitHub limits downloads until 1 hour has passed. You can only have this problem if you download, upgrade, etc., in an exaggerated quantity.

Since you are just updating or installing, this shouldn't be an issue. But if you are having this problem, wait 1 hour or do a Manual Installation.

As a workaround, you can perform a Manual Installation while you wait, or simply wait the hour and try again. You can check how to do it by visiting the **[Installation Guide](https://tyras-sw.github.io/MPV-SW-Capture/)**. This limit is imposed by GitHub to prevent abuse.

### 7. How do update numbers work in MPV-SW-Capture?

When you see an update, you see 3 numbers separated by dots. Here they are represented as `X`, `Y`, `Z`:

v`X`.`Y`.`Z`.

- `X` = Very important update that must be applied.
- `Y` = Important update.
- `Z` = Minor patch or something small added.

---

## 🛠️ Installation & Launchers

### 1. I opened `MPV-SW-Capture_INSTALLER.vbs` on a fresh install and nothing happened. Why?

On a fresh install you must run **`1_INSTALLER_MSC_First-Usage.cmd`** first. It downloads and installs all required components, including `mpv.exe`. After that, `MPV-SW-Capture_INSTALLER.vbs` works normally for future updates.

`MPV-SW-Capture_INSTALLER.vbs` requires `mpv.exe` to be present. If it's missing, the launcher does nothing visible — this is by design, but it can be confusing. Always check that `mpv.exe` exists in the folder before using the `.vbs` launchers.

> 💡 **Keep the CMD after installation.** Even though you'll only run `1_INSTALLER_MSC_First-Usage.cmd` once, don't delete it. It's the only way to recover `mpv.exe` if it ever gets deleted — the `.vbs` launchers depend on `mpv.exe` being present, so they cannot recover it themselves.

### 2. Windows shows a "Security Warning" when I run the `.cmd` or `.vbs`. Is that normal?

Yes. Windows marks downloaded files with the *Mark of the Web* and asks for confirmation before running them, because they don't carry a digital signature.

**To proceed:**
- Click **Run**.

**To stop it from asking every time:**
- Before clicking **Run**, uncheck **"Always ask before opening this file"**. Windows will remember your choice for that specific file.

The files that trigger this warning are:

- `1_INSTALLER_MSC_First-Usage.cmd`
- `MPV-SW-Capture_SETUP.vbs`
- `MPV-SW-Capture_INSTALLER.vbs`

### 3. Can I launch these tools without the Security Warning?

Yes — once MPV-SW-Capture is running, go to the **TOOLS** section in the menu. The menu opens the Installer, Setup, and other bundled tools internally, so no security dialog appears.

### 4. How do I install the extra tools (Bezel Manager, Video Manager, Stream Helper)?

They're available in two ways:

- Download the separate `TOOLS_*.zip` from the [releases page](https://github.com/TyRaS-SW/MPV-SW-Capture/releases) and extract it.
- Or check **"Install Extra Tools with Install / Update All?"** in the Installer and click **"Install / Update ALL"**.

### 5. I accidentally deleted `mpv.exe` / `ffplay.exe` / `ffmpeg.exe`. Do I have to reinstall everything?

It depends on which file is missing:

| Deleted file | Recovery method |
|---|---|
| `ffplay.exe` or `ffmpeg.exe` | Run `MPV-SW-Capture_INSTALLER.vbs` → **Check** → re-download the missing component. |
| **`mpv.exe`** | Run `1_INSTALLER_MSC_First-Usage.cmd` again. The `.vbs` launchers **cannot** be used in this case because they depend on `mpv.exe` to run. |

> 💡 **Why keep the CMD around?** Even though you only need it for the first install, it's the only recovery path if `mpv.exe` is ever deleted. Leave it in the folder — it takes almost no space (3 KB).

---

## 🎨 Image, Shaders, Bezels, Crops & Shapes

### 1. Why do some shaders say 4K if I'm only using 1080p60?

Those shaders perform an image enhancement. If you have a 4K display, this helps to improve image in higher resolution than the original (1080p) one.

### 2. During setup, there is an option to auto‑enable the "👑1080p→4K Fast⚡" shader combo. Why is it recommended?

Because it's a very good combination of shaders that improve the image quality when you use fullscreen to 4K, while using very few resources and this will help to have a less blurry and cleaner image.

### 3. I connected a Switch and use NSO, but when I apply a bezel or crop the image looks wrong (badly cut). How do I fix this?

This is usually caused by the black bar that NSO shows at the bottom with controls and help text. You need to disable that overlay. Open any NSO app, and before selecting a game go to the `right side menu` → `Settings` → `Control Display` → turn off `Show controls in game`. Once that bar is gone, the image area is cleaner (bigger in some cases) and the crops and bezels will work correctly. Must be done in each NSO app.

### 4. How do I disable a shader, bezel, or crop?

- **Shader**: Use the "Clean Shader" option, or simply select a different shader (it replaces the previous one, they are not stacked).
- **Bezel**: Press the same bezel you selected before, or use the "Clear Bezels" option.
- **Crop**: Press the same crop option you selected to toggle it off, or use the "Clear Crop" option.
- **Shape**: Press the same shape option you selected to toggle it off, or use the "Clear Shape" option.

If you want to clear everything at once (for example, bezel, shader, shape), you can use the "Clean ALL" option.

### 5. I want to create my own bezels but I don't know how. How do I do it?

Bezels are 1920x1080 PNG images. They are mainly used with NSO to replace the default borders with whatever artwork you want. The central area is where the game image goes; you just need to design the bezel so that the game area aligns correctly and looks good. A more detailed tutorial on how to create bezels and add them to the menu, you can go here: **[Advanced customization → 8. Create your Custom Bezel](https://tyras-sw.github.io/MPV-SW-Capture/#advanced)**.

### 6. Can I add my own shaders?

Yes, you can. Shaders must be compatible with MPV, and in `.glsl` format.

You must put them in the `/shaders` folder and edit `menu.conf` to add your shader, following the same format as the other ones.

### 7. What are SHAPES? Why do they have a specific separated submenu?

SHAPES are shaders that do the specific function of changing the shape of the screen.

For example, you can change the screen to a CRT TV shape, so the screen has a curvature.

You can make any combination possible, without limits!

So, you can combine any Shader with any Shape at any time. If you want to see some examples, go here: **[MPV-SW-Capture in action](https://tyras-sw.github.io/MPV-SW-Capture/)**.

### 8. What is "Fit Full 16:9 to Bezel" and how do I use it?

This option fits the entire 16:9 content window perfectly inside a chosen bezel frame. It lets you enjoy your 16:9 content in your favorite bezels without cutting the image.

**How to use it:**

1. Select a bezel frame first (from the `BEZELS` section).
2. Then navigate to `BEZELS → Fit Full 16:9 to Bezel`.

If you don't have a bezel selected, you will see a message asking you to select one first.

---

## 🔊 Audio

### 1. How can I change the volume of MPV-SW-Capture independently in Windows?

You have 2 alternatives:

- **Official**: You can easily change audio inside MPV-SW-Capture, without needing to change the output/mixer panel.
  Use the Mouse's Wheel (`UP` to increase, `DOWN` to decrease), the keyboard's arrow keys (`UP` to increase, `DOWN` to decrease, `M` to Mute/Unmute), and the submenu called `AUDIO` in the MENU to also change the audio.
- **Manual** (not recommended): On Windows, click the sound icon in the system tray, open the output/mixer panel, find the `ffplay` entry and adjust its volume to the level you want. That will change the volume for MPV‑SW‑Capture specifically. Use this only if the official way fails.

### 2. What is Audio Boost and when should I use it?

**Audio Boost** is an option that amplifies the capture card's audio **beyond the standard 100%**, up to **400% (×4)**.

It's ideal for users whose captured content has a very low volume and needs to be raised beyond normal limits.

You can find it in the **Quick Options** and **AUDIO** sections, alongside the standard Volume slider.

### 3. Does Audio Boost persist between sessions?

Yes. Your chosen value is saved to a `.txt` file and restored automatically. If you set it to 300% and close the program, it will still be 300% the next time you open MPV-SW-Capture.

### 4. What is the effective gain indicator?

A small readout below the audio sliders showing the combined **Volume × Boost** result. It changes colour based on clipping risk:

- **Gray** (≤ 2.0x): normal.
- **Green** (2.0 – 3.0x): noticeable gain.
- **Amber** (≥ 3.0x): high clipping risk.

**Best practice:** leave Volume at 100% and raise Boost slowly until you hear the first distortion, then back off a bit. Raising Volume cannot undo clipping that already happened upstream.

---

## 📹 Recording & Screenshots

### 1. Why is the default recording limit only 30 seconds? Isn't that too short?

You can actually record as long as you want. The 30‑second default exists because of the way recording works: while you play, the tool needs temporary space on disk. It can use around 7–10 GB (for 30 seconds of recording; 1 minute is twice the size) of free space on your HDD to store a temporary video file and a temporary audio file. After recording, both are merged into a compressed `.mp4` file without quality loss, and the temporary 7–10 GB files are deleted automatically.

If disk space is not a problem and you want a longer default duration, you can increase the time in `MPV-SW-Capture_SETUP.vbs`.

### 2. Can I record less than the default time I choose?

Yes. Start recording from the menu, and if you press the same record button again before the default time is over, the recording will stop immediately at that moment.

### 3. When I record a video, does it include bezels / crops / shaders?

No. The recorded video is captured as if none of these were active, regardless of what you are using. This is because recording happens "before" any of these effects are applied.

### 4. When I take a screenshot, does it include bezels / crops / shaders?

Yes. Screenshots are taken with whatever you have active at that moment. If you want a "clean" screenshot, just disable shaders (and any other overlay) before capturing.

### 5. Where are videos and screenshots stored?

They are saved inside the `_record` and `_screenshots` folders, located in the same folder where you installed MPV‑SW‑Capture.

It's not necessary to create them, because the software creates them automatically after taking a screenshot or recording a video.

If, for a strange reason, you cannot record video and/or take screenshots, and you don't have these folders, you can manually create them.

### 6. When recording a video, I see a counter with the time left to finish the record. Is that normal?

Yes, that is normal. With this you can check how much time is left for your video.

---

## 🧰 Menu, Window & Controls

### 1. How do I open the menu when the program starts?

Just right‑click on the window and the menu will open. Alternatively, you can press the `ESC` key on your keyboard, but make sure the mouse is over the MPV‑SW‑Capture window and the program is focused.

### 2. How do I close the program? I don't see any "X" button to close it.

To close MPV‑SW‑Capture, open the menu and select the `❌ CLOSE MPV-SW-Capture` option. You can also click the **X** button in the menu's header, which closes the menu but not the program. The **X** in the footer (bottom-left area) closes the whole program.

### 3. Why do I see a checkmark next to some options in the menu? What does the accent border mean?

These are two **independent** visual indicators:

- **✓ Checkmark** (bottom-right of a card): means the option is **currently active**.
- **Accent border** (coloured outline around a card): means the **cursor is currently on that card**.

They move independently. The border follows your cursor (keyboard or mouse), while the checkmark stays on whichever option is actually active. This way you can always tell "where you are" and "what's turned on" at a glance.

### 4. What is the "Info Stream" option and how do I hide it once it's on?

"Info Stream" shows statistics about the current stream (resolution, resource usage, etc.). It is useful when you want to check what is going on internally. To hide it, simply select the "Info Stream" option again and the overlay will disappear.

### 5. In the menu there are many options under WINDOW. What are they for?

These options let you customize the MPV‑SW‑Capture window as you like.

- You can change the size from 0.5x to 2.0x, or go full screen. You can also set a specific position for the window.
- "Always on Top" keeps the window above other windows (press it again to disable).
- "Stretch Window" lets you stretch the current image to a wider aspect ratio (for example, from 16:9 to 21:9, or from 4:3 to 16:9). This is especially useful with NSO: if you have a 4:3 game, you can apply a crop and then "Stretch Window" to fill a 16:9 area.
- "Mini Mode" sets the window to a smaller 0.3x size and moves it to the bottom‑right corner of the screen.

Additionally, these window modes are especially useful for streamers:

- **Mini Mode**: shrinks the window to 30% and places it in the bottom-right corner – perfect for keeping a small preview on screen while you manage other tasks.
- **Fullscreen**: gives you an immersive view with minimal distractions.
- **Stretch Window**: lets you adjust the aspect ratio (e.g., 4:3 → 16:9) to fill your screen or capture area.
- **Always on Top**: keeps the window above other applications, so you never lose sight of your game while streaming.

### 6. How can I change the volume of MPV‑SW‑Capture independently in Windows?

See the **🔊 Audio** section above (question 1).

### 7. You say there are two programs, one for video and one for audio. What happens to audio if I close MPV‑SW‑Capture?

If you close the MPV‑SW‑Capture window, the audio closes as well. Both parts are designed to work together, so when MPV‑SW‑Capture is closed, the audio process is also stopped and fully closed.

### 8. What happens if I use shaders/bezels/shapes/crops/any option, and I close the program?

Most options are **not persisted** — they only stay until you close MPV-SW-Capture. If you open it again, everything will be at default.

**The exception is Audio Boost.** Your chosen Boost value (from 100% to 400%) is saved to a `.txt` file and restored automatically on the next launch.

The other options that persist are the ones you can choose in the **Setup**, **Installer**, and **Tools**.

### 9. For MPV‑SW‑Capture you must use mouse to control the MENU, right? But, are there some keyboard and mouse shortcuts to some functions?

Yes, there are some functions that you can use with keyboard and mouse:

**a) Mouse:**

- **_Fullscreen_:** If you double click on the screen you can cycle fullscreen **ON** and **OFF**.
- **_Access to MENU_:** Right-click on the screen to access the menu.
- **_Control Audio_:** Use the Mouse's Wheel `UP` to increase volume, `DOWN` to decrease volume. You can keep rotating the Wheel to find your desired volume.

**b) Keyboard:**

- **_Access to MENU_:** Press `ESC` to access the menu.
- **_Navigate in MENU_:** You can also use keyboard keys `UP`, `DOWN`, `LEFT`, `RIGHT` to navigate in the MENU.
- **_Apply option_:** Press `ENTER` to activate the highlighted option.
- **_Change section_:** Press `TAB` to jump to the next section, or `PGUP`/`PGDN` to move between sections.
- **_Control Audio_:** Use the Keyboard's `UP` key to increase volume by +10, `DOWN` key to decrease volume by -10.
  - `M` key is to Mute and pressing again is to Unmute.

### 10. How can I check which version of MPV-SW-Capture I have installed?

There are two ways:

1. Visit the [official releases page](https://github.com/TyRaS-SW/MPV-SW-Capture/releases) to see the latest version available.
2. Open MPV-SW-Capture, go to the menu **`HELP` → `Check Latest MSC Version`**. The program will tell you if you have the latest version or if an update is available.

### 11. What's new in the menu compared to previous versions?

The old list-based menu was replaced with a graphical Smart-TV-style interface built on ASS (Advanced SubStation Alpha). It adds:

- Section-based navigation with a visual sidebar and badges.
- Dedicated cards per option, with active-state indicators.
- Draggable audio sliders with a live effective-gain readout.
- **In-menu language switcher**: change the interface language on the fly.
- **Header quick actions**: 4 clickable buttons — `TAKE SCREENSHOT`, `RECORD VIDEO`, the language badge (`EN`/`ES`/`JP`), and the close button (`X`).
- **Quick Options** section for fast access to common tasks.
- **Restructured sections**: the old `OTHERS` section was split into two independent entries — **HELP** and **TOOLS**.

### 12. Why does the menu sometimes close and reopen automatically?

Applying a card in **Shaders**, **Shapes**, **Crops**, or **Bezels** hides the menu and reopens it 3 seconds later. This is intentional — it lets you see the effect on the video while keeping the menu handy.

Audio Boost options behave the same way, so the slider reflects the new value when the menu reopens.

### 13. How do I change the language without leaving MPV?

Click the **language badge** in the header (shows `EN`, `ES`, `JP`, …) or the equivalent button in **Quick Options → SETTINGS**. Each click cycles to the next available language.

The change applies **instantly** — no need to close and reopen MPV-SW-Capture.

### 14. What does CLEAN ALL do?

`CLEAN ALL` performs a full reset. It clears all shaders, shapes, crops, and bezels, and additionally restores:

- Window size → **1.0x**
- Window position → **centered**
- Rotation → **0°**
- Border → **off**
- Title bar → **off**
- Always On Top → **off**
- Aspect override → **16:9**
- Deband → **off**

You can trigger it from the footer of the sidebar, or from **Quick Options → CAPTURE → Clean ALL**.

---

## 🧰 Tools

### 🌐 Stream with OBS

#### 1. What is the Stream Manager and what is it used for?

The Stream Manager (MSCGUI) is a graphical tool from the `TOOLS_*.zip` package that helps you configure OBS Studio to capture MPV-SW-Capture. It automates the installation of the `win-capture-audio` plugin, sets up scene collections, adds the required sources (Window Capture + Audio Capture), and includes a Streamer Mode to hide OSD messages. It also lets you switch between OBS **Installed** and **Portable** modes.

#### 2. Why does installing the win-capture-audio plugin in OBS (Installed mode) require administrator rights?

When OBS is installed in a protected system folder like `C:\Program Files`, writing files into its installation directory requires elevated permissions. The Stream Manager will detect this and prompt you to restart it as Administrator. In contrast, if you are using the **Portable** version of OBS (installed anywhere outside `Program Files`), no special permissions are needed.

#### 3. What is the difference between OBS Installed and OBS Portable in the context of MPV-SW-Capture?

- **Installed** OBS is the standard installation in `Program Files`. It is the most common but may require administrator rights to modify or install plugins.
- **Portable** OBS is a self-contained version that you can place anywhere (e.g., on a USB drive). It does not require admin rights and allows you to carry your configuration with you. However, you need to download the ZIP version and extract it manually. The Stream Manager can help you download and set up both modes.

#### 4. How can I use MPV-SW-Capture with OBS more easily?

The Stream Manager (from the `TOOLS_*.zip` package) automates the entire process. It installs the `win-capture-audio` plugin, creates a scene collection, or adds the required sources to an existing collection. For detailed step-by-step guides, see:

- [Advanced customization](https://tyras-sw.github.io/MPV-SW-Capture/#advanced)

#### 5. What is the "Hide OSD Messages" option and how does it affect recording?

The option **"Hide OSD Messages"** is located in the menu under **HELP → Hide OSD Messages**. When enabled, it hides all on‑screen messages that appear when you select any option (e.g., shader changes, crop adjustments, etc.). This is ideal for streamers who don't want these notifications to appear on their broadcast, or for users who simply prefer a cleaner interface.

**Important:** For safety reasons, the **`RECORD VIDEO`** function is completely disabled when `Hide OSD Messages` is active. You can only use recording when this option is turned off. This ensures that you are aware of the recording status and avoid accidentally capturing without visual feedback.

### 🖼 Bezel Manager

#### 1. What is the Bezel Manager and what is it used for?

The Bezel Manager is a graphical tool from the `TOOLS_*.zip` package that allows you to manage and customize bezels (decorative borders) for MPV-SW-Capture. With it, you can:

- Preview bezels before applying them.
- Add new bezels to the menu (by placing your PNG images in the appropriate folder and updating the configuration).
- Remove or reorganize existing bezels.

This tool simplifies the process of creating and using custom bezels without editing configuration files manually. For a detailed guide, go here: **[Advanced customization → 8. Create your Custom Bezel](https://tyras-sw.github.io/MPV-SW-Capture/#advanced)**.

### 🎞 Video Manager

#### 1. What is the Video Manager and what is it used for?

The Video Manager is a graphical tool from the `TOOLS_*.zip` package that lets you adjust advanced video parameters for MPV-SW-Capture without editing `mpv.conf` directly. You can modify settings such as:

- Video latency
- Audio buffer size
- Hardware decoding (`hwdec`)
- GPU rendering options (`vo=gpu`)
- And other performance‑related options

This tool is especially useful for users who want to fine‑tune performance and quality but prefer a user‑friendly interface over manual configuration files.

---

## 📋 Language

### 1. What languages are available?

Currently: **English** (`en`), **Spanish** (`es`), and **Japanese** (`jp`).

The list is read from `scripts/lang/language_list.dat`, which means **you can add any language you want** — the system is fully extensible. If you're interested in adding a new one, see question 5.

### 2. Where do I change the language — in the menu or in Setup?

Both work:

- **In Setup**: select the language from the list and press **"Apply Language"**.
- **In the menu**: click the **language badge** (`EN`/`ES`/`JP`) in the header, or the button in **Quick Options → SETTINGS**. Each click cycles to the next available language.

The change applies **instantly** in the menu — no need to close MPV-SW-Capture. Changes made in Setup require a program restart to take effect.

### 3. What gets translated?

The following elements are translated by the language selector:

- The **menu** (sections, tabs, card labels, footer, header).
- **MPV-SW-Capture messages** (OSD notifications, status messages, error prompts).

> ⚠️ **Note about the Setup, Installer, and Tools GUIs**: these tools have their **own hardcoded language support** and are **not** translated by the menu's language selector. They currently support only **English** and **Spanish**. See question 4 for details.

### 4. Does the language selection persist across all programs (Setup, Installer, Tools)?

**Short answer:** Yes, but there are **two separate language systems** — one for the GUIs and one for the menu.

**System 1 — All GUIs share ONE preference:**

- The Setup, Installer, Bezel Manager, Video Manager, and Stream Manager **all read and write to the same language file**.
- This means they always show the same language as each other. If you set Setup to Spanish, the Installer will also be in Spanish, and so on.
- These GUIs currently support only **English and Spanish** (Japanese is not available in them).

**System 2 — The menu has its own separate preference:**

- The in-game menu uses a different system, based on `scripts/lang/language_list.dat`.
- It currently supports **English, Spanish, and Japanese**.
- Changing the GUI language does **not** affect the menu, and changing the menu language does **not** affect the GUIs.

**Summary table:**

| Component | Languages available | Shared with |
|---|---|---|
| **All GUIs** (Setup, Installer, Tools) | EN, ES | Each other (one shared preference) |
| **Menu** (in MPV-SW-Capture) | EN, ES, JP + any you add | Nothing else — fully independent |

### 5. How do I add a new language?

MPV-SW-Capture supports adding any language, as long as someone provides the translation files. The process is straightforward and doesn't require any code changes.

**1. Register the language code**

Open `scripts/lang/language_list.dat` and add the two-letter code for your language on its own line (e.g., `fr` for French, `de` for German, `pt` for Portuguese).

**2. Create the 3 translation files**

You need to create **3 files** inside `scripts/lang/`. The easiest way is to **copy an existing file and translate only the right side of each line**:

| File to create | Copy this file as a starting point | What it translates |
|---|---|---|
| `MENUMSG_<lang>.dat` | `MENUMSG_es.dat` | Menu labels (section names, card labels, tooltips) |
| `ASMENU_<lang>.dat` | `ASMENU_en.dat` | Internal menu strings (sliders, buttons, footer) |
| `OSDMSG_<lang>.dat` | `OSDMSG_en.dat` | On-screen messages (notifications, errors, status) |

Replace `<lang>` with your language code from step 1. For example, for French you'd create `MENUMSG_fr.dat`, `ASMENU_fr.dat`, and `OSDMSG_fr.dat`.

> ⚠️ **Important: only translate the RIGHT side of each line.**
>
> Every line in these files has the format `left=right`. The **left side is the original English key** and must **not** be changed — it's how the program finds the translation. Only translate the **right side**, after the `=`.
>
> **Example** (in `MENUMSG_fr.dat`):
> ```
> Take Screenshot=Prendre une Capture d'Écran
> ```
> Notice that `Take Screenshot=` stays exactly the same. Only the text after `=` is translated.

**3. Restart mpv**

Close and reopen MPV-SW-Capture. Your language will now appear in the language selector (both in the menu's header button and in Setup → Apply Language).

> 💡 **Tip**: You don't need to translate every line. Any untranslated key falls back to English automatically, so you can start with a partial translation and improve it over time.

---

## 📋 Request, Issues and Comments

### 1. I have some comments, issues or requests about this project. Where can I share my opinion on GitHub?

- **Comments**: [Discussions](https://github.com/TyRaS-SW/MPV-SW-Capture/discussions)
- **Issues**: [Issues](https://github.com/TyRaS-SW/MPV-SW-Capture/issues)
- **Ideas / Requests**: [Ideas](https://github.com/TyRaS-SW/MPV-SW-Capture/discussions/categories/ideas)

### 2. Can I ask on another platform like Discord?

Yes! You can share comments/issues/requests and more in the official Discord: **[Official MPV-SW-Capture DISCORD](https://discord.gg/PaVutUUK9U)**.

---

## 📋 Troubleshooting

### 1. I tried opening `MPV.exe` (or its shortcut), but nothing happens. The screen doesn't open! What can I do?

Capture Cards are treated as Cameras in Windows.

Also, if you open your Capture Card with another software, you cannot use it in MPV-SW-Capture until you close the other software first.

For example, if you open the camera in Windows Settings → Bluetooth & devices → Cameras, and choose your Capture Card as Camera, you cannot use MPV-SW-Capture until you close it there.

This is a limitation that Capture Cards have by default.

If the window appears for a moment and then closes, it is usually because the capture device is not properly configured. Run `MPV-SW-Capture_SETUP.vbs`, select your capture card (video and audio), click "Save and Exit", and then launch the program again.

### 2. Can I open multiple windows with `MPV.exe`?

No. `MPV.exe` only accepts one window at the same time. Like the answer before, the Capture Card acts as one device, so this is normal.

### 3. I have more than one Capture Card connected. How can I change the default Capture Card?

With Setup, press **"Scan Device"** and choose the other Capture Card (video and audio) you want to use.

You must close and reopen MPV-SW-Capture to see the changes.

### 4. I ran `MPV-SW-Capture_INSTALLER.vbs` and nothing happened. What's wrong?

Most likely you're on a fresh install and `mpv.exe` doesn't exist yet. On a fresh install you must run **`1_INSTALLER_MSC_First-Usage.cmd`** first. See the **🛠️ Installation & Launchers** section for details.