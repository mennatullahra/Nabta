import 'package:audioplayers/audioplayers.dart';

/// Plays the short feedback sounds.
/// Files live in assets/sounds/ (correct.wav, wrong.wav, complete.wav).
class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> _play(String file) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$file'));
    } catch (_) {
      // If audio fails (e.g. browser autoplay rules), ignore silently.
    }
  }

  static void correct() => _play('correct.wav');
  static void wrong() => _play('wrong.wav');
  static void complete() => _play('complete.wav');
}
