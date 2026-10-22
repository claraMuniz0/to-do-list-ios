# To-do list iOS

## Running tests
- Scheme `MyApp`, test target `ToDoListTests`, Swift Testing.
- Run only the relevant suite, in the background, and kill it after 30 s. macOS has no `timeout` command, so use `&` plus a `kill`:

```bash
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:ToDoListTests/<SuiteName> > /tmp/test.log 2>&1 &
```

- Never run the whole suite without the user's OK (one full run before opening a PR, if they agree).
- Never rerun the same failing command more than 3 times without changing code.

## Secrets
- `Config/Secrets.xcconfig` is git-ignored. Never read, print or commit it. `Config/Secrets.example.xcconfig` is the template.
