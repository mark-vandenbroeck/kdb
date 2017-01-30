set serveroutput on
declare

	cursor c_sequences is select * from user_sequences   where sequence_name like 'KDB_%';
	cursor c_triggers  is select * from user_triggers    where trigger_name  like 'KDB_%';
	cursor c_tables    is select * from user_tab_columns where table_name    like 'KDB_%' and column_name = 'ID';
	cursor c_date_cols is
		select * from user_tab_columns
		where
			table_name like 'KDB_%' and 
			data_type = 'DATE' and 
			data_default is not null
	;
	
	v_max_value		number;
	v_sql					varchar2(32000);
	v_count				number;
	v_sequence		varchar2(100);
	v_trigger			varchar2(100);
	
	procedure exec (v_cmd in varchar2)
	is
	begin
--		dbms_output.put_line(v_cmd);
		execute immediate v_cmd;
	exception when others then
		dbms_output.put_line(v_cmd);
		raise;
	end;
	
begin

	-- Drop sequences
	for t in c_sequences loop
		exec('drop sequence '||t.sequence_name);
	end loop;
	
	-- Drop triggers
	for t in c_triggers loop
		exec('drop trigger '||t.trigger_name);
	end loop;
	
	-- For all tables
	for t in c_tables loop
	
		-- Create sequence
		v_sequence := t.table_name||'_ID_SEQ';
		if length(v_sequence) > 30 then
			v_sequence := 'KDB_'||substr(v_sequence, -26);
		end if;
		execute immediate 'select nvl(max(id), 1) from '||t.table_name into v_max_value;
		exec('create sequence '||v_sequence||' start with '||to_char(v_max_value + 1));
		
		-- Create trigger
		v_trigger := t.table_name||'_ID_TRG';
		if length(v_trigger) > 30 then
			v_trigger := 'KDB_'||substr(v_trigger, -26);
		end if;
		v_sql := '
			create or replace trigger '||v_trigger||'
				before insert or update on '||t.table_name||'
				for each row
			begin
				if inserting and :new.id is null then
					select '||v_sequence||'.nextval into :new.id from dual;
				end if;
		';
		
		-- CREATED_DT
		select count(*) into v_count from user_tab_columns where table_name = t.table_name and column_name = 'CREATED_DT';
		if v_count > 0 then
			v_sql := v_sql || '
				if inserting and :new.created_dt is null then
					:new.created_dt := sysdate;
				end if;
			';
		end if;
		
		-- MODIFIED_DT
		select count(*) into v_count from user_tab_columns where table_name = t.table_name and column_name = 'MODIFIED_DT';
		if v_count > 0 then
			v_sql := v_sql || '
				if :new.modified_dt is null then
					:new.modified_dt := sysdate;
				end if;
			';
		end if;

		-- CREATED_BY
		select count(*) into v_count from user_tab_columns where table_name = t.table_name and column_name = 'CREATED_BY';
		if v_count > 0 then
			v_sql := v_sql || '
				if inserting and :new.created_by is null then
					:new.created_by := nvl(v(''APP_USER''), user);
				end if;
			';
		end if;
		
		-- MODIFIED_BY
		select count(*) into v_count from user_tab_columns where table_name = t.table_name and column_name = 'MODIFIED_BY';
		if v_count > 0 then
			v_sql := v_sql || '
				if :new.modified_by is null then
					:new.modified_by := nvl(v(''APP_USER''), user);
				end if;
			';
		end if;
		
		-- VERSION_NO
		select count(*) into v_count from user_tab_columns where table_name = t.table_name and column_name = 'VERSION_NO';
		if v_count > 0 then
			v_sql := v_sql || '
				if inserting and :new.version_no is null then
					:new.version_no := 0;
				end if;
				if updating and :new.version_no is null then
					:new.version_no := nvl(:old.version_no, 0) + 1;
				end if;
			';
		end if;
		
		v_sql := v_sql || '
			end;
		';
		
		exec(v_sql);
		
	end loop;
	
	-- Date columns
	for t in c_date_cols loop
		exec('alter table '||t.table_name||' modify ('||t.column_name||' date default null)');
	end loop;
	
end;
/