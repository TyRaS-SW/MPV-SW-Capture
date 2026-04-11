\# ❓ FAQ



\## 🎮 General \& Concept



\### Why use MPV to play Switch / other consoles?



MPV is a very capable and fast video player when configured correctly. It also lets you add shaders, bezels, crops and many other options, which expands it beyond “just playing” into something you can really customize for console gaming.



\### Why MPV and not another program?



There are other programs that let you capture video and do something similar to this project, but they tend to be more limited and do not allow the same level of customization that MPV-SW-Capture offers on top of MPV.



\---



\## 🧩 Hardware \& Capture Cards



\### Why do I need a capture card that supports 1080p60?



Because 1080p60 is the current standard quality for most modern consoles and capture devices. Targeting 1080p60 ensures good image quality and smooth gameplay.



\### Why do you recommend USB 3.0? What happens if I use USB 2.0?



USB 3.0 is recommended because it offers higher bandwidth, which translates into better image quality and more stable performance for high‑resolution, high‑frame‑rate video. You can still use USB 2.0, but quality and stability may be affected. If you have no other option, you can use it anyway, just keep this limitation in mind.



\### Can I use any USB HDMI capture card?



In theory, yes. However, for this project the recommendation is a capture card that supports 1080p60 and has loop‑through (HDMI input + HDMI output). There are relatively inexpensive options that are easy to find. One example you can search for is: “4K Ultra HD USB 3.0 HD Video Capture (MS 2131)”. These devices accept up to 4K60 input and output 1080p60. For example, if you connect a console that supports 4K60, the capture card will accept that, but the final image used by MPV‑SW‑Capture will be 1080p60.



\### What about USB stick‑style capture cards that only have HDMI and USB, and usually support up to 720p60?



They should generally work, but they have not been tested with this project. If you try one and it works (or doesn’t), please share your results in the project so others can benefit from that information.



\### If I have a USB 3.0 capture card that can output more than 1080p60 (like 1440p60 or 4K60), will it work?



This scenario has not been tested either, but in principle it should work without major issues. If you try it, please share your results.



\---



\## 🎨 Image, Shaders, Bezels \& Crops



\### Why do some shaders say 4K if I’m only using 1080p60?



Those shaders perform upscaling and image enhancement. If you have a 4K display, the image will look very close to native 4K even if the input signal is 1080p60.



\### During setup, there is an option to auto‑enable the “👑1080p→4K Fast⚡” shader combo. Why is it recommended?



Because it is a very good combination of shaders that upscales to 4K while using very few resources. You get a cleaner and improved image compared to the original. If you have a 4K monitor or TV and use full screen, it will look very close to a native 4K signal.



\### I connected a Switch and use NSO, but when I apply a bezel or crop the image looks wrong (badly cut). How do I fix this?



This is usually caused by the black bar that NSO shows at the bottom with controls and help text. You need to disable that overlay. Open any NSO app, and before selecting a game go to the right side menu → Settings → Control Display → turn off “Show controls in game”. Once that bar is gone, the image area is cleaner (bigger in some cases) and the crops and bezels will work correctly. Must be done in each NSO app.



\### How do I disable a shader, bezel, or crop?



\- Shader: Use the “Clean Shader” option, or simply select a different shader (it replaces the previous one, they are not stacked).

\- Bezel: Press the same bezel you selected before, or use the “Clear Bezels” option.

\- Crop: Press the same crop option you selected to toggle it off.



If you want to clear everything at once (for example, bezel + shader), you can use the “Clean ALL” option.



\### I want to create my own bezels but I don’t know how. How do I do it?



Bezels are 1920x1080 PNG images. They are mainly used with NSO to replace the default borders with whatever artwork you want. The central area is where the game image goes; you just need to design the bezel so that the game area aligns correctly and looks good. A more detailed tutorial on how to create bezels and add them to the menu will be provided later.



\---



\## 📹 Recording \& Screenshots



\### Why is the default recording limit only 30 seconds? Isn’t that too short?



You can actually record as long as you want. The 30‑second default exists because of the way recording works: while you play, the tool needs a temporary space on disk. It can use around 7–10 GB (for 30 seconds of record, 1 minute is twice the size) of free space on your HDD to store a temporary video file and a temporary audio file. After recording, both are merged into a compressed `.mp4` file without quality loss, and the temporary 7–10 GB files are deleted automatically.



If disk space is not a problem and you want a longer default duration, you can edit `scripts/record.lua` and change the number in `data.max\_record\_time =` to any value you want (in seconds).



\### Can I record less than 30 seconds without changing the default time?



Yes. Start recording from the menu, and if you press the same record button again before the 30 seconds are over, the recording will stop immediately at that moment.



\### When I record a video, does it include bezels / crops / shaders?



No. The recorded video is captured as if none of these were active, regardless of what you are using. This is because recording happens “before” any of these effects are applied.



\### When I take a screenshot, does it include bezels / crops / shaders?



Yes. Screenshots are taken with whatever you have active at that moment. If you want a “clean” screenshot, just disable shaders (and any other overlay) before capturing.



\### Where are videos and screenshots stored?



They are saved inside the `\_record` and `\_screenshots` folders, located in the same folder where you installed MPV‑SW‑Capture.



\### When recording a video, I see some CMD windows appear and disappear at the start. Is that normal?



Yes, that is normal. Those console windows are part of the script that handles recording. They are expected and you can safely ignore them.



\---



\## 🧰 Menu, Window \& Controls



\### How do I open the menu when the program starts?



Just right‑click on the window and the menu will open. Alternatively, you can press the `ESC` key on your keyboard, but make sure the mouse is over the MPV‑SW‑Capture window and the program is focused.



\### How do I close the program? I don’t see any “X” button to close it.



To close MPV‑SW‑Capture, open the menu and select the “QUIT” option.



\### Why do I see a check mark next to some options in the menu?



The check mark means that the option is currently enabled. Not every single option has a check mark, but most of them do. It is there so you can quickly see what is active and what is not.



\### What is the “Info Stream” option and how do I hide it once it’s on?



“Info Stream” shows statistics about the current stream (resolution, resources usage, etc.). It is useful when you want to check what is going on internally. To hide it, simply select the “Info Stream” option again and the overlay will disappear.



\### In the menu there are many options under WINDOW. What are they for?



These options let you customize the MPV‑SW‑Capture window as you like.

\- You can change the size from 0.5x to 2.0x, or go full screen. You can also set a specific position for the window.

\- “Always on Top” keeps the window above other windows (press it again to disable).

\- “Stretch Window” lets you stretch the current image to a wider aspect ratio (for example, from 16:9 to 21:9, or from 4:3 to 16:9). This is especially useful with NSO: if you have a 4:3 game, you can apply a crop and then “Stretch Window” to fill a 16:9 area.

\- “Mini Mode” sets the window to a smaller 0.3x size and moves it to the bottom‑right corner of the screen.



\### How can I change the volume of MPV‑SW‑Capture independently in Windows?



On Windows, click the sound icon in the system tray, open the output/mixer panel, find the `ffplay` entry and adjust its volume to the level you want. That will change the volume for MPV‑SW‑Capture specifically.



\### You say there are two programs, one for video and one for audio. What happens to audio if I close MPV‑SW‑Capture?



If you close the MPV‑SW‑Capture window, the audio closes as well. Both parts are designed to work together, so when MPV‑SW‑Capture is closed, the audio process with is also stopped and fully closed.

