#!/usr/bin/env python3
import os
import sys
import time
import deepl

def translate_file(input_file, output_file):
    api_key = os.environ.get("DEEPL_API_KEY")
    if not api_key:
        print("❌ Error: DEEPL_API_KEY no encontrada en variables de entorno")
        sys.exit(1)

    translator = deepl.Translator(api_key)

    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    if not content.strip():
        print("⚠️ Archivo vacío, no se traduce.")
        return

    print(f"📝 Traduciendo con DeepL (caracteres: {len(content)})...")

    try:
        # DeepL maneja bien texto largo, pero dividimos en párrafos por seguridad
        paragraphs = content.split('\n\n')
        translated_paragraphs = []

        for i, para in enumerate(paragraphs):
            if para.strip():
                print(f"🔄 Fragmento {i+1}/{len(paragraphs)}...")
                translated = translator.translate_text(para, target_lang="ES")
                translated_paragraphs.append(translated.text)
                # Pequeña pausa para evitar rate limiting
                time.sleep(0.1)
            else:
                translated_paragraphs.append(para)

        translated_text = '\n\n'.join(translated_paragraphs)

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(translated_text)

        print(f"✅ Traducción guardada en: {output_file}")
        print(f"📊 Tamaño: {len(translated_text)} caracteres")

    except Exception as e:
        print(f"❌ Error en traducción: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python translate_deepl.py <input> <output>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    if not os.path.exists(input_file):
        print(f"❌ Error: El archivo {input_file} no existe")
        sys.exit(1)

    translate_file(input_file, output_file)