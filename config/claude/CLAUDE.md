When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision. "No aphorisms"

Never read secret-bearing files directly. Instead use Python to load them and print keys with masked values (show only first/last 2 chars). eg:
- values-local.yaml
- .env* (except sample files)

Question rounds (grilling, grill-me, grill-with-docs, or any numbered batch of questions for me): when `$HC_TERMINAL_ID` is set, post the round with `herdr-ask` (JSON on stdin; `herdr-ask --help` for the shape: topic + questions with id/title/body/recommended) instead of printing it in chat; in chat say only one line, e.g. "Questions posted to panel (<topic>, N questions)". If `herdr-ask` fails, print the round in chat as usual. Without `$HC_TERMINAL_ID`, print the round in chat. The panel opens with Cmd/Super+g; my answers come back as a message starting "Answers from the question panel" (I may also answer in chat). Run `herdr-ask --clear` when the session's questions are done.

@CLAUDE.local.md
@RTK.md
