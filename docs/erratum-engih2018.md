# Fe de erratas propuesta: análisis de la ENGIH 2018

Borrador para envío privado. Recoge los errores e inconsistencias hallados al
revisar el repositorio `analisis_ENGIH2018` (rama `main`, commit `7caab91`)
para construir el paquete `hcesfort`. Las referencias son `script:líneas` de
ese commit. El detalle de cada punto está en `docs/analysis-map.md`, sección 6,
con el mismo código (E1, E2…).

Lo que no se pudo medir sin los microdatos se indica como **pendiente de
medir**. Ninguna cifra corregida se da aquí: se obtendrán al repetir el
análisis con el paquete y se registrarán, antes y después, en `NEWS.md`.

## A. Errores que afectan a cifras publicadas o a su interpretación

### 1. Aporte de los grupos de alimentos calculado con alimentos enriquecidos (E1)

- **Qué ocurre.** `08_grupos_alimentos.R:39-49` une la composición unificada
  sin aplicar la línea base sin fortificar que sí construye
  `06_escenarios_fortificacion.R:74-91`. El arroz enriquecido (INCAP 70213002:
  4,36 mg de hierro y 386 µg DFE de folato por 100 g, frente a 0,8 y 9 del no
  enriquecido), la pasta y los panes entran con el enriquecimiento de la tabla
  de composición.
- **Dónde se publica.** `grupos_micronutrientes.csv` (cereales: 81,6% del
  folato y 66,1% del hierro) y la figura y el texto de la sección "Composición
  de la dieta por grupos de alimentos" del informe final, que afirma que el
  aporte "se calcula sobre el escenario sin fortificación".
- **Sentido del sesgo.** Sobrestima el aporte de los cereales al folato y al
  hierro.
- **Corrección.** Calcular los aportes sobre la misma composición de línea
  base que usan los escenarios.

### 2. La cobertura de la composición se mide después de eliminar los registros sin correspondencia (E3)

- **Qué ocurre.** Un registro sin correspondencia validada no recibe porción
  comestible, sus gramos quedan en `NA` y `04_equivalente_adulto.R:240` lo
  elimina. `05_ingesta_micronutrientes.R:260-279` calcula la cobertura sobre
  los registros que quedan: el resultado es cercano al 100% por construcción y
  `alimentos_sin_composicion.csv` sale vacío.
- **Magnitud conocida.** Unos 60.000 registros de la Sección 3A (18%) no
  llegan a la estimación de ingesta; 36.840 de ellos por falta de
  correspondencia (README). El alimento más frecuente de la sección, el caldo
  en cubos (18.087 registros), está entre ellos.
- **Dónde se publica.** El manual y el informe final dicen que los alimentos
  sin correspondencia "aportan cero" y que la cobertura "ponderada por gramos"
  acompaña a los resultados. La cobertura publicada por nutriente es la de los
  registros supervivientes, no la de todo lo adquirido.
- **Sentido del sesgo.** La ingesta es un límite inferior, como se declara,
  pero su distancia al valor real no está medida y es mayor que la que
  sugiere la cobertura publicada.
- **Corrección.** Medir la cobertura sobre todos los registros de alimentos,
  en registros y en gramos, y contar las pérdidas por causa sin jerarquía
  entre causas. El informe de factibilidad atribuye cada registro a una sola
  causa en orden fijo (cantidad, factor, composición, porción), lo que explica
  que señale el factor de conversión como causa principal.

### 3. Los hogares sin registros retenidos salen del denominador del riesgo y permanecen en el de la cobertura (E5)

- **Qué ocurre.** El diseño tiene 8.892 hogares; el riesgo se estima sobre
  8.778 (`07_riesgo_inadecuacion.R:93-96`, unión interna). La cobertura de
  vehículos (`06:100`) y el anexo del maíz conservan los 8.892 como no
  consumidores. Los 114 hogares no se describen ni se clasifican (sin
  alimentos adquiridos, o con todos sus registros perdidos por el punto 2).
  Además, el subconjunto se toma antes de declarar el diseño (`07:158`, también
  para el subconjunto de energía plausible), en lugar de estimar un dominio
  dentro del diseño completo.
- **Sentido del sesgo.** Desconocido; los denominadores de cobertura y de
  riesgo no son comparables y la varianza puede quedar subestimada.
- **Corrección.** Declarar el diseño sobre la muestra completa, estimar los
  subconjuntos como dominios e informar de esos hogares.

### 4. La proporción sobre el nivel máximo tolerable se presenta como cota máxima y no lo es (E7)

- **Qué ocurre.** `07:102-106` compara con el nivel máximo solo lo que añade
  el escenario. No se cuenta el retinol preformado de la dieta (hígado,
  lácteos, huevos; la columna `RETOL` del INCAP no se lee) ni el ácido fólico
  de alimentos fortificados fuera del escenario (columna `Folic acid` de
  FNDDS).
- **Dónde se publica.** `valores_referencia.csv`, el manual y el informe final
  (métodos y sección del ácido fólico) la llaman "cota máxima".
- **Sentido del sesgo.** Para la vitamina A es una cota mínima. Para el ácido
  fólico es la proporción debida solo a lo añadido.
- **Corrección.** Describirla como "proporción por lo añadido en el escenario"
  y, cuando la tabla de composición tenga la forma del nutriente, sumar la de
  la dieta.

### 5. Una docena se convierte como 12 gramos (E2)

- **Qué ocurre.** La unidad 52, "Docena", tiene `FC = 12` con método "Conteo"
  y la observación de que necesita el peso por unidad. `01_import.R:173-176`
  toma todo `FC` no ausente como factor universal en gramos, y el factor
  universal tiene prioridad sobre el específico del alimento.
- **Magnitud.** Pendiente de medir: número de registros declarados en docenas.
- **Sentido del sesgo.** Subestima los gramos de esos registros.
- **Corrección.** Distinguir en la tabla de unidades los factores de masa, de
  volumen y de conteo; una unidad de conteo necesita el peso por pieza del
  alimento.

### 6. La línea base sin fortificar de los derivados del trigo conserva solo la harina (E6)

- **Qué ocurre.** `06:80-90` fija el hierro y el folato de pan, pasta,
  galletas y repostería en fracción de harina × harina refinada sin
  enriquecer. Se descartan el hierro y el folato de los demás ingredientes, y
  los productos integrales reciben valores de harina refinada.
- **Sentido del sesgo.** La línea base de esos alimentos queda por debajo de la
  real; la limitación no está declarada.
- **Corrección.** Restar solo lo que añadió el enriquecimiento: valor de la
  tabla − fracción de harina × (harina enriquecida − harina sin enriquecer),
  con mínimo cero.

### 7. Base de los niveles de fortificación sin verificar (E8)

- **Qué ocurre.** `06:42-43` convierte los mg/kg de vitamina A a µg RAE uno a
  uno, como si el nivel fuera retinol. `parametros_normativos.csv` registra el
  compuesto de la norma del azúcar como palmitato de retinol y no dice a qué
  se refieren los 10 mg/kg. La misma duda vale para el hierro (compuesto o
  hierro elemental) y para las filas de vitamina A y B12 de la OMS (2009),
  marcadas `por_confirmar`.
- **Magnitud.** Depende del texto de las normas, que no se ha consultado. El
  escenario 1c mueve la mediana de vitamina A de 289 a 698 µg RAE, de modo que
  la base importa.
- **Corrección.** Leer los textos (RTD 616, NORDOM 602) y declarar en la tabla
  de escenarios si cada nivel es del nutriente o del compuesto.

## B. Defectos sin efecto demostrado o de efecto menor

- **Miembros sin edad o sexo cuentan como cero EMA** (`04:186`,
  `na.rm = TRUE`). El informe de factibilidad afirma que no hubo miembros sin
  requerimiento asignado; si se confirma con los microdatos, el defecto está
  en el código y no en las cifras (E10).
- **Regla de agotamiento con existencia final ausente** (`04:292-298`): la
  suma sin `na.rm` deja la comparación en `NA` y el hogar se trata como sin
  existencias (E11).
- **Los atípicos se detectan sobre gramos del hogar**, no por EMA ni por
  persona, con cuantiles sin ponderar (E9). El control a nivel de hogar que
  propone el informe de factibilidad no se construyó.
- **Los líquidos se convierten con la densidad del agua**, incluido el aceite
  (E18).
- **Intervalos de confianza.** Los de las proporciones son simétricos y pueden
  salir de [0, 100]; las medianas y la proporción sobre el nivel máximo no
  llevan intervalo; `significativa` se deriva de 336 comparaciones sin ajuste
  (E24).
- **Aportes por grupo sin diseño** y con denominadores mezclados (E22).

## C. Inconsistencias de documentación y de archivos

- **Dos definiciones del vehículo trigo**: expresiones regulares de
  `reports/_comun.R` y `vehiculos_escenarios.csv` (E12).
- **`escenarios_resumen.csv` repite columnas propias del folato** en las filas
  de los demás nutrientes (`06:231`) (E13).
- **El nivel máximo del ácido fólico está definido dos veces**: constante en
  `06:44` y fila de `valores_referencia.csv` (E14).
- **Texto que ya no describe el código** (E15): la cabecera de `01` y el
  informe final presentan la Sección 3A como fuente principal, y el código
  suma ambas secciones; el manual dice que el consumo de la Sección 2 se
  deduce de la diferencia de existencias, y el código usa la pregunta 9; el
  manual lista los valores de referencia como pendientes de confirmar y el
  archivo los marca `adoptado`.
- **La comprobación md5 no está en vigor**: `fuentes_datos.csv` no tiene url
  ni md5 de los microdatos, y las cifras de control no quedan ligadas a una
  versión de la entrada (E16).
- **Uniones sin comprobar la cardinalidad** en `01`, `04` y `08` (E17).
- **Reproducibilidad**: sin archivo de versiones de paquetes; `LEEME.txt` de
  las cifras de control registra la versión de R y el commit, no las de los
  paquetes (E26).
- **Correspondencias que conviene revisar** (E20): 114 filas validadas de la
  Sección 3A sin tipo de equivalencia; 8 filas validadas con tipo
  `requiere_revision`; pollo vivo asignado a pollo cocido con porción
  comestible 1,0; "Habichuelas blanditas" (2.708 registros) asignada a
  habichuelas verdes cocidas.
- **Valores ausentes de composición que pesan en las vitaminas D y E** (E21):
  cuentan como cero, y las proporciones bajo el requerimiento de ambas son en
  parte un artefacto; el informe final ya lo advierte.

## D. Hallazgo retirado

El período de referencia de la Sección 3A (días con registro por hogar) se
señaló al principio como error (E4). No lo es: el informe de factibilidad
contrasta las dos interpretaciones y muestra que la energía mediana no varía
con el número de días con registro. Queda como elección documentada, con tres
comprobaciones pendientes de medir: la misma tabla con la energía de la
Sección 3A sola, la cola superior según los días con registro y el
significado de un octavo día.
