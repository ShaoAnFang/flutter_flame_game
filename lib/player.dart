import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flame_game/bullets/extensions/bullets.dart';
import 'package:flutter_flame_game/bullets/mixins/weapon.dart';
import 'bullets/mixins/bullets.dart';

import '../main.dart';

class Player extends SpriteComponent with HasGameRef, GestureHitboxes, CollisionCallbacks, BulletsMixin, Weapon {
  double maxSpeed = 100.0;
  final JoystickComponent joystick;
  bool hasShield = false;
  int powerUpGrade = 0;
  late SpriteComponent wing1;
  late SpriteComponent wing2;

  Player(this.joystick) : super(size: Vector2(32, 24)) {
    add(RectangleHitbox());
    angle = pi / 2;
    anchor = Anchor.center;
    health = 2000;
  }

  addPowerUps() async {
    var planes = await Flame.images.load('ships_packed.png');

    var spriteSheet = SpriteSheet.fromColumnsAndRows(image: gameRef.images.fromCache('ships_packed.png'), columns: 4, rows: 6);
    // add(SpriteComponent(sprite: Sprite(planes, srcSize: Vector2(24, 29), srcPosition: Vector2(4, 39)), priority: 2)..position = Vector2(-28, 4));
    // add(SpriteComponent(sprite: Sprite(planes, srcSize: Vector2(24, 29), srcPosition: Vector2(4, 39)), priority: 2)..position = Vector2(36, 4));
    if (powerUpGrade != 0) {
      timers.map((e) => e.cancel);
      timers.clear();
      removeAll([wing1, wing2]);
      timers.add(shoot2(scale: Vector2(1, 1.5), bulletSpeed: 1000 - (300 * powerUpGrade)));
    }
    var winger = Sprite(planes, srcSize: Vector2(24, 19), srcPosition: Vector2(4, 39));
    wing1 = SpriteComponent(sprite: spriteSheet.getSpriteById(4 + powerUpGrade))
      ..anchor = Anchor.center
      ..position = Vector2(width / 2, height / 2)
      ..add(SpriteComponent(sprite: winger)
        ..position = Vector2(10, 30)
        ..scale = Vector2.all(0.4)
        ..add(ColorEffect(Colors.transparent, const Offset(0.6, 0.6), EffectController(duration: 1, infinite: true, reverseDuration: 1))))
      ..add(MoveAlongPathEffect(
          Path()..addArc(Rect.fromCircle(center: const Offset(0, 0), radius: 40), 0, 2 * pi),
          EffectController(
            duration: 4,
            infinite: true,
          )));
    timers.add(wing1.shoot2(scale: Vector2(0.5, 0.5), color: Colors.blue.withAlpha(10), bulletSpeed: 1000 - (300 * powerUpGrade)));
    add(wing1);
    // wing2 = SpriteComponent(sprite: winger)
    wing2 = SpriteComponent(sprite: spriteSheet.getSpriteById(4 + powerUpGrade))
      ..anchor = Anchor.center
      ..position = Vector2(width / 2, height / 2)
      ..add(SpriteComponent(sprite: winger)
        ..position = Vector2(10, 30)
        ..scale = Vector2.all(0.4)
        ..add(ColorEffect(Colors.transparent, const Offset(0.6, 0.6), EffectController(duration: 1, infinite: true, reverseDuration: 1))))
      ..add(MoveAlongPathEffect(
          Path()..addArc(Rect.fromCircle(center: const Offset(0, 0), radius: 40), pi, -3 * pi),
          EffectController(
            duration: 4,
            infinite: true,
          )));
    timers.add(wing2.shoot2(scale: Vector2(0.5, 0.5), color: Colors.blue.withAlpha(10), bulletSpeed: 1000 - (300 * powerUpGrade + 1)));

    add(wing2);

    powerUpGrade += 1;
  }

  final shieldComponents = [
    CircleComponent(position: Vector2(15, 15), anchor: Anchor.center, radius: 30, paint: Paint()..color = Colors.lightBlueAccent.withAlpha(100)),
    CircleComponent(
        position: Vector2(15, 15),
        anchor: Anchor.center,
        radius: 20,
        paint: Paint()
          ..color = Colors.purple.withAlpha(30)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke),
    CircleComponent(
        position: Vector2(15, 15),
        anchor: Anchor.center,
        radius: 22,
        paint: Paint()
          ..color = Colors.orangeAccent.withAlpha(120)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke),
  ];

  addShield() {
    if (!hasShield) {
      addAll(shieldComponents);
      hasShield = true;
    }
  }

  removeShield() {
    if (hasShield) removeAll(shieldComponents);
    hasShield = false;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    var planes = await gameRef.images.load('ships_packed.png');
    // sprite = Sprite(planes, srcPosition: Vector2(0, 4), srcSize: Vector2(32, 24));
    sprite = Sprite(planes, srcPosition: Vector2(0, 0), srcSize: Vector2(32, 24));
    position = gameRef.size / 2;
    timers.add(shoot2(scale: Vector2(1, 1.5)));
    add(SpriteComponent(sprite: sprite)
      ..position = Vector2(10, 30)
      ..scale = Vector2.all(0.4)
      //飛機尾巴的小陰影
      ..add(ColorEffect(Colors.transparent, const Offset(0.6, 0.6), EffectController(duration: 1, infinite: true, reverseDuration: 1))));
  }

  @override
  void update(double dt) {
    if (!joystick.delta.isZero()) {
      var vector2 = joystick.relativeDelta * maxSpeed * dt;
      var x = vector2.x;
      var y = vector2.y;
      if ((this.x + x) > worldWidth - width / 2) {
        vector2.x = 0;
      }
      if ((this.x + x - width / 2) < 0) {
        vector2.x = 0;
      }
      if (this.y + y - height / 2 < 0) {
        vector2.y = 0;
      }
      if (this.y + y + height / 2 > viewPortHeight) {
        vector2.y = 0;
      }
      position.add(vector2);
      // angle = joystick.delta.screenAngle();
    }

    var cameraPosition = gameRef.camera.position;
    if (x - height / 2 < cameraPosition.x) {
      x = cameraPosition.x + height / 2;
    } else if (x + width / 2 > cameraPosition.x + viewPortWidth) {
      x = cameraPosition.x + viewPortWidth - width / 2;
    }

    // var spriteSheet = SpriteSheet.fromColumnsAndRows(
    //   image: gameRef.images.fromCache('tiles_packed.png'),
    //   columns: 1,
    //   rows: 2,
    // );
    // Bullet bullet = Bullet(
    //   sprite: spriteSheet.getSpriteById(28),
    //   size: Vector2(64, 64),
    //   position: position.clone(),
    //   level: 5, //_spaceship.level,
    // );

    // Anchor it to center and add to game world.
    // bullet.anchor = Anchor.center;
    // gameRef.add(bullet);
  }
}
