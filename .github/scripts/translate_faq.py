#!/usr/bin/env python3
import os
import sys
import json
from openai import OpenAI

def translate_file(input_file, output_file):
    github_token = os.environ.get("GITHUB_TOKEN")
    if not github_token:
        print("❌ Error: GITHUB_TOKEN no encontrado")
        sys.exit(1)

    # Configurar cliente para GitHub Models
    client = OpenAI(
        base_url="https://models.inference.ai.azure.com",
        api_key=github_token,
        default_headers={"api-version": "2024-05-01-preview"}  # Versión requerida
    )

    # Leer archivo
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    if not content or content.strip() == "":
        print(f"⚠️ El archivo {input_file} está vacío.")
        return

    print(f"📝 Traduciendo {input_file}...")

    system_prompt = """Eres un traductor profesional especializado en documentación técnica.

Traduce el siguiente texto de inglés a español.

Reglas:
- Mantén en inglés los términos técnicos: OBS, plugin, stream, GitHub, API, GUI, CLI.
- NO traduzcas bloques de código, URLs, ni rutas de archivos.
- Preserva exactamente la sintaxis de Markdown (encabezados, listas, negritas, etc.).
- Mantén el formato y la estructura del documento.
- La traducción debe ser natural y clara en español."""

    models_to_try = ["gpt-4o-mini", "gpt-4o", "gpt-35-turbo"]

    for model in models_to_try:
        try:
            print(f"🔄 Intentando con modelo: {model}")
            response = client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": content}
                ],
                temperature=0.3
            )

            translated = response.choices[0].message.content
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(translated)

            print(f"✅ Traducción guardada en: {output_file}")
            print(f"📊 Tokens usados: {response.usage.total_tokens}")
            return  # Salir si funcionó

        except Exception as e:
            error_msg = str(e)
            print(f"⚠️ Error con {model}: {error_msg}")
            # Si el error contiene detalles, mostrarlos
            if hasattr(e, 'response') and e.response:
                try:
                    print(f"Detalles: {e.response.text}")
                except:
                    pass
            continue

    print("❌ No se pudo traducir con ningún modelo.")
    sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python translate_faq.py <archivo_entrada> <archivo_salida>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    if not os.path.exists(input_file):
        print(f"❌ Error: El archivo {input_file} no existe")
        sys.exit(1)

    translate_file(input_file, output_file)