import 'dart:async' as async;
import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter_flame_game/bullets/enemy_bullet.dart';
import 'package:flutter_flame_game/bullets/plane_bullet.dart';
import 'package:flutter_flame_game/player.dart';

import 'bullets/mixins/weapon.dart';
import 'bullets/mixins/bullets.dart';

class Tank extends SpriteComponent with HasGameRef, GestureHitboxes, CollisionCallbacks, Weapon, BulletsMixin {
  // final Sprite item;
  final String type;
  final Player player;
  late SpriteAnimation animation;
  // final AudioPool explosion;
  // final AudioPool zap;
  bool visible = false;
  int timerIndex = 0;

  Tank(
    this.type,
    this.player,
    // this.item,
    /* this.explosion, this.zap*/
  ) : super() {
    add(RectangleHitbox());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    var tiles = await Flame.images.load('tiles_packed.png');
    sprite = Sprite(tiles, srcSize: Vector2(16, 15), srcPosition: Vector2(64, 33));

    animation = await gameRef.loadSpriteAnimation(
      'tiles_packed.png',
      SpriteAnimationData.sequenced(
        texturePosition: Vector2(64, 0),
        amount: 4,
        textureSize: Vector2.all(16),
        stepTime: 0.4,
        loop: false,
      ),
    );
    timers.add(async.Timer.periodic(const Duration(milliseconds: 500), (timer) {
      gameRef.add(EnemyBullet(player, Vector2(player.x, player.y), 50, homing: true, timeForHomingSeconds: 2)
        ..position = Vector2(x, y)
        ..angle = atan2(player.y - y, player.x - x) + pi / 2);
    }));
  }

  @override
  void update(double dt) {
    super.update(dt);
    angle = atan2(player.y - y, player.x - x) - pi / 2;
    if (offScreen(gameRef) && visible) {
      for (var element in timers) {
        element.cancel();
      }
      removeFromParent();
    }

    if (!offScreen(gameRef)) {
      visible = true;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, dynamic other) {
    super.onCollision(intersectionPoints, other);
    if (other is PlaneBullet) {
      // gameRef.remove(this);
      final animationComponent = SpriteAnimationComponent(
        removeOnFinish: true,
        animation: animation,
        size: Vector2.all(16.0),
        anchor: Anchor.center,
        position: Vector2(x, y),
      );
      gameRef.add(animationComponent);
      removeFromParent();
      timers.first.cancel();
      timers.clear();
    }

    if (other is Player) {
      other.removeShield();
    }
  }
}
