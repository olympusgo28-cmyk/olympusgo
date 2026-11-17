# Third-party notices

OlympusGO's own code is not covered by the notices below. Each entry names what is used, where it is in this repository, and the licence it is used under.

## Body outline (Fitness muscle map)

The front and back body outlines in `lib/features/fitness/presentation/body_map_paths.dart` were taken on 17 Nov 2026 from [MuscleMap](https://github.com/melihcolpan/MuscleMap) by Melih Colpan, commit `d53ddf4d480b65979f1008b203e6b6eda0e67e54`, files `Sources/MuscleMap/Data/MaleFrontPaths.swift` and `MaleBackPaths.swift`.

Most of those paths are, in turn, the artwork of [react-native-body-highlighter](https://github.com/HichamELBSI/react-native-body-highlighter) by ELABBASSI Hicham (`assets/bodyFront.ts` and `assets/bodyBack.ts`, compared at commit `8ed39ac2ae9cb46fb79d77eedec7e5b029a75174`: 89 of the front paths and 70 of the back paths are identical). MuscleMap's repository does not say this; it was found by comparing the files.

Both projects are under the MIT License, so both copyright notices are carried, with the permission notice they share.

What was changed: the path strings were moved from Swift source into Dart constants, and MuscleMap's sub-group shapes (upper and lower chest, inner and outer quad and the like) were left out. The path geometry is unchanged. The app draws each view cropped to its viewBox, in its own colours, with the worked parts drawn last.

The same notices are in the header of the path data file and are registered with the app's licences (`registerBodyMapLicence` in `lib/features/fitness/presentation/body_map.dart`). The app has no licences page a player can open yet; one is needed before release (`docs/OPEN_QUESTIONS.md`, Q277 g).

```
MIT License

Copyright (c) 2026 Melih Colpan
Copyright (c) 2022 ELABBASSI Hicham

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
