# Modelo de Productos del CRM Patrimonial

- Estado: Aprobado como estructura transversal; catálogo en revisión continua
- Versión: 0.2
- Última reconciliación: 2026-08-03
- LCD de origen: LCD-20260712-01
- LCD de migración: LCD-20260803-01
- ADR: ADR-017

## Propósito

Definir la estructura común para representar productos sin duplicar fichas corporativas ni convertir una compañía en el modelo completo del dominio.

## Principios

- Producto es una oferta comercial identificable y vigente en un catálogo.
- Familia de Producto agrupa productos por propósito o naturaleza.
- Vehículo de Inversión conserva el marco jurídico, tributario, sucesorio, operativo y de costos.
- Estrategia de Inversión no se confunde con Producto ni Vehículo.
- La disponibilidad de Fondos y Series pertenece al producto y al catálogo vigente.
- Una Posición se registra sobre una Serie específica.
- La contratación efectiva genera un Producto Contratado con vida e historial propios.
- Toda regla particular identifica fuente, vigencia, fecha de consulta y nivel de validación.

## Fuentes Consorcio

La carpeta Drive `Productos Consorcio` y su Sheet `Índice y Matriz de Productos Consorcio` son fuentes corporativas y evidencia de análisis, no una copia del modelo. Permanecen exclusivamente en Drive por contener PDFs, manuales, fichas y material corporativo.

GitHub conserva únicamente este modelo transversal y enlaces de referencia; no reproduce los documentos de terceros.

## Reglas iniciales por validar continuamente

- APV Uno, APV Más y APV Fondo Experto: Serie APV.
- APV Prime: Serie APV-AP.
- CUI Familia Vida Ahorro: Serie F.
- CUI Gold: Serie A y componente de inversión.
- Fondos Mutuos puros: Series A y F según catálogo vigente.

Estas reglas operativas deben contrastarse con las fuentes vigentes antes de usarse como restricción técnica.

## Pendientes

- completar taxonomía de familias;
- distinguir atributos comunes y específicos;
- auditar el catálogo comenzando por APV;
- verificar vigencia, contratación, costos y Series;
- resolver con fuente oficial la definición comparable de rentabilidades APV.
