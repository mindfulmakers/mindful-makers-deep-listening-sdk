# Librosa SDK - Audio Analysis for Mindfulness

Analyze audio files to understand their meditation and mindfulness qualities using [librosa](https://librosa.org/).

## Features

- **Tempo Analysis** - Detect BPM and categorize as calming (<70), moderate (70-120), or energizing (>120)
- **Spectral Warmth** - Measure brightness/warmth for mood assessment
- **Meditation Features** - Extract comprehensive features including MFCCs, dynamics, and timbral complexity
- **Silence Detection** - Find natural pause points for guided meditation
- **Harmonic/Percussive Separation** - Isolate ambient textures from rhythmic elements

## Usage

### Basic Analysis

```python
from librosa_sdk import MindfulAnalyzer

# Load and analyze an audio file
analyzer = MindfulAnalyzer("meditation_track.mp3")

# Get tempo category
tempo = analyzer.analyze_tempo()
print(f"BPM: {tempo['bpm']}")
print(f"Category: {tempo['category']}")  # "calming", "moderate", or "energizing"
```

### Spectral Warmth

```python
warmth = analyzer.analyze_spectral_warmth()
print(f"Warmth score: {warmth['warmth_score']}")  # 0-1, higher = warmer
print(f"Character: {warmth['character']}")  # "warm", "balanced", or "bright"
```

### Full Meditation Feature Extraction

```python
features = analyzer.extract_meditation_features()

print(f"Tempo: {features['tempo_bpm']} BPM ({features['tempo_category']})")
print(f"Warmth: {features['warmth_score']} ({features['warmth_character']})")
print(f"Dynamics: {features['dynamics']}")  # "stable" or "dynamic"
print(f"Meditation suitability: {features['suitability']}")  # "excellent", "good", "moderate", "low"
```

### Find Silence Gaps

```python
# Find pauses suitable for guided meditation cues
gaps = analyzer.detect_silence_gaps(min_silence_ms=500)

for gap in gaps:
    print(f"Pause at {gap['start_sec']}s - {gap['end_sec']}s")
```

### Separate Harmonic and Percussive

```python
# Isolate the ambient drone from rhythmic elements
harmonic, percussive = analyzer.separate_harmonic_percussive()

# Save just the harmonic (ambient) portion
import soundfile as sf
sf.write("ambient_only.wav", harmonic, analyzer.sr)
```

### Loading from Array

```python
import numpy as np

# Generate or load audio as numpy array
audio = np.sin(2 * np.pi * 440 * np.linspace(0, 1, 22050))

analyzer = MindfulAnalyzer()
analyzer.load_from_array(audio, sr=22050)
features = analyzer.extract_meditation_features()
```

## Meditation Suitability Scoring

The `extract_meditation_features()` method returns a meditation suitability score based on:

| Factor | Weight | Ideal for Meditation |
|--------|--------|---------------------|
| Tempo | 40% | Calming (<70 BPM) |
| Warmth | 30% | Warm tones (>0.5) |
| Dynamics | 20% | Stable energy |
| Percussiveness | 10% | Low (smooth, flowing) |

**Score Interpretation:**
- **Excellent** (≥0.7): Ideal for deep meditation
- **Good** (0.5-0.7): Suitable for most meditation styles
- **Moderate** (0.3-0.5): May work for active meditation
- **Low** (<0.3): Better suited for focus or energizing sessions

## Example

Run the example to see all features in action:

```bash
uv run python librosa_sdk/example.py
```





Demo sound attribution:

Soothing Atmospheric Sound for Media by Matio888 -- https://freesound.org/s/797914/ -- License: Attribution 4.0

Demo Song by deleted_user_4397472 -- https://freesound.org/s/277457/ -- License: Creative Commons 0
