"""Example: Search and explore meditation sounds on Freesound."""

import os
import subprocess
import tempfile
from pathlib import Path

import requests
from dotenv import load_dotenv

from freesound_sdk import FreesoundClient


def download_preview(url: str, path: Path) -> None:
    """Download a preview MP3 from Freesound."""
    response = requests.get(url, stream=True)
    response.raise_for_status()
    with open(path, "wb") as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)


def play_audio(path: Path) -> None:
    """Play an audio file using the system player."""
    subprocess.run(["afplay", str(path)], check=True)


def main():
    print("=" * 60)
    print("Freesound SDK - Meditation Sound Discovery Demo")
    print("=" * 60)
    print()

    # Check for API credentials
    load_dotenv()
    if not os.getenv("FREESOUND_CLIENT_SECRET"):
        print("FREESOUND_CLIENT_SECRET not set!")
        print()
        print("To use this SDK:")
        print("1. Get credentials at: https://freesound.org/apiv2/apply")
        print("2. Add to .env file:")
        print("   FREESOUND_CLIENT_ID=your_client_id")
        print("   FREESOUND_CLIENT_SECRET=your_client_secret")
        print()
        print("Demo will show available features without API calls.")
        print("-" * 40)
        print()

        # Show presets even without API key
        print("Available Meditation Presets:")
        presets = FreesoundClient.MEDITATION_PRESETS
        for name, config in presets.items():
            print(f"  {name}: {config['description']}")
        print()
        return

    client = FreesoundClient()

    # Show available presets
    print("Available Meditation Presets:")
    print("-" * 40)
    for name, description in client.get_meditation_presets().items():
        print(f"  {name}: {description}")
    print()

    # Search for singing bowls
    print("Searching for singing bowl sounds (10-30 seconds)...")
    print("-" * 40)
    sounds = client.search_sounds(
        query="singing bowl",
        duration_range=(10, 30),
        page_size=5,
    )

    for sound in sounds:
        print(f"  [{sound['id']}] {sound['name']}")
        print(
            f"        Duration: {sound['duration']:.1f}s | Rating: {sound['rating']:.1f}"
        )
        print(f"        Tags: {', '.join(sound['tags'][:5])}")
        print()

    # Search using a preset
    print("Searching 'nature' preset for ambient sounds...")
    print("-" * 40)
    nature_sounds = client.search_preset(
        "nature", duration_range=(30, 120), page_size=5
    )

    for sound in nature_sounds:
        print(f"  [{sound['id']}] {sound['name']}")
        print(f"        Duration: {sound['duration']:.1f}s")
        print()

    # Download and play sounds
    if sounds:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmppath = Path(tmpdir)

            for i, sound in enumerate(sounds[:2]):  # Play first 2 sounds
                print(f"Downloading and playing sound {i + 1}: {sound['name']}")
                print("-" * 40)
                print(f"  ID: {sound['id']}")
                print(f"  Duration: {sound['duration']:.1f} seconds")

                if sound["preview_url"]:
                    mp3_path = tmppath / f"sound_{sound['id']}.mp3"
                    download_preview(sound["preview_url"], mp3_path)
                    print("  Playing preview...")
                    play_audio(mp3_path)
                    print()

                # Show attribution
                attribution = client.get_attribution(sound["id"])
                print(f"  Attribution: {attribution}")
                print()

    print("=" * 60)
    print("Demo complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
