alter table kdb_export_criteria modify (modified_dt date default null);

drop sequence kdb_export_criteria_id_SEQ;
declare
	v_id	number;
begin
	select max(id) into v_id from kdb_export_criteria;
	v_id := v_id + 1;
	execute immediate 'create sequence kdb_export_criteria_id_SEQ start with ' || v_id;
end;
/	

create or replace trigger KDB_EXPORT_CRITERIA_ID_TRG
	before insert or update on kdb_export_criteria
	for each row
begin
	if inserting then
		if :new.created_dt is null then
			:new.created_dt := sysdate;
		end if;	
		if :new.created_by is null then
			:new.created_by := nvl(v('APP_USER'), user);
		end if;
		if :new.version_no is null then
			:new.version_no := 0;
		end if;
		if :new.id is null then
			select kdb_export_criteria_id_SEQ.nextval into :new.id from dual;
		end if;
	end if;
	
	if updating and :new.version_no is null then
		:new.version_no := nvl(:old.version_no, 0) + 1;
	end if;
	
	if :new.modified_dt is null then
		:new.modified_dt := sysdate;
	end if;
	if :new.modified_by is null then
		:new.modified_by := nvl(v('APP_USER'), user);
	end if;
	
end;
/
show errors

