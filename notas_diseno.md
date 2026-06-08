# Notas de diseño — Variante B

## Qué cambia respecto al parche original

El parche original (`app_parcheada.py`) tiene tres capas:

1. **Separación estructural** — `system=` separado del `user`.
2. **Blacklist de input** — substring matching de cadenas sospechosas.
3. **Blacklist de output** — substring matching de cifras prohibidas.

La variante B mantiene la capa 1 sin tocar (es la defensa más sólida) y
sustituye las capas 2 y 3 por **dos clasificadores con Claude Haiku**.

## Por qué es mejor

Las blacklists fallan en cuanto el atacante:

- Cambia de idioma (la lista solo cubre castellano).
- Usa sinónimos no listados ("descártalo" en lugar de "olvida").
- Codifica el ataque (base64, traducciones).
- Pide la información en formato indirecto que evita las cifras exactas
  (redondeos, en letras, en operaciones aritméticas).

El clasificador con LLM tiene comprensión semántica del intento. No le
importa si el ataque está en inglés, si usa sinónimos o si pide los
datos en letras: si el patrón conceptual es "intento de extracción de
información confidencial", lo marca.

## Por qué es peor

Tres costes que conviene reconocer:

- **Latencia.** Haiku 3.5 añade ~ 200–400 ms al input guardrail y ~
  200–400 ms al output guardrail. Total: ~ 400–800 ms por turno. Es
  asumible para un asistente de chat (la respuesta principal ya tarda
  varios segundos), pero no para sistemas de tiempo real.
- **Coste.** Dos llamadas adicionales por turno. Haiku es muy barato
  (céntimos por mil llamadas), pero a escala suma. Para un sistema de
  alto volumen, considerar guardrail solo en input y output con
  validación más ligera.
- **Falsos positivos.** El clasificador puede marcar como ataque mensajes
  legítimos que mencionan tarifas, presupuestos o ediciones. El prompt
  del guardrail intenta acotarlo dando ejemplos de qué NO es ataque,
  pero no hay garantías. Hay que monitorizar la tasa de falsos
  positivos en producción.

## Decisiones del prompt del guardrail

### Por qué clasificación binaria con palabra exacta

El prompt pide responder *exclusivamente* con `ATAQUE` o `LEGITIMO`. Un
clasificador que devuelve texto libre invita a parseo frágil. Una
respuesta de una palabra es trivial de evaluar (`startswith`).

Si el modelo no devuelve la palabra esperada por algún motivo (por
ejemplo, alucinación rara), `classify()` cae en el camino de error.

### Por qué fail-closed

Cuando el guardrail falla (excepción, timeout, respuesta inesperada),
asumimos que es un ataque y bloqueamos. Es preferible un falso positivo
("no puedo procesar esa solicitud") a dejar pasar un ataque por un fallo
del sistema. Esto es **fail-closed** y es la postura correcta para un
sistema de seguridad.

### Por qué dos prompts separados

El prompt de input clasifica intención del usuario; el prompt de output
clasifica contenido de la respuesta. Son tareas distintas y combinarlas
en un único clasificador habría diluido las dos.

## Cómo verificar que funciona mejor que la variante con blacklists

Los tres ataques originales y los tres de evasión de la variante A:

```bash
# Levantar el tercer servicio
docker compose up cenit-propuestas-parcheado-v2 -d

# Ataques originales (variante A)
ENDPOINT=http://localhost:8002/chat ./attacks/attack_1_extraccion_rol.sh
ENDPOINT=http://localhost:8002/chat ./attacks/attack_2_suplantacion.sh
ENDPOINT=http://localhost:8002/chat ./attacks/attack_3_simulacion_admin.sh

# Ataques de evasion de blacklists (deberian quedar bloqueados)
ENDPOINT=http://localhost:8002/chat ./attacks/attack_4_evasion.sh
```

Resultado esperable: los siete ataques son bloqueados por el guardrail
de input. El alumno *ve* que el clasificador con LLM aguanta lo que la
blacklist no aguantaba.

Para apreciar el contraste, ejecutar lo mismo contra el puerto 8001
(blacklists) y comparar:

```bash
ENDPOINT=http://localhost:8001/chat ./attacks/attack_4_evasion.sh
# pasa la blacklist y llega al modelo

ENDPOINT=http://localhost:8002/chat ./attacks/attack_4_evasion.sh
# bloqueado por el guardrail Haiku
```

## Cómo evadir incluso este parche

La variante B es más robusta pero no inviolable. Los vectores que pueden
seguir funcionando:

- **Ataques muy sutiles que no parecen ataques al clasificador.** Un
  mensaje muy contextualizado en el rol legítimo del asistente que
  acaba en una pregunta de extracción puede evadir Haiku.
- **Ataques split en varios turnos.** Si el sistema mantiene historial
  entre turnos, el atacante puede preparar el terreno con varios
  mensajes inocuos y disparar el ataque al final.
- **Indirect injection** desde una fuente externa que el modelo lea.
  Este sistema no tiene ese vector porque no tiene tools — pero un
  asistente con tools (módulo 6) sí.

La conclusión que se traslada al alumno: **el guardrail con LLM eleva
el coste del ataque, no lo elimina**. Para sistemas críticos, hay que
sumar las otras capas del módulo 7 (allowlist de herramientas, mínimo
privilegio, auditoría de acciones con efectos) que este chatbot simple
no necesita.
