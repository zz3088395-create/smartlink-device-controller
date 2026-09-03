import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../ble/ble_provider.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/widgets.dart';
import '../control/ble_session_controller.dart';
import '../control/channel_slider.dart';
import 'pattern_player.dart';
import 'pattern_timeline.dart';
import 'preset_models.dart';
import 'presets_provider.dart';

/// Eight-step, three-channel pattern editor. Saves as a `CUSTOM` preset.
///
/// With [presetId] the editor opens an existing preset: personal ones are
/// updated in place, built-in ones are saved as a new personal copy.
class PatternEditorPage extends ConsumerStatefulWidget {
  const PatternEditorPage({super.key, this.presetId});

  final String? presetId;

  @override
  ConsumerState<PatternEditorPage> createState() => _PatternEditorPageState();
}

class _PatternEditorPageState extends ConsumerState<PatternEditorPage> {
  static const _channelLabels = ['Channel A', 'Channel B', 'Channel C'];

  late List<PatternStep> _steps = PatternData.starter();
  int _selected = 0;
  int? _playing;
  bool _saving = false;
  bool _loadedFromPreset = false;
  ControlPreset? _source;
  late final PatternPlayer _player = PatternPlayer(ref.read(bleServiceProvider));

  @override
  void initState() {
    super.initState();
    _adoptPreset(ref.read(presetByIdProvider(widget.presetId ?? '')));
  }

  @override
  void dispose() {
    _player.stop();
    super.dispose();
  }

  void _adoptPreset(ControlPreset? preset) {
    if (preset == null || _loadedFromPreset || !preset.isCustom) return;
    _loadedFromPreset = true;
    _source = preset;
    _steps = PatternData.normalize(preset.steps);
  }

  bool get _editingOwnPreset => _source != null && !_source!.builtIn;

  void _updateChannel(int channel, int value) {
    setState(() {
      _steps = List<PatternStep>.of(_steps)
        ..[_selected] = _steps[_selected].withChannel(channel, value);
    });
  }

  void _copyToNext() {
    if (_selected >= _steps.length - 1) return;
    setState(() {
      _steps = List<PatternStep>.of(_steps)
        ..[_selected + 1] = PatternStep(channels: _steps[_selected].channels);
      _selected += 1;
    });
  }

  void _reset() {
    _player.stop();
    setState(() {
      _steps = _source != null
          ? PatternData.normalize(_source!.steps)
          : PatternData.starter();
      _selected = 0;
      _playing = null;
    });
  }

  Future<void> _togglePreview() async {
    if (_player.isPlaying) {
      _player.stop();
      setState(() => _playing = null);
      return;
    }
    await _player.play(
      _steps,
      onStep: (index) {
        if (mounted) setState(() => _playing = index);
      },
    );
  }

  Future<void> _save() async {
    _player.stop();
    setState(() => _playing = null);
    try {
      PatternData.validate(_steps);
    } on PatternValidationError catch (error) {
      _notify(error.message);
      return;
    }

    final name = await _askName(initial: _source?.presetName ?? '');
    if (name == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final request = SavePresetRequest.custom(presetName: name, steps: _steps);
      final notifier = ref.read(presetsProvider.notifier);
      if (_editingOwnPreset) {
        await notifier.updatePreset(_source!.id, request);
      } else {
        await notifier.create(request);
      }
      if (!mounted) return;
      _notify(_editingOwnPreset ? 'Preset updated.' : '“$name” saved to your presets.');
      context.pop();
    } on ApiException catch (error) {
      _notify(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _askName({required String initial}) {
    final controller = TextEditingController(text: initial);
    return showAppBottomSheet<String>(
      context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editingOwnPreset ? 'Update preset' : 'Save preset',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Give this pattern a name you will recognise later.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) Navigator.of(context).pop(value.trim());
              },
              decoration: const InputDecoration(
                hintText: 'Preset name',
                counterText: '',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => AppButton(
                label: _editingOwnPreset ? 'Update' : 'Save',
                onPressed: value.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).pop(value.text.trim()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.presetId != null && !_loadedFromPreset) {
      ref.listen(presetByIdProvider(widget.presetId!), (_, preset) {
        if (preset != null) setState(() => _adoptPreset(preset));
      });
    }

    final connected = ref.watch(bleSessionProvider).hasSession;
    final total = PatternData.totalDuration(_steps);
    final step = _steps[_selected];
    final previewing = _playing != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Pattern'),
        actions: [
          TextButton(onPressed: _reset, child: const Text('Reset')),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xs,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _source == null
                      ? 'New pattern'
                      : _editingOwnPreset
                          ? 'Editing “${_source!.presetName}”'
                          : 'Based on “${_source!.presetName}”',
                  style: AppTextStyles.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_steps.length} steps · '
                '${(total.inMilliseconds / 1000).toStringAsFixed(1)} s',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PatternTimeline(
            steps: _steps,
            selectedIndex: _selected,
            playingIndex: _playing,
            onSelect: (index) => setState(() => _selected = index),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'Step ${_selected + 1} of ${_steps.length}',
                  actionLabel: _selected < _steps.length - 1 ? 'Copy to next' : null,
                  onAction: _copyToNext,
                ),
                for (var c = 0; c < step.channels.length; c++) ...[
                  ChannelSlider(
                    label: _channelLabels[c],
                    value: step.channels[c],
                    throttle: const Duration(milliseconds: 16),
                    onChanged: (value) => _updateChannel(c, value),
                  ),
                  if (c < step.channels.length - 1) const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
          ),
          if (!connected) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Connect a device to preview this pattern.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: previewing ? 'Stop' : 'Preview',
                  icon: previewing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  onPressed: connected && !_saving ? _togglePreview : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Save Preset',
                  loading: _saving,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
