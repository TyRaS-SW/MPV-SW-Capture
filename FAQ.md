# ❓ FAQ

## 🎮 General & Concept

### 1. Why use MPV to play Switch/2/PS/XB/Retro or any other HDMI compatible console?

MPV is a very capable and fast video player when configured correctly. It also lets you add shaders, bezels, crops and many other options, which expands it beyond "just playing" into something you can really customize for console gaming.

### 2. Why MPV and not another program?

There are other programs that let you capture video and do something similar to this project, but they tend to be more limited and do not allow the same level of customization that MPV-SW-Capture offers on top of MPV. On top that, most tend to increase the lag, making the experience unplayable.

---

## 🧩 Hardware & Capture Cards

### 1. Why do I need a capture card that supports 1080p60?

Because 1080p60 is the current standard quality for most modern consoles and capture devices. Targeting 1080p60 ensures good image quality and smooth gameplay.

### 2. Why do you recommend USB 3.0? What happens if I use USB 2.0?

USB 3.0 is recommended because it offers higher bandwidth, which translates into better image quality and more stable performance for high‑resolution, high‑frame‑rate video. You can still use USB 2.0, but quality and stability may be affected. If you have no other option, you can use it anyway, just keep this limitation in mind.

### 3. Can I use any USB HDMI capture card?

In theory, yes. However, for this project the recommendation is a capture card that supports 1080p60 and has loop‑through (HDMI input + HDMI output). There are relatively inexpensive options that are easy to find. One example you can search for is: "4K Ultra HD USB 3.0 HD Video Capture (MS 2131)". These devices accept up to 4K60 input and output 1080p60. For example, if you connect a console that supports 4K60, the capture card will accept that, but the final image used by MPV‑SW‑Capture will be 1080p60.

### 4. What about USB stick‑style capture cards that only have HDMI and USB, and usually support up to 720p60?

They should generally work, but they have not been tested with this project. If you try one and it works (or doesn’t), please share your results in the project so others can benefit from that information.

### 5. If I have a USB 3.0 capture card that can output more than 1080p60 (like 1440p60 or 4K60), will it work?

This scenario has not been tested either, but in principle it should work without major issues. If you try it, please share your results.

### 6. I have a console that only output up to 720p instead of 1080p, will it work?

Yes, this will work fine. For example, this was tested with a 720p only output, the result was an automatically upscale to 1080p. With this, all worked fine, even bezels, crops and shaders.

Also, it was tested with older consoles that support less than 720p (480p), connected with a AV to HDMI adapter, and the result is also an upscale to 1080p.

---

## 🎮 Software

### 1. What are the software we need to use with MPV-SW-Capture?

There are 3 software needed: `MPV` is the central one. `ffplay` and `ffmpeg` are also need to make it work.

That's why it needs to be downloaded and already explained in Instructions.

### 2. I followed the instructions and succesfully setup my `MPV-SW-Capture`. But, I noticed that the 3 software now have a newer version than I used before. Can I update them without breaking MPV-SW-Capture?

If you are talking about `MPV`, `ffplay` and `ffmpeg`, yes, you can update/replace the 3 software without problem. You need to download their new versions and replace the older with their newer ones.

That's all you need to do. And, it's always recommended have the newer version.

But, if you notice some problems, you can try older versions. If that even  happen, please comment the problem in **[Issues](https://github.com/TyRaS-SW/MPV-SW-Capture/issues)**, to check and fix that.

But, if you are talking about MPV-SW-Capture itself, the recommendation it's just replace all the files.

### 3. What this file, `Installer_MPV-SW-Capture.exe` do?

`Installer_MPV-SW-Capture.exe`, it's the new way to download and install/update `MPV-SW-Capture`, `ffplay`, `ffmpeg` and `mpv`. You use the installer and the program autoinstall all needed files. This means, that you can update new future versions of MPV-SW-Capture from the installer. Also, you can update all other needed programs to their latest versions, without the need of manual download.

You can still update in the old way. The instructions for that are separated here: **[MANUAL Install](https://github.com/TyRaS-SW/MPV-SW-Capture/wiki/MANUAL-Installation-Guide)**

### 4. I was using `Installer_MPV-SW-Capture.exe` and now I cannot update. Why this happened?

This is because of a limitation of Github. If you check a lot, Github limit to download again until 1 hour passed. You can only have this problem if you download, upgrade, etc.. in an exagerated quantity.

Since you are just updating or installing, this shouldn't be an issue. But, if you are having this problem, wait 1 hour or do a Manual Installation.

As a workaround, you can perform a **[Manual Installation](https://github.com/TyRaS-SW/MPV-SW-Capture/wiki/MANUAL-Installation-Guide)** while you wait, or simply wait the hour and try again. This limit is imposed by GitHub to prevent abuse.

### 5. How updates number work in MPV-SW-Capture?

When you see an update, you see 3 numbers digits, separated by dots. Here are represented in `X`, `Y`, `Z`:

v`X`.`Y`.`Z`.

- `X` = Very important update that must be updated.
- `Y` = Important update.
- `Z` = Minor patch or something small added.

---

## 🎨 Image, Shaders, Bezels, Crops & Shapes

### 1. Why do some shaders say 4K if I’m only using 1080p60?

Those shaders perform upscaling and image enhancement. If you have a 4K display, the image will better in 4K even if the input signal is 1080p60. This help to improve image in higher resolution than the original (1080p) one.

### 2. During setup, there is an option to auto‑enable the "👑1080p→4K Fast⚡" shader combo. Why is it recommended?

Because it's a very good combination of shaders that improve the image quality when you use fullscreen to 4K, while using very few resources. Since you have a maximum of of 1080p and you are expanding the image above that, up to 4K, this will help to have a less blurry and cleaned image.

### 3. I connected a Switch and use NSO, but when I apply a bezel or crop the image looks wrong (badly cut). How do I fix this?

This is usually caused by the black bar that NSO shows at the bottom with controls and help text. You need to disable that overlay. Open any NSO app, and before selecting a game go to the right side menu → Settings → Control Display → turn off "Show controls in game". Once that bar is gone, the image area is cleaner (bigger in some cases) and the crops and bezels will work correctly. Must be done in each NSO app.

### 4. How do I disable a shader, bezel, or crop?

- **Shader**: Use the "Clean Shader" option, or simply select a different shader (it replaces the previous one, they are not stacked).
- **Bezel**: Press the same bezel you selected before, or use the "Clear Bezels" option.
- **Crop**: Press the same crop option you selected to toggle it off, or use the "Clear Crop" option.
- **Shape**: Press the same shape option you selected to toggle it off, or use the "Clear Shape" option.

If you want to clear everything at once (for example, bezel, shader, shape), you can use the "Clean ALL" option.

### 5. I want to create my own bezels but I don’t know how. How do I do it?

Bezels are 1920x1080 PNG images. They are mainly used with NSO to replace the default borders with whatever artwork you want. The central area is where the game image goes; you just need to design the bezel so that the game area aligns correctly and looks good. A more detailed tutorial on how to create bezels and add them to the menu, you can go here: [Custom Bezels](https://github.com/TyRaS-SW/MPV-SW-Capture/wiki/Custom-Bezels)

### 6. Can I add my own shaders?

Yes, you can. Shaders must compatible for MPV, and in .glsl format.

You must put them in /shaders folder and edit menu.conf to add your shader, following the same format as other ones.

### 7. What are SHAPES? Why they have a specific separated Submenu?

SHAPES are shaders that do the specific function of change the Shape of the screen.

For example, you can change the screen to a CRT TV shape, so the screen has a curvature.

In an old version of MPV-SW-Capture, some shaders change the look to retro and change the shape of the screen, at the same time.

But, the shape was specific to that shader.

Now, this is separated, because you can change the shape and select whatever shader you want.

You can make any combination possible, without limits!

All older shaders that had a specific shape, now are "flat". So, you can choose to have the shader "flat" or combine with a shape, it's your choice.

---

## 📹 Recording & Screenshots

### 1. Why is the default recording limit only 30 seconds? Isn’t that too short?

You can actually record as long as you want. The 30‑second default exists because of the way recording works: while you play, the tool needs a temporary space on disk. It can use around 7–10 GB (for 30 seconds of record, 1 minute is twice the size) of free space on your HDD to store a temporary video file and a temporary audio file. After recording, both are merged into a compressed `.mp4` file without quality loss, and the temporary 7–10 GB files are deleted automatically.

If disk space is not a problem and you want a longer default duration, you can edit `scripts/record.lua` and change the number in `data.max_record_time =` to any value you want (in seconds).

### 2. I want to change the Default Record Video Time to more than the default 30 seconds. Can I do this without editing record.lua?

Yes, since v2.0.0 you can freely change the Default Record Time in Setup to 30/60/90/120 seconds.

### 3. Can I record less than the default time I choose?

Yes. Start recording from the menu, and if you press the same record button again before default time is over, the recording will stop immediately at that moment.

### 4. When I record a video, does it include bezels / crops / shaders?

No. The recorded video is captured as if none of these were active, regardless of what you are using. This is because recording happens "before" any of these effects are applied.

### 5. When I take a screenshot, does it include bezels / crops / shaders?

Yes. Screenshots are taken with whatever you have active at that moment. If you want a "clean" screenshot, just disable shaders (and any other overlay) before capturing.

### 6. Where are videos and screenshots stored?

They are saved inside the `_record` and `_screenshots` folders, located in the same folder where you installed MPV‑SW‑Capture.

It's not necessary to create them, because the software creates itself after taking a screenshot or record a video.

If, for a strange reason, you cannot record video and/or take screenshots, and you didn't have these folders, you can manually create them.

### 7. When recording a video, I see a counter with the time left to finish the record. Is that normal?

Yes, that is normal. With this you can check how much time left do you have for your video.

---

## 🧰 Menu, Window & Controls

### 1. How do I open the menu when the program starts?

Just right‑click on the window and the menu will open. Alternatively, you can press the `ESC` key on your keyboard, but make sure the mouse is over the MPV‑SW‑Capture window and the program is focused.

### 2. How do I close the program? I don’t see any "X" button to close it.

To close MPV‑SW‑Capture, open the menu and select the "QUIT" option.

### 3. Why do I see a check mark next to some options in the menu?

The check mark means that the option is currently enabled. Not every single option has a check mark, but most of them do. With this, you can quickly see what is active and what is not.

### 4. What is the "Info Stream" option and how do I hide it once it’s on?

"Info Stream" shows statistics about the current stream (resolution, resources usage, etc.). It is useful when you want to check what is going on internally. To hide it, simply select the "Info Stream" option again and the overlay will disappear.

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

On Windows, click the sound icon in the system tray, open the output/mixer panel, find the `ffplay` entry and adjust its volume to the level you want. That will change the volume for MPV‑SW‑Capture specifically.

In v2.1.0 you can change audio inside MPV-SW-Capture, without needing to change in output/mixer planel.

You can use Mouse's Wheel, Keyboard's keys and a new Submenu called "AUDIO" in MENU, to change the audio.

### 7. You say there are two programs, one for video and one for audio. What happens to audio if I close MPV‑SW‑Capture?

If you close the MPV‑SW‑Capture window, the audio closes as well. Both parts are designed to work together, so when MPV‑SW‑Capture is closed, the audio process with is also stopped and fully closed.

### 8. What happen if I use shaders/bezels/shapes/crops/any option, and I close the program?

Any option, anything you choose, only keep until you close MPV-SW-Capture.

So, if you open again, all will be the default options.

The only options that you can save to autostart, are some options you can choose in the Setup.

### 9. For MPV‑SW‑Capture you must use mouse to control the MENU, right? But, exist some keyboard and mouse shortcuts to some functions?

Yes, there are some functions that you can use with keyboard and mouse:

**a) Mouse:**

- **_Fullscreen_:** If you double click in the screen you can cycle fullscreen **ON** and **OFF**.
- **_Access to MENU_:** Press right click in the screen to access menu.
- **_Control Audio_:** If you use the Mouse's Wheel UP, you increase Volume. Wheel DOWN, decrease volume. You can keep rotating Wheel to find your desire volume.

**b) Keyboard:**

- **_Access to MENU_:** Press ESC key in the screen to access menu.
- **_Navigate in MENU_:** You can also use keyboard keys UP, DOWN, LEFT, RIGHT to navigate in MENU if you want.
- **_Quick Access_:** CTRL key + a key between 1 to 4, quick change to a selection of Shaders.
  - CTRL+5 is for Clean Shaders.
  - CTRL+0 is for Clean ALL.
- **_Control Audio_:** If you use the Keyboard's UP key, you increase Volume by +10. DOWN key, decrease volume by -10.
  - M key is a to Mute and pressing again is to Unmute.

### 10. How can I check which version of MPV-SW-Capture I have installed?

There are two ways:  
1. Visit the [official releases page](https://github.com/TyRaS-SW/MPV-SW-Capture/releases) to see the latest version available.  
2. Open MPV-SW-Capture, go to the menu **HELP → Check Latest MSC Version**. The program will tell you if you have the latest version or if an update is available.

---

## 🧰 Tools

### 🌐 Stream with OBS

#### 1. What is the Stream Manager and what is it used for?

The Stream Manager (MSCGUI) is a graphical tool located in the `tools/` folder that helps you configure OBS Studio to capture MPV-SW-Capture. It automates the installation of the `win-capture-audio` plugin, sets up scene collections, adds the required sources (Window Capture + Audio Capture), and includes a Streamer Mode to hide OSD messages. It also lets you switch between OBS **Installed** and **Portable** modes.

#### 2. Why does installing the win-capture-audio plugin in OBS (Installed mode) require administrator rights?

When OBS is installed in a protected system folder like `C:\Program Files`, writing files into its installation directory requires elevated permissions. The Stream Manager will detect this and prompt you to restart it as Administrator. In contrast, if you are using the **Portable** version of OBS (installed anywhere outside `Program Files`), no special permissions are needed.

#### 3. What is the difference between OBS Installed and OBS Portable in the context of MPV-SW-Capture?

- **Installed** OBS is the standard installation in `Program Files`. It is the most common but may require administrator rights to modify or install plugins.  
- **Portable** OBS is a self-contained version that you can place anywhere (e.g., on a USB drive). It does not require admin rights and allows you to carry your configuration with you. However, you need to download the ZIP version and extract it manually. The Stream Manager can help you download and set up both modes.

#### 4. How can I use MPV-SW-Capture with OBS more easily?

The Stream Manager (in the `tools/` folder) automates the entire process. It installs the `win-capture-audio` plugin, creates a scene collection, or adds the required sources to an existing collection. For detailed step-by-step guides, see:  
- [Stream Manager Guide](https://github.com/TyRaS-SW/MPV-SW-Capture/wiki/Guide-Stream-Manager)  
- [Installation Guide](https://github.com/TyRaS-SW/MPV-SW-Capture/wiki/Guide-Installation)

#### 5. What is the "Hide OSD Messages" option and how does it affect recording?

The option **"Hide OSD Messages"** is located in the menu under **OTHERS → Hide OSD Messages**. When enabled, it hides all on‑screen messages that appear when you select any option (e.g., shader changes, crop adjustments, etc.). This is ideal for streamers who don’t want these notifications to appear on their broadcast, or for users who simply prefer a cleaner interface.

**Important:** For safety reasons, the **RECORD VIDEO** function is completely disabled when "Hide OSD Messages" is active. You can only use recording when this option is turned off. This ensures that you are aware of the recording status and avoid accidentally capturing without visual feedback.

### 🖼 Bezel Manager

#### 1. What is `MSC_Bezel_Manager.exe` and what is it used for?

`MSC_Bezel_Manager.exe` is a tool located in the `tools/` folder that allows you to manage and customize bezels (decorative borders) for MPV-SW-Capture. With it, you can:
- Preview bezels before applying them.
- Add new bezels to the menu (by placing your PNG images in the appropriate folder and updating the configuration).
- Remove or reorganize existing bezels.

This tool simplifies the process of creating and using custom bezels without editing configuration files manually. For a detailed guide, see the [Custom Bezels](https://github.com/TyRaS-SW/MPV-SW-Capture/wiki/Custom-Bezels) page.

### 🎞 Video Manager

#### 1. What is `MSC_Video_Manager.exe` and what is it used for?

`MSC_Video_Manager.exe` is a graphical tool located in the `tools/` folder that lets you adjust advanced video parameters for MPV-SW-Capture without editing `mpv.conf` directly. You can modify settings such as:
- Video latency
- Audio buffer size
- Hardware decoding (`hwdec`)
- GPU rendering options (`vo=gpu`)
- And other performance‑related options

This tool is especially useful for users who want to fine‑tune performance and quality but prefer a user‑friendly interface over manual configuration files.

---

## 📋 Language

### 1. With v2.0.0, I noticed that you can change language from English and Spanish. How works?

With the new GUI setup in v2.0.0 you can easily change the language only using the button **"MENU: English <- -> Espanol"** in `Setup_MPV-SW-Capture.exe`.

You press the button and automatically updates all text from English to Spanish. If you press again, you can change from Spanish to English.

Note: You can only see the changes in languages after you close MPV-SW-Capture and open it again.

### 2. What do you translate with the button?

Nearly all. MENU is nearly complete translated to Spanish.

MPV-SW-Capture messages are also translated!

### 3. Does the language selection persist across all programs (Setup, Installer, Tools)?

Yes, the language you choose in any of the programs – such as `Setup_MPV-SW-Capture.exe`, `Installer_MPV-SW-Capture.exe`, or any of the tools (e.g., Stream Manager, Video Manager, Bezel Manager) – is saved and automatically loaded across all of them.

For example, if you open the Setup and change the language to Spanish, then close it and reopen it, the language will remain Spanish. Additionally, if you later open the Installer, it will also start in Spanish, reflecting the same preference.

---

## 📋 Request, Issues and Comments

### 1. I have some comments about this proyects. Where can I share my opinion?

You can share your comments here: **[Discussions](https://github.com/TyRaS-SW/MPV-SW-Capture/discussions)**

### 2. I have some issues. Where I can comment my issues?

You can share your issues here: **[Issues](https://github.com/TyRaS-SW/MPV-SW-Capture/issues)**

### 3. I have some ideas/requests. Can I share them? And where?

You can share your ideas/request here: **[Ideas](https://github.com/TyRaS-SW/MPV-SW-Capture/discussions/categories/ideas)**

---

## 📋 Troubleshooting

### 1. I tried opening `MPV-SW-Capture.exe` (or shortcut), but nothing happen. The screen doesn't open! What can I do?

Capture Cards are treated as Cameras in Windows.

Also, if you open your Capture Card with another software, you cannot use it in MPV-SW-Capture, until you close the other software first.

For example, if you open the camera in Windows Settings -> Bluetooth & devices -> Cameras, and choose your Capture Card as Camera, you cannot use MPV-SW-Capture until you close there.

This is a limitation that Capture Cards have by default.

If the window appears for a moment and then closes, it is usually because the capture device is not properly configured. Run `Setup_MPV-SW-Capture.exe`, select your capture card (video and audio), click "Save and Exit", and then launch the program again.

### 2. Can you open multiple windows with `MPV-SW-Capture.exe`?

No. MPV-SW-Capture.exe only accept one window at the same time. Like the answer before, the Capture Card act as one device, so this is normal.

### 3. I have more than one Capture Card connected. How can I change the default Capture Card?

With Setup, press **"Scan Device"** and choose the other Capture Card (video and audio) you want to use.

You must close and open again MPV-SW-Capture to see the changes.