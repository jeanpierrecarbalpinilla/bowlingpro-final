# BowlingPro

App móvil para aprender a jugar bolos, encargada por una liga deportiva. Permite registrar partidas con cálculo oficial de puntaje, seguir el progreso y recibir orientación de un entrenador.

Proyecto de Software I, con metodología Scrum. Sprint de un día, prototipo funcional.

## Equipo

| Persona | Rol |
|---|---|
| Jean | Product Owner |
| Jhon | Scrum Master |
| Juan | Developer |
| Jose | Usuario / Tester |

## Alcance implementado

| Épica | Estado |
|---|---|
| 1. Acceso seguro (registro, login, restricción por grupo) | Completa |
| 2. Aprendizaje (niveles con candados, lecciones con video, evaluación) | Funcional. Modo offline descartado deliberadamente |
| 3. Puntuación oficial (motor de reglas, historial, estadísticas) | Completa |
| 4. Coaching activo (jugadores del grupo, detalle, comentarios) | Funcional |
| Gamificación | Una insignia funcional: "Primer strike" |

**Documentado, no implementado:** gestión de lecciones por el administrador, notificaciones push, glosario y reglamento, retos adicionales y tabla de clasificación.

## Motor de puntuación

- Máximo 300 puntos.
- Strike: 10 más los dos lanzamientos siguientes.
- Spare: 10 más el lanzamiento siguiente.
- Frame 10: hasta 3 lanzamientos si hay strike o spare.
- Bloqueo circular: un frame no se cierra hasta que existen los lanzamientos bonus de los que depende.

## Stack

- Flutter / Dart
- Firebase Auth y Cloud Firestore
- GitHub Projects, GitHub Actions y wiki como ALM

## Cómo ejecutar

```bash
git clone https://github.com/jeanpierrecarbalpinilla/bowlingpro-final.git
cd bowlingpro-final
flutter pub get
flutter run
```

## Pruebas

```bash
flutter test
```

Cinco pruebas unitarias del motor: juego perfecto (300), juego en cero, mezcla de strikes y spares, frame 10 límite y bloqueo circular. Se ejecutan automáticamente con GitHub Actions en cada push y pull request.

## Descargas y documentación

- APK: [Releases](https://github.com/jeanpierrecarbalpinilla/bowlingpro-final/releases)
- Diagramas UML y prompts de IA: [Wiki](https://github.com/jeanpierrecarbalpinilla/bowlingpro-final/wiki)
- Backlog: [Tablero de GitHub Projects](https://github.com/jeanpierrecarbalpinilla/bowlingpro-final/projects)
- Prototipo de interfaces: [enlace a Figma]

## Decisiones de alcance

- Las reglas de Firestore están en modo de prueba durante el prototipo. La restricción por rol y grupo se valida en la capa de servicios (`JugadorService`, `CoachingService`). Endurecerlas queda como trabajo futuro.
- El progreso de aprendizaje se guarda por nivel, no por lección individual.