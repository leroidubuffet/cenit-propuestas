# Cenit Propuestas — laboratorio de seguridad módulo 7

Tres versiones del mismo chatbot para demostrar y mitigar vulnerabilidades
de prompt injection en sistemas con LLMs.

| Puerto | Versión | Qué demuestra |
|--------|---------|---------------|
| 8000 | `app_vulnerable.py` | System prompt concatenado al input del usuario en el rol `user`. Los tres ataques tienen éxito. |
| 8001 | `app_parcheada.py` | Separación estructural (`system=`) + blacklists. El flag `DISABLE_BLACKLISTS` permite aislar cada capa. |
| 8002 | `app_parcheada_v2.py` | Separación estructural + guardrails semánticos con Claude Haiku. Resiste también los ataques de evasión. |

---

## Requisitos

- Docker y Docker Compose (24.0 / 2.20 o superior)
- Clave de API de Anthropic (`sk-ant-...`) con saldo disponible
- Python 3.8 o superior (para formatear salidas con `python3 -m json.tool`)
- `jq` (para los scripts de ataque: `brew install jq` / `sudo apt install jq`)
- `curl`

---

## Configuración inicial

```bash
cp .env.example .env
# Editar .env y añadir la clave real
docker compose build
```

---

## Levantar los servicios

```bash
# Solo el vulnerable (fase de ataque)
docker compose up cenit-propuestas-vulnerable -d

# Solo el parcheado con blacklists activas (defecto)
docker compose up cenit-propuestas-parcheado -d

# Solo el parcheado con blacklists desactivadas (solo separacion estructural)
DISABLE_BLACKLISTS=true docker compose up cenit-propuestas-parcheado -d

# Los tres a la vez
docker compose up -d

# Ver logs de alertas en tiempo real
docker compose logs -f cenit-propuestas-parcheado | grep ALERTA
```

---

## Fase 1: ataques contra el sistema vulnerable (puerto 8000)

```bash
# Ataque 1: extraccion de rol
./attacks/attack_1_extraccion_rol.sh

# Ataque 2: suplantacion de contexto
./attacks/attack_2_suplantacion.sh

# Ataque 3: simulacion administrativa
./attacks/attack_3_simulacion_admin.sh
```

Los tres deben revelar las tarifas internas o confirmar acciones falsas.

---

## Fase 2.1: separacion estructural sola (puerto 8001, blacklists off)

```bash
docker compose down
DISABLE_BLACKLISTS=true docker compose up cenit-propuestas-parcheado -d

ENDPOINT=http://localhost:8001/chat ./attacks/attack_1_extraccion_rol.sh
ENDPOINT=http://localhost:8001/chat ./attacks/attack_2_suplantacion.sh
ENDPOINT=http://localhost:8001/chat ./attacks/attack_3_simulacion_admin.sh
```

Los ataques 1 y 2 se debilitan notablemente. El modelo resiste por separacion
estructural, no por filtros.

---

## Fase 2.2: anadir blacklists (puerto 8001, blacklists on)

```bash
docker compose down
docker compose up cenit-propuestas-parcheado -d

ENDPOINT=http://localhost:8001/chat ./attacks/attack_1_extraccion_rol.sh
ENDPOINT=http://localhost:8001/chat ./attacks/attack_2_suplantacion.sh
ENDPOINT=http://localhost:8001/chat ./attacks/attack_3_simulacion_admin.sh
```

Los tres ataques son bloqueados. Ver alertas en los logs:

```bash
docker compose logs cenit-propuestas-parcheado | grep ALERTA
```

---

## Fase 2.3: evasion de las blacklists

```bash
ENDPOINT=http://localhost:8001/chat ./attacks/attack_4_evasion.sh
```

Las tres variantes (idioma distinto, sinonimos, redondeo) pasan los filtros
y llegan al modelo. La blacklist solo cubre el vocabulario conocido.

---

## Bonus: guardrails semanticos con Haiku (puerto 8002)

```bash
docker compose up cenit-propuestas-parcheado-v2 -d

# Los siete ataques (3 originales + 4 evasion) deben quedar bloqueados
ENDPOINT=http://localhost:8002/chat ./attacks/attack_1_extraccion_rol.sh
ENDPOINT=http://localhost:8002/chat ./attacks/attack_2_suplantacion.sh
ENDPOINT=http://localhost:8002/chat ./attacks/attack_3_simulacion_admin.sh
ENDPOINT=http://localhost:8002/chat ./attacks/attack_4_evasion.sh
```

Para ver el contraste directamente:

```bash
# Pasa la blacklist
ENDPOINT=http://localhost:8001/chat ./attacks/attack_4_evasion.sh

# Bloqueado por el guardrail Haiku
ENDPOINT=http://localhost:8002/chat ./attacks/attack_4_evasion.sh
```

---

## Consulta rapida

```bash
curl -s http://localhost:8000/   # estado del servicio vulnerable
curl -s http://localhost:8001/   # estado del servicio parcheado (incluye blacklists_activas)
curl -s http://localhost:8002/   # estado del servicio con guardrails
```

---

## Documentacion adicional

| Archivo | Contenido |
|---------|-----------|
| `EXERCISE_NOTES.md` | Plantilla para que el alumno registre resultados y reflexiones |
| `guia_docente.md` | Guion de sesion con tiempos, notas por fase y troubleshooting |
| `notas_diseno.md` | Decisiones tecnicas de la variante B: por que es mejor, por que es peor, como evadir incluso ese parche |
