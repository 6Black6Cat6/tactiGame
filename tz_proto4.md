# Техническое задание (Godot 4)

## 1. Структура файлов и сцен

res://
├── config/
│   └── game_config.tres
├── scenes/
│   ├── unit.tscn
│   ├── timeline_view.tscn
│   └── main.tscn
├── scripts/
│   ├── unit.gd
│   ├── order.gd
│   ├── timeline.gd
│   ├── simulator.gd
│   └── sensor.gd
├── resources/
│   └── weapon.tres
└── ui/
    ├── order_block.tscn
    └── timeline_ruler.tscn

## 2. Конфиг (game_config.tres)

- units_per_side = 5
- reaction_min = 300
- reaction_max = 1500
- view_distance = 500
- view_cone = 120
- weapon_range = 400
- weapon_spread = 20
- move_speed_min = 100
- move_speed_max = 500
- unit_size = 20
- turn_duration = 5000   # мс

## 3. Сцена unit.tscn

- Node2D (корень)
- Sprite2D
- CollisionShape2D (круг, радиус из конфига)
- скрипт: unit.gd

## 4. unit.gd — параметры

enum StateType { MOVE, STAND, ATTACK, DETECTION }
enum Track { MOVEMENT, ACTION }

- reaction_time (генерится при спавне от min до max из конфига)
- move_speed (генерится при спавне от min до max из конфига)
- weapon (ссылка на weapon.tres)
- position: Vector2
- direction: Vector2
- team_id: int (0 — игрок, 1 — противник)

## 5. Ресурс order.gd

enum OrderType { MOVE, STAND, ATTACK, ATTACK_IF_POSSIBLE }
enum Track { MOVEMENT, ACTION }

- type: OrderType
- track: Track
- start_time: int
- duration: int
- target_position: Vector2 (для MOVE)
- target_direction: Vector2 (для STAND и ATTACK)
- interruptible: bool (MOVE/STAND/ATTACK_IF_POSSIBLE = true, ATTACK = false)

## 6. Модель таймлайна (timeline.gd)

- orders: Array[Order]
- turn_duration: int (берётся из конфига)
- current_view_position: int

Методы:
- add_order(order, track, start_time)
- resize_order(order, new_duration)
- remove_order(order)
- get_orders_at_time(time, track)

## 7. Simulator (simulator.gd)

Вход: List[Unit], timeline, turn_start_time

### 7.1. Цикл симуляции

Шаг = min(reaction_time / 4, 16 мс)

### 7.2. Атака (ATTACK)

Состояния:
- ANY
- ATTACK (длится reaction_time)

Правила:
1. Из ANY → ATTACK
2. ATTACK завершён → мгновенный выстрел (случайное направление в конусе разброса, физический луч) → IDLE
Выстрел происходит всегда, даже если нет цели.

### 7.3. Атака по возможности (ATTACK_IF_POSSIBLE)

Состояния:
- ANY
- DETECTING (длится reaction_time)
- ATTACK (длится reaction_time)

Правила:
1. Из ANY при появлении врага (team_id != свой) в конусе видимости → Удаляем все ATTACK из очереди → DETECTING добавляется в очередь действий после текущего действия
2. Если очередь пуста, то сразу начинается его выполнение.
3. Если за время DETECTING враг пропал → отмена текущего DETECTION и начать выполнение следующего действия
4. все действия в очереди завершены → есть обнаруженные враги → ATTACK ближайшего (по алгоритму из 7.2)
5. Во время ATTACK игрок не может прервать приказ
6. Союзники игнорируются при обнаружении и атаке

### 7.4. Параллельность

Приказы MOVEMENT и ACTION выполняются параллельно и независимо друг от друга.
- Движение не останавливается при обнаружении врага и не прерывается атакой.
- Атака не прерывается движением.

### 7.5. Физический луч

PhysicsRayQueryParameters2D для проверки:
- видимости (сенсорика) — только противники
- попадания (выстрел) — все юниты (включая союзников, если луч попадает)

### 7.6. Предпросмотр на таймлайне

При перемещении бегунка:
- Позиции юнитов рассчитываются линейной интерполяцией без коллизий.
- Направление взгляда интерполируется.
- Столкновения не проверяются, допускается наложение.

## 8. Таймлайн UI (timeline_view.tscn)

Компоненты:
- TimelineRuler (шкала)
- OrderBlock (плашка приказа)
- Playhead (бегунок)

Вертикальное разделение:
- верхняя половина = трек MOVEMENT
- нижняя половина = трек ACTION

Приказы за границей хода — полупрозрачные.

Бегунок: пересчёт позиций юнитов без коллизий (линейная интерполяция движения + направление взгляда).

## 9. Управление (main.gd)

Фаза планирования:

- Левый клик по юниту = выделить
- Правый клик по карте (юнит выделен) = создать MOVE с текущего момента
- Ctrl + левый клик по карте (юнит выделен) = создать STAND
- Правый клик после STAND (юнит выделен) = установить target_direction
- Delete (выделен OrderBlock) = удалить приказ
- Ctrl + колёсико (над таймлайном) = масштаб
- Колёсико (над таймлайном) = скролл
- Пробел или кнопка = запуск симуляции

## 10. Окружение

- Карта: плоскость без препятствий
- Границы: непроходимые края (StaticBody2D)

## 11. Смерть
При смерти юнита все его приказы и состояния очищаются и он удаляется с поля.
Если другой юнит уже начал атаку умершего - атака выполняется до конца, но поскольку труп убран, то попадение может быть в кого-то другого.