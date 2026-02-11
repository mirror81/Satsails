import 'package:lwk/lwk.dart';
import 'package:path_provider/path_provider.dart';

class LiquidConfigModel {
  final LiquidConfig config;

  LiquidConfigModel(this.config);

  static Future<String> getDbDir() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/lwk-db";
      return path;
    } catch (e) {
      print('Error getting current directory: $e');
      rethrow;
    }
  }

  static Future<Wallet> createWallet(String mnemonic, Network network) async {
    final dbPath = await getDbDir();
    final descriptor = await Descriptor.newConfidential(network: network, mnemonic: mnemonic).then((value) => value);

    final wallet = Wallet.init(
      descriptor: descriptor,
      network: network,
      dbpath: dbPath,
    );

    return wallet;
  }

  /// Extracts raw xpub from Liquid confidential descriptor
  /// Returns xpub for watch-only wallet import
  static Future<String> extractLiquidXpub(String mnemonic, Network network) async {
    try {
      final descriptor = await Descriptor.newConfidential(
        network: network,
        mnemonic: mnemonic
      );

      final descriptorString = descriptor.toString();

      // Parse Liquid descriptor to extract xpub
      // Expected format may vary, adapt pattern as needed
      final fingerprintPattern = RegExp(r'\]([xztvXZTV][a-zA-Z0-9]+)');
      var match = fingerprintPattern.firstMatch(descriptorString);

      if (match == null) {
        final simplePattern = RegExp(r'\(([xztvXZTV][a-zA-Z0-9]+)');
        match = simplePattern.firstMatch(descriptorString);
      }

      if (match == null) {
        throw Exception('Could not extract xpub from Liquid descriptor');
      }

      final key = match.group(1)!.split('/')[0];
      return key;
    } catch (e) {
      throw Exception('Failed to extract Liquid xpub: $e');
    }
  }
}

class LiquidConfig {
  final String mnemonic;
  final Network network;
  final Wallet wallet;


  LiquidConfig({
    required this.mnemonic,
    required this.network,
    required this.wallet,
  });
}