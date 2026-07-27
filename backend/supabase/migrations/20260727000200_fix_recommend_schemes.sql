-- Qualify eligibility_rules.scheme_id so it cannot be confused with the
-- RETURNS TABLE output variable of the same name.
create or replace function public.recommend_schemes(startup_profile_id uuid)
returns table (
  scheme_id uuid,
  scheme_name text,
  match_score numeric,
  matched_rules jsonb,
  failed_rules jsonb,
  recommendation_reason text
)
language plpgsql
as $$
declare
  sp_row public.startup_profiles%rowtype;
  sp_json jsonb;
  s_row record;
  r_row record;
  rule_passed boolean;
  val_text text;
  rule_val_numeric numeric;
  rule_val_min numeric;
  rule_val_max numeric;
  rule_single_numeric numeric;
  temp_matched jsonb;
  temp_failed jsonb;
  total_rules integer;
  passed_rules integer;
  final_score numeric;
  reason text;
begin
  select *
  into sp_row
  from public.startup_profiles as startup_profile
  where startup_profile.id = recommend_schemes.startup_profile_id;

  if not found then
    return;
  end if;

  sp_json := to_jsonb(sp_row);

  for s_row in
    select * from public.schemes as scheme where scheme.is_active = true
  loop
    temp_matched := '[]'::jsonb;
    temp_failed := '[]'::jsonb;
    total_rules := 0;
    passed_rules := 0;

    for r_row in
      select *
      from public.eligibility_rules as eligibility_rule
      where eligibility_rule.scheme_id = s_row.id
    loop
      total_rules := total_rules + 1;
      rule_passed := false;
      val_text := sp_json->>r_row.parameter_name;

      if val_text is not null then
        if r_row.operator = '=' then
          rule_passed := lower(val_text) = lower(r_row.value);
        elsif r_row.operator = '!=' then
          rule_passed := lower(val_text) <> lower(r_row.value);
        elsif r_row.operator = 'IN' then
          rule_passed := exists (
            select 1
            from unnest(string_to_array(r_row.value, ',')) as elem
            where trim(lower(elem)) = trim(lower(val_text))
          );
        elsif r_row.operator = 'NOT IN' then
          rule_passed := not exists (
            select 1
            from unnest(string_to_array(r_row.value, ',')) as elem
            where trim(lower(elem)) = trim(lower(val_text))
          );
        elsif r_row.operator = 'CONTAINS' then
          rule_passed := position(lower(r_row.value) in lower(val_text)) > 0;
        elsif r_row.operator = 'BETWEEN' then
          rule_val_numeric := public.safe_cast_to_numeric(val_text);
          rule_val_min := public.safe_cast_to_numeric(split_part(r_row.value, ',', 1));
          rule_val_max := public.safe_cast_to_numeric(split_part(r_row.value, ',', 2));
          rule_passed := rule_val_numeric is not null
            and rule_val_min is not null
            and rule_val_max is not null
            and rule_val_numeric between rule_val_min and rule_val_max;
        elsif r_row.operator = '>' then
          rule_val_numeric := public.safe_cast_to_numeric(val_text);
          rule_single_numeric := public.safe_cast_to_numeric(r_row.value);
          rule_passed := rule_val_numeric is not null
            and rule_single_numeric is not null
            and rule_val_numeric > rule_single_numeric;
        elsif r_row.operator = '>=' then
          rule_val_numeric := public.safe_cast_to_numeric(val_text);
          rule_single_numeric := public.safe_cast_to_numeric(r_row.value);
          rule_passed := rule_val_numeric is not null
            and rule_single_numeric is not null
            and rule_val_numeric >= rule_single_numeric;
        elsif r_row.operator = '<' then
          rule_val_numeric := public.safe_cast_to_numeric(val_text);
          rule_single_numeric := public.safe_cast_to_numeric(r_row.value);
          rule_passed := rule_val_numeric is not null
            and rule_single_numeric is not null
            and rule_val_numeric < rule_single_numeric;
        elsif r_row.operator = '<=' then
          rule_val_numeric := public.safe_cast_to_numeric(val_text);
          rule_single_numeric := public.safe_cast_to_numeric(r_row.value);
          rule_passed := rule_val_numeric is not null
            and rule_single_numeric is not null
            and rule_val_numeric <= rule_single_numeric;
        end if;
      end if;

      if rule_passed then
        passed_rules := passed_rules + 1;
        temp_matched := temp_matched || jsonb_build_object(
          'rule_id', r_row.id,
          'parameter', r_row.parameter_name,
          'description', r_row.description
        );
      else
        temp_failed := temp_failed || jsonb_build_object(
          'rule_id', r_row.id,
          'parameter', r_row.parameter_name,
          'description', r_row.description
        );
      end if;
    end loop;

    if total_rules > 0 then
      final_score := round((passed_rules::numeric / total_rules::numeric) * 100, 2);
    else
      final_score := 100.00;
    end if;

    if jsonb_array_length(temp_failed) = 0 then
      reason := 'Your startup profile perfectly matches all eligibility criteria for this scheme.';
    elsif jsonb_array_length(temp_failed) <= 1 then
      reason := 'Your startup profile matches most of the eligibility criteria.';
    else
      reason := 'Your startup profile does not meet several eligibility criteria.';
    end if;

    scheme_id := s_row.id;
    scheme_name := s_row.scheme_name;
    match_score := final_score;
    matched_rules := temp_matched;
    failed_rules := temp_failed;
    recommendation_reason := reason;
    return next;
  end loop;
end;
$$;
