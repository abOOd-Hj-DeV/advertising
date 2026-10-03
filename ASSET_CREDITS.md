# Asset sources and licenses

Replacement assets for an unofficial visual UI study. **No APK resources or real listing photos were extracted.** Listing descriptions, prices, profiles, addresses and messages are fictional.

## Nunito Sans

- Source: https://github.com/google/fonts/tree/main/ofl/nunitosans
- Local font: `assets/fonts/NunitoSans.ttf`
- License: **SIL Open Font License 1.1**, included in `assets/fonts/OFL.txt`.
- This is a substitute, not claimed to be the reference's exact font.

## Local fallback fonts

- Roboto: https://github.com/google/fonts/tree/main/ofl/roboto, bundled as `assets/fonts/Roboto.ttf` under SIL OFL 1.1 (`Roboto-OFL.txt`). Registered for Flutter Web's mandatory default font without fetching it from Google.
- DejaVu Sans: https://dejavu-fonts.github.io/, bundled from the system fonts as `assets/fonts/DejaVuSans.ttf`; Bitstream Vera license with public-domain DejaVu changes (`DejaVu-LICENSE.txt`). Provides local Web fallback for symbols and additional scripts.
- Web font fallback URLs are same-origin. Unbundled scripts/emoji require additional local fonts rather than an automatic CDN download.

## Photographs

Locally bundled Unsplash example photos under the [Unsplash License](https://unsplash.com/license), which permits free download, modification and commercial/noncommercial use. Used as listing illustrations, not resold or offered as a stock-photo library. No runtime image network requests.

| Local file | Source image |
|---|---|
| `bike.jpg` | https://images.unsplash.com/photo-1485965120184-e220f721d03e |
| `bike_city.jpg` | https://images.unsplash.com/photo-1532298229144-0ec0c57515c7 |
| `bike_road.jpg` | https://images.unsplash.com/photo-1571068316344-75bc76f77890 |
| `sofa.jpg` | https://images.unsplash.com/photo-1555041469-a586c61ea9bc |
| `room.jpg` | https://images.unsplash.com/photo-1600210492486-724fe5c67fb0 |
| `car.jpg` | https://images.unsplash.com/photo-1503376780353-7e6692767b70 |
| `camera.jpg` | https://images.unsplash.com/photo-1516035069371-29a1b244cc32 |
| `shoes.jpg` | https://images.unsplash.com/photo-1542291026-7eec264c27ff |
| `plant.jpg` | https://images.unsplash.com/photo-1416879595882-3373a0480b5b |
| `books.jpg` | https://images.unsplash.com/photo-1507842217343-583bb7270b66 |
| `laptop.jpg` | https://images.unsplash.com/photo-1496181133206-80ce9b88a853 |
| `dog.jpg` | https://images.unsplash.com/photo-1543466835-00a7907e9de1 |

## Illustrations, map, logo and launcher

- Guest/error illustrations and schematic map are newly drawn with Flutter `CustomPainter`.
- `assets/app_icon.svg` and launcher PNGs are an original demo marketplace tag icon.
- The hand-drawn wordmark study recreates the visual placement for reference fidelity. Kleinanzeigen trademarks remain their owner's property. This app is clearly an **unofficial UI demo**, with no affiliation or official service access.
- Material Icons, Cupertino Icons and Flutter retain their upstream licenses. Runtime license notices are not removed.
