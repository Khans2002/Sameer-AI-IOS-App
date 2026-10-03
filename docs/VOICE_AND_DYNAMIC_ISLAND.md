# Sameer AI — Voice and Dynamic Island Plan

## Promise

Voice is an optional, entirely on-device feature. It is not part of the first text-only release, and it cannot activate or use the microphone until the person explicitly turns on Voice conversation and grants microphone permission.

## Dynamic Island behavior

The iPhone 16 Pro supports Dynamic Island. Sameer AI will use an Apple Live Activity for an active voice session:

| Presentation | Purpose | Content |
| --- | --- | --- |
| Compact | At-a-glance status while the person uses another app | Privacy dot, concise “Listening” or “Speaking” state, elapsed session time. |
| Expanded | Shown when the person touches and holds Dynamic Island | Clear current state, a small local waveform, and an end-session action. |
| Minimal | Shown by the system when another app also has a Live Activity | Small, recognizable Sameer AI presence; tapping returns to the active voice conversation. |
| Lock Screen | Useful when the device is locked during an active interaction | Current local voice state and a way back to Sameer AI. |

The design cannot take over the island permanently: iOS decides which Live Activities appear, and it can show a minimal presentation if another app is active. This is an Apple platform rule, not an app limitation we can bypass.

## Technical design, when voice is implemented

1. Add a WidgetKit extension containing the Dynamic Island/Live Activity layouts.
2. Use ActivityKit only for the lifecycle: start at voice-session start, update state while the app is active, end immediately when the session ends.
3. Keep Live Activity state under Apple’s 4 KB combined limit; it contains only session state and elapsed time, never transcript text or audio.
4. Keep speech recognition, local LLM generation, and text-to-speech in the main app. The Live Activity has no network requirement and will never use a cloud voice service.
5. Essential Mode prevents starting a voice session and ends any active voice Live Activity.

## Privacy rules

- The Dynamic Island displays no sensitive transcript, question, contact, filename, or reply by default.
- The visible state is limited to “Listening”, “Thinking”, “Speaking”, or “Paused”.
- Audio is stored only if the future voice setting explicitly enables saving it; default behavior is no retained audio recording.
- Voice has an independent Storage category before any persistent audio feature can ship.

## Review gate

Before implementing voice, choose the on-device speech recognition and text-to-speech models/runtimes through the same license, battery, thermal, and privacy review used for the LLM. Test the Dynamic Island on the physical iPhone 16 Pro.
