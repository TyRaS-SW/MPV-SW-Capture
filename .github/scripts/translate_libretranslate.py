#!/usr/bin/env python3
import sys
import os
from deep_translator import GoogleTranslator

def translate_file(input_file, output_file):
    translator = GoogleTranslator(source='en', target='es')
    
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if not content or content.strip() == "":
        print("⚠️ Archivo vacío, no se traduce.")
        return
    
    print("📝 Traduciendo con Google Translate (deep-translator)...")
    
    # Dividir en fragmentos para evitar límites de tamaño
    chunks = content.split('\n\n')
    translated_chunks = []
    total = len(chunks)
    
    for i, chunk in enumerate(chunks):
        if chunk.strip():
            print(f"🔄 Traduciendo fragmento {i+1}/{total}...")
            try:
                translated = translator.translate(chunk)
                translated_chunks.append(translated)
            except Exception as e:
                print(f"⚠️ Error en fragmento {i+1}: {e}")
                # Si falla, mantener el original
                translated_chunks.append(chunk)
        else:
            translated_chunks.append(chunk)
    
    translated_text = '\n\n'.join(translated_chunks)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(translated_text)
    
    print(f"✅ Traducción guardada en: {output_file}")
    print(f"📊 Tamaño: {len(translated_text)} caracteres")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python translate_libretranslate.py <input> <output>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if not os.path.exists(input_file):
        print(f"❌ Error: El archivo {input_file} no existe")
        sys.exit(1)
    
    translate_file(input_file, output_file)