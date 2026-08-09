#!/usr/bin/env python3
import os
import sys
from openai import OpenAI

def translate_file(input_file, output_file):
    # Obtener el token de GitHub desde las variables de entorno
    github_token = os.environ.get("GITHUB_TOKEN")
    if not github_token:
        print("❌ Error: GITHUB_TOKEN no encontrado en las variables de entorno")
        sys.exit(1)

    # Configurar el cliente para usar GitHub Models
    client = OpenAI(
        base_url="https://models.inference.ai.azure.com",
        api_key=github_token
    )

    # Leer el archivo original
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    if not content or content.strip() == "":
        print(f"⚠️ El archivo {input_file} está vacío. No se traducirá.")
        return

    print(f"📝 Traduciendo {input_file}...")

    # Instrucciones para la IA
    system_prompt = """Eres un traductor profesional especializado en documentación técnica.

Traduce el siguiente texto de inglés a español.

Reglas:
- Mantén en inglés los términos técnicos: OBS, plugin, stream, GitHub, API, GUI, CLI.
- NO traduzcas bloques de código, URLs, ni rutas de archivos.
- Preserva exactamente la sintaxis de Markdown (encabezados, listas, negritas, etc.).
- Mantén el formato y la estructura del documento.
- La traducción debe ser natural y clara en español."""

    try:
        # Realizar la traducción usando GitHub Models
        response = client.chat.completions.create(
            model="gpt-4o-mini",  # Modelo gratuito y rápido
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": content}
            ],
            temperature=0.3
        )

        translated = response.choices[0].message.content

        # Guardar el resultado
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(translated)

        print(f"✅ Traducción guardada en: {output_file}")
        print(f"📊 Tokens usados: {response.usage.total_tokens}")

    except Exception as e:
        print(f"❌ Error durante la traducción: {e}")
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