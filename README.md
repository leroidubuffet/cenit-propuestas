# Cenit Propuestas — laboratorio de seguridad módulo 7

Tres versiones del mismo chatbot para demostrar y mitigar vulnerabilidades
de prompt injection en sistemas con LLMs.

| Puerto | Versión | Modelo | Qué demuestra |
|--------|---------|--------|---------------|
| 8000 | `app_vulnerable.py` | Llama 3.1 8B (Groq) | System prompt concatenado al input del usuario en el rol `user`. Los tres ataques tienen éxito. |
| 8001 | `app_parcheada.py` | Claude Sonnet 4.6 | Separación estructural (`system=`) + blacklists. El flag `DISABLE_BLACKLISTS` permite aislar cada capa. |
| 8002 | `app_parcheada_v2.py` | Claude Sonnet 4.6 + Haiku 4.5 | Separación estructural + guardrails semánticos con Claude Haiku. Resiste también los ataques de evasión. |

> **Por qué modelos distintos en cada puerto:** Llama 3.1 8B (Groq) se eligió para el puerto 8000 porque, a diferencia de los modelos Claude actuales, no tiene entrenamiento de seguridad suficiente para resistir inyecciones directas por sí solo; esto hace que la vulnerabilidad estructural (system prompt en el rol `user`) sea observable sin necesidad de modificar el código. Los puertos 8001 y 8002 usan Claude Sonnet 4.6, un modelo más robusto, para demostrar que las defensas implementadas en el código funcionan incluso cuando el modelo subyacente es capaz de resistir los ataques por sí mismo.

---

## Requisitos

- Docker y Docker Compose (24.0 / 2.20 o superior)
- Clave de API de Anthropic (`sk-ant-...`) con saldo disponible — para puertos 8001 y 8002
- Clave de API de Groq (gratuita en console.groq.com) — para el puerto 8000
- Python 3.8 o superior (para formatear salidas con `python3 -m json.tool`)
- `jq` (para los scripts de ataque: `brew install jq` / `sudo apt install jq`)
- `curl`

---

## Paso 0: configuración inicial

```bash
cp .env.example .env
```

Editar `.env` y añadir las dos claves:

```
ANTHROPIC_API_KEY=sk-ant-...
GROQ_API_KEY=gsk_...
```

La clave de Groq se obtiene en **console.groq.com → API Keys → Create API Key** (cuenta gratuita, sin tarjeta).

```bash
docker compose build
```

---

## Paso 1: atacar el sistema vulnerable

### 1.1 Levantar el servicio vulnerable

```bash
docker compose up cenit-propuestas-vulnerable -d
```

Verificar que está listo antes de continuar:

```bash
curl -s http://localhost:8000/
# Debe devolver: {"servicio": "Cenit Propuestas", "version": "vulnerable", ...}
```

### 1.2 Lanzar los ataques

```bash
./attacks/attack_1_extraccion_rol.sh
./attacks/attack_2_suplantacion.sh
./attacks/attack_3_simulacion_admin.sh
```

Los tres deben revelar las tarifas internas o confirmar acciones falsas.
Registra los resultados en `EXERCISE_NOTES.md`.

---

## Paso 2: aplicar defensas y comprobar su efecto

### 2.1 Separación estructural sola (sin blacklists)

```bash
docker compose down
DISABLE_BLACKLISTS=true docker compose up cenit-propuestas-parcheado -d
```

Verificar que está listo:

```bash
curl -s http://localhost:8001/
# Debe devolver: {..., "blacklists_activas": false}
```

Repetir los ataques contra el servicio parcheado:

```bash
ENDPOINT=http://localhost:8001/chat ./attacks/attack_1_extraccion_rol.sh
ENDPOINT=http://localhost:8001/chat ./attacks/attack_2_suplantacion.sh
ENDPOINT=http://localhost:8001/chat ./attacks/attack_3_simulacion_admin.sh
```

Los tres ataques quedan bloqueados. El modelo los rechaza porque el system prompt
llega a través del campo `system=` con autoridad estructural, no como texto de
usuario que se puede sobreescribir. No hay ningún filtro activo: la resistencia
la aporta la separación estructural.

### 2.2 Añadir blacklists

```bash
docker compose down
docker compose up cenit-propuestas-parcheado -d
```

Verificar que está listo:

```bash
curl -s http://localhost:8001/
# Debe devolver: {..., "blacklists_activas": true}
```

Repetir los ataques:

```bash
ENDPOINT=http://localhost:8001/chat ./attacks/attack_1_extraccion_rol.sh
ENDPOINT=http://localhost:8001/chat ./attacks/attack_2_suplantacion.sh
ENDPOINT=http://localhost:8001/chat ./attacks/attack_3_simulacion_admin.sh
```

Los tres ataques quedan bloqueados. Ver las alertas en los logs:

```bash
docker compose logs cenit-propuestas-parcheado | grep ALERTA
```

### 2.3 Evadir las blacklists

Sin cambiar el servicio que ya está levantado:

```bash
ENDPOINT=http://localhost:8001/chat ./attacks/attack_4_evasion.sh
```

Las tres variantes (idioma distinto, sinónimos, proporción indirecta) evaden
el filtro de input y llegan al modelo. El filtro de output puede capturar la
respuesta si el modelo incluye términos de la lista; en ese caso la respuesta
es "No puedo responder a esa pregunta." en lugar de la información filtrada.
La lección es que las blacklists son frágiles en ambas capas: el vocabulario
conocido es finito y cualquier reformulación puede saltárselo.

---

## Paso 3 (bonus): guardrails semánticos con Haiku

```bash
docker compose down
docker compose up cenit-propuestas-parcheado-v2 -d
```

Verificar que está listo:

```bash
curl -s http://localhost:8002/
```

Los seis ataques (3 originales + 3 evasión) deben quedar bloqueados:

```bash
ENDPOINT=http://localhost:8002/chat ./attacks/attack_1_extraccion_rol.sh
ENDPOINT=http://localhost:8002/chat ./attacks/attack_2_suplantacion.sh
ENDPOINT=http://localhost:8002/chat ./attacks/attack_3_simulacion_admin.sh
ENDPOINT=http://localhost:8002/chat ./attacks/attack_4_evasion.sh
```

Contraste directo entre blacklist y guardrail semántico:

```bash
# Pasa la blacklist
ENDPOINT=http://localhost:8001/chat ./attacks/attack_4_evasion.sh

# Bloqueado por el guardrail Haiku
ENDPOINT=http://localhost:8002/chat ./attacks/attack_4_evasion.sh
```

---

## Parar los servicios

```bash
# Parar todos los contenedores (los mantiene para volver a levantarlos)
docker compose stop

# Parar y eliminar los contenedores
docker compose down

# Parar y eliminar contenedores, imágenes y volúmenes
docker compose down --rmi all
```

---

## Documentación adicional

| Archivo | Contenido |
|---------|-----------|
| `EXERCISE_NOTES.md` | Plantilla para que el alumno registre resultados y reflexiones |
| `guia_docente.md` | Guión de sesión con tiempos, notas por fase y troubleshooting |
| `notas_diseno.md` | Decisiones técnicas de la variante B: por qué es mejor, por qué es peor, cómo evadir incluso ese parche |
