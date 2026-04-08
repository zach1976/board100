# board100

## Project Structure

```
board100/
└── tactics_board/   # Flutter app — multi-sport tactics board
```

## AI Code Editing Rules

1. Never modify code that already works.
2. Only apply the minimal change required.
3. Do not refactor unrelated code.
4. Do not rename variables or functions unless required.
5. Preserve code structure and formatting.
6. Prefer small diffs instead of rewriting files.
7. If uncertain, leave the code unchanged.

## Running the App

```bash
cd tactics_board
flutter run -d F237E798-FBA9-44F8-81B4-71F160131DF9  # iPhone 17 Pro Max simulator
```

## Running Tests

```bash
cd tactics_board
flutter test test/models/ test/state/
