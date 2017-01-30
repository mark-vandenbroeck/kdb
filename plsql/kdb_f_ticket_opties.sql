create or replace function kdb_f_ticket_opties (p_tkt_evenement_id in number) return varchar2
is
	v_sql	varchar2(4000);
	v_evt kdb_tkt_evenements%rowtype;
begin

	select * into v_evt from kdb_tkt_evenements where id = p_tkt_evenement_id;

	if v_evt.afhalen_dk_mogelijk = 1 then
		v_sql := 
			'select ''Afhalen in De Kampanje'' d, ''DK'' r from dual 
			UNION
		';
	end if;

	if v_evt.verzend_mogelijk = 1 then
		v_sql := v_sql ||
			'select ''Laten opsturen ('|| v_evt.verzendkost ||' EUR verzendkost)'' d, ''Post'' r from dual 
			UNION
		';
	end if;
	
	if v_evt.afhalen_zaal_mogelijk = 1 then
		v_sql :=  v_sql ||
			'select ''Klaarliggen aan de kassa'' d, ''Kassa'' r from dual 
			UNION
		';
	end if;
	
	v_sql := regexp_replace(v_sql, 'UNION\n*\s*$', '');
	return v_sql;
	
end;
/
show errors
