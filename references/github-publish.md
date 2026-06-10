# GitHub Publishing Checklist

Publish only generic skill files:

- `SKILL.md`
- `agents/openai.yaml`
- `scripts/ocr_video.swift`
- `scripts/process_chat_recording.py`
- `references/github-publish.md`
- `.gitignore`

Never publish:

- screen recordings
- extracted frame images
- OCR JSON/JSONL
- raw chat text
- anonymized user outputs derived from private chats
- mapping or anonymization reports

Recommended publish commands:

```bash
cd ~/.codex/skills/chat-recording-to-doc
git init
git add SKILL.md agents/openai.yaml scripts/ocr_video.swift scripts/process_chat_recording.py references/github-publish.md .gitignore
git commit -m "Add chat recording to doc skill"
gh repo create chat-recording-to-doc --private --source=. --remote=origin --push
```
