#!/usr/bin/env python3
import sys
import os
from googletrans import Translator

def translate_file(input_file, output_file):
    translator = Translator()
    
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if not content or content.strip() == "":
        print("⚠️ Archivo vacío, no se traduce.")
        return
    
    print("📝 Traduciendo con Google Translate...")
    
    try:
        # Dividir en fragmentos para evitar límites de tamaño
        chunks = content.split('\n\n')
        translated_chunks = []
        
        for i, chunk in enumerate(chunks):
            if chunk.strip():
                print(f"🔄 Traduciendo fragmento {i+1}/{len(chunks)}...")
                translated = translator.translate(chunk, src='en', dest='es').text
                translated_chunks.append(translated)
            else:
                translated_chunks.append(chunk)
        
        translated_text = '\n\n'.join(translated_chunks)
        
    except Exception as e:
        print(f"❌ Error en traducción: {e}")
        sys.exit(1)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(translated_text)
    
    print(f"✅ Traducción guardada en: {output_file}")
    print(f"📊 Tamaño: {len(translated_text)} caracteres")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python translate_googletrans.py <input> <output>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if not os.path.exists(input_file):
        print(f"❌ Error: El archivo {input_file} no existe")
        sys.exit(1)
    
    translate_file(input_file, output_file)