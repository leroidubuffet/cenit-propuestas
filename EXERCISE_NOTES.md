# Notas del ejercicio del modulo 7

> Plantilla. Rellena las secciones segun avanzas.

## Fase 1, ataques al sistema vulnerable (puerto 8000)

Para cada ataque, anota la respuesta del sistema y si revela algo
confidencial.

### Ataque 1, extraccion de rol

Respuesta del sistema:

Que ha revelado:

### Ataque 2, suplantacion de contexto

Respuesta del sistema:

Que ha revelado:

### Ataque 3, simulacion administrativa

Respuesta del sistema:

Que ha "confirmado":

Reflexion: ¿es una vulnerabilidad real o una alucinacion complaciente?

## Fase 2, defensa en tres pasos

### Paso 2.1, solo separacion estructural

(`DISABLE_BLACKLISTS=true`, puerto 8001)

| Ataque | Bloqueado por | Resultado |
|--------|---------------|-----------|
| 1      |               |           |
| 2      |               |           |
| 3      |               |           |

Observacion sobre que hace la separacion estructural:

### Paso 2.2, anadir blacklists

(`DISABLE_BLACKLISTS=false`, puerto 8001)

| Ataque | Bloqueado por | Resultado |
|--------|---------------|-----------|
| 1      |               |           |
| 2      |               |           |
| 3      |               |           |

Observacion sobre que cambia respecto a 2.1:

### Paso 2.3, evasion de las blacklists

Ejecuta `attack_4_evasion.sh` y anota cuales pasan la blacklist:

| Variante      | Pasa la blacklist? | Modelo responde con info confidencial? |
|---------------|--------------------|----------------------------------------|
| 4a (ingles)   |                    |                                        |
| 4b (sinonimos)|                    |                                        |
| 4c (redondeo) |                    |                                        |

### Tu propio ataque adversarial

Inventa un ataque que evada la blacklist y consiga revelar al menos
una tarifa interna. Anota el prompt y el resultado.

Prompt:

Resultado:

## Fase 3, discusion

### 1. Que capa hace mas trabajo en este sistema?

### 2. Que vectores de ataque NO defienden las dos capas actuales?

### 3. Tres cosas que anadirias para llevarlo a produccion

1.

2.

3.

## Bonus, variante B

Si la has visto en clase, anota dos diferencias que has observado
respecto a la variante A:

1.

2.
