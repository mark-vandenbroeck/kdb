create or replace function kdb_f_exec_export(p_id in number) return varchar2
is
	v_query		varchar2(32000);
	v_jaar		varchar2(10);
	v_export  kdb_exports%rowtype;
	v_prefix	varchar2(10);
	v_quote		varchar2(1);
	
	cursor c_criteria is
		SELECT
			e.id,
			c.model,
			c.field,
			e.operator,
			e.waarde,
			c.datatype
		FROM
			kdb_export_criteria e,
			kdb_criteria        c
		WHERE
			e.export_id = p_id and
			e.criterium_id = c.id
	;
	
	cursor c_vlaggen is
		SELECT
			e.flag_id,
			e.waarde,
			f.omschrijving
		FROM	
			kdb_export_flags e,
			kdb_flags        f
		WHERE
			e.flag_id = f.id and
			export_id = p_id
	;
	
begin

	-- Get data
	select parameter_value into v_jaar from kdb_parameters where parameter_name = 'huidig werkjaar';
	select * into v_export from kdb_exports where id = p_id;
	
	-- Query base
	v_query := '
		SELECT
			p.id,
			p.voornaam,
			p.straat,
			p.huisnummer,
			p.postcode,
			p.gemeente,
			p.telefoon,
			p.gsm,
			p.email1,
			p.email2,
			p.geboortedatum,
			p.opmerkingen,
			m.id lidnr
		FROM
			kdb_persons p,
			kdb_members m
		WHERE
			p.id = m.person_id(+)
	and nvl(m.werkjaar, '||v_jaar||') = '||v_jaar||'
	';
	
	-- vervallen personen
	if nvl(v_export.vervallen, 0) = 0 then
		v_query := v_query || '
			and nvl(p.einddatum, sysdate+1) > sysdate';
		end if;
		
	-- Criteria
	for c in c_criteria loop
	
		v_prefix := substr(c.model, 1, 1)||'.';
		
		if c.datatype = 'string' then
			v_quote := '''';
		else
			v_quote := '';
		end if;
		
		v_query := v_query || '
		and upper('||v_prefix||c.field||') '||c.operator||' upper('||v_quote||c.waarde||v_quote||')';
	end loop;
	
	-- Vlaggen
	for f in c_vlaggen loop
		if f.waarde = 0 then
			v_query := v_query || '
			and not exists (select 1 from kdb_flags_persons where person_id = p.id and flag_id = '||f.flag_id||') -- '||f.omschrijving;
		else
			v_query := v_query || '
			and     exists (select 1 from kdb_flags_persons where person_id = p.id and flag_id = '||f.flag_id||') -- '||f.omschrijving;
		end if;
	end loop;
	
	return v_query;
end;
/