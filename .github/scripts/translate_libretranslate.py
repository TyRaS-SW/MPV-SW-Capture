#!/usr/bin/env python3
import requests
import json
import sys
import os
import time

def translate_file(input_file, output_file, source_lang="en", target_lang="es", retries=3):
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if not content or content.strip() == "":
        print(f"⚠️ El archivo {input_file} está vacío.")
        return
    
    # Dividir el contenido en fragmentos más pequeños para evitar límites de tamaño
    # LibreTranslate tiene un límite de aproximadamente 1000 caracteres por petición
    # Vamos a dividir por párrafos o líneas vacías
    paragraphs = content.split('\n\n')
    translated_paragraphs = []
    
    for idx, paragraph in enumerate(paragraphs):
        if not paragraph.strip():
            translated_paragraphs.append("")
            continue
        
        # Si el párrafo es muy largo, dividirlo en oraciones
        if len(paragraph) > 900:
            # Dividir por puntos y saltos de línea
            chunks = paragraph.split('. ')
            translated_chunks = []
            for chunk in chunks:
                if chunk.strip():
                    translated_chunk = translate_chunk(chunk.strip(), source_lang, target_lang, retries)
                    translated_chunks.append(translated_chunk)
            translated_paragraph = '. '.join(translated_chunks)
        else:
            translated_paragraph = translate_chunk(paragraph, source_lang, target_lang, retries)
        
        translated_paragraphs.append(translated_paragraph)
        
        # Pequeña pausa para no sobrecargar el servidor
        time.sleep(0.5)
    
    final_text = '\n\n'.join(translated_paragraphs)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(final_text)
    
    print(f"✅ Traducción guardada en: {output_file}")

def translate_chunk(text, source_lang, target_lang, retries):
    url = "https://translate.argosopentech.com/translate"
    
    payload = {
        "q": text,
        "source": source_lang,
        "target": target_lang,
        "format": "text"
    }
    
    headers = {
        "Content-Type": "application/json"
    }
    
    for attempt in range(retries):
        try:
            response = requests.post(url, json=payload, headers=headers, timeout=30)
            if response.status_code == 200:
                result = response.json()
                return result.get("translatedText", text)
            else:
                print(f"⚠️ Error {response.status_code}: {response.text}")
                if attempt < retries - 1:
                    time.sleep(2 ** attempt)  # Espera exponencial
        except Exception as e:
            print(f"⚠️ Error en intento {attempt+1}: {e}")
            if attempt < retries - 1:
                time.sleep(2 ** attempt)
    
    print(f"⚠️ No se pudo traducir el fragmento: {text[:50]}...")
    return text  # Devuelve el original si falla

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python translate_libretranslate.py <archivo_entrada> <archivo_salida>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if not os.path.exists(input_file):
        print(f"❌ Error: El archivo {input_file} no existe")
        sys.exit(1)
    
    translate_file(input_file, output_file)