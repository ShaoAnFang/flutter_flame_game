# Flutter flame practice

Update to Flutter 3.7.1
flame package 1.6.0
flame_tiled: 1.9.1

Reference by this repo project and YT channel down below:
- [imperativelyfunctional/flutte_flame_2d_air_fighter](https://github.com/imperativelyfunctional/flutte_flame_2d_air_fighter)
- [用flutter及tiled做手遊和網遊【地圖加載，碰撞檢測，遊戲升級和相對座標處理】](https://youtu.be/k0nSdOgEYMk)

---

# [Flame package name changes](https://docs.flame-engine.org/1.2.0/flame/collision_detection.html)

ScreenCollidable -> ScreenHitbox

HitboxCircle -> CircleHitbox

HitboxRectangle -> RectangleHitbox

HitboxPolygon -> PolygonHitbox

Collidable -> CollisionCallbacks (Only needed when you want to receive the callbacks)

HasHitboxes -> GestureHitboxes (Only when you need hitboxes for gestures)

CollidableType -> CollisionType


# [Flame_tiled changes]
var map = await TiledComponent.load('rpg.tmx', Vector2.all(16));

instead

map.tileMap.getLayer.getObjectGroupFromLayer('enemies')

to 

map.tileMap.getLayer<ObjectGroup>('enemies');
