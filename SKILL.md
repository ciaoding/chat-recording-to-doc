---
name: chat-recording-to-doc
description: Convert local chat screen recordings into anonymized text documents using frame extraction and local OCR. Use when Codex needs to process WeChat or similar chat-scroll videos, recognize message bubbles, detect voice-message duration bubbles, attach visible voice-to-text transcript results from the recording, anonymize chat content, and export Markdown/DOCX/JSON without uploading raw media.
---

# Chat Recording to Doc

Use this skill to process private chat screen recordings locally. The workflow extracts frames, runs local OCR, merges repeated scroll content into ordered chat messages, attaches visible voice-to-text transcript text when it appears in the recording, anonymizes sensitive identifiers, and exports text documents.

## Privacy Contract

- Keep the original video, extracted frames, OCR JSON, raw text, and mapping reports local.
- Do not upload raw recordings, frames, OCR files, or non-anonymized documents.
- Commit only the skill code and generic docs to GitHub; never commit user recordings or generated chat outputs.
- Default to anonymized outputs. Use stable placeholders such as `[手机号_xxxxxxxx]`, `[邮箱_xxxxxxxx]`, `[身份证号_xxxxxxxx]`, `[公司_xxxxxxxx]`, and generic sender labels.

## Quick Workflow

1. Put the chat screen recording in a local folder.
2. Run the pipeline:

```bash
python3 ~/.codex/skills/chat-recording-to-doc/scripts/process_chat_recording.py \
  --video /path/to/chat-recording.mp4 \
  --output /path/to/output-folder \
  --conversation "聊天记录" \
  --date 2026-06-10 \
  --ollama-model qwen2.5:7b
```

3. Review:
   - `chat_anonymized.md`
   - `chat_anonymized.docx`
   - `chat_anonymized.json`
   - `anonymization_report.json`
4. Upload only the anonymized deliverables.

Use `--help` for options.

## Voice Messages and Voice-to-Text

The skill handles two cases:

- **Only a voice bubble is visible:** record it as `[语音 N秒]`.
- **The app displays speech-to-text result in the recording:** OCR captures the visible transcript and the merge step attaches nearby transcript text to the voice message when frame order, sender side, and vertical position indicate they belong together.

If the recording only contains played audio but no visible transcript, this skill does not transcribe the audio by default. Add a local ASR tool such as Whisper/whisper.cpp separately if audio transcription is required.

## Script Contents

- `scripts/ocr_video.swift`: macOS AVFoundation + Vision OCR frame extractor. No cloud calls.
- `scripts/process_chat_recording.py`: Orchestrates OCR, message merging, voice transcript attachment, anonymization, and exports.
- `references/github-publish.md`: GitHub publishing checklist.

## OCR Notes

- Works best on clear vertical phone recordings.
- Use `--step 0.25` for fast scrolling or when voice-to-text popups appear briefly.
- Use `--step 0.5` for slower scrolling and faster processing.
- The script keeps frame order and deduplicates repeated messages across scroll frames.

## QA Checklist

Before uploading anonymized outputs:

- Confirm no raw names, phone numbers, emails, addresses, account numbers, or IDs remain.
- Confirm all meaningful text bubbles are present in the exported document.
- Confirm visible speech-to-text transcript results are merged with the correct voice messages.
- Keep `anonymization_report.json` local; it may reveal entity categories and occurrence counts.
