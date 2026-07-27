-- RLS policies do not grant PostgreSQL table privileges. Keep public catalogue
-- reads available to the Flutter app and grant signed-in users only the tables
-- for which the existing RLS policies enforce ownership.

grant select on table
  public.schemes,
  public.document_types,
  public.services,
  public.eligibility_rules,
  public.scheme_documents,
  public.scheme_services,
  public.questions,
  public.question_options,
  public.search_documents
to anon, authenticated;

grant select, insert, update, delete on table
  public.users,
  public.startup_profiles,
  public.questionnaire_sessions,
  public.user_responses,
  public.recommendations,
  public.notifications
to authenticated;
