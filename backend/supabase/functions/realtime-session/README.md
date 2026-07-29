# Realtime voice session

Deploy this authenticated Edge Function and set these server-side secrets:

```sh
supabase secrets set OPENAI_API_KEY=... VOICE_SAFETY_SALT=...
supabase functions deploy realtime-session
```

The permanent OpenAI key is never returned. The function verifies the Supabase
access token and returns only OpenAI's short-lived Realtime client secret.
