import 'package:shared_preferences/shared_preferences.dart';

class UsageTracker {
  static const _prefIn  = 'usage_in_';
  static const _prefOut = 'usage_out_';

  Future<void> addUsage(String modelId, int inputTokens, int outputTokens) async {
    if (inputTokens == 0 && outputTokens == 0) return;
    final prefs = await SharedPreferences.getInstance();
    final prevIn  = prefs.getInt('$_prefIn$modelId')  ?? 0;
    final prevOut = prefs.getInt('$_prefOut$modelId') ?? 0;
    await prefs.setInt('$_prefIn$modelId',  prevIn  + inputTokens);
    await prefs.setInt('$_prefOut$modelId', prevOut + outputTokens);
  }

  Future<ModelUsage?> getUsage(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    final inTok  = prefs.getInt('$_prefIn$modelId')  ?? 0;
    final outTok = prefs.getInt('$_prefOut$modelId') ?? 0;
    if (inTok == 0 && outTok == 0) return null;
    return ModelUsage(modelId: modelId, inputTokens: inTok, outputTokens: outTok);
  }

  Future<List<ModelUsage>> getAllUsage(List<String> modelIds) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <ModelUsage>[];
    for (final id in modelIds) {
      final inTok  = prefs.getInt('$_prefIn$id')  ?? 0;
      final outTok = prefs.getInt('$_prefOut$id') ?? 0;
      if (inTok > 0 || outTok > 0) {
        result.add(ModelUsage(modelId: id, inputTokens: inTok, outputTokens: outTok));
      }
    }
    return result;
  }

  Future<void> resetAll(List<String> modelIds) async {
    final prefs = await SharedPreferences.getInstance();
    for (final id in modelIds) {
      await prefs.remove('$_prefIn$id');
      await prefs.remove('$_prefOut$id');
    }
  }
}

class ModelUsage {
  final String modelId;
  final int inputTokens;
  final int outputTokens;
  const ModelUsage({required this.modelId, required this.inputTokens, required this.outputTokens});
  int get totalTokens => inputTokens + outputTokens;
}
