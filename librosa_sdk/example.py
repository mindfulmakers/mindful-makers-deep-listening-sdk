"""Example: Analyze audio for meditation suitability."""

from pathlib import Path

import numpy as np

from librosa_sdk import MindfulAnalyzer

# Path to the sample meditation audio
SAMPLE_MP3 = Path(__file__).parent / "bad-meditation-music.mp3"


def main():
    print("=" * 60)
    print("Librosa SDK - Mindful Audio Analysis Demo")
    print("=" * 60)
    print()

    print("Loading sample meditation audio...")
    print(f"  File: {SAMPLE_MP3.name}")

    # Create analyzer and load audio
    analyzer = MindfulAnalyzer(str(SAMPLE_MP3))
    print(f"  Duration: {analyzer.get_duration():.1f} seconds")
    print(f"  Sample rate: {analyzer.sr} Hz")
    print()

    # Analyze tempo
    print("Tempo Analysis:")
    print("-" * 40)
    tempo = analyzer.analyze_tempo()
    print(f"  BPM: {tempo['bpm']}")
    print(f"  Category: {tempo['category']}")
    print(f"  {tempo['description']}")
    print()

    # Analyze spectral warmth
    print("Spectral Warmth Analysis:")
    print("-" * 40)
    warmth = analyzer.analyze_spectral_warmth()
    print(f"  Spectral centroid: {warmth['centroid_hz']} Hz")
    print(f"  Warmth score: {warmth['warmth_score']} (0=bright, 1=warm)")
    print(f"  Character: {warmth['character']}")
    print(f"  {warmth['description']}")
    print()

    # Full meditation features
    print("Full Meditation Feature Analysis:")
    print("-" * 40)
    features = analyzer.extract_meditation_features()
    print(f"  Tempo: {features['tempo_bpm']} BPM ({features['tempo_category']})")
    print(f"  Warmth: {features['warmth_score']} ({features['warmth_character']})")
    print(f"  Dynamics: {features['dynamics']}")
    print(f"  Timbral complexity: {features['timbral_complexity']}")
    print(f"  Percussiveness: {features['percussiveness']}")
    print(f"  Meditation score: {features['meditation_score']}")
    print(f"  Suitability: {features['suitability'].upper()}")
    print()

    # Detect silence gaps
    print("Silence Gap Detection:")
    print("-" * 40)
    gaps = analyzer.detect_silence_gaps(min_silence_ms=200)
    if gaps:
        for i, gap in enumerate(gaps[:5]):  # Show first 5
            print(
                f"  Gap {i + 1}: {gap['start_sec']}s - {gap['end_sec']}s ({gap['duration_sec']}s)"
            )
    else:
        print("  No significant silence gaps detected (continuous audio)")
    print()

    # Harmonic/Percussive separation
    print("Harmonic/Percussive Separation:")
    print("-" * 40)
    harmonic, percussive = analyzer.separate_harmonic_percussive()
    harmonic_energy = np.mean(np.abs(harmonic))
    percussive_energy = np.mean(np.abs(percussive))
    total = harmonic_energy + percussive_energy
    print(f"  Harmonic content: {harmonic_energy / total * 100:.1f}%")
    print(f"  Percussive content: {percussive_energy / total * 100:.1f}%")
    print()

    print("=" * 60)
    print("Analysis complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
