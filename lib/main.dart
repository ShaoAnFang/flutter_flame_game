import 'package:event/event.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame/palette.dart';
import 'package:flame/effects.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flame_game/components/events.dart';
import 'package:flutter_flame_game/components/player.dart';
import 'package:flutter_flame_game/components/player_item.dart';
import 'package:flutter_flame_game/components/tank.dart';
import 'dart:async' as async;
import 'dart:math';

import 'components/boss.dart';

const worldWidth = 1440.0;
const worldHeight = 720.0;
const viewPortHeight = 320.0;
const viewPortWidth = 640.0;
late Vector2 viewPortSize;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  var ifRpgGame = IFRpgGame()..camera.viewport = FixedResolutionViewport(Vector2(viewPortWidth, viewPortHeight));
  viewPortSize = Vector2(viewPortWidth, viewPortHeight);
  runApp(GameWidget(game: ifRpgGame));
}

var event = Event<BossAction>();

class IFRpgGame extends FlameGame with HasDraggables, HasCollisionDetection {
  late async.Timer cameraTimer;

  @override
  Future<void> onLoad() async {
    FlameAudio.bgm.initialize();
    FlameAudio.bgm.play('music/climax.mp3', volume: 0.6);
    super.onLoad();
    var joystick = JoystickComponent(
      knob: CircleComponent(radius: 15, paint: BasicPalette.white.withAlpha(150).paint()),
      background: CircleComponent(radius: 50, paint: BasicPalette.white.withAlpha(150).paint()),
      margin: const EdgeInsets.only(left: 30, bottom: 30),
    );
    var map = await TiledComponent.load('rpg.tmx', Vector2.all(16));
    final enemies = map.tileMap.getLayer<ObjectGroup>('enemies'); //getObjectGroupFromLayer('enemies');
    add(map);
    const tankIndex = 28;
    const shieldIndex = 26;
    const powerUpIndex = 25;
    var tiles = await Flame.images.load('tiles_packed.png');

    var tank = Sprite(tiles, srcSize: Vector2(16, 16), srcPosition: Vector2(tankIndex % 12 * 16, (tankIndex / 12).floorToDouble() * 16));

    var powerUp = Sprite(tiles, srcSize: Vector2(16, 16), srcPosition: Vector2(powerUpIndex % 12 * 16, (powerUpIndex / 12).floorToDouble() * 16));

    // var explosion = await AudioPool.create('explosion.wav', minPlayers: 1, maxPlayers: 2);
    // var zap = await AudioPool.create('zap.mp3', minPlayers: 1, maxPlayers: 2);
    var joystickPlayer = Player(joystick)..anchor = Anchor.center;
    // var shield = Sprite(tiles, srcSize: Vector2(16, 16), srcPosition: Vector2(shieldIndex % 12 * 16, (shieldIndex / 12).floorToDouble() * 16));
    var shield = Sprite(tiles, srcSize: Vector2(16, 16), srcPosition: Vector2(shieldIndex % 12 * 16, (shieldIndex / 12).floorToDouble() * 16));

    const vh = viewPortHeight / 5;
    add(Boss(joystickPlayer, /*explosion, zap,*/ image: 'e1.png', textureSize: Vector2(28, 30))..position = Vector2(worldWidth - 100, vh));

    add(Boss(joystickPlayer, /*explosion, zap,*/ image: 'e2.png', textureSize: Vector2(32, 32))..position = Vector2(worldWidth - 100, 2 * vh));

    add(Boss(joystickPlayer, /*explosion, zap,*/ image: 'e3.png', textureSize: Vector2(32, 30))..position = Vector2(worldWidth - 100, 3 * vh));

    add(Boss(joystickPlayer, /*explosion, zap,*/ image: 'e4.png', textureSize: Vector2(32, 30))..position = Vector2(worldWidth - 100, 4 * vh));
    for (var element in enemies!.objects) {
      switch (element.type) {
        case 'gt':
          // add(Tank('gt', item: tank, position: Vector2(element.x, element.y), size: Vector2(16, 16)));
          add(Tank('gt', joystickPlayer)
            ..position = Vector2(element.x + 8, element.y + 8)
            ..size = Vector2(16, 16));
          break;

        case 'power':
          add(PlayerItem('power', item: powerUp, position: Vector2(element.x, element.y), size: Vector2(16, 16))
            ..anchor = Anchor.center
            ..add(ScaleEffect.by(Vector2(2.5, 2.5), EffectController(duration: 1, reverseDuration: 1, infinite: true))));
          break;
        case 'shield':
          add(PlayerItem('shield', item: shield, position: Vector2(element.x, element.y), size: Vector2(16, 16))
            ..anchor = Anchor.center
            ..add(ScaleEffect.by(Vector2(1.5, 1.5), EffectController(duration: 1, reverseDuration: 1, infinite: true))));
          break;
      }
    }

    camera.followComponent(joystickPlayer, worldBounds: const Rect.fromLTWH(0, 0, worldWidth, worldHeight));
    add(joystickPlayer);
    add(joystick);

    cameraTimer = async.Timer.periodic(const Duration(milliseconds: 25), (timer) {
      camera.translateBy(Vector2(40, 0));
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    var lastLegalXForCamera = worldWidth - viewPortHeight;
    if (camera.position.x >= lastLegalXForCamera) {
      cameraTimer.cancel();
      camera.snapTo(Vector2(lastLegalXForCamera, 0));
    }
  }

  gameOver() {
    FlameAudio.bgm.stop();
    // FlameAudio.audioCache.play('music/game_over.mp3', volume: 0.6);
  }

  missionCleared() {
    FlameAudio.bgm.stop();
    camera.shake(duration: 2, intensity: 5);
    // FlameAudio.audioCache.play('music/mission_clear.mp3', volume: 0.6);
  }
}
